/*
    File: 01_basic-queries/05_common_table_expressions.sql
    Topic: Basic Queries
    Purpose: Demonstrates the use of Common Table Expressions (CTEs) for query readability and modularity.
    Author: Trailblazer Analytics
    Created: 2025-06-21
    Updated: 2025-06-21
    SQL Flavors: ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery | ✅ Snowflake
    Notes:
      • CTEs are temporary, named result sets that you can reference within another SELECT, INSERT, UPDATE, or DELETE statement.
      • They are defined using the WITH clause.
*/

-- =================================================================================
-- Example: Using a CTE to simplify a complex query
-- =================================================================================

-- Scenario: We want to find all employees who work in the 'Sales' department and have a salary above the company average.

-- Define a CTE named 'sales_employees' that selects all employees from the 'Sales' department.
WITH sales_employees AS (
    SELECT
        employee_id,
        employee_name,
        department,
        salary
    FROM employees
    WHERE department = 'Sales'
),
-- Define another CTE to calculate the average salary across all employees.
average_salary AS (
    SELECT AVG(salary) as avg_sal FROM employees
)

-- Final Query: Select employees from the 'sales_employees' CTE whose salary is above the average.
SELECT
    se.employee_name,
    se.salary
FROM
    sales_employees se
CROSS JOIN
    average_salary avs
WHERE
    se.salary > avs.avg_sal;

/*
-- Expected Result:
-- This query will return a list of names and salaries for sales employees
-- who earn more than the overall average salary.
--
-- | employee_name | salary |
-- |---------------|--------|
-- | Jane Doe      | 75000  |
-- | ...           | ...    |
*/
