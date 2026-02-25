-- 000004_enable_rls.up.sql
-- Row-Level Security for user data isolation.
--
-- Pattern:
--   The connection pool connects as the DB owner (used for migrations, health checks).
--   Per-request, the application does:
--     BEGIN;
--     SET LOCAL ROLE stash_app;
--     SET LOCAL app.current_user_id = '<uuid>';
--     -- all queries are now subject to RLS
--     COMMIT;  -- role and settings revert automatically

-- Create application role (non-superuser, subject to RLS)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'stash_app') THEN
        CREATE ROLE stash_app NOLOGIN;
    END IF;
END
$$;

-- Grant the app role to the current (migration) user so SET ROLE works
DO $$
BEGIN
    EXECUTE format('GRANT stash_app TO %I', CURRENT_USER);
END
$$;

-- Schema and table permissions for stash_app
GRANT USAGE ON SCHEMA public TO stash_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON
    users,
    user_oauth_connections,
    sender_configurations,
    parsing_templates,
    transactions,
    merchant_category_lookup,
    exchange_rates
TO stash_app;

-- Reference tables: read-only for the app role
GRANT SELECT ON
    supported_currencies,
    email_providers,
    parsing_methods,
    payment_methods,
    review_statuses,
    transaction_categories,
    transaction_subcategories
TO stash_app;

-- Future tables created by the migration user inherit these grants
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO stash_app;

-- ============================================================
-- Enable RLS on user-scoped tables
-- ============================================================
-- (Shared tables like parsing_templates, merchant_category_lookup,
--  exchange_rates, and all reference tables do NOT use RLS.)

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_oauth_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE sender_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Policies: users
-- ============================================================
CREATE POLICY users_select ON users
    FOR SELECT TO stash_app
    USING (id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY users_insert ON users
    FOR INSERT TO stash_app
    WITH CHECK (id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY users_update ON users
    FOR UPDATE TO stash_app
    USING (id = current_setting('app.current_user_id', true)::uuid)
    WITH CHECK (id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY users_delete ON users
    FOR DELETE TO stash_app
    USING (id = current_setting('app.current_user_id', true)::uuid);

-- ============================================================
-- Policies: user_oauth_connections
-- ============================================================
CREATE POLICY oauth_select ON user_oauth_connections
    FOR SELECT TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY oauth_insert ON user_oauth_connections
    FOR INSERT TO stash_app
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY oauth_update ON user_oauth_connections
    FOR UPDATE TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid)
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY oauth_delete ON user_oauth_connections
    FOR DELETE TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

-- ============================================================
-- Policies: sender_configurations
-- ============================================================
CREATE POLICY sender_select ON sender_configurations
    FOR SELECT TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY sender_insert ON sender_configurations
    FOR INSERT TO stash_app
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY sender_update ON sender_configurations
    FOR UPDATE TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid)
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY sender_delete ON sender_configurations
    FOR DELETE TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

-- ============================================================
-- Policies: transactions
-- ============================================================
CREATE POLICY txn_select ON transactions
    FOR SELECT TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY txn_insert ON transactions
    FOR INSERT TO stash_app
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY txn_update ON transactions
    FOR UPDATE TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid)
    WITH CHECK (user_id = current_setting('app.current_user_id', true)::uuid);

CREATE POLICY txn_delete ON transactions
    FOR DELETE TO stash_app
    USING (user_id = current_setting('app.current_user_id', true)::uuid);
