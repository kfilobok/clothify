from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from Backend.database import get_db
from Backend.services.product_service import ProductService
from Backend.models.schemas import ProductsPage, ProductRecommendations, UserResponse
from Backend.utils.security import get_current_user

router = APIRouter(prefix="/api/products", tags=["products"])

@router.get("/search", response_model=ProductsPage)
def search_products(
    page: int = 1,
    size: int = 10,
    type: Optional[str] = None,
    color: Optional[str] = None,
    price_min: Optional[int] = None,
    price_max: Optional[int] = None,
    store: Optional[str] = None,
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    return product_service.search_products(page, size, type, color, price_min, price_max, store)

@router.get("/recommendations", response_model=ProductRecommendations)
def get_product_recommendations(
    current_user: UserResponse = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    product_service = ProductService(db)
    return product_service.get_recommendations(current_user.id)