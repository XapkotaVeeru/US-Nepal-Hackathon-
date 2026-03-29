from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import uuid4

from sqlmodel import Field, Relationship, SQLModel

from app.models.common import MessageStatus, MessageType, utc_now

if TYPE_CHECKING:
    from app.models.anonymous_user import AnonymousUser
    from app.models.chat_session import ChatSession


class Message(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    session_id: str = Field(foreign_key="chatsession.id", index=True)
    sender_id: str = Field(foreign_key="anonymoususer.id", index=True)
    sender_name: str = Field(max_length=120)
    content: str = Field(max_length=4000)
    type: MessageType = Field(default=MessageType.user)
    status: MessageStatus = Field(default=MessageStatus.sent)
    is_read: bool = Field(default=False)
    created_at: datetime = Field(default_factory=utc_now, index=True)
    updated_at: datetime = Field(default_factory=utc_now)

    session: "ChatSession" = Relationship(back_populates="messages")
    sender: "AnonymousUser" = Relationship(back_populates="sent_messages")
