
USE Amazon;
GO

/* ==========================================
   1. DATA EXPLORATION
========================================== */

-- Total records
SELECT COUNT(*) AS total_students
FROM dbo.student_dropout;

-- Preview data
SELECT TOP 10 *
FROM dbo.student_dropout;

-- Column names and data types
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'student_dropout'
ORDER BY ORDINAL_POSITION;

-- Number of distinct values in the table's columns
DECLARE @sql NVARCHAR(MAX);

SELECT @sql = STRING_AGG(
    CAST(
        'COUNT(DISTINCT ' + QUOTENAME(COLUMN_NAME) +
        ') AS ' + QUOTENAME(COLUMN_NAME + '_distinct')
        AS NVARCHAR(MAX)
    ), ', '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'student_dropout';

SET @sql = 'SELECT ' + @sql +
           ' FROM dbo.student_dropout;';

EXEC sp_executesql @sql;


/* ==========================================
   2. DATA QUALITY CHECKS
========================================== */

-- Check missing values in every column
SELECT @sql = STRING_AGG(
    CAST(
        'SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME) +
        ' IS NULL THEN 1 ELSE 0 END) AS ' +
        QUOTENAME(COLUMN_NAME + '_nulls')
        AS NVARCHAR(MAX)
    ), ', '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'student_dropout';

SET @sql = 'SELECT ' + @sql +
           ' FROM dbo.student_dropout;';

EXEC sp_executesql @sql;


-- Check completely duplicate records
DECLARE @columns NVARCHAR(MAX);

SELECT @columns = STRING_AGG(
    CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), ', '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'student_dropout';

SET @sql =
    'SELECT ' + @columns +
    ', COUNT(*) AS duplicate_count
     FROM dbo.student_dropout
     GROUP BY ' + @columns +
    ' HAVING COUNT(*) > 1;';

EXEC sp_executesql @sql;


/* ==========================================
   3. FILTERING AND SORTING
========================================== */

-- View all records
SELECT *
FROM dbo.student_dropout;

-- View first 20 records
SELECT TOP 20 *
FROM dbo.student_dropout;

-- Find unique values (using the first text column)
DECLARE @category NVARCHAR(128);

SELECT TOP 1 @category = COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'student_dropout'
  AND DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar')
ORDER BY ORDINAL_POSITION;

IF @category IS NOT NULL
BEGIN
    SET @sql = 'SELECT DISTINCT ' + QUOTENAME(@category) +
               ' FROM dbo.student_dropout ORDER BY ' +
               QUOTENAME(@category) + ';';
    EXEC sp_executesql @sql;
END;


/* ==========================================
   4. AGGREGATE FUNCTIONS
========================================== */

-- Numeric column summary using the first numeric column
DECLARE @numeric_col NVARCHAR(128);

SELECT TOP 1 @numeric_col = COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'student_dropout'
  AND DATA_TYPE IN (
      'int', 'bigint', 'smallint', 'tinyint',
      'decimal', 'numeric', 'float', 'real', 'money'
  )
ORDER BY ORDINAL_POSITION;

IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT
            COUNT(*) AS total_records,
            COUNT(' + QUOTENAME(@numeric_col) + ') AS non_null_values,
            MIN(' + QUOTENAME(@numeric_col) + ') AS minimum_value,
            MAX(' + QUOTENAME(@numeric_col) + ') AS maximum_value,
            AVG(TRY_CONVERT(float, ' + QUOTENAME(@numeric_col) + ')) AS average_value
         FROM dbo.student_dropout;';

    EXEC sp_executesql @sql;
END;


/* ==========================================
   5. GROUP BY AND HAVING
========================================== */

-- Count students by first categorical column
IF @category IS NOT NULL
BEGIN
    SET @sql =
        'SELECT ' + QUOTENAME(@category) +
        ', COUNT(*) AS total_students
         FROM dbo.student_dropout
         GROUP BY ' + QUOTENAME(@category) +
        ' ORDER BY total_students DESC;';

    EXEC sp_executesql @sql;
END;

-- Groups having more than 100 records
IF @category IS NOT NULL
BEGIN
    SET @sql =
        'SELECT ' + QUOTENAME(@category) +
        ', COUNT(*) AS total_students
         FROM dbo.student_dropout
         GROUP BY ' + QUOTENAME(@category) +
        ' HAVING COUNT(*) > 100;';

    EXEC sp_executesql @sql;
END;


/* ==========================================
   6. CASE STATEMENT
========================================== */

-- Categorize the first numeric column into groups
IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT
            ' + QUOTENAME(@numeric_col) + ',
            CASE
                WHEN TRY_CONVERT(float, ' + QUOTENAME(@numeric_col) + ') >= 75
                    THEN ''High''
                WHEN TRY_CONVERT(float, ' + QUOTENAME(@numeric_col) + ') >= 40
                    THEN ''Medium''
                ELSE ''Low''
            END AS value_category
         FROM dbo.student_dropout;';

    EXEC sp_executesql @sql;
END;


/* ==========================================
   7. SUBQUERIES
========================================== */

-- Find records above the average numeric value
IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT *
         FROM dbo.student_dropout
         WHERE TRY_CONVERT(float, ' + QUOTENAME(@numeric_col) + ') >
         (
             SELECT AVG(TRY_CONVERT(float, ' +
             QUOTENAME(@numeric_col) + '))
             FROM dbo.student_dropout
         );';

    EXEC sp_executesql @sql;
END;


/* ==========================================
   8. WINDOW FUNCTIONS
========================================== */

-- 1. ROW_NUMBER
-- Assign a sequential number to records
IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT
            *,
            ROW_NUMBER() OVER (
                ORDER BY TRY_CONVERT(float, ' +
                QUOTENAME(@numeric_col) + ') DESC
            ) AS row_num
         FROM dbo.student_dropout;';

    EXEC sp_executesql @sql;
END;


-- 2. DENSE_RANK
-- Rank records by numeric value
IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT
            ' + QUOTENAME(@numeric_col) + ',
            DENSE_RANK() OVER (
                ORDER BY TRY_CONVERT(float, ' +
                QUOTENAME(@numeric_col) + ') DESC
            ) AS dense_rank
         FROM dbo.student_dropout;';

    EXEC sp_executesql @sql;
END;


-- 3. LAG
-- Compare with previous numeric value
IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT
            ' + QUOTENAME(@numeric_col) + ',
            LAG(' + QUOTENAME(@numeric_col) + ') OVER (
                ORDER BY TRY_CONVERT(float, ' +
                QUOTENAME(@numeric_col) + ')
            ) AS previous_value
         FROM dbo.student_dropout;';

    EXEC sp_executesql @sql;
END;


-- 4. LEAD
-- Compare with next numeric value
IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT
            ' + QUOTENAME(@numeric_col) + ',
            LEAD(' + QUOTENAME(@numeric_col) + ') OVER (
                ORDER BY TRY_CONVERT(float, ' +
                QUOTENAME(@numeric_col) + ')
            ) AS next_value
         FROM dbo.student_dropout;';

    EXEC sp_executesql @sql;
END;


-- COUNT OVER: Total records alongside each row
SELECT
    *,
    COUNT(*) OVER() AS total_records
FROM dbo.student_dropout;


/* ==========================================
   9. NULL HANDLING
========================================== */

-- COALESCE example using first numeric column
IF @numeric_col IS NOT NULL
BEGIN
    SET @sql =
        'SELECT
            COALESCE(TRY_CONVERT(float, ' +
            QUOTENAME(@numeric_col) + '), 0) AS cleaned_value
         FROM dbo.student_dropout;';

    EXEC sp_executesql @sql;
END;


/* ==========================================
   10. INDEXING
========================================== */

-- View current indexes
SELECT
    name,
    type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.student_dropout');

-- Index the first numeric column if one exists
IF @numeric_col IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_student_dropout_numeric'
      AND object_id = OBJECT_ID('dbo.student_dropout')
)
BEGIN
    SET @sql =
        'CREATE NONCLUSTERED INDEX IX_student_dropout_numeric
         ON dbo.student_dropout (' +
         QUOTENAME(@numeric_col) + ');';

    EXEC sp_executesql @sql;
END;


/* ==========================================
   11. TRANSACTION AND ROLLBACK
========================================== */

CREATE TABLE #RollbackDemo (
    id INT,
    amount DECIMAL(10,2)
);

INSERT INTO #RollbackDemo VALUES (1, 1000);

BEGIN TRANSACTION;

UPDATE #RollbackDemo
SET amount = 2000
WHERE id = 1;

SELECT * FROM #RollbackDemo;

ROLLBACK TRANSACTION;

-- Original value should be 1000
SELECT * FROM #RollbackDemo;

DROP TABLE #RollbackDemo;


/* ==========================================
   12. TRANSACTION AND COMMIT
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

-- Updated value should be 1500
SELECT * FROM #CommitDemo;

DROP TABLE #CommitDemo;

GO
