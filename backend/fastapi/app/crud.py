from datetime import datetime, timezone
from typing import Optional, List, Tuple
from sqlalchemy.orm import Session

from app.models import (
    User, Affiliate, Wallet, Transaction, RefreshToken, RevokedAccessToken, TransactionType
)
from app.security import get_password_hash


# ============ User CRUD ============

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email address."""
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    """Get user by ID."""
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, email: str, password: str, referral_id: Optional[int] = None) -> User:
    """Create a new user with hashed password."""
    hashed_password = get_password_hash(password)
    db_user = User(
        email=email,
        hashed_password=hashed_password,
        referral_id=referral_id
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


# ============ Affiliate CRUD ============

def get_affiliate_by_code(db: Session, code: str) -> Optional[Affiliate]:
    """Get affiliate by referral code."""
    return db.query(Affiliate).filter(Affiliate.code == code).first()


def get_affiliate_by_user_id(db: Session, user_id: int) -> Optional[Affiliate]:
    """Get affiliate by user ID."""
    return db.query(Affiliate).filter(Affiliate.user_id == user_id).first()


def create_affiliate(db: Session, user_id: int, code: str) -> Affiliate:
    """Create a new affiliate for user."""
    db_affiliate = Affiliate(user_id=user_id, code=code)
    db.add(db_affiliate)
    db.commit()
    db.refresh(db_affiliate)
    return db_affiliate


def get_affiliate_referral_count(db: Session, affiliate_id: int) -> int:
    """Get total number of referrals for an affiliate."""
    return db.query(User).filter(User.referral_id == affiliate_id).count()


# ============ Wallet CRUD ============

def get_wallet_by_user_id(db: Session, user_id: int) -> Optional[Wallet]:
    """Get wallet by user ID."""
    return db.query(Wallet).filter(Wallet.user_id == user_id).first()


def create_wallet(db: Session, user_id: int) -> Wallet:
    """Create a new wallet for user."""
    db_wallet = Wallet(user_id=user_id, balance=0.0)
    db.add(db_wallet)
    db.commit()
    db.refresh(db_wallet)
    return db_wallet


def update_wallet_balance(db: Session, wallet_id: int, amount: float) -> Wallet:
    """Update wallet balance."""
    wallet = db.query(Wallet).filter(Wallet.id == wallet_id).first()
    if wallet:
        wallet.balance += amount
        db.commit()
        db.refresh(wallet)
    return wallet


# ============ Transaction CRUD ============

def create_transaction(
    db: Session,
    wallet_id: int,
    amount: float,
    transaction_type: TransactionType,
    description: Optional[str] = None
) -> Transaction:
    """Create a new transaction."""
    db_transaction = Transaction(
        wallet_id=wallet_id,
        amount=amount,
        type=transaction_type,
        description=description
    )
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction


def get_wallet_transactions(db: Session, wallet_id: int) -> List[Transaction]:
    """Get all transactions for a wallet."""
    return db.query(Transaction).filter(
        Transaction.wallet_id == wallet_id
    ).order_by(Transaction.created_at.desc()).all()


# ============ RefreshToken CRUD ============

def create_refresh_token(
    db: Session,
    user_id: int,
    jti: str,
    token: str,
    expires_at: datetime
) -> RefreshToken:
    """
    Create and persist a new refresh token.
    Used when issuing new refresh tokens during login or refresh.
    """
    db_token = RefreshToken(
        jti=jti,
        user_id=user_id,
        token=token,
        revoked=False,
        expires_at=expires_at
    )
    db.add(db_token)
    db.commit()
    db.refresh(db_token)
    return db_token


def get_refresh_token_by_jti(db: Session, jti: str) -> Optional[RefreshToken]:
    """Get refresh token by JTI."""
    return db.query(RefreshToken).filter(RefreshToken.jti == jti).first()


def revoke_refresh_token(db: Session, jti: str) -> bool:
    """
    Revoke a specific refresh token by JTI.
    Used during token rotation and logout.
    """
    token = db.query(RefreshToken).filter(RefreshToken.jti == jti).first()
    if token:
        token.revoked = True
        db.commit()
        return True
    return False


def revoke_all_user_refresh_tokens(db: Session, user_id: int) -> int:
    """
    Revoke all refresh tokens for a user.
    Used for logout_all and as security response to token reuse detection.
    
    Returns:
        Number of tokens revoked
    """
    count = db.query(RefreshToken).filter(
        RefreshToken.user_id == user_id,
        RefreshToken.revoked == False
    ).update({"revoked": True})
    db.commit()
    return count


def validate_refresh_token(db: Session, jti: str, token: str) -> Tuple[bool, Optional[str]]:
    """
    Validate refresh token against database record.
    
    SECURITY: Detects token reuse attacks.
    If token JTI exists but token string doesn't match, this indicates
    someone is trying to reuse an old (rotated) refresh token.
    
    Args:
        db: Database session
        jti: JWT ID from token payload
        token: The full token string
    
    Returns:
        Tuple of (is_valid, error_reason)
        - (True, None) if valid
        - (False, "revoked") if token is revoked
        - (False, "reuse") if token reuse detected
        - (False, "not_found") if token not in database
    """
    db_token = get_refresh_token_by_jti(db, jti)
    
    if not db_token:
        return False, "not_found"
    
    if db_token.revoked:
        return False, "revoked"
    
    # CRITICAL: Token reuse detection
    # If JTI matches but token string differs, someone is reusing an old token
    if db_token.token != token:
        return False, "reuse"
    
    # Check expiration
    if db_token.expires_at < datetime.now(timezone.utc):
        return False, "expired"
    
    return True, None


# ============ RevokedAccessToken CRUD ============

def revoke_access_token(
    db: Session,
    user_id: int,
    jti: str,
    expires_at: datetime
) -> RevokedAccessToken:
    """
    Add an access token JTI to the revocation list.
    Used during logout and logout_all.
    """
    db_revoked = RevokedAccessToken(
        jti=jti,
        user_id=user_id,
        expires_at=expires_at
    )
    db.add(db_revoked)
    db.commit()
    db.refresh(db_revoked)
    return db_revoked


def is_access_token_revoked(db: Session, jti: str) -> bool:
    """
    Check if an access token JTI is in the revocation list.
    Called during authentication to reject revoked tokens.
    """
    revoked = db.query(RevokedAccessToken).filter(
        RevokedAccessToken.jti == jti
    ).first()
    return revoked is not None


def revoke_all_user_access_tokens(db: Session, user_id: int, current_jti: Optional[str] = None) -> int:
    """
    Revoke all active access tokens for a user.
    Used during logout_all and as security response to token reuse detection.
    
    Note: This is a best-effort approach. We can't revoke tokens that haven't
    been tracked. In a real scenario, you might track all issued access tokens
    or use shorter expiration times.
    
    Args:
        db: Database session
        user_id: User ID
        current_jti: Optional JTI of current access token to include
    
    Returns:
        Number of tokens revoked (always 1 if current_jti provided, else 0)
    """
    # Since we don't track all access tokens by default (only revoked ones),
    # we can only revoke the current access token if provided
    if current_jti:
        # Calculate expiration based on settings
        from datetime import timedelta
        from app.core.config import settings
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        revoke_access_token(db, user_id, current_jti, expires_at)
        return 1
    return 0


# ============ Token Cleanup (Optional) ============

def cleanup_expired_tokens(db: Session) -> Tuple[int, int]:
    """
    Clean up expired tokens from database.
    This is optional and can be run periodically to keep database clean.
    
    Returns:
        Tuple of (refresh_tokens_deleted, access_tokens_deleted)
    """
    now = datetime.now(timezone.utc)
    
    # Delete expired refresh tokens
    refresh_deleted = db.query(RefreshToken).filter(
        RefreshToken.expires_at < now
    ).delete()
    
    # Delete expired revoked access tokens
    access_deleted = db.query(RevokedAccessToken).filter(
        RevokedAccessToken.expires_at < now
    ).delete()
    
    db.commit()
    return refresh_deleted, access_deleted
