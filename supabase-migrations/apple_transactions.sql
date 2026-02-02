-- Apple transaction tracking table
-- Prevents duplicate credit grants for the same purchase

CREATE TABLE IF NOT EXISTS apple_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_transaction_id TEXT UNIQUE NOT NULL,
    product_id TEXT NOT NULL,
    user_email TEXT NOT NULL,
    credits_granted INTEGER NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT now(),

    CONSTRAINT valid_credits CHECK (credits_granted > 0)
);

-- Index for fast lookups by transaction ID
CREATE INDEX IF NOT EXISTS idx_apple_transactions_original_id
    ON apple_transactions(original_transaction_id);

-- Index for queries by user email
CREATE INDEX IF NOT EXISTS idx_apple_transactions_user_email
    ON apple_transactions(user_email);

-- Add comment for documentation
COMMENT ON TABLE apple_transactions IS 'Tracks verified Apple StoreKit 2 transactions to prevent duplicate credit grants';
COMMENT ON COLUMN apple_transactions.original_transaction_id IS 'Unique transaction ID from Apple - prevents duplicates';
COMMENT ON COLUMN apple_transactions.product_id IS 'StoreKit product ID (e.g., com.neatlify.Desktop.starter)';
COMMENT ON COLUMN apple_transactions.user_email IS 'User email for credit linkage to profiles table';
COMMENT ON COLUMN apple_transactions.credits_granted IS 'Number of credits granted for this transaction';
