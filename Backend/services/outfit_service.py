from typing import List, Dict, Optional, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
import math
import random

from Backend.repositories.outfit_repository import OutfitRepository
from Backend.repositories.wardrobe_repository import WardrobeRepository
from Backend.models.domain import WardrobeItem
from Backend.models.schemas import (
    OutfitCreate,
    OutfitUpdate,
    OutfitResponse,
    OutfitsPage,
    OutfitRecommendations,
    OutfitRecommendationType,
    OutfitRecommendationItem
)

class OutfitService:
    def __init__(self, db: Session):
        self.db = db
        self.outfit_repository = OutfitRepository(db)
        self.wardrobe_repository = WardrobeRepository(db)

    def get_outfits(self, user_id: int, page: int = 1, size: int = 10,
                  occasion: Optional[str] = None, is_favorite: Optional[bool] = None) -> OutfitsPage:
        filters = {}
        if occasion:
            filters["occasion"] = occasion
        if is_favorite is not None:
            filters["is_favorite"] = is_favorite

        skip = (page - 1) * size

        outfits = self.outfit_repository.get_outfits(user_id, skip, size, filters)
        total = self.outfit_repository.count_outfits(user_id, filters)

        total_pages = math.ceil(total / size) if total > 0 else 1

        return OutfitsPage(
            items=[OutfitResponse.model_validate(outfit) for outfit in outfits],
            total=total,
            page=page,
            size=size,
            pages=total_pages
        )

    def create_outfit(self, user_id: int, outfit_data: OutfitCreate) -> OutfitResponse:
        outfit = self.outfit_repository.create_outfit(
            user_id=user_id,
            name=outfit_data.name,
            occasion=outfit_data.occasion,
            is_favorite=outfit_data.is_favorite
        )

        for item in outfit_data.items:
            wardrobe_item = self.wardrobe_repository.get_item_by_id(item.wardrobe_item_id, user_id)
            if not wardrobe_item:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Wardrobe item with id {item.wardrobe_item_id} not found"
                )

            self.outfit_repository.add_item_to_outfit(outfit.id, item.wardrobe_item_id)

        updated_outfit = self.outfit_repository.get_outfit_by_id(outfit.id, user_id)
        return OutfitResponse.model_validate(updated_outfit)

    def update_outfit(self, outfit_id: int, user_id: int, outfit_data: OutfitUpdate) -> OutfitResponse:
        outfit = self.outfit_repository.get_outfit_by_id(outfit_id, user_id)
        if not outfit:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Outfit not found"
            )

        update_data = outfit_data.model_dump(exclude_unset=True)

        if "items" in update_data:
            items = update_data.pop("items")
            self.outfit_repository.clear_outfit_items(outfit_id)

            for item in items:
                wardrobe_item = self.wardrobe_repository.get_item_by_id(item["wardrobe_item_id"], user_id)
                if not wardrobe_item:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Wardrobe item with id {item['wardrobe_item_id']} not found"
                    )

                self.outfit_repository.add_item_to_outfit(outfit_id, item["wardrobe_item_id"])

        updated_outfit = self.outfit_repository.update_outfit(outfit_id, user_id, update_data)
        updated_outfit = self.outfit_repository.get_outfit_by_id(outfit_id, user_id)

        return OutfitResponse.model_validate(updated_outfit)

    def get_outfit(self, outfit_id: int, user_id: int) -> OutfitResponse:
        outfit = self.outfit_repository.get_outfit_by_id(outfit_id, user_id)
        if not outfit:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Outfit not found"
            )

        return OutfitResponse.model_validate(outfit)

    def delete_outfit(self, outfit_id: int, user_id: int) -> bool:
        success = self.outfit_repository.delete_outfit(outfit_id, user_id)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Outfit not found"
            )

        return True

    def get_recommendations(self, outfit_id: int, user_id: int) -> OutfitRecommendations:
        outfit = self.outfit_repository.get_outfit_by_id(outfit_id, user_id)
        if not outfit:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Outfit not found"
            )

        outfit_item_types = set()
        for item in outfit.items:
            outfit_item_types.add(item.wardrobe_item.type)

        completion_items = []
        missing_types = self._get_missing_item_types(outfit_item_types)

        for item_type in missing_types[:2]:  # Берём только 2 типа для рекомендаций
            wardrobe_items = self.outfit_repository.get_wardrobe_items_by_type(user_id, item_type)
            if wardrobe_items:
                for item in wardrobe_items[:2]:  # Берём только 2 предмета каждого типа
                    completion_items.append(
                        OutfitRecommendationItem(
                            wardrobe_item_id=item.id,
                            name=item.name,
                            type=item.type,
                            color=item.color,
                            image_url=item.image_url,
                            is_existing=True
                        )
                    )

        alternative_items = []
        for outfit_item in outfit.items:
            similar_items = self._get_similar_items(user_id, outfit_item.wardrobe_item)
            for item in similar_items[:2]:  # Берём только 2 альтернативы для каждого предмета
                if item.id != outfit_item.wardrobe_item_id:
                    alternative_items.append(
                        OutfitRecommendationItem(
                            wardrobe_item_id=item.id,
                            name=item.name,
                            type=item.type,
                            color=item.color,
                            image_url=item.image_url,
                            is_existing=True
                        )
                    )

        expansion_items = []
        for i in range(3):
            expansion_items.append(
                OutfitRecommendationItem(
                    product_id=i + 1,
                    name=f"Стильный {self._get_random_item_type()}",
                    type=self._get_random_item_type(),
                    color=self._get_random_color(),
                    image_url=f"https://example.com/product{i+1}.jpg",
                    is_existing=False
                )
            )

        recommendations = [
            OutfitRecommendationType(
                type="completion",
                description="Рекомендуемые предметы для завершения образа",
                items=completion_items
            ),
            OutfitRecommendationType(
                type="alternative",
                description="Альтернативные предметы для замены",
                items=alternative_items
            ),
            OutfitRecommendationType(
                type="expansion",
                description="Предметы для расширения образа из магазинов",
                items=expansion_items
            )
        ]

        return OutfitRecommendations(recommendations=recommendations)

    def _get_missing_item_types(self, existing_types: set) -> List[str]:
        all_types = {
            "верхняя одежда", "футболка", "рубашка", "свитер",
            "брюки", "джинсы", "юбка", "платье", "обувь", "аксессуар"
        }

        missing = list(all_types - existing_types)
        random.shuffle(missing)
        return missing

    def _get_similar_items(self, user_id: int, item: WardrobeItem) -> List[WardrobeItem]:
        similar_items = self.db.query(WardrobeItem).filter(
            WardrobeItem.user_id == user_id,
            WardrobeItem.type == item.type,
            WardrobeItem.id != item.id
        ).all()

        return similar_items

    def _get_random_item_type(self) -> str:
        types = ["футболка", "рубашка", "свитер", "брюки", "джинсы", "платье", "обувь", "аксессуар"]
        return random.choice(types)

    def _get_random_color(self) -> str:
        colors = ["черный", "белый", "синий", "красный", "зеленый", "желтый", "серый", "бежевый"]
        return random.choice(colors)