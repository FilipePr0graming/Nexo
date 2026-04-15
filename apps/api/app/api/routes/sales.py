from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.models.entities import Sale
from app.models.enums import Platform, SaleStatus
from app.schemas.sale import SaleCreate, SaleRead, SaleUpdate
from app.services.bootstrap import get_default_workspace
from app.services.records import upsert_sale

router = APIRouter()


@router.get("/", response_model=list[SaleRead])
def list_sales(
    status_filter: SaleStatus | None = Query(default=None, alias="status"),
    platform: Platform | None = None,
    client_id: str | None = None,
    start: datetime | None = None,
    end: datetime | None = None,
    session: Session = Depends(get_session),
) -> list[Sale]:
    stmt = select(Sale).where(Sale.deleted_at.is_(None))
    if status_filter:
        stmt = stmt.where(Sale.status == status_filter)
    if platform:
        stmt = stmt.where(Sale.platform == platform)
    if client_id:
        stmt = stmt.where(Sale.client_id == client_id)
    if start:
        stmt = stmt.where(Sale.sold_at >= start)
    if end:
        stmt = stmt.where(Sale.sold_at <= end)
    return session.scalars(stmt.order_by(Sale.sold_at.desc())).all()


@router.post("/", response_model=SaleRead, status_code=status.HTTP_201_CREATED)
def create_sale(payload: SaleCreate, session: Session = Depends(get_session)) -> Sale:
    workspace = get_default_workspace(session)
    try:
        sale = upsert_sale(session, workspace.id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    session.commit()
    session.refresh(sale)
    return sale


@router.put("/{sale_id}", response_model=SaleRead)
def update_sale(sale_id: str, payload: SaleUpdate, session: Session = Depends(get_session)) -> Sale:
    workspace = get_default_workspace(session)
    existing = session.get(Sale, sale_id)
    if existing is None or existing.deleted_at is not None:
        raise HTTPException(status_code=404, detail="Venda nao encontrada.")
    try:
        sale = upsert_sale(session, workspace.id, payload, sale_id=sale_id, base_revision=existing.revision)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    session.commit()
    session.refresh(sale)
    return sale
