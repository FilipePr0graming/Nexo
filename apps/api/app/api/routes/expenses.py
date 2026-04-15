from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.models.entities import Expense
from app.models.enums import Scope
from app.schemas.expense import ExpenseCreate, ExpenseRead, ExpenseUpdate
from app.services.bootstrap import get_default_workspace
from app.services.records import upsert_expense

router = APIRouter()


@router.get("/", response_model=list[ExpenseRead])
def list_expenses(
    scope: Scope | None = None,
    start: datetime | None = None,
    end: datetime | None = None,
    session: Session = Depends(get_session),
) -> list[Expense]:
    stmt = select(Expense).where(Expense.deleted_at.is_(None))
    if scope:
        stmt = stmt.where(Expense.scope == scope)
    if start:
        stmt = stmt.where(Expense.occurred_at >= start)
    if end:
        stmt = stmt.where(Expense.occurred_at <= end)
    return session.scalars(stmt.order_by(Expense.occurred_at.desc())).all()


@router.post("/", response_model=ExpenseRead, status_code=status.HTTP_201_CREATED)
def create_expense(payload: ExpenseCreate, session: Session = Depends(get_session)) -> Expense:
    workspace = get_default_workspace(session)
    expense = upsert_expense(session, workspace.id, payload)
    session.commit()
    session.refresh(expense)
    return expense


@router.put("/{expense_id}", response_model=ExpenseRead)
def update_expense(expense_id: str, payload: ExpenseUpdate, session: Session = Depends(get_session)) -> Expense:
    workspace = get_default_workspace(session)
    existing = session.get(Expense, expense_id)
    if existing is None or existing.deleted_at is not None:
        raise HTTPException(status_code=404, detail="Gasto nao encontrado.")
    expense = upsert_expense(session, workspace.id, payload, expense_id=expense_id, base_revision=existing.revision)
    session.commit()
    session.refresh(expense)
    return expense

