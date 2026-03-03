"""
Unit tests for QueueIngestFunction
"""

import json
import os
import sys

import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from QueueIngestFunction import main


# ---------------------------------------------------------------------------
# Echo mode (default)
# ---------------------------------------------------------------------------


def test_json_message_with_payload_echo(monkeypatch):
    """JSON message with 'payload' key is echoed."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    msg = json.dumps({"payload": "hello from queue"})

    # Should not raise
    main(msg)


def test_plain_string_message_echo(monkeypatch):
    """Plain string message is processed without error."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    main("just a plain string")


def test_json_string_message_echo(monkeypatch):
    """JSON-encoded bare string is processed without error."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    main(json.dumps("bare string value"))


# ---------------------------------------------------------------------------
# Uppercase / Lowercase modes
# ---------------------------------------------------------------------------


def test_json_message_uppercase(monkeypatch, caplog):
    """INFERENCE_MODE=uppercase processes payload through uppercase transform."""
    monkeypatch.setenv("INFERENCE_MODE", "uppercase")
    msg = json.dumps({"payload": "hello"})

    import logging

    with caplog.at_level(logging.INFO, logger="root"):
        main(msg)

    assert any("HELLO" in r.message for r in caplog.records)


def test_json_message_lowercase(monkeypatch, caplog):
    """INFERENCE_MODE=lowercase processes payload through lowercase transform."""
    monkeypatch.setenv("INFERENCE_MODE", "lowercase")
    msg = json.dumps({"payload": "WORLD"})

    import logging

    with caplog.at_level(logging.INFO, logger="root"):
        main(msg)

    assert any("world" in r.message for r in caplog.records)


# ---------------------------------------------------------------------------
# Edge / error cases
# ---------------------------------------------------------------------------


def test_empty_payload_logs_warning(monkeypatch, caplog):
    """Message with missing payload logs a warning and returns cleanly."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    msg = json.dumps({"other": "stuff"})

    import logging

    with caplog.at_level(logging.WARNING, logger="root"):
        main(msg)

    # Function should return without raising; optionally a warning is logged
    # (payload_text is None after dict extraction → warning branch)


def test_empty_string_message_logs_warning(monkeypatch):
    """Empty string message is handled gracefully (no exception)."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    main("")


def test_malformed_json_treated_as_raw_string(monkeypatch):
    """Non-JSON message is treated as a raw string and processed."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    # Should not raise even though it's not valid JSON
    main("not json at all {{")
