from pydantic import Field

from app.schemas.common import APIModel


class AIPlaceholderRequest(APIModel):
    user_id: str | None = None
    text: str = Field(min_length=1, max_length=5000)
