-- 000002_create_reference_tables.up.sql
-- Reference tables for evolving enumerations.
-- Expanding the system (new currency, provider, payment method) is an INSERT, not a migration.

-- Supported currencies (ISO 4217)
CREATE TABLE supported_currencies (
    code           TEXT PRIMARY KEY,
    name           TEXT NOT NULL,
    symbol         TEXT NOT NULL,
    decimal_places SMALLINT NOT NULL,
    is_active      BOOLEAN NOT NULL DEFAULT true,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO supported_currencies (code, name, symbol, decimal_places) VALUES
    ('USD', 'US Dollar',          '$',   2),
    ('EUR', 'Euro',               '€',   2),
    ('GBP', 'British Pound',      '£',   2),
    ('JPY', 'Japanese Yen',       '¥',   0),
    ('RWF', 'Rwandan Franc',      'RWF', 0),
    ('KES', 'Kenyan Shilling',    'KSh', 2),
    ('NGN', 'Nigerian Naira',     '₦',   2),
    ('ZAR', 'South African Rand', 'R',   2),
    ('CAD', 'Canadian Dollar',    'C$',  2),
    ('AUD', 'Australian Dollar',  'A$',  2),
    ('CHF', 'Swiss Franc',        'CHF', 2),
    ('CNY', 'Chinese Yuan',       '¥',   2),
    ('INR', 'Indian Rupee',       '₹',   2),
    ('BRL', 'Brazilian Real',     'R$',  2);

-- Email providers
CREATE TABLE email_providers (
    code       TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO email_providers (code, name) VALUES
    ('gmail',   'Gmail'),
    ('outlook', 'Microsoft Outlook');

-- Parsing methods
CREATE TABLE parsing_methods (
    code       TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO parsing_methods (code, name) VALUES
    ('template',   'Template Parser'),
    ('llm',        'LLM Extractor'),
    ('rule_based', 'Rule-Based Fallback');

-- Payment methods
CREATE TABLE payment_methods (
    code       TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO payment_methods (code, name) VALUES
    ('credit',   'Credit Card'),
    ('debit',    'Debit Card'),
    ('transfer', 'Bank Transfer'),
    ('payment',  'Direct Payment'),
    ('unknown',  'Unknown');

-- Review statuses
CREATE TABLE review_statuses (
    code       TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO review_statuses (code, name) VALUES
    ('pending',   'Pending Review'),
    ('approved',  'Approved'),
    ('corrected', 'User Corrected'),
    ('rejected',  'Rejected');

-- Transaction categories
CREATE TABLE transaction_categories (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transaction_subcategories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES transaction_categories(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_subcategory UNIQUE (category_id, name)
);

CREATE INDEX idx_subcategory_category ON transaction_subcategories (category_id);

INSERT INTO transaction_categories (name) VALUES
    ('Food & Drink'),
    ('Transport'),
    ('Shopping'),
    ('Bills & Utilities'),
    ('Entertainment'),
    ('Health & Wellness'),
    ('Travel'),
    ('Income'),
    ('Groceries'),
    ('Subscriptions'),
    ('Housing & Rent'),
    ('Transfers & Payments');
