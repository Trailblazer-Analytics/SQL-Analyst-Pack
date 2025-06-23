/*
    Script: 01_intro_to_window_functions.sql
    Module: 05_window_functions
    Description: Comprehensive introduction to window functions for business analytics
    Author: SQL Analyst Pack
    Version: 2.0
    Last-Modified: 2025-06-22
    
    Business Focus: Understanding window functions for advanced reporting and analytics
    Prerequisites: Basic SQL, Aggregation functions, JOINs
    Sample Database: Chinook (Music Store)
*/

-- =================================================================================================================================
-- WINDOW FUNCTIONS: FOUNDATION FOR ADVANCED ANALYTICS
-- =================================================================================================================================
--
-- Window functions are SQL's most powerful feature for analytical processing. They allow you to:
-- • Perform calculations across related rows while preserving individual row details
-- • Create running totals, moving averages, and rankings
-- • Compare values between different rows in the same result set
-- • Build sophisticated business intelligence reports
--
-- KEY BUSINESS APPLICATIONS:
-- • Sales performance dashboards
-- • Financial reporting and cumulative metrics
-- • Customer behavior analysis
-- • Trend identification and forecasting
-- • Comparative analysis and benchmarking
--
-- CORE SYNTAX: SELECT column, WINDOW_FUNCTION() OVER(window_specification)
-- WHERE window_specification includes:
-- • PARTITION BY: Creates separate calculation groups
-- • ORDER BY: Defines sequence for cumulative operations
-- • FRAME CLAUSE: Specifies which rows to include in calculations
--
-- =================================================================================================================================
-- SECTION 1: WINDOW FUNCTIONS vs AGGREGATE FUNCTIONS
-- =================================================================================================================================
--
-- Understanding the fundamental difference between aggregate and window functions is crucial:
-- • AGGREGATE functions: Collapse multiple rows into a single result
-- • WINDOW functions: Return a value for each row while using data from multiple rows

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Scenario: Sales Performance Analysis
-- Problem: Compare individual invoice amounts with overall sales metrics
-- ---------------------------------------------------------------------------------------------------------------------------------

-- BEFORE: Traditional aggregate approach (loses row-level detail)
SELECT
    COUNT(*) AS total_invoices,
    AVG(Total) AS average_invoice,
    MAX(Total) AS highest_invoice,
    MIN(Total) AS lowest_invoice
FROM invoices;

-- AFTER: Window function approach (preserves row-level detail)
SELECT
    InvoiceId,
    CustomerId,
    InvoiceDate,
    Total AS invoice_amount,
    -- Overall metrics available for each row
    COUNT(*) OVER() AS total_invoices,
    AVG(Total) OVER() AS average_invoice,
    MAX(Total) OVER() AS highest_invoice,
    MIN(Total) OVER() AS lowest_invoice,
    -- Business insights
    Total - AVG(Total) OVER() AS variance_from_average,
    CASE 
        WHEN Total > AVG(Total) OVER() THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_category
FROM invoices
ORDER BY Total DESC
LIMIT 20;

-- =================================================================================================================================
-- SECTION 2: PARTITIONING - CREATING BUSINESS SEGMENTS
-- =================================================================================================================================
--
-- PARTITION BY creates separate calculation windows for different business segments
-- Think of it as "GROUP BY for window functions" but without collapsing rows

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Scenario: Regional Sales Analysis
-- Problem: Compare performance within geographic regions
-- ---------------------------------------------------------------------------------------------------------------------------------

SELECT
    InvoiceId,
    BillingCountry,
    BillingState,
    InvoiceDate,
    Total AS invoice_amount,
    
    -- Country-level analytics
    COUNT(*) OVER(PARTITION BY BillingCountry) AS country_total_invoices,
    AVG(Total) OVER(PARTITION BY BillingCountry) AS country_avg_invoice,
    SUM(Total) OVER(PARTITION BY BillingCountry) AS country_total_sales,
    
    -- State-level analytics (where applicable)
    COUNT(*) OVER(PARTITION BY BillingCountry, BillingState) AS state_total_invoices,
    AVG(Total) OVER(PARTITION BY BillingCountry, BillingState) AS state_avg_invoice,
    
    -- Performance indicators
    CASE 
        WHEN Total > AVG(Total) OVER(PARTITION BY BillingCountry) 
        THEN 'Above Country Average'
        ELSE 'Below Country Average'
    END AS country_performance
    
FROM invoices
WHERE BillingCountry IN ('USA', 'Canada', 'Brazil', 'Germany', 'United Kingdom')
ORDER BY BillingCountry, Total DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Scenario: Customer Segmentation Analysis
-- Problem: Analyze customer behavior patterns and spending levels
-- ---------------------------------------------------------------------------------------------------------------------------------

