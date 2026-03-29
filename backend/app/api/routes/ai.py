from fastapi import APIRouter, HTTPException, status

from app.schemas.ai import AIPlaceholderRequest


router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/match")
def ai_match(_: AIPlaceholderRequest) -> dict:
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="AI matching is not implemented yet. Bedrock or another AI service can be added later.",
    )


@router.post("/summarize")
def ai_summarize(_: AIPlaceholderRequest) -> dict:
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="AI summarization is not implemented yet.",
    )


@router.post("/moderate")
def ai_moderate(_: AIPlaceholderRequest) -> dict:
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="AI moderation is not implemented yet.",
    )
