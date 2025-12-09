from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text, Enum
)
from sqlalchemy.orm import relationship
import enum

from app.db.session import Base


class TransactionType(enum.Enum):
    """Enum for transaction types."""
    deposit = "deposit"
    withdraw = "withdraw"
    commission = "commission"


class User(Base):
    """User model for authentication and profile."""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    referral_id = Column(Integer, ForeignKey("affiliates.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    affiliate = relationship("Affiliate", back_populates="user", uselist=False, foreign_keys="Affiliate.user_id")
    wallet = relationship("Wallet", back_populates="user", uselist=False)
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    revoked_access_tokens = relationship("RevokedAccessToken", back_populates="user", cascade="all, delete-orphan")


class Affiliate(Base):
    """Affiliate model for referral tracking."""
    __tablename__ = "affiliates"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    code = Column(String(50), unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="affiliate", foreign_keys=[user_id])


class Wallet(Base):
    """Wallet model for user balance management."""
    __tablename__ = "wallets"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    balance = Column(Float, default=0.0, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="wallet")
    transactions = relationship("Transaction", back_populates="wallet", cascade="all, delete-orphan")


class Transaction(Base):
    """Transaction model for wallet operations."""
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    wallet_id = Column(Integer, ForeignKey("wallets.id"), nullable=False)
    amount = Column(Float, nullable=False)
    type = Column(Enum(TransactionType), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    wallet = relationship("Wallet", back_populates="transactions")


class RefreshToken(Base):
    """
    RefreshToken model for secure refresh token storage.
    Used for token rotation and reuse detection.
    """
    __tablename__ = "refresh_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    jti = Column(String(255), unique=True, index=True, nullable=False)  # JWT ID (UUID)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token = Column(Text, nullable=False)  # Store the actual token for validation
    revoked = Column(Boolean, default=False, nullable=False)  # For rotation/revocation
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="refresh_tokens")


class RevokedAccessToken(Base):
    """
    RevokedAccessToken model for access token revocation.
    Stores revoked access token JTIs until their natural expiration.
    """
    __tablename__ = "revoked_access_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    jti = Column(String(255), unique=True, index=True, nullable=False)  # JWT ID (UUID)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    revoked_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    expires_at = Column(DateTime, nullable=False)  # When token naturally expires
    
    # Relationships
    user = relationship("User", back_populates="revoked_access_tokens")
