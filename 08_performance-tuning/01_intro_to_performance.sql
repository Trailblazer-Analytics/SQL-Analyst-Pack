/*
    File        : 08_performance-tuning/01_intro_to_performance.sql
    Topic       : Performance Tuning
    Purpose     : Demonstrates the basics of query performance analysis using EXPLAIN and the impact of indexes.
    Author      : GitHub Copilot
    Created     : 2025-06-21
    Updated     : 2025-06-21
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    -- SQL Server uses `EXPLAIN` differently, often via `SET SHOWPLAN_TEXT ON;`.
    -- BigQuery and Snowflake have their own query plan visualization tools.
    Notes       : • This script assumes the Chinook sample database is set up.
                • The exact output of EXPLAIN will vary between database systems.
*/

-- Introduction to Query Plans
-- A query plan is the sequence of steps a database uses to execute a SQL query.
-- By analyzing the plan, we can identify bottlenecks and opportunities for optimization.
-- The `EXPLAIN` keyword (or equivalent) shows this plan.

-- =============================================================================
-- Scenario: Find a customer by their email address.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Step 1: Analyze the query plan WITHOUT an index.
-- -----------------------------------------------------------------------------
-- The database will have to perform a "full table scan," meaning it reads every
-- single row in the `Customer` table to find the matching email. This is inefficient
-- for large tables.

-- In PostgreSQL, MySQL, SQLite:
EXPLAIN SELECT * FROM Customer WHERE Email = 'luisg@embraer.com.br';

-- In SQL Server:
-- SET SHOWPLAN_TEXT ON;
-- GO
-- SELECT * FROM Customer WHERE Email = 'luisg@embraer.com.br';
-- GO
-- SET SHOWPLAN_TEXT OFF;
-- GO

-- Expected Result (varies by system, but look for "SCAN" or "TABLE SCAN"):
-- The plan will indicate a full scan of the `Customer` table.


-- -----------------------------------------------------------------------------
-- Step 2: Create an index to speed up the query.
-- -----------------------------------------------------------------------------
-- An index is a special lookup table that the database search engine can use to
-- speed up data retrieval. It's like the index in the back of a book.

CREATE INDEX idx_customer_email ON Customer(Email);


-- -----------------------------------------------------------------------------
-- Step 3: Analyze the query plan WITH the index.
-- -----------------------------------------------------------------------------
-- After creating the index, the database can use it to quickly find the location
-- of the desired row(s) without scanning the whole table.

-- In PostgreSQL, MySQL, SQLite:
EXPLAIN SELECT * FROM Customer WHERE Email = 'luisg@embraer.com.br';

-- Expected Result (varies by system, but look for "INDEX SEEK" or "INDEX SCAN"):
-- The plan will now show that it uses `idx_customer_email` to find the data,
-- which is much faster.


-- -----------------------------------------------------------------------------
-- Step 4: Clean up the created index.
-- -----------------------------------------------------------------------------
-- It's good practice to remove indexes created for demonstration purposes.

DROP INDEX idx_customer_email;
