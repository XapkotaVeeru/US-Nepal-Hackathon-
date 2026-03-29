from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import uuid4

from sqlmodel import Field, Relationship, SQLModel

from app.models.common import utc_now

if TYPE_CHECKING:
    from app.models.anonymous_user import AnonymousUser


class JournalEntry(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    user_id: str = Field(foreign_key="anonymoususer.id", index=True)
    title: str = Field(max_length=200)
    content: str = Field(max_length=5000)
    prompt: str | None = Field(default=None, max_length=300)
    created_at: datetime = Field(default_factory=utc_now, index=True)
    updated_at: datetime = Field(default_factory=utc_now)

    user: "AnonymousUser" = Relationship(back_populates="journal_entries")
