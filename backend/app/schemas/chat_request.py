from datetime import datetime

from pydantic import Field

from app.models.common import ChatRequestStatus
from app.schemas.common import APIModel


class ChatRequestCreate(APIModel):
    from_user_id: str
    to_user_id: str
    context_summary: str | None = Field(default=None, max_length=500)
    matched_themes: list[str] = Field(default_factory=list)
    support_category: str | None = None
    user_category: str | None = None


class ChatRequestRead(APIModel):
    id: str
    from_user_id: str
    to_user_id: str
    session_id: str
    status: ChatRequestStatus
    context_summary: str | None
    matched_themes: list[str]
    support_category: str | None
    user_category: str | None
    created_at: datetime
    updated_at: datetime
