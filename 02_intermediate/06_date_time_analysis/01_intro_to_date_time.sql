/*
    Script: 01_intro_to_date_time.sql
    Module: 06_date_time_analysis
    Description: Comprehensive introduction to date/time analysis for business intelligence
    Author: SQL Analyst Pack
    Version: 2.0
    Last-Modified: 2025-06-22
    
    Business Focus: Master temporal data analysis for business insights and reporting
    Prerequisites: Basic SQL, Basic functions, Understanding of data types
    Sample Database: Chinook (Music Store)
*/

-- =================================================================================================================================
-- DATE/TIME ANALYSIS: FOUNDATION FOR TEMPORAL BUSINESS INTELLIGENCE
-- =================================================================================================================================
--
-- Date and time analysis is fundamental to business intelligence. Most business questions involve:
-- • "How did performance change over time?"
-- • "What are the seasonal patterns?"
-- • "How long does our process take?"
-- • "When should we take action?"
--
-- KEY BUSINESS APPLICATIONS:
-- • Sales trend analysis and forecasting
-- • Customer behavior and lifecycle analytics
-- • Operational efficiency measurement
-- • Financial reporting and compliance
-- • Marketing campaign effectiveness
-- • Supply chain and inventory optimization
--
-- TEMPORAL DATA TYPES:
-- • DATE: Calendar dates (YYYY-MM-DD)
-- • TIME: Time of day (HH:MM:SS)
-- • TIMESTAMP/DATETIME: Combined date and time with timezone info
-- • INTERVAL: Durations and time differences
--
-- =================================================================================================================================
-- SECTION 1: DATE/TIME DATA TYPES AND FORMATS
-- =================================================================================================================================

-- Explore the temporal data in our invoice system
SELECT
    InvoiceId,
    InvoiceDate,
    -- Different ways to examine date/time data
    TYPEOF(InvoiceDate) AS data_type,
    LENGTH(InvoiceDate) AS data_length,
    InvoiceDate AS original_format,
    
    -- Basic date information extraction
    DATE(InvoiceDate) AS date_only,
    TIME(InvoiceDate) AS time_only,
    DATETIME(InvoiceDate) AS datetime_format,
    
    -- Business context
    Total AS sale_amount,
    CustomerId
FROM invoices
ORDER BY InvoiceDate
LIMIT 10;

-- Common date format conversions for business reporting
SELECT
    InvoiceDate,
    Total,
    
    -- Standard business date formats
    STRFTIME('%Y-%m-%d', InvoiceDate) AS iso_date,
    STRFTIME('%m/%d/%Y', InvoiceDate) AS us_format,
    STRFTIME('%d/%m/%Y', InvoiceDate) AS european_format,
    STRFTIME('%B %d, %Y', InvoiceDate) AS readable_format,
    
    -- Business-friendly representations
    STRFTIME('%Y-Q%q', InvoiceDate) AS fiscal_quarter,
    STRFTIME('%Y-%m', InvoiceDate) AS year_month,
    STRFTIME('%A', InvoiceDate) AS day_of_week,
    
    -- Sorting and grouping helpers
    STRFTIME('%Y%m%d', InvoiceDate) AS sortable_date,
    STRFTIME('%w', InvoiceDate) AS weekday_number
    
FROM invoices
WHERE InvoiceDate BETWEEN '2009-01-01' AND '2009-01-31'
ORDER BY InvoiceDate;

-- =================================================================================================================================
-- SECTION 2: EXTRACTING DATE COMPONENTS FOR BUSINESS ANALYSIS
-- =================================================================================================================================

-- Business Scenario: Seasonal Sales Analysis
SELECT
    -- Date component extraction
    STRFTIME('%Y', InvoiceDate) AS year,
    STRFTIME('%m', InvoiceDate) AS month_number,
    STRFTIME('%B', InvoiceDate) AS month_name,
    STRFTIME('%q', InvoiceDate) AS quarter,
    STRFTIME('%w', InvoiceDate) AS day_of_week_num,
    STRFTIME('%A', InvoiceDate) AS day_of_week_name,
    
    -- Business metrics
    COUNT(*) AS transaction_count,
    SUM(Total) AS total_sales,
    AVG(Total) AS average_sale,
    
    -- Business insights
    CASE 
        WHEN STRFTIME('%m', InvoiceDate) IN ('12', '01', '02') THEN 'Winter'
        WHEN STRFTIME('%m', InvoiceDate) IN ('03', '04', '05') THEN 'Spring'
        WHEN STRFTIME('%m', InvoiceDate) IN ('06', '07', '08') THEN 'Summer'
        ELSE 'Fall'
    END AS season,
    
    CASE 
        WHEN STRFTIME('%w', InvoiceDate) IN ('0', '6') THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type
    
FROM invoices
WHERE STRFTIME('%Y', InvoiceDate) = '2009'
GROUP BY 
    STRFTIME('%Y', InvoiceDate),
    STRFTIME('%m', InvoiceDate),
    STRFTIME('%B', InvoiceDate),
    STRFTIME('%q', InvoiceDate),
    STRFTIME('%w', InvoiceDate),
    STRFTIME('%A', InvoiceDate)
ORDER BY year, month_number;

-- =================================================================================================================================
-- SECTION 3: DATE ARITHMETIC AND BUSINESS CALCULATIONS
-- =================================================================================================================================

