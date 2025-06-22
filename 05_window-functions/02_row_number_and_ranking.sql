/*
    File: 02_row_number_and_ranking.sql
    Topic: Window Functions
    Task: Ranking Functions - ROW_NUMBER, RANK, DENSE_RANK, NTILE
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL
*/

-- =================================================================================================================================
-- Introduction to Ranking Functions
-- =================================================================================================================================
--
-- Ranking functions are a specialized type of window function used to assign a rank to each row within a partition
-- based on a specified ordering. They are essential for solving a wide range of analytical problems, such as
-- finding the "Top N" items in a category, identifying duplicates, or paginating results.
--
-- The four main ranking functions are:
-- - `ROW_NUMBER()`: Assigns a unique, sequential integer to each row. No two rows will have the same number.
-- - `RANK()`: Assigns a rank based on the `ORDER BY` clause. Ties are given the same rank, and a gap is left in the sequence for the next rank.
-- - `DENSE_RANK()`: Similar to `RANK()`, but if there are ties, no gap is left in the sequence.
-- - `NTILE(n)`: Divides the rows into a specified number of ranked groups (e.g., quartiles, deciles).
--
-- All ranking functions require an `ORDER BY` clause within the `OVER()` clause.
--
-- =================================================================================================================================
-- Step 1: `ROW_NUMBER()` - Assigning a Unique Sequence
-- =================================================================================================================================
--
-- `ROW_NUMBER()` is often used to get the top N records per group or to assign a unique ID to rows for processing.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Find the most recent invoice for each customer
-- ---------------------------------------------------------------------------------------------------------------------------------
-- We partition by customer and order by invoice date descending. The row with `ROW_NUMBER() = 1` is the latest invoice.

WITH NumberedInvoices AS (
    SELECT
        CustomerId,
        InvoiceId,
        InvoiceDate,
        Total,
        ROW_NUMBER() OVER(PARTITION BY CustomerId ORDER BY InvoiceDate DESC) as rn
    FROM
        invoices
)
SELECT
    CustomerId,
    InvoiceId,
    InvoiceDate,
    Total
FROM
    NumberedInvoices
WHERE
    rn = 1; -- Select only the first row for each customer

-- =================================================================================================================================
-- Step 2: `RANK()` and `DENSE_RANK()` - Handling Ties
-- =================================================================================================================================
--
-- Use `RANK()` or `DENSE_RANK()` when you want to see how rows rank against each other, especially when ties are possible.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Rank employees by their hire date
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's see how `RANK()` and `DENSE_RANK()` handle employees who might have been hired on the same day.

SELECT
    FirstName || ' ' || LastName AS EmployeeName,
    HireDate,
    RANK() OVER (ORDER BY HireDate) AS RankValue, -- Skips ranks after a tie (e.g., 1, 2, 2, 4)
    DENSE_RANK() OVER (ORDER BY HireDate) AS DenseRankValue, -- Does not skip ranks (e.g., 1, 2, 2, 3)
    ROW_NUMBER() OVER (ORDER BY HireDate) AS RowNumValue -- Always unique (e.g., 1, 2, 3, 4)
FROM
    employees;

-- =================================================================================================================================
-- Step 3: `NTILE(n)` - Dividing Data into Buckets
-- =================================================================================================================================
--
-- `NTILE(n)` is useful for bucketing data into percentiles, quartiles, etc. For example, you can find the top 25% of your customers by spending.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Group tracks into 4 quartiles based on their price
-- ---------------------------------------------------------------------------------------------------------------------------------
-- `NTILE(4)` will assign a bucket number from 1 to 4 to each track. Quartile 1 will be the most expensive tracks.

SELECT
    Name,
    UnitPrice,
    NTILE(4) OVER (ORDER BY UnitPrice DESC) AS PriceQuartile
FROM
    tracks;

-- We can use this in a subquery to analyze the quartiles.
SELECT
    PriceQuartile,
    COUNT(*) AS NumberOfTracks,
    MIN(UnitPrice) AS MinPriceInQuartile,
    MAX(UnitPrice) AS MaxPriceInQuartile
FROM (
    SELECT
        Name,
        UnitPrice,
        NTILE(4) OVER (ORDER BY UnitPrice DESC) AS PriceQuartile
    FROM
        tracks
) AS TrackQuartiles
GROUP BY
    PriceQuartile
ORDER BY
    PriceQuartile;

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. Find the top 3 longest tracks in each genre.
--    Display the genre name, track name, and its length in milliseconds.
WITH RankedTracks AS (
    SELECT
        g.Name AS GenreName,
        t.Name AS TrackName,
        t.Milliseconds,
        ROW_NUMBER() OVER(PARTITION BY g.Name ORDER BY t.Milliseconds DESC) as rn
    FROM
        tracks t
    JOIN
        genres g ON t.GenreId = g.GenreId
)
SELECT
    GenreName,
    TrackName,
    Milliseconds
FROM
    RankedTracks
WHERE
    rn <= 3;

-- 2. Rank customers within each country based on their total spending.
--    Display the country, customer name, total spending, and their rank.
WITH CustomerSpending AS (
    SELECT
        c.CustomerId,
        c.FirstName || ' ' || c.LastName AS CustomerName,
        c.Country,
        SUM(i.Total) AS TotalSpent
    FROM
        customers c
    JOIN
        invoices i ON c.CustomerId = i.CustomerId
    GROUP BY
        c.CustomerId, CustomerName, c.Country
)
SELECT
    Country,
    CustomerName,
    TotalSpent,
    DENSE_RANK() OVER(PARTITION BY Country ORDER BY TotalSpent DESC) as CustomerRankInCountry
FROM
    CustomerSpending
ORDER BY
    Country, CustomerRankInCountry;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Ranking functions are indispensable for a wide variety of analytical queries.
-- - Use `ROW_NUMBER()` for unique numbering and fetching the Top-N per group.
-- - Use `RANK()` and `DENSE_RANK()` when you need to handle ties in rankings.
-- - Use `NTILE(n)` to segment your data into ranked buckets for analysis.
--
-- Mastering these functions will significantly enhance your ability to extract deep insights from your data.
--
-- =================================================================================================================================
