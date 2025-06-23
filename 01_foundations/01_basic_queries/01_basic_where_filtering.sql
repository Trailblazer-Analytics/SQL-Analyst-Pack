/*
    File        : 01_foundations/01_basic_queries/01_basic_where_filtering.sql
    Topic       : Basic WHERE Clause Filtering
    Purpose     : Master data filtering techniques using real-world music store examples
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-22
    Updated     : 2025-06-23
    Database    : Chinook Music Store
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery
    
    Prerequisites:
    - Chinook sample database loaded
    - Basic understanding of SELECT statements
    
    What You'll Learn:
    - Filter rows with single conditions
    - Combine conditions with AND, OR, NOT
    - Use IN and BETWEEN for efficient filtering
    - Handle NULL values properly
    - Apply best practices for readable queries
*/

-- =================================================================================
-- SECTION 1: BASIC FILTERING WITH WHERE
-- =================================================================================

-- Let's start by exploring the data without any filters
-- This shows all customers in the database
SELECT CustomerId, FirstName, LastName, Country, Email
FROM Customer
LIMIT 10;  -- LIMIT 10 to see just the first 10 rows

-- Now let's filter for customers from a specific country
-- This is the most basic WHERE clause - single condition
SELECT CustomerId, FirstName, LastName, Country, Email
FROM Customer
WHERE Country = 'Canada';

-- Real-world insight: This query helps us understand our Canadian market
-- Business question: "How many customers do we have in Canada?"

-- =================================================================================
-- SECTION 2: COMPARISON OPERATORS
-- =================================================================================

-- Find invoices with high values (greater than $10)
SELECT InvoiceId, CustomerId, InvoiceDate, Total
FROM Invoice
WHERE Total > 10.00
ORDER BY Total DESC;  -- Show highest amounts first

-- Find tracks that are shorter than 2 minutes (120,000 milliseconds)
SELECT TrackId, Name, Milliseconds, 
       ROUND(Milliseconds / 60000.0, 2) AS Minutes
FROM Track
WHERE Milliseconds < 120000
ORDER BY Milliseconds;

-- Find albums released in or after 2000 (using >= operator)
-- Note: Some albums may not have release years, so we also check for NULL
SELECT AlbumId, Title, ArtistId
FROM Album
WHERE AlbumId >= 200  -- Using AlbumId as a proxy for newer albums
LIMIT 20;

-- =================================================================================
-- SECTION 3: COMBINING CONDITIONS WITH AND & OR
-- =================================================================================

-- Find customers from North America (USA or Canada) - using OR
SELECT CustomerId, FirstName, LastName, Country
FROM Customer
WHERE Country = 'USA' OR Country = 'Canada'
ORDER BY Country, LastName;

-- Business insight: This helps us analyze our North American customer base

-- Find expensive long tracks (price > $1 AND duration > 5 minutes) - using AND
SELECT t.TrackId, t.Name, t.UnitPrice, 
       ROUND(t.Milliseconds / 60000.0, 2) AS Minutes
FROM Track t
WHERE t.UnitPrice > 1.00 AND t.Milliseconds > 300000  -- 5 minutes = 300,000 ms
ORDER BY t.UnitPrice DESC, Minutes DESC;

-- Find customers from specific European countries with proper grouping
SELECT CustomerId, FirstName, LastName, Country, City
FROM Customer
WHERE (Country = 'Germany' OR Country = 'France' OR Country = 'United Kingdom')
  AND City IS NOT NULL  -- Exclude customers without city information
ORDER BY Country, City;

-- =================================================================================
-- SECTION 4: USING IN FOR MULTIPLE VALUES
-- =================================================================================

-- The previous query can be written more elegantly with IN
SELECT CustomerId, FirstName, LastName, Country, City
FROM Customer
WHERE Country IN ('Germany', 'France', 'United Kingdom')
  AND City IS NOT NULL
ORDER BY Country, City;

-- Find tracks in specific genres - using IN with subquery
SELECT t.TrackId, t.Name, g.Name AS Genre
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
WHERE g.Name IN ('Rock', 'Jazz', 'Blues', 'Classical')
ORDER BY g.Name, t.Name;

-- =================================================================================
-- SECTION 5: RANGE FILTERING WITH BETWEEN
-- =================================================================================

-- Find invoices from a specific date range
SELECT InvoiceId, CustomerId, InvoiceDate, Total
FROM Invoice
WHERE InvoiceDate BETWEEN '2009-01-01' AND '2009-12-31'
ORDER BY InvoiceDate;

