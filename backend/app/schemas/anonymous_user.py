from datetime import datetime

from pydantic import Field

from app.schemas.common import APIModel


class AnonymousUserCreate(APIModel):
    display_name: str | None = Field(default=None, max_length=120)
    notifications_enabled: bool = True
    sound_enabled: bool = True
    chat_requests_enabled: bool = True
    group_invites_enabled: bool = True


class AnonymousUserUpsert(APIModel):
    display_name: str | None = Field(default=None, max_length=120)
    notifications_enabled: bool | None = None
    sound_enabled: bool | None = None
    chat_requests_enabled: bool | None = None
    group_invites_enabled: bool | None = None


class AnonymousUserRead(APIModel):
    id: str
    display_name: str
    is_active: bool
    notifications_enabled: bool
    sound_enabled: bool
    chat_requests_enabled: bool
    group_invites_enabled: bool
    created_at: datetime
    updated_at: datetime
