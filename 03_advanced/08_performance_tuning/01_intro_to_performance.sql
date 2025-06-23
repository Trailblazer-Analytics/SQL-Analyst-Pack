/*
    Script: 01_intro_to_performance.sql
    Module: 08_performance_tuning
    Description: Comprehensive introduction to SQL performance optimization and analysis
    Author: SQL Analyst Pack
    Version: 2.0
    Last-Modified: 2025-06-22
    
    Business Focus: Master performance fundamentals for production SQL systems
    Prerequisites: Advanced SQL, Complex queries, Database architecture understanding
    Sample Database: Chinook (Music Store)
*/

-- =================================================================================================================================
-- SQL PERFORMANCE OPTIMIZATION: FOUNDATION FOR ENTERPRISE SYSTEMS
-- =================================================================================================================================
--
-- Performance optimization is critical for business-critical applications. Poor performance costs:
-- • Lost revenue from slow customer-facing applications
-- • Reduced productivity from slow internal tools
-- • Increased infrastructure costs from resource waste
-- • Poor user experience leading to customer churn
-- • Failed SLA compliance and regulatory issues
--
-- KEY PERFORMANCE CONCEPTS:
-- • Execution plans: How the database executes queries
-- • Indexes: Data structures that speed up data retrieval
-- • Query optimization: Rewriting queries for better performance
-- • Resource utilization: CPU, memory, I/O, and network efficiency
-- • Scalability: Performance under increasing load
--
-- BUSINESS IMPACT METRICS:
-- • Query response time (user experience)
-- • Throughput (transactions per second)
-- • Resource utilization (cost optimization)
-- • Availability (system uptime)
-- • Scalability (growth capacity)
--
-- =================================================================================================================================
-- SECTION 1: PERFORMANCE MEASUREMENT AND BASELINES
-- =================================================================================================================================
--
-- Before optimizing, establish baseline metrics to measure improvement

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Scenario: Customer Lookup Performance Analysis
-- Problem: Customer service representatives wait too long for customer lookups
-- Solution: Analyze and optimize customer search queries
-- ---------------------------------------------------------------------------------------------------------------------------------

-- First, let's establish timing measurement for our optimizations
-- Note: Timing methods vary by database system

-- Clear any cached query plans and data (database-specific)
-- PRAGMA cache_flush; -- SQLite
-- DBCC DROPCLEANBUFFERS; -- SQL Server
-- RESET QUERY CACHE; -- MySQL

-- Baseline query: Find customer by email (common customer service scenario)
.timer ON  -- SQLite timing
EXPLAIN QUERY PLAN
SELECT 
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS customer_name,
    c.Email,
    c.Phone,
    c.City,
    c.Country,
    COUNT(i.InvoiceId) AS total_orders,
    SUM(i.Total) AS total_spent,
    MAX(i.InvoiceDate) AS last_order_date
FROM customers c
LEFT JOIN invoices i ON c.CustomerId = i.CustomerId
WHERE c.Email = 'luisg@embraer.com.br'
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Email, c.Phone, c.City, c.Country;

-- Business Impact: This query represents a critical customer service function
-- Current performance: [Time this query and note the execution plan]

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Scenario: Sales Report Performance
-- Problem: Monthly sales reports take too long to generate
-- Solution: Analyze complex aggregation query performance
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Complex aggregation query baseline
EXPLAIN QUERY PLAN
SELECT 
    DATE(i.InvoiceDate, 'start of month') AS month,
    COUNT(DISTINCT i.CustomerId) AS unique_customers,
    COUNT(i.InvoiceId) AS total_orders,
    SUM(i.Total) AS total_revenue,
    AVG(i.Total) AS avg_order_value,
    
    -- Business metrics
    SUM(i.Total) / COUNT(DISTINCT i.CustomerId) AS revenue_per_customer,
    COUNT(i.InvoiceId) / COUNT(DISTINCT i.CustomerId) AS orders_per_customer,
    
    -- Geographic analysis
    COUNT(DISTINCT i.BillingCountry) AS countries_served
FROM invoices i
WHERE i.InvoiceDate >= '2009-01-01' 
  AND i.InvoiceDate < '2010-01-01'
GROUP BY DATE(i.InvoiceDate, 'start of month')
ORDER BY month;

-- Business Impact: Executive monthly reporting and financial analysis
-- Current performance: [Time this query and analyze execution plan]

-- =================================================================================================================================
-- SECTION 2: INDEX FUNDAMENTALS AND BUSINESS APPLICATIONS
-- =================================================================================================================================
--
-- Indexes are the primary tool for query optimization in business applications

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Understanding Index Types and Business Use Cases
-- ---------------------------------------------------------------------------------------------------------------------------------

-- 1. PRIMARY KEY indexes (automatically created)
-- Business use: Unique record identification, foreign key relationships

-- 2. UNIQUE indexes 
-- Business use: Data integrity, preventing duplicates
CREATE UNIQUE INDEX IF NOT EXISTS idx_customer_email ON customers(Email);

