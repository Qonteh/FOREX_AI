from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


# ============ Auth Schemas ============

class UserRegister(BaseModel):
    """Schema for user registration."""
    email: EmailStr
    password: str = Field(..., min_length=6)
    referral_code: Optional[str] = None


class UserLogin(BaseModel):
    """Schema for user login."""
    email: EmailStr
    password: str


class Token(BaseModel):
    """Schema for token response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    """Schema for JWT token payload."""
    sub: str  # subject (user_id)
    jti: str  # JWT ID (UUID)
    exp: Optional[int] = None  # expiration timestamp


class RefreshTokenRequest(BaseModel):
    """Schema for refresh token request."""
    refresh_token: str


class LogoutRequest(BaseModel):
    """Schema for logout request."""
    refresh_token: str


class UserResponse(BaseModel):
    """Schema for user response."""
    id: int
    email: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============ Affiliate Schemas ============

class AffiliateCreate(BaseModel):
    """Schema for affiliate creation."""
    code: str = Field(..., min_length=4, max_length=50)


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
    code: str
    total_referrals: int
    total_commission: float


# ============ Wallet Schemas ============

class WalletResponse(BaseModel):
    """Schema for wallet response."""
    id: int
    user_id: int
    balance: float
    
    class Config:
        from_attributes = True


class DepositRequest(BaseModel):
    """Schema for deposit request."""
    amount: float = Field(..., gt=0)
    description: Optional[str] = None


class WithdrawRequest(BaseModel):
    """Schema for withdraw request."""
    amount: float = Field(..., gt=0)
    description: Optional[str] = None


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


# ============ Generic Response Schemas ============

class MessageResponse(BaseModel):
    """Generic message response."""
    message: str
