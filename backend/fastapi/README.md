# FOREX AI - FastAPI Backend

A FastAPI backend for the FOREX AI application with authentication, affiliate system, and wallet management.

## Features

- **JWT Authentication**: Secure access and refresh token implementation
- **User Management**: Registration, login, and profile management
- **Affiliate System**: Referral codes, tracking, and statistics
- **Wallet Management**: Balance tracking, deposits, withdrawals, and transaction history
- **MySQL Database**: Compatible with XAMPP for local development

## Prerequisites

- Python 3.8+
- XAMPP with MySQL running
- MySQL database created

## Setup Instructions

### 1. Start XAMPP MySQL

1. Open XAMPP Control Panel
2. Start the MySQL service
3. Click "Admin" to open phpMyAdmin
4. Create a new database (e.g., `forex_ai`)

### 2. Environment Configuration

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` and update the values:
- `DB_HOST`: Usually `localhost` for XAMPP
- `DB_PORT`: Usually `3306` for MySQL
- `DB_USER`: Usually `root` for XAMPP
- `DB_PASSWORD`: Leave empty for default XAMPP, or set your password
- `DB_NAME`: The database name you created (e.g., `forex_ai`)
- `SECRET_KEY`: Generate a secure random string (min 32 characters)

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Run the Application

```bash
uvicorn app.main:app --reload --port 8000
```

The API will be available at `http://localhost:8000`

### 5. API Documentation

Once running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Authentication (`/auth`)
- `POST /auth/register` - Register a new user (optional referral_code)
- `POST /auth/login` - Login and get access + refresh tokens
- `POST /auth/refresh` - Get new access token using refresh token
- `GET /auth/me` - Get current user profile (requires authentication)

### Affiliates (`/affiliates`)
- `POST /affiliates/create` - Create affiliate code (requires authentication)
- `GET /affiliates/{code}` - Get affiliate details by code
- `GET /affiliates/my/stats` - Get affiliate statistics (requires authentication)

### Wallet (`/wallet`)
- `GET /wallet` - Get wallet balance (requires authentication)
- `POST /wallet/deposit` - Deposit funds (requires authentication)
- `POST /wallet/withdraw` - Withdraw funds (requires authentication)
- `GET /wallet/transactions` - List transaction history (requires authentication)

## Database Schema

Tables are created automatically on startup:
- `users` - User accounts
- `affiliates` - Affiliate/referral codes
- `wallets` - User wallet balances
- `transactions` - Wallet transaction history

## Development Notes

- Tables are created automatically using SQLAlchemy `metadata.create_all()` on startup
- Password hashing uses bcrypt via passlib
- JWT tokens use HS256 algorithm
- MySQL connector uses `mysql+mysqlconnector` driver for XAMPP compatibility

## Security

- Never commit your `.env` file
- Use a strong `SECRET_KEY` in production
- Change default XAMPP passwords in production
- Use HTTPS in production

## Troubleshooting

**Database Connection Error:**
- Ensure XAMPP MySQL is running
- Verify database exists in phpMyAdmin
- Check credentials in `.env` file

**Module Import Errors:**
- Ensure all dependencies are installed: `pip install -r requirements.txt`

**Port Already in Use:**
- Change the port: `uvicorn app.main:app --reload --port 8001`

## Testing with curl

**Register a user:**
```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123","username":"testuser"}'
```

**Login:**
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'
```

**Get user profile (with token):**
```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```
