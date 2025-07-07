/*
    File: 01_duplicate_detection_and_removal.sql
    Topic: Data Cleaning
    Task: Duplicate Detection and Removal
    Author: SQL Analyst Pack Community
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Duplicate Data
-- =================================================================================================================================
--
-- Duplicate records are a common data quality issue that can significantly distort analysis, leading to inflated counts,
-- incorrect averages, and flawed insights. Data cleaning is the process of identifying and correcting or removing
-- inaccurate records from a dataset.
--
-- This script covers two main tasks:
-- 1. **Detection**: Identifying which records are duplicates based on a defined set of columns (a "business key").
-- 2. **Removal**: Deleting the duplicate records while keeping one version (the original or the most recent).
--
-- We will primarily use Window Functions (`ROW_NUMBER()`) with Common Table Expressions (CTEs), which is the
-- most powerful and standard method for handling duplicates in modern SQL.
--
-- =================================================================================================================================
-- Step 1: Detecting Duplicate Records
-- =================================================================================================================================
--
-- Before deleting anything, you must first identify the duplicates. The `GROUP BY` clause is a simple way to find them.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Find duplicate playlist names
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Here, we group by the `Name` column in the `playlists` table and use a `HAVING` clause to filter for names that appear more than once.

SELECT
    Name,
    COUNT(*) AS occurrence_count
FROM
    playlists
GROUP BY
    Name
HAVING
    COUNT(*) > 1;
-- In the standard Chinook database, this should return no results, indicating no duplicate playlist names.

-- =================================================================================================================================
-- Step 2: Identifying Rows to Delete using Window Functions
-- =================================================================================================================================
--
-- To remove duplicates, we need to uniquely identify each row within a group of duplicates. The `ROW_NUMBER()`
-- window function is perfect for this. It assigns a sequential integer to each row within a partition.
--
-- The strategy is:
-- 1. **PARTITION BY** the columns that define a duplicate (e.g., same name, same email).
-- 2. **ORDER BY** a column that can determine which record to keep (e.g., a primary key, a timestamp).
-- 3. Assign a row number (`rn`). Any row with `rn > 1` is a duplicate.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Assigning a row number to potential duplicates
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's imagine we have a table of customer contacts where duplicates might exist based on email.
-- First, let's create a temporary table to simulate this scenario.

-- This syntax for a temporary table with data is common but can vary.
-- SQLite/PostgreSQL/MySQL:
CREATE TEMP TABLE customer_contacts AS
SELECT 'John Doe' AS name, 'johndoe@email.com' AS email, 1 AS version
UNION ALL
SELECT 'Jane Smith', 'janesmith@email.com', 1
UNION ALL
SELECT 'John Doe', 'johndoe@email.com', 2 -- Duplicate email
UNION ALL
SELECT 'Peter Jones', 'peterjones@email.com', 1
UNION ALL
SELECT 'John Doe', 'johndoe@email.com', 3; -- Second duplicate email

-- Now, let's identify the duplicates using ROW_NUMBER()
WITH NumberedContacts AS (
    SELECT
        name,
        email,
        version,
        ROW_NUMBER() OVER(PARTITION BY email ORDER BY version DESC) as rn
    FROM
        customer_contacts
)
SELECT * FROM NumberedContacts;
-- In the result, any row where `rn` is greater than 1 is a duplicate that we might want to remove.
-- We ordered by `version DESC` to keep the newest version of the contact.

-- =================================================================================================================================
-- Step 3: Removing Duplicate Records
-- =================================================================================================================================
--
-- Once you have identified the rows to delete (where `rn > 1`), you can proceed with deletion.
-- **IMPORTANT**: Always back up your data before running a DELETE statement. Test with a SELECT first!

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Deleting duplicate rows using a CTE
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The ability to delete directly from a CTE is supported by PostgreSQL, SQL Server, and SQLite.
-- **MySQL does not support deleting from a CTE that uses window functions directly.**

-- Deletion query (works on PostgreSQL, SQL Server, SQLite)
WITH NumberedContacts AS (
    SELECT
        rowid, -- In SQLite, `rowid` is a unique identifier for each row.
               -- In PostgreSQL, use `ctid`. In SQL Server, you would typically use the primary key.
        ROW_NUMBER() OVER(PARTITION BY email ORDER BY version DESC) as rn
    FROM
        customer_contacts
)
DELETE FROM customer_contacts
WHERE rowid IN (SELECT rowid FROM NumberedContacts WHERE rn > 1);

-- Let's verify the result
SELECT * FROM customer_contacts;
-- The table should now only contain the unique emails with the highest version number.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Flavor-Specific Note: Deleting Duplicates in MySQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- In MySQL, you typically need to join the table to itself using the CTE result.
/*
DELETE t1 FROM customer_contacts t1
INNER JOIN (
    SELECT
        name, email, version, -- You need the primary key or a unique row identifier here
        ROW_NUMBER() OVER(PARTITION BY email ORDER BY version DESC) as rn
    FROM
        customer_contacts
) t2 ON t1.name = t2.name AND t1.email = t2.email AND t1.version = t2.version -- Join on the exact row
WHERE t2.rn > 1;
*/

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. Create a temporary table named `artists_staging` with the same structure as `artists`.
CREATE TEMP TABLE artists_staging (ArtistId INTEGER, Name NVARCHAR(120));

-- 2. Insert some data into it, including duplicates.
INSERT INTO artists_staging (ArtistId, Name) VALUES
(1, 'AC/DC'),
(2, 'Accept'),
(3, 'Aerosmith'),
(4, 'Accept'); -- Duplicate name, different ID

-- 3. Write a SELECT query using a CTE and ROW_NUMBER() to identify the duplicate artist names.
--    Partition by `Name` and order by `ArtistId`.
WITH NumberedArtists AS (
    SELECT
        ArtistId,
        Name,
        ROW_NUMBER() OVER(PARTITION BY Name ORDER BY ArtistId) as rn
    FROM
        artists_staging
)
SELECT * FROM NumberedArtists WHERE rn > 1;

-- 4. Write a DELETE statement to remove the duplicate artist.
WITH NumberedArtists AS (
    SELECT
        ArtistId,
        ROW_NUMBER() OVER(PARTITION BY Name ORDER BY ArtistId) as rn
    FROM
        artists_staging
)
DELETE FROM artists_staging
WHERE ArtistId IN (SELECT ArtistId FROM NumberedArtists WHERE rn > 1);

-- 5. Verify that the duplicate has been removed.
SELECT * FROM artists_staging;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- You have learned the standard, modern approach to detecting and removing duplicate data using CTEs and `ROW_NUMBER()`.
-- This method is efficient, readable, and gives you precise control over which records to keep and which to delete.
-- Always remember to identify duplicates with a `SELECT` statement before you `DELETE` them.
--
-- =================================================================================================================================
