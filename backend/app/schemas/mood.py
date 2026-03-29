from datetime import datetime

from pydantic import Field

from app.schemas.common import APIModel


class MoodEntryCreate(APIModel):
    mood_level: int = Field(ge=1, le=5)
    note: str = Field(default="", max_length=500)


class MoodEntryRead(APIModel):
    id: str
    user_id: str
    mood_level: int
    note: str
    created_at: datetime
    updated_at: datetime


class MoodSummaryRead(APIModel):
    total_entries: int
    current_streak: int
    recent_average: float | None
    latest_entry: MoodEntryRead | None
