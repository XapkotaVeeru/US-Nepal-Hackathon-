from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlmodel import Session

from app.db.deps import session_dependency
from app.db.session import engine
from app.schemas.chat import ChatSessionCreate, ChatSessionRead, MessageCreate, MessageRead
from app.services import chat as chat_service
from app.services.users import get_or_create_user
from app.websocket.manager import manager


router = APIRouter(tags=["sessions"])


@router.post("/users/{user_id}/sessions", response_model=ChatSessionRead, status_code=201)
def create_chat_session(
    user_id: str,
    payload: ChatSessionCreate,
    session: Session = Depends(session_dependency),
) -> ChatSessionRead:
    return chat_service.create_chat_session(session, user_id, payload)


@router.get("/users/{user_id}/sessions", response_model=list[ChatSessionRead])
def list_sessions_for_user(
    user_id: str,
    session: Session = Depends(session_dependency),
) -> list[ChatSessionRead]:
    return chat_service.list_sessions_for_user(session, user_id)


@router.get("/sessions/{session_id}/messages", response_model=list[MessageRead])
def list_messages(
    session_id: str,
    session: Session = Depends(session_dependency),
) -> list[MessageRead]:
    return chat_service.list_messages(session, session_id)


@router.post("/sessions/{session_id}/messages", response_model=MessageRead, status_code=201)
def create_message(
    session_id: str,
    payload: MessageCreate,
    session: Session = Depends(session_dependency),
) -> MessageRead:
    return chat_service.create_message(session, session_id, payload)


@router.websocket("/ws/sessions/{session_id}")
async def session_websocket(websocket: WebSocket, session_id: str) -> None:
    await manager.connect(session_id, websocket)
    try:
        while True:
            payload = await websocket.receive_json()
            message_payload = MessageCreate.model_validate(payload)

            with Session(engine) as session:
                message = chat_service.create_message(session, session_id, message_payload)
                await manager.broadcast(
                    session_id,
                    {
                        "id": message.id,
                        "sessionId": message.session_id,
                        "senderId": message.sender_id,
                        "senderName": message.sender_name,
                        "content": message.content,
                        "type": message.type.value,
                        "status": message.status.value,
                        "timestamp": message.created_at.isoformat(),
                        "isRead": message.is_read,
                    },
                )
    except WebSocketDisconnect:
        manager.disconnect(session_id, websocket)


@router.websocket("/ws")
async def legacy_websocket(websocket: WebSocket) -> None:
    await websocket.accept()
    active_session_id: str | None = None

    try:
        while True:
            payload = await websocket.receive_json()
            action = payload.get("action")

            if action == "ping":
                await websocket.send_json({"type": "pong"})
                continue

            if action == "joinCommunity":
                community_id = payload.get("communityId")
                user_id = payload.get("userId") or payload.get("senderId") or "anonymous"
                if not community_id:
                    continue

                if active_session_id:
                    manager.disconnect(active_session_id, websocket)

                with Session(engine) as session:
                    get_or_create_user(session, user_id)
                    chat_service.get_or_create_session(
                        session,
                        session_id=community_id,
                        owner_id=user_id,
                        name=f"Community {community_id}",
                    )

                await manager.connect(community_id, websocket, accept=False)
                active_session_id = community_id
                await websocket.send_json({"type": "joined", "communityId": community_id})
                continue

            if action == "sendMessage":
                community_id = payload.get("communityId") or active_session_id
                sender_id = payload.get("senderId") or payload.get("userId") or "anonymous"
                sender_name = payload.get("senderName") or "Anonymous"
                content = payload.get("content")

                if not community_id or not content:
                    continue

                message_payload = MessageCreate(
                    sender_id=sender_id,
                    sender_name=sender_name,
                    content=content,
                )

                with Session(engine) as session:
                    get_or_create_user(session, sender_id, sender_name)
                    chat_service.get_or_create_session(
                        session,
                        session_id=community_id,
                        owner_id=sender_id,
                        name=f"Community {community_id}",
                    )
                    message = chat_service.create_message(session, community_id, message_payload)

                await manager.broadcast(
                    community_id,
                    {
                        "type": "message",
                        "data": {
                            "id": message.id,
                            "sessionId": message.session_id,
                            "senderId": message.sender_id,
                            "senderName": message.sender_name,
                            "content": message.content,
                            "type": message.type.value,
                            "status": message.status.value,
                            "timestamp": message.created_at.isoformat(),
                            "isRead": message.is_read,
                        },
                    },
                )
    except WebSocketDisconnect:
        if active_session_id:
            manager.disconnect(active_session_id, websocket)
