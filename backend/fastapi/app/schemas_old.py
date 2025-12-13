"""
Pydantic schemas for request/response validation.
"""
from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
from datetime import datetime
from typing import Optional


class UserBase(BaseModel):
    """Base user schema with common fields."""
    email: EmailStr
    name: str = Field(..., min_length=2, max_length=255)


class UserCreate(UserBase):
    """Schema for user registration.
    
    Accepts both 'phone' and 'tel' field names for frontend compatibility.
    The 'tel' field is aliased to 'phone' internally.
    """
    password: str = Field(..., min_length=6)
    phone: str = Field(..., validation_alias='tel')
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        """Validate phone number format."""
        if not v:
            raise ValueError('Phone number is required')
        # Remove non-digit characters for validation
        digits_only = ''.join(filter(str.isdigit, v))
        if len(digits_only) < 10:
            raise ValueError('Phone number must contain at least 10 digits')
        if len(digits_only) > 15:
            raise ValueError('Phone number cannot exceed 15 digits')
        return v
    
    model_config = ConfigDict(
        # Allow population by field name or alias
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "email": "user@example.com",
                "name": "John Doe",
                "phone": "+1234567890",
                "password": "securepass123"
            }
        }
    )


class UserOut(UserBase):
    """Schema for user response (excludes password)."""
    id: str
    phone: str
    is_active: bool
    is_premium: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "email": "user@example.com",
                "name": "John Doe",
                "phone": "+1234567890",
                "is_active": True,
                "is_premium": False,
                "created_at": "2023-01-01T00:00:00",
                "updated_at": "2023-01-01T00:00:00"
            }
        }
    )


class UserLogin(BaseModel):
    """Schema for user login."""
    email: EmailStr
    password: str


class Token(BaseModel):
    """Schema for JWT token response."""
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class TokenData(BaseModel):
    """Schema for JWT token payload."""
    user_id: Optional[str] = None
    email: Optional[str] = None
