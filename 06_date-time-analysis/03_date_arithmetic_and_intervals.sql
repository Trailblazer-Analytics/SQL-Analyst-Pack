/*
    File        : 06_date-time-analysis/03_date_arithmetic_and_intervals.sql
    Topic       : Date-Time Analysis
    Purpose     : Demonstrates how to perform arithmetic on dates, such as adding/subtracting intervals and finding the difference between dates.
    Author      : GitHub Copilot
    Created     : 2025-06-21
    Updated     : 2025-06-21
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    -- Syntax for date arithmetic is highly variable between database systems.
    Notes       : • This is crucial for cohort analysis, trend analysis, and time-based filtering.
*/

-- =============================================================================
-- Scenario 1: Adding and Subtracting Intervals from a Date
-- =============================================================================
-- Goal: Find invoices that were created more than 1 year after the very first invoice.

-- -----------------------------------------------------------------------------
-- Step 1: Find the first invoice date.
-- -----------------------------------------------------------------------------
SELECT MIN(InvoiceDate) FROM Invoice; -- Let's assume this is '2009-01-01'

-- -----------------------------------------------------------------------------
-- Step 2: Add an interval to that date.
-- -----------------------------------------------------------------------------

-- PostgreSQL, Oracle, BigQuery, Snowflake (using INTERVAL):
SELECT '2009-01-01'::date + INTERVAL '1 year';

-- MySQL (using DATE_ADD):
-- SELECT DATE_ADD('2009-01-01', INTERVAL 1 YEAR);

-- SQL Server (using DATEADD):
-- SELECT DATEADD(year, 1, '2009-01-01');

-- SQLite (using strftime):
-- SELECT date('2009-01-01', '+1 year');


-- =============================================================================
-- Scenario 2: Calculating the Difference Between Two Dates
-- =============================================================================
-- Goal: For each customer, calculate how many days passed between their first and last invoice.

SELECT
    CustomerId,
    MIN(InvoiceDate) AS FirstInvoiceDate,
    MAX(InvoiceDate) AS LastInvoiceDate,
    -- PostgreSQL, Oracle:
    MAX(InvoiceDate) - MIN(InvoiceDate) AS DaysBetween

    -- MySQL, SQL Server (using DATEDIFF):
    -- DATEDIFF(day, MIN(InvoiceDate), MAX(InvoiceDate)) AS DaysBetween -- (Syntax varies)

    -- SQLite (using julianday):
    -- julianday(MAX(InvoiceDate)) - julianday(MIN(InvoiceDate)) AS DaysBetween
FROM Invoice
GROUP BY CustomerId
HAVING COUNT(InvoiceId) > 1 -- Only include customers with more than one invoice
ORDER BY DaysBetween DESC
LIMIT 10;


-- =============================================================================
-- Practical Application: Filtering for Recent Records
-- =============================================================================
-- Goal: Find all invoices from the last 90 days (relative to the most recent invoice date in the table).

-- PostgreSQL, Oracle:
SELECT * FROM Invoice
WHERE InvoiceDate > (SELECT MAX(InvoiceDate) FROM Invoice) - INTERVAL '90 day';

-- MySQL:
-- SELECT * FROM Invoice
-- WHERE InvoiceDate > DATE_SUB((SELECT MAX(InvoiceDate) FROM Invoice), INTERVAL 90 DAY);

-- SQL Server:
-- SELECT * FROM Invoice
-- WHERE InvoiceDate > DATEADD(day, -90, (SELECT MAX(InvoiceDate) FROM Invoice));

-- SQLite:
-- SELECT * FROM Invoice
-- WHERE InvoiceDate > date((SELECT MAX(InvoiceDate) FROM Invoice), '-90 day');
