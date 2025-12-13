# FOREX AI Backend API

FastAPI backend for the FOREX AI trading application.

## Setup

### Prerequisites
- Python 3.8+
- MySQL database

### Installation

1. Create a virtual environment:
```bash
python -m venv .venv
```

2. Activate the virtual environment:
   - Windows: `.venv\Scripts\activate`
   - Linux/Mac: `source .venv/bin/activate`

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure environment variables:
   - Copy `.env.example` to `.env`
   - Update the `DATABASE_URL` with your MySQL credentials

5. Create the database:
```sql
CREATE DATABASE forex_ai;
```

## Running the Server

```bash
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8001
```

The API will be available at `http://127.0.0.1:8001`

API documentation is available at:
- Swagger UI: `http://127.0.0.1:8001/docs`
- ReDoc: `http://127.0.0.1:8001/redoc`

## API Endpoints

### Authentication
- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login and get access token
- `GET /auth/me` - Get current user information

### Health Check
- `GET /health` - Check API health status

## Features

- User registration with email and phone validation
- Password hashing with bcrypt (properly handles 72-byte limit)
- JWT token-based authentication
- Referral system
- MySQL database with SQLAlchemy ORM
- CORS enabled for frontend integration

## Security Notes

- Passwords are hashed using bcrypt with 12 rounds
- Passwords longer than 72 bytes are automatically truncated (bcrypt limitation)
- JWT tokens expire after 30 minutes
- Default database configuration warns about missing password
