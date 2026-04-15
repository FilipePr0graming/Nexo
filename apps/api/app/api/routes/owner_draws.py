from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.models.entities import OwnerDraw
from app.schemas.owner_draw import OwnerDrawCreate, OwnerDrawRead
from app.services.bootstrap import get_default_workspace
from app.services.records import upsert_owner_draw

router = APIRouter()


@router.get("/", response_model=list[OwnerDrawRead])
def list_owner_draws(session: Session = Depends(get_session)) -> list[OwnerDraw]:
    return session.scalars(select(OwnerDraw).where(OwnerDraw.deleted_at.is_(None)).order_by(OwnerDraw.occurred_at.desc())).all()


@router.post("/", response_model=OwnerDrawRead, status_code=status.HTTP_201_CREATED)
def create_owner_draw(payload: OwnerDrawCreate, session: Session = Depends(get_session)) -> OwnerDraw:
    workspace = get_default_workspace(session)
    record = upsert_owner_draw(session, workspace.id, payload)
    session.commit()
    session.refresh(record)
    return record

