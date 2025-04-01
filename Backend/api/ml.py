from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from Backend.database import get_db
from Backend.services.ml_service import MLService
from Backend.models.schemas import MLImageUpload, RecognizeResponse, SegmentationResponse, UserResponse
from Backend.utils.security import get_current_user

router = APIRouter(prefix="/api/ml", tags=["ml"])

@router.post("/recognize", response_model=RecognizeResponse)
def recognize_clothing(
    image_data: MLImageUpload,
    current_user: UserResponse = Depends(get_current_user)
):
    ml_service = MLService()
    return ml_service.recognize_clothing(image_data)

@router.post("/segment", response_model=SegmentationResponse)
def segment_image(
    image_data: MLImageUpload,
    current_user: UserResponse = Depends(get_current_user)
):
    ml_service = MLService()
    return ml_service.segment_image(image_data)