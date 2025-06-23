/*
    File        : 01_foundations/01_basic_queries/02_filtering_and_selection.sql
    Topic       : Basic Queries
    Purpose     : Demonstrates fundamental data selection and filtering techniques using SELECT and WHERE.
    Author      : Alexander Nykolaiszyn
    Created     : 2025-06-22
    Updated     : 2025-06-23
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery | ✅ Snowflake
    Notes       : • This is the starting point for almost any data analysis task.
*/

-- =============================================================================
-- Selecting Data with `SELECT`
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Exercise 1: Select all columns from the `Artist` table.
-- -----------------------------------------------------------------------------
-- The `*` is a wildcard that means "all columns".
SELECT * FROM Artist;

-- -----------------------------------------------------------------------------
-- Exercise 2: Select only the `Name` and `Composer` from the `Track` table.
-- -----------------------------------------------------------------------------
-- It is best practice to specify only the columns you need.
SELECT Name, Composer FROM Track;

-- -----------------------------------------------------------------------------
-- Exercise 3: Select the `Name` column but show it with a different header.
-- -----------------------------------------------------------------------------
-- The `AS` keyword creates an alias, which is a temporary, more readable name.
SELECT Name AS ArtistName FROM Artist;


-- =============================================================================
-- Filtering Data with `WHERE`
-- =============================================================================

-- The `WHERE` clause is used to filter records based on specific conditions.

-- -----------------------------------------------------------------------------
-- Exercise 4: Find the customer with `CustomerId` 10.
-- -----------------------------------------------------------------------------
SELECT * FROM Customer WHERE CustomerId = 10;

-- -----------------------------------------------------------------------------
-- Exercise 5: Find all invoices with a total greater than $10.
-- -----------------------------------------------------------------------------
SELECT * FROM Invoice WHERE Total > 10;

-- -----------------------------------------------------------------------------
-- Exercise 6: Find all tracks composed by "AC/DC".
-- -----------------------------------------------------------------------------
-- Text values must be enclosed in single quotes.
SELECT * FROM Track WHERE Composer = 'AC/DC';

-- -----------------------------------------------------------------------------
-- Exercise 7: Find all invoices for customers in Brazil.
-- -----------------------------------------------------------------------------
SELECT * FROM Invoice WHERE BillingCountry = 'Brazil';
