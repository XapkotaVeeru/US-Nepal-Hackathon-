from datetime import datetime

from app.models.common import NotificationType
from app.schemas.common import APIModel


class NotificationRead(APIModel):
    id: str
    user_id: str
    type: NotificationType
    title: str
    message: str
    is_read: bool
    action_data: dict | None
    created_at: datetime
    updated_at: datetime


class NotificationReadUpdate(APIModel):
    is_read: bool = True
