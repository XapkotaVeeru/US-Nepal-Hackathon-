from collections import defaultdict

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._connections: dict[str, list[WebSocket]] = defaultdict(list)

    async def connect(self, session_id: str, websocket: WebSocket, *, accept: bool = True) -> None:
        if accept:
            await websocket.accept()
        self._connections[session_id].append(websocket)

    def disconnect(self, session_id: str, websocket: WebSocket) -> None:
        sockets = self._connections.get(session_id, [])
        if websocket in sockets:
            sockets.remove(websocket)
        if not sockets and session_id in self._connections:
            del self._connections[session_id]

    async def broadcast(self, session_id: str, payload: dict) -> None:
        for websocket in list(self._connections.get(session_id, [])):
            await websocket.send_json(payload)


manager = ConnectionManager()
