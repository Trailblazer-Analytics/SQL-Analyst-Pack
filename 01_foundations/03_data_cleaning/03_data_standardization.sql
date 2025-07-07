/*
    File: 03_data_standardization.sql
    Topic: Data Cleaning
    Task: Data Standardization
    Author: SQL Analyst Pack Community
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Data Standardization
-- =================================================================================================================================
--
-- Data often comes from various sources in inconsistent formats. For example, state names might be stored as
-- 'California', 'CA', or 'california'. Names could have extra whitespace, and text could be in mixed case.
--
-- Data standardization is the process of transforming data into a consistent, common format. This is crucial for:
-- - **Accurate Joins**: Ensuring that keys from different tables match correctly.
-- - **Correct Grouping and Aggregation**: Preventing the same entity from being treated as multiple different groups.
-- - **Reliable Filtering**: Making sure your `WHERE` clauses don't miss records due to formatting issues.
--
-- This script covers common standardization tasks like case conversion, trimming whitespace, and basic text cleaning.
--
-- =================================================================================================================================
-- Step 1: Case Conversion
-- =================================================================================================================================
--
-- Inconsistent casing (e.g., 'usa', 'USA', 'Usa') can cause issues in joins and filters. The standard solution is to
-- convert text to a consistent case, either all uppercase or all lowercase.
--
-- `UPPER(string)`: Converts a string to uppercase.
-- `LOWER(string)`: Converts a string to lowercase.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Standardizing country names to uppercase for consistent filtering
-- ---------------------------------------------------------------------------------------------------------------------------------
-- This query finds all customers from Canada, regardless of how 'Canada' is cased in the database.

SELECT
    FirstName,
    LastName,
    Country
FROM
    customers
WHERE
    UPPER(Country) = 'CANADA';

-- To permanently fix the data, you would use an UPDATE statement.
-- **IMPORTANT**: Be careful with UPDATE. Always test with SELECT first.
-- UPDATE customers SET Country = UPPER(Country);

-- =================================================================================================================================
-- Step 2: Trimming Whitespace
-- =================================================================================================================================
--
-- Leading or trailing whitespace characters are invisible but can prevent matches in joins and WHERE clauses.
-- For example, ' apple' is not the same as 'apple ', which is not the same as 'apple'.
--
-- `TRIM(string)`: Removes both leading and trailing whitespace (or other specified characters).
-- `LTRIM(string)`: Removes leading whitespace.
-- `RTRIM(string)`: Removes trailing whitespace.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Cleaning a column with potential whitespace issues
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's imagine the `artists.Name` column could have extra spaces.

SELECT
    Name,        -- Original name
    TRIM(Name)   -- Name with whitespace removed
FROM
    artists
WHERE
    Name LIKE ' %' OR Name LIKE '% '; -- Find names with leading or trailing spaces

-- To fix this permanently:
-- UPDATE artists SET Name = TRIM(Name);

-- =================================================================================================================================
-- Step 3: Basic Text Cleaning and Replacement
-- =================================================================================================================================
--
-- Sometimes you need to replace or remove specific characters or substrings to standardize your data.
-- The `REPLACE(string, from_substring, to_substring)` function is perfect for this.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Standardizing phone number formats
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's say we want to remove all parentheses, spaces, and dashes from phone numbers to create a standard numeric format.
-- We can nest `REPLACE` functions to do this.

SELECT
    Phone AS OriginalPhone,
    REPLACE(REPLACE(REPLACE(Phone, '(', ''), ')', ''), '-', '') AS StandardizedPhone_Step1,
    REPLACE(REPLACE(REPLACE(REPLACE(Phone, '(', ''), ')', ''), '-', ''), ' ', '') AS StandardizedPhone_Final
FROM
    customers
WHERE
    Phone IS NOT NULL;

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. The `genres` table contains music genres. Write a query to display all genre names in lowercase.
SELECT Name, LOWER(Name) AS LowercaseName FROM genres;

-- 2. Customer emails should be stored in a consistent, lowercase format to avoid duplicate accounts.
--    Write a query that shows the original email and the standardized (trimmed and lowercased) email for all customers.
SELECT
    Email AS OriginalEmail,
    LOWER(TRIM(Email)) AS StandardizedEmail
FROM
    customers;

-- 3. The `billingaddress` in the `invoices` table contains street information. Sometimes, abbreviations like 'St.' for 'Street'
--    or 'Ave.' for 'Avenue' can cause inconsistencies. Write a query to standardize 'St.' to 'Street'.
SELECT
    BillingAddress AS OriginalAddress,
    REPLACE(BillingAddress, 'St.', 'Street') AS StandardizedAddress
FROM
    invoices
WHERE
    BillingAddress LIKE '%St.%';

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Data standardization is a foundational step in data cleaning. By ensuring your data is in a consistent format,
-- you significantly improve the reliability and accuracy of your queries and analysis.
--
-- Key functions to remember:
-- - `UPPER()` and `LOWER()` for case consistency.
-- - `TRIM()`, `LTRIM()`, `RTRIM()` for removing whitespace.
-- - `REPLACE()` for substituting text patterns.
--
-- Next, we will look at validating data against a set of rules or constraints.
--
-- =================================================================================================================================
