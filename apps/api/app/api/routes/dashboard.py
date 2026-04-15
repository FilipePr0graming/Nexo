from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.schemas.dashboard import DashboardSummary
from app.services.dashboard import build_dashboard_summary

router = APIRouter()


@router.get("/", response_model=DashboardSummary)
def get_dashboard(
    start: datetime | None = None,
    end: datetime | None = None,
    session: Session = Depends(get_session),
) -> DashboardSummary:
    return build_dashboard_summary(session, start=start, end=end)

