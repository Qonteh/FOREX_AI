"""
SQLAlchemy database models for User, Affiliate, Wallet, and Transaction.
"""
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Enum
from sqlalchemy.orm import relationship
import enum

from app.db.session import Base


class TransactionType(str, enum.Enum):
    """Enum for transaction types."""
    DEPOSIT = "deposit"
    WITHDRAW = "withdraw"
    COMMISSION = "commission"


class User(Base):
    """User model for authentication and profile."""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    referral_id = Column(Integer, ForeignKey("affiliates.id"), nullable=True)  # Link to affiliate who referred this user
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    
    # Relationships
    wallet = relationship("Wallet", back_populates="user", uselist=False, cascade="all, delete-orphan")
    affiliates = relationship("Affiliate", back_populates="owner", foreign_keys="Affiliate.user_id", cascade="all, delete-orphan")
    referrer = relationship("Affiliate", foreign_keys=[referral_id], back_populates="referrals")


class Affiliate(Base):
    """Affiliate model for referral codes and tracking."""
    __tablename__ = "affiliates"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Owner of the affiliate code
    code = Column(String(50), unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    
    # Relationships
    owner = relationship("User", back_populates="affiliates", foreign_keys=[user_id])
    referrals = relationship("User", back_populates="referrer", foreign_keys="User.referral_id")


class Wallet(Base):
    """Wallet model for user balance."""
    __tablename__ = "wallets"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    balance = Column(Float, default=0.0, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="wallet")
    transactions = relationship("Transaction", back_populates="wallet", cascade="all, delete-orphan")


class Transaction(Base):
    """Transaction model for wallet activity tracking."""
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    wallet_id = Column(Integer, ForeignKey("wallets.id"), nullable=False)
    amount = Column(Float, nullable=False)
    type = Column(Enum(TransactionType), nullable=False)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    
    # Relationships
    wallet = relationship("Wallet", back_populates="transactions")
