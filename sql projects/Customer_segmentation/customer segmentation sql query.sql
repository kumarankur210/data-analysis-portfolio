
USE project1;
GO

/* ==========================================
   1. DATA EXPLORATION
========================================== */

-- Total records and columns
SELECT COUNT(*) AS total_customers
FROM ecommerce_customers;

-- View sample records
SELECT TOP 10 *
FROM ecommerce_customers;

-- Check customer distribution by country
SELECT Country, COUNT(*) AS total_customers
FROM ecommerce_customers
GROUP BY Country
ORDER BY total_customers DESC;


/* ==========================================
   2. DATA CLEANING
========================================== */

-- Check missing values
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS missing_age,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS missing_country,
    SUM(CASE WHEN Lifetime_Value IS NULL THEN 1 ELSE 0 END) AS missing_lifetime_value,
    SUM(CASE WHEN Churned IS NULL THEN 1 ELSE 0 END) AS missing_churn
FROM ecommerce_customers;

-- Check invalid values
SELECT *
FROM ecommerce_customers
WHERE Age < 0
   OR Membership_Years < 0
   OR Average_Order_Value < 0
   OR Lifetime_Value < 0;

-- Check churn column values
SELECT DISTINCT Churned
FROM ecommerce_customers;

-- Standardize country names (preview only)
SELECT
    Country,
    UPPER(LTRIM(RTRIM(Country))) AS cleaned_country
FROM ecommerce_customers;

-- Check duplicate customer profiles (not necessarily duplicate records)
SELECT
    Age, Gender, Country, City, Signup_Quarter,
    COUNT(*) AS profile_count
FROM ecommerce_customers
GROUP BY Age, Gender, Country, City, Signup_Quarter
HAVING COUNT(*) > 1;


/* ==========================================
   3. WHERE, DISTINCT, ORDER BY, TOP
========================================== */

-- Customers from India
SELECT *
FROM ecommerce_customers
WHERE Country = 'India';

-- Customers with lifetime value above 2000
SELECT *
FROM ecommerce_customers
WHERE Lifetime_Value > 2000;

-- Customers who have churned
SELECT *
FROM ecommerce_customers
WHERE Churned = 1;

-- Customers with membership between 2 and 5 years
SELECT *
FROM ecommerce_customers
WHERE Membership_Years BETWEEN 2 AND 5;

-- Unique countries
SELECT DISTINCT Country
FROM ecommerce_customers;

-- Top 10 customers by lifetime value
SELECT TOP 10 *
FROM ecommerce_customers
ORDER BY Lifetime_Value DESC;


/* ==========================================
   4. GROUP BY AND AGGREGATE FUNCTIONS
========================================== */

-- Customers by gender
SELECT Gender, COUNT(*) AS total_customers
FROM ecommerce_customers
GROUP BY Gender;

-- Average lifetime value by country
SELECT
    Country,
    AVG(Lifetime_Value) AS average_lifetime_value
FROM ecommerce_customers
GROUP BY Country
ORDER BY average_lifetime_value DESC;

-- Average order value by gender
SELECT
    Gender,
    AVG(Average_Order_Value) AS average_order_value
FROM ecommerce_customers
GROUP BY Gender;

-- Average purchases by signup quarter
SELECT
    Signup_Quarter,
    AVG(Total_Purchases) AS average_purchases
FROM ecommerce_customers
GROUP BY Signup_Quarter;


/* ==========================================
   5. HAVING
========================================== */

-- Countries with more than 1000 customers
SELECT Country, COUNT(*) AS total_customers
FROM ecommerce_customers
GROUP BY Country
HAVING COUNT(*) > 1000;

-- Countries with average lifetime value above 1500
SELECT
    Country,
    AVG(Lifetime_Value) AS average_lifetime_value
FROM ecommerce_customers
GROUP BY Country
HAVING AVG(Lifetime_Value) > 1500;

-- Countries with more than 100 churned customers
SELECT
    Country,
    COUNT(*) AS churned_customers
FROM ecommerce_customers
WHERE Churned = 1
GROUP BY Country
HAVING COUNT(*) > 100;


/* ==========================================
   6. BUSINESS ANALYSIS
========================================== */

-- Overall customer and churn KPIs
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END)
        AS churned_customers,
    SUM(CASE WHEN Churned = 0 THEN 1 ELSE 0 END)
        AS active_customers,
    ROUND(
        100.0 * SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS churn_percentage,
    AVG(Lifetime_Value) AS average_lifetime_value
FROM ecommerce_customers;

-- Churn by country
SELECT
    Country,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END)
        AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS churn_percentage
FROM ecommerce_customers
GROUP BY Country
ORDER BY churn_percentage DESC;

