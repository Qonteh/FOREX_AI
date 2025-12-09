"""
Pydantic schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


# User Schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=100)


class UserCreate(UserBase):
    password: str = Field(..., min_length=6)
    referral_code: Optional[str] = None


class UserResponse(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


# Auth Schemas
class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


# Affiliate Schemas
class AffiliateCreate(BaseModel):
    code: str = Field(..., min_length=3, max_length=50)


class AffiliateResponse(BaseModel):
    id: int
    user_id: int
    code: str
    total_referrals: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class AffiliateStats(BaseModel):
    code: str
    total_referrals: int
    created_at: datetime


# Wallet Schemas
class WalletResponse(BaseModel):
    id: int
    user_id: int
    balance: float
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class DepositRequest(BaseModel):
    amount: float = Field(..., gt=0)
    description: Optional[str] = None


class WithdrawRequest(BaseModel):
    amount: float = Field(..., gt=0)
    description: Optional[str] = None


class TransactionResponse(BaseModel):
    id: int
    wallet_id: int
    amount: float
    transaction_type: str
    description: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class TransactionListResponse(BaseModel):
    transactions: List[TransactionResponse]
    total: int
