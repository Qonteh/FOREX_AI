from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=50)
    name: str = Field(..., min_length=1, max_length=255)
    password: str = Field(..., min_length=8)
    referral_code: Optional[str] = None


class UserResponse(BaseModel):
    id: int
    email: str
    phone: str
    name: str
    is_active: bool
    is_verified: bool
    referral_code: Optional[str]
    referred_by: Optional[str]
    balance: float
    created_at: datetime
    
    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
