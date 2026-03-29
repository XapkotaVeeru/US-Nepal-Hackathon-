from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import uuid4

from sqlmodel import Field, Relationship, SQLModel

from app.models.common import utc_now

if TYPE_CHECKING:
    from app.models.anonymous_user import AnonymousUser


class MoodEntry(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    user_id: str = Field(foreign_key="anonymoususer.id", index=True)
    mood_level: int = Field(ge=1, le=5)
    note: str = Field(default="", max_length=500)
    created_at: datetime = Field(default_factory=utc_now, index=True)
    updated_at: datetime = Field(default_factory=utc_now)

    user: "AnonymousUser" = Relationship(back_populates="mood_entries")
