from datetime import datetime, timezone
from enum import Enum


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class SessionType(str, Enum):
    individual = "individual"
    group = "group"


class MessageType(str, Enum):
    user = "user"
    system = "system"
    assistant = "assistant"


class MessageStatus(str, Enum):
    sent = "sent"
    delivered = "delivered"
    read = "read"


class NotificationType(str, Enum):
    match_request = "match_request"
    group_invite = "group_invite"
    message = "message"
    system = "system"
