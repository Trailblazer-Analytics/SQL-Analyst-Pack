/*
Title: Modern SQL Features
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Description: Advanced SQL features like window functions, OVER clauses, and more
*/

-- ==========================================
-- INTRODUCTION TO MODERN SQL FEATURES
-- ==========================================
-- Modern SQL implementations provide powerful features that go beyond basic querying.
-- This script demonstrates advanced SQL features that improve analytics capabilities.

-- ==========================================
-- 1. SETUP EXAMPLE DATA
-- ==========================================

-- Sales data by region, product, and time
CREATE TABLE IF NOT EXISTS sales (
    sale_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    region_id INT NOT NULL,
    employee_id INT NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(4, 2) NOT NULL
);

-- Generate sample sales data
INSERT INTO sales (sale_id, product_id, region_id, employee_id, sale_date, quantity, unit_price, discount)
SELECT 
    generate_series,  -- sale_id
    1 + mod(generate_series, 10),  -- product_id (1-10)
    1 + mod(generate_series / 10, 5),  -- region_id (1-5)
    1 + mod(generate_series / 5, 20),  -- employee_id (1-20)
    date '2024-01-01' + (mod(generate_series, 365) || ' days')::interval,  -- sale_date (2024)
    1 + mod(generate_series, 10),  -- quantity (1-10)
    100 + mod(generate_series, 900),  -- unit_price (100-999)
    0.05 * (1 + mod(generate_series / 100, 5))  -- discount (0.05-0.25)
FROM generate_series(1, 1000);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    release_date DATE NOT NULL,
    cost DECIMAL(10, 2) NOT NULL
);

-- Insert sample product data
INSERT INTO products (product_id, product_name, category, release_date, cost)
VALUES
    (1, 'Laptop Pro', 'Electronics', '2023-01-15', 800),
    (2, 'Smartphone X', 'Electronics', '2023-02-20', 600),
    (3, 'Wireless Headphones', 'Audio', '2023-03-10', 150),
    (4, 'Smart Watch', 'Wearables', '2023-04-05', 250),
    (5, 'Tablet Mini', 'Electronics', '2023-05-12', 350),
    (6, 'Bluetooth Speaker', 'Audio', '2023-06-01', 80),
    (7, 'Digital Camera', 'Photography', '2023-07-15', 450),
    (8, 'Gaming Console', 'Electronics', '2023-08-22', 500),
    (9, 'Fitness Tracker', 'Wearables', '2023-09-10', 120),
    (10, 'VR Headset', 'Electronics', '2023-10-05', 300);

-- Regions table
CREATE TABLE IF NOT EXISTS regions (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL
);

-- Insert sample region data
INSERT INTO regions (region_id, region_name, country)
VALUES
    (1, 'East', 'USA'),
    (2, 'West', 'USA'),
    (3, 'North', 'Canada'),
    (4, 'South', 'Mexico'),
    (5, 'Central', 'USA');

-- Employees table
CREATE TABLE IF NOT EXISTS employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    region_id INT NOT NULL,
    manager_id INT,
    salary DECIMAL(10, 2) NOT NULL
);

-- Insert sample employee data
INSERT INTO employees (employee_id, first_name, last_name, hire_date, region_id, manager_id, salary)
VALUES
    (1, 'John', 'Smith', '2020-01-15', 1, NULL, 120000),
    (2, 'Sarah', 'Johnson', '2020-02-01', 1, 1, 90000),
    (3, 'Michael', 'Williams', '2020-03-10', 1, 1, 85000),
    (4, 'Jessica', 'Brown', '2020-04-15', 2, 1, 95000),
    (5, 'David', 'Miller', '2020-05-20', 2, 4, 80000),
    (6, 'Emily', 'Davis', '2020-06-10', 2, 4, 82000),
    (7, 'Robert', 'Wilson', '2020-07-05', 3, 1, 88000),
    (8, 'Amanda', 'Taylor', '2020-08-15', 3, 7, 78000),
    (9, 'Daniel', 'Anderson', '2020-09-20', 3, 7, 76000),
    (10, 'Jennifer', 'Thomas', '2020-10-01', 4, 1, 92000),
    (11, 'Matthew', 'Jackson', '2020-11-15', 4, 10, 79000),
    (12, 'Laura', 'White', '2020-12-10', 4, 10, 81000),
    (13, 'Christopher', 'Harris', '2021-01-05', 5, 1, 94000),
    (14, 'Nicole', 'Martin', '2021-02-10', 5, 13, 77000),
    (15, 'James', 'Thompson', '2021-03-15', 5, 13, 75000),
    (16, 'Elizabeth', 'Garcia', '2021-04-10', 1, 2, 65000),
    (17, 'Andrew', 'Martinez', '2021-05-20', 2, 5, 68000),
    (18, 'Michelle', 'Robinson', '2021-06-15', 3, 8, 62000),
    (19, 'Joseph', 'Clark', '2021-07-01', 4, 11, 64000),
    (20, 'Patricia', 'Rodriguez', '2021-08-10', 5, 14, 66000);

