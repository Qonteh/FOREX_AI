# Phone Field Integration Guide

This document describes the comprehensive changes made to add phone field support to the FOREX AI signup flow.

## Overview

The implementation adds phone number support across the entire application stack:
- **Backend API**: FastAPI with PostgreSQL
- **Frontend**: Flutter mobile app with Firebase Authentication
- **Database**: PostgreSQL with phone field and unique constraints
- **Compatibility**: Accepts both `phone` and `tel` field names

## Changes Summary

### 1. Backend API (FastAPI)

#### New Directory Structure
```
backend/fastapi/
├── app/
│   ├── __init__.py
│   ├── models.py           # User model with phone field
│   ├── schemas.py          # Pydantic schemas (phone/tel alias)
│   ├── crud.py             # CRUD operations with phone
│   ├── database.py         # Database connection
│   └── api/
│       └── routers/
│           └── auth.py     # Auth endpoints with phone validation
├── db/
│   ├── init.sql            # Database initialization
│   └── migrations/
│       └── 001_add_phone_to_users.sql
├── main.py                 # FastAPI app entry point
├── requirements.txt        # Python dependencies
├── .env.example           # Environment configuration template
└── README.md              # Backend documentation
```

#### Key Features

**User Model (models.py)**
- Phone field: `VARCHAR(32)`, unique, indexed, NOT NULL
- Supports international phone formats
- UUID-based user IDs

**Schemas (schemas.py)**
- `UserCreate`: Accepts both `phone` and `tel` for frontend compatibility
- Phone validation: 10-15 digits required
- Email validation with proper format checking
- Password minimum 6 characters

**CRUD Operations (crud.py)**
- `get_user_by_phone()`: Lookup users by phone number
- `get_user_by_email()`: Lookup users by email
- `get_user_by_email_or_phone()`: Check uniqueness
- `create_user()`: Create user with hashed password
- Password hashing with bcrypt

**Auth Router (auth.py)**
- `POST /auth/register`: Register with email, phone, name, password
  - Validates email uniqueness
  - Validates phone uniqueness
  - Returns JWT token + user data
  - Helpful error messages
- `POST /auth/login`: Login with email and password
- `GET /auth/me`: Get current user info

### 2. Frontend (Flutter)

#### Updated Files

**lib/providers/auth_provider.dart**
- Added `signup()` method accepting phone parameter
- Stores phone in Firebase Firestore user document
- Added `logout()` and `clearError()` methods
- Proper error handling and loading states

**lib/screens/auth/signup_screen.dart** (Already existed)
- Phone input field with country code picker
- Full phone number with country code passed to signup
- Input validation (10+ digits)
- Integration with auth provider

**lib/models/user.dart** (Already existed)
- Already includes `phoneNumber` field
- Proper JSON serialization

### 3. Database

#### Schema (init.sql)
```sql
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
```

#### Migration (001_add_phone_to_users.sql)
Safe migration script for existing installations:
1. Adds phone column as nullable
2. Populates with placeholder values for existing users
3. Adds unique constraint
4. Sets NOT NULL constraint
5. Creates index

## API Usage

### Register New User

**Endpoint**: `POST /auth/register`

**Request with 'phone'**:
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1234567890",
  "password": "securepass123"
}
```

**Request with 'tel' (alias)**:
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "tel": "+1234567890",
  "password": "securepass123"
}
```

**Response** (201 Created):
```json
{
  "access_token": "eyJ0eXAiOiJKV1Qi...",
  "token_type": "bearer",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "is_active": true,
    "is_premium": false,
    "created_at": "2023-12-09T23:00:00",
    "updated_at": "2023-12-09T23:00:00"
  }
}
```

**Error Responses**:
- `400 Bad Request`: Email already registered
- `400 Bad Request`: Phone number already registered
- `422 Unprocessable Entity`: Invalid email/phone format

## Setup Instructions

### Backend Setup

1. **Install Dependencies**:
```bash
cd backend/fastapi
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

2. **Configure Environment**:
```bash
cp .env.example .env
# Edit .env with your database credentials and secret key
```

3. **Setup Database**:
```bash
# Create database
psql -U postgres -c "CREATE DATABASE forex_ai;"

