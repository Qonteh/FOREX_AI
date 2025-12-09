from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.api.deps import get_current_user
from app.schemas import AffiliateCreate, AffiliateResponse, AffiliateStats
from app.models import User
from app.crud import (
    get_affiliate_by_user_id, get_affiliate_by_code,
    create_affiliate, get_affiliate_referral_count
)

router = APIRouter()


@router.post("/create", response_model=AffiliateResponse, status_code=status.HTTP_201_CREATED)
def create_affiliate_code(
    affiliate_data: AffiliateCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create affiliate code for current user.
    
    - User can only have one affiliate code
    - Code must be unique
    """
    # Check if user already has affiliate code
    existing_affiliate = get_affiliate_by_user_id(db, current_user.id)
    if existing_affiliate:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already has an affiliate code"
        )
    
    # Check if code is already taken
    existing_code = get_affiliate_by_code(db, affiliate_data.code)
    if existing_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Affiliate code already exists"
        )
    
    # Create affiliate
    affiliate = create_affiliate(db, current_user.id, affiliate_data.code)
    return affiliate


@router.get("/me", response_model=AffiliateResponse)
def get_my_affiliate(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's affiliate information.
    """
    affiliate = get_affiliate_by_user_id(db, current_user.id)
    if not affiliate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User does not have an affiliate code"
        )
    return affiliate


@router.get("/stats", response_model=AffiliateStats)
def get_affiliate_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get affiliate statistics for current user.
    
    Returns:
    - Total referrals count
    - Total commission earned (placeholder - not implemented in this MVP)
    """
    affiliate = get_affiliate_by_user_id(db, current_user.id)
    if not affiliate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User does not have an affiliate code"
        )
    
    # Get referral count
    referral_count = get_affiliate_referral_count(db, affiliate.id)
    
    # Calculate commission (placeholder - in real app, sum commission transactions)
    # For now, just return 0
    total_commission = 0.0
    
    return AffiliateStats(
        code=affiliate.code,
        total_referrals=referral_count,
        total_commission=total_commission
    )