-- ==========================================
-- 2. WINDOW FUNCTIONS WITH OVER CLAUSE
-- ==========================================

-- Basic window function: ROW_NUMBER()
SELECT 
    sale_id,
    region_id,
    sale_date,
    quantity * unit_price * (1 - discount) AS sale_amount,
    ROW_NUMBER() OVER (PARTITION BY region_id ORDER BY sale_date) AS row_num
FROM sales
WHERE sale_date BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY region_id, sale_date;

-- Multiple window functions together
SELECT 
    sale_id,
    region_id,
    sale_date,
    quantity * unit_price * (1 - discount) AS sale_amount,
    ROW_NUMBER() OVER (PARTITION BY region_id ORDER BY sale_date) AS row_num,
    RANK() OVER (PARTITION BY region_id ORDER BY quantity * unit_price * (1 - discount) DESC) AS amount_rank,
    DENSE_RANK() OVER (PARTITION BY region_id ORDER BY quantity * unit_price * (1 - discount) DESC) AS amount_dense_rank
FROM sales
WHERE sale_date BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY region_id, amount_rank;

-- ==========================================
-- 3. AGGREGATES WITH WINDOW FUNCTIONS
-- ==========================================

-- Running totals and moving averages
SELECT 
    sale_id,
    region_id,
    sale_date,
    quantity * unit_price * (1 - discount) AS sale_amount,
    SUM(quantity * unit_price * (1 - discount)) OVER (
        PARTITION BY region_id 
        ORDER BY sale_date
    ) AS running_total,
    AVG(quantity * unit_price * (1 - discount)) OVER (
        PARTITION BY region_id 
        ORDER BY sale_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3day
FROM sales
WHERE sale_date BETWEEN '2024-01-01' AND '2024-01-15'
ORDER BY region_id, sale_date;

-- Cumulative distribution and percentiles
SELECT 
    sale_id,
    employee_id,
    quantity * unit_price * (1 - discount) AS sale_amount,
    CUME_DIST() OVER (
        ORDER BY quantity * unit_price * (1 - discount)
    ) AS cumulative_distribution,
    PERCENT_RANK() OVER (
        ORDER BY quantity * unit_price * (1 - discount)
    ) AS percent_rank,
    NTILE(4) OVER (
        ORDER BY quantity * unit_price * (1 - discount)
    ) AS quartile
FROM sales
WHERE sale_date BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY sale_amount;

-- ==========================================
-- 4. WINDOW FRAMES
-- ==========================================

-- Different window frame options
SELECT 
    sale_id,
    sale_date,
    quantity * unit_price * (1 - discount) AS sale_amount,
    
    -- Default frame (RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    SUM(quantity * unit_price * (1 - discount)) OVER (
        ORDER BY sale_date
    ) AS running_total_default,
    
    -- Rows frame (specific number of rows)
    SUM(quantity * unit_price * (1 - discount)) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) AS sum_3_preceding_rows,
    
    -- Range frame (logical range of values)
    SUM(quantity * unit_price * (1 - discount)) OVER (
        ORDER BY sale_date
        RANGE BETWEEN INTERVAL '3 days' PRECEDING AND CURRENT ROW
    ) AS sum_3_preceding_days,
    
    -- Unbounded frames
    AVG(quantity * unit_price * (1 - discount)) OVER (
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS overall_average
FROM sales
WHERE sale_date BETWEEN '2024-01-01' AND '2024-01-10'
ORDER BY sale_date;

-- ==========================================
-- 5. LAG AND LEAD FUNCTIONS
-- ==========================================

-- Compare values with previous and next records
SELECT 
    sale_id,
    sale_date,
    quantity * unit_price * (1 - discount) AS sale_amount,
    LAG(quantity * unit_price * (1 - discount)) OVER (
        ORDER BY sale_date
    ) AS prev_day_amount,
    LEAD(quantity * unit_price * (1 - discount)) OVER (
        ORDER BY sale_date
    ) AS next_day_amount,
    
    -- Calculate day-over-day change
    (quantity * unit_price * (1 - discount)) - 
        LAG(quantity * unit_price * (1 - discount)) OVER (
            ORDER BY sale_date
        ) AS day_over_day_change,
    
    -- Calculate day-over-day percentage change
    CASE 
        WHEN LAG(quantity * unit_price * (1 - discount)) OVER (ORDER BY sale_date) = 0 THEN NULL
        ELSE ROUND(
            (
                (quantity * unit_price * (1 - discount)) - 
                LAG(quantity * unit_price * (1 - discount)) OVER (ORDER BY sale_date)
            ) / 
            LAG(quantity * unit_price * (1 - discount)) OVER (ORDER BY sale_date) * 100,
            2
        ) 
    END AS day_over_day_pct_change
FROM sales
WHERE 
    sale_date BETWEEN '2024-01-01' AND '2024-01-10'
    AND region_id = 1
ORDER BY sale_date;

-- ==========================================
-- 6. FIRST_VALUE AND LAST_VALUE
-- ==========================================

-- Identify first and last values in groups
SELECT 
    product_id,
    sale_date,
    quantity * unit_price * (1 - discount) AS sale_amount,
    FIRST_VALUE(quantity * unit_price * (1 - discount)) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_sale_amount,
    LAST_VALUE(quantity * unit_price * (1 - discount)) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_sale_amount,
    
    -- Calculate total change over period
    LAST_VALUE(quantity * unit_price * (1 - discount)) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) - 
    FIRST_VALUE(quantity * unit_price * (1 - discount)) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS total_change
FROM sales
WHERE 
    sale_date BETWEEN '2024-01-01' AND '2024-01-31'
    AND product_id BETWEEN 1 AND 5
ORDER BY product_id, sale_date;

-- ==========================================
-- 7. PIVOT AND UNPIVOT OPERATIONS
-- ==========================================

-- Pivot: Convert rows to columns
-- This example transforms monthly sales data from rows to columns (crosstab)
-- SQL Server syntax:
/*
SELECT 
    product_name,
    [1] AS Jan,
    [2] AS Feb,
    [3] AS Mar,
    [4] AS Apr
FROM (
    SELECT 
        p.product_name,
        MONTH(s.sale_date) AS sale_month,
        SUM(s.quantity * s.unit_price * (1 - s.discount)) AS monthly_sales
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE YEAR(s.sale_date) = 2024
    GROUP BY p.product_name, MONTH(s.sale_date)
) AS source_data
PIVOT (
    SUM(monthly_sales)
    FOR sale_month IN ([1], [2], [3], [4])
) AS pivot_table
ORDER BY product_name;
*/

-- PostgreSQL equivalent using crosstab (requires tablefunc extension)
/*
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM crosstab(
    'SELECT 
        p.product_name,
        EXTRACT(MONTH FROM s.sale_date)::INT AS sale_month,
        SUM(s.quantity * s.unit_price * (1 - s.discount)) AS monthly_sales
     FROM sales s
     JOIN products p ON s.product_id = p.product_id
     WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
     GROUP BY p.product_name, EXTRACT(MONTH FROM s.sale_date)
     ORDER BY 1, 2',
    'SELECT m FROM generate_series(1, 4) m'
) AS ct (
    product_name VARCHAR,
    "Jan" NUMERIC,
    "Feb" NUMERIC,
    "Mar" NUMERIC,
    "Apr" NUMERIC
);
*/

-- PostgreSQL alternative using conditional aggregation
SELECT 
    p.product_name,
    SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 1 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Jan,
    SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 2 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Feb,
    SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 3 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Mar,
    SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 4 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Apr
FROM sales s
JOIN products p ON s.product_id = p.product_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
GROUP BY p.product_name
ORDER BY p.product_name;

-- Unpivot: Convert columns to rows
-- SQL Server syntax:
/*
-- First, create a temp table with pivoted data
SELECT 
    product_name,
    [1] AS Jan,
    [2] AS Feb,
    [3] AS Mar,
    [4] AS Apr
INTO #temp_pivot
FROM (
    SELECT 
        p.product_name,
        MONTH(s.sale_date) AS sale_month,
        SUM(s.quantity * s.unit_price * (1 - s.discount)) AS monthly_sales
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE YEAR(s.sale_date) = 2024
    GROUP BY p.product_name, MONTH(s.sale_date)
) AS source_data
PIVOT (
    SUM(monthly_sales)
    FOR sale_month IN ([1], [2], [3], [4])
) AS pivot_table;

-- Now unpivot the data
SELECT 
    product_name,
    month_name,
    monthly_sales
FROM #temp_pivot
UNPIVOT (
    monthly_sales
    FOR month_name IN (Jan, Feb, Mar, Apr)
) AS unpivot_table
ORDER BY product_name, 
CASE month_name
    WHEN 'Jan' THEN 1
    WHEN 'Feb' THEN 2
    WHEN 'Mar' THEN 3
    WHEN 'Apr' THEN 4
END;

DROP TABLE #temp_pivot;
*/

-- PostgreSQL equivalent using UNION ALL
SELECT 
    product_name,
    'Jan' AS month_name,
    Jan AS monthly_sales
FROM (
    SELECT 
        p.product_name,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 1 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Jan,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 2 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Feb,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 3 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Mar,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 4 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Apr
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
    GROUP BY p.product_name
) AS pivoted_data
UNION ALL
SELECT 
    product_name,
    'Feb' AS month_name,
    Feb AS monthly_sales
FROM (
    SELECT 
        p.product_name,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 1 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Jan,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 2 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Feb,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 3 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Mar,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 4 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Apr
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
    GROUP BY p.product_name
) AS pivoted_data
UNION ALL
SELECT 
    product_name,
    'Mar' AS month_name,
    Mar AS monthly_sales
FROM (
    SELECT 
        p.product_name,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 1 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Jan,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 2 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Feb,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 3 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Mar,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 4 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Apr
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
    GROUP BY p.product_name
) AS pivoted_data
UNION ALL
SELECT 
    product_name,
    'Apr' AS month_name,
    Apr AS monthly_sales
FROM (
    SELECT 
        p.product_name,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 1 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Jan,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 2 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Feb,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 3 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Mar,
        SUM(CASE WHEN EXTRACT(MONTH FROM s.sale_date) = 4 THEN s.quantity * s.unit_price * (1 - s.discount) ELSE 0 END) AS Apr
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
    GROUP BY p.product_name
) AS pivoted_data
ORDER BY product_name, 
CASE month_name
    WHEN 'Jan' THEN 1
    WHEN 'Feb' THEN 2
    WHEN 'Mar' THEN 3
    WHEN 'Apr' THEN 4
END;

-- ==========================================
-- 8. LATERAL JOINS
-- ==========================================

-- LATERAL joins allow subqueries in the FROM clause to reference columns from preceding FROM items
-- They are similar to correlated subqueries but can return multiple columns and rows

-- Example: For each region, find the top 3 sales by amount
SELECT 
    r.region_id,
    r.region_name,
    top_sales.sale_id,
    top_sales.sale_date,
    top_sales.sale_amount,
    top_sales.rank
FROM regions r
CROSS JOIN LATERAL (
    SELECT 
        s.sale_id,
        s.sale_date,
        s.quantity * s.unit_price * (1 - s.discount) AS sale_amount,
        RANK() OVER (ORDER BY s.quantity * s.unit_price * (1 - s.discount) DESC) AS rank
    FROM sales s
    WHERE s.region_id = r.region_id
    ORDER BY sale_amount DESC
    LIMIT 3
) AS top_sales
ORDER BY r.region_id, top_sales.rank;

-- Example: For each product, calculate monthly sales statistics
SELECT 
    p.product_id,
    p.product_name,
    monthly_stats.month,
    monthly_stats.total_sales,
    monthly_stats.avg_sale_amount,
    monthly_stats.min_sale_amount,
    monthly_stats.max_sale_amount
FROM products p
CROSS JOIN LATERAL (
    SELECT 
        EXTRACT(MONTH FROM s.sale_date) AS month,
        SUM(s.quantity * s.unit_price * (1 - s.discount)) AS total_sales,
        AVG(s.quantity * s.unit_price * (1 - s.discount)) AS avg_sale_amount,
        MIN(s.quantity * s.unit_price * (1 - s.discount)) AS min_sale_amount,
        MAX(s.quantity * s.unit_price * (1 - s.discount)) AS max_sale_amount
    FROM sales s
    WHERE 
        s.product_id = p.product_id
        AND EXTRACT(YEAR FROM s.sale_date) = 2024
    GROUP BY EXTRACT(MONTH FROM s.sale_date)
    HAVING SUM(s.quantity * s.unit_price * (1 - s.discount)) > 0
) AS monthly_stats
WHERE p.product_id <= 5
ORDER BY p.product_id, monthly_stats.month;

-- ==========================================
-- 9. GROUPING SETS, ROLLUP, AND CUBE
-- ==========================================

-- GROUPING SETS: Multiple grouping clauses in a single query
SELECT 
    COALESCE(r.region_name, 'All Regions') AS region,
    COALESCE(p.category, 'All Categories') AS category,
    SUM(s.quantity * s.unit_price * (1 - s.discount)) AS total_sales,
    COUNT(DISTINCT s.sale_id) AS num_sales
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN regions r ON s.region_id = r.region_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
GROUP BY GROUPING SETS (
    (r.region_name, p.category),
    (r.region_name),
    (p.category),
    ()
)
ORDER BY 
    CASE WHEN r.region_name IS NULL THEN 1 ELSE 0 END,
    r.region_name,
    CASE WHEN p.category IS NULL THEN 1 ELSE 0 END,
    p.category;

-- ROLLUP: Hierarchical grouping
SELECT 
    COALESCE(r.region_name, 'All Regions') AS region,
    COALESCE(p.category, 'All Categories') AS category,
    COALESCE(TO_CHAR(s.sale_date, 'YYYY-MM'), 'All Months') AS month,
    SUM(s.quantity * s.unit_price * (1 - s.discount)) AS total_sales,
    COUNT(DISTINCT s.sale_id) AS num_sales
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN regions r ON s.region_id = r.region_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
GROUP BY ROLLUP (r.region_name, p.category, TO_CHAR(s.sale_date, 'YYYY-MM'))
ORDER BY 
    CASE WHEN r.region_name IS NULL THEN 1 ELSE 0 END,
    r.region_name,
    CASE WHEN p.category IS NULL THEN 1 ELSE 0 END,
    p.category,
    CASE WHEN TO_CHAR(s.sale_date, 'YYYY-MM') IS NULL THEN 1 ELSE 0 END,
    TO_CHAR(s.sale_date, 'YYYY-MM');

-- CUBE: All possible grouping combinations
SELECT 
    COALESCE(r.region_name, 'All Regions') AS region,
    COALESCE(p.category, 'All Categories') AS category,
    SUM(s.quantity * s.unit_price * (1 - s.discount)) AS total_sales,
    COUNT(DISTINCT s.sale_id) AS num_sales
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN regions r ON s.region_id = r.region_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
GROUP BY CUBE (r.region_name, p.category)
ORDER BY 
    CASE WHEN r.region_name IS NULL THEN 1 ELSE 0 END,
    r.region_name,
    CASE WHEN p.category IS NULL THEN 1 ELSE 0 END,
    p.category;

-- ==========================================
-- 10. COMMON TABLE EXPRESSIONS (CTEs) WITH RECURSION
-- ==========================================

-- Non-recursive CTE: Calculate sales summary
WITH sales_summary AS (
    SELECT 
        s.product_id,
        p.product_name,
        p.category,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * s.unit_price * (1 - s.discount)) AS total_revenue,
        COUNT(DISTINCT s.sale_id) AS num_transactions
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
    GROUP BY s.product_id, p.product_name, p.category
),
product_rankings AS (
    SELECT 
        product_id,
        product_name,
        category,
        total_quantity,
        total_revenue,
        num_transactions,
        RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS category_rank,
        RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank
    FROM sales_summary
)
SELECT 
    product_id,
    product_name,
    category,
    total_quantity,
    total_revenue,
    num_transactions,
    category_rank,
    overall_rank
