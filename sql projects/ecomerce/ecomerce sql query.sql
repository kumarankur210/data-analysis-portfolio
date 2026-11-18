
USE project1;

  -- 1. DATA EXPLORATION


-- Check total records in each table
SELECT 'customers' AS table_name, COUNT(*) AS total_records FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'returns', COUNT(*) FROM returns
UNION ALL
SELECT 'shipments', COUNT(*) FROM shipments;

-- View sample records
SELECT TOP 10 * FROM customers;
SELECT TOP 10 * FROM orders;
SELECT TOP 10 * FROM products;



   --2. DATA CLEANING


-- Find missing customer emails
SELECT *
FROM customers
WHERE email IS NULL OR LTRIM(RTRIM(email)) = '';

-- Find duplicate customer emails
SELECT email, COUNT(*) AS duplicate_count
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

-- Check duplicate customer IDs
SELECT customer_id, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check invalid product prices
SELECT *
FROM products
WHERE unit_price < 0 OR unit_cost < 0;

-- Check invalid order quantities
SELECT *
FROM order_items
WHERE quantity <= 0 OR unit_price < 0;

-- Standardize email format (preview only)
SELECT
    email,
    LOWER(LTRIM(RTRIM(email))) AS cleaned_email
FROM customers;

-- Check invalid dates
SELECT *
FROM orders
WHERE TRY_CONVERT(date, order_date) IS NULL
AND NULLIF(LTRIM(RTRIM(order_date)), '') IS NOT NULL;


   --3. WHERE, DISTINCT, ORDER BY, TOP
-- Find delivered orders
SELECT *
FROM orders
WHERE status = 'Delivered';

-- Find customers from India
SELECT *
FROM customers
WHERE country = 'India';

-- Find products within a price range
SELECT *
FROM products
WHERE unit_price BETWEEN 500 AND 2000;

-- Find orders with selected statuses
SELECT *
FROM orders
WHERE status IN ('Delivered', 'Shipped');

-- Find Gmail customers
SELECT *
FROM customers
WHERE email LIKE '%gmail.com';

-- List unique product categories
SELECT DISTINCT category
FROM products;

-- Find the 10 most expensive products
SELECT TOP 10 *
FROM products
ORDER BY unit_price DESC;



  -- 4. GROUP BY AND AGGREGATE FUNCTIONS


-- Count customers by country
SELECT
    country,
    COUNT(*) AS total_customers
FROM customers
GROUP BY country;

-- Total orders by status
SELECT
    status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY status;

-- Revenue by order status
SELECT
    status,
    SUM(total_amount) AS total_revenue
FROM orders
GROUP BY status;

-- Average product price by category
SELECT
    category,
    AVG(unit_price) AS average_price
FROM products
GROUP BY category;

-- Total quantity sold by product
SELECT
    product_id,
    SUM(quantity) AS total_quantity
FROM order_items
GROUP BY product_id;


--5.Having


-- Customers who placed more than 5 orders
SELECT
    customer_id,
    COUNT(*) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 5;

-- Categories with average price above 1000
SELECT
    category,
    AVG(unit_price) AS average_price
FROM products
GROUP BY category
HAVING AVG(unit_price) > 1000;

-- Countries having more than 1000 customers
SELECT
    country,
    COUNT(*) AS total_customers
FROM customers
GROUP BY country
HAVING COUNT(*) > 1000;



  -- 6. JOINS


-- INNER JOIN: Customer and order details
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id;

-- LEFT JOIN: Customers who never ordered
SELECT
    c.customer_id,
    c.first_name,
    c.email
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Multiple JOINs: Product sales details
SELECT
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    oi.line_total
FROM order_items oi
INNER JOIN products p
ON oi.product_id = p.product_id;

-- Orders with payment details
SELECT
    o.order_id,
    o.total_amount,
    p.method,
    p.amount,
    p.status AS payment_status
FROM orders o
LEFT JOIN payments p
ON o.order_id = p.order_id;



   --7. SUBQUERIES


-- Products costing more than average price
SELECT *
FROM products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM products
);

-- Orders with above-average order value
SELECT *
FROM orders
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM orders
);


  --8. BUSINESS ANALYSIS


-- Overall business performance
SELECT
    COUNT(*) AS total_orders,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS average_order_value,
    SUM(discount_amount) AS total_discount
FROM orders;

-- Monthly revenue
SELECT
    YEAR(TRY_CONVERT(date, order_date)) AS sales_year,
    MONTH(TRY_CONVERT(date, order_date)) AS sales_month,
    COUNT(*) AS total_orders,
    SUM(total_amount) AS revenue
FROM orders
WHERE TRY_CONVERT(date, order_date) IS NOT NULL
GROUP BY
    YEAR(TRY_CONVERT(date, order_date)),
    MONTH(TRY_CONVERT(date, order_date))
ORDER BY sales_year, sales_month;

