/*
    File        : 01_basic-queries/01_basic_where_filtering.sql
    Topic       : Basic Queries
    Purpose     : Demonstrates basic data filtering using the WHERE clause with practical examples.
    Author      : SQL Analyst Pack Contributors
    Created     : 2025-06-22
    Updated     : 2025-06-22
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery | ✅ Snowflake
    Notes       : • Uses the Chinook sample database
                  • Perfect starting point for beginners learning SQL filtering
*/

-- =================================================================================
-- Step-by-Step Guide
-- =================================================================================

-- Step 1: Select all columns from a table to see the unfiltered data.
-- SELECT * FROM your_table;

-- Step 2: Filter rows based on a single condition.
-- This example selects all records where the 'department' is 'Sales'.
-- SELECT * FROM your_table WHERE department = 'Sales';

-- Step 3: Filter rows based on multiple conditions using AND.
-- This example selects all records where the 'department' is 'Sales' AND the 'salary' is greater than 50000.
-- SELECT * FROM your_table WHERE department = 'Sales' AND salary > 50000;

-- Step 4: Filter rows based on multiple conditions using OR.
-- This example selects all records where the 'department' is 'Sales' OR the 'department' is 'Marketing'.
-- SELECT * FROM your_table WHERE department = 'Sales' OR department = 'Marketing';

-- Step 5: Filter rows using NOT to exclude a certain condition.
-- This example selects all records where the 'department' is NOT 'Sales'.
-- SELECT * FROM your_table WHERE NOT department = 'Sales';

-- Step 6: Combine AND and OR conditions with parentheses for clarity.
-- This example selects all records where the 'department' is 'Sales' OR 'Marketing' AND the 'salary' is above 50000.
-- SELECT * FROM your_table WHERE (department = 'Sales' OR department = 'Marketing') AND salary > 50000;

-- Step 7: Use IN for cleaner code when filtering by multiple values.
-- This example selects all records where the 'department' is either 'Sales', 'Marketing', or 'HR'.
-- SELECT * FROM your_table WHERE department IN ('Sales', 'Marketing', 'HR');

-- Step 8: Use BETWEEN to filter results within a certain range.
-- This example selects all records where the 'salary' is between 40000 and 60000.
-- SELECT * FROM your_table WHERE salary BETWEEN 40000 AND 60000;

-- =================================================================================
-- Conclusion
-- =================================================================================

-- This script demonstrated how to use the WHERE clause to filter data based on single or multiple conditions.
