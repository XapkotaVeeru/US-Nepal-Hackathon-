from fastapi import APIRouter

from app.api.routes import ai, chat_requests, health, journals, moods, notifications, sessions, users


api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(users.router)
api_router.include_router(moods.router)
api_router.include_router(journals.router)
api_router.include_router(sessions.router)
api_router.include_router(chat_requests.router)
api_router.include_router(notifications.router)
api_router.include_router(ai.router)
