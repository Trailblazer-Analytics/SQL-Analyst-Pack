/*
    File        : 08_performance-tuning/03_query_plan_analysis.sql
    Topic       : Performance Tuning
    Purpose     : Teaches how to read and interpret basic query execution plans.
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-21
    Updated     : 2025-06-23
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    Notes       : • Query plan output is highly specific to the database system and version.
                • This script provides a general guide to understanding the concepts.
*/

-- =============================================================================
-- Understanding Key Operations in a Query Plan
-- =============================================================================

-- A query plan is a tree of operations. You generally read it from the inside out.
-- The most important things to look for are operations that are computationally expensive.

-- -----------------------------------------------------------------------------
-- Operation 1: Full Table Scan (Seq Scan)
-- -----------------------------------------------------------------------------
-- This is often the most expensive operation on large tables.
-- It means the database has to read every single row to find the data it needs.
-- It is acceptable for small tables but a major red flag for large ones.

-- This query will almost certainly perform a full table scan on the `Invoice` table
-- because there is no index on the `BillingCity` column.
EXPLAIN SELECT * FROM Invoice WHERE BillingCity = 'London';

-- In the output, look for terms like:
-- `Seq Scan on Invoice` (PostgreSQL)
-- `TABLE ACCESS FULL` (Oracle)
-- `Table Scan` (SQL Server)


-- -----------------------------------------------------------------------------
-- Operation 2: Index Scan / Index Seek
-- -----------------------------------------------------------------------------
-- This is a much more efficient operation.
-- `Index Seek` means the database can use an index to go directly to the rows it needs.
-- `Index Scan` means it reads the entire index, which is still much faster than a full table scan.

-- First, let's create an index to demonstrate.
CREATE INDEX idx_invoice_billingcity ON Invoice(BillingCity);

-- Now, run the same query again.
EXPLAIN SELECT * FROM Invoice WHERE BillingCity = 'London';

-- In the output, look for terms like:
-- `Index Seek` (SQL Server)
-- `Index Scan using idx_invoice_billingcity` (PostgreSQL)
-- `TABLE ACCESS BY INDEX ROWID` (Oracle)

-- Clean up the index
DROP INDEX idx_invoice_billingcity;


-- -----------------------------------------------------------------------------
-- Operation 3: Joins (e.g., Nested Loop, Hash Join, Merge Join)
-- -----------------------------------------------------------------------------
-- The way a database joins tables can have a huge impact on performance.

-- Example Query: Get all tracks for a specific album.
EXPLAIN SELECT
    t.Name AS TrackName,
    a.Title AS AlbumTitle
FROM Track t
JOIN Album a ON t.AlbumId = a.AlbumId
WHERE a.Title = 'For Those About To Rock We Salute You';

-- Common Join Types:
-- 1. Nested Loop: Good for joining a small table to a large table (especially if the join column on the large table is indexed).
-- 2. Hash Join: Efficient for joining large, unsorted datasets. The database builds a hash table in memory.
-- 3. Merge Join: Very efficient if both datasets are already sorted on the join key.

-- The query planner chooses the best join algorithm based on table sizes, indexes, and statistics.
-- Analyzing the chosen join type can reveal if an index is missing on a join key.
-- In the query above, an index on `Track.AlbumId` is crucial for good performance.
-- (The Chinook database already has this as a foreign key, which is typically indexed automatically).
