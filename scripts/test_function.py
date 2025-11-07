"""
Script to test the deployed Azure Function
"""
import requests
import json
import argparse


def test_health_endpoint(base_url: str):
    """
    Test the health check endpoint
    """
    print("Testing health endpoint...")
    response = requests.get(f"{base_url}/api/health")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_inference_endpoint(base_url: str, function_key: str = None):
    """
    Test the inference endpoint with sample data
    """
    print("\nTesting inference endpoint...")
    
    # Sample features (10 features for the demo model)
    payload = {
        "features": [0.5, -0.3, 1.2, 0.8, -0.5, 0.1, 0.9, -0.2, 0.6, 0.4]
    }
    
    headers = {"Content-Type": "application/json"}
    if function_key:
        headers["x-functions-key"] = function_key
    
    url = f"{base_url}/api/predict"
    if function_key:
        url += f"?code={function_key}"
    
    response = requests.post(url, json=payload, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    return response.status_code == 200


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test Azure Function endpoints")
    parser.add_argument("--url", required=True, help="Base URL of the function app")
    parser.add_argument("--key", help="Function key for authentication")
    
    args = parser.parse_args()
    
    base_url = args.url.rstrip('/')
    
    # Test endpoints
    health_ok = test_health_endpoint(base_url)
    inference_ok = test_inference_endpoint(base_url, args.key)
    
    print("\n" + "="*50)
    if health_ok and inference_ok:
        print("✓ All tests passed!")
    else:
        print("✗ Some tests failed")
        if not health_ok:
            print("  - Health check failed")
        if not inference_ok:
            print("  - Inference test failed")
