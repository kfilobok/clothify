from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_

from Backend.models.domain import Product

class ProductRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_product(self, name: str, type: str, color: str, price: int,
                      store: str, image_url: str, description: Optional[str] = None) -> Product:
        product = Product(
            name=name,
            type=type,
            color=color,
            price=price,
            store=store,
            image_url=image_url,
            description=description
        )
        self.db.add(product)
        self.db.commit()
        self.db.refresh(product)
        return product

    def get_products(self, skip: int = 0, limit: int = 10, filters: Dict[str, Any] = None) -> List[Product]:
        query = self.db.query(Product)

        if filters:
            if filters.get("type"):
                query = query.filter(Product.type == filters["type"])
            if filters.get("color"):
                query = query.filter(Product.color == filters["color"])
            if filters.get("store"):
                query = query.filter(Product.store == filters["store"])
            if filters.get("price_min") is not None:
                query = query.filter(Product.price >= filters["price_min"])
            if filters.get("price_max") is not None:
                query = query.filter(Product.price <= filters["price_max"])

        return query.order_by(desc(Product.created_at)).offset(skip).limit(limit).all()

    def count_products(self, filters: Dict[str, Any] = None) -> int:
        query = self.db.query(Product)

        if filters:
            if filters.get("type"):
                query = query.filter(Product.type == filters["type"])
            if filters.get("color"):
                query = query.filter(Product.color == filters["color"])
            if filters.get("store"):
                query = query.filter(Product.store == filters["store"])
            if filters.get("price_min") is not None:
                query = query.filter(Product.price >= filters["price_min"])
            if filters.get("price_max") is not None:
                query = query.filter(Product.price <= filters["price_max"])

        return query.count()

    def get_product_by_id(self, product_id: int) -> Optional[Product]:
        return self.db.query(Product).filter(Product.id == product_id).first()

    def get_products_by_type(self, type: str, limit: int = 5) -> List[Product]:
        return self.db.query(Product).filter(Product.type == type).limit(limit).all()

    def get_products_by_color(self, color: str, limit: int = 5) -> List[Product]:
        return self.db.query(Product).filter(Product.color == color).limit(limit).all()

    def seed_products(self):
        if self.db.query(Product).count() > 0:
            print("Product data already exists, skipping seed")
            return

        print("Seeding Product data...")
        if self.db.query(Product).count() == 0:
            mock_products = [
                {
                    "name": "Классическая белая футболка",
                    "type": "футболка",
                    "color": "белый",
                    "price": 1500,
                    "store": "Zara",
                    "image_url": "https://example.com/products/tshirt1.jpg",
                    "description": "Базовая хлопковая футболка"
                },
                {
                    "name": "Синие джинсы slim fit",
                    "type": "джинсы",
                    "color": "синий",
                    "price": 3500,
                    "store": "H&M",
                    "image_url": "https://example.com/products/jeans1.jpg",
                    "description": "Джинсы облегающего силуэта"
                },
                {
                    "name": "Черный кожаный пиджак",
                    "type": "верхняя одежда",
                    "color": "черный",
                    "price": 8500,
                    "store": "Mango",
                    "image_url": "https://example.com/products/jacket1.jpg",
                    "description": "Стильный пиджак из искусственной кожи"
                },
                {
                    "name": "Красное платье миди",
                    "type": "платье",
                    "color": "красный",
                    "price": 4500,
                    "store": "Zara",
                    "image_url": "https://example.com/products/dress1.jpg",
                    "description": "Элегантное платье средней длины"
                },
                {
                    "name": "Бежевый тренч",
                    "type": "верхняя одежда",
                    "color": "бежевый",
                    "price": 7500,
                    "store": "Mango",
                    "image_url": "https://example.com/products/trench1.jpg",
                    "description": "Классический тренч"
                },
                {
                    "name": "Серые брюки",
                    "type": "брюки",
                    "color": "серый",
                    "price": 3200,
                    "store": "H&M",
                    "image_url": "https://example.com/products/pants1.jpg",
                    "description": "Классические брюки прямого кроя"
                },
                {
                    "name": "Зеленый свитер",
                    "type": "свитер",
                    "color": "зеленый",
                    "price": 2800,
                    "store": "Pull&Bear",
                    "image_url": "https://example.com/products/sweater1.jpg",
                    "description": "Теплый свитер"
                },
                {
                    "name": "Черные кожаные ботинки",
                    "type": "обувь",
                    "color": "черный",
                    "price": 6500,
                    "store": "Aldo",
                    "image_url": "https://example.com/products/boots1.jpg",
                    "description": "Классические ботинки из натуральной кожи"
                },
                {
                    "name": "Голубая рубашка",
                    "type": "рубашка",
                    "color": "голубой",
                    "price": 2500,
                    "store": "Zara",
                    "image_url": "https://example.com/products/shirt1.jpg",
                    "description": "Рубашка из хлопка"
                },
                {
                    "name": "Белые кроссовки",
                    "type": "обувь",
                    "color": "белый",
                    "price": 5500,
                    "store": "Adidas",
                    "image_url": "https://example.com/products/sneakers1.jpg",
                    "description": "Спортивные кроссовки"
                }
            ]

            for product_data in mock_products:
                self.create_product(**product_data)