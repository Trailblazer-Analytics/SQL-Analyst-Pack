/*
    File: 02_time_based_aggregations.sql
    Topic: Data Aggregation
    Task: Time-Based Aggregations
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Time-Based Aggregations
-- =================================================================================================================================
--
-- Analyzing data over time is a common requirement in business intelligence and data analysis. Time-based aggregations
-- allow us to summarize data by different time periods, such as day, week, month, quarter, or year. This helps in
-- identifying trends, seasonality, and patterns.
--
-- To perform time-based aggregations, you need a column with a date or timestamp data type. We will use the
-- `InvoiceDate` column from the `invoices` table.
--
-- Key techniques involve:
-- 1. **Extracting Date Parts**: Pulling out specific parts of a date (like the year or month) to group by.
-- 2. **Truncating Dates**: Rounding a date down to the beginning of a specific interval (like the start of the week or month).
--
-- =================================================================================================================================
-- Step 1: Extracting Date Parts for Aggregation
-- =================================================================================================================================
--
-- Most SQL dialects provide functions to extract specific components from a date/timestamp value.
-- The ANSI SQL standard function is `EXTRACT(part FROM date_column)`.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Calculate total sales for each year
-- ---------------------------------------------------------------------------------------------------------------------------------
-- We extract the year from `InvoiceDate` and group by it.

SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS SalesYear,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    SalesYear
ORDER BY
    SalesYear;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Calculate total sales for each year and month
-- ---------------------------------------------------------------------------------------------------------------------------------
-- We can group by multiple date parts to get a more granular view.

SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS SalesYear,
    EXTRACT(MONTH FROM InvoiceDate) AS SalesMonth,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    SalesYear, SalesMonth
ORDER BY
    SalesYear, SalesMonth;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Flavor-Specific Functions for Date Parts
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Many databases have their own, often more concise, functions.
--
-- **SQL Server**: `YEAR(date)`, `MONTH(date)`, `DAY(date)`
-- **MySQL**: `YEAR(date)`, `MONTH(date)`, `DAY(date)`
-- **PostgreSQL**: `EXTRACT` or `date_part('year', date)`
-- **SQLite**: `strftime('%Y', date)`, `strftime('%m', date)`

-- Example using SQLite syntax:
SELECT
    strftime('%Y', InvoiceDate) AS SalesYear,
    strftime('%m', InvoiceDate) AS SalesMonth,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    SalesYear, SalesMonth
ORDER BY
    SalesYear, SalesMonth;

-- =================================================================================================================================
-- Step 2: Truncating Dates for Aggregation
-- =================================================================================================================================
--
-- Sometimes, instead of just extracting a part, you want to group by a consistent time interval, like the beginning of the week
-- or the start of the month. The `DATE_TRUNC` function (available in PostgreSQL and BigQuery) is excellent for this.
-- For other databases, you have to use date arithmetic to achieve the same result.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Calculate total sales by month (using date truncation)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- `DATE_TRUNC('month', ...)` will convert any date (e.g., '2023-10-15', '2023-10-27') to the first day of that month ('2023-10-01').
-- This makes grouping by month very clean.

-- PostgreSQL / BigQuery Syntax:
/*
SELECT
    DATE_TRUNC('month', InvoiceDate)::DATE AS SalesMonth,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    SalesMonth
ORDER BY
    SalesMonth;
*/

-- Simulating DATE_TRUNC in SQLite:
-- We format the date to 'YYYY-MM-01' to achieve the same grouping effect.
SELECT
    strftime('%Y-%m-01', InvoiceDate) AS SalesMonth,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    SalesMonth
ORDER BY
    SalesMonth;

-- Simulating DATE_TRUNC in SQL Server:
/*
SELECT
    DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1) AS SalesMonth,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1)
ORDER BY
    SalesMonth;
*/

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. How many invoices were there on each day of the week?
--    Display the day of the week (e.g., Sunday, Monday) and the count of invoices.
--    Hint: For SQLite, `strftime('%w', date)` gives the day of the week (0=Sunday, 6=Saturday).
SELECT
    CASE strftime('%w', InvoiceDate)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS DayOfWeek,
    COUNT(InvoiceId) AS NumberOfInvoices
FROM
    invoices
GROUP BY
    DayOfWeek
ORDER BY
    strftime('%w', InvoiceDate);

-- 2. What were the total sales for each quarter of each year?
--    Hint: For SQLite, `strftime('%m', date)` can be used with a CASE statement to determine the quarter.
SELECT
    strftime('%Y', InvoiceDate) AS SalesYear,
    CASE
        WHEN CAST(strftime('%m', InvoiceDate) AS INTEGER) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN CAST(strftime('%m', InvoiceDate) AS INTEGER) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN CAST(strftime('%m', InvoiceDate) AS INTEGER) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS SalesQuarter,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    SalesYear, SalesQuarter
ORDER BY
    SalesYear, SalesQuarter;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Time-based aggregation is essential for trend analysis. By using date functions to extract parts or truncate dates,
-- you can effectively group your data into meaningful time periods.
--
-- - Use `EXTRACT` or flavor-specific functions (`YEAR`, `MONTH`, `strftime`) to group by date components.
-- - Use `DATE_TRUNC` or its equivalent to group by consistent time intervals (like the start of a month or week).
--
-- This allows you to answer questions like "How did our sales perform month-over-month?" or "Is there a weekly pattern to our business?"
--
-- =================================================================================================================================
