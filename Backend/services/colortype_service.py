from typing import List, Dict
from collections import Counter
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
import random

from ..repositories.colortype_repository import ColorTypeRepository
from ..repositories.user_repository import UserRepository
from ..models.schemas import (
    ColorTypeQuestionResponse,
    ColorTypeSubmit,
    ColorTypeResult,
    ColorRecommendation,
    ColorRecommendations
)


class ColorTypeService:
    def __init__(self, db: Session):
        self.db = db
        self.colortype_repository = ColorTypeRepository(db)
        self.user_repository = UserRepository(db)

    def get_questions(self) -> List[ColorTypeQuestionResponse]:
        questions = self.colortype_repository.get_questions()
        return [ColorTypeQuestionResponse.model_validate(q) for q in questions]

    def submit_answers(self, user_id: int, answers: ColorTypeSubmit) -> ColorTypeResult:
        all_valid = True

        style_counters = {
            "casual": 0,
            "classic": 0,
            "oldmoney": 0,
            "sport": 0,
            "grunge": 0
        }

        for answer in answers.answers:
            question = self.colortype_repository.get_question_by_id(answer.question_id)
            if not question:
                all_valid = False
                break

            option = self.colortype_repository.get_option_by_id(answer.selected_option_id)
            if not option or option.question_id != answer.question_id:
                all_valid = False
                break

            styles = option.value.split(',')
            for style in styles:
                style_counters[style] += 1

        if not all_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid question or option IDs"
            )

        max_count = max(style_counters.values())
        top_styles = [style for style, count in style_counters.items() if count == max_count]

        determined_style = random.choice(top_styles)

        style_info = self.colortype_repository.get_color_type_by_name(determined_style)
        if not style_info:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Style information not found in database."
            )

        self.user_repository.update_color_type(user_id, determined_style)

        return ColorTypeResult(
            color_type=determined_style,
            description=style_info.description,
            recommended_colors=style_info.recommended_colors,
            avoid_colors=style_info.avoid_colors
        )

    def get_color_recommendations(self, user_id: int) -> ColorRecommendations:
        user = self.user_repository.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        if not user.color_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Style test not completed"
            )

        style_info = self.colortype_repository.get_color_type_by_name(user.color_type)
        if not style_info:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Style information not found"
            )

        recommendations = [
            ColorRecommendation(
                category="Верхняя одежда",
                colors=style_info.recommended_colors[:2]
            ),
            ColorRecommendation(
                category="Футболки и рубашки",
                colors=style_info.recommended_colors[1:3]
            ),
            ColorRecommendation(
                category="Брюки и джинсы",
                colors=style_info.recommended_colors[2:4]
            ),
            ColorRecommendation(
                category="Обувь",
                colors=style_info.recommended_colors[3:5]
            ),
            ColorRecommendation(
                category="Аксессуары",
                colors=style_info.recommended_colors[4:]
            )
        ]

        return ColorRecommendations(recommendations=recommendations)

    def get_user_colortype(self, user_id: int) -> ColorTypeResult:
        user = self.user_repository.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found."
            )

        if not user.color_type:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has not completed style test. Color type not found."
            )

        style_info = self.colortype_repository.get_color_type_by_name(user.color_type)
        if not style_info:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Style information not found in database."
            )

        return ColorTypeResult(
            color_type=user.color_type,
            description=style_info.description,
            recommended_colors=style_info.recommended_colors,
            avoid_colors=style_info.avoid_colors
        )