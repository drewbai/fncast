"""
Unit tests for EventGridIngestFunction
"""

import json
import logging
import os
import sys

import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from EventGridIngestFunction import main


# ---------------------------------------------------------------------------
# Echo mode (default)
# ---------------------------------------------------------------------------


def test_event_with_data_message_echo(monkeypatch):
    """Event containing data.message is processed without error."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    event = {"id": "abc", "eventType": "test", "data": {"message": "hello event"}}

    main(event)  # should not raise


def test_event_with_string_data_echo(monkeypatch):
    """Event with a plain string in data is processed without error."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    event = {"data": "raw string payload"}

    main(event)


def test_event_with_numeric_data(monkeypatch):
    """Event with numeric data is coerced to string and processed."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    event = {"data": 42}

    main(event)


# ---------------------------------------------------------------------------
# Uppercase / Lowercase modes
# ---------------------------------------------------------------------------


def test_data_message_uppercase(monkeypatch, caplog):
    """INFERENCE_MODE=uppercase transforms data.message to uppercase."""
    monkeypatch.setenv("INFERENCE_MODE", "uppercase")
    event = {"data": {"message": "hello"}}

    with caplog.at_level(logging.INFO, logger="root"):
        main(event)

    assert any("HELLO" in r.message for r in caplog.records)


def test_data_message_lowercase(monkeypatch, caplog):
    """INFERENCE_MODE=lowercase transforms data.message to lowercase."""
    monkeypatch.setenv("INFERENCE_MODE", "lowercase")
    event = {"data": {"message": "WORLD"}}

    with caplog.at_level(logging.INFO, logger="root"):
        main(event)

    assert any("world" in r.message for r in caplog.records)


# ---------------------------------------------------------------------------
# Edge / error cases
# ---------------------------------------------------------------------------


def test_event_no_data_logs_and_returns(monkeypatch, caplog):
    """Event with no 'data' field is logged and function returns cleanly."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    event = {"id": "xyz", "eventType": "no-data"}

    with caplog.at_level(logging.INFO, logger="root"):
        main(event)

    # No exception expected; function logs the raw event
    assert any("no recognizable payload" in r.message.lower() for r in caplog.records)


def test_event_data_empty_dict(monkeypatch, caplog):
    """Event with data as empty dict has no recognizable payload."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    event = {"data": {}}

    with caplog.at_level(logging.INFO, logger="root"):
        main(event)

    assert any("no recognizable payload" in r.message.lower() for r in caplog.records)


def test_non_dict_event_handled(monkeypatch):
    """Non-dict event_grid_event is handled gracefully (no exception)."""
    monkeypatch.delenv("INFERENCE_MODE", raising=False)
    # Pass a non-dict — function checks isinstance and falls through to logging
    main("not a dict")
