import logging
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import secrets
import string

from app.models import User
from app.schemas import UserCreate

logger = logging.getLogger(__name__)

# Configure password hashing with bcrypt
# Use bcrypt with proper configuration to avoid compatibility issues
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=12,
)


def get_password_hash(password: str) -> str:
    """
    Hash a password using bcrypt.
    Handles long passwords by truncating to 72 bytes as per bcrypt limitation.
    """
    try:
        # Bcrypt has a 72-byte limit. Truncate if necessary.
        # This is a known limitation of bcrypt.
        if len(password.encode('utf-8')) > 72:
            logger.warning("Password exceeds 72 bytes, truncating for bcrypt")
            password = password.encode('utf-8')[:72].decode('utf-8', errors='ignore')
        
        return pwd_context.hash(password)
    except Exception as e:
        logger.error(f"Error hashing password: {e}")
        # Retry with truncated password if there's an error
        password = password.encode('utf-8')[:72].decode('utf-8', errors='ignore')
        return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash."""
    try:
        # Handle long passwords the same way as hashing
        if len(plain_password.encode('utf-8')) > 72:
            plain_password = plain_password.encode('utf-8')[:72].decode('utf-8', errors='ignore')
        
        return pwd_context.verify(plain_password, hashed_password)
    except Exception as e:
        logger.error(f"Error verifying password: {e}")
        return False


def generate_referral_code(length: int = 8) -> str:
    """Generate a random referral code."""
    chars = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))


def get_user_by_email(db: Session, email: str):
    """Get user by email."""
    return db.query(User).filter(User.email == email).first()


def get_user_by_phone(db: Session, phone: str):
    """Get user by phone."""
    return db.query(User).filter(User.phone == phone).first()


def get_user_by_referral_code(db: Session, referral_code: str):
    """Get user by referral code."""
    return db.query(User).filter(User.referral_code == referral_code).first()


def create_user(db: Session, user: UserCreate, verification_token: str, referred_by_code: str = None):
    """Create a new user."""
    logger.info("📝 Creating new user...")
    
    # Generate unique referral code
    referral_code = generate_referral_code()
    while get_user_by_referral_code(db, referral_code):
        referral_code = generate_referral_code()
    
    # Validate referred_by_code if provided
    referred_by = None
    if referred_by_code:
        referrer = get_user_by_referral_code(db, referred_by_code)
        if referrer:
            referred_by = referred_by_code
        else:
            logger.warning(f"Invalid referral code provided: {referred_by_code}")
    
    db_user = User(
        email=user.email,
        phone=user.phone,
        name=user.name,
        hashed_password=get_password_hash(user.password),
        is_active=False,
        is_verified=False,
        verification_token=verification_token,
        referral_code=referral_code,
        referred_by=referred_by,
        balance=0.0
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    logger.info(f"✅ User created successfully: {user.email}")
    return db_user


def authenticate_user(db: Session, email: str, password: str):
    """Authenticate a user."""
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user
