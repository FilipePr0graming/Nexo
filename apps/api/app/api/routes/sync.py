from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.schemas.sync import SyncAppliedItem, SyncPullResponse, SyncPushRequest
from app.services.bootstrap import get_default_workspace
from app.services.sync import pull_changes, push_changes

router = APIRouter()


@router.post("/push", response_model=list[SyncAppliedItem])
def sync_push(payload: SyncPushRequest, session: Session = Depends(get_session)) -> list[SyncAppliedItem]:
    workspace = get_default_workspace(session)
    return push_changes(session, workspace.id, payload)


@router.get("/pull", response_model=SyncPullResponse)
def sync_pull(updated_since: datetime | None = None, session: Session = Depends(get_session)) -> SyncPullResponse:
    return pull_changes(session, updated_since=updated_since)

