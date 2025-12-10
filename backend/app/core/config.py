from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App settings
    APP_NAME: str = "FOREX AI API"
    VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Security settings
    SECRET_KEY: str = "your-secret-key-change-in-production-use-openssl-rand-hex-32"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database settings
    DATABASE_URL: str = "sqlite:///./forex_ai.db"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
