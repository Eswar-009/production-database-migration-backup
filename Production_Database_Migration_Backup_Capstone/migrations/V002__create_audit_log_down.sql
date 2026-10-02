-- V002 DOWN
BEGIN;

DROP TRIGGER IF EXISTS trg_orders_audit ON orders;
DROP FUNCTION IF EXISTS audit_order_changes();
DROP TABLE IF EXISTS order_audit_log;

COMMIT;
