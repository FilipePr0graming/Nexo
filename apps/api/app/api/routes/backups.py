from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.services.backup import build_backup_snapshot, write_backup_file

router = APIRouter()


@router.post("/export")
def export_backup(session: Session = Depends(get_session)) -> dict[str, str]:
    snapshot = build_backup_snapshot(session)
    path = write_backup_file(snapshot)
    return {"status": "ok", "path": str(path)}

