-- Database initialization script for FOREX AI (MySQL)
-- Creates the database and users table with phone field

-- Create database (run as MySQL root user)
-- CREATE DATABASE forex_ai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE forex_ai;

-- Connect to forex_ai database before running the rest

-- Create users table with phone field
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_email (email),
    INDEX idx_users_phone (phone),
    INDEX idx_users_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note: MySQL automatically updates 'updated_at' with ON UPDATE CURRENT_TIMESTAMP
-- No need for triggers like in PostgreSQL

-- For PostgreSQL compatibility, you can also use this file:
-- See db/init_postgresql.sql for PostgreSQL-specific setup
