from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.db.deps import session_dependency
from app.schemas.mood import MoodEntryCreate, MoodEntryRead, MoodSummaryRead
from app.services import moods as mood_service


router = APIRouter(prefix="/users/{user_id}/moods", tags=["moods"])


@router.post("", response_model=MoodEntryRead, status_code=201)
def create_mood_entry(
    user_id: str,
    payload: MoodEntryCreate,
    session: Session = Depends(session_dependency),
) -> MoodEntryRead:
    return mood_service.create_mood_entry(session, user_id, payload)


@router.get("", response_model=list[MoodEntryRead])
def list_mood_entries(
    user_id: str,
    session: Session = Depends(session_dependency),
) -> list[MoodEntryRead]:
    return mood_service.list_mood_entries(session, user_id)


@router.get("/summary", response_model=MoodSummaryRead)
def mood_summary(user_id: str, session: Session = Depends(session_dependency)) -> MoodSummaryRead:
    return MoodSummaryRead.model_validate(mood_service.get_recent_mood_summary(session, user_id))
