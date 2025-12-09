"""
CRUD (Create, Read, Update, Delete) operations for database models.
"""
from typing import Optional, List
from sqlalchemy.orm import Session

from app.models import User, Affiliate, Wallet, Transaction
from app.security import get_password_hash


# User CRUD operations
def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email address."""
    return db.query(User).filter(User.email == email).first()


def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """Get user by username."""
    return db.query(User).filter(User.username == username).first()


def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    """Get user by ID."""
    return db.query(User).filter(User.id == user_id).first()


def create_user(
    db: Session, 
    email: str, 
    username: str, 
    password: str, 
    referral_id: Optional[int] = None
) -> User:
    """
    Create a new user with hashed password.
    
    Args:
        db: Database session
        email: User email
        username: Username
        password: Plain text password (will be hashed)
        referral_id: Optional referrer user ID
        
    Returns:
        Created User object
    """
    hashed_password = get_password_hash(password)
    db_user = User(
        email=email,
        username=username,
        hashed_password=hashed_password,
        referral_id=referral_id
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


# Affiliate CRUD operations
def get_affiliate_by_code(db: Session, code: str) -> Optional[Affiliate]:
    """Get affiliate by referral code."""
    return db.query(Affiliate).filter(Affiliate.code == code).first()


def get_affiliate_by_user_id(db: Session, user_id: int) -> Optional[Affiliate]:
    """Get affiliate by user ID."""
    return db.query(Affiliate).filter(Affiliate.user_id == user_id).first()


def create_affiliate(db: Session, user_id: int, code: str) -> Affiliate:
    """
    Create a new affiliate code for a user.
    
    Args:
        db: Database session
        user_id: User ID
        code: Affiliate referral code
        
    Returns:
        Created Affiliate object
    """
    db_affiliate = Affiliate(user_id=user_id, code=code)
    db.add(db_affiliate)
    db.commit()
    db.refresh(db_affiliate)
    return db_affiliate


def increment_affiliate_referrals(db: Session, affiliate_id: int) -> Affiliate:
    """
    Increment the total referrals count for an affiliate.
    
    Args:
        db: Database session
        affiliate_id: Affiliate ID
        
    Returns:
        Updated Affiliate object
    """
    affiliate = db.query(Affiliate).filter(Affiliate.id == affiliate_id).first()
    if affiliate:
        affiliate.total_referrals += 1
        db.commit()
        db.refresh(affiliate)
    return affiliate


# Wallet CRUD operations
def get_wallet_by_user_id(db: Session, user_id: int) -> Optional[Wallet]:
    """Get wallet by user ID."""
    return db.query(Wallet).filter(Wallet.user_id == user_id).first()


def create_wallet(db: Session, user_id: int) -> Wallet:
    """
    Create a new wallet for a user with initial balance of 0.
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        Created Wallet object
    """
    db_wallet = Wallet(user_id=user_id, balance=0.0)
    db.add(db_wallet)
    db.commit()
    db.refresh(db_wallet)
    return db_wallet


def update_wallet_balance(db: Session, wallet_id: int, amount: float) -> Wallet:
    """
    Update wallet balance by adding/subtracting an amount.
    
    Args:
        db: Database session
        wallet_id: Wallet ID
        amount: Amount to add (positive) or subtract (negative)
        
    Returns:
        Updated Wallet object
    """
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if wallet:
        wallet.balance += amount
        db.commit()
        db.refresh(wallet)
    return wallet


# Transaction CRUD operations
def create_transaction(
    db: Session, 
    wallet_id: int, 
    amount: float, 
    transaction_type: str,
    description: Optional[str] = None
) -> Transaction:
    """
    Create a new transaction record.
    
    Args:
        db: Database session
        wallet_id: Wallet ID
        amount: Transaction amount
        transaction_type: Type of transaction ('deposit' or 'withdraw')
        description: Optional description
        
    Returns:
        Created Transaction object
    """
    db_transaction = Transaction(
        wallet_id=wallet_id,
        amount=amount,
        transaction_type=transaction_type,
        description=description
    )
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction


def get_transactions_by_wallet_id(
    db: Session, 
    wallet_id: int, 
    skip: int = 0, 
    limit: int = 100
) -> List[Transaction]:
    """
    Get transactions for a wallet with pagination.
    
    Args:
        db: Database session
        wallet_id: Wallet ID
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List of Transaction objects
    """
    return (
        db.query(Transaction)
        .filter(Transaction.wallet_id == wallet_id)
        .order_by(Transaction.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def count_transactions_by_wallet_id(db: Session, wallet_id: int) -> int:
    """
    Count total transactions for a wallet.
    
    Args:
        db: Database session
        wallet_id: Wallet ID
        
    Returns:
        Total count of transactions
    """
    return db.query(Transaction).filter(Transaction.wallet_id == wallet_id).count()
