from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc

from Backend.models.domain import Outfit, OutfitItem, WardrobeItem

class OutfitRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_outfit(self, user_id: int, name: str, occasion: str, is_favorite: bool = False) -> Outfit:
        outfit = Outfit(
            user_id=user_id,
            name=name,
            occasion=occasion,
            is_favorite=is_favorite
        )
        self.db.add(outfit)
        self.db.commit()
        self.db.refresh(outfit)
        return outfit

    def add_item_to_outfit(self, outfit_id: int, wardrobe_item_id: int) -> OutfitItem:
        outfit_item = OutfitItem(
            outfit_id=outfit_id,
            wardrobe_item_id=wardrobe_item_id
        )
        self.db.add(outfit_item)
        self.db.commit()
        self.db.refresh(outfit_item)
        return outfit_item

    def get_outfits(self, user_id: int, skip: int = 0, limit: int = 10, filters: Dict[str, Any] = None) -> List[Outfit]:
        query = self.db.query(Outfit).filter(Outfit.user_id == user_id)

        if filters:
            if filters.get("occasion"):
                query = query.filter(Outfit.occasion == filters["occasion"])
            if filters.get("is_favorite") is not None:
                query = query.filter(Outfit.is_favorite == filters["is_favorite"])

        return query.order_by(desc(Outfit.created_at)).offset(skip).limit(limit).all()

    def count_outfits(self, user_id: int, filters: Dict[str, Any] = None) -> int:
        query = self.db.query(Outfit).filter(Outfit.user_id == user_id)

        if filters:
            if filters.get("occasion"):
                query = query.filter(Outfit.occasion == filters["occasion"])
            if filters.get("is_favorite") is not None:
                query = query.filter(Outfit.is_favorite == filters["is_favorite"])

        return query.count()

    def get_outfit_by_id(self, outfit_id: int, user_id: int) -> Optional[Outfit]:
        return self.db.query(Outfit).filter(
            Outfit.id == outfit_id,
            Outfit.user_id == user_id
        ).first()

    def update_outfit(self, outfit_id: int, user_id: int, update_data: Dict[str, Any]) -> Optional[Outfit]:
        outfit = self.get_outfit_by_id(outfit_id, user_id)
        if not outfit:
            return None

        for key, value in update_data.items():
            if key != "items" and value is not None:
                setattr(outfit, key, value)

        self.db.commit()
        self.db.refresh(outfit)
        return outfit

    def delete_outfit(self, outfit_id: int, user_id: int) -> bool:
        outfit = self.get_outfit_by_id(outfit_id, user_id)
        if not outfit:
            return False

        self.db.delete(outfit)
        self.db.commit()
        return True

    def clear_outfit_items(self, outfit_id: int) -> None:
        self.db.query(OutfitItem).filter(OutfitItem.outfit_id == outfit_id).delete()
        self.db.commit()

    def get_wardrobe_items_by_type(self, user_id: int, item_type: str) -> List[WardrobeItem]:
        return self.db.query(WardrobeItem).filter(
            WardrobeItem.user_id == user_id,
            WardrobeItem.type == item_type
        ).all()