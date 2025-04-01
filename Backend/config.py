from functools import lru_cache
from pydantic_settings import BaseSettings
import os


class Settings(BaseSettings):
    database_url: str = "sqlite:///./clothify.db"
    secret_key: str = "your-secret-key"
    token_expire_minutes: int = 60 * 24 * 7  # 7 days
    api_base_url: str = "http://localhost:8000"
    environment: str = "development"
    algorithm: str = "HS256"

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings():
    return Settings()