FROM product_rankings
WHERE category_rank <= 2
ORDER BY category, category_rank;

-- Recursive CTE: Employee hierarchy with total team revenue
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Top-level employees (managers with no manager)
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.manager_id,
        0 AS level
    FROM employees e
    WHERE e.manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Employees who report to managers in the CTE
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.manager_id,
        eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
),
employee_sales AS (
    SELECT 
        s.employee_id,
        SUM(s.quantity * s.unit_price * (1 - s.discount)) AS total_revenue
    FROM sales s
    WHERE EXTRACT(YEAR FROM s.sale_date) = 2024
    GROUP BY s.employee_id
)
SELECT 
    eh.employee_id,
    eh.employee_name,
    eh.level,
    COALESCE(es.total_revenue, 0) AS personal_revenue,
    (
        SELECT COALESCE(SUM(es_sub.total_revenue), 0)
        FROM employee_hierarchy eh_sub
        LEFT JOIN employee_sales es_sub ON eh_sub.employee_id = es_sub.employee_id
        WHERE 
            eh_sub.employee_id = eh.employee_id
            OR (
                WITH RECURSIVE subordinates AS (
                    SELECT employee_id FROM employees WHERE manager_id = eh.employee_id
                    UNION ALL
                    SELECT e.employee_id FROM employees e JOIN subordinates s ON e.manager_id = s.employee_id
                )
                SELECT COUNT(*) > 0 FROM subordinates WHERE subordinates.employee_id = eh_sub.employee_id
            )
    ) AS team_revenue
