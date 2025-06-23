/*
    Script: 04_advanced_joins.sql
    Description: This script demonstrates advanced SQL JOIN techniques.
    Author: Your Name/Team
    Version: 1.0
    Last-Modified: 2023-10-27
*/

-- =================================================================================
-- Step-by-Step Guide
-- =================================================================================

-- Step 1: Use a FULL OUTER JOIN to retrieve all records when there is a match in either the left or right table.
-- This example retrieves all customers and all orders, matching them where possible.
-- SELECT customers.customer_name, orders.order_id
-- FROM customers
-- FULL OUTER JOIN orders ON customers.customer_id = orders.customer_id;

-- Step 2: Use a CROSS JOIN to create a Cartesian product of two tables.
-- This example combines every customer with every product, which can be useful for generating all possible combinations.
-- SELECT customers.customer_name, products.product_name
-- FROM customers
-- CROSS JOIN products;

-- Step 3: Use a SELF JOIN to join a table to itself.
-- This example finds employees who have the same manager.
-- SELECT e1.employee_name, e2.employee_name AS manager_name
-- FROM employees e1
-- JOIN employees e2 ON e1.manager_id = e2.employee_id;

-- =================================================================================
-- Conclusion
-- =================================================================================

-- This script covered advanced JOINs, including FULL OUTER JOIN, CROSS JOIN, and SELF JOIN.
