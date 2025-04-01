import pytest
from api_test_client import ApiTestClient

@pytest.fixture
def client():
    return ApiTestClient()

@pytest.fixture
def auth_client():
    client = ApiTestClient()
    client.register_user()
    return client

def test_get_questions(client):
    response = client.get("/api/colortype/questions")

    assert response.status_code == 200
    questions = response.json()
    assert len(questions) > 0

    for question in questions:
        assert "id" in question
        assert "text" in question
        assert "options" in question
        assert len(question["options"]) > 0

def test_submit_answers(auth_client):
    response = auth_client.get("/api/colortype/questions")

    if response.status_code != 200:
        pytest.skip("Не удалось получить вопросы для определения цветотипа")

    questions = response.json()

    answers = {
        "answers": [
            {
                "question_id": question["id"],
                "selected_option_id": question["options"][0]["id"]
            }
            for question in questions
        ]
    }

    response = auth_client.post("/api/colortype/results", json_data=answers)

    assert response.status_code == 200
    result = response.json()
    assert "color_type" in result
    assert "description" in result
    assert "recommended_colors" in result
    assert "avoid_colors" in result

def test_submit_invalid_answers(auth_client):
    invalid_answers = {
        "answers": [
            {
                "question_id": 999999,
                "selected_option_id": 999999
            }
        ]
    }

    response = auth_client.post("/api/colortype/results", json_data=invalid_answers)

    assert response.status_code == 400

def test_get_color_recommendations(auth_client):
    response = auth_client.get("/api/colortype/questions")

    if response.status_code != 200:
        pytest.skip("Не удалось получить вопросы для определения цветотипа")

    questions = response.json()

    answers = {
        "answers": [
            {
                "question_id": question["id"],
                "selected_option_id": question["options"][0]["id"]
            }
            for question in questions
        ]
    }

    auth_client.post("/api/colortype/results", json_data=answers)

    response = auth_client.get("/api/users/me/recommendations")

    assert response.status_code == 200
    recommendations = response.json()
    assert "recommendations" in recommendations

def test_get_user_colortype(auth_client):
    response = auth_client.get("/api/colortype/questions")

    if response.status_code != 200:
        pytest.skip("Не удалось получить вопросы для определения цветотипа")

    questions = response.json()

    answers = {
        "answers": [
            {
                "question_id": question["id"],
                "selected_option_id": question["options"][0]["id"]
            }
            for question in questions
        ]
    }

    auth_client.post("/api/colortype/results", json_data=answers)

    response = auth_client.get("/api/users/me/colortype")

    assert response.status_code == 200
    colortype = response.json()
    assert "color_type" in colortype
    assert "description" in colortype
    assert "recommended_colors" in colortype
    assert "avoid_colors" in colortype