FROM employee_hierarchy eh
LEFT JOIN employee_sales es ON eh.employee_id = es.employee_id
ORDER BY eh.level, team_revenue DESC;

-- ==========================================
-- 11. JSON FUNCTIONS
-- ==========================================

-- Create a table with JSON data
CREATE TABLE IF NOT EXISTS customer_preferences (
    customer_id INT PRIMARY KEY,
    preferences JSONB,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customer_preferences (customer_id, preferences)
VALUES
    (1, '{"theme": "dark", "notifications": {"email": true, "sms": false}, "favorite_categories": ["Electronics", "Books"]}'),
    (2, '{"theme": "light", "notifications": {"email": true, "sms": true}, "favorite_categories": ["Clothing", "Sports"]}'),
    (3, '{"theme": "light", "notifications": {"email": false, "sms": false}, "favorite_categories": ["Home", "Garden"]}'),
    (4, '{"theme": "dark", "notifications": {"email": true, "sms": true}, "favorite_categories": ["Electronics", "Music"]}'),
    (5, '{"theme": "system", "notifications": {"email": true, "sms": false}, "favorite_categories": ["Books", "Movies"]}');

-- Extract scalar values
SELECT 
    customer_id,
    preferences->>'theme' AS theme
FROM customer_preferences;

-- Extract nested values
SELECT 
    customer_id,
    preferences->'notifications'->>'email' AS email_notifications,
    preferences->'notifications'->>'sms' AS sms_notifications
FROM customer_preferences;

-- Filter based on JSON properties
SELECT 
    customer_id,
    preferences
FROM customer_preferences
WHERE 
    preferences->>'theme' = 'dark'
    AND (preferences->'notifications'->>'email')::BOOLEAN = TRUE;

-- Work with JSON arrays
SELECT 
    customer_id,
    jsonb_array_elements_text(preferences->'favorite_categories') AS category
FROM customer_preferences;

-- Aggregate JSON objects
SELECT 
    preferences->>'theme' AS theme,
    COUNT(*) AS num_customers,
    jsonb_agg(customer_id) AS customer_ids
FROM customer_preferences
GROUP BY preferences->>'theme';

-- ==========================================
-- 12. CLEANUP (UNCOMMENT TO RUN)
-- ==========================================

-- DROP TABLE IF EXISTS customer_preferences;
-- DROP TABLE IF EXISTS sales;
-- DROP TABLE IF EXISTS products;
-- DROP TABLE IF EXISTS regions;
-- DROP TABLE IF EXISTS employees;
