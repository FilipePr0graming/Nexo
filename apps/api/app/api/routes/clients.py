from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.models.entities import Client
from app.schemas.client import ClientCreate, ClientRead, ClientUpdate
from app.services.bootstrap import get_default_workspace
from app.services.records import upsert_client

router = APIRouter()


@router.get("/", response_model=list[ClientRead])
def list_clients(
    search: str | None = Query(default=None),
    session: Session = Depends(get_session),
) -> list[Client]:
    stmt = select(Client).where(Client.deleted_at.is_(None))
    if search:
        stmt = stmt.where(Client.name.ilike(f"%{search}%"))
    return session.scalars(stmt.order_by(Client.updated_at.desc())).all()


@router.post("/", response_model=ClientRead, status_code=status.HTTP_201_CREATED)
def create_client(payload: ClientCreate, session: Session = Depends(get_session)) -> Client:
    workspace = get_default_workspace(session)
    client = upsert_client(session, workspace.id, payload)
    session.commit()
    session.refresh(client)
    return client


@router.put("/{client_id}", response_model=ClientRead)
def update_client(client_id: str, payload: ClientUpdate, session: Session = Depends(get_session)) -> Client:
    workspace = get_default_workspace(session)
    existing = session.get(Client, client_id)
    if existing is None or existing.deleted_at is not None:
        raise HTTPException(status_code=404, detail="Cliente nao encontrado.")
    client = upsert_client(session, workspace.id, payload, client_id=client_id, base_revision=existing.revision)
    session.commit()
    session.refresh(client)
    return client

