from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Database
    DATABASE_URL: str = Field(
        default="mysql+mysqlconnector://root:@localhost:3306/forex_ai_db",
        description="Database connection URL for MySQL"
    )
    
    # JWT Configuration
    SECRET_KEY: str = Field(
        default="your-secret-key-change-this-in-production-min-32-chars",
        description="Secret key for JWT token generation"
    )
    ALGORITHM: str = Field(default="HS256", description="JWT algorithm")
    
    # Token Expiration
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(
        default=30, description="Access token expiration in minutes"
    )
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(
        default=30, description="Refresh token expiration in days"
    )
    
    # Application
    PROJECT_NAME: str = Field(default="FOREX AI Backend", description="Project name")
    DEBUG: bool = Field(default=True, description="Debug mode")
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
