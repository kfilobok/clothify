from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, JSON, Text, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime

from ..database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    password_hash = Column(String)
    color_type = Column(String, nullable=True)
    onboarding_completed = Column(Boolean, default=False)
    favorite_outfits = Column(String, default="")

    wardrobe_items = relationship("WardrobeItem", back_populates="user")
    outfits = relationship("Outfit", back_populates="user")


class ColorTypeQuestion(Base):
    __tablename__ = "colortype_questions"

    id = Column(Integer, primary_key=True, index=True)
    text = Column(String)

    options = relationship("ColorTypeOption", back_populates="question")


class ColorTypeOption(Base):
    __tablename__ = "colortype_options"

    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("colortype_questions.id"))
    text = Column(String)
    value = Column(String)

    question = relationship("ColorTypeQuestion", back_populates="options")


class ColorType(Base):
    __tablename__ = "colortypes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(Text)
    recommended_colors = Column(JSON)
    avoid_colors = Column(JSON)


class WardrobeItem(Base):
    __tablename__ = "wardrobe_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String)
    type = Column(String, index=True)
    color = Column(String, index=True)
    season = Column(String, index=True)
    image_url = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="wardrobe_items")


class Outfit(Base):
    __tablename__ = "outfits"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String)
    occasion = Column(String, index=True)
    is_favorite = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="outfits")
    items = relationship("OutfitItem", back_populates="outfit", cascade="all, delete-orphan")


class OutfitItem(Base):
    __tablename__ = "outfit_items"

    id = Column(Integer, primary_key=True, index=True)
    outfit_id = Column(Integer, ForeignKey("outfits.id"))
    wardrobe_item_id = Column(Integer, ForeignKey("wardrobe_items.id"))

    outfit = relationship("Outfit", back_populates="items")
    wardrobe_item = relationship("WardrobeItem")


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    type = Column(String, index=True)
    color = Column(String, index=True)
    price = Column(Integer)
    store = Column(String, index=True)
    image_url = Column(String)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)