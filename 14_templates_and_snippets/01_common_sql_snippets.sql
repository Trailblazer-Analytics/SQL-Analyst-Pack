-- File: 14_templates_and_snippets/01_common_sql_snippets.sql
-- Topic: Common SQL Snippets and Templates
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script serves as a repository of common, reusable SQL snippets for frequent
-- analytical tasks. These templates can be adapted for various scenarios.

-- Prerequisites:
-- Knowledge of window functions, CTEs, and basic aggregations is helpful to fully
-- understand and adapt these snippets.

-- Dialect Compatibility:
-- Most snippets use window functions, which are available in modern SQL dialects like
-- PostgreSQL, SQL Server, Oracle, MySQL 8.0+, and SQLite 3.25+.
-- Notes are provided for any significant variations.

---------------------------------------------------------------------------------------------------

-- Snippet 1: Find the Top N Records Per Group

-- Use Case: Find the top 3 best-selling tracks in each genre.
-- Technique: Use the `ROW_NUMBER()` window function partitioned by the group.

WITH RankedTracks AS (
    SELECT
        g.Name AS Genre,
        t.Name AS TrackName,
        SUM(ii.Quantity) AS UnitsSold,
        ROW_NUMBER() OVER(PARTITION BY g.Name ORDER BY SUM(ii.Quantity) DESC) as Rank
    FROM
        genres g
    JOIN
        tracks t ON g.GenreId = t.GenreId
    JOIN
        invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY
        g.Name, t.Name
)
SELECT
    Genre,
    TrackName,
    UnitsSold
FROM
    RankedTracks
WHERE
    Rank <= 3
ORDER BY
    Genre, UnitsSold DESC;

---------------------------------------------------------------------------------------------------

-- Snippet 2: Calculate Running Totals

-- Use Case: Calculate the cumulative monthly revenue over the entire history of the store.
-- Technique: Use `SUM() OVER()` with an `ORDER BY` clause to create a cumulative sum.

WITH MonthlyRevenue AS (
    SELECT
        DATE(InvoiceDate, 'start of month') AS InvoiceMonth,
        SUM(Total) AS MonthlyTotal
    FROM
        invoices
    GROUP BY
        InvoiceMonth
)
SELECT
    InvoiceMonth,
    MonthlyTotal,
    SUM(MonthlyTotal) OVER (ORDER BY InvoiceMonth) AS RunningTotalRevenue
FROM
    MonthlyRevenue
ORDER BY
    InvoiceMonth;

---------------------------------------------------------------------------------------------------

-- Snippet 3: Pivot Data (Conditional Aggregation)

-- Use Case: Show total sales for each country, with a separate column for each year.
-- Technique: Use an aggregate function (`SUM`) with a `CASE` statement for each column you want to create.

SELECT
    BillingCountry,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2009' THEN Total ELSE 0 END) AS Sales_2009,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2010' THEN Total ELSE 0 END) AS Sales_2010,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2011' THEN Total ELSE 0 END) AS Sales_2011,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2012' THEN Total ELSE 0 END) AS Sales_2012,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    BillingCountry
ORDER BY
    TotalSales DESC;

-- Note on Date Functions:
-- `STRFTIME('%Y', ...)` is for SQLite/MySQL. 
-- PostgreSQL: `EXTRACT(YEAR FROM ...)`
-- SQL Server: `YEAR(...)`

---------------------------------------------------------------------------------------------------

-- Snippet 4: Find the First and Last Event for Each User

-- Use Case: Find the date of the first and last purchase for each customer.
-- Technique: Use `MIN()` and `MAX()` aggregate functions grouped by the user.

SELECT
    CustomerId,
    MIN(InvoiceDate) AS FirstPurchaseDate,
    MAX(InvoiceDate) AS LastPurchaseDate
FROM
    invoices
GROUP BY
    CustomerId
ORDER BY
    CustomerId;

---------------------------------------------------------------------------------------------------

-- Snippet 5: Generate a Date Series (Recursive CTE)

-- Use Case: Create a complete list of dates for a given month, useful for filling gaps in time-series data.
-- Technique: Use a recursive CTE to generate a series of dates.

