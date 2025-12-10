"""
FastAPI main application for FOREX AI backend.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routers import auth
from app.database import init_db
import os

app = FastAPI(
    title="FOREX AI API",
    description="Backend API for FOREX AI Trading Application",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)


@app.on_event("startup")
async def startup_event():
    """Initialize database on startup."""
    print("🚀 Starting FOREX AI API...")
    
    # Get database URL (default: MySQL without password for local dev)
    db_url = os.getenv('DATABASE_URL', 'mysql+pymysql://root@localhost:3306/forex_ai')
    
    # Mask password in log for security (if password exists)
    if '@' in db_url and '://' in db_url:
        parts = db_url.split('://', 1)
        if '@' in parts[1]:
            user_pass, host_db = parts[1].split('@', 1)
            if ':' in user_pass:
                user, _ = user_pass.split(':', 1)
                masked_url = f"{parts[0]}://{user}:****@{host_db}"
            else:
                masked_url = db_url
        else:
            masked_url = db_url
    else:
        masked_url = db_url
    
    print(f"📊 Database URL: {masked_url}")
    
    # Check if using default credentials
    if 'DATABASE_URL' not in os.environ:
        print("⚠️  WARNING: Using default DATABASE_URL")
        print("⚠️  Default: MySQL without password (root@localhost:3306)")
        print("⚠️  If you need a password, create .env file with:")
        print("⚠️  DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@localhost:3306/forex_ai")
    
    # Initialize database tables
    try:
        init_db()
        print("✅ Database initialized successfully")
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")
        print("\n📝 Troubleshooting:")
        print("   1. Make sure MySQL is running")
        print("   2. Create the database: CREATE DATABASE forex_ai;")
        print("   3. Check your DATABASE_URL in .env file")
        print("   4. Verify MySQL credentials (username/password)")
        print("   5. If no password: DATABASE_URL=mysql+pymysql://root@localhost:3306/forex_ai")
        print("   6. If with password: DATABASE_URL=mysql+pymysql://root:PASSWORD@localhost:3306/forex_ai")
        print("   3. Check your DATABASE_URL in .env file")
        print("   4. Verify MySQL credentials (username/password)")
        print("   5. Example: DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@localhost:3306/forex_ai")


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "FOREX AI API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "forex-ai-api"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
