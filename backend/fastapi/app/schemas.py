"""
Extended Pydantic schemas for request/response validation.
Includes: Users, Wallet, Referrals, Transactions, Subscriptions
"""
from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
from datetime import datetime
from typing import Optional, List
from enum import Enum


# Enums
class UserStatusEnum(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    DELETED = "deleted"


class TransactionTypeEnum(str, Enum):
    DEPOSIT = "deposit"
    WITHDRAWAL = "withdrawal"
    COMMISSION = "commission"
    BONUS = "bonus"
    REFUND = "refund"
    SUBSCRIPTION = "subscription"


class TransactionStatusEnum(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class SubscriptionPlanEnum(str, Enum):
    FREE = "free"
    BASIC = "basic"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"


# User Schemas
class UserBase(BaseModel):
    """Base user schema with common fields."""
    email: EmailStr
    name: str = Field(..., min_length=2, max_length=255)


class UserCreate(UserBase):
    """Schema for user registration."""
    password: str = Field(..., min_length=6)
    phone: str = Field(..., validation_alias='tel')
    referred_by_code: Optional[str] = None  # Referral code (optional)
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        """Validate phone number format."""
        if not v:
            raise ValueError('Phone number is required')
        digits_only = ''.join(filter(str.isdigit, v))
        if len(digits_only) < 10:
            raise ValueError('Phone number must contain at least 10 digits')
        if len(digits_only) > 15:
            raise ValueError('Phone number cannot exceed 15 digits')
        return v
    
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "email": "user@example.com",
                "name": "John Doe",
                "phone": "+1234567890",
                "password": "securepass123",
                "referred_by_code": "QT123456"
            }
        }
    )


class UserOut(UserBase):
    """Schema for user response (excludes password)."""
    id: str
    phone: str
    status: UserStatusEnum
    is_email_verified: bool
    is_premium: bool
    subscription_plan: SubscriptionPlanEnum
    subscription_expires_at: Optional[datetime]
    referral_code: str
    referred_by_id: Optional[str]
    created_at: datetime
    updated_at: datetime
    last_login_at: Optional[datetime]
    
    model_config = ConfigDict(from_attributes=True)


class UserLogin(BaseModel):
    """Schema for user login."""
    email: EmailStr
    password: str


class EmailVerification(BaseModel):
    """Schema for email verification."""
    token: str


# Wallet Schemas
class WalletOut(BaseModel):
    """Schema for wallet response."""
    id: str
    user_id: str
    balance: float
    pending_balance: float
    total_earned: float
    total_withdrawn: float
    referral_earnings: float
    bonus_earnings: float
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class WalletUpdate(BaseModel):
    """Schema for wallet update."""
    balance: Optional[float] = None
    pending_balance: Optional[float] = None


# Transaction Schemas
class TransactionCreate(BaseModel):
    """Schema for creating a transaction."""
    type: TransactionTypeEnum
    amount: float = Field(..., gt=0)
    currency: str = "USD"
    description: Optional[str] = None
    reference_id: Optional[str] = None


class TransactionOut(BaseModel):
    """Schema for transaction response."""
    id: str
    user_id: str
    type: TransactionTypeEnum
    status: TransactionStatusEnum
    amount: float
    currency: str
    description: Optional[str]
    reference_id: Optional[str]
    referral_id: Optional[str]
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime]
    
    model_config = ConfigDict(from_attributes=True)


# Referral Schemas
class ReferralOut(BaseModel):
    """Schema for referral response."""
    id: str
    referrer_id: str
    referred_id: str
    is_active: bool
    is_premium_converted: bool
    commission_earned: float
    commission_rate: float
    created_at: datetime
    converted_at: Optional[datetime]
    
    model_config = ConfigDict(from_attributes=True)


class ReferralStats(BaseModel):
    """Schema for referral statistics."""
    referral_code: str
    total_referrals: int
    active_referrals: int
    premium_referrals: int
    total_earnings: float
    pending_earnings: float
    referrals: List[ReferralOut]


# Subscription Schemas
class SubscriptionCreate(BaseModel):
    """Schema for creating a subscription."""
    plan: SubscriptionPlanEnum
    billing_cycle: str = "monthly"  # monthly or yearly
    payment_method: Optional[str] = None


class SubscriptionOut(BaseModel):
    """Schema for subscription response."""
    id: str
    user_id: str
    plan: SubscriptionPlanEnum
    status: str
    price: float
    currency: str
    billing_cycle: str
    next_billing_date: Optional[datetime]
    auto_renew: bool
    payment_method: Optional[str]
    created_at: datetime
    started_at: datetime
    expires_at: Optional[datetime]
    cancelled_at: Optional[datetime]
    
    model_config = ConfigDict(from_attributes=True)


# Token Schemas
class Token(BaseModel):
    """Schema for JWT token response."""
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class TokenData(BaseModel):
    """Schema for JWT token payload."""
    user_id: Optional[str] = None
    email: Optional[str] = None


# Email Verification Response
class EmailVerificationResponse(BaseModel):
    """Schema for email verification response."""
    success: bool
    message: str
    user: Optional[UserOut] = None
