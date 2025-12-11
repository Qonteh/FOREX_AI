# Database Setup Guide

This guide helps you set up the MySQL database for the FOREX AI backend.

## Quick Setup (Recommended)

The easiest way to set up your database is using the automated setup script:

```bash
cd backend/fastapi
python setup_database.py
```

This script will:
- ✅ Create the `forex_ai` database if it doesn't exist
- ✅ Create all necessary tables (`users` table with phone field)
- ✅ Verify the database structure
- ✅ Test the connection
- ✅ Show you a summary of what was done

## Manual Setup

If you prefer to set up the database manually:

### Step 1: Create the Database

```bash
mysql -u root
```

Then in the MySQL prompt:

```sql
CREATE DATABASE forex_ai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
exit;
```

### Step 2: Create Tables

Option A: Using the SQL script

```bash
mysql -u root forex_ai < db/init.sql
```

Option B: Let SQLAlchemy create tables (happens automatically on server startup)

```bash
uvicorn main:app --reload
```

## Configuration

### MySQL Without Password (Default)

If your MySQL root user has no password (common for local development):

```bash
# No .env file needed, uses default:
# mysql+pymysql://root@localhost:3306/forex_ai
```

### MySQL With Password

If your MySQL root user has a password, create a `.env` file:

```bash
cd backend/fastapi
cp .env.example .env
```

Then edit `.env`:

```env
DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@localhost:3306/forex_ai
SECRET_KEY=your-secret-key-here
```

### Custom MySQL Settings

You can customize MySQL connection settings using environment variables:

```env
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_HOST=localhost
MYSQL_PORT=3306
```

## Troubleshooting

### Error: "Table 'forex_ai.users' doesn't exist"

**Solution:** Run the setup script:

```bash
python setup_database.py
```

Or manually create tables:

```bash
mysql -u root forex_ai < db/init.sql
```

### Error: "Access denied for user 'root'@'localhost'"

**Solution:** Check your MySQL password.

If you have a password, create `.env` file:

```env
DATABASE_URL=mysql+pymysql://root:YOUR_ACTUAL_PASSWORD@localhost:3306/forex_ai
```

If you don't have a password, make sure `.env` doesn't have a password:

```env
DATABASE_URL=mysql+pymysql://root@localhost:3306/forex_ai
```

### Error: "Unknown database 'forex_ai'"

**Solution:** Create the database:

```bash
mysql -u root -e "CREATE DATABASE forex_ai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

Or run the setup script:

```bash
python setup_database.py
```

### Error: "Can't connect to MySQL server"

**Solution:** Make sure MySQL is running:

**Windows:**
- Check MySQL service in Services (services.msc)
- Or start from MySQL Workbench

**Linux/Mac:**
```bash
sudo service mysql start
# or
brew services start mysql
```

### Server Error 500 when registering

**Solution:** Check the server console for detailed error messages.

The registration endpoint now shows detailed logs:
- ✅ What it's checking
- ❌ What failed
- 💡 How to fix it

**Common causes:**
1. **Table doesn't exist** → Run `python setup_database.py`
2. **Can't connect to database** → Check MySQL is running
3. **Wrong password** → Check `.env` file
4. **Wrong database name** → Verify database exists

## Verification

After setup, verify everything is working:

```bash
# Start the server
uvicorn main:app --reload

# In another terminal, test the database
python -c "from app.database import engine; from sqlalchemy import text; \
with engine.connect() as conn: \
    result = conn.execute(text('SELECT COUNT(*) FROM users')); \
    print(f'Users table exists with {result.fetchone()[0]} users')"
```

Or open the API docs and try registering:
- http://localhost:8000/docs
- Go to POST /auth/register
- Click "Try it out"
- Fill in the form
- Click "Execute"

## Database Schema

The `users` table structure:

| Column | Type | Constraints |
|--------|------|-------------|
| id | VARCHAR(36) | PRIMARY KEY |
| email | VARCHAR(255) | UNIQUE, NOT NULL, INDEXED |
| **phone** | **VARCHAR(32)** | **UNIQUE, NOT NULL, INDEXED** |
| name | VARCHAR(255) | NOT NULL |
| hashed_password | VARCHAR(255) | NOT NULL |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| is_premium | BOOLEAN | NOT NULL, DEFAULT FALSE |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE CURRENT_TIMESTAMP |

## Migration

If you already have a `users` table without the phone column, run the migration:

```bash
mysql -u root forex_ai < db/migrations/001_add_phone_to_users.sql
```

This migration safely:
1. Adds phone column as nullable
2. Populates with placeholder values
3. Adds unique index
4. Makes column NOT NULL

## Next Steps

After successful setup:

1. ✅ Database is ready
2. ✅ Start the server: `uvicorn main:app --reload`
3. ✅ Open API docs: http://localhost:8000/docs
4. ✅ Test registration with phone number
5. ✅ Integrate with your Flutter app

## Support

If you continue to have issues:

1. Check the server console for detailed error messages
2. Run `python setup_database.py` to diagnose issues
3. Review this guide for solutions
4. Check that MySQL is running and accessible
