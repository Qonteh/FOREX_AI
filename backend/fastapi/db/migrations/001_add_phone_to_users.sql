-- Migration: Add phone column to users table
-- Database: forex_ai
-- Description: Safely adds phone column to existing users table with unique constraint

-- Step 1: Add phone column as nullable initially
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'phone'
    ) THEN
        ALTER TABLE users ADD COLUMN phone VARCHAR(32);
        RAISE NOTICE 'Phone column added to users table';
    ELSE
        RAISE NOTICE 'Phone column already exists, skipping addition';
    END IF;
END $$;

-- Step 2: For existing users without phone, set a placeholder
-- In production, you may want to prompt users to update their phone numbers
UPDATE users 
SET phone = 'PLACEHOLDER_' || id 
WHERE phone IS NULL;

-- Step 3: Add NOT NULL constraint if all rows have phone values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM users WHERE phone IS NULL
    ) THEN
        -- Make phone NOT NULL
        ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
        RAISE NOTICE 'Phone column set to NOT NULL';
    ELSE
        RAISE NOTICE 'Some users still have NULL phone values, skipping NOT NULL constraint';
    END IF;
END $$;

-- Step 4: Add unique constraint if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'users_phone_key' AND conrelid = 'users'::regclass
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_phone_key UNIQUE (phone);
        RAISE NOTICE 'Unique constraint added to phone column';
    ELSE
        RAISE NOTICE 'Unique constraint already exists on phone column';
    END IF;
END $$;

-- Step 5: Create index on phone if not exists
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- Verify migration
DO $$
DECLARE
    phone_column_exists BOOLEAN;
    phone_is_unique BOOLEAN;
    phone_index_exists BOOLEAN;
BEGIN
    -- Check if phone column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'phone'
    ) INTO phone_column_exists;
    
    -- Check if phone has unique constraint
    SELECT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'users_phone_key' AND conrelid = 'users'::regclass
    ) INTO phone_is_unique;
    
    -- Check if phone index exists
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'users' AND indexname = 'idx_users_phone'
    ) INTO phone_index_exists;
    
    -- Report results
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration Verification Results:';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Phone column exists: %', phone_column_exists;
    RAISE NOTICE 'Phone unique constraint: %', phone_is_unique;
    RAISE NOTICE 'Phone index exists: %', phone_index_exists;
    RAISE NOTICE '========================================';
    
    IF phone_column_exists AND phone_is_unique AND phone_index_exists THEN
        RAISE NOTICE '✅ Migration completed successfully!';
    ELSE
        RAISE WARNING '⚠️ Migration may be incomplete. Please review the results above.';
    END IF;
END $$;
