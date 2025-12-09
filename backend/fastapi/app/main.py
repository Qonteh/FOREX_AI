"""
FastAPI main application.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.db.session import Base, engine
from app.api.routers import auth, affiliates, wallet


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events.
    Creates database tables if they don't exist on startup.
    """
    # Startup
    print("Starting FOREX AI Backend API...")
    try:
        print(f"Database URL: {settings.database_url.split('@')[1]}")  # Print without credentials
        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully!")
    except Exception as e:
        print(f"Warning: Could not create database tables: {e}")
        print("Make sure MySQL is running and database exists before using the API.")
    
    yield
    
    # Shutdown (cleanup if needed)
    print("Shutting down FOREX AI Backend API...")


# Create FastAPI application
app = FastAPI(
    title="FOREX AI Backend API",
    description="Backend API for FOREX AI application with authentication, affiliates, and wallet management",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(affiliates.router)
app.include_router(wallet.router)


@app.get("/")
def root():
    """Root endpoint - API health check."""
    return {
        "message": "FOREX AI Backend API",
        "status": "running",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