-- Business Scenario: Customer Lifecycle Analysis
WITH customer_lifecycle AS (
    SELECT
        c.CustomerId,
        c.FirstName || ' ' || c.LastName AS customer_name,
        MIN(i.InvoiceDate) AS first_purchase,
        MAX(i.InvoiceDate) AS last_purchase,
        COUNT(i.InvoiceId) AS total_purchases,
        SUM(i.Total) AS lifetime_value,
        
        -- Date arithmetic for business metrics
        JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)) AS customer_lifespan_days,
        
        -- Calculate average days between purchases
        CASE 
            WHEN COUNT(i.InvoiceId) > 1 THEN 
                (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate))) / (COUNT(i.InvoiceId) - 1)
            ELSE NULL
        END AS avg_days_between_purchases
        
    FROM customers c
    JOIN invoices i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName
)
SELECT
    customer_name,
    first_purchase,
    last_purchase,
    total_purchases,
    lifetime_value,
    
    -- Business-friendly duration formatting
    CASE 
        WHEN customer_lifespan_days = 0 THEN 'Single Day'
        WHEN customer_lifespan_days < 30 THEN ROUND(customer_lifespan_days) || ' days'
        WHEN customer_lifespan_days < 365 THEN ROUND(customer_lifespan_days / 30.0, 1) || ' months'
        ELSE ROUND(customer_lifespan_days / 365.0, 1) || ' years'
    END AS customer_lifespan,
    
    ROUND(avg_days_between_purchases, 1) AS avg_days_between_purchases,
    
    -- Customer segmentation based on behavior
    CASE 
        WHEN total_purchases = 1 THEN 'One-time Customer'
        WHEN avg_days_between_purchases <= 30 THEN 'Frequent Customer'
        WHEN avg_days_between_purchases <= 90 THEN 'Regular Customer'
        WHEN avg_days_between_purchases <= 180 THEN 'Occasional Customer'
        ELSE 'Rare Customer'
    END AS customer_segment
    
FROM customer_lifecycle
WHERE total_purchases >= 2
ORDER BY lifetime_value DESC;

-- =================================================================================================================================
-- SECTION 4: PRACTICAL BUSINESS EXERCISES
-- =================================================================================================================================

-- Exercise 1: Fiscal Year Analysis (fiscal year starts July 1)
WITH fiscal_year_sales AS (
    SELECT
        InvoiceDate,
        Total,
        -- Calculate fiscal year (starts July 1)
        CASE 
            WHEN STRFTIME('%m', InvoiceDate) >= '07' THEN 
                STRFTIME('%Y', InvoiceDate) || '-' || (CAST(STRFTIME('%Y', InvoiceDate) AS INTEGER) + 1)
            ELSE 
                (CAST(STRFTIME('%Y', InvoiceDate) AS INTEGER) - 1) || '-' || STRFTIME('%Y', InvoiceDate)
        END AS fiscal_year,
        
        -- Calculate fiscal quarter
        CASE 
            WHEN STRFTIME('%m', InvoiceDate) IN ('07', '08', '09') THEN 'Q1'
            WHEN STRFTIME('%m', InvoiceDate) IN ('10', '11', '12') THEN 'Q2'
            WHEN STRFTIME('%m', InvoiceDate) IN ('01', '02', '03') THEN 'Q3'
            ELSE 'Q4'
        END AS fiscal_quarter
        
    FROM invoices
)
SELECT
    fiscal_year,
    fiscal_quarter,
    COUNT(*) AS transaction_count,
    SUM(Total) AS total_revenue,
    AVG(Total) AS avg_transaction
FROM fiscal_year_sales
GROUP BY fiscal_year, fiscal_quarter
ORDER BY fiscal_year, fiscal_quarter;

-- Exercise 2: Employee Tenure Analysis
SELECT
    e.EmployeeId,
    e.FirstName || ' ' || e.LastName AS employee_name,
    e.Title,
    e.HireDate,
    
    -- Calculate current tenure
    ROUND((JULIANDAY('now') - JULIANDAY(e.HireDate)) / 365.25, 1) AS tenure_years,
    
    -- Performance metrics
    COUNT(DISTINCT c.CustomerId) AS customers_managed,
    COALESCE(SUM(i.Total), 0) AS total_sales_value,
    
    -- Business insights
    CASE 
        WHEN (JULIANDAY('now') - JULIANDAY(e.HireDate)) / 365.25 < 1 THEN 'New Employee'
        WHEN (JULIANDAY('now') - JULIANDAY(e.HireDate)) / 365.25 < 3 THEN 'Junior Employee'
        WHEN (JULIANDAY('now') - JULIANDAY(e.HireDate)) / 365.25 < 7 THEN 'Experienced Employee'
        ELSE 'Senior Employee'
    END AS experience_level
    
FROM employees e
LEFT JOIN customers c ON e.EmployeeId = c.SupportRepId
LEFT JOIN invoices i ON c.CustomerId = i.CustomerId
GROUP BY e.EmployeeId, e.FirstName, e.LastName, e.Title, e.HireDate
ORDER BY tenure_years DESC;

-- =================================================================================================================================
-- KEY TAKEAWAYS
-- =================================================================================================================================
--
-- DATE/TIME ANALYSIS ENABLES:
-- • Seasonal pattern identification for inventory and marketing
-- • Customer lifecycle and retention analysis
-- • Operational efficiency measurement and SLA tracking
-- • Financial reporting and compliance requirements
-- • Trend analysis and forecasting capabilities
--
-- NEXT STEPS:
-- 1. Master date component extraction and formatting
-- 2. Learn advanced date arithmetic and interval calculations
-- 3. Implement time series analysis and gap detection
-- 4. Build comprehensive temporal dashboards
--
-- =================================================================================================================================
