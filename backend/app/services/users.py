from sqlmodel import Session, select
from fastapi import HTTPException, status

from app.models import AnonymousUser, ChatSession, JournalEntry, Message, MoodEntry, Notification
from app.models.common import utc_now
from app.schemas.anonymous_user import AnonymousUserCreate


def create_anonymous_user(session: Session, payload: AnonymousUserCreate) -> AnonymousUser:
    name = payload.display_name or _generate_display_name()
    user = AnonymousUser(display_name=name)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def get_user_or_404(session: Session, user_id: str) -> AnonymousUser:
    user = session.get(AnonymousUser, user_id)
    if not user:
      raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


def reset_user_profile(session: Session, user_id: str) -> AnonymousUser:
    user = get_user_or_404(session, user_id)

    mood_entries = session.exec(select(MoodEntry).where(MoodEntry.user_id == user_id)).all()
    journal_entries = session.exec(select(JournalEntry).where(JournalEntry.user_id == user_id)).all()
    notifications = session.exec(select(Notification).where(Notification.user_id == user_id)).all()
    sessions = session.exec(select(ChatSession).where(ChatSession.owner_id == user_id)).all()
    messages = session.exec(select(Message).where(Message.sender_id == user_id)).all()

    for item in mood_entries + journal_entries + notifications + messages:
        session.delete(item)

    for chat_session in sessions:
        session_messages = session.exec(
            select(Message).where(Message.session_id == chat_session.id)
        ).all()
        for message in session_messages:
            session.delete(message)
        session.delete(chat_session)

    user.display_name = _generate_display_name()
    user.updated_at = utc_now()
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def _generate_display_name() -> str:
    return f"Anonymous-{utc_now().strftime('%H%M%S')}"