-- Find medium-priced tracks (between $0.99 and $1.99)
SELECT TrackId, Name, UnitPrice
FROM Track
WHERE UnitPrice BETWEEN 0.99 AND 1.99
ORDER BY UnitPrice, Name;

-- BETWEEN is inclusive - includes both boundary values
-- Alternative way to write the same query:
SELECT TrackId, Name, UnitPrice
FROM Track
WHERE UnitPrice >= 0.99 AND UnitPrice <= 1.99
ORDER BY UnitPrice, Name;

-- =================================================================================
-- SECTION 6: HANDLING NULL VALUES
-- =================================================================================

-- Find customers who have provided a company name
SELECT CustomerId, FirstName, LastName, Company
FROM Customer
WHERE Company IS NOT NULL
ORDER BY Company;

-- Find customers without a company (individual customers)
SELECT CustomerId, FirstName, LastName, Company
FROM Customer
WHERE Company IS NULL
ORDER BY LastName;

-- Important: Use IS NULL and IS NOT NULL, never = NULL or != NULL
-- This is incorrect and won't work: WHERE Company = NULL

-- =================================================================================
-- SECTION 7: USING NOT TO EXCLUDE DATA
-- =================================================================================

-- Find all customers NOT from the USA
SELECT CustomerId, FirstName, LastName, Country
FROM Customer
WHERE NOT Country = 'USA'
-- OR equivalently: WHERE Country != 'USA' OR WHERE Country <> 'USA'
ORDER BY Country, LastName;

-- Find tracks NOT in Rock or Pop genres
SELECT t.TrackId, t.Name, g.Name AS Genre
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
WHERE g.Name NOT IN ('Rock', 'Pop')
ORDER BY g.Name, t.Name;

-- =================================================================================
-- SECTION 8: REAL-WORLD BUSINESS SCENARIOS
-- =================================================================================

-- Business Question: "Find all high-value customers from English-speaking countries"
SELECT c.CustomerId, c.FirstName, c.LastName, c.Country, 
       SUM(i.Total) AS TotalSpent
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
WHERE c.Country IN ('USA', 'Canada', 'United Kingdom', 'Australia')
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
HAVING SUM(i.Total) > 30  -- High-value threshold
ORDER BY TotalSpent DESC;

-- Business Question: "Find recent purchases of expensive items"
SELECT i.InvoiceId, c.FirstName, c.LastName, i.InvoiceDate, i.Total
FROM Invoice i
JOIN Customer c ON i.CustomerId = c.CustomerId
WHERE i.InvoiceDate >= '2013-01-01'  -- Recent purchases
  AND i.Total > 15.00  -- Expensive purchases
ORDER BY i.InvoiceDate DESC, i.Total DESC;

-- =================================================================================
-- PRACTICE EXERCISES
-- =================================================================================

-- Try these queries on your own:

-- Exercise 1: Find all albums by artists whose name starts with 'A'
-- Hint: You'll need to join Album and Artist tables

-- Exercise 2: Find invoices from 2012 with totals between $5 and $15
-- Hint: Use BETWEEN for the total and date filtering for the year

-- Exercise 3: Find customers from countries that start with 'B'
-- Hint: Use LIKE with a wildcard pattern

-- Exercise 4: Find tracks longer than 4 minutes that cost less than $1
-- Hint: Convert milliseconds to minutes and use multiple conditions

-- =================================================================================
-- KEY TAKEAWAYS
-- =================================================================================

/*
🎯 WHERE Clause Best Practices:

1. Always use proper comparison operators (=, >, <, >=, <=, !=)
2. Use IS NULL and IS NOT NULL for null value checks
3. Use IN for multiple value comparisons instead of multiple OR conditions
4. Use BETWEEN for range queries (it's inclusive of both boundaries)
5. Use parentheses to group complex conditions clearly
6. Consider performance - filter on indexed columns when possible

🔍 Common Mistakes to Avoid:

❌ WHERE column = NULL          → ✅ WHERE column IS NULL
❌ WHERE date = '2023'          → ✅ WHERE date BETWEEN '2023-01-01' AND '2023-12-31'
❌ WHERE column = 'A' OR 'B'    → ✅ WHERE column IN ('A', 'B')

💡 Real-World Applications:

- Customer segmentation (country, purchase behavior)
- Product filtering (price ranges, categories)
- Date-based reporting (quarters, years, specific periods)
- Quality control (exclude incomplete or invalid records)
*/
