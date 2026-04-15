from datetime import datetime
from typing import Any

from app.models.enums import IntegrationMode, IntegrationProvider, IntegrationStatus
from app.schemas.common import ORMBaseModel, RecordMeta


class IntegrationConnectionRead(RecordMeta):
    workspace_id: str
    provider: IntegrationProvider
    mode: IntegrationMode
    status: IntegrationStatus
    external_account_label: str | None = None
    config: dict[str, Any]
    last_sync_at: datetime | None = None
    last_error: str | None = None


class ProviderCapability(ORMBaseModel):
    provider: IntegrationProvider
    supports_webhooks: bool
    supports_pull_api: bool
    supports_balance: bool
    supports_statement: bool
    status: str
    notes: str

