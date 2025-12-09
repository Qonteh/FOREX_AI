"""
Wallet API endpoints for balance, deposits, withdrawals, and transaction history.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import User
from app.schemas import (
    WalletResponse, DepositRequest, WithdrawRequest,
    TransactionResponse, TransactionListResponse
)
from app.crud import (
    get_wallet_by_user_id, update_wallet_balance,
    create_transaction, get_transactions_by_wallet_id,
    count_transactions_by_wallet_id
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/wallet", tags=["wallet"])


@router.get("", response_model=WalletResponse)
def get_wallet(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's wallet balance.
    
    Requires authentication.
    
    Returns wallet information including current balance.
    """
    wallet = get_wallet_by_user_id(db, current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    return wallet


@router.post("/deposit", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def deposit_funds(
    deposit_data: DepositRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Deposit funds into the wallet.
    
    Requires authentication.
    
    - **amount**: Amount to deposit (must be positive)
    - **description**: Optional description for the transaction
    
    Creates a deposit transaction and updates the wallet balance.
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
        db=db,
        wallet_id=wallet.id,
        amount=deposit_data.amount,
        transaction_type="deposit",
        description=deposit_data.description
    )
    
    return transaction


@router.post("/withdraw", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def withdraw_funds(
    withdraw_data: WithdrawRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Withdraw funds from the wallet.
    
    Requires authentication.
    
    - **amount**: Amount to withdraw (must be positive)
    - **description**: Optional description for the transaction
    
    Validates sufficient balance before withdrawal.
    Creates a withdrawal transaction and updates the wallet balance.
    """
    wallet = get_wallet_by_user_id(db, current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    # Check for sufficient balance
    if wallet.balance < withdraw_data.amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient funds"
        )
    
    # Update wallet balance (subtract)
    update_wallet_balance(db, wallet.id, -withdraw_data.amount)
    
    # Create transaction record
    transaction = create_transaction(
        db=db,
        wallet_id=wallet.id,
        amount=withdraw_data.amount,
        transaction_type="withdraw",
        description=withdraw_data.description
    )
    
    return transaction


@router.get("/transactions", response_model=TransactionListResponse)
def get_transactions(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get transaction history for the current user's wallet.
    
    Requires authentication.
    
    - **skip**: Number of transactions to skip (for pagination)
    - **limit**: Maximum number of transactions to return (max 100)
    
    Returns list of transactions ordered by most recent first.
    """
    wallet = get_wallet_by_user_id(db, current_user.id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found"
        )
    
    transactions = get_transactions_by_wallet_id(db, wallet.id, skip=skip, limit=limit)
    total = count_transactions_by_wallet_id(db, wallet.id)
    
    return TransactionListResponse(
        transactions=transactions,
        total=total
    )
