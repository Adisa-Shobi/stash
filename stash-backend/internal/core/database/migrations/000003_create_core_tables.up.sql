-- 000003_create_core_tables.up.sql
-- Core business tables. Created in dependency order.

-- ============================================================
-- Users
-- ============================================================
CREATE TABLE users (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email                    TEXT NOT NULL UNIQUE,
    auth_provider            TEXT NOT NULL DEFAULT 'supabase',
    auth_provider_id         TEXT NOT NULL,
    base_currency            TEXT NOT NULL DEFAULT 'USD',
    timezone                 TEXT NOT NULL DEFAULT 'UTC',
    date_format              TEXT NOT NULL DEFAULT 'yyyy-MM-dd',
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),

    notification_preferences JSONB NOT NULL DEFAULT '{
        "weekly_brief": true,
        "spending_alerts": true,
        "large_transaction_threshold": 100,
        "review_needed": false
    }'::jsonb,

    CONSTRAINT fk_users_base_currency
        FOREIGN KEY (base_currency) REFERENCES supported_currencies(code)
);

CREATE INDEX idx_users_auth_provider_id ON users (auth_provider, auth_provider_id);

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- User OAuth Connections (1NF: separate table, not embedded JSON)
-- ============================================================
CREATE TABLE user_oauth_connections (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider             TEXT NOT NULL,
    is_connected         BOOLEAN NOT NULL DEFAULT true,
    access_token_enc     BYTEA,
    refresh_token_enc    BYTEA,
    token_expires_at     TIMESTAMPTZ,
    push_subscription_id TEXT,
    last_sync            TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_user_provider UNIQUE (user_id, provider),
    CONSTRAINT fk_oauth_provider
        FOREIGN KEY (provider) REFERENCES email_providers(code)
);

CREATE INDEX idx_oauth_user_id ON user_oauth_connections (user_id);
CREATE INDEX idx_oauth_token_expiry ON user_oauth_connections (token_expires_at)
    WHERE is_connected = true;

CREATE TRIGGER trg_oauth_updated_at
    BEFORE UPDATE ON user_oauth_connections
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Parsing Templates (shared across users, no user_id)
-- ============================================================
CREATE TABLE parsing_templates (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name    TEXT NOT NULL,
    sender_email     TEXT NOT NULL,
    version          INTEGER NOT NULL,
    is_current       BOOLEAN NOT NULL DEFAULT true,
    category_default TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    parsing_rules    JSONB NOT NULL,

    CONSTRAINT uq_template_version UNIQUE (sender_email, version)
);

CREATE INDEX idx_template_current ON parsing_templates (sender_email)
    WHERE is_current = true;

-- ============================================================
-- Sender Configurations
-- ============================================================
CREATE TABLE sender_configurations (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_name    TEXT NOT NULL,
    email_pattern    TEXT NOT NULL,
    is_active        BOOLEAN NOT NULL DEFAULT true,
    template_id      UUID REFERENCES parsing_templates(id),
    template_version INTEGER,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_user_sender UNIQUE (user_id, email_pattern)
);

CREATE INDEX idx_sender_user_active ON sender_configurations (user_id)
    WHERE is_active = true;

