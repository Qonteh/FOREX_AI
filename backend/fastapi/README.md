# FOREX AI Backend - FastAPI

A secure, minimal FastAPI backend implementing authentication, affiliates, and wallet features with MySQL (XAMPP) database.

## Features

### Authentication
- **JWT-based authentication** with access and refresh tokens
- **Secure password hashing** using bcrypt via passlib
- **Access token revocation** - Revoked tokens are tracked and rejected
- **Refresh token rotation** - New refresh token issued on each refresh
- **Refresh token reuse detection** - Security response to prevent token replay attacks
- **Multiple logout options**:
  - Single device logout (revokes one refresh token)
  - All devices logout (revokes all refresh tokens and access tokens)

### Security Features
- Access tokens: Short-lived (30 minutes by default)
- Refresh tokens: Long-lived (30 days by default), persisted in database
- Each token has unique JTI (JWT ID) for tracking
- Token reuse detection: If an old (rotated) refresh token is reused, all user tokens are revoked
- Access token revocation list with automatic expiration cleanup

### Affiliates
- Create unique referral codes
- Track referrals and commissions
- Link new users via referral codes during registration

### Wallet
- Balance management
- Deposit and withdraw operations
- Transaction history tracking
- Transaction types: deposit, withdraw, commission

## Prerequisites

1. **XAMPP** with MySQL installed and running
2. **Python 3.8+**
3. **pip** package manager

## Installation & Setup

### 1. Start XAMPP MySQL

1. Open XAMPP Control Panel
2. Start **MySQL** module
3. (Optional) Start **Apache** if you want to use phpMyAdmin
4. Access phpMyAdmin at `http://localhost/phpmyadmin`

### 2. Create Database

Using phpMyAdmin or MySQL command line:

```sql
CREATE DATABASE forex_ai_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and update values as needed:

```env
# Database Configuration (XAMPP MySQL)
DATABASE_URL=mysql+mysqlconnector://root:@localhost:3306/forex_ai_db

# JWT Secret Keys (IMPORTANT: Change in production!)
SECRET_KEY=your-secret-key-change-this-in-production-min-32-chars
ALGORITHM=HS256

# Token Expiration
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=30

# Application
PROJECT_NAME=FOREX AI Backend
DEBUG=True
```

**Note:** If your XAMPP MySQL has a password, update the DATABASE_URL:
```
DATABASE_URL=mysql+mysqlconnector://root:YOUR_PASSWORD@localhost:3306/forex_ai_db
```

### 4. Install Dependencies

```bash
pip install -r requirements.txt
```

### 5. Run the Application

```bash
uvicorn app.main:app --reload --port 8000
```

The API will be available at:
- **API Base URL:** http://localhost:8000
- **Interactive Docs:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

## Database Tables

Tables are **automatically created** on application startup. The following tables will be created:

- `users` - User accounts with authentication
- `affiliates` - Affiliate/referral codes
- `wallets` - User wallet balances
- `transactions` - Wallet transaction history
- `refresh_tokens` - Persisted refresh tokens for rotation/revocation
- `revoked_access_tokens` - Revoked access token JTIs

## API Endpoints

### Authentication (`/auth`)

#### POST `/auth/register`
Register a new user.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "referral_code": "OPTIONAL_CODE"
}
```

**Response:** User object

#### POST `/auth/login`
Login and get access + refresh tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

#### POST `/auth/refresh`
Refresh access token using refresh token.

**Features:**
- Validates refresh token against database
- Detects token reuse (security breach)
- Rotates refresh token (old token revoked, new token issued)
- If reuse detected: Revokes ALL user tokens and returns 401

**Request Body:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

#### POST `/auth/logout`
Logout from current device.

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response:**
```json
{
  "message": "Successfully logged out"
}
```

#### POST `/auth/logout_all`
Logout from all devices (revoke all tokens).

**Headers:** `Authorization: Bearer <access_token>`

**Response:**
```json
{
  "message": "Successfully logged out from all devices. Revoked X refresh tokens."
}
```

#### GET `/auth/me`
Get current user information.

**Headers:** `Authorization: Bearer <access_token>`

**Response:** User object

### Affiliates (`/affiliates`)

All affiliate endpoints require authentication (`Authorization: Bearer <access_token>`).

#### POST `/affiliates/create`
Create affiliate code for current user.

**Request Body:**
```json
{
  "code": "MYCODE123"
}
```

**Response:** Affiliate object

#### GET `/affiliates/me`
Get current user's affiliate information.

**Response:** Affiliate object

#### GET `/affiliates/stats`
Get affiliate statistics.

**Response:**
```json
{
  "code": "MYCODE123",
  "total_referrals": 5,
  "total_commission": 0.0
}
```

### Wallet (`/wallet`)

All wallet endpoints require authentication (`Authorization: Bearer <access_token>`).

