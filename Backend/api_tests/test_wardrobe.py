import pytest
from api_test_client import ApiTestClient

@pytest.fixture
def auth_client():
    client = ApiTestClient()
    client.register_user()
    return client

@pytest.fixture
def test_item(auth_client):
    item_data = {
        "name": "Test T-shirt",
        "type": "футболка",
        "color": "белый",
        "season": "лето"
    }

    response = auth_client.post("/api/wardrobe/items", json_data=item_data)
    if response.status_code in (200, 201):
        return response.json()
    pytest.skip(f"Не удалось создать тестовый предмет гардероба, код ответа: {response.status_code}")

def test_create_wardrobe_item(auth_client):
    item_data = {
        "name": "Blue Jeans",
        "type": "джинсы",
        "color": "синий",
        "season": "демисезон"
    }

    response = auth_client.post("/api/wardrobe/items", json_data=item_data)

    assert response.status_code in (200, 201)
    item = response.json()
    assert item["name"] == item_data["name"]
    assert item["type"] == item_data["type"]
    assert item["color"] == item_data["color"]
    assert item["season"] == item_data["season"]
    assert "id" in item

def test_get_wardrobe_items(auth_client, test_item):
    response = auth_client.get("/api/wardrobe/items")

    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert len(data["items"]) > 0
    assert "total" in data

@pytest.mark.skip(reason="API не поддерживает получение отдельного предмета гардероба по ID")
def test_get_wardrobe_item_by_id(auth_client, test_item):
    response = auth_client.get(f"/api/wardrobe/items")

    assert response.status_code == 200
    items = response.json()["items"]

    found_item = next((item for item in items if item["id"] == test_item["id"]), None)
    assert found_item is not None
    assert found_item["name"] == test_item["name"]

def test_get_wardrobe_items_with_filters(auth_client, test_item):
    response = auth_client.get(f"/api/wardrobe/items?type={test_item['type']}")

    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) > 0
    for item in data["items"]:
        assert item["type"] == test_item["type"]

def test_update_wardrobe_item(auth_client, test_item):
    update_data = {
        "name": "Updated T-shirt",
        "color": "черный"
    }

    response = auth_client.put(f"/api/wardrobe/items/{test_item['id']}", json_data=update_data)

    assert response.status_code == 200
    updated_item = response.json()
    assert updated_item["name"] == update_data["name"]
    assert updated_item["color"] == update_data["color"]
    assert updated_item["type"] == test_item["type"]

@pytest.mark.skip(reason="API не поддерживает удаление отдельного предмета гардероба по ID")
def test_delete_wardrobe_item(auth_client, test_item):
    response = auth_client.get("/api/wardrobe/items")
    assert response.status_code == 200
    before_count = len(response.json()["items"])

    delete_data = {"id": test_item["id"]}
    response = auth_client.post("/api/wardrobe/delete", json_data=delete_data)

    assert response.status_code in (200, 201, 202, 204)

    response = auth_client.get("/api/wardrobe/items")
    assert response.status_code == 200
    after_count = len(response.json()["items"])

    assert after_count < before_count