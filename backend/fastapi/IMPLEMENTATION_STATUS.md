# Implementation Status - Extended Features

## Completed ✅

### 1. Port Change (8000 → 8001)
- ✅ Flutter API service updated
- ✅ Main.dart logging updated
- ✅ Ready to run on port 8001

### 2. Extended Database Models
- ✅ **Users**: Email verification, subscriptions, referral codes
- ✅ **Wallets**: Balance tracking, earnings, withdrawals
- ✅ **Transactions**: All financial transactions
- ✅ **Referrals**: Referral tracking with 30% commission
- ✅ **Subscriptions**: Plan management and billing

### 3. Email Verification System
- ✅ EmailService created with SMTP support
- ✅ Development mode (prints links in console)
- ✅ HTML email templates
- ✅ Welcome email after verification

### 4. Signup Flow Changes
- ✅ No auto-login after registration
- ✅ Redirects to login page
- ✅ Prompts user to verify email

### 5. CRUD Operations
- ✅ Extended CRUD with all new models
- ✅ Referral code generation
- ✅ Wallet initialization on signup
- ✅ Commission processing
- ✅ Subscription management

## Remaining Tasks ⏳

### 1. Update Auth Router
**File**: `app/api/routers/auth.py`

**Changes Needed**:
```python
# Update register endpoint to:
from app.email_service import EmailService

@router.post("/register")
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Generate verification token
    email_service = EmailService()
    verification_token = email_service.generate_verification_token()
    
    # Create user with verification token
    user = crud.create_user(
        db, 
        user_data, 
        verification_token,
        referred_by_code=user_data.referred_by_code
    )
    
    # Send verification email
    email_service.send_verification_email(
        user.email,
        user.name,
        verification_token
    )
    
    # Return success message (NO TOKEN - user must verify first)
    return {
        "message": "Registration successful! Please check your email to verify your account.",
        "email": user.email
    }

# Add new endpoint:
@router.get("/verify-email")
async def verify_email(token: str, db: Session = Depends(get_db)):
    user = crud.get_user_by_verification_token(db, token)
    if not user:
        raise HTTPException(404, "Invalid or expired verification token")
    
    # Verify user
    user = crud.verify_user_email(db, user)
    
    # Send welcome email
    email_service = EmailService()
    email_service.send_welcome_email(user.email, user.name)
    
    return {
        "message": "Email verified successfully! You can now login.",
        "user": UserOut.model_validate(user)
    }

# Update login endpoint to check email verification:
@router.post("/login")
async def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, credentials.email)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    
    if not crud.verify_password(credentials.password, user.hashed_password):
        raise HTTPException(401, "Invalid credentials")
    
    # Check email verification
    if not user.is_email_verified:
        raise HTTPException(403, "Please verify your email before logging in")
    
    # Update last login
    user = crud.update_user_login(db, user)
    
    # Create token
    access_token = create_access_token({"sub": user.id, "email": user.email})
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )
```

### 2. Update Database Setup Script
**File**: `setup_database.py`

**Changes Needed**:
```python
# Import new models
from app.models import Base, User, Wallet, Referral, Transaction, Subscription

# Create all tables
Base.metadata.create_all(bind=engine)
```

### 3. Add Wallet & Referral Endpoints
**New File**: `app/api/routers/wallet.py`

```python
@router.get("/wallet")
async def get_wallet(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    wallet = crud.get_user_wallet(db, current_user.id)
    return WalletOut.model_validate(wallet)

@router.get("/referrals")
async def get_referrals(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    referrals = crud.get_user_referrals(db, current_user.id)
    stats = crud.get_referral_stats(db, current_user.id)
    return {
        "referral_code": current_user.referral_code,
        "stats": stats,
        "referrals": [ReferralOut.model_validate(r) for r in referrals]
    }

@router.get("/transactions")
async def get_transactions(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    transactions = crud.get_user_transactions(db, current_user.id)
    return [TransactionOut.model_validate(t) for t in transactions]
```

### 4. Update Main.py
**Changes Needed**:
```python
# Add new routers
from app.api.routers import auth, wallet

app.include_router(auth.router)
app.include_router(wallet.router)

# Update to run on port 8001 by default
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
```

## Testing Checklist

### Registration Flow
1. [ ] User registers with email/password/phone
2. [ ] Verification email sent (check console in dev mode)
3. [ ] User redirected to login page
4. [ ] Wallet created automatically
5. [ ] Referral code generated

### Email Verification
1. [ ] Click verification link
2. [ ] Account status changes to ACTIVE
3. [ ] is_email_verified = True
4. [ ] Welcome email sent

### Login Flow
1. [ ] User cannot login before email verification
2. [ ] After verification, login works
3. [ ] Token generated
4. [ ] last_login_at updated

### Referral System
1. [ ] User A gets referral code (e.g., QT123456)
2. [ ] User B registers with User A's referral code
3. [ ] Referral record created
4. [ ] When User B subscribes, User A gets 30% commission
5. [ ] Commission added to User A's pending balance

## Quick Start Commands

```bash
# 1. Install dependencies
cd backend/fastapi
pip install -r requirements.txt

# 2. Setup database (creates all tables)
python setup_database.py

# 3. Run backend on port 8001
uvicorn main:app --reload --port 8001

# 4. Test registration
curl -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "phone": "+1234567890"
  }'

# 5. Check console for verification link (in dev mode)
# 6. Visit verification link
# 7. Login

curl -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## Environment Variables

Create `.env` file:
```
# Database
DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@localhost:3306/forex_ai

# JWT
SECRET_KEY=your-super-secret-key-change-in-production

# Email (Optional - for production)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=noreply@forexai.com
FROM_NAME=FOREX AI Trading

# Application
BASE_URL=http://localhost:8001
```

## Database Schema Summary

### Users
- Basic info + email verification + subscriptions + referrals

### Wallets (1:1 with Users)
- balance, pending_balance
- total_earned, total_withdrawn
- referral_earnings, bonus_earnings

### Referrals (Many:Many Users)
- referrer_id, referred_id
- commission tracking

### Transactions
- All financial activities
- Linked to users and referrals

### Subscriptions
- Plan management
- Billing cycles
- Auto-renewal

## Notes

- Development mode prints verification links in console (no SMTP needed)
- Production mode requires SMTP configuration
- Referral commission: 30% of subscription price
- Email verification required before login
- Wallet created automatically on registration
- Referral code format: QT + 6 digits (e.g., QT123456)
