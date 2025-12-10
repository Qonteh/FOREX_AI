# FOREX AI Backend API

Backend API for FOREX AI Trading Application built with FastAPI.

## Features

- User registration with email and phone validation
- JWT authentication
- SQLite database (can be easily switched to PostgreSQL/MySQL)
- OpenAPI/Swagger documentation
- CORS support

## Setup

### Prerequisites

- Python 3.8 or higher
- pip

### Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Create a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

### Running the Server

#### Using the run script (Linux/Mac):
```bash
./run.sh
```

#### Manual start:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- API: http://localhost:8000
- Interactive API docs (Swagger UI): http://localhost:8000/docs
- Alternative API docs (ReDoc): http://localhost:8000/redoc
- OpenAPI JSON: http://localhost:8000/openapi.json

## API Endpoints

### Authentication

#### POST /auth/register
Register a new user.

**Request Body:**
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "password": "securepass123",
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "is_active": true,
    "created_at": "2025-12-10T01:00:00"
  },
  "message": "User registered successfully"
}
```

### Health Check

#### GET /health
Check API health status.

**Response:**
```json
{
  "status": "healthy",
  "app": "FOREX AI API",
  "version": "1.0.0"
}
```

## Configuration

Configuration can be set via environment variables or a `.env` file:

```env
# App Settings
APP_NAME=FOREX AI API
VERSION=1.0.0
DEBUG=True

# Security
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Database
DATABASE_URL=sqlite:///./forex_ai.db
```

## Database

The application uses SQLite by default. The database file (`forex_ai.db`) will be created automatically on first run.

To use PostgreSQL or MySQL, update the `DATABASE_URL` in the configuration:

**PostgreSQL:**
```env
DATABASE_URL=postgresql://user:password@localhost/dbname
```

**MySQL:**
```env
DATABASE_URL=mysql://user:password@localhost/dbname
```

## Development

The API automatically creates database tables on startup. No migrations are needed for development.

## Security Notes

1. Change the `SECRET_KEY` in production
2. Update CORS settings to allow only specific origins
3. Use HTTPS in production
4. Consider rate limiting for authentication endpoints
