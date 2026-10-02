-- Stored procedure for safe order placement.
-- Call inside an application transaction boundary.

CREATE OR REPLACE PROCEDURE place_order(
    p_customer_id BIGINT,
    p_product_id BIGINT,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_unit_price NUMERIC(12,2);
    v_order_id BIGINT;
    v_available INTEGER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    SELECT quantity
    INTO v_available
    FROM inventory
    WHERE product_id = p_product_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        RAISE EXCEPTION 'No inventory record for product %', p_product_id;
    END IF;

    IF v_available < p_quantity THEN
        RAISE EXCEPTION
            'Insufficient inventory: available %, requested %',
            v_available, p_quantity;
    END IF;

    SELECT unit_price
    INTO v_unit_price
    FROM products
    WHERE product_id = p_product_id;

    IF v_unit_price IS NULL THEN
        RAISE EXCEPTION 'Product % does not exist', p_product_id;
    END IF;

    INSERT INTO orders(customer_id, status, total_amount)
    VALUES (p_customer_id, 'CONFIRMED', v_unit_price * p_quantity)
    RETURNING order_id INTO v_order_id;

    INSERT INTO order_items(order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, p_product_id, p_quantity, v_unit_price);

    UPDATE inventory
    SET quantity = quantity - p_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;

    RAISE NOTICE 'Order % created successfully', v_order_id;
END;
$$;

-- Example:
-- BEGIN;
-- CALL place_order(1, 10, 2);
-- COMMIT;
--
-- On an exception:
-- ROLLBACK;