-- SQLite / PostgreSQL / SQL Server / MySQL 8.0+
WITH RECURSIVE DateSeries(Date) AS (
    -- Anchor: Start of the series
    SELECT '2023-01-01'
    UNION ALL
    -- Recursive part: Add one day until the end condition is met
    SELECT DATE(Date, '+1 day')
    FROM DateSeries
    WHERE Date < '2023-01-31'
)
SELECT Date FROM DateSeries;

-- Note on Date Functions:
-- `DATE(Date, '+1 day')` is SQLite syntax.
-- PostgreSQL: `Date + INTERVAL '1 day'`
-- SQL Server: `DATEADD(day, 1, Date)`

---------------------------------------------------------------------------------------------------

-- Snippet 6: Calculating Session-like Data

-- Use Case: Group customer purchases into "sessions" where each session is defined as a series of
-- purchases made within 24 hours of the previous one.
-- Technique: Use `LAG` to find the time since the last purchase and a cumulative `SUM` to create a session ID.

WITH PurchaseGaps AS (
    SELECT
        CustomerId,
        InvoiceDate,
        -- Calculate hours since last purchase for this customer
        (JULIANDAY(InvoiceDate) - JULIANDAY(LAG(InvoiceDate, 1, InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate))) * 24 AS HoursSinceLastPurchase
    FROM
        invoices
),
SessionIdentifier AS (
    SELECT
        CustomerId,
        InvoiceDate,
        -- If the gap is > 24 hours, it's a new session. Create a flag.
        CASE WHEN HoursSinceLastPurchase > 24 THEN 1 ELSE 0 END AS IsNewSession
    FROM
        PurchaseGaps
)
SELECT
    CustomerId,
    InvoiceDate,
    -- The session ID is the cumulative sum of the IsNewSession flags.
    SUM(IsNewSession) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS SessionId
FROM
    SessionIdentifier
ORDER BY
    CustomerId, InvoiceDate;

-- Note on Date Functions:
-- `JULIANDAY` is SQLite-specific. Use `EXTRACT(EPOCH FROM ...)` in PostgreSQL or `DATEDIFF` in SQL Server.

---------------------------------------------------------------------------------------------------

-- Snippet 7: Calculate Customer Lifetime Value (CLV)

-- Use Case: Calculate total revenue, average order value, and purchase frequency per customer.
-- Technique: Combine multiple aggregations to create a comprehensive customer analysis.

SELECT
    c.CustomerId,
    c.FirstName,
    c.LastName,
    c.Country,
    COUNT(DISTINCT i.InvoiceId) AS TotalOrders,
    SUM(i.Total) AS TotalRevenue,
    AVG(i.Total) AS AverageOrderValue,
    MIN(i.InvoiceDate) AS FirstPurchaseDate,
    MAX(i.InvoiceDate) AS LastPurchaseDate,
    -- Calculate days between first and last purchase
    CASE 
        WHEN COUNT(DISTINCT i.InvoiceId) > 1 
        THEN (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)))
        ELSE 0 
    END AS CustomerLifespanDays,
    -- Calculate purchase frequency (orders per year)
    CASE 
        WHEN COUNT(DISTINCT i.InvoiceId) > 1 AND 
             (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate))) > 0
        THEN (COUNT(DISTINCT i.InvoiceId) * 365.0) / 
             (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)))
        ELSE COUNT(DISTINCT i.InvoiceId)
    END AS OrdersPerYear
FROM
    customers c
LEFT JOIN
    invoices i ON c.CustomerId = i.CustomerId
GROUP BY
    c.CustomerId, c.FirstName, c.LastName, c.Country
HAVING
    COUNT(DISTINCT i.InvoiceId) > 0  -- Only customers with purchases
ORDER BY
    TotalRevenue DESC;

-- This comprehensive customer analysis helps identify:
-- - High-value customers (by total revenue)
-- - Frequent buyers (by orders per year)
-- - Recent vs. long-term customers (by purchase dates)
-- - Geographic patterns (by country)
