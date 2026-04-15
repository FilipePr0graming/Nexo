from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import Client, Expense, OwnerDraw, Sale, Subscription, SyncConflict
from app.models.enums import ConflictStatus, SyncOperation
from app.schemas.client import ClientRead
from app.schemas.expense import ExpenseRead
from app.schemas.owner_draw import OwnerDrawRead
from app.schemas.sale import SaleRead
from app.schemas.subscription import SubscriptionRead
from app.schemas.sync import SyncAppliedItem, SyncEnvelope, SyncPullResponse, SyncPushRequest
from app.services.records import (
    RevisionConflictError,
    soft_delete_record,
    upsert_client,
    upsert_expense,
    upsert_owner_draw,
    upsert_sale,
    upsert_subscription,
)


SYNC_MODELS: dict[str, tuple[Any, Any]] = {
    "clients": (Client, ClientRead),
    "sales": (Sale, SaleRead),
    "expenses": (Expense, ExpenseRead),
    "subscriptions": (Subscription, SubscriptionRead),
    "owner_draws": (OwnerDraw, OwnerDrawRead),
}


def _serialize(schema_cls: Any, instance: Any) -> dict[str, Any]:
    return schema_cls.model_validate(instance).model_dump(mode="json")


def push_changes(session: Session, workspace_id: str, request: SyncPushRequest) -> list[SyncAppliedItem]:
    results: list[SyncAppliedItem] = []
    for mutation in request.mutations:
        if mutation.entity not in SYNC_MODELS:
            results.append(SyncAppliedItem(entity=mutation.entity, status="ignored", message="Entidade nao suportada."))
            continue
        model, _ = SYNC_MODELS[mutation.entity]
        try:
            if mutation.operation == SyncOperation.DELETE:
                record = soft_delete_record(
                    session,
                    model,
                    mutation.payload["id"],
                    base_revision=mutation.base_revision,
                    device_id=request.device_id,
                )
            elif mutation.entity == "clients":
                record = upsert_client(
                    session,
                    workspace_id,
                    mutation.payload,
                    base_revision=mutation.base_revision,
                    device_id=request.device_id,
                )
            elif mutation.entity == "sales":
                record = upsert_sale(
                    session,
                    workspace_id,
                    mutation.payload,
                    base_revision=mutation.base_revision,
                    device_id=request.device_id,
                )
            elif mutation.entity == "expenses":
                record = upsert_expense(
                    session,
                    workspace_id,
                    mutation.payload,
                    base_revision=mutation.base_revision,
                    device_id=request.device_id,
                )
            elif mutation.entity == "subscriptions":
                record = upsert_subscription(
                    session,
                    workspace_id,
                    mutation.payload,
                    base_revision=mutation.base_revision,
                    device_id=request.device_id,
                )
            else:
                record = upsert_owner_draw(
                    session,
                    workspace_id,
                    mutation.payload,
                    base_revision=mutation.base_revision,
                    device_id=request.device_id,
                )
            if record is None:
                results.append(SyncAppliedItem(entity=mutation.entity, status="missing", message="Registro nao encontrado."))
            else:
                results.append(
                    SyncAppliedItem(
                        entity=mutation.entity,
                        record_id=record.id,
                        revision=record.revision,
                        updated_at=record.updated_at,
                        status="applied",
                    )
                )
        except RevisionConflictError as exc:
            results.append(
                SyncAppliedItem(
                    entity=mutation.entity,
                    status="conflict",
                    message=exc.message,
                    conflict_id=exc.conflict_id,
                )
            )
        except ValueError as exc:
            results.append(
                SyncAppliedItem(
                    entity=mutation.entity,
                    status="invalid",
                    message=str(exc),
                )
            )
    session.commit()
    return results


def pull_changes(session: Session, *, updated_since: datetime | None = None) -> SyncPullResponse:
    cursor = updated_since or datetime.fromtimestamp(0, timezone.utc)
    changes: list[SyncEnvelope] = []

    for entity_name, (model, schema_cls) in SYNC_MODELS.items():
        rows = session.scalars(select(model).where(model.updated_at > cursor)).all()
        for row in rows:
            changes.append(
                SyncEnvelope(
                    entity=entity_name,
                    operation=SyncOperation.DELETE if row.deleted_at else SyncOperation.UPSERT,
                    revision=row.revision,
                    updated_at=row.updated_at,
                    payload=_serialize(schema_cls, row),
                )
            )

    changes.sort(key=lambda item: item.updated_at)
    open_conflict_ids = [
        conflict.id
        for conflict in session.scalars(select(SyncConflict).where(SyncConflict.status == ConflictStatus.OPEN)).all()
    ]
    next_cursor = changes[-1].updated_at if changes else datetime.now(timezone.utc)
    return SyncPullResponse(cursor=next_cursor, changes=changes, open_conflict_ids=open_conflict_ids)
