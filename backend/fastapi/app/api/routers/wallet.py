"""
Wallet management endpoints: balance, deposit, withdraw, and transaction history.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app import schemas, crud, models
from app.api.deps import get_current_user

router = APIRouter(prefix="/wallet", tags=["Wallet"])


@router.get("", response_model=schemas.WalletResponse)
async def get_wallet(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's wallet balance.
    
    Returns the wallet information including current balance.
    """
    wallet = crud.get_wallet_by_user_id(db, user_id=current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    return wallet


@router.post("/deposit", response_model=schemas.TransactionResponse, status_code=status.HTTP_201_CREATED)
async def deposit(
    deposit_request: schemas.DepositRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Deposit funds to wallet.
    
    Creates a deposit transaction and updates the wallet balance.
    """
    # Get user's wallet
    wallet = crud.get_wallet_by_user_id(db, user_id=current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    # Create deposit transaction
    transaction = crud.create_transaction(
        db=db,
        wallet_id=wallet.id,
        amount=deposit_request.amount,
        transaction_type=models.TransactionType.DEPOSIT,
        description=deposit_request.description or "Deposit"
    )
    
    # Update wallet balance
    crud.update_wallet_balance(db, wallet_id=wallet.id, amount=deposit_request.amount)
    
    return transaction


@router.post("/withdraw", response_model=schemas.TransactionResponse, status_code=status.HTTP_201_CREATED)
async def withdraw(
    withdraw_request: schemas.WithdrawRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Withdraw funds from wallet.
    
    Creates a withdrawal transaction and updates the wallet balance.
    Validates that sufficient funds are available.
    """
    # Get user's wallet
    wallet = crud.get_wallet_by_user_id(db, user_id=current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    # Check if sufficient funds available
    if wallet.balance < withdraw_request.amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Insufficient funds. Available balance: {wallet.balance}"
        )
    
    # Create withdrawal transaction
    transaction = crud.create_transaction(
        db=db,
        wallet_id=wallet.id,
        amount=-withdraw_request.amount,  # Negative amount for withdrawal
        transaction_type=models.TransactionType.WITHDRAW,
        description=withdraw_request.description or "Withdrawal"
    )
    
    # Update wallet balance
    crud.update_wallet_balance(db, wallet_id=wallet.id, amount=-withdraw_request.amount)
    
    return transaction


@router.get("/transactions", response_model=schemas.TransactionListResponse)
async def get_transactions(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get transaction history for current user's wallet.
    
    Supports pagination with skip and limit parameters.
    Returns transactions ordered by creation date (newest first).
    """
    # Get user's wallet
    wallet = crud.get_wallet_by_user_id(db, user_id=current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    # Get transactions
    transactions = crud.get_transactions_by_wallet(db, wallet_id=wallet.id, skip=skip, limit=limit)
    total = crud.get_transaction_count(db, wallet_id=wallet.id)
    
    return {
        "transactions": transactions,
        "total": total
    }