-- 3. COMPOSITE indexes
-- Business use: Multi-criteria searches, reporting queries
CREATE INDEX IF NOT EXISTS idx_invoice_customer_date ON invoices(CustomerId, InvoiceDate);

-- 4. COVERING indexes (include all needed columns)
-- Business use: Eliminating table lookups for read-heavy workloads
CREATE INDEX IF NOT EXISTS idx_invoice_summary 
ON invoices(CustomerId, InvoiceDate, Total, BillingCountry);

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Measuring Index Impact on Business Queries
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Test customer lookup performance after email index
EXPLAIN QUERY PLAN
SELECT 
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS customer_name,
    c.Email,
    c.City,
    c.Country
FROM customers c
WHERE c.Email = 'luisg@embraer.com.br';

-- Expected improvement: Index seek instead of table scan
-- Business benefit: Faster customer service, better user experience

-- Test composite index impact on customer order history
EXPLAIN QUERY PLAN
SELECT 
    i.InvoiceId,
    i.InvoiceDate,
    i.Total,
    i.BillingCountry
FROM invoices i
WHERE i.CustomerId = 1
ORDER BY i.InvoiceDate DESC;

-- Expected improvement: Index-based filtering and sorting
-- Business benefit: Faster customer account views

-- =================================================================================================================================
-- SECTION 3: QUERY OPTIMIZATION PATTERNS
-- =================================================================================================================================
--
-- Common patterns for optimizing business queries

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Pattern 1: Filtering Early (Predicate Pushdown)
-- Business Context: Reduce data processing in complex reports
-- ---------------------------------------------------------------------------------------------------------------------------------

-- BEFORE: Inefficient - processes all data then filters
SELECT customer_data.*, order_summary.*
FROM (
    SELECT CustomerId, FirstName, LastName, Country 
    FROM customers
) customer_data
JOIN (
    SELECT CustomerId, COUNT(*) as order_count, SUM(Total) as total_spent
    FROM invoices 
    GROUP BY CustomerId
) order_summary ON customer_data.CustomerId = order_summary.CustomerId
WHERE customer_data.Country = 'USA';

-- AFTER: Efficient - filters early to reduce processing
SELECT 
    c.CustomerId,
    c.FirstName,
    c.LastName,
    c.Country,
    COUNT(i.InvoiceId) as order_count,
    SUM(i.Total) as total_spent
FROM customers c
LEFT JOIN invoices i ON c.CustomerId = i.CustomerId
WHERE c.Country = 'USA'  -- Filter applied early
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Pattern 2: Avoiding N+1 Query Problems
-- Business Context: Dashboard performance with related data
-- ---------------------------------------------------------------------------------------------------------------------------------

-- PROBLEM: N+1 queries (common in application code)
-- This pattern would execute one query per customer:
-- SELECT * FROM customers WHERE Country = 'USA';
-- For each customer: SELECT COUNT(*) FROM invoices WHERE CustomerId = ?;

-- SOLUTION: Single optimized query
SELECT 
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS customer_name,
    c.Country,
    COALESCE(customer_stats.order_count, 0) AS order_count,
    COALESCE(customer_stats.total_spent, 0) AS total_spent,
    COALESCE(customer_stats.avg_order, 0) AS avg_order_value
FROM customers c
LEFT JOIN (
    SELECT 
        CustomerId,
        COUNT(*) AS order_count,
        SUM(Total) AS total_spent,
        AVG(Total) AS avg_order
    FROM invoices
    GROUP BY CustomerId
) customer_stats ON c.CustomerId = customer_stats.CustomerId
WHERE c.Country = 'USA';

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Pattern 3: Efficient Pagination for Large Result Sets
-- Business Context: Application search results and reports
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Create index for efficient pagination
CREATE INDEX IF NOT EXISTS idx_customer_name_id ON customers(LastName, FirstName, CustomerId);

-- Efficient pagination query (avoids OFFSET for large datasets)
SELECT 
    CustomerId,
    FirstName,
    LastName,
    Email,
    Country
FROM customers
WHERE (LastName > 'Garcia') 
   OR (LastName = 'Garcia' AND FirstName > 'Eduardo')
   OR (LastName = 'Garcia' AND FirstName = 'Eduardo' AND CustomerId > 15)
ORDER BY LastName, FirstName, CustomerId
LIMIT 10;

-- Business benefit: Consistent pagination performance regardless of page number

