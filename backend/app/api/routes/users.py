from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.db.deps import session_dependency
from app.schemas.anonymous_user import (
    AnonymousUserCreate,
    AnonymousUserRead,
    AnonymousUserUpsert,
)
from app.services import users as user_service


router = APIRouter(prefix="/users", tags=["users"])


@router.post("/anonymous", response_model=AnonymousUserRead, status_code=201)
def create_anonymous_user(
    payload: AnonymousUserCreate,
    session: Session = Depends(session_dependency),
) -> AnonymousUserRead:
    return user_service.create_anonymous_user(session, payload)


@router.get("/{user_id}", response_model=AnonymousUserRead)
def get_user(user_id: str, session: Session = Depends(session_dependency)) -> AnonymousUserRead:
    return user_service.get_user_or_404(session, user_id)


@router.put("/{user_id}", response_model=AnonymousUserRead)
def upsert_user(
    user_id: str,
    payload: AnonymousUserUpsert,
    session: Session = Depends(session_dependency),
) -> AnonymousUserRead:
    return user_service.upsert_user(session, user_id, payload)


@router.post("/{user_id}/reset", response_model=AnonymousUserRead)
def reset_user(user_id: str, session: Session = Depends(session_dependency)) -> AnonymousUserRead:
    return user_service.reset_user_profile(session, user_id)
