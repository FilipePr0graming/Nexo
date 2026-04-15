from datetime import datetime
from decimal import Decimal

from app.models.enums import Scope
from app.schemas.common import ORMBaseModel, RecordMeta


class ExpenseBase(ORMBaseModel):
    category_id: str | None = None
    paid_from_account_id: str | None = None
    scope: Scope
    description: str
    subcategory_name: str | None = None
    amount: Decimal
    occurred_at: datetime
    recurrence_rule: str | None = None
    vendor_name: str | None = None
    notes: str | None = None


class ExpenseCreate(ExpenseBase):
    id: str | None = None


class ExpenseUpdate(ORMBaseModel):
    category_id: str | None = None
    paid_from_account_id: str | None = None
    scope: Scope | None = None
    description: str | None = None
    subcategory_name: str | None = None
    amount: Decimal | None = None
    occurred_at: datetime | None = None
    recurrence_rule: str | None = None
    vendor_name: str | None = None
    notes: str | None = None


class ExpenseRead(ExpenseBase, RecordMeta):
    workspace_id: str

