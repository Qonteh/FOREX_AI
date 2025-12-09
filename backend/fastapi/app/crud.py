"""
CRUD operations for database models.
"""
from typing import Optional, List
from sqlalchemy.orm import Session
import secrets
import string

from app import models, schemas
from app.security import get_password_hash


# ============= User CRUD =============

def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """Get user by email."""
    return db.query(models.User).filter(models.User.email == email).first()


def get_user_by_id(db: Session, user_id: int) -> Optional[models.User]:
    """Get user by ID."""
    return db.query(models.User).filter(models.User.id == user_id).first()


def create_user(db: Session, user: schemas.UserCreate, referral_affiliate_id: Optional[int] = None) -> models.User:
    """
    Create a new user with hashed password and wallet.
    
    Args:
        db: Database session
        user: User creation schema
        referral_affiliate_id: Optional affiliate ID for referral tracking
        
    Returns:
        Created user object
    """
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        hashed_password=hashed_password,
        referral_id=referral_affiliate_id
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create wallet for new user
    db_wallet = models.Wallet(user_id=db_user.id, balance=0.0)
    db.add(db_wallet)
    db.commit()
    db.refresh(db_user)
    
    # If referred by affiliate, create initial commission transaction
    if referral_affiliate_id:
        affiliate = get_affiliate_by_id(db, referral_affiliate_id)
        if affiliate:
            affiliate_wallet = get_wallet_by_user_id(db, affiliate.user_id)
            if affiliate_wallet:
                create_transaction(
                    db=db,
                    wallet_id=affiliate_wallet.id,
                    amount=0.0,  # Initial tracking transaction, commission logic can be expanded
                    transaction_type=models.TransactionType.COMMISSION,
                    description=f"Referral signup: {user.email}"
                )
    
    return db_user


# ============= Affiliate CRUD =============

def get_affiliate_by_code(db: Session, code: str) -> Optional[models.Affiliate]:
    """Get affiliate by code."""
    return db.query(models.Affiliate).filter(models.Affiliate.code == code).first()


def get_affiliate_by_user_id(db: Session, user_id: int) -> Optional[models.Affiliate]:
    """Get affiliate by user ID."""
    return db.query(models.Affiliate).filter(models.Affiliate.user_id == user_id).first()


def get_affiliate_by_id(db: Session, affiliate_id: int) -> Optional[models.Affiliate]:
    """Get affiliate by ID."""
    return db.query(models.Affiliate).filter(models.Affiliate.id == affiliate_id).first()


def generate_affiliate_code(length: int = 8) -> str:
    """Generate a random affiliate code."""
    characters = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(characters) for _ in range(length))


def create_affiliate(db: Session, user_id: int) -> models.Affiliate:
    """
    Create an affiliate code for a user.
    
    Args:
        db: Database session
        user_id: User ID to create affiliate for
        
    Returns:
        Created affiliate object
    """
    # Generate unique code
    while True:
        code = generate_affiliate_code()
        existing = get_affiliate_by_code(db, code)
        if not existing:
            break
    
    db_affiliate = models.Affiliate(user_id=user_id, code=code)
    db.add(db_affiliate)
    db.commit()
    db.refresh(db_affiliate)
    return db_affiliate


def get_affiliate_stats(db: Session, user_id: int) -> dict:
    """
    Get affiliate statistics for a user.
    
    Args:
        db: Database session
        user_id: User ID to get stats for
        
    Returns:
        Dictionary with affiliate statistics
    """
    affiliate = get_affiliate_by_user_id(db, user_id)
    if not affiliate:
        return {"affiliate_code": None, "total_referrals": 0, "total_commissions": 0.0}
    
    # Count referrals
    referrals_count = db.query(models.User).filter(models.User.referral_id == affiliate.id).count()
    
    # Calculate total commissions
    wallet = get_wallet_by_user_id(db, user_id)
    total_commissions = 0.0
    if wallet:
        commissions = db.query(models.Transaction).filter(
            models.Transaction.wallet_id == wallet.id,
            models.Transaction.type == models.TransactionType.COMMISSION
        ).all()
        total_commissions = sum(t.amount for t in commissions)
    
    return {
        "affiliate_code": affiliate.code,
        "total_referrals": referrals_count,
        "total_commissions": total_commissions
    }


# ============= Wallet CRUD =============

def get_wallet_by_user_id(db: Session, user_id: int) -> Optional[models.Wallet]:
    """Get wallet by user ID."""
    return db.query(models.Wallet).filter(models.Wallet.user_id == user_id).first()


def update_wallet_balance(db: Session, wallet_id: int, amount: float) -> models.Wallet:
    """
    Update wallet balance.
    
    Args:
        db: Database session
        wallet_id: Wallet ID to update
        amount: Amount to add (positive) or subtract (negative)
        
    Returns:
        Updated wallet object
    """
    wallet = db.query(models.Wallet).filter(models.Wallet.id == wallet_id).first()
    if wallet:
        wallet.balance += amount
        db.commit()
        db.refresh(wallet)
    return wallet


# ============= Transaction CRUD =============

def create_transaction(
    db: Session,
    wallet_id: int,
    amount: float,
    transaction_type: models.TransactionType,
    description: Optional[str] = None
) -> models.Transaction:
    """
    Create a transaction.
    
    Args:
        db: Database session
        wallet_id: Wallet ID for the transaction
        amount: Transaction amount
        transaction_type: Type of transaction (deposit, withdraw, commission)
        description: Optional transaction description
        
    Returns:
        Created transaction object
    """
    db_transaction = models.Transaction(
        wallet_id=wallet_id,
        amount=amount,
        type=transaction_type,
        description=description
    )
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction


def get_transactions_by_wallet(
    db: Session,
    wallet_id: int,
    skip: int = 0,
    limit: int = 100
) -> List[models.Transaction]:
    """
    Get transactions for a wallet.
    
    Args:
        db: Database session
        wallet_id: Wallet ID to get transactions for
        skip: Number of records to skip (pagination)
        limit: Maximum number of records to return
        
    Returns:
        List of transaction objects
    """
    return db.query(models.Transaction)\
        .filter(models.Transaction.wallet_id == wallet_id)\
        .order_by(models.Transaction.created_at.desc())\
        .offset(skip)\
        .limit(limit)\
        .all()


def get_transaction_count(db: Session, wallet_id: int) -> int:
    """Get total count of transactions for a wallet."""
    return db.query(models.Transaction).filter(models.Transaction.wallet_id == wallet_id).count()
