"""
Pydantic schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field, validator


# ============= User Schemas =============

class UserBase(BaseModel):
    """Base user schema."""
    email: EmailStr


class UserCreate(UserBase):
    """Schema for user registration."""
    password: str = Field(..., min_length=8, description="Password must be at least 8 characters")
    referral_code: Optional[str] = Field(None, description="Optional referral code")


class UserLogin(BaseModel):
    """Schema for user login (OAuth2 compatible)."""
    username: EmailStr  # OAuth2PasswordRequestForm uses 'username' field
    password: str


class UserResponse(UserBase):
    """Schema for user response."""
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserInDB(UserResponse):
    """Schema for user in database with hashed password."""
    hashed_password: str


# ============= Token Schemas =============

class Token(BaseModel):
    """Schema for token response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Schema for token data."""
    user_id: Optional[int] = None


class RefreshTokenRequest(BaseModel):
    """Schema for refresh token request."""
    refresh_token: str


# ============= Affiliate Schemas =============

class AffiliateCreate(BaseModel):
    """Schema for creating affiliate code (no input needed, generated automatically)."""
    pass


class AffiliateResponse(BaseModel):
    """Schema for affiliate response."""
    id: int
    user_id: int
    code: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class AffiliateStats(BaseModel):
    """Schema for affiliate statistics."""
    affiliate_code: str
    total_referrals: int
    total_commissions: float


# ============= Wallet Schemas =============

class WalletResponse(BaseModel):
    """Schema for wallet response."""
    id: int
    user_id: int
    balance: float
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class DepositRequest(BaseModel):
    """Schema for deposit request."""
    amount: float = Field(..., gt=0, description="Amount must be greater than 0")
    description: Optional[str] = Field(None, max_length=255)


class WithdrawRequest(BaseModel):
    """Schema for withdraw request."""
    amount: float = Field(..., gt=0, description="Amount must be greater than 0")
    description: Optional[str] = Field(None, max_length=255)


# ============= Transaction Schemas =============

class TransactionResponse(BaseModel):
    """Schema for transaction response."""
    id: int
    wallet_id: int
    amount: float
    type: str
    description: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class TransactionListResponse(BaseModel):
    """Schema for transaction list response."""
    transactions: List[TransactionResponse]
    total: int
