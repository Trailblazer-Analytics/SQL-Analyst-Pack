/*
    File: 01_table_overview_and_counts.sql
    Topic: Data Profiling
    Task: Table Overview and Row Counts
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Table Overview and Counts
-- =================================================================================================================================
--
-- Data profiling is the first step in any data analysis project. It involves getting a high-level overview of the data,
-- understanding its structure, and identifying potential quality issues. This script focuses on two fundamental tasks:
-- 1. Listing all tables in a database or schema.
-- 2. Counting the number of rows in each table.
--
-- These simple checks help you understand the scope of the database and the volume of data you are working with.
--
-- =================================================================================================================================
-- General ANSI SQL Approach (using INFORMATION_SCHEMA)
-- =================================================================================================================================
--
-- The `INFORMATION_SCHEMA` is an ANSI standard set of views that provide metadata about a database.
-- It is supported by most major SQL databases, including PostgreSQL, SQL Server, MySQL, and others.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: List All Tables in a Specific Schema
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `tables` view in `INFORMATION_SCHEMA` contains information about all tables and views.
-- We filter by `table_schema` to limit results to a specific schema (e.g., 'public' in PostgreSQL).
-- We also filter by `table_type` to get only base tables, excluding views.

-- Note: The schema name can vary. 'public' is common in PostgreSQL, 'dbo' in SQL Server, and in MySQL/SQLite,
-- you often query without a schema qualifier if you are connected to a specific database.

SELECT
    table_catalog, -- The database name
    table_schema,  -- The schema name
    table_name,    -- The table name
    table_type     -- e.g., 'BASE TABLE' for tables, 'VIEW' for views
FROM
    information_schema.tables
WHERE
    table_type = 'BASE TABLE'
    AND table_schema NOT IN ('pg_catalog', 'information_schema'); -- Exclude system schemas

-- =================================================================================================================================
-- Flavor-Specific Examples for Listing Tables
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- PostgreSQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the 'public' schema.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQL Server
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the current database.
SELECT name AS table_name
FROM sys.objects
WHERE type = 'U'; -- 'U' stands for User Table

-- Or using INFORMATION_SCHEMA
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = 'Chinook'; -- Replace 'Chinook' with your DB name

-- ---------------------------------------------------------------------------------------------------------------------------------
-- MySQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the currently connected database.
SHOW TABLES;

-- Or using INFORMATION_SCHEMA
SELECT table_name
FROM information_schema.tables
WHERE table_schema = DATABASE(); -- DATABASE() returns the current database name

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQLite
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the database.
SELECT name
FROM sqlite_master
WHERE type = 'table' AND name NOT LIKE 'sqlite_%'; -- Excludes internal SQLite tables

-- =================================================================================================================================
-- Getting Row Counts for Tables
-- =================================================================================================================================
--
-- Counting rows is essential for understanding the size of your tables. While `SELECT COUNT(*)` is straightforward
-- for a single table, it can be tedious to run for every table. Many databases provide metadata or shortcuts
-- to get approximate or exact row counts more efficiently.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Get Row Count for a Single Table (Universal)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- This works in all SQL flavors.
SELECT COUNT(*) AS row_count
FROM "artists"; -- Using quotes for case-sensitivity if needed

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Get Row Counts for All Tables (Flavor-Specific)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Getting counts for all tables at once often requires a more advanced or flavor-specific approach.

-- PostgreSQL (using table metadata for approximate counts - very fast)
-- The `reltuples` column in `pg_class` stores an estimated row count.
SELECT
    c.relname AS table_name,
    c.reltuples AS approximate_row_count
FROM
    pg_class c
JOIN
    pg_namespace n ON c.relnamespace = n.oid
WHERE
    n.nspname = 'public' AND c.relkind = 'r' -- 'r' for regular table
ORDER BY
    c.relname;

-- SQL Server (using system views for exact counts)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.rows AS row_count
FROM
    sys.tables t
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN
    sys.partitions p ON t.object_id = p.object_id
WHERE
    p.index_id IN (0, 1) -- 0 for heap, 1 for clustered index
ORDER BY
    s.name, t.name;

-- MySQL (using INFORMATION_SCHEMA - can be slow on large databases)
-- The `TABLE_ROWS` column provides an estimated count for InnoDB tables.
SELECT
    table_name,
    table_rows AS approximate_row_count
FROM
    information_schema.tables
WHERE
    table_schema = DATABASE()
ORDER BY
    table_name;

-- Note on Dynamic SQL: For some databases, creating a script that iterates through table names
-- and executes `SELECT COUNT(*)` for each is a common pattern, especially if exact counts are required
-- and system tables are not preferred. This typically involves procedural code (e.g., PL/pgSQL, T-SQL).

-- =================================================================================================================================
-- Practical Exercise: Profile the Chinook Database
-- =================================================================================================================================

-- 1. List all tables in the Chinook database using the method for your SQL flavor.
--    (Example for SQLite)
SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';

-- 2. Get the row count for the 'invoices', 'customers', and 'tracks' tables.
SELECT 'invoices' AS table_name, COUNT(*) AS row_count FROM "invoices"
UNION ALL
SELECT 'customers', COUNT(*) FROM "customers"
UNION ALL
SELECT 'tracks', COUNT(*) FROM "tracks";

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- You have learned how to list tables and get row counts, which are foundational data profiling skills.
-- This information provides a map of your database and helps you plan your analysis. Always start here
-- before diving into more complex queries.
--
-- Next, you might want to profile the columns within these tables to understand data types, null values,
-- and value distributions.
--
-- =================================================================================================================================
