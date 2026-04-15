from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.models.entities import IntegrationConnection
from app.models.enums import IntegrationProvider
from app.schemas.integration import IntegrationConnectionRead, ProviderCapability
from app.services.bootstrap import get_default_workspace
from app.services.integrations.cora import build_cora_direct_auth_request
from app.services.integrations.lastlink import ingest_lastlink_webhook

router = APIRouter()


@router.get("/connections", response_model=list[IntegrationConnectionRead])
def list_connections(session: Session = Depends(get_session)) -> list[IntegrationConnection]:
    return session.scalars(select(IntegrationConnection).order_by(IntegrationConnection.provider.asc())).all()


@router.get("/capabilities", response_model=list[ProviderCapability])
def capabilities() -> list[ProviderCapability]:
    cora_auth = build_cora_direct_auth_request()
    return [
        ProviderCapability(
            provider=IntegrationProvider.LASTLINK,
            supports_webhooks=True,
            supports_pull_api=False,
            supports_balance=False,
            supports_statement=False,
            status="mvp_ready",
            notes="Usa webhooks oficiais para criar rascunhos de vendas e clientes.",
        ),
        ProviderCapability(
            provider=IntegrationProvider.CORA,
            supports_webhooks=True,
            supports_pull_api=True,
            supports_balance=True,
            supports_statement=True,
            status="awaiting_credentials",
            notes=f"Requer credenciais oficiais e mTLS. Endpoint de token esperado: {cora_auth.token_url}",
        ),
        ProviderCapability(
            provider=IntegrationProvider.MERCADO_PAGO,
            supports_webhooks=True,
            supports_pull_api=True,
            supports_balance=False,
            supports_statement=False,
            status="future",
            notes="Slot preparado para pagamentos/notificacoes futuras.",
        ),
    ]


@router.post("/webhooks/lastlink")
async def lastlink_webhook(request: Request, session: Session = Depends(get_session)) -> dict[str, Any]:
    workspace = get_default_workspace(session)
    payload = await request.json()
    result = ingest_lastlink_webhook(session, workspace.id, payload)
    session.commit()
    return {
        "status": result.status,
        "webhook_event_id": result.webhook_event_id,
        "client_id": result.client_id,
        "sale_id": result.sale_id,
    }

