/*
    File        : 09_database-administration/02_table_and_column_info.sql
    Topic       : Database Administration
    Purpose     : Demonstrates how to find primary keys and check for column properties like defaults and nullability.
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-21
    Updated     : 2025-06-23
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    -- BigQuery and Snowflake have slightly different INFORMATION_SCHEMA views for constraints.
    -- SQLite uses the PRAGMA interface for this information.
    Notes       : • This script uses the INFORMATION_SCHEMA, which is the standard way to query metadata.
*/

-- =============================================================================
-- Finding Primary Keys for a Table
-- =============================================================================
-- The primary key is a crucial piece of information for any table.
-- We can find it by querying for constraints.

-- For PostgreSQL, MySQL, SQL Server:
SELECT
    kcu.column_name,
    tco.constraint_type
FROM information_schema.table_constraints AS tco
JOIN information_schema.key_column_usage AS kcu
    ON tco.constraint_name = kcu.constraint_name
    AND tco.table_schema = kcu.table_schema
    AND tco.table_name = kcu.table_name
WHERE tco.table_name = 'Album' AND tco.constraint_type = 'PRIMARY KEY';

-- For SQLite:
-- The `table_info` pragma has a `pk` column. A non-zero value indicates
-- that the column is part of the primary key.
PRAGMA table_info('Album');

-- For Oracle:
-- SELECT cols.column_name
-- FROM all_constraints cons, all_cons_columns cols
-- WHERE cols.table_name = 'ALBUM'
-- AND cons.constraint_type = 'P'
-- AND cons.constraint_name = cols.constraint_name
-- AND cons.owner = cols.owner;


-- =============================================================================
-- Checking Column Nullability and Defaults
-- =============================================================================
-- This information is available directly in the `information_schema.columns` view.

-- Goal: Check the properties of the columns in the `Customer` table.
SELECT
    column_name,
    data_type,
    is_nullable,      -- 'YES' if the column allows NULLs, 'NO' otherwise.
    column_default    -- The default value for the column, if one is defined.
FROM information_schema.columns
WHERE table_name = 'Customer'
ORDER BY ordinal_position;

-- Example Interpretation:
-- You might find that a `ModifiedDate` column has a `column_default` of `CURRENT_TIMESTAMP`
-- or that a `FirstName` column has `is_nullable` set to `NO`.
