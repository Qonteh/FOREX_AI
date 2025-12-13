"""
Extended CRUD operations for database models.
Includes operations for Users, Wallet, Referrals, Transactions, Subscriptions
"""
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from app.models import User, Wallet, Referral, Transaction, Subscription, UserStatus, SubscriptionPlan
from app.schemas import UserCreate, TransactionCreate, SubscriptionCreate
from passlib.context import CryptContext
from typing import Optional, List
from datetime import datetime, timedelta
import uuid
import secrets
import string

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_password_hash(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)


def generate_referral_code(db: Session) -> str:
    """
    Generate a unique referral code.
    Format: QT + 6 digits (e.g., QT123456)
    """
    while True:
        # Generate random 6-digit number
        digits = ''.join(secrets.choice(string.digits) for _ in range(6))
        referral_code = f"QT{digits}"
        
        # Check if code already exists
        existing = db.query(User).filter(User.referral_code == referral_code).first()
        if not existing:
            return referral_code


# ===== USER OPERATIONS =====

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email address."""
    return db.query(User).filter(User.email == email).first()


def get_user_by_phone(db: Session, phone: str) -> Optional[User]:
    """Get user by phone number."""
    return db.query(User).filter(User.phone == phone).first()


def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    """Get user by ID."""
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_referral_code(db: Session, referral_code: str) -> Optional[User]:
    """Get user by their referral code."""
    return db.query(User).filter(User.referral_code == referral_code).first()


def get_user_by_verification_token(db: Session, token: str) -> Optional[User]:
    """Get user by email verification token."""
    return db.query(User).filter(User.email_verification_token == token).first()


def create_user(db: Session, user: UserCreate, verification_token: str, referred_by_code: Optional[str] = None) -> User:
    """
    Create a new user with wallet and referral tracking.
    
    Args:
        db: Database session
        user: User creation data
        verification_token: Email verification token
        referred_by_code: Optional referral code from another user
        
    Returns:
        Created User object
    """
    # Generate unique referral code for this user
    referral_code = generate_referral_code(db)
    
    # Handle referred_by relationship
    referred_by_id = None
    if referred_by_code:
        referrer = get_user_by_referral_code(db, referred_by_code)
        if referrer and referrer.status == UserStatus.ACTIVE:
            referred_by_id = referrer.id
    
    # Create user
    db_user = User(
        id=str(uuid.uuid4()),
        email=user.email.lower(),
        phone=user.phone,
        name=user.name,
        hashed_password=get_password_hash(user.password),
        status=UserStatus.PENDING,  # Email not verified yet
        is_email_verified=False,
        email_verification_token=verification_token,
        email_verification_sent_at=datetime.utcnow(),
        is_premium=False,
        subscription_plan=SubscriptionPlan.FREE,
        referral_code=referral_code,
        referred_by_id=referred_by_id,
    )
    
    db.add(db_user)
    db.flush()  # Get the user ID
    
    # Create wallet for user
    wallet = Wallet(
        id=str(uuid.uuid4()),
        user_id=db_user.id,
        balance=0.0,
        pending_balance=0.0,
        total_earned=0.0,
        total_withdrawn=0.0,
        referral_earnings=0.0,
        bonus_earnings=0.0,
    )
    db.add(wallet)
    
    # Create referral record if user was referred
    if referred_by_id:
        referral = Referral(
            id=str(uuid.uuid4()),
            referrer_id=referred_by_id,
            referred_id=db_user.id,
            is_active=True,
            is_premium_converted=False,
            commission_earned=0.0,
            commission_rate=0.30,  # 30% commission
        )
        db.add(referral)
    
    db.commit()
    db.refresh(db_user)
    return db_user


def verify_user_email(db: Session, user: User) -> User:
    """
    Verify user's email and activate account.
    
    Args:
        db: Database session
        user: User object
        
    Returns:
        Updated User object
    """
    user.is_email_verified = True
    user.email_verification_token = None
    user.status = UserStatus.ACTIVE
    db.commit()
    db.refresh(user)
    return user


def update_user_login(db: Session, user: User) -> User:
    """Update user's last login timestamp."""
    user.last_login_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    return user


# ===== WALLET OPERATIONS =====

def get_user_wallet(db: Session, user_id: str) -> Optional[Wallet]:
    """Get wallet for a specific user."""
    return db.query(Wallet).filter(Wallet.user_id == user_id).first()


def update_wallet_balance(db: Session, wallet: Wallet, amount: float, balance_type: str = "balance") -> Wallet:
    """
    Update wallet balance.
    
    Args:
        db: Database session
        wallet: Wallet object
        amount: Amount to add (positive) or subtract (negative)
        balance_type: Type of balance to update ("balance" or "pending_balance")
    """
    if balance_type == "balance":
        wallet.balance += amount
    elif balance_type == "pending_balance":
        wallet.pending_balance += amount
    
    wallet.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(wallet)
    return wallet


# ===== TRANSACTION OPERATIONS =====

def create_transaction(
    db: Session,
    user_id: str,
    transaction_data: TransactionCreate,
    referral_id: Optional[str] = None
) -> Transaction:
    """Create a new transaction."""
    transaction = Transaction(
        id=str(uuid.uuid4()),
        user_id=user_id,
        type=transaction_data.type,
        amount=transaction_data.amount,
        currency=transaction_data.currency,
        description=transaction_data.description,
        reference_id=transaction_data.reference_id,
        referral_id=referral_id,
    )
    
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return transaction


