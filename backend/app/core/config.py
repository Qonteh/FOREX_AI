from pydantic_settings import BaseSettings
import secrets

class Settings(BaseSettings):
    # App settings
    APP_NAME: str = "FOREX AI API"
    VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Security settings - SECRET_KEY should be set via environment variable in production
    SECRET_KEY: str = secrets.token_urlsafe(32)  # Generate random key if not provided
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database settings
    DATABASE_URL: str = "sqlite:///./forex_ai.db"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
