-- V004: High-frequency daily sales materialized view

BEGIN;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_sales AS
SELECT
    DATE(created_at) AS sales_date,
    COUNT(*) AS order_count,
    SUM(total_amount)::NUMERIC(14,2) AS revenue
FROM orders
WHERE status <> 'CANCELLED'
GROUP BY DATE(created_at);

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_daily_sales_date
    ON mv_daily_sales(sales_date);

COMMIT;
