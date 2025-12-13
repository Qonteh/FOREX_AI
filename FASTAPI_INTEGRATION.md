# FastAPI Integration Guide

## Overview
Firebase has been completely removed from this project. The app now uses a FastAPI backend with MySQL database for all authentication and data storage.

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
└────────┬────────┘
         │
         │ HTTP/REST
         │
         ▼
┌─────────────────┐
│  FastAPI        │
│  (Backend)      │
│  Port: 8000     │
└────────┬────────┘
         │
         │ SQL
         │
         ▼
┌─────────────────┐
│  MySQL          │
│  Database       │
│  forex_ai       │
└─────────────────┘
```

## Quick Start

### 1. Setup Backend

```bash
# Navigate to backend directory
cd backend/fastapi

# Install Python dependencies
pip install -r requirements.txt

# Setup database (creates forex_ai database and users table)
python setup_database.py

# Start FastAPI server
uvicorn main:app --reload
```

The server will run at: http://localhost:8000
API docs: http://localhost:8000/docs

### 2. Setup Flutter App

```bash
# Get dependencies (removes Firebase, adds dio + shared_preferences)
flutter pub get

# Run app
flutter run
```

## API Endpoints

### Authentication

#### Register New User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123",
  "name": "John Doe",
  "phone": "+1234567890"
}

Response:
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890"
  }
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123"
}

Response:
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890"
  }
}
```

#### Get Current User
```http
GET /auth/me
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...

Response:
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1234567890"
}
```

## Flutter Code Structure

### ApiService
**Location**: `lib/services/api_service.dart`

Handles all HTTP requests to FastAPI backend:
- Base URL: `http://localhost:8000`
- Methods: `register()`, `login()`, `getCurrentUser()`, `logout()`
- Token management: Stored in SharedPreferences
- Auto-attaches JWT token to requests

### AuthProvider
**Location**: `lib/providers/auth_provider.dart`

Manages authentication state:
- `login(email, password)` - Authenticate user
- `signup(email, password, name, phoneNumber)` - Create new account
- `logout()` - Clear session
- `loadCurrentUser()` - Restore session on app start
- State: `isAuthenticated`, `user`, `error`, `isLoading`

### Screens
- **LoginScreen**: `lib/screens/auth/login_screen.dart`
- **SignupScreen**: `lib/screens/auth/signup_screen.dart`

Both screens use `Provider.of<AuthProvider>()` to access auth methods.

## Database Schema

### Users Table (MySQL)

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(32) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Key Features

### Phone Field Support
✅ **Backend**: Phone field in database with unique constraint
✅ **API**: Accepts both 'phone' and 'tel' field names (aliasing)
✅ **Frontend**: Phone input with country code picker
✅ **Validation**: 10-15 digits required

### Token-Based Authentication
- JWT tokens generated on login/signup
- Stored in SharedPreferences
- Auto-attached to API requests
- Tokens expire after 30 days (configurable in backend)

### Error Handling
- Network errors caught and displayed
- Validation errors from backend shown in UI
- Duplicate email/phone detected
- Invalid credentials handled gracefully

## Configuration

### Change Backend URL
Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:8000';
// Change to your server URL, e.g.:
// static const String baseUrl = 'https://api.yourapp.com';
```

### Database Configuration
Edit `backend/fastapi/.env`:
```env
DATABASE_URL=mysql+pymysql://root@localhost:3306/forex_ai
SECRET_KEY=your-secret-key-here
```

## Troubleshooting

### "Cannot connect to server"
- Ensure FastAPI is running: `uvicorn main:app --reload`
- Check baseUrl in ApiService matches your server
- For mobile/emulator, use computer's IP instead of localhost

### "Table doesn't exist"
- Run database setup: `python setup_database.py`
- Or manually: `mysql -u root forex_ai < db/init.sql`

### "Invalid credentials"
- Verify email/password are correct
- Check database has user: `mysql -u root -e "SELECT * FROM forex_ai.users;"`

### Token expired
- Login again to get new token
- Token validity: 30 days (configurable in backend/fastapi/app/api/routers/auth.py)

## Migration from Firebase

All Firebase code has been removed:
- ❌ Firebase Auth → ✅ FastAPI JWT Auth
- ❌ Firestore → ✅ MySQL Database
- ❌ Firebase packages → ✅ dio + shared_preferences

**Backup files created**:
- `lib/main_old_firebase_backup.dart`
- `lib/providers/auth_provider_old_firebase_backup.dart`

## Testing

### Test Backend
```bash
curl http://localhost:8000/docs
# Should open Swagger UI

curl http://localhost:8000/health
# Should return 200 OK
```

### Test Registration
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "name": "Test User",
    "phone": "+1234567890"
  }'
```

### Test Login
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }'
```

## Next Steps

1. ✅ Backend is ready with phone support
2. ✅ Flutter app connects to FastAPI
3. ✅ Authentication works end-to-end
4. 🎯 Add more API endpoints as needed
5. 🎯 Deploy backend to production server
6. 🎯 Update Flutter baseUrl for production

## Support

For issues or questions:
- Backend setup: See `backend/fastapi/README.md`
- Database setup: See `backend/fastapi/DATABASE_SETUP.md`
- Quick setup: See `backend/fastapi/QUICK_SETUP.md`

---

**Status**: ✅ Complete
**Last Updated**: December 10, 2025
**Firebase**: Removed
**Backend**: FastAPI + MySQL
**Frontend**: Flutter (Pure)
