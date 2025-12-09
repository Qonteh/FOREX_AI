"""
Main FastAPI application entry point.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db.session import engine, Base
from app.api.routers import auth, affiliates, wallet


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events.
    """
    # Startup: Create database tables
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")
    yield
    # Shutdown: cleanup if needed
    print("Shutting down...")


# Create FastAPI application instance
app = FastAPI(
    title="FOREX AI Backend",
    description="Backend API for FOREX AI with authentication, affiliates, and wallet management",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
# Note: In production, replace with specific origins for security
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include API routers
app.include_router(auth.router)
app.include_router(affiliates.router)
app.include_router(wallet.router)


@app.get("/")
def root():
    """Root endpoint."""
    return {
        "message": "FOREX AI Backend API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
