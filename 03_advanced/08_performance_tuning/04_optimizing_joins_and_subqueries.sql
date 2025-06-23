/*
    File        : 08_performance-tuning/04_optimizing_joins_and_subqueries.sql
    Topic       : Performance Tuning
    Purpose     : Provides strategies for optimizing JOINs and rewriting subqueries for better performance.
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-21
    Updated     : 2025-06-23
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery | ✅ Snowflake
    Notes       : • Modern query optimizers are very smart, but these patterns are still good practice.
                • The performance difference is most noticeable on very large datasets.
*/

-- =============================================================================
-- Subqueries vs. JOINs
-- =============================================================================
-- While subqueries can be convenient, they can sometimes be less efficient than a JOIN.
-- A JOIN can often provide the database with more information to create an optimal execution plan.

-- -----------------------------------------------------------------------------
-- Scenario 1: Using a JOIN instead of a subquery in the WHERE clause.
-- -----------------------------------------------------------------------------
-- Goal: Find all tracks belonging to the band "U2".

-- **Method 1: Using a Subquery**
-- This is often readable, but can be less performant on older database systems.
EXPLAIN SELECT
    TrackId,
    Name
FROM Track
WHERE AlbumId IN (SELECT AlbumId FROM Album WHERE ArtistId = (SELECT ArtistId FROM Artist WHERE Name = 'U2'));

-- **Method 2: Using JOINs**
-- This is generally the preferred method. It clearly expresses the relationships
-- between the tables and allows the optimizer to choose the best join strategy.
EXPLAIN SELECT
    t.TrackId,
    t.Name
FROM Track AS t
JOIN Album AS a ON t.AlbumId = a.AlbumId
JOIN Artist AS ar ON a.ArtistId = ar.ArtistId
WHERE ar.Name = 'U2';


-- -----------------------------------------------------------------------------
-- Scenario 2: Avoiding Correlated Subqueries
-- -----------------------------------------------------------------------------
-- A correlated subquery is a subquery that depends on the outer query for its values.
-- It can be very slow because it may be executed once for every row processed by the outer query.

-- Goal: For each customer, find the date of their most recent invoice.

-- **Method 1: Correlated Subquery (Inefficient)**
-- For every single customer, this query runs a separate subquery to find their max invoice date.
-- This is a classic performance anti-pattern.
EXPLAIN SELECT
    c.CustomerId,
    c.FirstName,
    c.LastName,
    (SELECT MAX(i.InvoiceDate) FROM Invoice i WHERE i.CustomerId = c.CustomerId) AS LastInvoiceDate
FROM Customer c;

-- **Method 2: Using a JOIN with GROUP BY (More Efficient)**
-- This is much better. The database can calculate all the max dates in one pass.
EXPLAIN SELECT
    c.CustomerId,
    c.FirstName,
    c.LastName,
    MAX(i.InvoiceDate) AS LastInvoiceDate
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName;

-- **Method 3: Using a Window Function (Often the Cleanest)**
-- Window functions can also solve this, sometimes more readably, though not demonstrated here.


-- -----------------------------------------------------------------------------
-- Key Takeaways for Joins:
-- -----------------------------------------------------------------------------
-- 1. **Index Your Join Keys**: The single most important thing you can do. Foreign key constraints
--    often create these indexes automatically. `Album.ArtistId` and `Track.AlbumId` should be indexed.
-- 2. **Join on Numeric Columns**: Joining on integers is faster than joining on strings.
-- 3. **Filter Early**: Apply `WHERE` clauses as early as possible to reduce the amount of data
--    that needs to be processed in later join steps.
