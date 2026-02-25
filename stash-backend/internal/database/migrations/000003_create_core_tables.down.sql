-- 000003_create_core_tables.down.sql
-- Drop in reverse dependency order.

DROP TABLE IF EXISTS exchange_rates;
DROP TABLE IF EXISTS merchant_category_lookup;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS sender_configurations;
DROP TABLE IF EXISTS parsing_templates;
DROP TABLE IF EXISTS user_oauth_connections;
DROP TABLE IF EXISTS users;
