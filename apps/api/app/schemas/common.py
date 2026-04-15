from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class ORMBaseModel(BaseModel):
    model_config = ConfigDict(from_attributes=True, use_enum_values=True)


class RecordMeta(ORMBaseModel):
    id: str
    revision: int
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None = None


class MonetarySummary(ORMBaseModel):
    value: Decimal
    label: str

