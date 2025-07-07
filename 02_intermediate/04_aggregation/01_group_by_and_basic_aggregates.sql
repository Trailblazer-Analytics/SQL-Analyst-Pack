/*
    File: 01_group_by_and_basic_aggregates.sql
    Topic: Data Aggregation
    Task: GROUP BY and Basic Aggregate Functions
    Author: SQL Analyst Pack Community
    Date: 2024-07-15
    SQL Flavor: ANSI SQL
*/

-- =================================================================================================================================
-- Introduction to Data Aggregation
-- =================================================================================================================================
--
-- Data aggregation is the process of summarizing data. Instead of looking at individual rows, we often want to see
-- statistics, totals, or other summary metrics for groups of rows. This is one of the most common tasks in data analysis.
--
-- The cornerstone of aggregation in SQL is the `GROUP BY` clause, which groups rows that have the same values in
-- specified columns into summary rows. We then use aggregate functions to perform a calculation on each group.
--
-- Key Aggregate Functions:
-- - `COUNT()`: Counts the number of rows.
-- - `SUM()`: Calculates the sum of a set of values.
-- - `AVG()`: Calculates the average of a set of values.
-- - `MIN()`: Finds the minimum value in a set.
-- - `MAX()`: Finds the maximum value in a set.
--
-- =================================================================================================================================
-- Step 1: The `GROUP BY` Clause
-- =================================================================================================================================
--
-- The `GROUP BY` clause is used with a `SELECT` statement to collect data across multiple records and group it by one or more columns.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Count the number of albums for each artist
-- ---------------------------------------------------------------------------------------------------------------------------------
-- We group the `albums` table by `ArtistId` and then use `COUNT(*)` to count the number of albums in each group.

SELECT
    ArtistId,
    COUNT(*) AS NumberOfAlbums
FROM
    albums
GROUP BY
    ArtistId
ORDER BY
    NumberOfAlbums DESC; -- Order to see which artists have the most albums

-- To make this more readable, we can join to the `artists` table to get the artist's name.
SELECT
    ar.Name AS ArtistName,
    COUNT(al.AlbumId) AS NumberOfAlbums
FROM
    artists ar
JOIN
    albums al ON ar.ArtistId = al.ArtistId
GROUP BY
    ar.Name -- Group by the artist's name
ORDER BY
    NumberOfAlbums DESC;

-- =================================================================================================================================
-- Step 2: Using Various Aggregate Functions
-- =================================================================================================================================
--
-- You can use multiple aggregate functions in the same query to get a comprehensive summary of your groups.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Get sales statistics for each country
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's analyze the `invoices` table to see sales performance by country.

SELECT
    BillingCountry,
    COUNT(InvoiceId) AS NumberOfInvoices, -- Total number of invoices (transactions)
    SUM(Total) AS TotalSales,             -- Sum of all invoice totals
    AVG(Total) AS AverageInvoiceValue,    -- Average value per invoice
    MIN(Total) AS SmallestInvoice,        -- The smallest invoice amount
    MAX(Total) AS LargestInvoice          -- The largest invoice amount
FROM
    invoices
GROUP BY
    BillingCountry
ORDER BY
    TotalSales DESC;

-- =================================================================================================================================
-- Step 3: The `HAVING` Clause - Filtering After Aggregation
-- =================================================================================================================================
--
-- The `WHERE` clause is used to filter rows *before* they are grouped and aggregated.
-- The `HAVING` clause is used to filter groups *after* they have been aggregated.
--
-- You cannot use an aggregate function in a `WHERE` clause. You must use it in a `HAVING` clause.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Find countries with more than $100 in total sales
-- ---------------------------------------------------------------------------------------------------------------------------------
-- We first calculate the total sales for each country, then use `HAVING` to keep only those countries where the sum is greater than 100.

SELECT
    BillingCountry,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    BillingCountry
HAVING
    SUM(Total) > 100 -- Filter on the result of the aggregate function
ORDER BY
    TotalSales DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Find artists who have released more than 10 albums
-- ---------------------------------------------------------------------------------------------------------------------------------
SELECT
    ar.Name AS ArtistName,
    COUNT(al.AlbumId) AS NumberOfAlbums
FROM
    artists ar
JOIN
    albums al ON ar.ArtistId = al.ArtistId
GROUP BY
    ar.Name
HAVING
    COUNT(al.AlbumId) > 10
ORDER BY
    NumberOfAlbums DESC;

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. How many customers does each sales support representative have?
--    Display the employee's full name and the number of customers they support.
SELECT
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    COUNT(c.CustomerId) AS NumberOfCustomers
FROM
    employees e
JOIN
    customers c ON e.EmployeeId = c.SupportRepId
GROUP BY
    EmployeeName
ORDER BY
    NumberOfCustomers DESC;

-- 2. What is the total value of sales for each genre?
--    Display the genre name and the total sales. Order by the highest-selling genre.
SELECT
    g.Name AS GenreName,
    SUM(ii.UnitPrice * ii.Quantity) AS TotalSales
FROM
    genres g
JOIN
    tracks t ON g.GenreId = t.GenreId
JOIN
    invoice_items ii ON t.TrackId = ii.TrackId
GROUP BY
    g.Name
ORDER BY
    TotalSales DESC;

-- 3. Which customers have spent more than $40 in total?
--    Display the customer's full name and their total spending.
SELECT
    c.FirstName || ' ' || c.LastName AS CustomerName,
    SUM(i.Total) AS TotalSpent
FROM
    customers c
JOIN
    invoices i ON c.CustomerId = i.CustomerId
GROUP BY
    CustomerName
HAVING
    SUM(i.Total) > 40
ORDER BY
    TotalSpent DESC;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Aggregation is a fundamental skill in SQL for summarizing and understanding data.
-- - `GROUP BY` creates the groups.
-- - `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` calculate summary statistics for those groups.
-- - `HAVING` filters the results based on those summary statistics.
--
-- Mastering these concepts allows you to move from viewing raw data to generating meaningful insights.
--
-- =================================================================================================================================
