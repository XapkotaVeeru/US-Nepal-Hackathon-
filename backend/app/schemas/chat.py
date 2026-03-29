from datetime import datetime

from pydantic import Field

from app.models.common import MessageStatus, MessageType, SessionType
from app.schemas.common import APIModel


class ChatSessionCreate(APIModel):
    name: str = Field(min_length=1, max_length=200)
    type: SessionType = SessionType.group
    participant_ids: list[str] = Field(default_factory=list)


class ChatSessionRead(APIModel):
    id: str
    owner_id: str
    type: SessionType
    name: str
    participant_ids: list[str]
    last_message: str | None
    last_message_time: datetime | None
    unread_count: int
    is_active: bool
    created_at: datetime
    updated_at: datetime


class MessageCreate(APIModel):
    sender_id: str
    sender_name: str = Field(min_length=1, max_length=120)
    content: str = Field(min_length=1, max_length=4000)
    type: MessageType = MessageType.user


class MessageRead(APIModel):
    id: str
    session_id: str
    sender_id: str
    sender_name: str
    content: str
    type: MessageType
    status: MessageStatus
    is_read: bool
    created_at: datetime
    updated_at: datetime
