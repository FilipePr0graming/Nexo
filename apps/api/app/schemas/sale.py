from datetime import datetime
from decimal import Decimal

from pydantic import Field

from app.models.enums import PaymentMethod, Platform, SaleKind, SaleStatus, Scope
from app.schemas.common import ORMBaseModel, RecordMeta


class SaleBase(ORMBaseModel):
    client_id: str | None = None
    parent_sale_id: str | None = None
    destination_account_id: str | None = None
    project_label: str | None = None
    service_name: str | None = None
    sale_kind: SaleKind = SaleKind.PRIMARY
    scope: Scope = Scope.BUSINESS
    platform: Platform = Platform.OTHER
    payment_method: PaymentMethod = PaymentMethod.OTHER
    gross_amount: Decimal
    platform_fee_amount: Decimal = Decimal("0.00")
    payment_fee_amount: Decimal = Decimal("0.00")
    net_amount: Decimal | None = None
    installment_count: int = Field(default=1, ge=1)
    sold_at: datetime
    expected_receipt_at: datetime | None = None
    received_at: datetime | None = None
    status: SaleStatus = SaleStatus.PENDING
    notes: str | None = None
    origin: str | None = None
    daniel_involved: bool = False
    daniel_percent: Decimal = Decimal("30.00")
    commissionable_amount: Decimal | None = None
    daniel_amount: Decimal | None = None
    owner_net_amount: Decimal | None = None
    external_source: str | None = None
    external_reference: str | None = None
    external_event_name: str | None = None


class SaleCreate(SaleBase):
    id: str | None = None


class SaleUpdate(ORMBaseModel):
    client_id: str | None = None
    parent_sale_id: str | None = None
    destination_account_id: str | None = None
    project_label: str | None = None
    service_name: str | None = None
    sale_kind: SaleKind | None = None
    scope: Scope | None = None
    platform: Platform | None = None
    payment_method: PaymentMethod | None = None
    gross_amount: Decimal | None = None
    platform_fee_amount: Decimal | None = None
    payment_fee_amount: Decimal | None = None
    net_amount: Decimal | None = None
    installment_count: int | None = Field(default=None, ge=1)
    sold_at: datetime | None = None
    expected_receipt_at: datetime | None = None
    received_at: datetime | None = None
    status: SaleStatus | None = None
    notes: str | None = None
    origin: str | None = None
    daniel_involved: bool | None = None
    daniel_percent: Decimal | None = None
    commissionable_amount: Decimal | None = None
    daniel_amount: Decimal | None = None
    owner_net_amount: Decimal | None = None
    external_source: str | None = None
    external_reference: str | None = None
    external_event_name: str | None = None


class SaleRead(SaleBase, RecordMeta):
    workspace_id: str

