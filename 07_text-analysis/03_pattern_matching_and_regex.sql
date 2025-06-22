-- File: 07_text-analysis/03_pattern_matching_and_regex.sql
-- Topic: Pattern Matching and Regular Expressions (Regex)
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates how to find patterns in text data using SQL's LIKE operator
-- and regular expressions (regex). These techniques are powerful for filtering and
-- validating data based on specific text structures.

-- Prerequisites:
-- A basic understanding of SQL SELECT and WHERE clauses is required.
-- This script uses the Chinook sample database.

-- Dialect Compatibility:
-- The LIKE operator is standard SQL. Regular expression syntax and function names vary
-- significantly across database systems. Common functions include REGEXP, REGEXP_LIKE,
-- and SIMILAR TO.
-- - PostgreSQL: Uses `SIMILAR TO` and POSIX-style regex with `~` or `~*`.
-- - MySQL: Uses `REGEXP` or `RLIKE`.
-- - SQL Server: Uses `LIKE` for simple patterns; regex requires CLR integration.
-- - Oracle: Uses `REGEXP_LIKE`.
-- - SQLite: Uses the `REGEXP` operator, which needs to be implemented by a user-defined function.

---------------------------------------------------------------------------------------------------

-- Section 1: Basic Pattern Matching with LIKE

-- The `LIKE` operator is used in a WHERE clause to search for a specified pattern in a column.
-- It uses two wildcard characters:
-- `%`: Represents zero, one, or multiple characters.
-- `_`: Represents a single character.

-- Example 1.1: Find all tracks that start with 'A'
SELECT
    Name,
    Composer
FROM
    tracks
WHERE
    Name LIKE 'A%';

-- Example 1.2: Find all customers whose last name ends with 's'
SELECT
    FirstName,
    LastName
FROM
    customers
WHERE
    LastName LIKE '%s';

-- Example 1.3: Find all artists with 'Beatles' anywhere in their name
SELECT
    Name
FROM
    artists
WHERE
    Name LIKE '%Beatles%';

-- Example 1.4: Find all employees hired in 2003
-- The `HireDate` is a datetime field, so we need to convert it to text first.
-- Note: Date formatting functions vary by SQL dialect.

-- SQLite / MySQL:
SELECT
    FirstName,
    LastName,
    HireDate
FROM
    employees
WHERE
    STRFTIME('%Y', HireDate) = '2003';

-- PostgreSQL:
-- SELECT FirstName, LastName, HireDate FROM employees WHERE EXTRACT(YEAR FROM HireDate) = 2003;

-- SQL Server:
-- SELECT FirstName, LastName, HireDate FROM employees WHERE YEAR(HireDate) = 2003;

-- Example 1.5: Using the `_` wildcard
-- Find all customers with a first name of 4 letters, starting with 'J' and ending with 'n' (e.g., John).
SELECT
    FirstName,
    LastName
FROM
    customers
WHERE
    FirstName LIKE 'J__n'; -- Two underscores for two characters

---------------------------------------------------------------------------------------------------

-- Section 2: Advanced Pattern Matching with LIKE (Not universally supported)

-- Some SQL dialects extend `LIKE` with character sets.
-- `[charlist]`: Matches any single character in the list.
-- `[^charlist]` or `[!charlist]`: Matches any single character not in the list.

-- This is common in SQL Server.

-- Example 2.1 (SQL Server): Find customers whose first name starts with A, B, or C.
-- SELECT FirstName, LastName
-- FROM customers
-- WHERE FirstName LIKE '[ABC]%';

-- Example 2.2 (SQL Server): Find customers whose first name does NOT start with A, B, or C.
-- SELECT FirstName, LastName
-- FROM customers
-- WHERE FirstName LIKE '[^ABC]%';

-- For other databases, you often use regular expressions for this.

---------------------------------------------------------------------------------------------------

-- Section 3: Introduction to Regular Expressions (Regex)

-- Regex provides a more powerful and flexible way to match complex patterns.
-- The syntax and function names differ between database systems.

-- Common Regex Metacharacters:
-- `.`      : Matches any single character.
-- `^`      : Matches the start of the string.
-- `$`      : Matches the end of the string.
-- `*`      : Matches the preceding element zero or more times.
-- `+`      : Matches the preceding element one or more times.
-- `?`      : Matches the preceding element zero or one time.
-- `[abc]`  : Matches either a, b, or c.
-- `[a-z]`  : Matches any lowercase letter.
-- `\d`     : Matches a digit (in some flavors).

-- Example 3.1: Using Regex to find tracks that contain only numbers.
-- This is useful for identifying data quality issues.

-- MySQL / SQLite (with user function):
SELECT
    Name
FROM
    tracks
WHERE
    Name REGEXP '^[0-9]+$';

-- PostgreSQL:
-- SELECT Name FROM tracks WHERE Name ~ '^[0-9]+$';

-- Oracle:
-- SELECT Name FROM tracks WHERE REGEXP_LIKE(Name, '^[0-9]+$');

-- Example 3.2: Find all customers with a gmail.com email address.

-- MySQL / SQLite:
SELECT
    FirstName,
    LastName,
    Email
FROM
    customers
WHERE
    Email REGEXP '@gmail\.com$'; -- We escape the dot `.` because it's a special character.

-- PostgreSQL:
-- SELECT FirstName, LastName, Email FROM customers WHERE Email ~ '@gmail\.com$';

-- Oracle:
-- SELECT FirstName, LastName, Email FROM customers WHERE REGEXP_LIKE(Email, '@gmail\.com$');

-- Example 3.3: Find employees with a phone number in the standard North American format (e.g., +1 (XXX) XXX-XXXX)

-- MySQL / SQLite:
SELECT
    FirstName,
    LastName,
    Phone
FROM
    employees
WHERE
    Phone REGEXP '\+1 \\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}';

-- PostgreSQL:
-- SELECT FirstName, LastName, Phone FROM employees WHERE Phone ~ '\+1 \([0-9]{3}\) [0-9]{3}-[0-9]{4}';

-- Oracle:
-- SELECT FirstName, LastName, Phone FROM employees WHERE REGEXP_LIKE(Phone, '\+1 \([0-9]{3}\) [0-9]{3}-[0-9]{4}');

-- This demonstrates the power of regex for validating structured text data.
-- By mastering pattern matching, you can perform sophisticated data filtering and cleaning tasks.
