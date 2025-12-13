import os
import logging
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mysql+pymysql://root@localhost:3306/forex_ai"
)

logger.info(f"📊 Database URL: {DATABASE_URL}")

if DATABASE_URL == "mysql+pymysql://root@localhost:3306/forex_ai":
    logger.warning("⚠️  WARNING: Using default DATABASE_URL")
    logger.warning("⚠️  Default: MySQL without password (root@localhost:3306)")
    logger.warning("⚠️  If you need a password, create .env file with:")
    logger.warning("⚠️  DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@localhost:3306/forex_ai")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    from app.models import User
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created successfully")
        logger.info("✅ Database initialized successfully")
    except Exception as e:
        logger.error(f"❌ Error initializing database: {e}")
        raise