SELECT
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS customer_name,
    c.Country,
    i.InvoiceId,
    i.InvoiceDate,
    i.Total AS invoice_amount,
    
    -- Customer-specific metrics
    COUNT(*) OVER(PARTITION BY c.CustomerId) AS customer_total_orders,
    AVG(i.Total) OVER(PARTITION BY c.CustomerId) AS customer_avg_order,
    SUM(i.Total) OVER(PARTITION BY c.CustomerId) AS customer_lifetime_value,
    
    -- Country-level benchmarking
    AVG(i.Total) OVER(PARTITION BY c.Country) AS country_avg_order,
    
    -- Customer classification
    CASE 
        WHEN SUM(i.Total) OVER(PARTITION BY c.CustomerId) > 40 THEN 'High Value'
        WHEN SUM(i.Total) OVER(PARTITION BY c.CustomerId) > 20 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
    
FROM customers c
JOIN invoices i ON c.CustomerId = i.CustomerId
ORDER BY customer_lifetime_value DESC, c.CustomerId, i.InvoiceDate;

-- =================================================================================================================================
-- SECTION 3: ORDERING AND CUMULATIVE CALCULATIONS
-- =================================================================================================================================
--
-- ORDER BY in window functions enables sequential processing for time-series analysis

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Scenario: Financial Performance Tracking
-- Problem: Track cumulative revenue and growth trends over time
-- ---------------------------------------------------------------------------------------------------------------------------------

WITH daily_sales AS (
    SELECT
        DATE(InvoiceDate) AS sale_date,
        SUM(Total) AS daily_revenue,
        COUNT(*) AS daily_transactions
    FROM invoices
    GROUP BY DATE(InvoiceDate)
)
SELECT
    sale_date,
    daily_revenue,
    daily_transactions,
    
    -- Cumulative metrics
    SUM(daily_revenue) OVER(ORDER BY sale_date) AS cumulative_revenue,
    AVG(daily_revenue) OVER(ORDER BY sale_date) AS running_avg_daily_sales,
    
    -- Growth tracking
    LAG(daily_revenue) OVER(ORDER BY sale_date) AS previous_day_revenue,
    daily_revenue - LAG(daily_revenue) OVER(ORDER BY sale_date) AS daily_change,
    
    -- Performance indicators
    CASE 
        WHEN daily_revenue > AVG(daily_revenue) OVER(ORDER BY sale_date) 
        THEN 'Above Running Average'
        ELSE 'Below Running Average'
    END AS performance_trend
    
FROM daily_sales
ORDER BY sale_date;

-- =================================================================================================================================
-- SECTION 4: COMBINING PARTITIONING AND ORDERING
-- =================================================================================================================================
--
-- The most powerful window function pattern: segment data AND track sequential patterns

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Scenario: Customer Purchase Journey Analysis
-- Problem: Track individual customer purchasing patterns over time
-- ---------------------------------------------------------------------------------------------------------------------------------

SELECT
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS customer_name,
    i.InvoiceId,
    i.InvoiceDate,
    i.Total AS invoice_amount,
    
    -- Customer journey metrics
    ROW_NUMBER() OVER(PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) AS purchase_sequence,
    SUM(i.Total) OVER(PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) AS cumulative_spending,
    AVG(i.Total) OVER(PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) AS running_avg_order,
    
    -- Time-based analysis
    FIRST_VALUE(i.Total) OVER(PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) AS first_purchase_amount,
    LAG(i.InvoiceDate) OVER(PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) AS previous_purchase_date,
    
    -- Business insights
    CASE 
        WHEN ROW_NUMBER() OVER(PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) = 1 THEN 'First Purchase'
        WHEN i.Total > AVG(i.Total) OVER(PARTITION BY c.CustomerId ORDER BY i.InvoiceDate) THEN 'Above Personal Average'
        ELSE 'Regular Purchase'
    END AS purchase_type
    
FROM customers c
JOIN invoices i ON c.CustomerId = i.CustomerId
WHERE c.CustomerId <= 10  -- Limit for readability
ORDER BY c.CustomerId, i.InvoiceDate;

-- =================================================================================================================================
-- SECTION 5: PRACTICAL BUSINESS EXERCISES
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Exercise 1: Genre Performance Analysis
-- Problem: Analyze music genre sales performance and market share
-- ---------------------------------------------------------------------------------------------------------------------------------

SELECT
    g.Name AS genre_name,
    t.Name AS track_name,
    t.UnitPrice,
    il.Quantity,
    il.UnitPrice * il.Quantity AS revenue,
    
    -- Genre-level analytics
    SUM(il.UnitPrice * il.Quantity) OVER(PARTITION BY g.GenreId) AS genre_total_revenue,
    AVG(il.UnitPrice * il.Quantity) OVER(PARTITION BY g.GenreId) AS genre_avg_sale,
    COUNT(*) OVER(PARTITION BY g.GenreId) AS genre_total_sales,
    
    -- Market share analysis
    SUM(il.UnitPrice * il.Quantity) OVER() AS total_market_revenue,
    ROUND(
        SUM(il.UnitPrice * il.Quantity) OVER(PARTITION BY g.GenreId) * 100.0 / 
        SUM(il.UnitPrice * il.Quantity) OVER(),
        2
    ) AS genre_market_share_percent
    