CREATE TRIGGER trg_sender_updated_at
    BEFORE UPDATE ON sender_configurations
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Transactions (flattened — no nested JSON for queryable fields)
-- ============================================================
CREATE TABLE transactions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_configuration_id UUID NOT NULL REFERENCES sender_configurations(id),
    email_message_id        TEXT NOT NULL,

    -- Money: NUMERIC, never float
    amount                  NUMERIC(12, 2) NOT NULL,
    original_currency       TEXT NOT NULL,
    converted_amount        NUMERIC(12, 2),
    converted_currency      TEXT,
    exchange_rate           NUMERIC(15, 6),
    exchange_rate_source    TEXT,
    rate_timestamp          TIMESTAMPTZ,

    -- Merchant & category (denormalized snapshot at parse time)
    raw_merchant_name       TEXT,
    merchant_name           TEXT,
    description             TEXT,
    transaction_date        TIMESTAMPTZ NOT NULL,
    category                TEXT,
    subcategory             TEXT,
    payment_method          TEXT NOT NULL DEFAULT 'unknown',
    is_recurring            BOOLEAN NOT NULL DEFAULT false,

    -- Parsing metadata
    confidence_score        NUMERIC(3, 2) NOT NULL,
    parsing_method          TEXT NOT NULL,

    -- User review (flattened from nested JSON)
    review_status           TEXT NOT NULL DEFAULT 'pending',
    corrected_category      TEXT,
    corrected_amount        NUMERIC(12, 2),
    reviewed_at             TIMESTAMPTZ,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Deduplication at the database level
    CONSTRAINT uq_user_email_message UNIQUE (user_id, email_message_id),

    -- Mathematical invariants only (not evolving enums)
    CONSTRAINT chk_amount_positive   CHECK (amount >= 0),
    CONSTRAINT chk_confidence_range  CHECK (confidence_score >= 0 AND confidence_score <= 1),

    -- FK to reference tables
    CONSTRAINT fk_txn_original_currency
        FOREIGN KEY (original_currency) REFERENCES supported_currencies(code),
    CONSTRAINT fk_txn_converted_currency
        FOREIGN KEY (converted_currency) REFERENCES supported_currencies(code),
    CONSTRAINT fk_txn_parsing_method
        FOREIGN KEY (parsing_method) REFERENCES parsing_methods(code),
    CONSTRAINT fk_txn_payment_method
        FOREIGN KEY (payment_method) REFERENCES payment_methods(code),
    CONSTRAINT fk_txn_review_status
        FOREIGN KEY (review_status) REFERENCES review_statuses(code)
);

CREATE INDEX idx_txn_user_date     ON transactions (user_id, transaction_date DESC);
CREATE INDEX idx_txn_user_category ON transactions (user_id, category);
CREATE INDEX idx_txn_sender_config ON transactions (sender_configuration_id);

CREATE INDEX idx_txn_review_queue  ON transactions (user_id, confidence_score)
    WHERE review_status = 'pending';

CREATE TRIGGER trg_txn_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Merchant-Category Lookup (feedback loop core)
-- ============================================================
CREATE TABLE merchant_category_lookup (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_name_normalized TEXT NOT NULL UNIQUE,
    category                 TEXT NOT NULL,
    subcategory              TEXT,
    source                   TEXT NOT NULL,
    correction_count         INTEGER NOT NULL DEFAULT 0,
    confidence               NUMERIC(3, 2) NOT NULL DEFAULT 0.50,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_mcl_confidence_range  CHECK (confidence >= 0 AND confidence <= 1),
    CONSTRAINT chk_mcl_correction_count  CHECK (correction_count >= 0)
);

CREATE INDEX idx_merchant_lookup ON merchant_category_lookup (merchant_name_normalized);

CREATE TRIGGER trg_merchant_updated_at
    BEFORE UPDATE ON merchant_category_lookup
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Exchange Rates
-- ============================================================
CREATE TABLE exchange_rates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_currency TEXT NOT NULL,
    target_currency TEXT NOT NULL,
    rate            NUMERIC(15, 6) NOT NULL,
    source          TEXT NOT NULL,
    fetched_at      TIMESTAMPTZ NOT NULL,
    valid_until     TIMESTAMPTZ NOT NULL,

    CONSTRAINT uq_rate_pair_time UNIQUE (source_currency, target_currency, fetched_at),
    CONSTRAINT chk_rate_positive CHECK (rate > 0),

    CONSTRAINT fk_rate_source_currency
        FOREIGN KEY (source_currency) REFERENCES supported_currencies(code),
    CONSTRAINT fk_rate_target_currency
        FOREIGN KEY (target_currency) REFERENCES supported_currencies(code)
);

CREATE INDEX idx_rate_pair_valid ON exchange_rates (source_currency, target_currency, valid_until DESC);
