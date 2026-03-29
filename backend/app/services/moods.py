from datetime import timedelta

from fastapi import HTTPException, status
from sqlmodel import Session, select

from app.models import MoodEntry
from app.models.common import utc_now
from app.schemas.mood import MoodEntryCreate
from app.services.users import get_user_or_404


def create_mood_entry(session: Session, user_id: str, payload: MoodEntryCreate) -> MoodEntry:
    get_user_or_404(session, user_id)

    start_of_today = _start_of_day(utc_now())
    existing = session.exec(select(MoodEntry).where(MoodEntry.user_id == user_id)).all()
    if any(_start_of_day(entry.created_at) == start_of_today for entry in existing):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Mood already logged for today",
        )

    entry = MoodEntry(user_id=user_id, mood_level=payload.mood_level, note=payload.note.strip())
    session.add(entry)
    session.commit()
    session.refresh(entry)
    return entry


def list_mood_entries(session: Session, user_id: str) -> list[MoodEntry]:
    get_user_or_404(session, user_id)
    return session.exec(
        select(MoodEntry)
        .where(MoodEntry.user_id == user_id)
        .order_by(MoodEntry.created_at.desc())
    ).all()


def get_recent_mood_summary(session: Session, user_id: str) -> dict:
    entries = list_mood_entries(session, user_id)
    latest_entry = entries[0] if entries else None
    recent_cutoff = utc_now() - timedelta(days=7)
    recent_entries = [entry for entry in entries if entry.created_at >= recent_cutoff]
    recent_average = None
    if recent_entries:
        recent_average = round(
            sum(entry.mood_level for entry in recent_entries) / len(recent_entries),
            2,
        )

    return {
        "total_entries": len(entries),
        "current_streak": _current_streak(entries),
        "recent_average": recent_average,
        "latest_entry": latest_entry,
    }


def _current_streak(entries: list[MoodEntry]) -> int:
    if not entries:
        return 0

    unique_days = sorted({_start_of_day(entry.created_at) for entry in entries}, reverse=True)
    today = _start_of_day(utc_now())
    yesterday = today - timedelta(days=1)
    if unique_days[0] not in {today, yesterday}:
        return 0

    streak = 1
    for index in range(1, len(unique_days)):
        if unique_days[index - 1] - unique_days[index] == timedelta(days=1):
            streak += 1
        else:
            break
    return streak


def _start_of_day(timestamp):
    return timestamp.replace(hour=0, minute=0, second=0, microsecond=0)
