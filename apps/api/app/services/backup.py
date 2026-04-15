from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.entities import Account, Category, Client, Expense, IntegrationConnection, OwnerDraw, Sale, Subscription, SyncConflict, WebhookEvent, Workspace


def _serialize_rows(rows: list[object]) -> list[dict]:
    serialized: list[dict] = []
    for row in rows:
        serialized.append({column.name: getattr(row, column.name) for column in row.__table__.columns})
    return serialized


def build_backup_snapshot(session: Session) -> dict:
    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "workspaces": _serialize_rows(session.scalars(select(Workspace)).all()),
        "accounts": _serialize_rows(session.scalars(select(Account)).all()),
        "categories": _serialize_rows(session.scalars(select(Category)).all()),
        "clients": _serialize_rows(session.scalars(select(Client)).all()),
        "sales": _serialize_rows(session.scalars(select(Sale)).all()),
        "expenses": _serialize_rows(session.scalars(select(Expense)).all()),
        "subscriptions": _serialize_rows(session.scalars(select(Subscription)).all()),
        "owner_draws": _serialize_rows(session.scalars(select(OwnerDraw)).all()),
        "integration_connections": _serialize_rows(session.scalars(select(IntegrationConnection)).all()),
        "webhook_events": _serialize_rows(session.scalars(select(WebhookEvent)).all()),
        "sync_conflicts": _serialize_rows(session.scalars(select(SyncConflict)).all()),
    }


def write_backup_file(snapshot: dict) -> Path:
    backup_dir = Path(settings.backup_dir)
    backup_dir.mkdir(parents=True, exist_ok=True)
    filename = backup_dir / f"nexo-backup-{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')}.json"
    filename.write_text(json.dumps(snapshot, default=str, ensure_ascii=True, indent=2), encoding="utf-8")
    return filename
