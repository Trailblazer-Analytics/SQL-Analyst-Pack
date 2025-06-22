/*
    File: 02_column_profiling_and_types.sql
    Topic: Data Profiling
    Task: Column Profiling and Data Types
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Column Profiling
-- =================================================================================================================================
--
-- After getting an overview of the tables, the next step in data profiling is to inspect the columns.
-- Column profiling helps you understand the details of each attribute in your dataset. Key activities include:
-- 1. Identifying data types (e.g., integer, text, date).
-- 2. Checking for nullability (i.e., whether a column can contain missing values).
-- 3. Examining column metadata like character length or numeric precision.
--
-- This script provides queries to extract this metadata, which is crucial for planning data cleaning and analysis.
--
-- =================================================================================================================================
-- Using INFORMATION_SCHEMA.COLUMNS (ANSI SQL)
-- =================================================================================================================================
--
-- The `INFORMATION_SCHEMA.COLUMNS` view is the standard way to get metadata about columns. It is supported
-- across most major databases and provides a consistent interface.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Get Column Information for a Specific Table
-- ---------------------------------------------------------------------------------------------------------------------------------
-- This query retrieves the name, data type, nullability, and default value for each column in the 'employees' table.

SELECT
    column_name,
    ordinal_position, -- The position of the column in the table (1, 2, 3, ...)
    column_default,   -- The default value for the column, if any
    is_nullable,      -- 'YES' or 'NO'
    data_type,        -- The data type (e.g., VARCHAR, INTEGER, TIMESTAMP)
    character_maximum_length, -- For character types, the maximum length
    numeric_precision, -- For numeric types, the precision (total number of digits)
    numeric_scale      -- For numeric types, the scale (number of digits to the right of the decimal point)
FROM
    information_schema.columns
WHERE
    table_name = 'employees' -- Specify the table name here
ORDER BY
    ordinal_position;

-- =================================================================================================================================
-- Flavor-Specific Examples for Describing Table Structure
-- =================================================================================================================================
--
-- While `INFORMATION_SCHEMA` is standard, some databases offer convenient shortcuts to describe a table.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- PostgreSQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `\d` command in the `psql` client provides a detailed description of a table.
-- This is a command-line shortcut, not an SQL query.
-- \d employees

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQL Server
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `sp_help` stored procedure gives a comprehensive overview of a table or any other object.
EXEC sp_help 'dbo.employees';

-- A more focused procedure for columns is `sp_columns`.
EXEC sp_columns 'employees';

-- ---------------------------------------------------------------------------------------------------------------------------------
-- MySQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `DESCRIBE` or `EXPLAIN` statement is a concise way to see a table's structure.
DESCRIBE employees;
-- or
EXPLAIN employees;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQLite
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `PRAGMA` statement is used to query database metadata. `table_info` returns column details.
PRAGMA table_info(employees);

-- =================================================================================================================================
-- Practical Exercise: Profile Columns in the Chinook Database
-- =================================================================================================================================

-- 1. Get the column profile for the 'tracks' table.
--    Use the INFORMATION_SCHEMA query or the specific command for your database flavor.
--    (Example for ANSI SQL)
SELECT
    column_name,
    data_type,
    is_nullable,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM
    information_schema.columns
WHERE
    table_name = 'tracks'
ORDER BY
    ordinal_position;

-- 2. Describe the structure of the 'invoices' table using your database's shortcut command.
--    (Example for SQLite)
PRAGMA table_info(invoices);

--    (Example for MySQL)
--    DESCRIBE invoices;

--    (Example for SQL Server)
--    EXEC sp_help 'dbo.invoices';

-- 3. Find out which columns in the 'customers' table can accept NULL values.
SELECT
    column_name,
    is_nullable
FROM
    information_schema.columns
WHERE
    table_name = 'customers' AND is_nullable = 'YES';

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Understanding column properties is fundamental to data analysis. It informs how you query data (e.g., knowing
-- date formats), how you clean it (e.g., handling nulls), and how you join tables (e.g., matching data types).
-- Always take the time to profile your columns before proceeding with more complex analysis.
--
-- Next, we will explore data quality issues like NULL values and inconsistencies.
--
-- =================================================================================================================================
