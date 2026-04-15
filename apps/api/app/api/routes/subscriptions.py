from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.models.entities import Subscription
from app.schemas.subscription import SubscriptionCreate, SubscriptionRead, SubscriptionUpdate
from app.services.bootstrap import get_default_workspace
from app.services.records import upsert_subscription

router = APIRouter()


@router.get("/", response_model=list[SubscriptionRead])
def list_subscriptions(session: Session = Depends(get_session)) -> list[Subscription]:
    return session.scalars(select(Subscription).where(Subscription.deleted_at.is_(None)).order_by(Subscription.updated_at.desc())).all()


@router.post("/", response_model=SubscriptionRead, status_code=status.HTTP_201_CREATED)
def create_subscription(payload: SubscriptionCreate, session: Session = Depends(get_session)) -> Subscription:
    workspace = get_default_workspace(session)
    record = upsert_subscription(session, workspace.id, payload)
    session.commit()
    session.refresh(record)
    return record


@router.put("/{subscription_id}", response_model=SubscriptionRead)
def update_subscription(subscription_id: str, payload: SubscriptionUpdate, session: Session = Depends(get_session)) -> Subscription:
    workspace = get_default_workspace(session)
    existing = session.get(Subscription, subscription_id)
    if existing is None or existing.deleted_at is not None:
        raise HTTPException(status_code=404, detail="Assinatura nao encontrada.")
    record = upsert_subscription(session, workspace.id, payload, subscription_id=subscription_id, base_revision=existing.revision)
    session.commit()
    session.refresh(record)
    return record

