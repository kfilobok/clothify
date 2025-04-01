from sqlalchemy.orm import Session
from typing import Optional, List

from Backend.models.domain import User
from Backend.utils.security import get_password_hash


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, email: str, name: str, password: str) -> User:
        user = User(
            email=email,
            name=name,
            password_hash=get_password_hash(password)
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def update_color_type(self, user_id: int, color_type: str) -> Optional[User]:
        user = self.get_by_id(user_id)
        if user:
            user.color_type = color_type
            self.db.commit()
            self.db.refresh(user)
        return user

    def update_onboarding_status(self, user_id: int, status: bool) -> Optional[User]:
        user = self.get_by_id(user_id)
        if user:
            user.onboarding_completed = status
            self.db.commit()
            self.db.refresh(user)
        return user

    def get_favorite_outfits(self, user_id: int) -> List[int]:
        user = self.get_by_id(user_id)
        if not user or not user.favorite_outfits:
            return []

        return [int(outfit_id) for outfit_id in user.favorite_outfits.split(",") if outfit_id]

    def add_favorite_outfit(self, user_id: int, outfit_id: int) -> bool:
        user = self.get_by_id(user_id)
        if not user:
            return False

        favorite_ids = self.get_favorite_outfits(user_id)

        if outfit_id in favorite_ids:
            return True

        favorite_ids.append(outfit_id)
        user.favorite_outfits = ",".join(str(id) for id in favorite_ids)

        self.db.commit()
        self.db.refresh(user)
        return True

    def remove_favorite_outfit(self, user_id: int, outfit_id: int) -> bool:
        user = self.get_by_id(user_id)
        if not user:
            return False

        favorite_ids = self.get_favorite_outfits(user_id)

        if outfit_id not in favorite_ids:
            return True

        favorite_ids.remove(outfit_id)
        user.favorite_outfits = ",".join(str(id) for id in favorite_ids)

        self.db.commit()
        self.db.refresh(user)
        return True