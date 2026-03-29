from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import uuid4

from sqlmodel import Field, Relationship, SQLModel

from app.models.common import utc_now

if TYPE_CHECKING:
    from app.models.chat_session import ChatSession
    from app.models.journal_entry import JournalEntry
    from app.models.message import Message
    from app.models.mood_entry import MoodEntry
    from app.models.notification import Notification


class AnonymousUser(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    display_name: str = Field(index=True, max_length=120)
    is_active: bool = Field(default=True)
    notifications_enabled: bool = Field(default=True)
    sound_enabled: bool = Field(default=True)
    chat_requests_enabled: bool = Field(default=True)
    group_invites_enabled: bool = Field(default=True)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)

    mood_entries: list["MoodEntry"] = Relationship(back_populates="user")
    journal_entries: list["JournalEntry"] = Relationship(back_populates="user")
    chat_sessions: list["ChatSession"] = Relationship(back_populates="owner")
    sent_messages: list["Message"] = Relationship(back_populates="sender")
    notifications: list["Notification"] = Relationship(back_populates="user")
