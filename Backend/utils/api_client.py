import requests
import json
from Backend.config import get_settings

class ApiClient:
    def __init__(self, base_url=None, token=None):
        settings = get_settings()
        self.base_url = base_url or settings.api_base_url
        self.token = token
        self.headers = {}
        if token:
            self.headers["Authorization"] = f"Bearer {token}"

    def set_token(self, token):
        self.token = token
        self.headers["Authorization"] = f"Bearer {token}"

    def get(self, endpoint, params=None):
        url = f"{self.base_url}{endpoint}"
        response = requests.get(url, headers=self.headers, params=params)
        return response

    def post(self, endpoint, data=None, json_data=None):
        url = f"{self.base_url}{endpoint}"
        response = requests.post(url, headers=self.headers, data=data, json=json_data)
        return response

    def put(self, endpoint, data=None, json_data=None):
        url = f"{self.base_url}{endpoint}"
        response = requests.put(url, headers=self.headers, data=data, json=json_data)
        return response

    def delete(self, endpoint):
        url = f"{self.base_url}{endpoint}"
        response = requests.delete(url, headers=self.headers)
        return response