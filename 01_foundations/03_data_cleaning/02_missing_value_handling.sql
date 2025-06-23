/*
    File: 02_missing_value_handling.sql
    Topic: Data Cleaning
    Task: Handling Missing (NULL) Values
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Handling Missing Values
-- =================================================================================================================================
--
-- Missing data, represented as NULL, is a common problem in datasets. NULLs can complicate calculations, break joins,
-- and lead to biased or incorrect analysis if not handled properly. Data cleaning involves choosing a strategy
-- for managing these missing values.
--
-- Common strategies include:
-- 1. **Imputation**: Replacing NULLs with a substitute value. This could be a constant (e.g., 0, 'Unknown'),
--    or a calculated value (e.g., the mean, median, or mode of the column).
-- 2. **Deletion**: Removing rows that contain NULL values. This is often done if the missing value is in a critical
--    column or if the number of affected rows is small.
-- 3. **Keeping NULLs**: Sometimes, the fact that a value is missing is informative in itself. In such cases,
--    NULLs can be treated as a separate category in analysis.
--
-- This script focuses on imputation and deletion techniques.
--
-- =================================================================================================================================
-- Step 1: Imputation - Replacing NULLs with a Substitute Value
-- =================================================================================================================================
--
-- Imputation is the most common strategy. The `COALESCE` function is the ANSI-standard way to replace NULLs.
-- It returns the first non-NULL value from a list of expressions.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Replace NULL in a text column with a placeholder string
-- ---------------------------------------------------------------------------------------------------------------------------------
-- In the `customers` table, the `Company` column has many NULLs. We can replace them with 'N/A' for reporting.

SELECT
    FirstName,
    LastName,
    Company, -- The original column with NULLs
    COALESCE(Company, 'Not Provided') AS Company_Imputed -- The column with NULLs replaced
FROM
    customers;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Flavor-Specific Note: ISNULL (SQL Server)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQL Server also has the `ISNULL()` function. It takes two arguments: the column to check and the replacement value.
-- `COALESCE` is generally preferred because it is part of the ANSI SQL standard and can handle multiple arguments.
--
-- -- SQL Server Syntax
-- SELECT Company, ISNULL(Company, 'Not Provided') FROM customers;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Replace NULL in a numeric column with zero
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Imagine the `invoices` table could have a NULL `Total`. Calculations like SUM() would ignore NULLs, but if you
-- want to treat them as 0 for an average, you must impute them.

SELECT
    InvoiceId,
    Total,
    COALESCE(Total, 0.0) AS Total_Imputed
FROM
    invoices;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Imputing with a Calculated Value (e.g., the Average)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- A more advanced technique is to replace NULLs with the average (mean) of the non-NULL values in that column.
-- This is often done in statistical analysis and machine learning.
--
-- Let's simulate this. First, let's find the average `Total` for all invoices.
SELECT AVG(Total) FROM invoices;
-- Result is approx 5.65

-- Now, we can use this value in a query. In a real scenario, you might store this in a variable.
-- This is a SELECT query to show the concept. An UPDATE would permanently change the data.
SELECT
    InvoiceId,
    Total,
    COALESCE(Total, (SELECT AVG(Total) FROM invoices)) AS Total_Imputed_With_Mean
FROM
    invoices;
-- Note: Since `Total` in Chinook has no NULLs, this is for demonstration.

-- =================================================================================================================================
-- Step 2: Deletion - Removing Rows with NULL Values
-- =================================================================================================================================
--
-- If a row is missing a critical piece of information (e.g., a primary key, a crucial date), it might be better
-- to remove it entirely. This should be done with caution, as it can lead to loss of information.
-- **IMPORTANT**: Always run a `SELECT` to see what you are about to delete before running a `DELETE` statement.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Deleting rows where a specific column is NULL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's say we need to delete all customer records that are missing a `State`, for a state-level analysis in the US.

-- First, let's create a temporary table to work with, so we don't alter the original data.
CREATE TEMP TABLE customers_temp AS SELECT * FROM customers;

-- Now, let's see how many customers from the USA are missing a state.
SELECT COUNT(*) FROM customers_temp WHERE Country = 'USA' AND State IS NULL;
-- This should return 0 in the standard Chinook database.

-- Let's find customers missing a `PostalCode`.
SELECT * FROM customers_temp WHERE PostalCode IS NULL;

-- Let's write the DELETE statement to remove them.
DELETE FROM customers_temp WHERE PostalCode IS NULL;

-- Verify the deletion.
SELECT COUNT(*) FROM customers_temp WHERE PostalCode IS NULL;
-- This should now return 0.

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. In the `customers` table, the `Fax` column has many NULLs. Write a query that displays the customer's full name,
--    their fax number, and a new column `Fax_Status` that shows 'Available' if the fax number exists and 'Not Available' if it is NULL.
SELECT
    FirstName || ' ' || LastName AS FullName,
    Fax,
    COALESCE(Fax, 'Not Available') AS Fax_Status -- A simple way, but let's use CASE for more clarity
FROM customers;

-- A better way using CASE for more descriptive status:
SELECT
    FirstName || ' ' || LastName AS FullName,
    Fax,
    CASE
        WHEN Fax IS NOT NULL THEN 'Available'
        ELSE 'Not Available'
    END AS Fax_Status
FROM customers;

-- 2. The `employees` table has a `ReportsTo` column, which is NULL for the top-level manager.
--    Write a query that displays the employee's full name and their manager's ID.
--    For the top manager, display 'Top Manager' instead of a NULL ID.
SELECT
    FirstName || ' ' || LastName AS EmployeeName,
    ReportsTo,
    COALESCE(CAST(ReportsTo AS VARCHAR), 'Top Manager') AS Manager_Info
FROM
    employees;
-- Note: We need to CAST the numeric `ReportsTo` to VARCHAR to be compatible with the string 'Top Manager' in COALESCE.

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- You have learned the primary methods for handling missing data: imputation and deletion.
-- - `COALESCE` is your standard tool for replacing NULLs with a default value.
-- - Deleting rows with `DELETE ... WHERE ... IS NULL` is powerful but should be used with care.
--
-- The choice of strategy depends heavily on the context of your data and your analysis goals.
-- Always investigate *why* data is missing before deciding how to handle it.
--
-- =================================================================================================================================
