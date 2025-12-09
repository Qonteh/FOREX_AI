# FastAPI Backend for FOREX_AI

A minimal, secure, and well-structured FastAPI backend that provides authentication, affiliate management, and wallet functionality using MySQL (XAMPP) as the database.

## Features

- **JWT-based Authentication**: Secure access and refresh tokens
- **User Management**: Registration, login, and profile access
- **Affiliate System**: Create affiliate codes, track referrals, and manage commissions
- **Wallet Management**: Balance tracking, deposits, withdrawals, and transaction history

## Prerequisites

- Python 3.8+
- XAMPP with MySQL running
- pip (Python package manager)

## Setup Instructions

### 1. Database Setup (XAMPP)

1. Start XAMPP Control Panel
2. Start the MySQL service
3. Open phpMyAdmin (http://localhost/phpmyadmin)
4. Create a new database named `forex_ai` (or use the name specified in your .env file)

### 2. Backend Configuration

1. Navigate to the backend directory:
```bash
cd backend/fastapi
```

2. Create a virtual environment (recommended):
```bash
python -m venv venv
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure environment variables:
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env file and update if needed:
# - DB_HOST: Usually 127.0.0.1 for XAMPP
# - DB_PORT: Usually 3306 for XAMPP MySQL
# - DB_USER: Usually 'root' for XAMPP
# - DB_PASSWORD: Usually empty for default XAMPP installation
# - DB_NAME: The database name you created
# - SECRET_KEY: Generate a secure random key (important for production!)
```

### 3. Running the Backend

Start the FastAPI server with Uvicorn:

```bash
uvicorn app.main:app --reload --port 8000
```

The API will be available at: http://localhost:8000

- **API Documentation (Swagger UI)**: http://localhost:8000/docs
- **Alternative API Documentation (ReDoc)**: http://localhost:8000/redoc

## API Endpoints

### Authentication (`/auth`)

- `POST /auth/register` - Register a new user (optionally with referral code)
- `POST /auth/login` - Login and receive access/refresh tokens
- `POST /auth/refresh` - Refresh access token using refresh token
- `GET /auth/me` - Get current user information (requires authentication)

### Affiliates (`/affiliates`)

- `POST /affiliates/create` - Create an affiliate code for current user
- `GET /affiliates/{code}` - Get affiliate information by code
- `GET /affiliates/me/stats` - Get affiliate statistics for current user

### Wallet (`/wallet`)

- `GET /wallet` - Get current user's wallet balance
- `POST /wallet/deposit` - Deposit funds to wallet
- `POST /wallet/withdraw` - Withdraw funds from wallet
- `GET /wallet/transactions` - Get transaction history

## Testing the API

### 1. Register a new user:
```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

### 2. Login:
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=user@example.com&password=securepassword123"
```

### 3. Use the access token:
```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

### 4. Create an affiliate code:
```bash
curl -X POST "http://localhost:8000/affiliates/create" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

### 5. Check wallet balance:
```bash
curl -X GET "http://localhost:8000/wallet" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

## Database Schema

The application automatically creates the following tables on startup:

- **users**: User accounts with email, hashed password, and referral tracking
- **affiliates**: Affiliate codes linked to users
- **wallets**: One wallet per user with balance tracking
- **transactions**: Transaction history for deposits, withdrawals, and commissions

## Security Notes

- Always change the `SECRET_KEY` in production to a strong, random value
- Use HTTPS in production environments
- The default XAMPP MySQL has no password - set a strong password for production
- JWT tokens are used for stateless authentication
- Passwords are hashed using bcrypt

## Development Notes

- Tables are created automatically on startup using SQLAlchemy's `create_all()`
- No migrations are required for initial development
- The application uses synchronous SQLAlchemy with mysql-connector-python for simplicity
- For production, consider using async drivers and proper database migrations (e.g., Alembic)

## Troubleshooting

### Database Connection Issues
- Ensure MySQL is running in XAMPP
- Check that the database name in `.env` matches the database created in phpMyAdmin
- Verify database credentials in `.env` file

### Import Errors
- Make sure all dependencies are installed: `pip install -r requirements.txt`
- Ensure you're in the correct directory: `backend/fastapi`

### Port Already in Use
- Change the port: `uvicorn app.main:app --reload --port 8001`
- Or stop the process using port 8000

## Project Structure

```
backend/fastapi/
├── app/
│   ├── api/
│   │   ├── deps.py          # Authentication dependencies
│   │   └── routers/
│   │       ├── auth.py      # Authentication endpoints
│   │       ├── affiliates.py # Affiliate management endpoints
│   │       └── wallet.py     # Wallet management endpoints
│   ├── core/
│   │   └── config.py        # Configuration and settings
│   ├── db/
│   │   └── session.py       # Database session management
│   ├── models.py            # SQLAlchemy models
│   ├── schemas.py           # Pydantic schemas
│   ├── security.py          # Security utilities (JWT, password hashing)
│   ├── crud.py              # Database CRUD operations
│   └── main.py              # FastAPI application entry point
├── .env.example             # Example environment variables
├── requirements.txt         # Python dependencies
└── README.md               # This file
```
