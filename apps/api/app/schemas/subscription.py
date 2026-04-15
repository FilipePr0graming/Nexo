from datetime import date
from decimal import Decimal

from app.models.enums import Scope, SubscriptionCycle
from app.schemas.common import ORMBaseModel, RecordMeta


class SubscriptionBase(ORMBaseModel):
    category_id: str | None = None
    account_id: str | None = None
    scope: Scope
    name: str
    responsible: str | None = None
    cycle: SubscriptionCycle = SubscriptionCycle.MONTHLY
    amount: Decimal
    renewal_date: date | None = None
    next_renewal_at: date | None = None
    reminder_days_before: int = 5
    notes: str | None = None
    is_active: bool = True


class SubscriptionCreate(SubscriptionBase):
    id: str | None = None


class SubscriptionUpdate(ORMBaseModel):
    category_id: str | None = None
    account_id: str | None = None
    scope: Scope | None = None
    name: str | None = None
    responsible: str | None = None
    cycle: SubscriptionCycle | None = None
    amount: Decimal | None = None
    renewal_date: date | None = None
    next_renewal_at: date | None = None
    reminder_days_before: int | None = None
    notes: str | None = None
    is_active: bool | None = None


class SubscriptionRead(SubscriptionBase, RecordMeta):
    workspace_id: str

