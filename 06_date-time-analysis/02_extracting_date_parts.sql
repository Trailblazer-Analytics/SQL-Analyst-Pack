/*
    File        : 06_date-time-analysis/02_extracting_date_parts.sql
    Topic       : Date-Time Analysis
    Purpose     : Demonstrates how to extract specific parts (year, month, day, etc.) from date/time values.
    Author      : GitHub Copilot
    Created     : 2025-06-21
    Updated     : 2025-06-21
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    -- Most systems support `EXTRACT`, but many also have their own dedicated functions (e.g., `YEAR()`, `MONTH()`).
    -- SQLite uses `strftime` for all date/time manipulation.
    Notes       : • Extracting date parts is fundamental for time-based reporting and aggregation.
*/

-- =============================================================================
-- Scenario: Analyze monthly and yearly sales trends.
-- =============================================================================
-- To do this, we need to extract the year and month from the `InvoiceDate`.

-- -----------------------------------------------------------------------------
-- Method 1: Using the standard `EXTRACT` function
-- -----------------------------------------------------------------------------
-- `EXTRACT` is the ANSI SQL standard for this operation.
-- Supported by PostgreSQL, MySQL, Oracle, BigQuery, Snowflake.

SELECT
    InvoiceDate,
    EXTRACT(YEAR FROM InvoiceDate) AS SalesYear,
    EXTRACT(MONTH FROM InvoiceDate) AS SalesMonth,
    EXTRACT(DAY FROM InvoiceDate) AS SalesDay,
    EXTRACT(QUARTER FROM InvoiceDate) AS SalesQuarter,
    EXTRACT(DOW FROM InvoiceDate) AS DayOfWeek -- 0=Sunday, 1=Monday... (PostgreSQL specific)
FROM Invoice
LIMIT 10;

-- -----------------------------------------------------------------------------
-- Method 2: Using specific date part functions
-- -----------------------------------------------------------------------------
-- Many database systems provide simpler, more readable functions.
-- Supported by MySQL, SQL Server.

-- MySQL Example:
-- SELECT
--     InvoiceDate,
--     YEAR(InvoiceDate) AS SalesYear,
--     MONTH(InvoiceDate) AS SalesMonth,
--     DAY(InvoiceDate) AS SalesDay,
--     QUARTER(InvoiceDate) AS SalesQuarter,
--     DAYOFWEEK(InvoiceDate) AS DayOfWeek -- 1=Sunday, 2=Monday...
-- FROM Invoice
-- LIMIT 10;

-- SQL Server Example:
-- SELECT TOP 10
--     InvoiceDate,
--     YEAR(InvoiceDate) AS SalesYear,
--     MONTH(InvoiceDate) AS SalesMonth,
--     DAY(InvoiceDate) AS SalesDay,
--     DATEPART(quarter, InvoiceDate) AS SalesQuarter,
--     DATEPART(weekday, InvoiceDate) AS DayOfWeek
-- FROM Invoice;

-- -----------------------------------------------------------------------------
-- Method 3: Using `strftime` in SQLite
-- -----------------------------------------------------------------------------
-- SQLite has a powerful `strftime` function that can format dates in almost any way.

-- SELECT
--     InvoiceDate,
--     strftime('%Y', InvoiceDate) AS SalesYear,
--     strftime('%m', InvoiceDate) AS SalesMonth,
--     strftime('%d', InvoiceDate) AS SalesDay,
--     strftime('%w', InvoiceDate) AS DayOfWeek -- 0=Sunday, 1=Monday...
-- FROM Invoice
-- LIMIT 10;

-- =============================================================================
-- Practical Application: Aggregating Sales by Year and Month
-- =============================================================================
-- Now we can use these functions to group our sales data.

SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS SalesYear,
    EXTRACT(MONTH FROM InvoiceDate) AS SalesMonth,
    COUNT(InvoiceId) AS NumberOfInvoices,
    SUM(Total) AS TotalSales
FROM Invoice
GROUP BY SalesYear, SalesMonth
ORDER BY SalesYear, SalesMonth;
