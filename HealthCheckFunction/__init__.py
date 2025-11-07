"""
Health Check Function
Simple endpoint to verify the function app is running
"""
import logging
import json
import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint
    """
    logging.info('Health check function called.')
    
    response = {
        "status": "healthy",
        "service": "FnCast ML Inference API",
        "version": "1.0.0"
    }
    
    return func.HttpResponse(
        json.dumps(response),
        status_code=200,
        mimetype="application/json"
    )
