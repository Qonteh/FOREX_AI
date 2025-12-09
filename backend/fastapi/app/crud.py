"""
CRUD operations for database models.
"""
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models import User
from app.schemas import UserCreate
from passlib.context import CryptContext
from typing import Optional

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_password_hash(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """
    Get user by email address.
    
    Args:
        db: Database session
        email: User's email address
        
    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(User.email == email).first()


def get_user_by_phone(db: Session, phone: str) -> Optional[User]:
    """
    Get user by phone number.
    
    Args:
        db: Database session
        phone: User's phone number
        
    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(User.phone == phone).first()


def get_user_by_email_or_phone(db: Session, email: str, phone: str) -> Optional[User]:
    """
    Check if user exists with given email or phone.
    
    Args:
        db: Database session
        email: User's email address
        phone: User's phone number
        
    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(
        or_(User.email == email, User.phone == phone)
    ).first()


def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    """
    Get user by ID.
    
    Args:
        db: Database session
        user_id: User's unique identifier
        
    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, user: UserCreate) -> User:
    """
    Create a new user in the database.
    
    Args:
        db: Database session
        user: User data from registration
        
    Returns:
        Created User object
    """
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email.lower(),
        phone=user.phone,
        name=user.name,
        hashed_password=hashed_password,
        is_active=True,
        is_premium=False
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    """
    Authenticate user with email and password.
    
    Args:
        db: Database session
        email: User's email address
        password: Plain text password
        
    Returns:
        User object if authentication successful, None otherwise
    """
    user = get_user_by_email(db, email.lower())
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user
