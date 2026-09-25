import os

import anthropic

from models.assistant import AssistantResponse
from pulmocare_shared import genai_tool_span

DEFAULT_ASSISTANT_MODEL = "claude-sonnet-4-6"
ASSISTANT_DISCLAIMER = (
    "AI-generated clinical support content may be incomplete or incorrect. "
    "A qualified healthcare professional must review it before use."
)


def generate_assistant_response(message: str, context: str | None = None) -> AssistantResponse:
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError("AI assistant is not configured")

    model = os.getenv("ANTHROPIC_MODEL", DEFAULT_ASSISTANT_MODEL)
    client = anthropic.Anthropic(api_key=api_key)

    system = (
        "You are PulmoCare's clinical documentation assistant for authenticated "
        "healthcare professionals. Be concise, factual, and conservative. Do not "
        "invent patient facts, diagnoses, citations, or test results. Distinguish "
        "observations from suggestions. Never claim to replace clinician judgment. "
        "If the request lacks enough information, say what information is missing."
    )
    user_content = message.strip()
    if context and context.strip():
        user_content = (
            "<clinical_context>\n"
            f"{context.strip()}\n"
            "</clinical_context>\n\n"
            "<request>\n"
            f"{message.strip()}\n"
            "</request>"
        )

    with genai_tool_span("clinical_assistant", operation="chat", model=model) as span:
        response = client.messages.create(
            model=model,
            max_tokens=900,
            system=system,
            messages=[{"role": "user", "content": user_content}],
        )
        usage = getattr(response, "usage", None)
        if usage is not None:
            span["input_tokens"] = getattr(usage, "input_tokens", 0)
            span["output_tokens"] = getattr(usage, "output_tokens", 0)

    text = "".join(
        block.text for block in response.content if getattr(block, "type", None) == "text"
    ).strip()
    if not text:
        raise RuntimeError("AI provider returned an empty response")

    return AssistantResponse(
        response=text,
        model=model,
        disclaimer=ASSISTANT_DISCLAIMER,
    )
