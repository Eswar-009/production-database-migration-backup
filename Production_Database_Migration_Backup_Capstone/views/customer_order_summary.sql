-- Customer reporting view

CREATE OR REPLACE VIEW customer_order_summary AS
SELECT
    c.customer_id,
    c.customer_name,
    c.email,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0)::NUMERIC(14,2) AS total_spend,
    MAX(o.created_at) AS last_order_at
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.email;
