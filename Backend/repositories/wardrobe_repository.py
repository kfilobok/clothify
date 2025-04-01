from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc

from Backend.models.domain import WardrobeItem

class WardrobeRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_item(self, user_id: int, name: str, type: str, color: str, season: str, image_url: Optional[str] = None) -> WardrobeItem:
        item = WardrobeItem(
            user_id=user_id,
            name=name,
            type=type,
            color=color,
            season=season,
            image_url=image_url
        )
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def get_items(self, user_id: int, skip: int = 0, limit: int = 10, filters: Dict[str, Any] = None) -> List[WardrobeItem]:
        query = self.db.query(WardrobeItem).filter(WardrobeItem.user_id == user_id)

        if filters:
            if filters.get("type"):
                query = query.filter(WardrobeItem.type == filters["type"])
            if filters.get("color"):
                query = query.filter(WardrobeItem.color == filters["color"])
            if filters.get("season"):
                query = query.filter(WardrobeItem.season == filters["season"])

        return query.order_by(desc(WardrobeItem.created_at)).offset(skip).limit(limit).all()

    def count_items(self, user_id: int, filters: Dict[str, Any] = None) -> int:
        query = self.db.query(WardrobeItem).filter(WardrobeItem.user_id == user_id)

        if filters:
            if filters.get("type"):
                query = query.filter(WardrobeItem.type == filters["type"])
            if filters.get("color"):
                query = query.filter(WardrobeItem.color == filters["color"])
            if filters.get("season"):
                query = query.filter(WardrobeItem.season == filters["season"])

        return query.count()

    def get_item_by_id(self, item_id: int, user_id: int) -> Optional[WardrobeItem]:
        return self.db.query(WardrobeItem).filter(
            WardrobeItem.id == item_id,
            WardrobeItem.user_id == user_id
        ).first()

    def update_item(self, item_id: int, user_id: int, update_data: Dict[str, Any]) -> Optional[WardrobeItem]:
        item = self.get_item_by_id(item_id, user_id)
        if not item:
            return None

        for key, value in update_data.items():
            if value is not None:
                setattr(item, key, value)

        self.db.commit()
        self.db.refresh(item)
        return item

    def delete_item(self, item_id: int, user_id: int) -> bool:
        item = self.get_item_by_id(item_id, user_id)
        if not item:
            return False

        self.db.delete(item)
        self.db.commit()
        return True