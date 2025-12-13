-- Migration: Add phone column to users table (MySQL)
-- Database: forex_ai
-- Description: Safely adds phone column to existing users table with unique constraint

-- Step 1: Add phone column as nullable initially
SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.columns 
    WHERE table_schema = DATABASE()
    AND table_name = 'users' 
    AND column_name = 'phone'
);

SET @sql = IF(@column_exists = 0, 
    'ALTER TABLE users ADD COLUMN phone VARCHAR(32)',
    'SELECT "Phone column already exists, skipping addition" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 2: For existing users without phone, set a placeholder
-- In production, you may want to prompt users to update their phone numbers
UPDATE users 
SET phone = CONCAT('PLACEHOLDER_', id)
WHERE phone IS NULL OR phone = '';

-- Step 3: Add NOT NULL constraint
-- MySQL requires recreating the column with NOT NULL
SET @column_nullable = (
    SELECT IS_NULLABLE 
    FROM information_schema.columns 
    WHERE table_schema = DATABASE()
    AND table_name = 'users' 
    AND column_name = 'phone'
);

SET @sql = IF(@column_nullable = 'YES',
    'ALTER TABLE users MODIFY COLUMN phone VARCHAR(32) NOT NULL',
    'SELECT "Phone column already NOT NULL" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 4: Add unique constraint if not exists
SET @unique_exists = (
    SELECT COUNT(*) 
    FROM information_schema.table_constraints 
    WHERE table_schema = DATABASE()
    AND table_name = 'users' 
    AND constraint_name = 'phone'
    AND constraint_type = 'UNIQUE'
);

SET @sql = IF(@unique_exists = 0,
    'ALTER TABLE users ADD UNIQUE KEY phone (phone)',
    'SELECT "Unique constraint already exists on phone column" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 5: Create index on phone if not exists
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE()
    AND table_name = 'users' 
    AND index_name = 'idx_users_phone'
);

SET @sql = IF(@index_exists = 0,
    'CREATE INDEX idx_users_phone ON users(phone)',
    'SELECT "Index already exists on phone column" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verify migration
SELECT 
    'Migration Verification' AS step,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'phone') AS phone_column_exists,
    (SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema = DATABASE() AND table_name = 'users' AND constraint_name = 'phone' AND constraint_type = 'UNIQUE') AS phone_unique_constraint,
    (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'users' AND index_name = 'idx_users_phone') AS phone_index_exists;

SELECT '✅ Migration completed! Check the verification results above.' AS status;