FROM genres g
JOIN tracks t ON g.GenreId = t.GenreId
JOIN invoice_lines il ON t.TrackId = il.TrackId
ORDER BY genre_total_revenue DESC, revenue DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Exercise 2: Employee Sales Performance Dashboard
-- Problem: Create comprehensive sales rep performance metrics
-- ---------------------------------------------------------------------------------------------------------------------------------

WITH employee_sales AS (
    SELECT
        e.EmployeeId,
        e.FirstName || ' ' || e.LastName AS employee_name,
        e.Title,
        COUNT(DISTINCT c.CustomerId) AS customers_managed,
        COUNT(DISTINCT i.InvoiceId) AS total_sales,
        SUM(i.Total) AS total_revenue,
        AVG(i.Total) AS avg_order_value
    FROM employees e
    LEFT JOIN customers c ON e.EmployeeId = c.SupportRepId
    LEFT JOIN invoices i ON c.CustomerId = i.CustomerId
    GROUP BY e.EmployeeId, e.FirstName, e.LastName, e.Title
)
SELECT
    employee_name,
    title,
    customers_managed,
    total_sales,
    total_revenue,
    avg_order_value,
    
    -- Performance rankings
    RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank,
    RANK() OVER(ORDER BY customers_managed DESC) AS customer_count_rank,
    RANK() OVER(ORDER BY avg_order_value DESC) AS avg_order_rank,
    
    -- Performance metrics
    total_revenue / NULLIF(customers_managed, 0) AS revenue_per_customer,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER(), 2) AS revenue_share_percent,
    
    -- Performance categories
    CASE 
        WHEN RANK() OVER(ORDER BY total_revenue DESC) <= 2 THEN 'Top Performer'
        WHEN RANK() OVER(ORDER BY total_revenue DESC) <= 4 THEN 'Strong Performer'
        ELSE 'Developing'
    END AS performance_tier
    
FROM employee_sales
WHERE total_revenue > 0
ORDER BY total_revenue DESC;

-- =================================================================================================================================
-- SECTION 6: ADVANCED CONCEPTS AND BEST PRACTICES
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Frame Specifications: Controlling Window Boundaries
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Different frame types for moving calculations
SELECT
    DATE(InvoiceDate) AS sale_date,
    SUM(Total) AS daily_sales,
    
    -- Different moving average calculations
    AVG(SUM(Total)) OVER(
        ORDER BY DATE(InvoiceDate) 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7_days,
    
    AVG(SUM(Total)) OVER(
        ORDER BY DATE(InvoiceDate) 
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS centered_moving_avg_5_days,
    
    SUM(SUM(Total)) OVER(
        ORDER BY DATE(InvoiceDate) 
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_sales_to_date
    
FROM invoices
GROUP BY DATE(InvoiceDate)
ORDER BY sale_date;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Performance Considerations
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Best practices for window function performance:
-- 1. Use appropriate indexes on PARTITION BY and ORDER BY columns
-- 2. Limit window frame size when possible
-- 3. Consider materializing complex calculations in CTEs
-- 4. Test performance with realistic data volumes

-- Example: Optimized customer analysis with indexes
-- CREATE INDEX idx_invoices_customer_date ON invoices(CustomerId, InvoiceDate);
-- CREATE INDEX idx_customers_country ON customers(Country);

-- =================================================================================================================================
-- KEY TAKEAWAYS AND NEXT STEPS
-- =================================================================================================================================
--
-- WINDOW FUNCTIONS ENABLE:
-- • Row-level analysis with aggregate insights
-- • Segmented analysis using PARTITION BY
-- • Sequential analysis using ORDER BY
-- • Advanced analytical patterns for business intelligence
--
-- BUSINESS APPLICATIONS:
-- • Performance dashboards and KPI tracking
-- • Trend analysis and forecasting
-- • Customer segmentation and lifetime value
-- • Sales territory and rep performance
-- • Financial reporting and cumulative metrics
--
-- NEXT STEPS:
-- 1. Practice with ranking functions (ROW_NUMBER, RANK, DENSE_RANK)
-- 2. Master LAG/LEAD for period-over-period analysis
-- 3. Explore advanced frame specifications
-- 4. Build comprehensive business dashboards
--
-- PERFORMANCE TIPS:
-- • Use appropriate indexes on partition and order columns
-- • Limit window frame sizes when possible
-- • Consider query execution plans for optimization
-- • Test with realistic data volumes
--
-- =================================================================================================================================
