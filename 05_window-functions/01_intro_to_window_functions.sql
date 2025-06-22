/*
    Script: 01_intro_to_window_functions.sql
    Description: This script provides an introduction to window functions.
    Author: Your Name/Team
    Version: 1.0
    Last-Modified: 2023-10-27
*/

-- =================================================================================================================================
-- Introduction to Window Functions
-- =================================================================================================================================
--
-- Window functions are a powerful feature in SQL that perform calculations across a set of table rows that are somehow
-- related to the current row. This set of rows is called the "window" or "window frame".
--
-- Unlike aggregate functions (`SUM`, `COUNT`, etc.) which collapse rows into a single output row, window functions
-- return a value for *every single row*. This allows you to see both the individual row's data and the result of the
-- window function in the same query.
--
-- The key syntax is the `OVER()` clause, which defines the window.
-- The `OVER()` clause has three main components:
-- 1. `PARTITION BY`: Divides the rows into partitions (groups). The window function is applied independently to each partition.
--    (e.g., `PARTITION BY Country` would create a separate window for each country).
-- 2. `ORDER BY`: Orders the rows within each partition. This is crucial for functions that depend on order, like running totals or rankings.
-- 3. `ROWS` or `RANGE`: Specifies the window frame within a partition (e.g., 'the current row and the 2 preceding rows').
--
-- =================================================================================================================================
-- Step 1: A Simple Window Function without PARTITION BY
-- =================================================================================================================================
--
-- When used without `PARTITION BY`, the window function operates over the entire result set.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Show each invoice total along with the average invoice total for the entire dataset
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Here, `AVG(Total) OVER ()` calculates the average of `Total` across all rows and attaches that same value to every row.

SELECT
    InvoiceDate,
    BillingCountry,
    Total AS InvoiceTotal,
    AVG(Total) OVER () AS AverageOfAllInvoices
FROM
    invoices;

-- =================================================================================================================================
-- Step 2: Using `PARTITION BY` to Define Windows
-- =================================================================================================================================
--
-- `PARTITION BY` is similar to `GROUP BY` but it doesn't collapse the rows. It defines the groups over which the
-- window function will be calculated separately.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Show each invoice total along with the average invoice total *for its country*
-- ---------------------------------------------------------------------------------------------------------------------------------
-- `PARTITION BY BillingCountry` tells the `AVG()` function to calculate the average for each country independently.

SELECT
    InvoiceDate,
    BillingCountry,
    Total AS InvoiceTotal,
    AVG(Total) OVER (PARTITION BY BillingCountry) AS AverageInvoiceForCountry
FROM
    invoices
ORDER BY
    BillingCountry, InvoiceDate;

-- =================================================================================================================================
-- Step 3: Using `ORDER BY` for Cumulative Calculations
-- =================================================================================================================================
--
-- When you add `ORDER BY` inside the `OVER()` clause, the window function can perform cumulative calculations, like a running total.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Calculate a running total of sales over time
-- ---------------------------------------------------------------------------------------------------------------------------------
-- `ORDER BY InvoiceDate` tells the `SUM()` function to sum the `Total` for the current row and all preceding rows based on the date.

SELECT
    InvoiceDate,
    Total AS InvoiceTotal,
    SUM(Total) OVER (ORDER BY InvoiceDate) AS RunningTotalSales
FROM
    invoices;

-- =================================================================================================================================
-- Step 4: Combining `PARTITION BY` and `ORDER BY`
-- =================================================================================================================================
--
-- This is the most common and powerful use case. You partition the data into groups and then perform an ordered calculation within each group.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Calculate a running total of sales *for each country*
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The running total will start over for each new country.

SELECT
    InvoiceDate,
    BillingCountry,
    Total AS InvoiceTotal,
    SUM(Total) OVER (PARTITION BY BillingCountry ORDER BY InvoiceDate) AS RunningTotalByCountry
FROM
    invoices
ORDER BY
    BillingCountry, InvoiceDate;

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. For each track, show its name, its price, and the average price of all tracks in its genre.
SELECT
    t.Name AS TrackName,
    g.Name AS GenreName,
    t.UnitPrice,
    AVG(t.UnitPrice) OVER (PARTITION BY g.Name) AS AvgPriceForGenre
FROM
    tracks t
JOIN
    genres g ON t.GenreId = g.GenreId;

-- 2. For each customer, show their invoices and a cumulative spending total over time.
SELECT
    c.FirstName || ' ' || c.LastName AS CustomerName,
    i.InvoiceDate,
    i.Total,
    SUM(i.Total) OVER (PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) AS CustomerRunningTotal
FROM
    customers c
JOIN
    invoices i ON c.CustomerId = i.CustomerId
ORDER BY
    CustomerName, i.InvoiceDate;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Window functions are a fundamental tool for advanced SQL analysis. They allow you to perform complex calculations
-- like running totals, moving averages, and rankings without collapsing rows.
--
-- - `OVER()` is the keyword that initiates a window function.
-- - `PARTITION BY` defines the groups.
-- - `ORDER BY` defines the order within the groups, which is essential for cumulative calculations.
--
-- In the next scripts, we will explore specific types of window functions like ranking and offset functions.
--
-- =================================================================================================================================
