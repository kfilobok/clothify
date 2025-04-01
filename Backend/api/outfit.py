from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from Backend.database import get_db
from Backend.services.outfit_service import OutfitService
from Backend.models.schemas import (
    OutfitCreate,
    OutfitUpdate,
    OutfitResponse,
    OutfitsPage,
    OutfitRecommendations,
    UserResponse
)
from Backend.utils.security import get_current_user

router = APIRouter(prefix="/api/outfits", tags=["outfits"])

@router.get("", response_model=OutfitsPage)
def get_outfits(
    page: int = 1,
    size: int = 10,
    occasion: Optional[str] = None,
    is_favorite: Optional[bool] = None,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    outfit_service = OutfitService(db)
    return outfit_service.get_outfits(current_user.id, page, size, occasion, is_favorite)

@router.post("", response_model=OutfitResponse)
def create_outfit(
    outfit_data: OutfitCreate,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    outfit_service = OutfitService(db)
    return outfit_service.create_outfit(current_user.id, outfit_data)

@router.get("/{outfit_id}", response_model=OutfitResponse)
def get_outfit(
    outfit_id: int,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    outfit_service = OutfitService(db)
    return outfit_service.get_outfit(outfit_id, current_user.id)

@router.put("/{outfit_id}", response_model=OutfitResponse)
def update_outfit(
    outfit_id: int,
    outfit_data: OutfitUpdate,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    outfit_service = OutfitService(db)
    return outfit_service.update_outfit(outfit_id, current_user.id, outfit_data)

@router.delete("/{outfit_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_outfit(
    outfit_id: int,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    outfit_service = OutfitService(db)
    outfit_service.delete_outfit(outfit_id, current_user.id)
    return None

@router.get("/{outfit_id}/recommendations", response_model=OutfitRecommendations)
def get_outfit_recommendations(
    outfit_id: int,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    outfit_service = OutfitService(db)
    return outfit_service.get_recommendations(outfit_id, current_user.id)