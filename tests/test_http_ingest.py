"""
Unit tests for HttpIngestFunction
"""

import json
import os
import sys

import azure.functions as func
import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from HttpIngestFunction import main


def _make_request(body: bytes, content_type: str = "application/json") -> func.HttpRequest:
    return func.HttpRequest(
        method="POST",
        body=body,
        url="/api/ingest",
        params={},
        headers={"content-type": content_type},
    )


# ---------------------------------------------------------------------------
# Echo mode (default)
# ---------------------------------------------------------------------------


def test_json_payload_echo(monkeypatch):
    """JSON body with 'payload' key returns echoed result in echo mode."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    req = _make_request(json.dumps({"payload": "hello world"}).encode())

    resp = main(req)

    assert resp.status_code == 200
    body = json.loads(resp.get_body())
    assert body["result"] == "hello world"
    assert body["mode"] == "Echo"


def test_plain_text_payload_echo(monkeypatch):
    """Plain-text body is echoed when no mode is set."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    req = _make_request(b"plain text input", content_type="text/plain")

    resp = main(req)

    assert resp.status_code == 200
    body = json.loads(resp.get_body())
    assert body["result"] == "plain text input"


# ---------------------------------------------------------------------------
# Uppercase mode
# ---------------------------------------------------------------------------


def test_json_payload_uppercase(monkeypatch):
    """INFERENCE_MODE=uppercase uppercases the payload."""
    monkeypatch.setenv("INFERENCE_MODE", "uppercase")
    req = _make_request(json.dumps({"payload": "hello"}).encode())

    resp = main(req)

    assert resp.status_code == 200
    body = json.loads(resp.get_body())
    assert body["result"] == "HELLO"
    assert body["mode"] == "uppercase"


def test_plain_text_uppercase(monkeypatch):
    """Plain-text body is uppercased."""
    monkeypatch.setenv("INFERENCE_MODE", "uppercase")
    req = _make_request(b"hi there", content_type="text/plain")

    resp = main(req)

    assert resp.status_code == 200
    assert json.loads(resp.get_body())["result"] == "HI THERE"


# ---------------------------------------------------------------------------
# Lowercase mode
# ---------------------------------------------------------------------------


def test_json_payload_lowercase(monkeypatch):
    """INFERENCE_MODE=lowercase lowercases the payload."""
    monkeypatch.setenv("INFERENCE_MODE", "lowercase")
    req = _make_request(json.dumps({"payload": "HELLO"}).encode())

    resp = main(req)

    assert resp.status_code == 200
    assert json.loads(resp.get_body())["result"] == "hello"


# ---------------------------------------------------------------------------
# Edge / error cases
# ---------------------------------------------------------------------------


def test_empty_body_returns_400(monkeypatch):
    """Empty request body should return 400."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    req = _make_request(b"", content_type="text/plain")

    resp = main(req)

    assert resp.status_code == 400
    assert "error" in json.loads(resp.get_body())


def test_invalid_json_returns_400(monkeypatch):
    """Malformed JSON body should return 400."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    req = _make_request(b"not valid json {{")

    resp = main(req)

    assert resp.status_code == 400
    assert "error" in json.loads(resp.get_body())


def test_json_without_payload_key_falls_back_to_raw_body(monkeypatch):
    """JSON body missing 'payload' key falls back to reading raw body string."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    raw = json.dumps({"other_key": "value"})
    req = _make_request(raw.encode())

    resp = main(req)

    # raw body string is non-empty so should succeed
    assert resp.status_code == 200
    body = json.loads(resp.get_body())
    assert body["result"] == raw
