from fastapi import HTTPException, status
from sqlmodel import Session, select

from app.models import Notification
from app.models.common import utc_now
from app.services.users import get_user_or_404


def list_notifications(session: Session, user_id: str) -> list[Notification]:
    get_user_or_404(session, user_id)
    return session.exec(
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
    ).all()


def mark_notification_read(session: Session, notification_id: str) -> Notification:
    notification = session.get(Notification, notification_id)
    if not notification:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")

    notification.is_read = True
    notification.updated_at = utc_now()
    session.add(notification)
    session.commit()
    session.refresh(notification)
    return notification
