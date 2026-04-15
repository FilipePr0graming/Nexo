from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.entities import Account, Category, IntegrationConnection, Workspace
from app.models.enums import AccountKind, IntegrationMode, IntegrationProvider, IntegrationStatus, Scope


BUSINESS_CATEGORIES = [
    "Aluguel",
    "Luz",
    "Agua",
    "Internet da agencia",
    "Assinaturas de IA",
    "Softwares",
    "Ferramentas",
    "Marketing",
    "Fornecedores",
    "Impostos",
    "Alimentacao da empresa",
    "Outras despesas operacionais",
]

PERSONAL_CATEGORIES = [
    "Alimentacao",
    "Compras do mes",
    "Internet do celular",
    "Transporte",
    "Moradia",
    "Lazer",
    "Saude",
    "Assinaturas pessoais",
    "Outros",
]


def bootstrap_reference_data(session: Session) -> Workspace:
    workspace = session.scalar(select(Workspace).limit(1))
    if workspace is None:
        workspace = Workspace(
            name=settings.default_workspace_name,
            currency=settings.default_currency,
            timezone=settings.default_timezone,
            default_partner_name=settings.default_partner_name,
            default_partner_percent=settings.default_partner_percent,
        )
        session.add(workspace)
        session.flush()

    if not session.scalar(select(Account).where(Account.workspace_id == workspace.id).limit(1)):
        session.add_all(
            [
                Account(
                    workspace_id=workspace.id,
                    name="Conta empresa",
                    scope=Scope.BUSINESS,
                    kind=AccountKind.BANK,
                    institution="Principal",
                ),
                Account(
                    workspace_id=workspace.id,
                    name="Conta pessoal",
                    scope=Scope.PERSONAL,
                    kind=AccountKind.BANK,
                    institution="Principal",
                ),
            ]
        )

    if not session.scalar(select(Category).where(Category.workspace_id == workspace.id).limit(1)):
        session.add_all(
            [Category(workspace_id=workspace.id, scope=Scope.BUSINESS, name=name, system_default=True) for name in BUSINESS_CATEGORIES]
            + [Category(workspace_id=workspace.id, scope=Scope.PERSONAL, name=name, system_default=True) for name in PERSONAL_CATEGORIES]
        )

    existing_integrations = {
        item.provider for item in session.scalars(select(IntegrationConnection).where(IntegrationConnection.workspace_id == workspace.id)).all()
    }
    defaults = [
        (
            IntegrationProvider.LASTLINK,
            IntegrationMode.WEBHOOK,
            IntegrationStatus.STAGED,
            {"mvp_mode": "webhook_ingestion_only"},
        ),
        (
            IntegrationProvider.CORA,
            IntegrationMode.API,
            IntegrationStatus.DISCONNECTED,
            {"mvp_mode": "awaiting_credentials"},
        ),
        (
            IntegrationProvider.MERCADO_PAGO,
            IntegrationMode.WEBHOOK,
            IntegrationStatus.DISCONNECTED,
            {"mvp_mode": "future"},
        ),
    ]
    for provider, mode, status, config in defaults:
        if provider not in existing_integrations:
            session.add(
                IntegrationConnection(
                    workspace_id=workspace.id,
                    provider=provider,
                    mode=mode,
                    status=status,
                    config=config,
                )
            )

    session.commit()
    session.refresh(workspace)
    return workspace


def get_default_workspace(session: Session) -> Workspace:
    workspace = session.scalar(select(Workspace).limit(1))
    if workspace is None:
        workspace = bootstrap_reference_data(session)
    return workspace

