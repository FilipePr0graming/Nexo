from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from sqlalchemy.orm import Session

from app.models.base import utc_now
from app.models.entities import Client, Expense, OwnerDraw, Sale, Subscription, SyncConflict
from app.models.enums import ConflictStatus
from app.schemas.client import ClientCreate, ClientUpdate
from app.schemas.expense import ExpenseCreate, ExpenseUpdate
from app.schemas.owner_draw import OwnerDrawCreate
from app.schemas.sale import SaleCreate, SaleUpdate
from app.schemas.subscription import SubscriptionCreate, SubscriptionUpdate
from app.services.commission import calculate_sale_financials


@dataclass(slots=True)
class RevisionConflictError(Exception):
    conflict_id: str
    message: str


def _register_conflict(
    session: Session,
    *,
    workspace_id: str,
    entity_type: str,
    entity_id: str,
    server_revision: int,
    client_revision: int,
    client_payload: dict[str, Any],
    server_payload: dict[str, Any],
) -> str:
    conflict = SyncConflict(
        workspace_id=workspace_id,
        entity_type=entity_type,
        entity_id=entity_id,
        server_revision=server_revision,
        client_revision=client_revision,
        client_payload=client_payload,
        server_payload=server_payload,
        status=ConflictStatus.OPEN,
    )
    session.add(conflict)
    session.flush()
    return conflict.id


def _ensure_revision(existing: Any, base_revision: int | None, entity_type: str, payload: dict[str, Any], session: Session) -> None:
    if existing is None or base_revision is None:
        return
    if existing.revision != base_revision:
        conflict_id = _register_conflict(
            session,
            workspace_id=existing.workspace_id,
            entity_type=entity_type,
            entity_id=existing.id,
            server_revision=existing.revision,
            client_revision=base_revision,
            client_payload=payload,
            server_payload={column.name: getattr(existing, column.name) for column in existing.__table__.columns},
        )
        raise RevisionConflictError(conflict_id=conflict_id, message=f"Conflito de revisao em {entity_type}:{existing.id}")


def _apply_common_update(instance: Any, data: dict[str, Any], *, device_id: str | None = None) -> Any:
    for key, value in data.items():
        setattr(instance, key, value)
    instance.revision += 1
    instance.updated_at = utc_now()
    instance.last_device_id = device_id
    return instance


def upsert_client(
    session: Session,
    workspace_id: str,
    payload: ClientCreate | ClientUpdate | dict[str, Any],
    *,
    client_id: str | None = None,
    base_revision: int | None = None,
    device_id: str | None = None,
) -> Client:
    data = payload.model_dump(exclude_unset=True) if not isinstance(payload, dict) else payload
    record_id = client_id or data.get("id")
    existing = session.get(Client, record_id) if record_id else None
    _ensure_revision(existing, base_revision, "clients", data, session)
    if existing is None:
        model = ClientCreate.model_validate(data)
        instance = Client(workspace_id=workspace_id, **model.model_dump(exclude={"id"}, exclude_none=False))
        if model.id:
            instance.id = model.id
        instance.last_device_id = device_id
        session.add(instance)
        session.flush()
        return instance

    update = ClientUpdate.model_validate(data).model_dump(exclude_unset=True)
    return _apply_common_update(existing, update, device_id=device_id)


def upsert_sale(
    session: Session,
    workspace_id: str,
    payload: SaleCreate | SaleUpdate | dict[str, Any],
    *,
    sale_id: str | None = None,
    base_revision: int | None = None,
    device_id: str | None = None,
) -> Sale:
    data = payload.model_dump(exclude_unset=True) if not isinstance(payload, dict) else payload
    record_id = sale_id or data.get("id")
    existing = session.get(Sale, record_id) if record_id else None
    _ensure_revision(existing, base_revision, "sales", data, session)

    validated_input = SaleCreate.model_validate(data) if existing is None else SaleUpdate.model_validate(data)
    values = validated_input.model_dump(exclude_unset=True)
    financials = calculate_sale_financials(
        gross_amount=values.get("gross_amount", existing.gross_amount if existing else 0),
        platform_fee_amount=values.get("platform_fee_amount", existing.platform_fee_amount if existing else 0),
        payment_fee_amount=values.get("payment_fee_amount", existing.payment_fee_amount if existing else 0),
        net_amount=values.get("net_amount", existing.net_amount if existing else None),
        daniel_involved=values.get("daniel_involved", existing.daniel_involved if existing else False),
        daniel_percent=values.get("daniel_percent", existing.daniel_percent if existing else 30),
        commissionable_amount=values.get("commissionable_amount", existing.commissionable_amount if existing else None),
    )
    values["net_amount"] = financials.net_amount
    values["commissionable_amount"] = financials.commissionable_amount
    values["daniel_amount"] = financials.daniel_amount
    values["owner_net_amount"] = financials.owner_net_amount

    if existing is None:
        instance = Sale(workspace_id=workspace_id, **values)
        if values.get("id"):
            instance.id = values["id"]
        instance.last_device_id = device_id
        session.add(instance)
        session.flush()
        return instance

    return _apply_common_update(existing, values, device_id=device_id)


