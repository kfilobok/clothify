import pytest
from api_test_client import ApiTestClient

@pytest.fixture
def auth_client():
    client = ApiTestClient()
    client.register_user()
    return client

def test_search_products(auth_client):
    response = auth_client.get("/api/products/search")

    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert "page" in data
    assert "size" in data
    assert "pages" in data

def test_get_product_recommendations(auth_client):
    response = auth_client.get("/api/products/recommendations")

    assert response.status_code == 200
    data = response.json()
    assert "recommendations" in data

    if len(data["recommendations"]) > 0:
        recommendation = data["recommendations"][0]
        assert "category" in recommendation
        assert "products" in recommendation