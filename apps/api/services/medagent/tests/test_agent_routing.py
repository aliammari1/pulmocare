"""LangGraph tool-routing tests for the MedRAX agent.

These tests verify the *routing* logic of ``medrax.agent.Agent`` -- that the
graph dispatches model-requested tool calls to the right tool, feeds results
back, and terminates when no more tool calls are requested -- WITHOUT any GPU,
model weights, or network. Both the language model and the tools are mocked.

The heavy MedRAX tool modules (torch / transformers) are intentionally NOT
imported here; we only need the LangGraph plumbing in ``medrax.agent``.

Run with:  uv run pytest tests/test_agent_routing.py
"""

from __future__ import annotations

from typing import Any

import pytest

# langchain-core / langgraph are declared deps of medrax; skip cleanly if the
# environment was synced without them (e.g. weights-only install).
pytest.importorskip("langgraph")
pytest.importorskip("langchain_core")

from langchain_core.language_models import BaseLanguageModel  # noqa: E402
from langchain_core.messages import AIMessage, HumanMessage  # noqa: E402
from langchain_core.tools import StructuredTool  # noqa: E402

from medrax.agent.agent import Agent  # noqa: E402


class ScriptedModel(BaseLanguageModel):
    """A fake chat model that replays a fixed list of AIMessage responses.

    Each ``invoke`` returns the next scripted message, letting us drive the
    process -> execute -> process loop deterministically.
    """

    responses: list[AIMessage] = []
    calls: int = 0

    class Config:
        arbitrary_types_allowed = True

    def bind_tools(self, tools, **kwargs):  # noqa: ANN001
        return self

    def invoke(self, messages, *args, **kwargs):  # noqa: ANN001
        msg = self.responses[self.calls]
        self.calls += 1
        return msg

    # --- BaseLanguageModel abstract surface (unused by Agent) ---
    def generate_prompt(self, *a: Any, **k: Any):  # pragma: no cover
        raise NotImplementedError

    async def agenerate_prompt(self, *a: Any, **k: Any):  # pragma: no cover
        raise NotImplementedError

    def predict(self, *a: Any, **k: Any):  # pragma: no cover
        raise NotImplementedError

    def predict_messages(self, *a: Any, **k: Any):  # pragma: no cover
        raise NotImplementedError

    async def apredict(self, *a: Any, **k: Any):  # pragma: no cover
        raise NotImplementedError

    async def apredict_messages(self, *a: Any, **k: Any):  # pragma: no cover
        raise NotImplementedError


def _make_tool(name: str, recorder: list[str]):
    def _fn(image_path: str) -> str:
        recorder.append(name)
        return f"{name}::{image_path}"

    return StructuredTool.from_function(
        func=_fn,
        name=name,
        description=f"fake {name}",
    )


def test_agent_routes_single_tool_then_stops(tmp_path):
    recorder: list[str] = []
    report_tool = _make_tool("chest_xray_report_generator", recorder)
    vqa_tool = _make_tool("xray_vqa", recorder)

    tool_call = {
        "name": "chest_xray_report_generator",
        "args": {"image_path": "/demo/cxr.png"},
        "id": "call_1",
    }
    model = ScriptedModel(
        responses=[
            AIMessage(content="", tool_calls=[tool_call]),  # round 1 -> execute
            AIMessage(content="Here is the report.", tool_calls=[]),  # round 2 -> END
        ]
    )

    agent = Agent(
        model=model,
        tools=[report_tool, vqa_tool],
        system_prompt="test",
        log_tools=True,
        log_dir=str(tmp_path / "logs"),
    )

    final = agent.workflow.invoke(
        {"messages": [HumanMessage(content="Generate a report")]}
    )

    # The report tool ran exactly once; the VQA tool did not.
    assert recorder == ["chest_xray_report_generator"]
    # The conversation terminated with the model's final answer.
    assert final["messages"][-1].content == "Here is the report."


def test_agent_dispatches_to_correct_tool(tmp_path):
    recorder: list[str] = []
    report_tool = _make_tool("chest_xray_report_generator", recorder)
    vqa_tool = _make_tool("xray_vqa", recorder)

    model = ScriptedModel(
        responses=[
            AIMessage(
                content="",
                tool_calls=[
                    {"name": "xray_vqa", "args": {"image_path": "/demo/cxr.png"}, "id": "c1"}
                ],
            ),
            AIMessage(content="done", tool_calls=[]),
        ]
    )

    agent = Agent(model=model, tools=[report_tool, vqa_tool], log_tools=False)
    agent.workflow.invoke({"messages": [HumanMessage(content="Is there effusion?")]})

    assert recorder == ["xray_vqa"]


def test_invalid_tool_name_does_not_crash(tmp_path):
    recorder: list[str] = []
    report_tool = _make_tool("chest_xray_report_generator", recorder)

    model = ScriptedModel(
        responses=[
            AIMessage(
                content="",
                tool_calls=[{"name": "nonexistent_tool", "args": {}, "id": "c1"}],
            ),
            AIMessage(content="recovered", tool_calls=[]),
        ]
    )

    agent = Agent(model=model, tools=[report_tool], log_tools=False)
    final = agent.workflow.invoke({"messages": [HumanMessage(content="hi")]})

    # No real tool executed; the loop recovered and finished.
    assert recorder == []
    assert final["messages"][-1].content == "recovered"
