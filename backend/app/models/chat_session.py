from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import uuid4

from sqlalchemy import Column
from sqlalchemy.types import JSON
from sqlmodel import Field, Relationship, SQLModel

from app.models.common import SessionType, utc_now

if TYPE_CHECKING:
    from app.models.anonymous_user import AnonymousUser
    from app.models.message import Message


class ChatSession(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    owner_id: str = Field(foreign_key="anonymoususer.id", index=True)
    type: SessionType = Field(default=SessionType.group)
    name: str = Field(max_length=200)
    participant_ids: list[str] = Field(default_factory=list, sa_column=Column(JSON, nullable=False))
    last_message: str | None = Field(default=None, max_length=2000)
    last_message_time: datetime | None = Field(default=None)
    unread_count: int = Field(default=0, ge=0)
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)

    owner: "AnonymousUser" = Relationship(back_populates="chat_sessions")
    messages: list["Message"] = Relationship(back_populates="session")
