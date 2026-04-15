from datetime import datetime
from decimal import Decimal

from app.schemas.common import ORMBaseModel, RecordMeta


class OwnerDrawBase(ORMBaseModel):
    from_account_id: str | None = None
    to_account_id: str | None = None
    amount: Decimal
    occurred_at: datetime
    notes: str | None = None


class OwnerDrawCreate(OwnerDrawBase):
    id: str | None = None


class OwnerDrawRead(OwnerDrawBase, RecordMeta):
    workspace_id: str