def upsert_expense(
    session: Session,
    workspace_id: str,
    payload: ExpenseCreate | ExpenseUpdate | dict[str, Any],
    *,
    expense_id: str | None = None,
    base_revision: int | None = None,
    device_id: str | None = None,
) -> Expense:
    data = payload.model_dump(exclude_unset=True) if not isinstance(payload, dict) else payload
    record_id = expense_id or data.get("id")
    existing = session.get(Expense, record_id) if record_id else None
    _ensure_revision(existing, base_revision, "expenses", data, session)
    if existing is None:
        model = ExpenseCreate.model_validate(data)
        instance = Expense(workspace_id=workspace_id, **model.model_dump(exclude={"id"}))
        if model.id:
            instance.id = model.id
        instance.last_device_id = device_id
        session.add(instance)
        session.flush()
        return instance

    values = ExpenseUpdate.model_validate(data).model_dump(exclude_unset=True)
    return _apply_common_update(existing, values, device_id=device_id)


def upsert_subscription(
    session: Session,
    workspace_id: str,
    payload: SubscriptionCreate | SubscriptionUpdate | dict[str, Any],
    *,
    subscription_id: str | None = None,
    base_revision: int | None = None,
    device_id: str | None = None,
) -> Subscription:
    data = payload.model_dump(exclude_unset=True) if not isinstance(payload, dict) else payload
    record_id = subscription_id or data.get("id")
    existing = session.get(Subscription, record_id) if record_id else None
    _ensure_revision(existing, base_revision, "subscriptions", data, session)
    if existing is None:
        model = SubscriptionCreate.model_validate(data)
        instance = Subscription(workspace_id=workspace_id, **model.model_dump(exclude={"id"}))
        if model.id:
            instance.id = model.id
        instance.last_device_id = device_id
        session.add(instance)
        session.flush()
        return instance

    values = SubscriptionUpdate.model_validate(data).model_dump(exclude_unset=True)
    return _apply_common_update(existing, values, device_id=device_id)


def upsert_owner_draw(
    session: Session,
    workspace_id: str,
    payload: OwnerDrawCreate | dict[str, Any],
    *,
    base_revision: int | None = None,
    device_id: str | None = None,
) -> OwnerDraw:
    data = payload.model_dump(exclude_unset=True) if not isinstance(payload, dict) else payload
    record_id = data.get("id")
    existing = session.get(OwnerDraw, record_id) if record_id else None
    _ensure_revision(existing, base_revision, "owner_draws", data, session)
    if existing is None:
        model = OwnerDrawCreate.model_validate(data)
        instance = OwnerDraw(workspace_id=workspace_id, **model.model_dump(exclude={"id"}))
        if model.id:
            instance.id = model.id
        instance.last_device_id = device_id
        session.add(instance)
        session.flush()
        return instance

    values = OwnerDrawCreate.model_validate(data).model_dump(exclude_unset=True, exclude={"id"})
    return _apply_common_update(existing, values, device_id=device_id)


def soft_delete_record(session: Session, model: Any, record_id: str, *, base_revision: int | None = None, device_id: str | None = None) -> Any:
    existing = session.get(model, record_id)
    if existing is None:
        return None
    _ensure_revision(existing, base_revision, model.__tablename__, {"id": record_id}, session)
    existing.deleted_at = utc_now()
    existing.updated_at = utc_now()
    existing.revision += 1
    existing.last_device_id = device_id
    return existing

