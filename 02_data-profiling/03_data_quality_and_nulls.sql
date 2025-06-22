/*
    File: 03_data_quality_and_nulls.sql
    Topic: Data Profiling
    Task: Data Quality and NULL Values
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Data Quality and NULLs
-- =================================================================================================================================
--
-- Data quality is a critical aspect of any analysis. Poor quality data can lead to incorrect conclusions.
-- This script focuses on two fundamental data quality checks:
-- 1. Identifying and quantifying NULL (missing) values.
-- 2. Detecting duplicate records.
--
-- A NULL value represents the absence of data. It is different from zero or an empty string. Understanding
-- where and how often data is missing is crucial for deciding how to handle it (e.g., remove, impute, or ignore).
--
-- Duplicate records can skew aggregations and analysis, so identifying them early is important.
--
-- =================================================================================================================================
-- Identifying and Counting NULL Values
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Count NULLs in a Single Column
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `IS NULL` operator is used to check for NULL values.
-- Let's check the 'customers' table. The 'Fax' and 'Company' columns are likely to have missing values.

SELECT
    COUNT(*) AS total_rows,
    COUNT(Fax) AS non_null_fax_count,
    (COUNT(*) - COUNT(Fax)) AS null_fax_count
FROM
    customers;

-- A more direct way using a CASE statement or filter:
SELECT
    SUM(CASE WHEN Company IS NULL THEN 1 ELSE 0 END) AS null_company_count,
    SUM(CASE WHEN Company IS NOT NULL THEN 1 ELSE 0 END) AS non_null_company_count
FROM
    customers;

-- Or using a simple WHERE clause:
SELECT COUNT(*) AS null_state_count
FROM customers
WHERE State IS NULL;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Check for Blanks or Empty Strings
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Sometimes, missing data is represented by an empty string ('') instead of NULL. It's important to check for both.
-- This query looks for customers who have a non-NULL but empty string in the 'State' column (unlikely in Chinook, but good practice).

SELECT * FROM customers WHERE State = '';

-- To check for both NULL and empty strings:
SELECT * FROM customers WHERE State IS NULL OR State = '';

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Count NULLs in Every Column of a Table (More Advanced)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- This is a common but more complex task. The query below works for the 'customers' table and can be adapted.
-- It unpivots the data conceptually to count NULLs per column.

SELECT 'CustomerId' as column_name, SUM(CASE WHEN CustomerId IS NULL THEN 1 ELSE 0 END) as null_count FROM customers
UNION ALL
SELECT 'FirstName', SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'LastName', SUM(CASE WHEN LastName IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'Company', SUM(CASE WHEN Company IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'Address', SUM(CASE WHEN Address IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'City', SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'State', SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'Country', SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'PostalCode', SUM(CASE WHEN PostalCode IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'Phone', SUM(CASE WHEN Phone IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'Fax', SUM(CASE WHEN Fax IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'Email', SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) FROM customers
UNION ALL
SELECT 'SupportRepId', SUM(CASE WHEN SupportRepId IS NULL THEN 1 ELSE 0 END) FROM customers;

-- Note: For databases with many columns, generating this query dynamically using `INFORMATION_SCHEMA` is a common
--       best practice, but that requires procedural SQL (e.g., T-SQL, PL/pgSQL).

-- =================================================================================================================================
-- Detecting Duplicate Records
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Check for Duplicate Primary Keys
-- ---------------------------------------------------------------------------------------------------------------------------------
-- A well-designed table should have a primary key constraint that prevents duplicate keys.
-- This query will return any `ArtistId` that appears more than once. It should return no rows for the `artists` table.

SELECT
    ArtistId,
    COUNT(*)
FROM
    artists
GROUP BY
    ArtistId
HAVING
    COUNT(*) > 1;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 5: Check for Duplicates Based on a Combination of Columns
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Sometimes, duplicates are defined by a combination of business keys, not just the primary key.
-- For example, let's check if there are any playlists with the exact same name.

SELECT
    Name,
    COUNT(*)
FROM
    playlists
GROUP BY
    Name
HAVING
    COUNT(*) > 1;

-- Let's check for duplicate tracks based on Name, AlbumId, MediaTypeId, GenreId, and Composer.
-- This combination should uniquely identify a track.
SELECT
    Name,
    AlbumId,
    MediaTypeId,
    GenreId,
    Composer,
    COUNT(*)
FROM
    tracks
GROUP BY
    Name, AlbumId, MediaTypeId, GenreId, Composer
HAVING
    COUNT(*) > 1;

-- =================================================================================================================================
-- Practical Exercise: Data Quality Check on the Chinook Database
-- =================================================================================================================================

-- 1. How many customers are missing a 'Company' name?
SELECT COUNT(*) FROM customers WHERE Company IS NULL;

-- 2. How many customers are from a state, but the state information is missing?
--    (i.e., Country is 'USA', but State is NULL).
SELECT COUNT(*) FROM customers WHERE Country = 'USA' AND State IS NULL;

-- 3. Are there any employees with the same first and last name?
SELECT
    FirstName,
    LastName,
    COUNT(*)
FROM
    employees
GROUP BY
    FirstName, LastName
HAVING
    COUNT(*) > 1;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- In this script, you learned how to perform basic but essential data quality checks.
-- - Counting NULLs helps you assess the completeness of your data.
-- - Finding duplicates ensures the integrity of your records.
--
-- These checks are the foundation for data cleaning, where you will decide how to handle these issues.
--
-- =================================================================================================================================
