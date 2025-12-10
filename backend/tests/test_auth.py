"""
Tests for the authentication endpoints.
"""
import os
import pytest
from fastapi.testclient import TestClient

# Set test database before importing app
os.environ["DATABASE_URL"] = "sqlite:///./test_forex_ai.db"

from app.main import app, Base, engine

# Create test client
client = TestClient(app)


@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    """Setup test database once for all tests."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    # Clean up test database file
    if os.path.exists("test_forex_ai.db"):
        os.remove("test_forex_ai.db")


@pytest.fixture(autouse=True)
def clean_database():
    """Clean all tables before each test."""
    # Delete all records from all tables
    from sqlalchemy import delete
    from app.models.user import User
    with engine.begin() as conn:
        conn.execute(delete(User))
    yield


def test_register_success():
    """Test successful user registration."""
    response = client.post(
        "/auth/register",
        json={
            "email": "test@example.com",
            "name": "Test User",
            "password": "testpass123",
            "phone": "+1234567890"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert "token" in data
    assert "user" in data
    assert data["user"]["email"] == "test@example.com"
    assert data["user"]["name"] == "Test User"
    assert data["user"]["phone"] == "+1234567890"
    assert data["message"] == "User registered successfully"


def test_register_with_tel_field():
    """Test registration using 'tel' field instead of 'phone'."""
    response = client.post(
        "/auth/register",
        json={
            "email": "test2@example.com",
            "name": "Test User 2",
            "password": "testpass456",
            "tel": "+9876543210"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["user"]["phone"] == "+9876543210"


def test_register_duplicate_email():
    """Test registration with duplicate email."""
    # First registration
    client.post(
        "/auth/register",
        json={
            "email": "duplicate@example.com",
            "name": "User One",
            "password": "pass123",
            "phone": "+1111111111"
        }
    )
    
    # Second registration with same email
    response = client.post(
        "/auth/register",
        json={
            "email": "duplicate@example.com",
            "name": "User Two",
            "password": "pass456",
            "phone": "+2222222222"
        }
    )
    assert response.status_code == 400
    assert "Email already registered" in response.json()["detail"]


def test_register_duplicate_phone():
    """Test registration with duplicate phone number."""
    # First registration
    client.post(
        "/auth/register",
        json={
            "email": "user1@example.com",
            "name": "User One",
            "password": "pass123",
            "phone": "+3333333333"
        }
    )
    
    # Second registration with same phone
    response = client.post(
        "/auth/register",
        json={
            "email": "user2@example.com",
            "name": "User Two",
            "password": "pass456",
            "phone": "+3333333333"
        }
    )
    assert response.status_code == 400
    assert "Phone number already registered" in response.json()["detail"]


def test_register_missing_phone():
    """Test registration without phone or tel field."""
    response = client.post(
        "/auth/register",
        json={
            "email": "nophone@example.com",
            "name": "No Phone User",
            "password": "pass789"
        }
    )
    assert response.status_code == 422
    assert "Either phone or tel field must be provided" in str(response.json())


def test_register_invalid_email():
    """Test registration with invalid email."""
    response = client.post(
        "/auth/register",
        json={
            "email": "invalid-email",
            "name": "Invalid Email User",
            "password": "pass789",
            "phone": "+4444444444"
        }
    )
    assert response.status_code == 422


def test_register_short_password():
    """Test registration with password shorter than 6 characters."""
    response = client.post(
        "/auth/register",
        json={
            "email": "short@example.com",
            "name": "Short Password User",
            "password": "12345",
            "phone": "+5555555555"
        }
    )
    assert response.status_code == 422


def test_health_endpoint():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["app"] == "FOREX AI API"
    assert data["version"] == "1.0.0"


def test_root_endpoint():
    """Test root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data
