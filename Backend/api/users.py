from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..repositories.user_repository import UserRepository
from ..services.colortype_service import ColorTypeService
from ..models.schemas import (
    OnboardingUpdate,
    UserResponse,
    ColorRecommendations,
    ColorTypeResult
)
from ..utils.security import get_current_user

router = APIRouter(prefix="/api/users", tags=["users"])


@router.put("/me/onboarding", response_model=UserResponse)
def update_onboarding_status(
    onboarding_data: OnboardingUpdate,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    updated_user = user_repo.update_onboarding_status(
        current_user.id,
        onboarding_data.onboarding_completed
    )

    if not updated_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found."
        )

    return UserResponse.model_validate(updated_user)


@router.get("/me/recommendations", response_model=ColorRecommendations)
def get_color_recommendations(
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    colortype_service = ColorTypeService(db)
    return colortype_service.get_color_recommendations(current_user.id)


@router.get("/me/favorites", response_model=List[int])
def get_favorite_outfits(
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    return user_repo.get_favorite_outfits(current_user.id)


@router.post("/me/favorites/{outfit_id}", status_code=status.HTTP_200_OK)
def add_favorite_outfit(
    outfit_id: int,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    success = user_repo.add_favorite_outfit(current_user.id, outfit_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to add outfit to favorites"
        )

    return {"success": True}


@router.delete("/me/favorites/{outfit_id}", status_code=status.HTTP_200_OK)
def remove_favorite_outfit(
    outfit_id: int,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_repo = UserRepository(db)
    success = user_repo.remove_favorite_outfit(current_user.id, outfit_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to remove outfit from favorites"
        )

    return {"success": True}


@router.get("/me/colortype", response_model=ColorTypeResult)
def get_user_colortype(
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    colortype_service = ColorTypeService(db)
    return colortype_service.get_user_colortype(current_user.id)