/*
    File        : 09_database-administration/03_foreign_keys_and_relationships.sql
    Topic       : Database Administration
    Purpose     : Shows how to identify foreign key relationships between tables.
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-21
    Updated     : 2025-06-23
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ⚠️ BigQuery | ⚠️ Snowflake
    -- BigQuery and Snowflake have slightly different INFORMATION_SCHEMA views for constraints.
    -- SQLite uses the PRAGMA interface for this information.
    Notes       : • Understanding foreign keys is essential for knowing how to JOIN tables correctly.
*/

-- =============================================================================
-- Discovering Table Relationships with Foreign Keys
-- =============================================================================
-- Foreign keys define the relationships between tables. We can query the
-- information schema to see exactly how tables are linked.

-- Goal: Find all foreign keys that reference the `Album` table.

-- For PostgreSQL, MySQL, SQL Server:
SELECT
    con.constraint_name,
    tbl.table_name AS referencing_table,
    kcu.column_name AS referencing_column,
    rel_tbl.table_name AS referenced_table,
    rel_kcu.column_name AS referenced_column
FROM information_schema.referential_constraints AS con
JOIN information_schema.key_column_usage AS kcu
    ON con.constraint_name = kcu.constraint_name
JOIN information_schema.key_column_usage AS rel_kcu
    ON con.unique_constraint_name = rel_kcu.constraint_name
JOIN information_schema.tables AS tbl
    ON kcu.table_name = tbl.table_name
JOIN information_schema.tables AS rel_tbl
    ON rel_kcu.table_name = rel_tbl.table_name
WHERE rel_tbl.table_name = 'Album';

-- For SQLite:
-- The `foreign_key_list` pragma shows all foreign keys for a given table.
-- This shows that the `Track` table has a foreign key to the `Album` table.
PRAGMA foreign_key_list('Track');

-- For Oracle:
-- SELECT
--     a.constraint_name,
--     a.table_name AS referencing_table,
--     a.column_name AS referencing_column,
--     c.table_name AS referenced_table
-- FROM all_cons_columns a
-- JOIN all_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
-- WHERE c.constraint_type = 'R' AND c.r_constraint_name IN (
--     SELECT constraint_name FROM all_constraints WHERE table_name = 'ALBUM' AND constraint_type = 'P'
-- );
