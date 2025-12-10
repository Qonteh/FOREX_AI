from pydantic import BaseModel, EmailStr, Field, model_validator
from typing import Optional
from datetime import datetime

class UserRegisterRequest(BaseModel):
    """Schema for user registration request."""
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=100)
    password: str = Field(..., min_length=6, max_length=100)
    phone: Optional[str] = None
    tel: Optional[str] = None  # Accept both 'phone' and 'tel' for frontend compatibility
    
    @model_validator(mode='after')
    def validate_phone_fields(self):
        """Ensure at least one phone field is provided."""
        if not self.phone and not self.tel:
            raise ValueError('Either phone or tel field must be provided')
        return self
    
    @property
    def phone_number(self) -> str:
        """Get the phone number from either field."""
        return self.phone or self.tel or ""

class UserResponse(BaseModel):
    """Schema for user response."""
    id: int
    email: str
    name: str
    phone: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    """Schema for token response."""
    access_token: str
    token_type: str = "bearer"

class UserRegisterResponse(BaseModel):
    """Schema for user registration response."""
    token: str
    user: UserResponse
    message: str = "User registered successfully"
