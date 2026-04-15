from datetime import datetime
from typing import Any

from app.models.enums import SyncOperation
from app.schemas.common import ORMBaseModel


class SyncMutation(ORMBaseModel):
    entity: str
    operation: SyncOperation = SyncOperation.UPSERT
    base_revision: int | None = None
    payload: dict[str, Any]


class SyncPushRequest(ORMBaseModel):
    device_id: str
    mutations: list[SyncMutation]


class SyncAppliedItem(ORMBaseModel):
    entity: str
    record_id: str | None = None
    revision: int | None = None
    updated_at: datetime | None = None
    status: str
    message: str | None = None
    conflict_id: str | None = None


class SyncEnvelope(ORMBaseModel):
    entity: str
    operation: SyncOperation
    revision: int
    updated_at: datetime
    payload: dict[str, Any]


class SyncPullResponse(ORMBaseModel):
    cursor: datetime
    changes: list[SyncEnvelope]
    open_conflict_ids: list[str]

