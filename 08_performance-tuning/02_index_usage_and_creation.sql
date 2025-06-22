/*
    File        : 08_performance-tuning/02_index_usage_and_creation.sql
    Topic       : Performance Tuning
    Purpose     : Demonstrates different types of indexes and their use cases.
    Author      : GitHub Copilot
    Created     : 2025-06-21
    Updated     : 2025-06-21
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery | ✅ Snowflake
    Notes       : • This script builds upon the concepts from the previous one.
                • Ensure the Chinook sample database is available.
*/

-- =============================================================================
-- Scenario: Optimizing queries on the `Invoice` table.
-- The `Invoice` table is frequently queried by customer, date, and total amount.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Case 1: Single-Column Index
-- -----------------------------------------------------------------------------
-- Used when you frequently filter or sort by a single column.
-- Let's assume we often search for invoices by their total amount.

-- Query without an index (will likely cause a full table scan)
EXPLAIN SELECT * FROM Invoice WHERE Total > 20.00;

-- Create a single-column index on the `Total` column
CREATE INDEX idx_invoice_total ON Invoice(Total);

-- Query with the index (should be more efficient)
-- The database can use the index to quickly find rows where `Total` > 20.00.
EXPLAIN SELECT * FROM Invoice WHERE Total > 20.00;

-- Clean up the index
DROP INDEX idx_invoice_total;


-- -----------------------------------------------------------------------------
-- Case 2: Multi-Column (Composite) Index
-- -----------------------------------------------------------------------------
-- Used when you frequently filter by two or more columns together.
-- The order of columns in the index is very important.
-- Let's assume we often search for invoices for a specific customer on a specific date.

-- Query without a composite index
EXPLAIN SELECT * FROM Invoice WHERE CustomerId = 10 AND InvoiceDate > '2010-01-01';

-- Create a composite index. The order `(CustomerId, InvoiceDate)` is chosen because
-- we are more likely to filter by a specific customer first.
CREATE INDEX idx_invoice_customer_date ON Invoice(CustomerId, InvoiceDate);

-- Query with the composite index. The database can use this index to efficiently
-- satisfy both conditions in the `WHERE` clause.
EXPLAIN SELECT * FROM Invoice WHERE CustomerId = 10 AND InvoiceDate > '2010-01-01';

-- This query can also use the index because the `CustomerId` is the first column
-- in the index definition.
EXPLAIN SELECT * FROM Invoice WHERE CustomerId = 10;

-- However, this query CANNOT efficiently use the index because it only filters by
-- `InvoiceDate`, which is the second column in the index.
EXPLAIN SELECT * FROM Invoice WHERE InvoiceDate > '2010-01-01';

-- Clean up the index
DROP INDEX idx_invoice_customer_date;


-- -----------------------------------------------------------------------------
-- General Rules for Indexes:
-- -----------------------------------------------------------------------------
-- 1. DO index columns used frequently in `WHERE` clauses and `JOIN` conditions.
-- 2. DO index columns used in `ORDER BY` clauses.
-- 3. DON'T over-index. Indexes speed up reads (`SELECT`) but slow down writes (`INSERT`, `UPDATE`, `DELETE`)
--    because the index must also be updated.
-- 4. DON'T index small tables, as a full table scan is often fast enough.
-- 5. DON'T index columns with low cardinality (few unique values), like a `gender` column.
