from datetime import datetime

from pydantic import Field

from app.schemas.common import APIModel


class AnonymousUserCreate(APIModel):
    display_name: str | None = Field(default=None, max_length=120)


class AnonymousUserRead(APIModel):
    id: str
    display_name: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
