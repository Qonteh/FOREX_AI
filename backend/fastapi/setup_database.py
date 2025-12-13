"""
Automated database setup script for FOREX AI backend.
This script will create the database and tables if they don't exist.
"""
import pymysql
import sys
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import Session
import os

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

# Database configuration
MYSQL_USER = os.getenv('MYSQL_USER', 'root')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', '')  # Empty for passwordless
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', '3306'))
DB_NAME = 'forex_ai'


def create_database():
    """Create the forex_ai database if it doesn't exist."""
    print(f"🔍 Connecting to MySQL at {MYSQL_HOST}:{MYSQL_PORT}...")
    
    try:
        # Connect to MySQL server (without specifying database)
        connection = pymysql.connect(
            host=MYSQL_HOST,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            port=MYSQL_PORT,
            charset='utf8mb4'
        )
        
        print("✅ Connected to MySQL server")
        
        with connection.cursor() as cursor:
            # Check if database exists
            cursor.execute(f"SHOW DATABASES LIKE '{DB_NAME}'")
            result = cursor.fetchone()
            
            if result:
                print(f"✅ Database '{DB_NAME}' already exists")
            else:
                # Create database
                print(f"📝 Creating database '{DB_NAME}'...")
                cursor.execute(
                    f"CREATE DATABASE {DB_NAME} "
                    f"CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
                )
                connection.commit()
                print(f"✅ Database '{DB_NAME}' created successfully")
        
        connection.close()
        return True
        
    except pymysql.Error as e:
        print(f"❌ MySQL Error: {e}")
        print("\n💡 Troubleshooting:")
        print("   1. Make sure MySQL is running")
        print("   2. Check your MySQL credentials")
        if MYSQL_PASSWORD:
            print(f"   3. Current settings: {MYSQL_USER}:***@{MYSQL_HOST}:{MYSQL_PORT}")
        else:
            print(f"   3. Current settings: {MYSQL_USER}@{MYSQL_HOST}:{MYSQL_PORT} (no password)")
            print("   4. If you need a password, set MYSQL_PASSWORD environment variable")
        return False


def create_tables():
    """Create database tables using SQLAlchemy models."""
    print(f"\n📝 Creating tables in '{DB_NAME}' database...")
    
    # Build connection string
    if MYSQL_PASSWORD:
        db_url = f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{DB_NAME}"
    else:
        db_url = f"mysql+pymysql://{MYSQL_USER}@{MYSQL_HOST}:{MYSQL_PORT}/{DB_NAME}"
    
    try:
        # Create engine
        engine = create_engine(db_url)
        
        # Import ALL models
        from app.models import Base, User, Wallet, Referral, Transaction, Subscription
        
        # Check existing tables
        inspector = inspect(engine)
        existing_tables = inspector.get_table_names()
        
        # List of all tables we need to create
        required_tables = ['users', 'wallets', 'referrals', 'transactions', 'subscriptions']
        missing_tables = set(required_tables) - set(existing_tables)
        
        if missing_tables:
            print(f"📝 Creating {len(missing_tables)} missing table(s): {', '.join(missing_tables)}")
            Base.metadata.create_all(bind=engine)
            print(f"✅ All tables created successfully")
        else:
            print("✅ All required tables already exist")
        
        # Verify each table
        for table in required_tables:
            if table in inspector.get_table_names():
                columns = [col['name'] for col in inspector.get_columns(table)]
                print(f"✅ '{table}' table exists with {len(columns)} columns")
        
        # Verify table structure
        with Session(engine) as session:
            result = session.execute(text("DESCRIBE users"))
            rows = result.fetchall()
            print(f"\n📋 Table structure ({len(rows)} columns):")
            for row in rows:
                print(f"   • {row[0]:20s} {row[1]:20s} {row[2]:5s} {row[3]:5s}")
        
        engine.dispose()
        return True
        
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_connection():
    """Test database connection and basic operations."""
    print("\n🧪 Testing database connection...")
    
    # Build connection string
    if MYSQL_PASSWORD:
        db_url = f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{DB_NAME}"
    else:
        db_url = f"mysql+pymysql://{MYSQL_USER}@{MYSQL_HOST}:{MYSQL_PORT}/{DB_NAME}"
    
    try:
        engine = create_engine(db_url)
        
        with Session(engine) as session:
            # Test simple query
            result = session.execute(text("SELECT 1"))
            result.fetchone()
            print("✅ Database connection test passed")
            
            # Count users
            result = session.execute(text("SELECT COUNT(*) FROM users"))
            count = result.fetchone()[0]
            print(f"✅ Current user count: {count}")
        
        engine.dispose()
        return True
        
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
        return False


def main():
    """Main setup function."""
    print("=" * 60)
    print("🚀 FOREX AI Database Setup")
    print("=" * 60)
    print()
    
    # Step 1: Create database
    if not create_database():
        print("\n❌ Failed to create database. Please fix the issues above and try again.")
        sys.exit(1)
    
    # Step 2: Create tables
    if not create_tables():
        print("\n❌ Failed to create tables. Please fix the issues above and try again.")
        sys.exit(1)
    
    # Step 3: Test connection
    if not test_connection():
        print("\n❌ Connection test failed. Please check your database setup.")
        sys.exit(1)
    
    print("\n" + "=" * 60)
    print("✅ Database setup completed successfully!")
    print("=" * 60)
    print("\n📊 Database includes:")
    print("   • users (with email verification, referrals, subscriptions)")
    print("   • wallets (balance tracking)")
    print("   • referrals (30% commission tracking)")
    print("   • transactions (financial history)")
    print("   • subscriptions (plan management)")
    print("\n💡 Next steps:")
    print("   1. Start the server: uvicorn main:app --reload --port 8001")
    print("   2. Open API docs: http://localhost:8001/docs")
    print("   3. Test registration endpoint")
    print("   4. Check console for email verification link (dev mode)")
    print()


if __name__ == "__main__":
    main()
