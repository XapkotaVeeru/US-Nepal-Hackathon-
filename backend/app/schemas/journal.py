from datetime import datetime

from pydantic import Field

from app.schemas.common import APIModel


class JournalEntryCreate(APIModel):
    title: str | None = Field(default=None, max_length=200)
    content: str = Field(min_length=1, max_length=5000)
    prompt: str | None = Field(default=None, max_length=300)


class JournalEntryRead(APIModel):
    id: str
    user_id: str
    title: str
    content: str
    prompt: str | None
    created_at: datetime
    updated_at: datetime
