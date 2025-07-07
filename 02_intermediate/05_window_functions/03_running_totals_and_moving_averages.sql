/*
    File: 03_running_totals_and_moving_averages.sql
    Topic: Window Functions
    Task: Running Totals and Moving Averages
    Author: SQL Analyst Pack Community
    Date: 2024-07-15
    SQL Flavor: ANSI SQL
*/

-- =================================================================================================================================
-- Introduction to Running Totals and Moving Averages
-- =================================================================================================================================
--
-- Running totals and moving averages are two of the most common applications of window functions in time-series analysis.
-- They help to smooth out short-term fluctuations and highlight longer-term trends or patterns.
--
-- - **Running Total (or Cumulative Sum)**: The sum of a sequence of numbers, which is updated each time a new number is added to the sequence.
--   It shows the total accumulation over time.
--
-- - **Moving Average**: The average of a set of numbers in a sliding window of a fixed size. It helps to smooth out noise
--   and see the underlying trend.
--
-- To define these calculations, we use the `ORDER BY` and the window frame (`ROWS` or `RANGE`) clauses within the `OVER()` clause.
--
-- =================================================================================================================================
-- Step 1: Calculating a Running Total
-- =================================================================================================================================
--
-- A running total is calculated by summing the current value with all the previous values in the ordered partition.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Calculate the cumulative (running) total of sales over time.
-- ---------------------------------------------------------------------------------------------------------------------------------
-- By default, `ORDER BY` in a window function creates a window frame from the start of the partition to the current row.
-- `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` is the full, explicit syntax for a standard running total.

SELECT
    InvoiceDate,
    Total,
    -- This is the shorthand for a running total
    SUM(Total) OVER (ORDER BY InvoiceDate) AS RunningTotal,
    -- This is the full, explicit syntax, which is functionally identical
    SUM(Total) OVER (ORDER BY InvoiceDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal_Explicit
FROM
    invoices
ORDER BY
    InvoiceDate;

-- =================================================================================================================================
-- Step 2: Defining a Window Frame for Moving Averages
-- =================================================================================================================================
--
-- A moving average requires a "sliding window" of a fixed size. We define this using the `ROWS BETWEEN ...` clause.
-- `ROWS BETWEEN N PRECEDING AND CURRENT ROW` defines a window that includes the current row and the N rows before it.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Calculate a 7-day moving average of sales
-- ---------------------------------------------------------------------------------------------------------------------------------
-- First, we need to aggregate sales by day, as the `invoices` table can have multiple invoices on the same day.

WITH DailySales AS (
    SELECT
        CAST(InvoiceDate AS DATE) AS SaleDate,
        SUM(Total) AS DailyTotal
    FROM
        invoices
    GROUP BY
        CAST(InvoiceDate AS DATE)
)
SELECT
    SaleDate,
    DailyTotal,
    -- The window includes the current day and the 6 previous days (7 days total)
    AVG(DailyTotal) OVER (ORDER BY SaleDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS MovingAverage7Day
FROM
    DailySales
ORDER BY
    SaleDate;

-- =================================================================================================================================
-- Step 3: Combining with `PARTITION BY`
-- =================================================================================================================================
--
-- We can combine these calculations with `PARTITION BY` to have them restart for each group.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Calculate a running total of sales for each country
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The running total will reset to 0 for each new country.

SELECT
    BillingCountry,
    InvoiceDate,
    Total,
    SUM(Total) OVER (PARTITION BY BillingCountry ORDER BY InvoiceDate) AS CountryRunningTotal
FROM
    invoices
ORDER BY
    BillingCountry, InvoiceDate;

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. Calculate the cumulative number of customers acquired over time.
--    Hint: Use the `customers` table and their join date (which we can simulate with their first invoice date).
WITH CustomerFirstInvoice AS (
    SELECT
        CustomerId,
        MIN(InvoiceDate) AS FirstInvoiceDate
    FROM
        invoices
    GROUP BY
        CustomerId
)
SELECT
    FirstInvoiceDate,
    COUNT(CustomerId) OVER (ORDER BY FirstInvoiceDate) AS CumulativeCustomers
FROM
    CustomerFirstInvoice
ORDER BY
    FirstInvoiceDate;

-- 2. Calculate a 3-month moving average of sales for the USA.
--    First, aggregate sales by month for the USA, then apply the moving average.
WITH MonthlySalesUSA AS (
    SELECT
        strftime('%Y-%m-01', InvoiceDate) AS SalesMonth,
        SUM(Total) AS MonthlyTotal
    FROM
        invoices
    WHERE
        BillingCountry = 'USA'
    GROUP BY
        SalesMonth
)
SELECT
    SalesMonth,
    MonthlyTotal,
    -- The window is the current month and the 2 previous months
    AVG(MonthlyTotal) OVER (ORDER BY SalesMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAverage3Month
FROM
    MonthlySalesUSA
ORDER BY
    SalesMonth;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Running totals and moving averages are powerful tools for trend analysis.
-- - Use `SUM(...) OVER (ORDER BY ...)` for running totals.
-- - Use `AVG(...) OVER (ORDER BY ... ROWS BETWEEN N PRECEDING AND CURRENT ROW)` for moving averages.
--
-- The window frame clause (`ROWS BETWEEN ...`) gives you precise control over which rows are included in the calculation,
-- enabling sophisticated time-series and sequential analysis.
--
-- =================================================================================================================================
