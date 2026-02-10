"""
HTTP Ingest Function
Accepts events via POST and runs a simple placeholder inference

Parities with fncast-dotnet Minimal API:
- POST /ingest with text or JSON payload
- Inference modes: Uppercase | Lowercase | Echo (via env INFERENCE_MODE)
"""

import json
import logging
import os

import azure.functions as func


def _infer(payload: str) -> str:
    mode = (os.environ.get("INFERENCE_MODE") or "Echo").lower()
    if mode == "uppercase":
        return payload.upper()
    if mode == "lowercase":
        return payload.lower()
    # Echo by default
    return payload


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    POST /api/ingest
    Supports:
      - Content-Type: text/plain → treat body as raw text
      - Content-Type: application/json → expect { "payload": "...", "contentType": "..." }
    Returns IngestResponse-like JSON: { "result": "...", "mode": "..." }
    """
    logging.info("HttpIngestFunction invoked")

    content_type = (req.headers.get("content-type") or "").lower()
    payload_text: str | None = None

    try:
        if "json" in content_type:
            try:
                body = req.get_json()
            except ValueError:
                return func.HttpResponse(
                    json.dumps({"error": "Invalid JSON"}), status_code=400, mimetype="application/json"
                )

            # payload can be under 'payload'; fallback to raw body string if missing
            payload_text = body.get("payload")
            if payload_text is None:
                # try raw body text
                payload_text = req.get_body().decode("utf-8", errors="ignore")
        else:
            # treat body as raw text
            payload_text = req.get_body().decode("utf-8", errors="ignore")

        if payload_text is None or payload_text == "":
            return func.HttpResponse(
                json.dumps({"error": "Missing payload"}), status_code=400, mimetype="application/json"
            )

        result = _infer(payload_text)
        response = {
            "result": result,
            "mode": (os.environ.get("INFERENCE_MODE") or "Echo"),
        }
        return func.HttpResponse(json.dumps(response), status_code=200, mimetype="application/json")

    except Exception as e:
        logging.exception("HttpIngestFunction failed")
        return func.HttpResponse(
            json.dumps({"error": str(e)}), status_code=500, mimetype="application/json"
        )