-- Churn by gender
SELECT
    Gender,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churned = 1 THEN 1 ELSE 0 END)
        AS churned_customers
FROM ecommerce_customers
GROUP BY Gender;

-- Average customer engagement
SELECT
    Churned,
    AVG(Login_Frequency) AS average_logins,
    AVG(Session_Duration_Avg) AS average_session_duration,
    AVG(Pages_Per_Session) AS average_pages,
    AVG(Email_Open_Rate) AS average_email_open_rate
FROM ecommerce_customers
GROUP BY Churned;

-- Compare lifetime value of churned and active customers
SELECT
    Churned,
    AVG(Lifetime_Value) AS average_lifetime_value,
    AVG(Total_Purchases) AS average_purchases,
    AVG(Average_Order_Value) AS average_order_value
FROM ecommerce_customers
GROUP BY Churned;

-- Customers with high cart abandonment
SELECT *
FROM ecommerce_customers
WHERE Cart_Abandonment_Rate > 70
ORDER BY Cart_Abandonment_Rate DESC;


/* ==========================================
   7. CASE STATEMENT
========================================== */

-- Classify customers by lifetime value
SELECT
    Lifetime_Value,
    CASE
        WHEN Lifetime_Value >= 3000 THEN 'High Value'
        WHEN Lifetime_Value >= 1500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM ecommerce_customers;

-- Classify customers by churn status
SELECT
    CASE
        WHEN Churned = 1 THEN 'Churned'
        ELSE 'Active'
    END AS customer_status,
    COUNT(*) AS total_customers
FROM ecommerce_customers
GROUP BY Churned;


/* ==========================================
   8. SUBQUERIES
========================================== */

-- Customers with lifetime value above average
SELECT *
FROM ecommerce_customers
WHERE Lifetime_Value > (
    SELECT AVG(Lifetime_Value)
    FROM ecommerce_customers
);

-- Customers making more purchases than average
SELECT *
FROM ecommerce_customers
WHERE Total_Purchases > (
    SELECT AVG(Total_Purchases)
    FROM ecommerce_customers
);


/* ==========================================
   9. NULL HANDLING
========================================== */

-- Replace missing values in query output
SELECT
    Country,
    ISNULL(Gender, 'Unknown') AS Gender,
    ISNULL(City, 'Unknown') AS City
FROM ecommerce_customers;

-- Use COALESCE for lifetime value
SELECT
    COALESCE(Lifetime_Value, 0) AS lifetime_value
FROM ecommerce_customers;


/* ==========================================
   10. WINDOW FUNCTIONS
========================================== */

-- ROW_NUMBER: Number customers within each country
SELECT
    Country,
    Lifetime_Value,
    ROW_NUMBER() OVER (
        PARTITION BY Country
        ORDER BY Lifetime_Value DESC
    ) AS customer_number
FROM ecommerce_customers;

-- DENSE_RANK: Rank customers by lifetime value
SELECT
    Country,
    Lifetime_Value,
    DENSE_RANK() OVER (
        ORDER BY Lifetime_Value DESC
    ) AS value_rank
FROM ecommerce_customers;

-- NTILE: Divide customers into 4 lifetime-value groups
SELECT
    Lifetime_Value,
    NTILE(4) OVER (
        ORDER BY Lifetime_Value DESC
    ) AS value_group
FROM ecommerce_customers;


/* ==========================================
   11. INDEXING
========================================== */

-- Check existing indexes
SELECT name, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('ecommerce_customers');

-- Create an index on churn status if not present
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ecommerce_customers_Churned'
      AND object_id = OBJECT_ID('ecommerce_customers')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ecommerce_customers_Churned
    ON ecommerce_customers(Churned);
END;


/* ==========================================
   12. TRANSACTION AND ROLLBACK
========================================== */

-- Safe rollback demonstration
CREATE TABLE #TransactionDemo (
    id INT,
    amount DECIMAL(10,2)
);

INSERT INTO #TransactionDemo VALUES (1, 1000);

BEGIN TRANSACTION;

UPDATE #TransactionDemo
SET amount = 2000
WHERE id = 1;

SELECT * FROM #TransactionDemo;

ROLLBACK TRANSACTION;

-- Original amount should be 1000
SELECT * FROM #TransactionDemo;

DROP TABLE #TransactionDemo;


/* ==========================================
   13. COMMIT TRANSACTION
========================================== */

CREATE TABLE #CommitDemo (
    id INT,
    amount DECIMAL(10,2)
);

INSERT INTO #CommitDemo VALUES (1, 1000);

BEGIN TRANSACTION;

UPDATE #CommitDemo
SET amount = 1500
WHERE id = 1;

COMMIT TRANSACTION;

-- Updated amount should be 1500
SELECT * FROM #CommitDemo;

DROP TABLE #CommitDemo;

GO
