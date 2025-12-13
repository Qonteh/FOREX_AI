import logging
import secrets
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import UserCreate, UserResponse, Token, TokenData, LoginRequest
from app.models import User
import app.crud as crud

logger = logging.getLogger(__name__)

router = APIRouter()

# Security configuration
SECRET_KEY = secrets.token_urlsafe(32)
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """Get the current authenticated user."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    
    user = crud.get_user_by_email(db, email=token_data.email)
    if user is None:
        raise credentials_exception
    return user


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user."""
    logger.info("============================================================")
    logger.info("📝 Registration attempt:")
    logger.info(f"   Email: {user_data.email}")
    logger.info(f"   Phone: {user_data.phone}")
    logger.info(f"   Name: {user_data.name}")
    logger.info("============================================================")
    
    # Check if email already exists
    logger.info("🔍 Checking if email exists...")
    existing_user = crud.get_user_by_email(db, user_data.email)
    if existing_user:
        logger.warning(f"❌ Email already registered: {user_data.email}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    logger.info("✅ Email is available")
    
    # Check if phone already exists
    logger.info("🔍 Checking if phone exists...")
    existing_phone = crud.get_user_by_phone(db, user_data.phone)
    if existing_phone:
        logger.warning(f"❌ Phone already registered: {user_data.phone}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number already registered"
        )
    logger.info("✅ Phone is available")
    
    # Generate verification token
    verification_token = secrets.token_urlsafe(32)
    
    # Get referral code if provided
    referred_by_code = user_data.referral_code if hasattr(user_data, 'referral_code') else None
    
    try:
        # Create user
        user = crud.create_user(db, user_data, verification_token, referred_by_code)
        logger.info(f"✅ User registered successfully: {user.email}")
        return user
    except Exception as e:
        logger.error(f"❌ Error creating user:\n{e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating user: {str(e)}"
        )


@router.post("/login", response_model=Token)
async def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """Login endpoint."""
    logger.info("============================================================")
    logger.info("🔐 Login attempt:")
    logger.info(f"   Email: {login_data.email}")
    logger.info("============================================================")
    
    user = crud.authenticate_user(db, login_data.email, login_data.password)
    if not user:
        logger.warning(f"❌ Invalid credentials for: {login_data.email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    logger.info(f"✅ User authenticated: {user.email}")
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    logger.info(f"✅ Token generated for: {user.email}")
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information."""
    return current_user
