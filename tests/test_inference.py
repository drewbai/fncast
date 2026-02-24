"""
Unit tests for the inference function
"""

import json
import os
import sys
from unittest.mock import Mock, patch

import azure.functions as func
import pytest

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from InferenceFunction import main


@pytest.fixture
def mock_model():
    """Mock ML model"""
    model = Mock()
    model.predict.return_value = [[1]]  # Mock prediction
    return model


@pytest.fixture
def valid_request():
    """Create a valid HTTP request"""
    body = json.dumps({"features": [0.5, -0.3, 1.2, 0.8, -0.5, 0.1, 0.9, -0.2, 0.6, 0.4]})
    return func.HttpRequest(method="POST", body=body.encode("utf-8"), url="/api/predict", params={})


@pytest.fixture
def invalid_request():
    """Create an invalid HTTP request (missing features)"""
    body = json.dumps({"data": [1, 2, 3]})
    return func.HttpRequest(method="POST", body=body.encode("utf-8"), url="/api/predict", params={})


def test_valid_inference(valid_request, mock_model):
    """Test successful inference"""
    with patch("InferenceFunction.load_model_from_blob", return_value=mock_model):
        response = main(valid_request)

        assert response.status_code == 200
        result = json.loads(response.get_body())
        assert result["status"] == "success"
        assert "prediction" in result


def test_invalid_request(invalid_request, mock_model):
    """Test request with missing features field"""
    with patch("InferenceFunction.load_model_from_blob", return_value=mock_model):
        response = main(invalid_request)

        assert response.status_code == 400
        result = json.loads(response.get_body())
        assert "error" in result


def test_malformed_json():
    """Test request with malformed JSON"""
    request = func.HttpRequest(method="POST", body=b"not json", url="/api/predict", params={})

    response = main(request)
    assert response.status_code == 400
    result = json.loads(response.get_body())
    assert "error" in result
