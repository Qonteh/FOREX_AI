from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.db.session import engine, Base
from app.api.routers import auth, affiliates, wallet

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI application
app = FastAPI(
    title=settings.PROJECT_NAME,
    debug=settings.DEBUG,
    description="FastAPI backend for FOREX AI with authentication, affiliates, and wallet features",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(affiliates.router, prefix="/affiliates", tags=["Affiliates"])
app.include_router(wallet.router, prefix="/wallet", tags=["Wallet"])


@app.get("/", tags=["Root"])
def root():
    """Root endpoint - health check."""
    return {
        "message": "FOREX AI Backend API",
        "version": "1.0.0",
        "status": "online"
    }


@app.get("/health", tags=["Health"])
def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
