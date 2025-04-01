from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import os

# Используем абсолютные импорты
from Backend.database import create_tables, SessionLocal, db_exists, update_db_structure
from Backend.repositories.colortype_repository import ColorTypeRepository
from Backend.repositories.product_repository import ProductRepository
from Backend.api import auth, colortype, users, wardrobe, outfit, ml, products

app = FastAPI(title="Clothify API")

# Настраиваем CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Для продакшена нужно указать конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Монтируем директорию uploads для доступа к загруженным файлам
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Подключаем роутеры API
app.include_router(auth.router)
app.include_router(colortype.router)
app.include_router(users.router)
app.include_router(wardrobe.router)
app.include_router(outfit.router)
app.include_router(ml.router)
app.include_router(products.router)


# Создаем таблицы в БД при запуске
@app.on_event("startup")
async def startup_event():
    # Обновляем структуру БД до создания таблиц
    structure_updated = update_db_structure()

    # Создаем таблицы (только если структура не была обновлена)
    if not structure_updated:
        create_tables()

    # Если БД не существовала ранее или в ней нет данных, заполняем ее
    if not db_exists():
        db = SessionLocal()
        try:
            colortype_repo = ColorTypeRepository(db)
            colortype_repo.seed_data()

            product_repo = ProductRepository(db)
            product_repo.seed_products()

            print("Database initialized with seed data")
        finally:
            db.close()
    else:
        print("Using existing database")


@app.get("/")
def read_root():
    return {"message": "Welcome to Clothify API"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("Backend.main:app", host="0.0.0.0", port=8000, reload=True)
