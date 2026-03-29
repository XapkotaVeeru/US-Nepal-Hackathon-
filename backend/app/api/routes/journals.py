from fastapi import APIRouter, Depends, Response, status
from sqlmodel import Session

from app.db.deps import session_dependency
from app.schemas.journal import JournalEntryCreate, JournalEntryRead
from app.services import journals as journal_service


router = APIRouter(tags=["journals"])


@router.post("/users/{user_id}/journals", response_model=JournalEntryRead, status_code=201)
def create_journal_entry(
    user_id: str,
    payload: JournalEntryCreate,
    session: Session = Depends(session_dependency),
) -> JournalEntryRead:
    return journal_service.create_journal_entry(session, user_id, payload)


@router.get("/users/{user_id}/journals", response_model=list[JournalEntryRead])
def list_journal_entries(
    user_id: str,
    session: Session = Depends(session_dependency),
) -> list[JournalEntryRead]:
    return journal_service.list_journal_entries(session, user_id)


@router.delete("/journals/{journal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_journal_entry(
    journal_id: str,
    session: Session = Depends(session_dependency),
) -> Response:
    journal_service.delete_journal_entry(session, journal_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
