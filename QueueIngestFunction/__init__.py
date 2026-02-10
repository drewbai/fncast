"""
Queue Ingest Function
Consumes messages from Azure Storage Queue (fncast-events) and runs placeholder inference.
Message is expected to be a simple string or JSON with { "payload": "..." }.
"""

import json
import logging
import os


def _infer(payload: str) -> str:
    mode = (os.environ.get("INFERENCE_MODE") or "Echo").lower()
    if mode == "uppercase":
        return payload.upper()
    if mode == "lowercase":
        return payload.lower()
    return payload


def main(msg: str):
    logging.info("QueueIngestFunction triggered")

    payload_text = None
    try:
        # Try JSON first
        try:
            data = json.loads(msg)
            if isinstance(data, dict):
                payload_text = data.get("payload")
            elif isinstance(data, str):
                payload_text = data
        except Exception:
            # treat as raw string
            payload_text = msg

        if not payload_text:
            logging.warning("Queue message missing payload")
            return

        result = _infer(payload_text)
        logging.info(f"Queue message processed. Mode={os.environ.get('INFERENCE_MODE') or 'Echo'} Result={result}")
    except Exception:
        logging.exception("QueueIngestFunction failed")
