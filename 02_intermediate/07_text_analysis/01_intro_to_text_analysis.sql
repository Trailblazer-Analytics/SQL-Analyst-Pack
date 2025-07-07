/*
    File: 01_intro_to_text_analysis.sql
    Topic: Text Analysis
    Task: Introduction to Text Analysis and Basic String Functions
    Author: SQL Analyst Pack Community
    Date: 2024-07-15
    SQL Flavor: ANSI SQL, with flavor-specific notes.
*/

-- =================================================================================================================================
-- Introduction to Text Analysis in SQL
-- =================================================================================================================================
--
-- Text analysis involves parsing and deriving insights from unstructured text data. While specialized tools often handle
-- complex Natural Language Processing (NLP), SQL provides a powerful set of built-in functions for many common
-- text manipulation and analysis tasks directly within the database.
--
-- This is useful for:
-- - Cleaning and standardizing text fields (e.g., names, addresses).
-- - Extracting specific pieces of information from longer strings.
-- - Performing simple pattern matching.
--
-- This script covers the most fundamental string functions for concatenation, changing case, and finding the length of strings.
--
-- =================================================================================================================================
-- Step 1: Concatenation - Combining Strings
-- =================================================================================================================================
--
-- Concatenation is the process of joining two or more strings together.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Create a full name from first and last name columns
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The ANSI standard for string concatenation is the double pipe operator `||`.
-- SQL Server uses the `+` operator.

-- Standard SQL (PostgreSQL, Oracle, SQLite)
SELECT
    FirstName,
    LastName,
    FirstName || ' ' || LastName AS FullName
FROM
    customers;

-- SQL Server Syntax
-- SELECT FirstName + ' ' + LastName AS FullName FROM customers;

-- MySQL Syntax (uses the CONCAT function)
-- SELECT CONCAT(FirstName, ' ', LastName) AS FullName FROM customers;

-- =================================================================================================================================
-- Step 2: Case Conversion - UPPER and LOWER
-- =================================================================================================================================
--
-- Standardizing the case of text is a common data cleaning task, ensuring that searches and joins are case-insensitive.
-- `UPPER(string)` converts a string to all uppercase letters.
-- `LOWER(string)` converts a string to all lowercase letters.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Standardize email addresses to lowercase
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Storing all emails in lowercase is a best practice to prevent duplicate accounts for the same user.

SELECT
    Email AS OriginalEmail,
    LOWER(Email) AS LowercaseEmail
FROM
    customers;

-- =================================================================================================================================
-- Step 3: String Length - LENGTH or LEN
-- =================================================================================================================================
--
-- Finding the length of a string is useful for validation (e.g., checking if a postal code has the correct number of characters)
-- or for finding outliers.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Find the length of track names
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The function name varies between databases.
-- `LENGTH(string)` is common (PostgreSQL, MySQL, Oracle, SQLite).
-- `LEN(string)` is used in SQL Server.

SELECT
    Name AS TrackName,
    LENGTH(Name) AS NameLength
FROM
    tracks
ORDER BY
    NameLength DESC; -- Find the longest track names

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. Create a descriptive label for each track in the format: "Track: [Track Name] (Genre: [Genre Name])".
SELECT
    'Track: ' || t.Name || ' (Genre: ' || g.Name || ')' AS TrackLabel
FROM
    tracks t
JOIN
    genres g ON t.GenreId = g.GenreId;

-- 2. Find all customers whose last name is longer than 10 characters.
SELECT
    FirstName,
    LastName
FROM
    customers
WHERE
    LENGTH(LastName) > 10;

-- 3. Create a new email address for employees based on the pattern: `lower(firstname.lastname)@chinookcorp.com`.
SELECT
    FirstName,
    LastName,
    LOWER(FirstName || '.' || LastName) || '@chinookcorp.com' AS NewCorporateEmail
FROM
    employees;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- You have learned the basic building blocks of text manipulation in SQL.
-- - Concatenation (`||` or `+` or `CONCAT`) for combining strings.
-- - Case conversion (`UPPER`, `LOWER`) for standardization.
-- - Length calculation (`LENGTH`, `LEN`) for validation and analysis.
--
-- These simple functions are the foundation for more advanced text cleaning and analysis techniques.
--
-- =================================================================================================================================
