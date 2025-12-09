from datetime import datetime, timedelta
from typing import Tuple, Optional
import uuid

from passlib.context import CryptContext
import jwt
from jwt.exceptions import InvalidTokenError

from app.core.config import settings

# Password hashing context using bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)


def create_access_token(subject: str) -> Tuple[str, str, datetime]:
    """
    Create a JWT access token with embedded jti (JWT ID).
    
    Args:
        subject: The subject of the token (typically user_id)
    
    Returns:
        Tuple of (token_string, jti, expires_at)
    """
    # Generate unique jti for this token
    jti = str(uuid.uuid4())
    
    # Calculate expiration
    expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    expires_at = datetime.utcnow() + expires_delta
    
    # Create token payload
    to_encode = {
        "sub": str(subject),
        "jti": jti,
        "exp": expires_at,
        "type": "access"
    }
    
    # Encode token
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt, jti, expires_at


def create_refresh_token(subject: str) -> Tuple[str, str, datetime]:
    """
    Create a JWT refresh token with embedded jti (JWT ID).
    
    Args:
        subject: The subject of the token (typically user_id)
    
    Returns:
        Tuple of (token_string, jti, expires_at)
    """
    # Generate unique jti for this token
    jti = str(uuid.uuid4())
    
    # Calculate expiration
    expires_delta = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    expires_at = datetime.utcnow() + expires_delta
    
    # Create token payload
    to_encode = {
        "sub": str(subject),
        "jti": jti,
        "exp": expires_at,
        "type": "refresh"
    }
    
    # Encode token
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt, jti, expires_at


def decode_token(token: str) -> Optional[dict]:
    """
    Decode and verify a JWT token.
    
    Args:
        token: The JWT token string
    
    Returns:
        Decoded token payload or None if invalid
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except InvalidTokenError:
        return None
