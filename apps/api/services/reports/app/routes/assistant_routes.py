from fastapi import APIRouter, Depends, HTTPException, status

from auth.keycloak_auth import get_current_report_writer
from models.assistant import AssistantRequest, AssistantResponse
from services.assistant_service import generate_assistant_response

router = APIRouter(prefix="/api/reports/ai", tags=["AI Assistant"])


@router.post("/assistant", response_model=AssistantResponse)
async def assistant(
    request: AssistantRequest,
    user_info: dict = Depends(get_current_report_writer),
) -> AssistantResponse:
    del user_info
    try:
        return generate_assistant_response(request.message, request.context)
    except RuntimeError as exc:
        if str(exc) == "AI assistant is not configured":
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="AI assistant is not configured on this environment",
            )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="AI assistant is temporarily unavailable",
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="AI assistant is temporarily unavailable",
        )
