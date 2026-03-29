from fastapi import HTTPException, status
from sqlmodel import Session, select

from app.models import ChatRequest, ChatSession, Notification
from app.models.common import ChatRequestStatus, NotificationType, SessionType, utc_now
from app.schemas.chat_request import ChatRequestCreate
from app.services.users import get_or_create_user


def create_chat_request(session: Session, payload: ChatRequestCreate) -> ChatRequest:
    from_user = get_or_create_user(session, payload.from_user_id)
    to_user = get_or_create_user(session, payload.to_user_id)

    existing_session = _find_direct_session(
        session,
        user_a=from_user.id,
        user_b=to_user.id,
    )
    chat_session = existing_session or ChatSession(
        owner_id=payload.from_user_id,
        type=SessionType.individual,
        name=f"Direct support: {from_user.display_name} & {to_user.display_name}",
        participant_ids=[payload.from_user_id, payload.to_user_id],
    )
    if existing_session is None:
        session.add(chat_session)
        session.commit()
        session.refresh(chat_session)

    chat_request = ChatRequest(
        from_user_id=payload.from_user_id,
        to_user_id=payload.to_user_id,
        session_id=chat_session.id,
        status=ChatRequestStatus.pending,
        context_summary=(payload.context_summary or "").strip() or None,
        matched_themes=payload.matched_themes,
        support_category=payload.support_category,
        user_category=payload.user_category,
    )
    session.add(chat_request)
    session.commit()
    session.refresh(chat_request)

    _create_notification(
        session,
        user_id=payload.to_user_id,
        type=NotificationType.match_request,
        title=f"{from_user.display_name} wants to connect",
        message=_request_message(from_user.display_name, payload),
        action_data={
            "requestId": chat_request.id,
            "sessionId": chat_session.id,
            "fromUserId": from_user.id,
            "fromUserName": from_user.display_name,
            "communityName": from_user.display_name,
            "communityEmoji": "🤝",
        },
    )
    _create_notification(
        session,
        user_id=payload.from_user_id,
        type=NotificationType.system,
        title="Support request sent",
        message=f"You can continue in a direct support chat with {to_user.display_name}.",
        action_data={
            "requestId": chat_request.id,
            "sessionId": chat_session.id,
            "communityName": to_user.display_name,
            "communityEmoji": "🤝",
        },
    )

    return chat_request


def accept_chat_request(session: Session, request_id: str) -> ChatRequest:
    chat_request = _get_request_or_404(session, request_id)
    chat_request.status = ChatRequestStatus.accepted
    chat_request.updated_at = utc_now()
    session.add(chat_request)
    session.commit()
    session.refresh(chat_request)

    _create_notification(
        session,
        user_id=chat_request.from_user_id,
        type=NotificationType.message,
        title="Support request accepted",
        message="Your match accepted the request. The direct support chat is ready.",
        action_data={
            "requestId": chat_request.id,
            "sessionId": chat_request.session_id,
            "communityName": "Support Chat",
            "communityEmoji": "🤝",
        },
    )
    return chat_request


def decline_chat_request(session: Session, request_id: str) -> ChatRequest:
    chat_request = _get_request_or_404(session, request_id)
    chat_request.status = ChatRequestStatus.declined
    chat_request.updated_at = utc_now()
    session.add(chat_request)
    session.commit()
    session.refresh(chat_request)

    _create_notification(
        session,
        user_id=chat_request.from_user_id,
        type=NotificationType.system,
        title="Support request closed",
        message="That direct support request was declined. You can still use community support rooms.",
        action_data={
            "requestId": chat_request.id,
        },
    )
    return chat_request


def _find_direct_session(
    session: Session,
    user_a: str,
    user_b: str,
) -> ChatSession | None:
    sessions = session.exec(
        select(ChatSession).where(ChatSession.type == SessionType.individual)
    ).all()
    for item in sessions:
        participants = item.participant_ids or []
        if user_a in participants and user_b in participants:
            return item
    return None


def _get_request_or_404(session: Session, request_id: str) -> ChatRequest:
    chat_request = session.get(ChatRequest, request_id)
    if not chat_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat request not found",
        )
    return chat_request


def _request_message(sender_name: str, payload: ChatRequestCreate) -> str:
    parts = [f"{sender_name} wants to connect"]
    if payload.support_category:
        parts.append(f"about {payload.support_category.replace('_', ' ')}")
    if payload.context_summary:
        parts.append(f"({payload.context_summary.strip()})")
    return " ".join(parts)


def _create_notification(
    session: Session,
    *,
    user_id: str,
    type: NotificationType,
    title: str,
    message: str,
    action_data: dict | None = None,
) -> Notification:
    notification = Notification(
        user_id=user_id,
        type=type,
        title=title,
        message=message,
        action_data=action_data,
    )
    session.add(notification)
    session.commit()
    session.refresh(notification)
    return notification
