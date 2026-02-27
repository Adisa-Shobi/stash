-- 000001_initial_setup.up.sql
-- Creates reusable trigger function for auto-updating updated_at columns.

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
