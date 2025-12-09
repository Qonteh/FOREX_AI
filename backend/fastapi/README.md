# FOREX AI Backend API

FastAPI backend for FOREX AI Trading Application with user authentication and phone number support.

## Features

- **User Authentication**: Register and login with email, password, and phone number
- **Phone Field Support**: Accepts both `phone` and `tel` field names for frontend compatibility
- **JWT Authentication**: Secure token-based authentication
- **Database Migrations**: Safe SQL migrations for adding phone field to existing installations
- **Input Validation**: Email and phone number validation with helpful error messages
- **Unique Constraints**: Ensures email and phone uniqueness across users

## Requirements

- Python 3.9+
- PostgreSQL 12+
- pip or poetry for package management

## Installation

### 1. Install Dependencies

#### Linux/macOS

```bash
cd backend/fastapi
pip install -r requirements.txt
```

#### Windows

On Windows, you may need to upgrade pip first to ensure pre-built wheels are used:

```bash
cd backend\fastapi
python -m pip install --upgrade pip
pip install -r requirements.txt
```

**Troubleshooting on Windows:**

If you encounter a `pg_config executable not found` error with `psycopg2-binary`:

1. **Upgrade pip**: Make sure you have the latest pip version:
   ```bash
   python -m pip install --upgrade pip
   ```

2. **Install wheel package**: Ensure wheel is installed:
   ```bash
   pip install wheel
   ```

3. **Use Python 3.9-3.12**: psycopg2-binary 2.9.11 has pre-built wheels for Python 3.9-3.12. Check your version:
   ```bash
   python --version
   ```

4. **Alternative**: If issues persist, you can use `psycopg` (version 3) instead:
   ```bash
   # Edit requirements.txt and replace psycopg2-binary with:
   psycopg[binary]==3.1.19
   ```
   Then update `backend/fastapi/app/database.py` to use `postgresql+psycopg` instead of `postgresql` in DATABASE_URL.

### 2. Database Setup

#### Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE forex_ai;

# Exit psql
\q
```

#### Initialize Database Schema

For a fresh installation:

```bash
psql -U postgres -d forex_ai -f db/init.sql
```

#### Or Run Migration (for existing installations)

If you already have a users table without the phone field:

```bash
psql -U postgres -d forex_ai -f db/migrations/001_add_phone_to_users.sql
```

### 3. Configure Environment Variables

Create a `.env` file in the `backend/fastapi` directory:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/forex_ai
SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
```

**Security Note**: Always use a strong, randomly generated `SECRET_KEY` in production!

### 4. Run the Server

```bash
# Development mode with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Or using Python
python main.py
```

The API will be available at:
- API: http://localhost:8000
- Interactive Docs: http://localhost:8000/docs
- Alternative Docs: http://localhost:8000/redoc

## API Endpoints

### Authentication

#### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1234567890",
  "password": "securepass123"
}
```

**Note**: The API accepts both `phone` and `tel` field names:
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
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "is_active": true,
    "is_premium": false,
    "created_at": "2023-01-01T00:00:00",
    "updated_at": "2023-01-01T00:00:00"
  }
}
```

**Error Responses**:
- 400: Email already registered
- 400: Phone number already registered
- 422: Validation error (invalid email or phone format)

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123"
}
```

**Response** (200 OK):
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": { ... }
}
```

#### Get Current User
```http
GET /auth/me?token=your_jwt_token
```

### Health Check

```http
GET /health
```

Returns service health status.

## Database Schema

### Users Table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(36) | PRIMARY KEY | UUID user identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL, INDEXED | User email address |
| phone | VARCHAR(32) | UNIQUE, NOT NULL, INDEXED | User phone number |
| name | VARCHAR(255) | NOT NULL | User full name |
| hashed_password | VARCHAR(255) | NOT NULL | Bcrypt hashed password |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Account active status |
| is_premium | BOOLEAN | NOT NULL, DEFAULT FALSE | Premium subscription status |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Account creation time |
| updated_at | TIMESTAMP | NOT NULL, AUTO-UPDATE | Last update time |

## Phone Field Migration

If you have an existing installation without the phone field, follow these steps:

### Step 1: Backup Your Database

```bash
pg_dump -U postgres forex_ai > backup_before_migration.sql
```

### Step 2: Run Migration

```bash
psql -U postgres -d forex_ai -f db/migrations/001_add_phone_to_users.sql
```

### Step 3: Verify Migration

The migration script will output verification results. Look for:
```
✅ Migration completed successfully!
```

### Step 4: Update Existing Users

For existing users, the migration sets placeholder phone numbers. You should:
1. Prompt users to update their phone numbers on next login
2. Or manually update phone numbers in the database:

```sql
UPDATE users SET phone = '+1234567890' WHERE email = 'user@example.com';
```

## Validation Rules

### Email
- Must be a valid email format
- Must be unique across all users

### Phone
- Must contain at least 10 digits
- Cannot exceed 15 digits (including country code)
- Must be unique across all users
- Accepts international formats (e.g., +1234567890)

### Password
- Minimum 6 characters
- No maximum length enforced

### Name
- Minimum 2 characters
- Maximum 255 characters

## Security Considerations

1. **Passwords**: Hashed using bcrypt with automatic salt generation
2. **JWT Tokens**: Expire after 7 days (configurable)
3. **CORS**: Configure `allow_origins` in production to specific domains
4. **Database Credentials**: Store in environment variables, never commit to version control
5. **Secret Key**: Use a strong, randomly generated key in production

## Development

### Project Structure

```
backend/fastapi/
├── app/
│   ├── api/
│   │   └── routers/
│   │       └── auth.py       # Authentication routes
│   ├── models.py              # SQLAlchemy models
│   ├── schemas.py             # Pydantic schemas
│   ├── crud.py                # Database operations
│   └── database.py            # Database connection
├── db/
│   ├── init.sql               # Database initialization
│   └── migrations/
│       └── 001_add_phone_to_users.sql  # Phone field migration
├── main.py                    # FastAPI application
├── requirements.txt           # Python dependencies
└── README.md                  # This file
```

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest
```

### Code Quality

```bash
# Format code
black app/ main.py

# Lint code
flake8 app/ main.py

# Type checking
mypy app/ main.py
```

## Troubleshooting

### Database Connection Issues

**Error**: `could not connect to server`

**Solution**: Verify PostgreSQL is running and connection details are correct:
```bash
psql -U postgres -d forex_ai -c "SELECT 1"
```

### Migration Fails

**Error**: `column "phone" already exists`

**Solution**: The phone column already exists. Skip migration or modify migration script.

### Import Errors

**Error**: `ModuleNotFoundError: No module named 'app'`

**Solution**: Run from the `backend/fastapi` directory or add it to PYTHONPATH:
```bash
export PYTHONPATH="${PYTHONPATH}:/path/to/backend/fastapi"
```

## Production Deployment

1. **Use a production WSGI server**: gunicorn or uvicorn workers
2. **Set environment variables**: Use secrets management
3. **Configure CORS**: Restrict to your frontend domains
4. **Enable HTTPS**: Use reverse proxy (nginx) with SSL
5. **Database**: Use connection pooling and read replicas
6. **Monitoring**: Add logging and error tracking (Sentry, etc.)
7. **Backups**: Automated database backups

Example production command:
```bash
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## License

Copyright © 2024 FOREX AI. All rights reserved.
