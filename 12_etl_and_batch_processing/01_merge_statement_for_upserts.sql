-- File: 12_etl_and_batch_processing/01_merge_statement_for_upserts.sql
-- Topic: ETL and Batch Processing - The MERGE Statement
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates how to use the `MERGE` statement to perform "upsert"
-- (update or insert) operations. This is a cornerstone of ETL (Extract, Transform, Load)
-- processes, where you need to synchronize a target table with a source of new data.

-- Prerequisites:
-- Understanding of `INSERT` and `UPDATE` statements, and `JOIN`s.
-- This is a moderately advanced topic.

-- Dialect Compatibility:
-- The `MERGE` statement is part of the SQL standard but is not universally implemented.
-- - Supported: SQL Server, Oracle, Snowflake, BigQuery.
-- - Not Supported: PostgreSQL, MySQL, SQLite. These systems have their own syntax for upserts.
-- This script provides examples for both `MERGE` and the alternatives.

---------------------------------------------------------------------------------------------------

-- Section 1: The ETL Challenge - Synchronizing Data

-- In ETL, a common task is to load data from a temporary "staging" table into a final
-- "production" table. Some rows from the staging table might be new and need to be inserted.
-- Other rows might correspond to existing records in the production table and need to be updated.

-- Doing this with separate `INSERT` and `UPDATE` statements can be complex and inefficient.
-- The `MERGE` statement (or its equivalent) handles this in a single, atomic operation.

---------------------------------------------------------------------------------------------------

-- Section 2: The MERGE Statement

-- Scenario: We have a main `employees` table. A staging table, `employees_staging`,
-- contains updated information for some employees and one new employee.
-- We need to synchronize the `employees` table with this new data.

-- First, let's create and populate our staging table for the demonstration.
-- Note: We'll use temporary tables for this example.

-- SQLite / PostgreSQL / SQL Server:
CREATE TEMP TABLE employees_staging (
    EmployeeId INT PRIMARY KEY,
    LastName VARCHAR(20),
    FirstName VARCHAR(20),
    Title VARCHAR(30),
    Email VARCHAR(60)
);

INSERT INTO employees_staging (EmployeeId, LastName, FirstName, Title, Email) VALUES
    -- Update existing employee: Jane Peacock's title has changed.
    (3, 'Peacock', 'Jane', 'Senior Sales Support Agent', 'jane.peacock@chinookcorp.com'),
    -- New employee
    (9, 'Smith', 'John', 'IT Staff', 'john.smith@chinookcorp.com');

-- Now, let's perform the MERGE operation (Syntax for SQL Server, Oracle, etc.)
/*
MERGE INTO employees AS target
USING employees_staging AS source
ON (target.EmployeeId = source.EmployeeId)

-- Case 1: When a matching employee is found
WHEN MATCHED THEN
    UPDATE SET
        target.Title = source.Title,
        target.Email = source.Email

-- Case 2: When no matching employee is found in the target table
WHEN NOT MATCHED BY TARGET THEN
    INSERT (EmployeeId, LastName, FirstName, Title, Email)
    VALUES (source.EmployeeId, source.LastName, source.FirstName, source.Title, source.Email);
*/

-- After this operation:
-- - Jane Peacock's (EmployeeId 3) record in the `employees` table would be updated.
-- - John Smith's (EmployeeId 9) record would be inserted into the `employees` table.

-- Cleanup the staging table
DROP TABLE employees_staging;

---------------------------------------------------------------------------------------------------

-- Section 3: Alternatives in PostgreSQL and MySQL

-- These popular databases use a different, non-standard syntax for upserts.

-- PostgreSQL: `INSERT ... ON CONFLICT ... DO UPDATE`
-- This syntax is often considered very readable. You specify what to do when an insert
-- fails due to a constraint violation (like a duplicate primary key).

/*
-- First, create the staging table as before.
CREATE TEMP TABLE employees_staging (...);
INSERT INTO employees_staging VALUES ...;

-- The PostgreSQL Upsert command:
INSERT INTO employees (EmployeeId, LastName, FirstName, Title, Email)
SELECT EmployeeId, LastName, FirstName, Title, Email FROM employees_staging
ON CONFLICT (EmployeeId) DO UPDATE
SET
    Title = EXCLUDED.Title, -- EXCLUDED refers to the values from the row that was not inserted.
    Email = EXCLUDED.Email;
*/

-- MySQL: `INSERT ... ON DUPLICATE KEY UPDATE`
-- Similar to PostgreSQL, this command handles a duplicate key violation during an insert.

/*
-- First, create the staging table as before.
CREATE TEMPORARY TABLE employees_staging (...);
INSERT INTO employees_staging VALUES ...;

-- The MySQL Upsert command:
INSERT INTO employees (EmployeeId, LastName, FirstName, Title, Email)
SELECT EmployeeId, LastName, FirstName, Title, Email FROM employees_staging
ON DUPLICATE KEY UPDATE
    Title = VALUES(Title), -- VALUES() refers to the values from the row that was not inserted.
    Email = VALUES(Email);
*/

-- Understanding the `MERGE` statement and its equivalents is crucial for anyone involved
-- in data warehousing, ETL, or synchronizing datasets.
