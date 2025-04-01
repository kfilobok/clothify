from typing import List, Dict, Optional, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
import math

from Backend.repositories.wardrobe_repository import WardrobeRepository
from Backend.models.schemas import WardrobeItemCreate, WardrobeItemUpdate, WardrobeItemResponse, WardrobeItemsPage

class WardrobeService:
    def __init__(self, db: Session):
        self.db = db
        self.wardrobe_repository = WardrobeRepository(db)

    def get_items(self, user_id: int, page: int = 1, size: int = 10, type: Optional[str] = None,
                 color: Optional[str] = None, season: Optional[str] = None) -> WardrobeItemsPage:
        filters = {}
        if type:
            filters["type"] = type
        if color:
            filters["color"] = color
        if season:
            filters["season"] = season

        skip = (page - 1) * size

        items = self.wardrobe_repository.get_items(user_id, skip, size, filters)
        total = self.wardrobe_repository.count_items(user_id, filters)

        total_pages = math.ceil(total / size) if total > 0 else 1

        return WardrobeItemsPage(
            items=[WardrobeItemResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            size=size,
            pages=total_pages
        )

    def create_item(self, user_id: int, item_data: WardrobeItemCreate) -> WardrobeItemResponse:
        item = self.wardrobe_repository.create_item(
            user_id=user_id,
            name=item_data.name,
            type=item_data.type,
            color=item_data.color,
            season=item_data.season,
            image_url=item_data.image_url
        )

        return WardrobeItemResponse.model_validate(item)

    def update_item(self, item_id: int, user_id: int, item_data: WardrobeItemUpdate) -> WardrobeItemResponse:
        update_data = item_data.model_dump(exclude_unset=True)

        updated_item = self.wardrobe_repository.update_item(item_id, user_id, update_data)

        if not updated_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item not found"
            )

        return WardrobeItemResponse.model_validate(updated_item)

    def delete_item(self, item_id: int, user_id: int) -> bool:
        success = self.wardrobe_repository.delete_item(item_id, user_id)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item not found"
            )

        return True