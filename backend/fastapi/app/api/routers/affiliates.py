"""
Affiliate management endpoints: create affiliate code, get affiliate info, and stats.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app import schemas, crud, models
from app.api.deps import get_current_user

router = APIRouter(prefix="/affiliates", tags=["Affiliates"])


@router.post("/create", response_model=schemas.AffiliateResponse, status_code=status.HTTP_201_CREATED)
async def create_affiliate_code(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create an affiliate code for the current user.
    
    Each user can have one affiliate code. If the user already has a code,
    this endpoint returns the existing code.
    """
    # Check if user already has an affiliate code
    existing_affiliate = crud.get_affiliate_by_user_id(db, user_id=current_user.id)
    if existing_affiliate:
        return existing_affiliate
    
    # Create new affiliate code
    affiliate = crud.create_affiliate(db, user_id=current_user.id)
    return affiliate


@router.get("/{code}", response_model=schemas.AffiliateResponse)
def get_affiliate_by_code(
    code: str,
    db: Session = Depends(get_db)
):
    """
    Get affiliate information by code.
    
    This endpoint is public to allow validation of referral codes
    during registration without authentication.
    """
    affiliate = crud.get_affiliate_by_code(db, code=code)
    if not affiliate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Affiliate code not found"
        )
    return affiliate


@router.get("/me/stats", response_model=schemas.AffiliateStats)
async def get_affiliate_stats(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get affiliate statistics for the current user.
    
    Returns:
    - affiliate_code: The user's affiliate code (if exists)
    - total_referrals: Number of users who signed up with this code
    - total_commissions: Total commission earned from referrals
    """
    stats = crud.get_affiliate_stats(db, user_id=current_user.id)
    return stats
