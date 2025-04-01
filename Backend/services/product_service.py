from typing import List, Dict, Optional, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
import math
import random

from Backend.repositories.product_repository import ProductRepository
from Backend.repositories.wardrobe_repository import WardrobeRepository
from Backend.models.schemas import (
    ProductResponse,
    ProductsPage,
    ProductRecommendations,
    ProductRecommendationGroup
)

class ProductService:
    def __init__(self, db: Session):
        self.db = db
        self.product_repository = ProductRepository(db)
        self.wardrobe_repository = WardrobeRepository(db)

    def search_products(self, page: int = 1, size: int = 10, type: Optional[str] = None,
                       color: Optional[str] = None, price_min: Optional[int] = None,
                       price_max: Optional[int] = None, store: Optional[str] = None) -> ProductsPage:
        filters = {}
        if type:
            filters["type"] = type
        if color:
            filters["color"] = color
        if price_min is not None:
            filters["price_min"] = price_min
        if price_max is not None:
            filters["price_max"] = price_max
        if store:
            filters["store"] = store

        skip = (page - 1) * size

        products = self.product_repository.get_products(skip, size, filters)
        total = self.product_repository.count_products(filters)

        total_pages = math.ceil(total / size) if total > 0 else 1

        return ProductsPage(
            items=[ProductResponse.model_validate(product) for product in products],
            total=total,
            page=page,
            size=size,
            pages=total_pages
        )

    def get_recommendations(self, user_id: int) -> ProductRecommendations:
        wardrobe_items = self.wardrobe_repository.get_items(user_id, 0, 100)

        types_in_wardrobe = set(item.type for item in wardrobe_items)
        colors_in_wardrobe = set(item.color for item in wardrobe_items)

        recommendation_groups = []

        missing_types = self._get_missing_item_types(types_in_wardrobe)
        if missing_types:
            missing_type = random.choice(missing_types)
            products = self.product_repository.get_products_by_type(missing_type)
            if products:
                recommendation_groups.append(
                    ProductRecommendationGroup(
                        category=f"Пополните свой гардероб: {missing_type}",
                        products=[ProductResponse.model_validate(product) for product in products]
                    )
                )

        if colors_in_wardrobe:
            color = random.choice(list(colors_in_wardrobe))
            products = self.product_repository.get_products_by_color(color)
            if products:
                recommendation_groups.append(
                    ProductRecommendationGroup(
                        category=f"Подойдет к вашему гардеробу: {color} цвет",
                        products=[ProductResponse.model_validate(product) for product in products]
                    )
                )

        random_types = ["футболка", "джинсы", "платье", "свитер", "рубашка"]
        random_type = random.choice(random_types)
        products = self.product_repository.get_products_by_type(random_type)
        if products:
            recommendation_groups.append(
                ProductRecommendationGroup(
                    category=f"Популярные товары: {random_type}",
                    products=[ProductResponse.model_validate(product) for product in products]
                )
            )

        return ProductRecommendations(recommendations=recommendation_groups)

    def _get_missing_item_types(self, existing_types: set) -> List[str]:
        all_types = {
            "верхняя одежда", "футболка", "рубашка", "свитер",
            "брюки", "джинсы", "юбка", "платье", "обувь", "аксессуар"
        }

        missing = list(all_types - existing_types)
        random.shuffle(missing)
        return missing