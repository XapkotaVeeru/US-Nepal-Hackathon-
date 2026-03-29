from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.db.deps import session_dependency
from app.schemas.notification import NotificationCreate, NotificationRead
from app.services import notifications as notification_service


router = APIRouter(tags=["notifications"])


@router.get("/users/{user_id}/notifications", response_model=list[NotificationRead])
def list_notifications(
    user_id: str,
    session: Session = Depends(session_dependency),
) -> list[NotificationRead]:
    return notification_service.list_notifications(session, user_id)


@router.post("/users/{user_id}/notifications", response_model=NotificationRead, status_code=201)
def create_notification(
    user_id: str,
    payload: NotificationCreate,
    session: Session = Depends(session_dependency),
) -> NotificationRead:
    return notification_service.create_notification(session, user_id, payload)


@router.post("/notifications/{notification_id}/read", response_model=NotificationRead)
def mark_notification_read(
    notification_id: str,
    session: Session = Depends(session_dependency),
) -> NotificationRead:
    return notification_service.mark_notification_read(session, notification_id)
