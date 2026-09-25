"""Hugging Face ZeroGPU Space entrypoint for the MedRAX demo (RESEARCH ONLY).

This is a thin wrapper around MedRAX's upstream ``interface.create_demo`` and
``main.initialize_agent``. It is meant to be copied into a Gradio + ZeroGPU
Space alongside the vendored ``medagent`` sources (see this folder's README for
deployment steps). It does **not** run as part of the FastAPI mesh.

RESEARCH ONLY -- NOT FOR CLINICAL USE. Not a medical device.
"""

from __future__ import annotations

import os

# ``spaces`` is provided by the ZeroGPU runtime. The decorator is a no-op
# outside ZeroGPU, so the module degrades gracefully when run locally for a
# smoke test.
try:
    import spaces  # type: ignore
except ImportError:  # local / non-ZeroGPU environment

    class _SpacesShim:
        @staticmethod
        def GPU(*dargs, **dkwargs):  # noqa: N802 - mirror HF API
            def _decorator(fn):
                return fn

            # support both @spaces.GPU and @spaces.GPU(duration=...)
            if dargs and callable(dargs[0]):
                return dargs[0]
            return _decorator

    spaces = _SpacesShim()  # type: ignore

import gradio as gr

# MedRAX upstream modules (copied into the Space; see README step 4).
from interface import create_demo  # type: ignore
from main import initialize_agent  # type: ignore

RESEARCH_BANNER = (
    "## ⚠️ RESEARCH ONLY — NOT FOR CLINICAL USE\n"
    "This demo wraps the **MedRAX** chest X-ray reasoning agent "
    "(ICML 2025, arXiv:2502.02673). It is **not a medical device** and must "
    "**never** be used for any clinical, diagnostic, or treatment decision. "
    "AI output is unvalidated and may be incorrect."
)

# Keep the default tool set small so each GPU call stays within the duration
# budget and queue priority stays high on shared ZeroGPU hardware.
SELECTED_TOOLS = [
    "ImageVisualizerTool",
    "DicomProcessorTool",
    "ChestXRayClassifierTool",
    "ChestXRaySegmentationTool",
    "ChestXRayReportGeneratorTool",
]


def _build_agent():
    openai_kwargs: dict[str, str] = {}
    if api_key := os.getenv("OPENAI_API_KEY"):
        openai_kwargs["api_key"] = api_key
    if base_url := os.getenv("OPENAI_BASE_URL"):
        openai_kwargs["base_url"] = base_url

    return initialize_agent(
        "medrax/docs/system_prompts.txt",
        tools_to_use=SELECTED_TOOLS,
        model_dir=os.getenv("MODEL_DIR", "./model-weights"),
        temp_dir="temp",
        device="cuda",  # CUDA emulation outside @spaces.GPU; real GPU inside
        model=os.getenv("MEDRAX_MODEL", "gpt-4o"),
        temperature=0.7,
        top_p=0.95,
        openai_kwargs=openai_kwargs,
    )


# Models are placed on ``cuda`` at module level (ZeroGPU requirement); the GPU
# is only physically allocated when a @spaces.GPU-wrapped tool call runs.
agent, tools_dict = _build_agent()


@spaces.GPU(duration=120)
def _warm_gpu():  # pragma: no cover - ZeroGPU scheduling hook
    """Touch the GPU so MedRAX vision tools schedule onto ZeroGPU."""
    return "ready"


def main() -> None:
    inner = create_demo(agent, tools_dict)
    with gr.Blocks(title="PulmoCare — MedRAX (research only)") as demo:
        gr.Markdown(RESEARCH_BANNER)
        inner.render()
    demo.queue().launch(server_name="0.0.0.0", server_port=7860)


if __name__ == "__main__":
    main()
