from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from Backend.database import get_db
from Backend.services.wardrobe_service import WardrobeService
from Backend.models.schemas import WardrobeItemCreate, WardrobeItemUpdate, WardrobeItemResponse, WardrobeItemsPage, UserResponse
from Backend.utils.security import get_current_user

router = APIRouter(prefix="/api/wardrobe", tags=["wardrobe"])

@router.get("/items", response_model=WardrobeItemsPage)
def get_wardrobe_items(
    page: int = 1,
    size: int = 10,
    type: Optional[str] = None,
    color: Optional[str] = None,
    season: Optional[str] = None,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wardrobe_service = WardrobeService(db)
    return wardrobe_service.get_items(current_user.id, page, size, type, color, season)

@router.post("/items", response_model=WardrobeItemResponse)
def create_wardrobe_item(
    item_data: WardrobeItemCreate,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wardrobe_service = WardrobeService(db)
    return wardrobe_service.create_item(current_user.id, item_data)

@router.put("/items/{item_id}", response_model=WardrobeItemResponse)
def update_wardrobe_item(
    item_id: int,
    item_data: WardrobeItemUpdate,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wardrobe_service = WardrobeService(db)
    return wardrobe_service.update_item(item_id, current_user.id, item_data)

@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_wardrobe_item(
    item_id: int,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wardrobe_service = WardrobeService(db)
    wardrobe_service.delete_item(item_id, current_user.id)
    return None