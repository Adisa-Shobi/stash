-- 000004_enable_rls.down.sql

-- Drop all policies
DROP POLICY IF EXISTS users_select  ON users;
DROP POLICY IF EXISTS users_insert  ON users;
DROP POLICY IF EXISTS users_update  ON users;
DROP POLICY IF EXISTS users_delete  ON users;

DROP POLICY IF EXISTS oauth_select  ON user_oauth_connections;
DROP POLICY IF EXISTS oauth_insert  ON user_oauth_connections;
DROP POLICY IF EXISTS oauth_update  ON user_oauth_connections;
DROP POLICY IF EXISTS oauth_delete  ON user_oauth_connections;

DROP POLICY IF EXISTS sender_select ON sender_configurations;
DROP POLICY IF EXISTS sender_insert ON sender_configurations;
DROP POLICY IF EXISTS sender_update ON sender_configurations;
DROP POLICY IF EXISTS sender_delete ON sender_configurations;

DROP POLICY IF EXISTS txn_select    ON transactions;
DROP POLICY IF EXISTS txn_insert    ON transactions;
DROP POLICY IF EXISTS txn_update    ON transactions;
DROP POLICY IF EXISTS txn_delete    ON transactions;

-- Disable RLS
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_oauth_connections DISABLE ROW LEVEL SECURITY;
ALTER TABLE sender_configurations DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;

-- Revoke permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM stash_app;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM stash_app;
REVOKE USAGE ON SCHEMA public FROM stash_app;

-- Remove role membership and drop role
DO $$
BEGIN
    EXECUTE format('REVOKE stash_app FROM %I', CURRENT_USER);
EXCEPTION WHEN OTHERS THEN
    NULL;
END
$$;

DROP ROLE IF EXISTS stash_app;
