"""
Authentication API endpoints for registration, login, token refresh, and user profile.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import jwt

from app.db.session import get_db
from app.models import User
from app.schemas import (
    UserCreate, UserResponse, LoginRequest, TokenResponse,
    RefreshRequest, AccessTokenResponse
)
from app.security import (
    verify_password, create_access_token, create_refresh_token, decode_token
)
from app.crud import (
    get_user_by_email, get_user_by_username, create_user,
    get_affiliate_by_code, increment_affiliate_referrals, create_wallet
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user.
    
    - **email**: User's email address (must be unique)
    - **username**: Username (must be unique)
    - **password**: Password (minimum 6 characters)
    - **referral_code**: Optional affiliate referral code
    
    Creates a wallet with balance 0 for the new user.
    If referral_code is provided and valid, links user to referrer and increments referral count.
    """
    # Check if email already exists
    if get_user_by_email(db, user_data.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Check if username already exists
    if get_user_by_username(db, user_data.username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # Handle referral code if provided
    referral_id = None
    if user_data.referral_code:
        affiliate = get_affiliate_by_code(db, user_data.referral_code)
        if affiliate:
            referral_id = affiliate.user_id
            # Increment referral count
            increment_affiliate_referrals(db, affiliate.id)
    
    # Create user
    user = create_user(
        db=db,
        email=user_data.email,
        username=user_data.username,
        password=user_data.password,
        referral_id=referral_id
    )
    
    # Create wallet for user
    create_wallet(db=db, user_id=user.id)
    
    return user


@router.post("/login", response_model=TokenResponse)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """
    Login with email and password.
    
    Returns access token and refresh token on successful authentication.
    
    - **email**: User's email address
    - **password**: User's password
    """
    # Get user by email
    user = get_user_by_email(db, login_data.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Verify password
    if not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Create tokens
    access_token = create_access_token(data={"sub": user.id})
    refresh_token = create_refresh_token(data={"sub": user.id})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/refresh", response_model=AccessTokenResponse)
def refresh_token(refresh_data: RefreshRequest, db: Session = Depends(get_db)):
    """
    Get a new access token using a refresh token.
    
    - **refresh_token**: Valid refresh token
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid refresh token"
    )
    
    try:
        payload = decode_token(refresh_data.refresh_token)
        user_id: int = payload.get("sub")
        token_type: str = payload.get("type")
        
        if user_id is None or token_type != "refresh":
            raise credentials_exception
            
    except jwt.InvalidTokenError:
        raise credentials_exception
    
    # Create new access token
    access_token = create_access_token(data={"sub": user_id})
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """
    Get current authenticated user's profile.
    
    Requires valid access token in Authorization header.
    """
    return current_user
