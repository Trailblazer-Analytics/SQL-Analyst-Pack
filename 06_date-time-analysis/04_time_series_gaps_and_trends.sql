/*
    File        : 06_date-time-analysis/04_time_series_gaps_and_trends.sql
    Topic       : Date-Time Analysis
    Purpose     : Advanced techniques for finding gaps in a time series and identifying trends.
    Author      : GitHub Copilot
    Created     : 2025-06-21
    Updated     : 2025-06-21
    SQL Flavors : ✅ PostgreSQL | ⚠️ MySQL | ⚠️ SQL Server | ⚠️ Oracle | ⚠️ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    -- Generating a date series is a common task, but the syntax is highly vendor-specific.
    -- PostgreSQL's `generate_series` is shown here as a canonical example.
    Notes       : • This is a more advanced script that often requires temporary tables or CTEs.
*/

-- =============================================================================
-- Scenario 1: Finding Gaps in a Time Series
-- =============================================================================
-- Goal: Identify any days in a specific month where no invoices were generated.
-- This can help spot data issues or business lulls.

-- This technique requires generating a complete series of dates for the desired
-- period and then using a LEFT JOIN to find which dates are missing from our data.

-- Step 1: Generate a complete series of dates (PostgreSQL example).
-- We will generate all dates for January 2010.
WITH DateSeries AS (
    SELECT generate_series('2010-01-01'::date, '2010-01-31'::date, '1 day')::date AS CalendarDate
),
-- Step 2: Summarize our actual invoice data by day.
DailyInvoices AS (
    SELECT CAST(InvoiceDate AS DATE) AS InvoiceDay, COUNT(InvoiceId) AS InvoiceCount
    FROM Invoice
    WHERE InvoiceDate >= '2010-01-01' AND InvoiceDate < '2010-02-01'
    GROUP BY InvoiceDay
)
-- Step 3: LEFT JOIN the complete date series to our actual data.
-- Any date with a NULL in the InvoiceDay column is a gap.
SELECT
    ds.CalendarDate,
    di.InvoiceCount
FROM DateSeries ds
LEFT JOIN DailyInvoices di ON ds.CalendarDate = di.InvoiceDay
WHERE di.InvoiceDay IS NULL; -- This condition finds the gaps

-- Note on other systems:
-- SQL Server: Requires a recursive CTE or a calendar table.
-- MySQL: Requires a recursive CTE or a calendar table.
-- Oracle: Can use `CONNECT BY` to generate series.
-- SQLite: Requires a recursive CTE.


-- =============================================================================
-- Scenario 2: Identifying Trends with LAG()
-- =============================================================================
-- Goal: Compare each month's sales to the previous month's sales to calculate month-over-month growth.

WITH MonthlySales AS (
    SELECT
        -- Use DATE_TRUNC to ensure we group by the start of the month
        DATE_TRUNC('month', InvoiceDate)::date AS SalesMonth,
        SUM(Total) AS TotalSales
    FROM Invoice
    GROUP BY SalesMonth
),
MonthlySalesWithLag AS (
    SELECT
        SalesMonth,
        TotalSales,
        -- The LAG() window function gets the value from a previous row.
        LAG(TotalSales, 1) OVER (ORDER BY SalesMonth) AS PreviousMonthSales
    FROM MonthlySales
)
-- Final calculation
SELECT
    SalesMonth,
    TotalSales,
    PreviousMonthSales,
    (TotalSales - PreviousMonthSales) / PreviousMonthSales * 100.0 AS MoM_Growth_Percentage
FROM MonthlySalesWithLag
ORDER BY SalesMonth;
