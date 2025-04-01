import pytest
from api_test_client import ApiTestClient
import random
import string

@pytest.fixture
def client():
    return ApiTestClient()

@pytest.fixture
def user_data():
    random_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    return {
        "email": f"test_{random_suffix}@example.com",
        "password": "testpassword123",
        "name": f"Test User {random_suffix}"
    }

def test_register(client, user_data):
    response = client.post("/api/auth/register", json_data=user_data)

    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "user" in data
    assert data["user"]["email"] == user_data["email"]
    assert data["user"]["name"] == user_data["name"]

def test_register_existing_user(client, user_data):
    response = client.post("/api/auth/register", json_data=user_data)
    assert response.status_code == 201

    response = client.post("/api/auth/register", json_data=user_data)
    assert response.status_code == 400
    assert "уже зарегистрирован" in response.json().get("detail", "") or "already registered" in response.json().get("detail", "")

def test_login_success(client, user_data):
    client.post("/api/auth/register", json_data=user_data)

    response = client.post("/api/auth/login", json_data={
        "email": user_data["email"],
        "password": user_data["password"]
    })

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "user" in data
    assert data["user"]["email"] == user_data["email"]

def test_login_wrong_password(client, user_data):
    client.post("/api/auth/register", json_data=user_data)

    response = client.post("/api/auth/login", json_data={
        "email": user_data["email"],
        "password": "wrongpassword"
    })

    assert response.status_code == 401
    assert "Invalid" in response.json().get("detail", "") or "недействительный" in response.json().get("detail", "").lower()

def test_login_nonexistent_user(client):
    response = client.post("/api/auth/login", json_data={
        "email": "nonexistent@example.com",
        "password": "somepassword"
    })

    assert response.status_code == 401

def test_get_profile(client, user_data):
    response = client.post("/api/auth/register", json_data=user_data)
    token = response.json()["access_token"]
    client.set_token(token)

    response = client.get("/api/auth/profile")

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == user_data["email"]
    assert data["name"] == user_data["name"]

def test_update_onboarding_status(client, user_data):
    response = client.post("/api/auth/register", json_data=user_data)
    token = response.json()["access_token"]
    client.set_token(token)

    onboarding_data = {
        "onboarding_completed": True
    }

    response = client.put("/api/users/me/onboarding", json_data=onboarding_data)

    assert response.status_code == 200
    data = response.json()
    assert data["onboarding_completed"] is True