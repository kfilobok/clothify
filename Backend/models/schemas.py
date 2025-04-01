from typing import List, Dict, Optional, Any
from pydantic import BaseModel, EmailStr
from datetime import datetime


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    color_type: Optional[str] = None
    onboarding_completed: bool

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse


class ColorTypeOptionResponse(BaseModel):
    id: int
    text: str
    value: str

    class Config:
        from_attributes = True


class ColorTypeQuestionResponse(BaseModel):
    id: int
    text: str
    options: List[ColorTypeOptionResponse]

    class Config:
        from_attributes = True


class ColorTypeAnswer(BaseModel):
    question_id: int
    selected_option_id: int


class ColorTypeSubmit(BaseModel):
    answers: List[ColorTypeAnswer]


class ColorTypeResult(BaseModel):
    color_type: str
    description: str
    recommended_colors: List[str]
    avoid_colors: List[str]


class OnboardingUpdate(BaseModel):
    onboarding_completed: bool


class ColorRecommendation(BaseModel):
    category: str
    colors: List[str]


class ColorRecommendations(BaseModel):
    recommendations: List[ColorRecommendation]


class WardrobeItemBase(BaseModel):
    name: str
    type: str
    color: str
    season: str
    image_url: Optional[str] = None


class WardrobeItemCreate(WardrobeItemBase):
    pass


class WardrobeItemUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    color: Optional[str] = None
    season: Optional[str] = None
    image_url: Optional[str] = None


class WardrobeItemResponse(WardrobeItemBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class WardrobeItemsPage(BaseModel):
    items: List[WardrobeItemResponse]
    total: int
    page: int
    size: int
    pages: int


class OutfitItemCreate(BaseModel):
    wardrobe_item_id: int


class OutfitCreate(BaseModel):
    name: str
    occasion: str
    is_favorite: Optional[bool] = False
    items: List[OutfitItemCreate]


class OutfitItemResponse(BaseModel):
    id: int
    wardrobe_item_id: int
    wardrobe_item: WardrobeItemResponse

    class Config:
        from_attributes = True


class OutfitUpdate(BaseModel):
    name: Optional[str] = None
    occasion: Optional[str] = None
    is_favorite: Optional[bool] = None
    items: Optional[List[OutfitItemCreate]] = None


class OutfitResponse(BaseModel):
    id: int
    user_id: int
    name: str
    occasion: str
    is_favorite: bool
    created_at: datetime
    items: List[OutfitItemResponse]

    class Config:
        from_attributes = True


class OutfitsPage(BaseModel):
    items: List[OutfitResponse]
    total: int
    page: int
    size: int
    pages: int


class OutfitRecommendationItem(BaseModel):
    wardrobe_item_id: Optional[int] = None
    product_id: Optional[int] = None
    name: str
    type: str
    color: str
    image_url: str
    is_existing: bool


class OutfitRecommendationType(BaseModel):
    type: str
    description: str
    items: List[OutfitRecommendationItem]


class OutfitRecommendations(BaseModel):
    recommendations: List[OutfitRecommendationType]


class MLImageUpload(BaseModel):
    file_data: str
    file_name: str


class DetectedClothing(BaseModel):
    type: str
    color: str
    confidence: float
    x: int
    y: int
    width: int
    height: int


class RecognizeResponse(BaseModel):
    detected_items: List[DetectedClothing]


class SegmentationResponse(BaseModel):
    segmented_image_url: str


class ProductBase(BaseModel):
    name: str
    type: str
    color: str
    price: int
    store: str
    image_url: str
    description: Optional[str] = None


class ProductCreate(ProductBase):
    pass


class ProductResponse(ProductBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class ProductsPage(BaseModel):
    items: List[ProductResponse]
    total: int
    page: int
    size: int
    pages: int


class ProductSearchParams(BaseModel):
    type: Optional[str] = None
    color: Optional[str] = None
    price_min: Optional[int] = None
    price_max: Optional[int] = None
    store: Optional[str] = None


class ProductRecommendationGroup(BaseModel):
    category: str
    products: List[ProductResponse]


class ProductRecommendations(BaseModel):
    recommendations: List[ProductRecommendationGroup]