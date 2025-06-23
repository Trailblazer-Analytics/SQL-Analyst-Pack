/*
    File        : 09_database-administration/01_schema_overview_and_metadata.sql
    Topic       : Database Administration
    Purpose     : How to query the database's own metadata to understand its structure.
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-21
    Updated     : 2025-06-23
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    -- SQLite has a special `sqlite_master` table instead of a standard information schema.
    -- Oracle uses `ALL_TABLES` and `ALL_TAB_COLUMNS` views.
    -- BigQuery and Snowflake have their own `INFORMATION_SCHEMA` views which are very similar.
    Notes       : • The INFORMATION_SCHEMA is an ANSI standard, but implementations vary slightly.
*/

-- =============================================================================
-- The Information Schema
-- =============================================================================
-- Nearly every database has a built-in, read-only set of views called the
-- `INFORMATION_SCHEMA`. It provides information about the database itself:
-- schemas, tables, columns, constraints, etc.

-- -----------------------------------------------------------------------------
-- Example 1: List all tables in the current database/schema.
-- -----------------------------------------------------------------------------
-- This is useful for getting a quick overview of the database structure.

-- For PostgreSQL, MySQL, SQL Server, BigQuery, Snowflake:
SELECT
    table_catalog, -- The database name
    table_schema,  -- The schema name (e.g., 'public')
    table_name,
    table_type     -- 'BASE TABLE' for a normal table, 'VIEW' for a view
FROM information_schema.tables
-- In some systems, you may need to filter by schema or catalog:
-- WHERE table_schema = 'public';
ORDER BY table_name;

-- For SQLite:
-- SQLite does not have an information schema. It has a special table called `sqlite_master`.
SELECT
    type,
    name,
    tbl_name,
    sql
FROM sqlite_master
WHERE type = 'table';

-- For Oracle:
-- SELECT owner, table_name FROM all_tables;


-- -----------------------------------------------------------------------------
-- Example 2: Get detailed information about the columns of a specific table.
-- -----------------------------------------------------------------------------
-- This is like running `DESCRIBE TABLE` but allows for more flexible filtering.

-- For PostgreSQL, MySQL, SQL Server, BigQuery, Snowflake:
SELECT
    column_name,
    ordinal_position, -- The numeric position of the column in the table (1, 2, 3...)
    data_type,        -- The data type (e.g., VARCHAR, INTEGER)
    character_maximum_length, -- For string types, the max length
    is_nullable,      -- 'YES' or 'NO'
    column_default    -- The default value, if any
FROM information_schema.columns
WHERE table_name = 'Customer' -- Specify the table you are interested in
-- AND table_schema = 'public' -- You may need to specify the schema
ORDER BY ordinal_position;

-- For SQLite:
-- The `PRAGMA` command provides table information.
PRAGMA table_info('Customer');

-- For Oracle:
-- SELECT column_name, data_type, data_length, nullable FROM all_tab_columns WHERE table_name = 'CUSTOMER';
