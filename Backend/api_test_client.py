import requests
import json
import os
import random
import string

class ApiTestClient:
    def __init__(self, base_url=None):
        self.base_url = base_url or os.environ.get("API_BASE_URL", "http://localhost:8000")
        self.token = None
        self.headers = {'Content-Type': 'application/json'}

    def set_token(self, token):
        self.token = token
        self.headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {token}'
        }

    def get(self, endpoint, params=None):
        url = f"{self.base_url}{endpoint}"
        response = requests.get(url, headers=self.headers, params=params)
        return response

    def post(self, endpoint, json_data=None):
        url = f"{self.base_url}{endpoint}"
        response = requests.post(url, headers=self.headers, json=json_data)
        return response

    def put(self, endpoint, json_data=None):
        url = f"{self.base_url}{endpoint}"
        response = requests.put(url, headers=self.headers, json=json_data)
        return response

    def delete(self, endpoint):
        url = f"{self.base_url}{endpoint}"
        response = requests.delete(url, headers=self.headers)
        return response

    # Вспомогательные методы
    def register_user(self):
        """Регистрирует нового пользователя с уникальным email"""
        random_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
        user_data = {
            "email": f"test_{random_suffix}@example.com",
            "password": "testpassword123",
            "name": f"Test User {random_suffix}"
        }

        response = self.post("/api/auth/register", json_data=user_data)
        if response.status_code == 201:
            data = response.json()
            self.set_token(data["access_token"])
            return {
                "user_data": user_data,
                "user_id": data["user"]["id"],
                "access_token": data["access_token"]
            }
        return None

    def create_wardrobe_item(self, item_data=None):
        """Создает предмет гардероба"""
        if not self.token:
            return None

        if not item_data:
            item_data = {
                "name": f"Test Item {random.randint(1, 1000)}",
                "type": "футболка",
                "color": "белый",
                "season": "лето"
            }

        response = self.post("/api/wardrobe/items", json_data=item_data)
        if response.status_code == 201:
            return response.json()
        return None

    def create_multiple_items(self, count=3):
        """Создает несколько предметов гардероба"""
        items = []
        types = ["футболка", "джинсы", "куртка", "платье", "обувь"]
        colors = ["белый", "черный", "синий", "красный", "зеленый"]
        seasons = ["лето", "зима", "демисезон"]

        for i in range(count):
            item_data = {
                "name": f"Test Item {random.randint(1, 1000)}",
                "type": random.choice(types),
                "color": random.choice(colors),
                "season": random.choice(seasons)
            }
            item = self.create_wardrobe_item(item_data)
            if item:
                items.append(item)

        return items

    def create_outfit(self, item_ids=None):
        """Создает образ из предметов гардероба"""
        if not self.token:
            return None

        if not item_ids:
            items = self.create_multiple_items(3)
            if not items:
                return None
            item_ids = [item["id"] for item in items]

        outfit_data = {
            "name": f"Test Outfit {random.randint(1, 1000)}",
            "occasion": "повседневный",
            "is_favorite": False,
            "items": [{"wardrobe_item_id": item_id} for item_id in item_ids]
        }

        response = self.post("/api/outfits", json_data=outfit_data)
        if response.status_code == 201:
            return response.json()
        return None