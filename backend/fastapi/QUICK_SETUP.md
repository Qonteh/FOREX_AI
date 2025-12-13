# Quick Setup Guide for MySQL

## Step 1: Create .env file

Copy the example file:
```bash
cp .env.example .env
```

## Step 2: Update .env with YOUR MySQL configuration

Edit `.env` and set your MySQL connection:

### If you have a MySQL password:
```env
DATABASE_URL=mysql+pymysql://root:YOUR_MYSQL_PASSWORD@localhost:3306/forex_ai
SECRET_KEY=your-super-secret-jwt-key-change-this
```

### If you DON'T have a MySQL password (no password):
```env
DATABASE_URL=mysql+pymysql://root@localhost:3306/forex_ai
SECRET_KEY=your-super-secret-jwt-key-change-this
```

**Note:** Just remove the `:password` part from the URL if you don't use a password!

## Step 3: Create the database

Open MySQL and create the database:

### If you have a password:
```bash
mysql -u root -p
```

### If you DON'T have a password:
```bash
mysql -u root
```

Then run:
```sql
CREATE DATABASE forex_ai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
exit;
```

## Step 4: Initialize the database schema

### If you have a password:
```bash
mysql -u root -p forex_ai < db/init.sql
```

### If you DON'T have a password:
```bash
mysql -u root forex_ai < db/init.sql
```

## Step 5: Run the server

```bash
uvicorn main:app --reload
```

## Common Issues

### "Access denied for user 'root'@'localhost'"
- Your MySQL password in .env is wrong
- If you don't have a password, use: `DATABASE_URL=mysql+pymysql://root@localhost:3306/forex_ai`
- If you have a password, use: `DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@localhost:3306/forex_ai`

### "Unknown database 'forex_ai'"
- Run: `CREATE DATABASE forex_ai;` in MySQL

### "Can't connect to MySQL server"
- Make sure MySQL is running
- Check if it's running on port 3306

## Test Your Setup

Visit http://127.0.0.1:8000/docs to see the API documentation.

If you see the API docs, everything is working! ✅
