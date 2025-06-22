/*
    File: 04_data_validation_and_integrity.sql
    Topic: Data Cleaning
    Task: Data Validation and Integrity
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Data Validation and Integrity
-- =================================================================================================================================
--
-- Data validation is the process of ensuring that data is accurate, logical, and conforms to predefined business rules.
-- Data integrity refers to the overall accuracy, completeness, and consistency of data. While data standardization
-- cleans up the format, validation checks if the *values* themselves make sense.
--
-- This script covers two aspects of validation:
-- 1. **Manual Validation**: Writing queries to find data that violates business rules.
-- 2. **Automated Integrity (Constraints)**: Using database features like constraints to automatically enforce rules
--    and prevent bad data from being entered in the first place.
--
-- Common validation checks include:
-- - Checking for valid ranges (e.g., age must be > 0).
-- - Verifying specific formats (e.g., email addresses must contain an '@' symbol).
-- - Ensuring referential integrity (e.g., every `Invoice` must belong to a valid `Customer`).
--
-- =================================================================================================================================
-- Step 1: Manual Validation using SQL Queries
-- =================================================================================================================================
--
-- Before enforcing rules, it's good practice to write queries to find existing data that violates them.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Find invalid data based on a pattern (e.g., email format)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- A simple rule for an email is that it must contain an '@' symbol and a '.'.
-- The `LIKE` operator is useful for this kind of pattern matching.

SELECT
    CustomerId,
    Email
FROM
    customers
WHERE
    Email NOT LIKE '%@%.%'; -- Find emails that don't match the pattern 'something@something.something'
-- In the Chinook database, this should return no results, as the data is clean.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Find values outside an expected range
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `UnitPrice` for a track in the `invoice_items` table should always be positive.

SELECT
    *
FROM
    invoice_items
WHERE
    UnitPrice <= 0;
-- This should also return no results.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Check for referential integrity manually
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Every `AlbumId` in the `tracks` table should correspond to a valid `AlbumId` in the `artists` table.
-- An `ANTI JOIN` (using `LEFT JOIN` and checking for `NULL`) is a great way to find "orphan" records.

SELECT
    t.TrackId,
    t.Name,
    t.AlbumId
FROM
    tracks t
LEFT JOIN
    albums a ON t.AlbumId = a.AlbumId
WHERE
    a.AlbumId IS NULL;
-- This query identifies tracks that point to a non-existent album. It should return no rows.

-- =================================================================================================================================
-- Step 2: Enforcing Data Integrity with Constraints
-- =================================================================================================================================
--
-- Constraints are rules defined on a table that prevent invalid data from being inserted, updated, or deleted.
-- They are the database's way of automatically enforcing data integrity.
--
-- Common constraints:
-- - `NOT NULL`: Ensures a column cannot have a NULL value.
-- - `UNIQUE`: Ensures all values in a column (or a set of columns) are unique.
-- - `PRIMARY KEY`: A combination of `NOT NULL` and `UNIQUE`. Uniquely identifies each row.
-- - `FOREIGN KEY`: Ensures that a value in a column matches a value in another table's primary key, enforcing referential integrity.
-- - `CHECK`: Ensures that values in a column satisfy a specific condition.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Adding Constraints (Conceptual)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The syntax to add constraints is typically `ALTER TABLE ... ADD CONSTRAINT ...`.
-- **NOTE**: Running these `ALTER` statements on a database with existing data will fail if the data violates the new constraint.
-- You must clean the data first!

-- Let's create a temporary table to demonstrate.
CREATE TEMP TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    sku TEXT,
    price REAL
);

-- Add a UNIQUE constraint to the SKU
-- ALTER TABLE products ADD CONSTRAINT uq_sku UNIQUE (sku);

-- Add a CHECK constraint to the price
-- ALTER TABLE products ADD CONSTRAINT chk_price CHECK (price > 0);

-- Now, let's try to insert some data that violates these rules.
-- INSERT INTO products (product_id, product_name, sku, price) VALUES (1, 'Test', 'SKU001', -5.00); -- This would fail due to the CHECK constraint.
-- INSERT INTO products (product_id, product_name, sku, price) VALUES (2, 'Test', 'SKU001', 5.00); -- This would fail due to the UNIQUE constraint if the first one succeeded.

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. Write a query to find any customers whose `Country` is 'USA' but whose `PostalCode` is not 5 digits long.
--    (Note: This is a simplified check and doesn't account for ZIP+4 codes).
SELECT
    CustomerId,
    FirstName,
    LastName,
    Country,
    PostalCode
FROM
    customers
WHERE
    Country = 'USA' AND LENGTH(PostalCode) != 5;

-- 2. Every track belongs to a genre. Write a query to find any tracks that have an invalid `GenreId`.
SELECT
    t.TrackId,
    t.Name,
    t.GenreId
FROM
    tracks t
LEFT JOIN
    genres g ON t.GenreId = g.GenreId
WHERE
    g.GenreId IS NULL;

-- 3. The `employees` table has a `ReportsTo` column that links an employee to their manager.
--    This is a self-referencing foreign key. Write a query to find any `ReportsTo` value that does not
--    correspond to a valid `EmployeeId`.
SELECT
    e1.EmployeeId,
    e1.FirstName || ' ' || e1.LastName AS EmployeeName,
    e1.ReportsTo
FROM
    employees e1
LEFT JOIN
    employees e2 ON e1.ReportsTo = e2.EmployeeId
WHERE
    e2.EmployeeId IS NULL AND e1.ReportsTo IS NOT NULL; -- Exclude the top manager who reports to no one

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Data validation is a critical final step in data cleaning. It ensures your data is not only clean in format but also
-- logical and consistent in value.
--
-- - Use **manual validation queries** (`WHERE`, `LIKE`, `JOIN`) to find and inspect existing data quality issues.
-- - Use **database constraints** (`CHECK`, `UNIQUE`, `FOREIGN KEY`) to proactively enforce rules and maintain data
--   integrity over time.
--
-- A clean, validated, and reliable dataset is the foundation of trustworthy analysis.
--
-- =================================================================================================================================