#### GET `/wallet/balance`
Get current wallet balance.

**Response:**
```json
{
  "id": 1,
  "user_id": 1,
  "balance": 1000.0
}
```

#### POST `/wallet/deposit`
Deposit funds to wallet.

**Request Body:**
```json
{
  "amount": 100.0,
  "description": "Initial deposit"
}
```

**Response:** Transaction object

#### POST `/wallet/withdraw`
Withdraw funds from wallet.

**Request Body:**
```json
{
  "amount": 50.0,
  "description": "Withdrawal"
}
```

**Response:** Transaction object

#### GET `/wallet/transactions`
Get all transactions for current user's wallet.

**Response:** Array of transaction objects

## Testing Token Security

### Test Refresh Token Rotation

1. **Login:**
   ```bash
   curl -X POST http://localhost:8000/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email": "user@example.com", "password": "password123"}'
   ```
   Save both `access_token` and `refresh_token`.

2. **Refresh once (normal flow):**
   ```bash
   curl -X POST http://localhost:8000/auth/refresh \
     -H "Content-Type: application/json" \
     -d '{"refresh_token": "OLD_REFRESH_TOKEN"}'
   ```
   You'll get new access and refresh tokens. Save the new tokens.

3. **Try to reuse old refresh token (reuse detection):**
   ```bash
   curl -X POST http://localhost:8000/auth/refresh \
     -H "Content-Type: application/json" \
     -d '{"refresh_token": "OLD_REFRESH_TOKEN"}'
   ```
   **Expected:** 401 Unauthorized with message "Token reuse detected. All tokens have been revoked for security."
   
   This demonstrates the security response - all user tokens are revoked when reuse is detected.

### Test Access Token Revocation

1. **Login and get tokens**
2. **Call `/auth/me` with access token** - Should work
3. **Logout all devices:**
   ```bash
   curl -X POST http://localhost:8000/auth/logout_all \
     -H "Authorization: Bearer ACCESS_TOKEN"
   ```
4. **Try to call `/auth/me` again with same access token** - Should fail with 401

## Project Structure

```
backend/fastapi/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── models.py            # SQLAlchemy database models
│   ├── schemas.py           # Pydantic request/response schemas
│   ├── security.py          # JWT token creation/validation, password hashing
│   ├── crud.py              # Database operations and token management
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py        # Configuration settings
│   ├── db/
│   │   ├── __init__.py
│   │   └── session.py       # Database session management
│   └── api/
│       ├── __init__.py
│       ├── deps.py          # API dependencies (authentication)
│       └── routers/
│           ├── __init__.py
│           ├── auth.py      # Authentication endpoints
│           ├── affiliates.py # Affiliate endpoints
│           └── wallet.py     # Wallet endpoints
├── .env.example             # Environment variables template
├── requirements.txt         # Python dependencies
└── README.md               # This file
```

## Security Considerations

### Token Security
- **Access tokens** are short-lived and should be used for API requests
- **Refresh tokens** are long-lived and should be stored securely (e.g., httpOnly cookies in production)
- **Token rotation** ensures refresh tokens are single-use
- **Reuse detection** prevents token replay attacks
- **Revocation lists** allow immediate token invalidation

### Production Recommendations
1. **Use strong SECRET_KEY**: Generate with `openssl rand -hex 32`
2. **Use HTTPS**: Never send tokens over unencrypted connections
3. **Secure token storage**: Store refresh tokens in httpOnly cookies
4. **Rate limiting**: Add rate limiting to prevent brute force attacks
5. **Environment security**: Never commit `.env` file
6. **Database security**: Use strong database passwords
7. **CORS configuration**: Restrict allowed origins in production
8. **Token expiration**: Adjust token lifetimes based on your security requirements

## Troubleshooting

### Database Connection Error
- Ensure XAMPP MySQL is running
- Check database name exists: `forex_ai_db`
- Verify DATABASE_URL in `.env` matches your MySQL configuration
- If MySQL has password, include it in connection string

### Import Errors
- Ensure all dependencies are installed: `pip install -r requirements.txt`
- Check Python version: `python --version` (requires 3.8+)

### Tables Not Created
- Check console output on startup for errors
- Manually verify database exists in phpMyAdmin
- Check database user has CREATE TABLE privileges

### Token Issues
- Verify SECRET_KEY is set in `.env`
- Check token hasn't expired
- For revocation issues, check `revoked_access_tokens` table

## Development

### Running in Development Mode

The application is configured for development by default:
- Auto-reload on code changes (`--reload` flag)
- Debug mode enabled
- SQL query logging enabled
- CORS allows all origins

### Adding New Features

1. Add models to `app/models.py`
2. Add schemas to `app/schemas.py`
3. Add CRUD functions to `app/crud.py`
4. Create router in `app/api/routers/`
5. Include router in `app/main.py`

## License

This project is for educational/development purposes.
