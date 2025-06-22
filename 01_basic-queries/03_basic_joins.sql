/*
    Script: 03_basic_joins.sql
    Description: This script demonstrates the use of basic SQL JOINs.
    Author: Your Name/Team
    Version: 1.0
    Last-Modified: 2023-10-27
*/

-- =================================================================================
-- Step-by-Step Guide
-- =================================================================================

-- Step 1: Use an INNER JOIN to combine rows from two tables based on a related column.
-- This example joins 'orders' and 'customers' tables on the 'customer_id' column.
-- SELECT orders.order_id, customers.customer_name
-- FROM orders
-- INNER JOIN customers ON orders.customer_id = customers.customer_id;

-- Step 2: Use a LEFT JOIN to retrieve all records from the left table and the matched records from the right table.
-- This example retrieves all customers and their orders, if any.
-- SELECT customers.customer_name, orders.order_id
-- FROM customers
-- LEFT JOIN orders ON customers.customer_id = orders.customer_id;

-- Step 3: Use a RIGHT JOIN to retrieve all records from the right table and the matched records from the left table.
-- This example retrieves all orders and the customers who placed them.
-- SELECT customers.customer_name, orders.order_id
-- FROM customers
-- RIGHT JOIN orders ON customers.customer_id = orders.customer_id;

-- =================================================================================
-- Conclusion
-- =================================================================================

-- This script covered the basic types of SQL JOINs: INNER, LEFT, and RIGHT.
