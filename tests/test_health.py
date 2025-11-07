"""
Unit tests for the health check function
"""
import pytest
import json
import sys
import os

import azure.functions as func

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from HealthCheckFunction import main


def test_health_check():
    """Test health check endpoint"""
    request = func.HttpRequest(
        method='GET',
        body=None,
        url='/api/health',
        params={}
    )
    
    response = main(request)
    
    assert response.status_code == 200
    result = json.loads(response.get_body())
    assert result['status'] == 'healthy'
    assert 'service' in result
    assert 'version' in result