-- =================================================================================================================================
-- SECTION 4: PERFORMANCE MONITORING AND ALERTING
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Business Performance Monitoring Query
-- Create a simple performance monitoring framework
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Monitor query patterns and performance (conceptual - adapt to your database)
WITH performance_metrics AS (
    SELECT 
        'Customer Lookup' AS query_type,
        'Critical' AS business_priority,
        COUNT(*) AS execution_count,
        -- Note: actual timing columns vary by database
        'Email index lookup' AS optimization_notes
    FROM customers 
    WHERE Email LIKE '%@%'  -- Simulate monitoring customer lookups
    
    UNION ALL
    
    SELECT 
        'Sales Report' AS query_type,
        'High' AS business_priority,
        COUNT(*) AS data_volume,
        'Monthly aggregation' AS optimization_notes
    FROM invoices
    WHERE InvoiceDate >= DATE('now', '-30 days')
)
SELECT 
    query_type,
    business_priority,
    execution_count AS metric_value,
    optimization_notes,
    CASE 
        WHEN business_priority = 'Critical' AND execution_count > 1000 THEN 'Monitor Closely'
        WHEN business_priority = 'High' AND execution_count > 5000 THEN 'Review Performance'
        ELSE 'Normal'
    END AS alert_status
FROM performance_metrics;

-- =================================================================================================================================
-- SECTION 5: BUSINESS-FOCUSED OPTIMIZATION EXERCISES
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Exercise 1: Customer Service Dashboard Optimization
-- Business Requirement: Sub-second customer lookups for call center
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Current slow query (to be optimized):
SELECT 
    c.*,
    COUNT(i.InvoiceId) AS order_count,
    SUM(i.Total) AS lifetime_value,
    MAX(i.InvoiceDate) AS last_order,
    AVG(i.Total) AS avg_order_value
FROM customers c
LEFT JOIN invoices i ON c.CustomerId = i.CustomerId
WHERE c.Email LIKE '%gmail%'  -- Simulate partial email search
GROUP BY c.CustomerId;

-- Optimization challenge: Make this query run in <100ms
-- Considerations: Indexing strategy, query rewriting, caching

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Exercise 2: Executive Report Optimization
-- Business Requirement: Monthly executive summary in <5 seconds
-- ---------------------------------------------------------------------------------------------------------------------------------

-- Complex executive dashboard query:
SELECT 
    strftime('%Y-%m', i.InvoiceDate) AS month,
    COUNT(DISTINCT i.CustomerId) AS active_customers,
    SUM(i.Total) AS revenue,
    COUNT(i.InvoiceId) AS transactions,
    COUNT(DISTINCT i.BillingCountry) AS countries,
    AVG(customer_metrics.customer_lifetime_value) AS avg_clv
FROM invoices i
JOIN (
    SELECT 
        CustomerId,
        SUM(Total) AS customer_lifetime_value
    FROM invoices
    GROUP BY CustomerId
) customer_metrics ON i.CustomerId = customer_metrics.CustomerId
WHERE i.InvoiceDate >= '2008-01-01'
GROUP BY strftime('%Y-%m', i.InvoiceDate)
ORDER BY month;

-- Optimization challenge: Reduce execution time by 80%
-- Consider: Materialized views, pre-aggregation, index optimization

-- =================================================================================================================================
-- KEY PERFORMANCE OPTIMIZATION PRINCIPLES
-- =================================================================================================================================
--
-- BUSINESS-CRITICAL OPTIMIZATION STRATEGIES:
-- • Index design for common query patterns
-- • Query rewriting for efficiency
-- • Early filtering to reduce data processing
-- • Avoiding N+1 query patterns
-- • Efficient pagination for large datasets
-- • Performance monitoring and alerting
--
-- MEASUREMENT AND VALIDATION:
-- • Always measure before and after optimization
-- • Test with realistic data volumes
-- • Consider business peak usage patterns
-- • Monitor resource utilization (CPU, memory, I/O)
-- • Validate business requirements are met
--
-- SCALABILITY CONSIDERATIONS:
-- • Design for growth in data volume
-- • Consider concurrent user scenarios
-- • Plan for business seasonality
-- • Account for data archival strategies
-- • Monitor performance regression over time
--
-- NEXT STEPS:
-- 1. Practice with execution plan analysis
-- 2. Master indexing strategies for different scenarios
-- 3. Learn query rewriting techniques
-- 4. Implement performance monitoring frameworks
--
-- =================================================================================================================================

CREATE INDEX idx_customer_email ON Customer(Email);


-- -----------------------------------------------------------------------------
-- Step 3: Analyze the query plan WITH the index.
-- -----------------------------------------------------------------------------
-- After creating the index, the database can use it to quickly find the location
-- of the desired row(s) without scanning the whole table.

-- In PostgreSQL, MySQL, SQLite:
EXPLAIN SELECT * FROM Customer WHERE Email = 'luisg@embraer.com.br';

-- Expected Result (varies by system, but look for "INDEX SEEK" or "INDEX SCAN"):
-- The plan will now show that it uses `idx_customer_email` to find the data,
-- which is much faster.


-- -----------------------------------------------------------------------------
-- Step 4: Clean up the created index.
-- -----------------------------------------------------------------------------
-- It's good practice to remove indexes created for demonstration purposes.

DROP INDEX idx_customer_email;
