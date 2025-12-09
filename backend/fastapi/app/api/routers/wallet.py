from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.api.deps import get_current_user
from app.schemas import (
    WalletResponse, DepositRequest, WithdrawRequest,
    TransactionResponse, MessageResponse
)
from app.models import User, TransactionType
from app.crud import (
    get_wallet_by_user_id, update_wallet_balance,
    create_transaction, get_wallet_transactions
)

router = APIRouter()


@router.get("/balance", response_model=WalletResponse)
def get_balance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's wallet balance.
    """
    wallet = get_wallet_by_user_id(db, current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    return wallet


@router.post("/deposit", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def deposit(
    deposit_data: DepositRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Deposit funds to user's wallet.
    
    - Amount must be positive
    - Updates wallet balance
    - Creates transaction record
    """
    wallet = get_wallet_by_user_id(db, current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    # Update wallet balance
    update_wallet_balance(db, wallet.id, deposit_data.amount)
    
    # Create transaction record
    transaction = create_transaction(
        db,
        wallet_id=wallet.id,
        amount=deposit_data.amount,
        transaction_type=TransactionType.deposit,
        description=deposit_data.description or "Deposit"
    )
    
    return transaction


@router.post("/withdraw", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def withdraw(
    withdraw_data: WithdrawRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Withdraw funds from user's wallet.
    
    - Amount must be positive
    - Must have sufficient balance
    - Updates wallet balance
    - Creates transaction record
    """
    wallet = get_wallet_by_user_id(db, current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    # Check sufficient balance
    if wallet.balance < withdraw_data.amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient balance"
        )
    
    # Update wallet balance (negative amount for withdrawal)
    update_wallet_balance(db, wallet.id, -withdraw_data.amount)
    
    # Create transaction record (stored as positive amount with withdraw type)
    transaction = create_transaction(
        db,
        wallet_id=wallet.id,
        amount=withdraw_data.amount,
        transaction_type=TransactionType.withdraw,
        description=withdraw_data.description or "Withdrawal"
    )
    
    return transaction


@router.get("/transactions", response_model=List[TransactionResponse])
def get_transactions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all transactions for current user's wallet.
    
    Returns transactions in descending order (most recent first).
    """
    wallet = get_wallet_by_user_id(db, current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    transactions = get_wallet_transactions(db, wallet.id)
    return transactions