def get_user_transactions(db: Session, user_id: str, limit: int = 50) -> List[Transaction]:
    """Get transactions for a user."""
    return db.query(Transaction).filter(
        Transaction.user_id == user_id
    ).order_by(Transaction.created_at.desc()).limit(limit).all()


# ===== REFERRAL OPERATIONS =====

def get_user_referrals(db: Session, user_id: str) -> List[Referral]:
    """Get all referrals made by a user."""
    return db.query(Referral).filter(Referral.referrer_id == user_id).all()


def get_referral_stats(db: Session, user_id: str) -> dict:
    """
    Get referral statistics for a user.
    
    Returns:
        dict with total_referrals, active_referrals, premium_referrals, total_earnings, pending_earnings
    """
    referrals = get_user_referrals(db, user_id)
    
    total_referrals = len(referrals)
    active_referrals = len([r for r in referrals if r.is_active])
    premium_referrals = len([r for r in referrals if r.is_premium_converted])
    total_earnings = sum(r.commission_earned for r in referrals)
    
    # Get wallet for pending earnings
    wallet = get_user_wallet(db, user_id)
    pending_earnings = wallet.pending_balance if wallet else 0.0
    
    return {
        "total_referrals": total_referrals,
        "active_referrals": active_referrals,
        "premium_referrals": premium_referrals,
        "total_earnings": total_earnings,
        "pending_earnings": pending_earnings,
    }


def process_referral_commission(db: Session, referred_user: User, subscription_price: float) -> Optional[Transaction]:
    """
    Process commission for referrer when referred user subscribes to premium.
    
    Args:
        db: Database session
        referred_user: User who subscribed
        subscription_price: Price of the subscription
        
    Returns:
        Transaction object if commission was processed, None otherwise
    """
    if not referred_user.referred_by_id:
        return None
    
    # Get referral record
    referral = db.query(Referral).filter(
        Referral.referrer_id == referred_user.referred_by_id,
        Referral.referred_id == referred_user.id
    ).first()
    
    if not referral:
        return None
    
    # Calculate commission
    commission = subscription_price * referral.commission_rate
    
    # Update referral record
    referral.is_premium_converted = True
    referral.commission_earned += commission
    referral.converted_at = datetime.utcnow()
    
    # Update referrer's wallet
    referrer_wallet = get_user_wallet(db, referral.referrer_id)
    if referrer_wallet:
        referrer_wallet.pending_balance += commission
        referrer_wallet.referral_earnings += commission
        referrer_wallet.total_earned += commission
        referrer_wallet.updated_at = datetime.utcnow()
    
    # Create transaction record
    transaction = Transaction(
        id=str(uuid.uuid4()),
        user_id=referral.referrer_id,
        type="commission",
        amount=commission,
        currency="USD",
        description=f"Referral commission from {referred_user.name}",
        referral_id=referral.id,
        status="pending",
    )
    
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    
    return transaction


# ===== SUBSCRIPTION OPERATIONS =====

def create_subscription(db: Session, user_id: str, subscription_data: SubscriptionCreate) -> Subscription:
    """Create a new subscription for a user."""
    # Determine price based on plan and billing cycle
    prices = {
        SubscriptionPlan.BASIC: {"monthly": 9.99, "yearly": 99.99},
        SubscriptionPlan.PREMIUM: {"monthly": 29.99, "yearly": 299.99},
        SubscriptionPlan.ENTERPRISE: {"monthly": 99.99, "yearly": 999.99},
    }
    
    price = prices.get(subscription_data.plan, {}).get(subscription_data.billing_cycle, 0.0)
    
    # Calculate expiration date
    if subscription_data.billing_cycle == "monthly":
        expires_at = datetime.utcnow() + timedelta(days=30)
        next_billing = datetime.utcnow() + timedelta(days=30)
    else:  # yearly
        expires_at = datetime.utcnow() + timedelta(days=365)
        next_billing = datetime.utcnow() + timedelta(days=365)
    
    subscription = Subscription(
        id=str(uuid.uuid4()),
        user_id=user_id,
        plan=subscription_data.plan,
        status="active",
        price=price,
        currency="USD",
        billing_cycle=subscription_data.billing_cycle,
        next_billing_date=next_billing,
        auto_renew=True,
        payment_method=subscription_data.payment_method,
        started_at=datetime.utcnow(),
        expires_at=expires_at,
    )
    
    db.add(subscription)
    
    # Update user's premium status
    user = get_user_by_id(db, user_id)
    if user:
        user.is_premium = True
        user.subscription_plan = subscription_data.plan
        user.subscription_expires_at = expires_at
        
        # Process referral commission if applicable
        process_referral_commission(db, user, price)
    
    db.commit()
    db.refresh(subscription)
    return subscription


def get_user_subscriptions(db: Session, user_id: str) -> List[Subscription]:
    """Get all subscriptions for a user."""
    return db.query(Subscription).filter(
        Subscription.user_id == user_id
    ).order_by(Subscription.created_at.desc()).all()


def get_active_subscription(db: Session, user_id: str) -> Optional[Subscription]:
    """Get user's active subscription."""
    return db.query(Subscription).filter(
        Subscription.user_id == user_id,
        Subscription.status == "active",
        Subscription.expires_at > datetime.utcnow()
    ).first()
