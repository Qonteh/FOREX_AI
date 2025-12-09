"""
Main FastAPI application entry point.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db.session import engine, Base
from app.api.routers import auth, affiliates, wallet

# Create FastAPI application instance
app = FastAPI(
    title="FOREX AI Backend",
    description="Backend API for FOREX AI with authentication, affiliates, and wallet management",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    """
    Startup event handler.
    Creates database tables if they don't exist.
    """
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")


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
