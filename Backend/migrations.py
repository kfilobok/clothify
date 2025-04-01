from sqlalchemy import create_engine, Column, String
from sqlalchemy.ext.declarative import declarative_base
from Backend.config import get_settings

settings = get_settings()
engine = create_engine(settings.database_url)
Base = declarative_base()

def add_favorites_column():
    from sqlalchemy import text
    with engine.connect() as conn:
        conn.execute(text("ALTER TABLE users ADD COLUMN favorite_outfits TEXT DEFAULT ''"))
        conn.commit()
        print("Column 'favorite_outfits' added to users table")

if __name__ == "__main__":
    add_favorites_column()