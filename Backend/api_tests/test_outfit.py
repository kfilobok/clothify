import pytest
from api_test_client import ApiTestClient

@pytest.fixture
def auth_client():
    client = ApiTestClient()
    client.register_user()
    return client

@pytest.fixture
def wardrobe_items(auth_client):
    items = []
    for i in range(3):
        item_data = {
            "name": f"Test Item {i}",
            "type": "футболка" if i == 0 else "джинсы" if i == 1 else "обувь",
            "color": "белый" if i == 0 else "синий" if i == 1 else "черный",
            "season": "лето"
        }
        response = auth_client.post("/api/wardrobe/items", json_data=item_data)
        if response.status_code in (200, 201):
            items.append(response.json())

    if not items:
        pytest.skip("Не удалось создать тестовые предметы гардероба")
    return items

@pytest.fixture
def outfit(auth_client, wardrobe_items):
    if not wardrobe_items:
        pytest.skip("Нет предметов гардероба для создания образа")

    outfit_data = {
        "name": "Test Outfit",
        "occasion": "повседневный",
        "is_favorite": False,
        "items": [{"wardrobe_item_id": item["id"]} for item in wardrobe_items]
    }

    response = auth_client.post("/api/outfits", json_data=outfit_data)
    if response.status_code in (200, 201):
        return response.json()
    pytest.skip(f"Не удалось создать тестовый образ, код ответа: {response.status_code}")

def test_create_outfit(auth_client, wardrobe_items):
    outfit_data = {
        "name": "Test Outfit",
        "occasion": "повседневный",
        "is_favorite": False,
        "items": [{"wardrobe_item_id": item["id"]} for item in wardrobe_items]
    }

    response = auth_client.post("/api/outfits", json_data=outfit_data)

    assert response.status_code in (200, 201)
    outfit = response.json()
    assert outfit["name"] == outfit_data["name"]
    assert outfit["occasion"] == outfit_data["occasion"]
    assert "items" in outfit
    assert len(outfit["items"]) == len(outfit_data["items"])

def test_get_outfits(auth_client, outfit):
    response = auth_client.get("/api/outfits")

    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert len(data["items"]) > 0

def test_get_outfit_by_id(auth_client, outfit):
    if outfit is None:
        pytest.skip("Нет тестового образа для проверки")

    response = auth_client.get(f"/api/outfits/{outfit['id']}")

    assert response.status_code == 200
    result = response.json()
    assert result["id"] == outfit["id"]
    assert result["name"] == outfit["name"]
    assert "items" in result

def test_update_outfit(auth_client, outfit, wardrobe_items):
    update_data = {
        "name": "Updated Outfit",
        "occasion": "вечеринка",
        "items": [{"wardrobe_item_id": item["id"]} for item in wardrobe_items[:1]]
    }

    response = auth_client.put(f"/api/outfits/{outfit['id']}", json_data=update_data)

    assert response.status_code == 200
    updated_outfit = response.json()
    assert updated_outfit["name"] == update_data["name"]
    assert updated_outfit["occasion"] == update_data["occasion"]
    assert len(updated_outfit["items"]) == len(update_data["items"])

def test_delete_outfit(auth_client, outfit):
    response = auth_client.delete(f"/api/outfits/{outfit['id']}")

    assert response.status_code == 204

    response = auth_client.get(f"/api/outfits/{outfit['id']}")
    assert response.status_code == 404

def test_add_outfit_to_favorites(auth_client, outfit):
    response = auth_client.post(f"/api/users/me/favorites/{outfit['id']}")

    assert response.status_code == 200

    response = auth_client.get("/api/users/me/favorites")
    favorites = response.json()

    assert outfit["id"] in favorites or any(o["id"] == outfit["id"] for o in favorites)

def test_remove_outfit_from_favorites(auth_client, outfit):
    auth_client.post(f"/api/users/me/favorites/{outfit['id']}")

    response = auth_client.delete(f"/api/users/me/favorites/{outfit['id']}")

    assert response.status_code == 200

    response = auth_client.get("/api/users/me/favorites")
    favorites = response.json()

    assert outfit["id"] not in favorites and not any(o["id"] == outfit["id"] for o in favorites)

def test_get_outfit_recommendations(auth_client, outfit):
    response = auth_client.get(f"/api/outfits/{outfit['id']}/recommendations")

    assert response.status_code == 200
    data = response.json()
    assert "recommendations" in data
    if len(data["recommendations"]) > 0:
        recommendation = data["recommendations"][0]
        assert "type" in recommendation
        assert "description" in recommendation
        assert "items" in recommendation