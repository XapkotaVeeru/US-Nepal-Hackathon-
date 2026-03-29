from fastapi import HTTPException, status
from sqlmodel import Session, select

from app.models import ChatSession, Message
from app.models.common import MessageStatus, utc_now
from app.schemas.chat import ChatSessionCreate, MessageCreate
from app.services.users import get_or_create_user, get_user_or_404


def create_chat_session(session: Session, user_id: str, payload: ChatSessionCreate) -> ChatSession:
    get_user_or_404(session, user_id)

    participant_ids = list(dict.fromkeys([user_id, *payload.participant_ids]))
    chat_session = ChatSession(
        owner_id=user_id,
        type=payload.type,
        name=payload.name.strip(),
        participant_ids=participant_ids,
    )
    session.add(chat_session)
    session.commit()
    session.refresh(chat_session)
    return chat_session


def list_sessions_for_user(session: Session, user_id: str) -> list[ChatSession]:
    get_user_or_404(session, user_id)
    sessions = session.exec(select(ChatSession).where(ChatSession.is_active == True)).all()  # noqa: E712
    return [
        item
        for item in sessions
        if item.owner_id == user_id or user_id in (item.participant_ids or [])
    ]


def get_chat_session_or_404(session: Session, session_id: str) -> ChatSession:
    chat_session = session.get(ChatSession, session_id)
    if not chat_session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat session not found")
    return chat_session


def get_or_create_session(
    session: Session,
    session_id: str,
    owner_id: str,
    name: str | None = None,
    participant_ids: list[str] | None = None,
    session_type: SessionType = SessionType.group,
) -> ChatSession:
    chat_session = session.get(ChatSession, session_id)
    if chat_session:
        return chat_session

    chat_session = ChatSession(
        id=session_id,
        owner_id=owner_id,
        name=name or f"Community {session_id}",
        type=session_type,
        participant_ids=participant_ids or [owner_id],
    )
    session.add(chat_session)
    session.commit()
    session.refresh(chat_session)
    return chat_session


def list_messages(session: Session, session_id: str) -> list[Message]:
    get_chat_session_or_404(session, session_id)
    return session.exec(
        select(Message)
        .where(Message.session_id == session_id)
        .order_by(Message.created_at.asc())
    ).all()


def create_message(session: Session, session_id: str, payload: MessageCreate) -> Message:
    chat_session = get_chat_session_or_404(session, session_id)
    get_or_create_user(session, payload.sender_id, payload.sender_name)

    message = Message(
        session_id=session_id,
        sender_id=payload.sender_id,
        sender_name=payload.sender_name.strip(),
        content=payload.content.strip(),
        type=payload.type,
        status=MessageStatus.delivered,
    )
    session.add(message)

    chat_session.last_message = message.content
    chat_session.last_message_time = utc_now()
    chat_session.updated_at = utc_now()
    session.add(chat_session)

    session.commit()
    session.refresh(message)
    return message
