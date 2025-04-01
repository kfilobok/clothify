from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..services.colortype_service import ColorTypeService
from ..models.schemas import (
    ColorTypeQuestionResponse,
    ColorTypeSubmit,
    ColorTypeResult,
    UserResponse
)
from ..utils.security import get_current_user

router = APIRouter(prefix="/api/colortype", tags=["colortype"])


@router.get("/questions", response_model=List[ColorTypeQuestionResponse])
def get_questions(db: Session = Depends(get_db)):
    colortype_service = ColorTypeService(db)
    return colortype_service.get_questions()


@router.post("/results", response_model=ColorTypeResult)
def submit_answers(
    answers: ColorTypeSubmit,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    colortype_service = ColorTypeService(db)
    return colortype_service.submit_answers(current_user.id, answers)