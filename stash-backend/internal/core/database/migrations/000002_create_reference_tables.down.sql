-- 000002_create_reference_tables.down.sql
-- Drop in reverse dependency order.

DROP TABLE IF EXISTS transaction_subcategories;
DROP TABLE IF EXISTS transaction_categories;
DROP TABLE IF EXISTS review_statuses;
DROP TABLE IF EXISTS payment_methods;
DROP TABLE IF EXISTS parsing_methods;
DROP TABLE IF EXISTS email_providers;
DROP TABLE IF EXISTS supported_currencies;
