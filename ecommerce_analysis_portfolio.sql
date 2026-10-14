-- =====================================================
-- E-COMMERCE SALES & CUSTOMER ANALYTICS
-- Portfolio SQL Project
-- Database: ecommerce_analysis
-- Tools: MySQL
-- =====================================================

USE ecommerce_analysis;

-- 1. CHECK TABLE ROW COUNTS
-- Confirm the size of each table in the dataset

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items;

-- 2. ORDER STATUS SUMMARY
-- Count orders by status and calculate their share of all orders

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders),
        2
    ) AS percentage_of_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- =====================================================
-- 3. TOTAL REVENUE AND PROFIT FROM DELIVERED ORDERS
-- =====================================================

SELECT
    SUM(oi.quantity * p.price) AS total_revenue,
    SUM(oi.quantity * (p.price - p.cost)) AS total_profit,
    ROUND(
        SUM(oi.quantity * (p.price - p.cost)) * 100.0
        / NULLIF(SUM(oi.quantity * p.price), 0),
        2
    ) AS profit_margin_percentage
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered';

-- =====================================================
-- 4. REVENUE BY PRODUCT CATEGORY
-- =====================================================

SELECT
    p.category,
    SUM(oi.quantity * p.price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- =====================================================
-- 5. TOP 10 CUSTOMERS BY DELIVERED REVENUE
-- =====================================================

SELECT
    c.customer_name,
    SUM(oi.quantity * p.price) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue DESC, c.customer_name ASC
LIMIT 10;

-- =====================================================
-- 6. CUSTOMER ORDER FREQUENCY
-- =====================================================

SELECT
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(
        CASE
            WHEN o.order_status = 'Delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders DESC, c.customer_name ASC;

-- =====================================================
-- 7. MONTHLY REVENUE TREND
-- =====================================================

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    SUM(oi.quantity * p.price) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;

-- =====================================================
-- 8. RANK CUSTOMERS BY REVENUE
-- Demonstrates a CTE and a window function
-- =====================================================

WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * p.price) AS total_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_name,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM customer_revenue
ORDER BY revenue_rank, customer_name;

-- =====================================================
-- 9. ORDER CANCELLATION ANALYSIS
-- =====================================================

SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'Delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders,
    SUM(
        CASE
            WHEN order_status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,
    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_percentage
FROM orders;

-- =====================================================
-- 10. REVENUE BY ORDER STATUS
-- Only delivered revenue is treated as realized revenue
-- =====================================================

SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * p.price) AS order_item_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY o.order_status
ORDER BY total_orders DESC;