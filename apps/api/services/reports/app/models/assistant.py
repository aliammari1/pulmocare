from pydantic import BaseModel, Field


class AssistantRequest(BaseModel):
    message: str = Field(min_length=1, max_length=8_000)
    context: str | None = Field(default=None, max_length=12_000)


class AssistantResponse(BaseModel):
    response: str
    model: str
    disclaimer: str
