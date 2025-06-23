/*
    File        : 02_data-profiling/04_value_distribution_and_frequency.sql
    Topic       : Data Profiling
    Purpose     : Provides methods for analyzing the distribution and frequency of values in a column.
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-21
    Updated     : 2025-06-23
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery | ✅ Snowflake
    Notes       : • Understanding value distribution is a core part of data exploration and profiling.
*/

-- =============================================================================
-- Scenario 1: Value Frequency for a Categorical Column
-- =============================================================================
-- Goal: Find out which countries our customers are from and how many customers are in each country.
-- This helps us understand our customer base geographically.

SELECT
    Country,
    COUNT(*) AS CustomerCount
FROM Customer
GROUP BY Country
ORDER BY CustomerCount DESC;

-- Expected Result:
-- A list of countries and the number of customers in each, from most to least common.
-- This can quickly highlight our primary markets


-- =============================================================================
-- Scenario 2: Creating a Histogram for a Numeric Column
-- =============================================================================
-- Goal: Analyze the distribution of invoice totals to understand common purchase sizes.
-- Since `Total` is a continuous numeric value, we group it into buckets (a histogram).

SELECT
    CASE
        WHEN Total BETWEEN 0 AND 1.99   THEN '0-2'
        WHEN Total BETWEEN 2 AND 4.99   THEN '2-5'
        WHEN Total BETWEEN 5 AND 9.99   THEN '5-10'
        WHEN Total BETWEEN 10 AND 14.99 THEN '10-15'
        ELSE '15+'
    END AS InvoiceTotalBucket,
    COUNT(*) AS NumberOfInvoices,
    -- Simple bar chart for visualization in text results
    RPAD('', COUNT(*), '*') AS BarChart
FROM Invoice
GROUP BY InvoiceTotalBucket
ORDER BY MIN(Total); -- Order the buckets logically

-- Expected Result:
-- A set of buckets for invoice totals and the count of invoices in each bucket.
-- This shows whether most invoices are for small amounts or large amounts.


-- =============================================================================
-- Scenario 3: Finding the Most Frequent Values (Top N)
-- =============================================================================
-- Goal: Find the top 5 most frequently purchased tracks.
-- This is useful for identifying the most popular items in our catalog.

SELECT
    t.Name AS TrackName,
    COUNT(il.TrackId) AS PurchaseCount
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
GROUP BY t.Name
ORDER BY PurchaseCount DESC
LIMIT 5;

-- For SQL Server, you would use `TOP 5`:
-- SELECT TOP 5
--     t.Name AS TrackName,
--     COUNT(il.TrackId) AS PurchaseCount
-- FROM InvoiceLine il
-- JOIN Track t ON il.TrackId = t.TrackId
-- GROUP BY t.Name
-- ORDER BY PurchaseCount DESC;

-- Expected Result:
-- The names of the 5 tracks that appear most often in all invoices combined.
