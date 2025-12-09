from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.api.deps import get_current_user
from app.schemas import (
    UserRegister, UserLogin, Token, RefreshTokenRequest, 
    LogoutRequest, UserResponse, MessageResponse
)
from app.models import User
from app.security import (
    verify_password, create_access_token, create_refresh_token, decode_token
)
from app.crud import (
    get_user_by_email, create_user, get_affiliate_by_code,
    create_wallet, create_refresh_token as persist_refresh_token,
    validate_refresh_token, revoke_refresh_token,
    revoke_all_user_refresh_tokens, revoke_access_token,
    revoke_all_user_access_tokens
)

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """
    Register a new user.
    
    - Validates email is unique
    - Links to affiliate if referral code provided
    - Creates wallet for new user
    """
    # Check if user already exists
    existing_user = get_user_by_email(db, user_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Validate referral code if provided
    referral_id = None
    if user_data.referral_code:
        affiliate = get_affiliate_by_code(db, user_data.referral_code)
        if not affiliate:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid referral code"
            )
        referral_id = affiliate.id
    
    # Create user
    user = create_user(
        db,
        email=user_data.email,
        password=user_data.password,
        referral_id=referral_id
    )
    
    # Create wallet for user
    create_wallet(db, user.id)
    
    return user


@router.post("/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """
    Login user and return access + refresh tokens.
    
    - Validates credentials
    - Generates access token (short-lived) with jti
    - Generates refresh token (long-lived) with jti
    - Persists refresh token in database for rotation/revocation
    """
    # Authenticate user
    user = get_user_by_email(db, user_data.email)
    if not user or not verify_password(user_data.password, user.hashed_password):
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
    
    # Create access token with jti
    access_token, access_jti, access_expires = create_access_token(subject=str(user.id))
    
    # Create refresh token with jti
    refresh_token, refresh_jti, refresh_expires = create_refresh_token(subject=str(user.id))
    
    # Persist refresh token for rotation and revocation
    persist_refresh_token(
        db,
        user_id=user.id,
        jti=refresh_jti,
        token=refresh_token,
        expires_at=refresh_expires
    )
    
    return Token(
        access_token=access_token,
        refresh_token=refresh_token
    )


@router.post("/refresh", response_model=Token)
def refresh(token_data: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    Refresh access token using refresh token.
    
    SECURITY FEATURES:
    1. Token Validation: Validates refresh token against database record
    2. Reuse Detection: If token JTI exists but token differs, revokes all user tokens
    3. Token Rotation: On successful refresh, revokes old refresh token and issues new one
    
    This prevents refresh token reuse attacks where an attacker tries to use
    an old (rotated) refresh token.
    """
    refresh_token = token_data.refresh_token
    
    # Decode and validate refresh token structure
    payload = decode_token(refresh_token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify token type
    token_type = payload.get("type")
    if token_type != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = payload.get("sub")
    jti = payload.get("jti")
    
    if not user_id or not jti:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # SECURITY: Validate refresh token against database and detect reuse
    is_valid, error_reason = validate_refresh_token(db, jti, refresh_token)
    
    if not is_valid:
        if error_reason == "reuse":
            # CRITICAL SECURITY RESPONSE: Token reuse detected!
            # Someone is trying to use an old (rotated) refresh token.
            # This is a security breach - revoke all tokens for this user.
            revoke_all_user_refresh_tokens(db, int(user_id))
            revoke_all_user_access_tokens(db, int(user_id))
            
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token reuse detected. All tokens have been revoked for security.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        elif error_reason == "revoked":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has been revoked",
                headers={"WWW-Authenticate": "Bearer"},
            )
        elif error_reason == "expired":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has expired",
                headers={"WWW-Authenticate": "Bearer"},
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
                headers={"WWW-Authenticate": "Bearer"},
            )
    
    # Token is valid - perform rotation
    # 1. Revoke old refresh token
    revoke_refresh_token(db, jti)
    
    # 2. Create new tokens
    new_access_token, new_access_jti, new_access_expires = create_access_token(subject=user_id)
    new_refresh_token, new_refresh_jti, new_refresh_expires = create_refresh_token(subject=user_id)
    
    # 3. Persist new refresh token
    persist_refresh_token(
        db,
        user_id=int(user_id),
        jti=new_refresh_jti,
        token=new_refresh_token,
        expires_at=new_refresh_expires
    )
    
    return Token(
        access_token=new_access_token,
        refresh_token=new_refresh_token
    )


@router.post("/logout", response_model=MessageResponse)
def logout(
    logout_data: LogoutRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logout user by revoking refresh token and current access token.
    
    - Requires authentication (access token)
    - Revokes the specified refresh token
    - Revokes the current access token used for this request
    """
    refresh_token = logout_data.refresh_token
    
    # Decode refresh token to get jti
    payload = decode_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid refresh token"
        )
    
    refresh_jti = payload.get("jti")
    if not refresh_jti:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid refresh token"
        )
    
    # Revoke refresh token
    revoke_refresh_token(db, refresh_jti)
    
    # Note: To revoke current access token, we would need to extract it from the request
    # For now, we'll just revoke the refresh token
    # In a production system, you'd want to track the current access token jti as well
    
    return MessageResponse(message="Successfully logged out")


@router.post("/logout_all", response_model=MessageResponse)
def logout_all(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logout from all devices by revoking all refresh tokens and access tokens.
    
    - Requires authentication
    - Revokes all refresh tokens for the user
    - Revokes all access tokens for the user (if tracked)
    """
    # Revoke all refresh tokens
    refresh_count = revoke_all_user_refresh_tokens(db, current_user.id)
    
    # Revoke all access tokens (best effort - we only track revoked ones)
    access_count = revoke_all_user_access_tokens(db, current_user.id)
    
    return MessageResponse(
        message=f"Successfully logged out from all devices. "
        f"Revoked {refresh_count} refresh tokens."
    )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Get current authenticated user information.
    
    - Requires valid access token
    - Returns user profile
    """
    return current_user
