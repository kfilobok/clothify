from datetime import timedelta
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from Backend.repositories.user_repository import UserRepository
from Backend.utils.security import verify_password, create_access_token
from Backend.models.schemas import UserCreate, UserLogin, Token, UserResponse
from Backend.config import get_settings

settings = get_settings()


class AuthService:
    def __init__(self, db: Session):
        self.db = db
        self.user_repository = UserRepository(db)

    def register(self, user_data: UserCreate) -> Token:
        existing_user = self.user_repository.get_by_email(user_data.email)

        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This email is already registered. Please use a different email or try logging in."
            )

        user = self.user_repository.create(
            email=user_data.email,
            name=user_data.name,
            password=user_data.password
        )

        access_token = create_access_token(data={"sub": user.email})

        return Token(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse.model_validate(user)
        )

    def login(self, user_data: UserLogin) -> Token:
        user = self.user_repository.get_by_email(user_data.email)

        if not user or not verify_password(user_data.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password. Please check your credentials and try again.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        access_token = create_access_token(data={"sub": user.email})

        return Token(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse.model_validate(user)
        )

    def login_with_form(self, username: str, password: str) -> Token:
        user = self.user_repository.get_by_email(username)

        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password. Please check your credentials and try again.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        access_token = create_access_token(data={"sub": user.email})

        return Token(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse.model_validate(user)
        )

    def get_profile(self, user_id: int) -> UserResponse:
        user = self.user_repository.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found."
            )

        return UserResponse.model_validate(user)