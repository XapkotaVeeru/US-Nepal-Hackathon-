from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.db.deps import session_dependency
from app.schemas.chat_request import ChatRequestCreate, ChatRequestRead
from app.services import chat_requests as chat_request_service


router = APIRouter(tags=["chat-requests"])


@router.post("/chat-requests", response_model=ChatRequestRead, status_code=201)
def create_chat_request(
    payload: ChatRequestCreate,
    session: Session = Depends(session_dependency),
) -> ChatRequestRead:
    return chat_request_service.create_chat_request(session, payload)


@router.post("/chat-requests/{request_id}/accept", response_model=ChatRequestRead)
def accept_chat_request(
    request_id: str,
    session: Session = Depends(session_dependency),
) -> ChatRequestRead:
    return chat_request_service.accept_chat_request(session, request_id)


@router.post("/chat-requests/{request_id}/decline", response_model=ChatRequestRead)
def decline_chat_request(
    request_id: str,
    session: Session = Depends(session_dependency),
) -> ChatRequestRead:
    return chat_request_service.decline_chat_request(session, request_id)
