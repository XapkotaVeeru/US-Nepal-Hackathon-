from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import uuid4

from sqlalchemy import Column
from sqlalchemy.types import JSON
from sqlmodel import Field, Relationship, SQLModel

from app.models.common import NotificationType, utc_now

if TYPE_CHECKING:
    from app.models.anonymous_user import AnonymousUser


class Notification(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    user_id: str = Field(foreign_key="anonymoususer.id", index=True)
    type: NotificationType = Field(default=NotificationType.system)
    title: str = Field(max_length=200)
    message: str = Field(max_length=1000)
    is_read: bool = Field(default=False)
    action_data: dict | None = Field(default=None, sa_column=Column(JSON, nullable=True))
    created_at: datetime = Field(default_factory=utc_now, index=True)
    updated_at: datetime = Field(default_factory=utc_now)

    user: "AnonymousUser" = Relationship(back_populates="notifications")
