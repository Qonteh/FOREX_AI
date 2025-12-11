"""
Authentication routes for user registration and login.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import os
import jwt

from app.database import get_db
from app.schemas import UserCreate, UserOut, UserLogin, Token
from app import crud

router = APIRouter(prefix="/auth", tags=["Authentication"])

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """
    Register a new user.
    
    Validates that:
    - Email is unique
    - Phone number is unique
    - All required fields are provided
    
    Accepts both 'phone' and 'tel' field names for frontend compatibility.
    
    Returns:
        JWT token and user data
    """
    # Log the registration attempt
    print(f"\n{'='*60}")
    print(f"📝 Registration attempt:")
    print(f"   Email: {user_data.email}")
    print(f"   Phone: {user_data.phone}")
    print(f"   Name: {user_data.name}")
    print(f"{'='*60}\n")
    
    # Check if user with email already exists
    try:
        print(f"🔍 Checking if email exists...")
        existing_user = crud.get_user_by_email(db, user_data.email.lower())
        if existing_user:
            print(f"❌ Email already registered: {user_data.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered. Please use a different email or login."
            )
        print(f"✅ Email is available")
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"❌ Database error checking email:")
        print(error_details)
        
        # Provide helpful error message based on the error type
        error_msg = str(e)
        if "Table" in error_msg and "doesn't exist" in error_msg:
            detail = (
                "Database table 'users' does not exist. "
                "Please run the database setup script: "
                "python setup_database.py"
            )
        elif "Can't connect" in error_msg or "Access denied" in error_msg:
            detail = (
                "Cannot connect to MySQL database. "
                "Please check MySQL is running and credentials are correct."
            )
        else:
            detail = f"Database error: {error_msg}"
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=detail
        )
    
    # Check if user with phone already exists
    try:
        print(f"🔍 Checking if phone exists...")
        existing_phone = crud.get_user_by_phone(db, user_data.phone)
        if existing_phone:
            print(f"❌ Phone already registered: {user_data.phone}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Phone number already registered. Please use a different phone number or login."
            )
        print(f"✅ Phone is available")
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"❌ Database error checking phone:")
        print(error_details)
        
        # Provide helpful error message based on the error type
        error_msg = str(e)
        if "Table" in error_msg and "doesn't exist" in error_msg:
            detail = (
                "Database table 'users' does not exist. "
                "Please run the database setup script: "
                "python setup_database.py"
            )
        elif "Can't connect" in error_msg or "Access denied" in error_msg:
            detail = (
                "Cannot connect to MySQL database. "
                "Please check MySQL is running and credentials are correct."
            )
        else:
            detail = f"Database error: {error_msg}"
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=detail
        )
    
    # Create new user
    try:
        print(f"📝 Creating new user...")
        user = crud.create_user(db, user_data)
        print(f"✅ User created successfully: ID={user.id}")
    except Exception as e:
        # Log the full error for debugging
        import traceback
        error_details = traceback.format_exc()
        print(f"❌ Error creating user:")
        print(error_details)
        
        # Provide helpful error message
        error_msg = str(e)
        if "Duplicate entry" in error_msg:
            if "email" in error_msg:
                detail = "Email already exists in database"
            elif "phone" in error_msg:
                detail = "Phone number already exists in database"
            else:
                detail = "Duplicate entry in database"
        else:
            detail = f"Failed to create user: {error_msg}"
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=detail
        )
    
    # Create access token
    try:
        print(f"🔐 Creating access token...")
        access_token = create_access_token(
            data={"sub": user.id, "email": user.email}
        )
        print(f"✅ Access token created")
        print(f"\n{'='*60}")
        print(f"✅ Registration successful!")
        print(f"   User ID: {user.id}")
        print(f"   Email: {user.email}")
        print(f"{'='*60}\n")
    except Exception as e:
        print(f"❌ Error creating token: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create authentication token: {str(e)}"
        )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )


@router.post("/login", response_model=Token)
async def login(
    credentials: UserLogin,
    db: Session = Depends(get_db)
):
    """
    Login with email and password.
    
    Returns:
        JWT token and user data
    """
    user = crud.authenticate_user(db, credentials.email, credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    # Create access token
    access_token = create_access_token(
        data={"sub": user.id, "email": user.email}
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )


@router.get("/me", response_model=UserOut)
async def get_current_user(
    token: str,
    db: Session = Depends(get_db)
):
    """
    Get current authenticated user.
    
    Args:
        token: JWT access token
        
    Returns:
        Current user data
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials"
            )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )
    
    user = crud.get_user_by_id(db, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return UserOut.model_validate(user)
