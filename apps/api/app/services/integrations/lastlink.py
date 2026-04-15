from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.base import utc_now
from app.models.entities import Client, Sale, WebhookEvent
from app.models.enums import IntegrationProvider, PaymentMethod, Platform, SaleKind, SaleStatus, Scope
from app.schemas.client import ClientCreate
from app.schemas.sale import SaleCreate
from app.services.records import upsert_client, upsert_sale


SUPPORTED_LASTLINK_EVENTS = {
    "Purchase_Order_Confirmed",
    "Purchase_Request_Confirmed",
    "Recurrent_Payment",
    "Payment_Refund",
    "Payment_Chargeback",
    "Subscription_Canceled",
}


@dataclass(slots=True)
class LastlinkWebhookResult:
    webhook_event_id: str
    client_id: str | None = None
    sale_id: str | None = None
    status: str = "stored"


def _map_payment_method(value: str | None) -> PaymentMethod:
    mapping = {
        "pix": PaymentMethod.PIX,
        "credit_card": PaymentMethod.CREDIT_CARD,
        "bankslip": PaymentMethod.BOLETO,
    }
    return mapping.get((value or "").lower(), PaymentMethod.OTHER)


def _extract_platform_fee(commissions: list[dict[str, Any]]) -> Decimal:
    for item in commissions:
        if str(item.get("Source", "")).upper() == "MARKETPLACE":
            return Decimal(str(item.get("Value", 0)))
    return Decimal("0.00")


def ingest_lastlink_webhook(session: Session, workspace_id: str, payload: dict[str, Any]) -> LastlinkWebhookResult:
    event_name = str(payload.get("Event", "unknown"))
    webhook = WebhookEvent(
        workspace_id=workspace_id,
        provider=IntegrationProvider.LASTLINK,
        external_event_id=payload.get("Id"),
        event_name=event_name,
        is_test=bool(payload.get("IsTest", False)),
        payload=payload,
        received_at=utc_now(),
        processing_status="received",
    )
    session.add(webhook)
    session.flush()

    if event_name not in SUPPORTED_LASTLINK_EVENTS:
        webhook.processing_status = "ignored"
        session.flush()
        return LastlinkWebhookResult(webhook_event_id=webhook.id, status="ignored")

    data = payload.get("Data", {}) or {}
    buyer = data.get("Buyer", {}) or {}
    offer = data.get("Offer", {}) or {}
    products = data.get("Products", []) or []
    purchase = data.get("Purchase", {}) or {}
    payment = purchase.get("Payment", {}) or {}
    utm = data.get("Utm", {}) or {}

    existing_client = None
    buyer_name = buyer.get("Name")
    if buyer_name:
        existing_client = session.scalar(
            select(Client).where(Client.workspace_id == workspace_id, Client.name == buyer_name, Client.deleted_at.is_(None)).limit(1)
        )

    client = existing_client
    if buyer_name:
        client = upsert_client(
            session,
            workspace_id,
            ClientCreate(
                id=existing_client.id if existing_client else None,
                name=buyer_name,
                email=buyer.get("Email"),
                phone=buyer.get("PhoneNumber"),
                lead_source=utm.get("UtmSource"),
                sales_platform=Platform.LASTLINK,
                service_name=(products[0].get("Name") if products else offer.get("Name")),
                related_group=offer.get("Name"),
            ),
        )

    payment_date_raw = purchase.get("PaymentDate")
    sold_at = datetime.fromisoformat(payment_date_raw.replace("Z", "+00:00")) if payment_date_raw else datetime.now(timezone.utc)
    gross_amount = Decimal(str((purchase.get("Price") or {}).get("Value", 0)))
    platform_fee = _extract_platform_fee(data.get("Commissions", []) or [])
    external_reference = purchase.get("PaymentId") or payload.get("Id")

    existing_sale = session.scalar(
        select(Sale).where(Sale.workspace_id == workspace_id, Sale.external_reference == external_reference).limit(1)
    )

    status = SaleStatus.PENDING
    if event_name in {"Payment_Refund", "Payment_Chargeback", "Subscription_Canceled"}:
        status = SaleStatus.REFUNDED

    sale = upsert_sale(
        session,
        workspace_id,
        SaleCreate(
            id=existing_sale.id if existing_sale else None,
            client_id=client.id if client else None,
            project_label=offer.get("Name"),
            service_name=(products[0].get("Name") if products else offer.get("Name")),
            sale_kind=SaleKind.RECURRING if event_name == "Recurrent_Payment" else SaleKind.PRIMARY,
            scope=Scope.BUSINESS,
            platform=Platform.LASTLINK,
            payment_method=_map_payment_method(payment.get("PaymentMethod")),
            gross_amount=gross_amount,
            platform_fee_amount=platform_fee,
            payment_fee_amount=Decimal("0.00"),
            installment_count=int(payment.get("NumberOfInstallments", 1) or 1),
            sold_at=sold_at,
            expected_receipt_at=None,
            received_at=None,
            status=status,
            origin=utm.get("UtmMedium") or utm.get("UtmCampaign") or utm.get("UtmSource"),
            notes="Importado via webhook Lastlink. Requer conciliacao final de recebimento.",
            external_source="lastlink",
            external_reference=external_reference,
            external_event_name=event_name,
        ),
    )
    webhook.processing_status = "processed"
    webhook.processed_at = utc_now()
    session.flush()
    return LastlinkWebhookResult(webhook_event_id=webhook.id, client_id=client.id if client else None, sale_id=sale.id, status="processed")