-- Top 10 customers by spending
SELECT TOP 10
    c.customer_id,
    c.first_name,
    SUM(o.total_amount) AS total_spending
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name
ORDER BY total_spending DESC;

-- Top 10 best-selling products
SELECT TOP 10
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS total_sales
FROM products p
INNER JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC;

-- Revenue by product category
SELECT
    p.category,
    SUM(oi.line_total) AS category_revenue
FROM products p
INNER JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- Payment method analysis
SELECT
    method,
    COUNT(*) AS total_payments,
    SUM(amount) AS total_amount
FROM payments
GROUP BY method;

-- Return analysis
SELECT
    status,
    COUNT(*) AS total_returns,
    SUM(refund_amount) AS total_refunds
FROM returns
GROUP BY status;



  -- 9. CASE STATEMENT
-- Classify orders by order value
SELECT
    order_id,
    total_amount,
    CASE
        WHEN total_amount >= 5000 THEN 'High Value'
        WHEN total_amount >= 2000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_category
FROM orders;

-- Classify customers by loyalty tier
SELECT
    loyalty_tier,
    COUNT(*) AS total_customers
FROM customers
GROUP BY loyalty_tier;


   --10. NULL HANDLING


-- Replace missing phone numbers in output
SELECT
    customer_id,
    first_name,
    COALESCE(phone, 'Not Available') AS phone
FROM customers;

-- Calculate payment amount safely
SELECT
    payment_id,
    amount,
    ISNULL(amount, 0) AS corrected_amount
FROM payments;

-- 11. WINDOW FUNCTION
-- Rank products by price
SELECT
    product_name,
    category,
    unit_price,
    RANK() OVER (
        ORDER BY unit_price DESC
    ) AS price_rank
FROM products;

-- 1. ROW_NUMBER()
-- Find the latest order placed by each customer

SELECT *
FROM (
    SELECT
        customer_id,
        order_id,
        order_date,
        total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY TRY_CONVERT(date, order_date) DESC
        ) AS row_num
    FROM orders
) AS ranked_orders
WHERE row_num = 1;


-- 2. DENSE_RANK()
-- Rank products by price without skipping rank numbers

SELECT
    product_name,
    category,
    unit_price,
    DENSE_RANK() OVER (
        ORDER BY unit_price DESC
    ) AS price_rank
FROM products;


-- 3. LAG()
-- Compare monthly revenue with the previous month

SELECT
    sales_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (
        ORDER BY sales_month
    ) AS previous_month_revenue
FROM (
    SELECT
        DATEFROMPARTS(
            YEAR(TRY_CONVERT(date, order_date)),
            MONTH(TRY_CONVERT(date, order_date)),
            1
        ) AS sales_month,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE TRY_CONVERT(date, order_date) IS NOT NULL
    GROUP BY
        YEAR(TRY_CONVERT(date, order_date)),
        MONTH(TRY_CONVERT(date, order_date))
) AS monthly_sales;


-- 4. LEAD()
-- Compare each month's revenue with the next month

SELECT
    sales_month,
    monthly_revenue,
    LEAD(monthly_revenue) OVER (
        ORDER BY sales_month
    ) AS next_month_revenue
FROM (
    SELECT
        DATEFROMPARTS(
            YEAR(TRY_CONVERT(date, order_date)),
            MONTH(TRY_CONVERT(date, order_date)),
            1
        ) AS sales_month,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE TRY_CONVERT(date, order_date) IS NOT NULL
    GROUP BY
        YEAR(TRY_CONVERT(date, order_date)),
        MONTH(TRY_CONVERT(date, order_date))
) AS monthly_sales;

GO

 --  12. INDEXING


-- View indexes on orders
SELECT
    name,
    type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('orders');

-- Create index if it does not exist
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_orders_customer_id'
      AND object_id = OBJECT_ID('orders')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_orders_customer_id
    ON orders(customer_id);
END;



   --13. TRANSACTION AND ROLLBACK


-- Safe transaction demonstration using a temporary table

CREATE TABLE #TransactionDemo (
    id INT,
    amount DECIMAL(10,2)
);

INSERT INTO #TransactionDemo
VALUES (1, 1000);

BEGIN TRANSACTION;

UPDATE #TransactionDemo
SET amount = 2000
WHERE id = 1;

-- Check updated value
SELECT * FROM #TransactionDemo;

-- Undo the update
ROLLBACK TRANSACTION;

-- Original value should be 1000
SELECT * FROM #TransactionDemo;

DROP TABLE #TransactionDemo;

  --14. COMMIT TRANSACTION DEMO


CREATE TABLE #CommitDemo (
    id INT,
    amount DECIMAL(10,2)
);

INSERT INTO #CommitDemo
VALUES (1, 1000);

BEGIN TRANSACTION;

UPDATE #CommitDemo
SET amount = 1500
WHERE id = 1;

COMMIT TRANSACTION;

-- Updated value should be 1500
SELECT * FROM #CommitDemo;

DROP TABLE #CommitDemo;

GO
