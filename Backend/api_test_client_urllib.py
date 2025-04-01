import json
import os
import random
import string
import urllib.request
import urllib.error
import urllib.parse

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

    def _make_request(self, method, endpoint, data=None, params=None):
        url = f"{self.base_url}{endpoint}"

        # Отладочная информация
        print(f"\n[DEBUG] Sending {method} request to {url}")
        if data:
            print(f"[DEBUG] Request data: {data}")

        # Добавляем параметры запроса, если они есть
        if params:
            query_string = urllib.parse.urlencode(params)
            url = f"{url}?{query_string}"

        # Подготавливаем данные и заголовки
        request_data = None
        if data:
            request_data = json.dumps(data).encode('utf-8')

        # Создаем запрос
        req = urllib.request.Request(
            url=url,
            data=request_data,
            headers=self.headers,
            method=method
        )

        try:
            # Выполняем запрос
            with urllib.request.urlopen(req) as response:
                status_code = response.status
                content = response.read().decode('utf-8')

                # Отладочная информация
                print(f"[DEBUG] Response status: {status_code}")
                print(f"[DEBUG] Response body: {content[:200]}...")

                # Создаем объект, имитирующий ответ requests
                class Response:
                    def __init__(self, status_code, content):
                        self.status_code = status_code
                        self._content = content

                    def json(self):
                        return json.loads(self._content) if self._content else {}

                return Response(status_code, content)

        except urllib.error.HTTPError as e:
            # Отладочная информация об ошибке
            print(f"[DEBUG] HTTP Error: {e.code}")
            content = e.read().decode('utf-8')
            print(f"[DEBUG] Error response: {content[:200]}...")
            return Response(e.code, content)

    def get(self, endpoint, params=None):
        return self._make_request('GET', endpoint, params=params)

    def post(self, endpoint, json_data=None):
        return self._make_request('POST', endpoint, data=json_data)

    def put(self, endpoint, json_data=None):
        return self._make_request('PUT', endpoint, data=json_data)

    def delete(self, endpoint):
        return self._make_request('DELETE', endpoint)

    # Остальные вспомогательные методы остаются без изменений
    # ...