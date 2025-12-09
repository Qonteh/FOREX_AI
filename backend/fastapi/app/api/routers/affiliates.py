"""
Affiliate API endpoints for creating and managing referral codes.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import User
from app.schemas import AffiliateCreate, AffiliateResponse, AffiliateStats
from app.crud import (
    get_affiliate_by_code, get_affiliate_by_user_id, create_affiliate
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/affiliates", tags=["affiliates"])


@router.post("/create", response_model=AffiliateResponse, status_code=status.HTTP_201_CREATED)
def create_affiliate_code(
    affiliate_data: AffiliateCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create an affiliate referral code for the current user.
    
    Requires authentication.
    
    - **code**: Unique affiliate code (3-50 characters)
    
    A user can only have one affiliate code.
    """
    # Check if user already has an affiliate code
    existing_affiliate = get_affiliate_by_user_id(db, current_user.id)
    if existing_affiliate:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already has an affiliate code"
        )
    
    # Check if code is already taken
    if get_affiliate_by_code(db, affiliate_data.code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Affiliate code already exists"
        )
    
    # Create affiliate
    affiliate = create_affiliate(
        db=db,
        user_id=current_user.id,
        code=affiliate_data.code
    )
    
    return affiliate


@router.get("/{code}", response_model=AffiliateResponse)
def get_affiliate(code: str, db: Session = Depends(get_db)):
    """
    Get affiliate details by referral code.
    
    - **code**: Affiliate referral code
    
    Returns affiliate information including total referrals.
    """
    affiliate = get_affiliate_by_code(db, code)
    if not affiliate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Affiliate code not found"
        )
    
    return affiliate


@router.get("/my/stats", response_model=AffiliateStats)
def get_my_affiliate_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get affiliate statistics for the current user.
    
    Requires authentication.
    
    Returns the user's affiliate code and referral statistics.
    """
    affiliate = get_affiliate_by_user_id(db, current_user.id)
    if not affiliate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User does not have an affiliate code"
        )
    
    return AffiliateStats(
        code=affiliate.code,
        total_referrals=affiliate.total_referrals,
        created_at=affiliate.created_at
    )
