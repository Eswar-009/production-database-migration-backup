-- V002: Audit logging

BEGIN;

CREATE TABLE IF NOT EXISTS order_audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT NOT NULL DEFAULT CURRENT_USER,
    old_row JSONB,
    new_row JSONB
);

CREATE INDEX IF NOT EXISTS idx_order_audit_order_time
    ON order_audit_log(order_id, changed_at DESC);

CREATE OR REPLACE FUNCTION audit_order_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO order_audit_log(order_id, operation, changed_by, new_row)
        VALUES (NEW.order_id, TG_OP, CURRENT_USER, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO order_audit_log(order_id, operation, changed_by, old_row, new_row)
        VALUES (NEW.order_id, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSE
        INSERT INTO order_audit_log(order_id, operation, changed_by, old_row)
        VALUES (OLD.order_id, TG_OP, CURRENT_USER, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_audit ON orders;

CREATE TRIGGER trg_orders_audit
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW
EXECUTE FUNCTION audit_order_changes();

COMMIT;
