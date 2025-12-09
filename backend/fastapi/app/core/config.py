"""
Application configuration management using pydantic-settings.
Loads environment variables from .env file and provides type-safe access.
"""
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Database Configuration
    DB_HOST: str = Field(default="127.0.0.1", description="Database host")
    DB_PORT: int = Field(default=3306, description="Database port")
    DB_USER: str = Field(default="root", description="Database user")
    DB_PASSWORD: str = Field(default="", description="Database password")
    DB_NAME: str = Field(default="forex_ai", description="Database name")
    
    # Security Configuration
    SECRET_KEY: str = Field(..., description="Secret key for JWT token generation")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=30, description="Access token expiration in minutes")
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(default=7, description="Refresh token expiration in days")
    
    # JWT Algorithm
    ALGORITHM: str = Field(default="HS256", description="JWT algorithm")
    
    @property
    def database_url(self) -> str:
        """Construct database URL for SQLAlchemy."""
        return f"mysql+mysqlconnector://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()
