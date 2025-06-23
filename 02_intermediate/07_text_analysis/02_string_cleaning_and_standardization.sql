-- File: 07_text-analysis/02_string_cleaning_and_standardization.sql
-- Topic: String Cleaning and Standardization
-- Author: Alexander Nykolaiszyn
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates how to clean and standardize text data, which is a critical step in
-- text analysis. Common tasks include removing extra spaces, converting case, and correcting
-- inconsistent formatting.

-- Prerequisites:
-- No specific prerequisites, but a basic understanding of SQL SELECT statements is assumed.
-- This script uses the Chinook sample database.

-- Dialect Compatibility:
-- The examples use standard SQL functions available in most modern database systems,
-- including PostgreSQL, MySQL, SQL Server, Oracle, and SQLite. Notes are provided for any
-- dialect-specific variations.

---------------------------------------------------------------------------------------------------

-- Introduction to String Cleaning Functions

-- String cleaning is essential for ensuring data quality and consistency.
-- Key functions include TRIM, LTRIM, RTRIM, UPPER, LOWER, and REPLACE.

---------------------------------------------------------------------------------------------------

-- Example 1: Removing Leading and Trailing Spaces with TRIM, LTRIM, and RTRIM

-- Scenario: Customer names in the `customers` table might have extra spaces due to data entry errors.
-- We want to clean these up before analysis.

-- TRIM removes spaces from both ends of a string.
-- LTRIM removes spaces from the left (leading).
-- RTRIM removes spaces from the right (trailing).

-- Let's create a temporary table with messy data to see how it works.
-- Note: Temp table syntax varies across SQL dialects.

-- SQLite, PostgreSQL, SQL Server:
CREATE TEMP TABLE CustomerNames (
    Name VARCHAR(100)
);

-- MySQL:
-- CREATE TEMPORARY TABLE CustomerNames (
--     Name VARCHAR(100)
-- );

-- Oracle:
-- CREATE GLOBAL TEMPORARY TABLE CustomerNames (
--     Name VARCHAR(100)
-- ) ON COMMIT PRESERVE ROWS;

INSERT INTO CustomerNames (Name) VALUES
    ('  John Doe  '),
    ('   Jane Smith'),
    ('Richard Roe   ');

-- Now, let's clean the names.
SELECT
    Name,
    TRIM(Name) AS TrimmedName,
    LTRIM(Name) AS LeftTrimmedName,
    RTRIM(Name) AS RightTrimmedName
FROM CustomerNames;

-- Cleanup the temporary table
DROP TABLE CustomerNames;

---------------------------------------------------------------------------------------------------

-- Example 2: Standardizing Case with UPPER and LOWER

-- Scenario: We want to standardize email addresses to lowercase to avoid duplicates
-- caused by case differences (e.g., 'user@example.com' vs. 'User@Example.com').

-- UPPER converts a string to all uppercase letters.
-- LOWER converts a string to all lowercase letters.

SELECT
    Email,
    LOWER(Email) AS LowercaseEmail,
    UPPER(Email) AS UppercaseEmail
FROM
    customers
WHERE
    CustomerId IN (1, 2, 3); -- Limiting for a small sample

-- This is often used in WHERE clauses to ensure case-insensitive comparisons.
SELECT
    *
FROM
    customers
WHERE
    LOWER(Country) = 'usa';

---------------------------------------------------------------------------------------------------

-- Example 3: Replacing Substrings with REPLACE

-- Scenario: The `genres` table has a genre named "Sci Fi & Fantasy". We want to
-- standardize it to "Science Fiction & Fantasy".

-- REPLACE(string, from_substring, to_substring)
-- Replaces all occurrences of `from_substring` with `to_substring`.

SELECT
    Name,
    REPLACE(Name, 'Sci Fi', 'Science Fiction') AS StandardizedName
FROM
    genres
WHERE
    Name = 'Sci Fi & Fantasy';

-- Another example: Let's standardize phone numbers by removing dashes.
SELECT
    Phone,
    REPLACE(Phone, '-', '') AS StandardizedPhone
FROM
    customers
WHERE
    Country = 'USA'
    AND Phone IS NOT NULL
LIMIT 5; -- Limiting for a small sample

-- Note on LIMIT:
-- SQL Server/Oracle: Use `FETCH FIRST 5 ROWS ONLY` or `TOP 5`.
-- `SELECT TOP 5 Phone, REPLACE(Phone, '-', '') AS StandardizedPhone FROM customers WHERE Country = 'USA' AND Phone IS NOT NULL;`

---------------------------------------------------------------------------------------------------

-- Example 4: Combining Functions for Comprehensive Cleaning

-- Scenario: Imagine a messy `products` table where product codes are inconsistent.
-- They have extra spaces, mixed case, and use hyphens instead of underscores.
-- Let's standardize them to 'CODE_FORMAT'.

-- Let's create another temporary table.
CREATE TEMP TABLE MessyProducts (
    ProductCode VARCHAR(50)
);

INSERT INTO MessyProducts (ProductCode) VALUES
    ('  prod-a123  '),
    ('PROD-B456'),
    ('  prod-c789');

-- We can nest functions to perform multiple cleaning steps in one go.
-- The innermost function runs first.
SELECT
    ProductCode,
    UPPER(REPLACE(TRIM(ProductCode), '-', '_')) AS CleanedProductCode
FROM
    MessyProducts;

-- The steps are:
-- 1. TRIM(ProductCode): Removes leading/trailing spaces.
-- 2. REPLACE(...): Replaces hyphens with underscores.
-- 3. UPPER(...): Converts the result to uppercase.

-- Cleanup
DROP TABLE MessyProducts;

---------------------------------------------------------------------------------------------------

-- Practical Application: Cleaning Customer Addresses

-- Scenario: Let's clean the `BillingAddress` column from the `invoices` table.
-- We will trim spaces and convert the address to uppercase for consistency.

SELECT
    BillingAddress,
    UPPER(TRIM(BillingAddress)) AS StandardizedAddress
FROM
    invoices
LIMIT 10;

-- Note on LIMIT:
-- SQL Server/Oracle: Use `FETCH FIRST 10 ROWS ONLY` or `TOP 10`.

-- By applying these cleaning techniques, you ensure that your text data is consistent,
-- which improves query accuracy, reporting, and the overall quality of your analysis.
