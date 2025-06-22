-- File: 13_testing_and_validation/01_data_validation_and_testing.sql
-- Topic: Data Validation and Testing
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates how to write SQL queries for data validation and testing.
-- These tests are crucial for maintaining data quality, ensuring integrity, and verifying
-- the results of data transformations.

-- Prerequisites:
-- A solid understanding of aggregate functions, `CASE` statements, and `JOIN`s.
-- Familiarity with the concept of primary and foreign keys is essential.

-- Dialect Compatibility:
-- The queries use standard SQL functions and should be compatible with most database systems,
-- including PostgreSQL, MySQL, SQL Server, Oracle, and SQLite.

---------------------------------------------------------------------------------------------------

-- Section 1: Why is Data Validation in SQL Important?

-- Data validation is the process of ensuring that data is accurate, consistent, and complete.
-- In a data warehouse or analytical database, "bad data" can lead to incorrect reports,
-- flawed analysis, and poor business decisions. SQL is a powerful tool for running tests
-- directly against the database to catch issues early.

-- Common Data Quality Checks:
-- 1. Uniqueness: Are primary keys unique?
-- 2. Not-Null Constraints: Are critical fields populated?
-- 3. Referential Integrity: Do foreign keys point to existing records?
-- 4. Value Constraints: Are values within an expected range or set?
-- 5. Consistency: Does the data make sense logically?

---------------------------------------------------------------------------------------------------

-- Section 2: Uniqueness and Not-Null Tests

-- These are the most fundamental data quality checks.

-- Test 2.1: Check for duplicate primary keys.
-- A primary key column must contain unique values. This query should return a count of 0.
SELECT
    CustomerId, -- The primary key column
    COUNT(*) AS Occurrences
FROM
    customers
GROUP BY
    CustomerId
HAVING
    COUNT(*) > 1;

-- Test 2.2: Check for NULL values in a critical column.
-- For example, every customer should have a first and last name. This query should return 0 rows.
SELECT
    CustomerId,
    FirstName,
    LastName
FROM
    customers
WHERE
    FirstName IS NULL OR LastName IS NULL;

---------------------------------------------------------------------------------------------------

-- Section 3: Referential Integrity Tests

-- Referential integrity ensures that relationships between tables are valid.
-- A foreign key in one table must match a primary key in another table.

-- Test 3.1: Check for "orphan" records.
-- Every `CustomerId` in the `invoices` table should exist in the `customers` table.
-- This query should return 0 rows.
SELECT
    inv.CustomerId
FROM
    invoices inv
LEFT JOIN
    customers cust ON inv.CustomerId = cust.CustomerId
WHERE
    cust.CustomerId IS NULL; -- If the join fails, the customer doesn't exist.

-- Test 3.2: Check for orphan invoice items.
-- Every `InvoiceId` in the `invoice_items` table must exist in the `invoices` table.
SELECT
    ii.InvoiceId
FROM
    invoice_items ii
LEFT JOIN
    invoices i ON ii.InvoiceId = i.InvoiceId
WHERE
    i.InvoiceId IS NULL;

---------------------------------------------------------------------------------------------------

-- Section 4: Value and Consistency Tests

-- These tests check if data values conform to business rules.

-- Test 4.1: Check for valid values in a specific column.
-- For example, the `Country` column in the `customers` table should not contain invalid or misspelled names.
-- This is often a manual or semi-automated check.
SELECT DISTINCT
    Country
FROM
    customers
ORDER BY
    Country;
-- An analyst would review this list for anomalies (e.g., 'USA' vs 'U.S.A').

-- Test 4.2: Check for logical consistency.
-- An invoice total should equal the sum of its line items. This is a critical business rule.
-- The following query identifies any invoices where the numbers don't add up.
-- It should return 0 rows.

WITH InvoiceLineItemTotals AS (
    SELECT
        InvoiceId,
        SUM(UnitPrice * Quantity) AS CalculatedTotal
    FROM
        invoice_items
    GROUP BY
        InvoiceId
)
SELECT
    i.InvoiceId,
    i.Total AS StoredTotal,
    ilt.CalculatedTotal
FROM
    invoices i
JOIN
    InvoiceLineItemTotals ilt ON i.InvoiceId = ilt.InvoiceId
WHERE
    -- Using a small tolerance for floating point inaccuracies.
    ABS(i.Total - ilt.CalculatedTotal) > 0.01;

-- These validation queries can be automated and run as part of a regular data quality
-- monitoring process to ensure the reliability of your data.
