"""
Extended SQLAlchemy models for the FOREX AI application.
Includes: Users, Wallet, Referrals, Transactions, Subscriptions, and Email Verification
"""
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import uuid
import enum

Base = declarative_base()


class UserStatus(str, enum.Enum):
    """User account status"""
    PENDING = "pending"  # Email not verified
    ACTIVE = "active"  # Email verified and active
    SUSPENDED = "suspended"  # Account suspended
    DELETED = "deleted"  # Soft deleted


class TransactionType(str, enum.Enum):
    """Transaction types"""
    DEPOSIT = "deposit"
    WITHDRAWAL = "withdrawal"
    COMMISSION = "commission"
    BONUS = "bonus"
    REFUND = "refund"
    SUBSCRIPTION = "subscription"


class TransactionStatus(str, enum.Enum):
    """Transaction status"""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class SubscriptionPlan(str, enum.Enum):
    """Subscription plan types"""
    FREE = "free"
    BASIC = "basic"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"


class User(Base):
    """User model with phone field for authentication and profile management."""
    
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(32), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    
    # Account status
    status = Column(SQLEnum(UserStatus), default=UserStatus.PENDING, nullable=False)
    is_email_verified = Column(Boolean, default=False, nullable=False)
    email_verification_token = Column(String(255), unique=True, nullable=True)
    email_verification_sent_at = Column(DateTime, nullable=True)
    
    # Premium features
    is_premium = Column(Boolean, default=False, nullable=False)
    subscription_plan = Column(SQLEnum(SubscriptionPlan), default=SubscriptionPlan.FREE, nullable=False)
    subscription_expires_at = Column(DateTime, nullable=True)
    
    # Referral system
    referral_code = Column(String(32), unique=True, nullable=False, index=True)
    referred_by_id = Column(String(36), ForeignKey('users.id'), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    last_login_at = Column(DateTime, nullable=True)
    
    # Relationships
    wallet = relationship("Wallet", back_populates="user", uselist=False, cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    subscriptions = relationship("Subscription", back_populates="user", cascade="all, delete-orphan")
    referrals = relationship("Referral", foreign_keys="[Referral.referrer_id]", back_populates="referrer", cascade="all, delete-orphan")
    referred_by = relationship("User", remote_side=[id], backref="referred_users")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, status={self.status})>"


class Wallet(Base):
    """User wallet for managing funds and commissions."""
    
    __tablename__ = "wallets"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey('users.id'), unique=True, nullable=False)
    
    # Balances
    balance = Column(Float, default=0.0, nullable=False)  # Available balance
    pending_balance = Column(Float, default=0.0, nullable=False)  # Pending/processing
    total_earned = Column(Float, default=0.0, nullable=False)  # Lifetime earnings
    total_withdrawn = Column(Float, default=0.0, nullable=False)  # Total withdrawn
    
    # Commission tracking
    referral_earnings = Column(Float, default=0.0, nullable=False)
    bonus_earnings = Column(Float, default=0.0, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="wallet")
    
    def __repr__(self):
        return f"<Wallet(user_id={self.user_id}, balance={self.balance})>"


class Transaction(Base):
    """Financial transactions for deposits, withdrawals, and commissions."""
    
    __tablename__ = "transactions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey('users.id'), nullable=False)
    
    # Transaction details
    type = Column(SQLEnum(TransactionType), nullable=False)
    status = Column(SQLEnum(TransactionStatus), default=TransactionStatus.PENDING, nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="USD", nullable=False)
    
    # Description and metadata
    description = Column(Text, nullable=True)
    reference_id = Column(String(255), nullable=True, index=True)  # External reference (e.g., PayPal transaction ID)
    metadata = Column(Text, nullable=True)  # JSON string for additional data
    
    # Related referral (if applicable)
    referral_id = Column(String(36), ForeignKey('referrals.id'), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    completed_at = Column(DateTime, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="transactions")
    referral = relationship("Referral", back_populates="transactions")
    
    def __repr__(self):
        return f"<Transaction(id={self.id}, type={self.type}, amount={self.amount}, status={self.status})>"


class Referral(Base):
    """Tracks referrals between users."""
    
    __tablename__ = "referrals"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    referrer_id = Column(String(36), ForeignKey('users.id'), nullable=False)  # Person who referred
    referred_id = Column(String(36), ForeignKey('users.id'), nullable=False)  # Person who was referred
    
    # Referral status
    is_active = Column(Boolean, default=True, nullable=False)
    is_premium_converted = Column(Boolean, default=False, nullable=False)  # Did referred user go premium?
    
    # Commission tracking
    commission_earned = Column(Float, default=0.0, nullable=False)
    commission_rate = Column(Float, default=0.30, nullable=False)  # 30% default
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    converted_at = Column(DateTime, nullable=True)  # When referred user went premium
    
    # Relationships
    referrer = relationship("User", foreign_keys=[referrer_id], back_populates="referrals")
    referred = relationship("User", foreign_keys=[referred_id])
    transactions = relationship("Transaction", back_populates="referral")
    
    def __repr__(self):
        return f"<Referral(referrer_id={self.referrer_id}, referred_id={self.referred_id})>"


class Subscription(Base):
    """User subscription history and details."""
    
    __tablename__ = "subscriptions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey('users.id'), nullable=False)
    
    # Subscription details
    plan = Column(SQLEnum(SubscriptionPlan), nullable=False)
    status = Column(String(32), default="active", nullable=False)  # active, cancelled, expired
    price = Column(Float, nullable=False)
    currency = Column(String(10), default="USD", nullable=False)
    
    # Billing
    billing_cycle = Column(String(32), default="monthly", nullable=False)  # monthly, yearly
    next_billing_date = Column(DateTime, nullable=True)
    auto_renew = Column(Boolean, default=True, nullable=False)
    
    # Payment reference
    payment_method = Column(String(64), nullable=True)
    payment_provider_id = Column(String(255), nullable=True)  # Stripe/PayPal customer ID
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    started_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    cancelled_at = Column(DateTime, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="subscriptions")
    
    def __repr__(self):
        return f"<Subscription(user_id={self.user_id}, plan={self.plan}, status={self.status})>"
