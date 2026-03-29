from fastapi import HTTPException, status
from sqlmodel import Session, select

from app.models import JournalEntry
from app.models.common import utc_now
from app.schemas.journal import JournalEntryCreate
from app.services.users import get_user_or_404


def create_journal_entry(session: Session, user_id: str, payload: JournalEntryCreate) -> JournalEntry:
    get_user_or_404(session, user_id)
    content = payload.content.strip()
    title = (payload.title or _build_title(content)).strip()

    entry = JournalEntry(
        user_id=user_id,
        title=title,
        content=content,
        prompt=payload.prompt.strip() if payload.prompt else None,
    )
    session.add(entry)
    session.commit()
    session.refresh(entry)
    return entry


def list_journal_entries(session: Session, user_id: str) -> list[JournalEntry]:
    get_user_or_404(session, user_id)
    return session.exec(
        select(JournalEntry)
        .where(JournalEntry.user_id == user_id)
        .order_by(JournalEntry.created_at.desc())
    ).all()


def delete_journal_entry(session: Session, journal_id: str) -> None:
    entry = session.get(JournalEntry, journal_id)
    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal entry not found")

    session.delete(entry)
    session.commit()


def _build_title(content: str) -> str:
    lines = [line.strip() for line in content.splitlines() if line.strip()]
    first_line = lines[0] if lines else "Untitled Entry"
    return first_line if len(first_line) <= 40 else f"{first_line[:40]}..."