# Initialize schema (fresh installation)
psql -U postgres -d forex_ai -f db/init.sql

# OR run migration (existing installation)
psql -U postgres -d forex_ai -f db/migrations/001_add_phone_to_users.sql
```

4. **Run Server**:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

5. **Access API Docs**:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Frontend Setup

The Flutter app is already configured with phone support:

1. **Verify Dependencies**:
```bash
flutter pub get
```

2. **Run App**:
```bash
flutter run
```

The signup screen already includes:
- Phone number input with country code picker
- Phone validation
- Integration with Firebase and backend API

## Testing

### Backend Testing

**Test Schema Validation**:
```bash
cd backend/fastapi
source venv/bin/activate
python3 << 'EOF'
from app.schemas import UserCreate

# Test with 'phone'
user1 = UserCreate(
    email="test@example.com",
    name="Test User",
    phone="+1234567890",
    password="password123"
)
print("✅ Phone field:", user1.phone)

# Test with 'tel' alias
user2 = UserCreate.model_validate({
    "email": "test2@example.com",
    "name": "Test User 2",
    "tel": "+9876543210",
    "password": "password456"
})
print("✅ Tel alias:", user2.phone)
EOF
```

**Test API Endpoints**:
```bash
# Register user
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "phone": "+1234567890",
    "password": "password123"
  }'

# Test with 'tel' alias
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test2@example.com",
    "name": "Test User 2",
    "tel": "+9876543210",
    "password": "password456"
  }'
```

### Frontend Testing

1. Run the Flutter app
2. Navigate to signup screen
3. Fill in all fields including phone number
4. Submit the form
5. Verify account creation in Firebase and backend

## Validation Rules

### Email
- Must be valid email format
- Must be unique across all users
- Case-insensitive

### Phone
- Must contain 10-15 digits (excluding formatting)
- Must be unique across all users
- Supports international formats with country codes
- Examples: +1234567890, +44 1234 567890, etc.

### Password
- Minimum 6 characters
- Must contain at least one letter and one number (frontend validation)

### Name
- Minimum 2 characters
- Maximum 255 characters

## Security Considerations

1. **Password Storage**: Bcrypt hashing with automatic salt
2. **JWT Tokens**: 7-day expiration (configurable)
3. **CORS**: Configure allowed origins in production
4. **SQL Injection**: Protected by SQLAlchemy ORM
5. **Input Validation**: Pydantic schema validation
6. **Unique Constraints**: Database-level enforcement

## Troubleshooting

### Backend Issues

**Import Errors**:
- Ensure virtual environment is activated
- Verify all dependencies are installed: `pip install -r requirements.txt`

**Database Connection Errors**:
- Check DATABASE_URL in .env
- Verify PostgreSQL is running
- Ensure database 'forex_ai' exists

**Migration Errors**:
- Check if phone column already exists
- Review migration output for specific errors
- Backup database before running migrations

### Frontend Issues

**Phone Not Saving**:
- Check Firebase Firestore rules
- Verify auth_provider.signup() is called with phoneNumber parameter
- Check console logs for errors

**Validation Errors**:
- Ensure phone number has at least 10 digits
- Check that country code is included
- Verify all required fields are filled

## Future Enhancements

Potential improvements for consideration:

1. **Phone Verification**: SMS OTP verification
2. **Phone Format**: Normalize phone storage format
3. **Country Detection**: Auto-detect user's country
4. **Multi-Factor Auth**: Phone-based 2FA
5. **Phone Update**: Allow users to change phone number
6. **Admin Panel**: Manage users and phone numbers
7. **Rate Limiting**: Prevent abuse of registration endpoint
8. **Audit Logs**: Track phone number changes

## Support

For issues or questions:
1. Check backend logs: `journalctl -u forex-ai-api -f`
2. Check Flutter console for errors
3. Review API documentation at `/docs`
4. Verify database schema matches init.sql

## License

Copyright © 2024 FOREX AI. All rights reserved.
