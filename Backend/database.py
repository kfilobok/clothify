from sqlalchemy import create_engine, inspect
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import Generator
import os
import sqlite3

from Backend.config import get_settings

settings = get_settings()

SQLALCHEMY_DATABASE_URL = settings.database_url

# Для SQLite
if SQLALCHEMY_DATABASE_URL.startswith('sqlite'):
    engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def db_exists():
    """Проверка существования базы данных."""
    if SQLALCHEMY_DATABASE_URL.startswith('sqlite'):
        # Для SQLite проверяем существование файла
        db_path = SQLALCHEMY_DATABASE_URL.replace('sqlite:///', '')
        return os.path.exists(db_path)
    else:
        # Для других БД проверяем наличие хотя бы одной таблицы
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        return len(tables) > 0

def create_tables():
    """Создание таблиц, если они не существуют."""
    # Создаем все таблицы, определенные в моделях
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def update_db_structure():
    """Обновляет структуру базы данных, добавляя недостающие колонки."""
    if SQLALCHEMY_DATABASE_URL.startswith('sqlite'):
        from sqlalchemy import text

        # Получим путь к файлу БД
        db_path = SQLALCHEMY_DATABASE_URL.replace('sqlite:///', '')

        # Используем низкоуровневый SQLite API для миграции
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            # Проверяем, есть ли колонка favorite_outfits
            cursor.execute("PRAGMA table_info(users)")
            columns = [info[1] for info in cursor.fetchall()]

            if 'favorite_outfits' not in columns:
                print("Adding favorite_outfits column to users table")
                cursor.execute("ALTER TABLE users ADD COLUMN favorite_outfits TEXT DEFAULT ''")
                conn.commit()
                print("Column added successfully")

                # Закрываем соединение для освобождения ресурсов
                cursor.close()
                conn.close()

                # Перезагружаем метаданные SQLAlchemy, чтобы увидеть новую структуру
                Base.metadata.clear()
                Base.metadata.create_all(bind=engine)
                print("SQLAlchemy metadata refreshed")

                return True
            return False
        except Exception as e:
            print(f"Error in direct SQLite update: {e}")
            return False