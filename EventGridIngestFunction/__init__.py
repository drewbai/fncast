"""
Event Grid Ingest Function
Consumes events from Azure Event Grid and runs placeholder inference on 'data' if present.
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


def main(event_grid_event):
    logging.info("EventGridIngestFunction triggered")
    try:
        # event_grid_event is a dict-like object in Python functions
        # Try to pull 'data' and derive a string payload
        data = event_grid_event.get("data") if isinstance(event_grid_event, dict) else None
        payload_text = None

        if isinstance(data, dict) and "message" in data:
            payload_text = str(data["message"])
        elif isinstance(data, str | int | float):
            payload_text = str(data)

        if not payload_text:
            logging.info("Event Grid event has no recognizable payload; logging event.")
            logging.info(json.dumps(event_grid_event))
            return

        result = _infer(payload_text)
        logging.info(
            f"EventGrid event processed. Mode={os.environ.get('INFERENCE_MODE') or 'Echo'} Result={result}"
        )
    except Exception:
        logging.exception("EventGridIngestFunction failed")
