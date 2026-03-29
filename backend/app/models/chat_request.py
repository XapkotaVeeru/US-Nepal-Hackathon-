from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from sqlalchemy import Column
from sqlalchemy.types import JSON
from sqlmodel import Field, SQLModel

from app.models.common import ChatRequestStatus, utc_now


class ChatRequest(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    from_user_id: str = Field(foreign_key="anonymoususer.id", index=True)
    to_user_id: str = Field(foreign_key="anonymoususer.id", index=True)
    session_id: str = Field(foreign_key="chatsession.id", index=True)
    status: ChatRequestStatus = Field(default=ChatRequestStatus.pending)
    context_summary: str | None = Field(default=None, max_length=500)
    matched_themes: list[str] = Field(default_factory=list, sa_column=Column(JSON, nullable=False))
    support_category: str | None = Field(default=None, max_length=80)
    user_category: str | None = Field(default=None, max_length=80)
    created_at: datetime = Field(default_factory=utc_now, index=True)
    updated_at: datetime = Field(default_factory=utc_now)
