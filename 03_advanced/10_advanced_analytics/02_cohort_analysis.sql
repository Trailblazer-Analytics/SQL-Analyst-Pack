-- File: 10_advanced-analytics/02_cohort_analysis.sql
-- Topic: Cohort Analysis - Customer Retention and Lifetime Value Analytics
-- Author: SQL Analyst Pack
-- Date: 2024

/*
PURPOSE:
Master cohort analysis to understand customer behavior patterns, retention trends, and lifetime value.
This analysis is fundamental for subscription businesses, e-commerce, and any customer-centric organization.

BUSINESS APPLICATIONS:
- Customer retention measurement and optimization
- Lifetime value (LTV) calculation and forecasting  
- Product-market fit validation
- Marketing campaign effectiveness analysis
- Churn prediction and prevention strategies
- Subscription business health monitoring

REAL-WORLD SCENARIOS:
- SaaS companies tracking monthly user retention
- E-commerce analyzing customer purchase patterns
- Mobile apps measuring user engagement decay
- Financial services monitoring account activity
- Content platforms evaluating subscriber retention

ADVANCED CONCEPTS:
- Multi-dimensional cohort segmentation
- Revenue-based cohort analysis  
- Predictive cohort modeling
- Cohort comparison and benchmarking
- Dynamic cohort definition strategies
*/

---------------------------------------------------------------------------------------------------
-- SECTION 1: COHORT ANALYSIS FUNDAMENTALS
---------------------------------------------------------------------------------------------------

-- What is Cohort Analysis?
-- A cohort is a group of customers who share a common characteristic within a defined time period.
-- Most commonly: customers who made their first purchase in the same month/week.

-- Why Cohort Analysis Matters:
-- 1. RETENTION INSIGHTS: Understand how customer engagement changes over time
-- 2. BUSINESS HEALTH: Track if new customers are more/less engaged than historical ones
-- 3. PRODUCT IMPACT: Measure how product changes affect customer behavior
-- 4. FORECASTING: Predict future revenue based on retention patterns
-- 5. OPTIMIZATION: Identify the best customer acquisition periods and channels

-- Example Business Impact:
-- - Netflix uses cohort analysis to optimize content strategy and reduce churn
-- - Spotify tracks music discovery patterns to improve recommendation algorithms
-- - Amazon analyzes purchase cohorts to personalize shopping experiences

---------------------------------------------------------------------------------------------------
-- SECTION 2: BASIC CUSTOMER RETENTION COHORT ANALYSIS  
---------------------------------------------------------------------------------------------------

-- Business Scenario: E-commerce company wants to understand customer loyalty
-- Goal: Track monthly customer retention rates by acquisition cohort
-- Key Metric: Percentage of customers who make repeat purchases over time

-- Sample Data Structure
/*
CREATE TABLE customer_orders (
    customer_id INT,
    order_date DATE,
    order_value DECIMAL(10,2),
    order_number INT,
    acquisition_channel VARCHAR(50)
);
*/
    SELECT
        CustomerId,
        MIN(DATE(InvoiceDate, 'start of month')) AS CohortMonth
    FROM
        invoices
    GROUP BY
        CustomerId
),

-- Step 2: Calculate the monthly activity for each customer.
MonthlyActivity AS (
    SELECT DISTINCT
        CustomerId,
        DATE(InvoiceDate, 'start of month') AS ActivityMonth
    FROM
        invoices
),

-- Step 3: Join cohorts with their monthly activity and calculate the month number.
-- The month number is the number of months that have passed since the cohort month.
CohortActivity AS (
    SELECT
        ma.CustomerId,
        cc.CohortMonth,
        ma.ActivityMonth,
        -- Calculate the difference in months between activity and cohort month.
        -- This logic is highly dialect-specific.
        (CAST(STRFTIME('%Y', ma.ActivityMonth) AS INTEGER) - CAST(STRFTIME('%Y', cc.CohortMonth) AS INTEGER)) * 12 +
        (CAST(STRFTIME('%m', ma.ActivityMonth) AS INTEGER) - CAST(STRFTIME('%m', cc.CohortMonth) AS INTEGER)) AS MonthNumber
    FROM
        MonthlyActivity ma
    JOIN
        CustomerCohorts cc ON ma.CustomerId = cc.CustomerId
),

-- Step 4: Count the number of unique customers in each cohort for each month number.
CohortSize AS (
    SELECT
        CohortMonth,
        MonthNumber,
        COUNT(DISTINCT CustomerId) AS ActiveCustomers
    FROM
        CohortActivity
    GROUP BY
        CohortMonth, MonthNumber
),

-- Step 5: Get the initial size of each cohort (number of customers in Month 0).
InitialCohortSize AS (
    SELECT
        CohortMonth,
        ActiveCustomers AS TotalCohortSize
    FROM
        CohortSize
    WHERE
        MonthNumber = 0
)

-- Final Step: Join the cohort sizes to calculate retention percentages and pivot the data.
SELECT
    cs.CohortMonth,
    ics.TotalCohortSize,
    cs.MonthNumber,
    cs.ActiveCustomers,
    -- Calculate retention rate
    (CAST(cs.ActiveCustomers AS REAL) / ics.TotalCohortSize) * 100 AS RetentionPercentage
FROM
    CohortSize cs
JOIN
    InitialCohortSize ics ON cs.CohortMonth = ics.CohortMonth
ORDER BY
    cs.CohortMonth, cs.MonthNumber;

-- To create the classic cohort chart, you would pivot the results of this query,
-- with CohortMonth as rows, MonthNumber as columns, and RetentionPercentage as values.
-- Most SQL dialects require conditional aggregation for pivoting.

-- Example of Pivoting (for a few months):
/*
SELECT
    CohortMonth,
    TotalCohortSize,
    MAX(CASE WHEN MonthNumber = 0 THEN RetentionPercentage END) AS Month_0,
    MAX(CASE WHEN MonthNumber = 1 THEN RetentionPercentage END) AS Month_1,
    MAX(CASE WHEN MonthNumber = 2 THEN RetentionPercentage END) AS Month_2,
    MAX(CASE WHEN MonthNumber = 3 THEN RetentionPercentage END) AS Month_3
FROM (
    SELECT
        cs.CohortMonth,
        ics.TotalCohortSize,
        cs.MonthNumber,
        (CAST(cs.ActiveCustomers AS REAL) / ics.TotalCohortSize) * 100 AS RetentionPercentage
    FROM
        CohortSize cs
    JOIN
        InitialCohortSize ics ON cs.CohortMonth = ics.CohortMonth
) AS SubQuery
GROUP BY
    CohortMonth, TotalCohortSize
ORDER BY
    CohortMonth;
*/

---------------------------------------------------------------------------------------------------

-- Dialect-Specific Notes for Month Difference Calculation:

-- PostgreSQL:
-- `(EXTRACT(YEAR FROM ma.ActivityMonth) - EXTRACT(YEAR FROM cc.CohortMonth)) * 12 +`
-- `(EXTRACT(MONTH FROM ma.ActivityMonth) - EXTRACT(MONTH FROM cc.CohortMonth)) AS MonthNumber`

-- SQL Server:
-- `DATEDIFF(month, cc.CohortMonth, ma.ActivityMonth) AS MonthNumber`

-- MySQL:
-- `PERIOD_DIFF(DATE_FORMAT(ma.ActivityMonth, '%Y%m'), DATE_FORMAT(cc.CohortMonth, '%Y%m')) AS MonthNumber`

-- This script provides a foundational template for cohort analysis. The real power comes from
-- adapting it to specific business questions and visualizing the resulting data.

---------------------------------------------------------------------------------------------------
-- SECTION 2: CUSTOMER RETENTION COHORT ANALYSIS
---------------------------------------------------------------------------------------------------

-- CUSTOMER RETENTION COHORT ANALYSIS
-- Step-by-step breakdown for business understanding

WITH
-- Step 1: Identify each customer's first purchase (cohort assignment)
customer_first_purchase AS (
    SELECT 
        customer_id,
        MIN(order_date) as first_purchase_date,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month
    FROM customer_orders
    GROUP BY customer_id
),

-- Step 2: Create customer activity timeline by month
customer_monthly_activity AS (
    SELECT 
        co.customer_id,
        cfp.cohort_month,
        DATE_TRUNC('month', co.order_date) as activity_month,
        COUNT(*) as orders_in_month,
        SUM(co.order_value) as revenue_in_month
    FROM customer_orders co
    JOIN customer_first_purchase cfp ON co.customer_id = cfp.customer_id
    GROUP BY co.customer_id, cfp.cohort_month, DATE_TRUNC('month', co.order_date)
),

-- Step 3: Calculate period numbers (months since first purchase)
cohort_periods AS (
    SELECT 
        customer_id,
        cohort_month,
        activity_month,
        orders_in_month,
        revenue_in_month,
        -- Calculate months elapsed since cohort start
        EXTRACT(MONTH FROM AGE(activity_month, cohort_month)) + 
        EXTRACT(YEAR FROM AGE(activity_month, cohort_month)) * 12 as period_number
    FROM customer_monthly_activity
),

-- Step 4: Calculate cohort sizes and retention metrics
cohort_retention AS (
    SELECT 
        cohort_month,
        period_number,
        COUNT(DISTINCT customer_id) as customers_active,
        SUM(revenue_in_month) as cohort_revenue,
        AVG(revenue_in_month) as avg_revenue_per_customer
    FROM cohort_periods
    GROUP BY cohort_month, period_number
),

-- Step 5: Add cohort sizes for retention percentage calculation
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size,
        SUM(first_order_value) as total_first_month_revenue
    FROM (
        SELECT 
            cfp.cohort_month,
            cfp.customer_id,
            SUM(co.order_value) as first_order_value
        FROM customer_first_purchase cfp
        JOIN customer_orders co ON cfp.customer_id = co.customer_id 
        WHERE DATE_TRUNC('month', co.order_date) = cfp.cohort_month
        GROUP BY cfp.cohort_month, cfp.customer_id
    ) first_month_orders
    GROUP BY cohort_month
)

-- Final cohort analysis output
SELECT 
    cr.cohort_month,
    cr.period_number,
    cs.cohort_size,
    cr.customers_active,
    ROUND(cr.customers_active * 100.0 / cs.cohort_size, 2) as retention_rate,
    cr.cohort_revenue,
    ROUND(cr.avg_revenue_per_customer, 2) as avg_revenue_per_customer,
    -- Cumulative revenue per cohort
    SUM(cr.cohort_revenue) OVER (
        PARTITION BY cr.cohort_month 
        ORDER BY cr.period_number
    ) as cumulative_revenue
FROM cohort_retention cr
JOIN cohort_sizes cs ON cr.cohort_month = cs.cohort_month
WHERE cr.period_number <= 12  -- Focus on first year retention
ORDER BY cr.cohort_month, cr.period_number;

-- BUSINESS INTERPRETATION GUIDE:
-- - Period 0: First month (100% retention by definition)
-- - Period 1: Second month retention (critical metric)
-- - Period 3: Quarter retention (seasonal analysis)
-- - Period 6: Half-year retention (product-market fit indicator)
-- - Period 12: Annual retention (customer lifetime value basis)

---------------------------------------------------------------------------------------------------
-- SECTION 3: REVENUE-BASED COHORT ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: Understanding customer lifetime value by acquisition period
-- Goal: Track revenue generation patterns rather than just retention
-- Key Insight: Some cohorts may have lower retention but higher revenue per customer

-- Revenue Cohort Analysis with Customer Lifetime Value
WITH customer_revenue_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month,
        COUNT(*) as total_orders,
        SUM(order_value) as total_lifetime_value,
        AVG(order_value) as avg_order_value,
        MAX(order_date) - MIN(order_date) as customer_lifespan
    FROM customer_orders
    GROUP BY customer_id
),
monthly_cohort_revenue AS (
    SELECT 
        crc.cohort_month,
        DATE_TRUNC('month', co.order_date) as revenue_month,
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', co.order_date), crc.cohort_month)) + 
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', co.order_date), crc.cohort_month)) * 12 as period_number,
        COUNT(DISTINCT co.customer_id) as active_customers,
        SUM(co.order_value) as period_revenue,
        COUNT(*) as total_orders
    FROM customer_revenue_cohorts crc
    JOIN customer_orders co ON crc.customer_id = co.customer_id
    GROUP BY crc.cohort_month, DATE_TRUNC('month', co.order_date)
),
cohort_revenue_analysis AS (
    SELECT 
        cohort_month,
        period_number,
        active_customers,
        period_revenue,
        total_orders,
        ROUND(period_revenue / active_customers, 2) as revenue_per_customer,
        ROUND(total_orders::DECIMAL / active_customers, 2) as orders_per_customer,
        -- Running totals for LTV calculation
        SUM(period_revenue) OVER (
            PARTITION BY cohort_month 
            ORDER BY period_number
        ) as cumulative_revenue,
        SUM(active_customers) OVER (
            PARTITION BY cohort_month 
            ORDER BY period_number
        ) as cumulative_customer_months
    FROM monthly_cohort_revenue
    WHERE period_number <= 24  -- Two year analysis
)
SELECT 
    cohort_month,
    period_number,
    active_customers,
    period_revenue,
    revenue_per_customer,
    orders_per_customer,
    cumulative_revenue,
    ROUND(cumulative_revenue / 
          FIRST_VALUE(active_customers) OVER (
              PARTITION BY cohort_month 
              ORDER BY period_number
          ), 2) as ltv_to_date
FROM cohort_revenue_analysis
ORDER BY cohort_month, period_number;

-- BUSINESS INSIGHTS:
-- 1. LTV_TO_DATE: Customer lifetime value accumulated up to each period
-- 2. REVENUE_PER_CUSTOMER: Monthly revenue intensity by cohort age
-- 3. ORDERS_PER_CUSTOMER: Purchase frequency patterns
-- 4. Use to optimize customer acquisition cost (CAC) vs LTV ratios

---------------------------------------------------------------------------------------------------
-- SECTION 4: SEGMENTED COHORT ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: Marketing team wants to compare acquisition channel performance
-- Goal: Understand which marketing channels produce the most valuable long-term customers
-- Application: Optimize marketing budget allocation across channels

-- Multi-Dimensional Cohort Analysis by Acquisition Channel
WITH customer_acquisition_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month,
        acquisition_channel,
        MIN(order_date) as first_order_date
    FROM customer_orders
    GROUP BY customer_id, acquisition_channel
),
channel_cohort_performance AS (
    SELECT 
        cac.cohort_month,
        cac.acquisition_channel,
        DATE_TRUNC('month', co.order_date) as activity_month,
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', co.order_date), cac.cohort_month)) + 
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', co.order_date), cac.cohort_month)) * 12 as period_number,
        COUNT(DISTINCT co.customer_id) as active_customers,
        SUM(co.order_value) as channel_revenue,
        AVG(co.order_value) as avg_order_value
    FROM customer_acquisition_cohorts cac
    JOIN customer_orders co ON cac.customer_id = co.customer_id
    GROUP BY cac.cohort_month, cac.acquisition_channel, DATE_TRUNC('month', co.order_date)
),
channel_sizes AS (
    SELECT 
        cohort_month,
        acquisition_channel,
        COUNT(DISTINCT customer_id) as initial_cohort_size
    FROM customer_acquisition_cohorts
    GROUP BY cohort_month, acquisition_channel
)
SELECT 
    ccp.cohort_month,
    ccp.acquisition_channel,
    ccp.period_number,
    cs.initial_cohort_size,
    ccp.active_customers,
    ROUND(ccp.active_customers * 100.0 / cs.initial_cohort_size, 2) as retention_rate,
    ccp.channel_revenue,
    ROUND(ccp.channel_revenue / ccp.active_customers, 2) as revenue_per_active_customer,
    -- Channel comparison metrics
    ROUND(ccp.channel_revenue / cs.initial_cohort_size, 2) as revenue_per_original_customer,
    RANK() OVER (
        PARTITION BY ccp.period_number 
        ORDER BY ccp.channel_revenue / cs.initial_cohort_size DESC
    ) as channel_rank_by_revenue
FROM channel_cohort_performance ccp
JOIN channel_sizes cs ON ccp.cohort_month = cs.cohort_month 
    AND ccp.acquisition_channel = cs.acquisition_channel
WHERE ccp.period_number <= 12
ORDER BY ccp.cohort_month, ccp.acquisition_channel, ccp.period_number;

-- STRATEGIC INSIGHTS:
-- 1. Compare retention rates across acquisition channels
-- 2. Identify channels that produce highest lifetime value customers
-- 3. Optimize marketing spend based on long-term customer value
-- 4. Adjust acquisition strategies based on cohort performance patterns

---------------------------------------------------------------------------------------------------
-- SECTION 5: PREDICTIVE COHORT MODELING
---------------------------------------------------------------------------------------------------

-- Business Scenario: Finance team needs revenue forecasting for existing customers
-- Goal: Predict future revenue from current customer cohorts
-- Method: Use historical retention patterns to forecast future performance

-- Cohort Retention Rate Forecasting
WITH historical_retention AS (
    -- Calculate average retention rates by period across all cohorts
    SELECT 
        period_number,
        AVG(retention_rate) as avg_retention_rate,
        STDDEV(retention_rate) as retention_volatility,
        COUNT(*) as cohort_sample_size
    FROM (
        -- Your cohort retention analysis from previous sections
        SELECT 
            cohort_month,
            period_number,
            customers_active * 100.0 / 
            FIRST_VALUE(customers_active) OVER (
                PARTITION BY cohort_month 
                ORDER BY period_number
            ) as retention_rate
        FROM cohort_retention cr
        WHERE period_number <= 12
    ) retention_history
    GROUP BY period_number
),
recent_cohorts AS (
    -- Identify cohorts with incomplete data for forecasting
    SELECT DISTINCT cohort_month
    FROM cohort_retention
    WHERE cohort_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
),
forecast_base AS (
    SELECT 
        rc.cohort_month,
        cs.cohort_size,
        hr.period_number,
        hr.avg_retention_rate,
        -- Apply historical retention rates to recent cohorts
        ROUND(cs.cohort_size * hr.avg_retention_rate / 100.0) as forecasted_active_customers
    FROM recent_cohorts rc
    CROSS JOIN historical_retention hr
    JOIN cohort_sizes cs ON rc.cohort_month = cs.cohort_month
    WHERE hr.period_number > 
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, rc.cohort_month))
)
SELECT 
    cohort_month,
    period_number,
    forecasted_active_customers,
    -- Estimate revenue based on historical patterns
    forecasted_active_customers * 50 as forecasted_revenue,  -- Adjust $50 based on your avg order value
    'FORECAST' as data_type
FROM forecast_base
WHERE forecasted_active_customers > 0

UNION ALL

-- Include actual historical data for comparison
SELECT 
    cohort_month,
    period_number,
    customers_active as forecasted_active_customers,
    cohort_revenue as forecasted_revenue,
    'ACTUAL' as data_type
FROM cohort_retention
WHERE cohort_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')

ORDER BY cohort_month, period_number;

-- FORECASTING APPLICATIONS:
-- 1. Revenue forecasting for business planning
-- 2. Customer lifetime value predictions
-- 3. Capacity planning for customer success teams
-- 4. Investment planning based on expected customer growth

---------------------------------------------------------------------------------------------------
-- SECTION 6: COHORT HEALTH SCORING SYSTEM
---------------------------------------------------------------------------------------------------

-- Business Scenario: Executive dashboard needs simple cohort health indicators
-- Goal: Create actionable scores for business leaders
-- Output: Traffic light system for cohort performance

-- Cohort Health Score Calculation
WITH cohort_health_metrics AS (
    SELECT 
        cohort_month,
        -- Key health indicators
        MAX(CASE WHEN period_number = 1 THEN retention_rate END) as month_1_retention,
        MAX(CASE WHEN period_number = 3 THEN retention_rate END) as month_3_retention,
        MAX(CASE WHEN period_number = 6 THEN retention_rate END) as month_6_retention,
        MAX(CASE WHEN period_number = 12 THEN retention_rate END) as month_12_retention,
        AVG(avg_revenue_per_customer) as avg_monthly_revenue_per_customer,
        MAX(cumulative_revenue) / MAX(cohort_size) as estimated_ltv
    FROM (
        -- Use your cohort analysis results
        SELECT * FROM cohort_retention cr
        JOIN cohort_sizes cs ON cr.cohort_month = cs.cohort_month
    ) cohort_data
    GROUP BY cohort_month
),
benchmark_scores AS (
    SELECT 
        -- Industry benchmarks (adjust based on your business)
        PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY month_1_retention) as benchmark_month_1,
        PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY month_3_retention) as benchmark_month_3,
        PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY month_6_retention) as benchmark_month_6,
        PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY estimated_ltv) as benchmark_ltv
    FROM cohort_health_metrics
)
SELECT 
    chm.cohort_month,
    chm.month_1_retention,
    chm.month_3_retention,
    chm.month_6_retention,
    chm.estimated_ltv,
    -- Health scoring (0-100 scale)
    CASE 
        WHEN chm.month_1_retention >= bs.benchmark_month_1 * 1.2 THEN 100
        WHEN chm.month_1_retention >= bs.benchmark_month_1 THEN 80
        WHEN chm.month_1_retention >= bs.benchmark_month_1 * 0.8 THEN 60
        ELSE 40
    END as retention_health_score,
    CASE 
        WHEN chm.estimated_ltv >= bs.benchmark_ltv * 1.2 THEN 100
        WHEN chm.estimated_ltv >= bs.benchmark_ltv THEN 80
        WHEN chm.estimated_ltv >= bs.benchmark_ltv * 0.8 THEN 60
        ELSE 40
    END as ltv_health_score,
    -- Overall cohort health assessment
    CASE 
        WHEN (chm.month_1_retention >= bs.benchmark_month_1 * 1.1 
              AND chm.estimated_ltv >= bs.benchmark_ltv * 1.1) THEN 'EXCELLENT'
        WHEN (chm.month_1_retention >= bs.benchmark_month_1 * 0.9 
              AND chm.estimated_ltv >= bs.benchmark_ltv * 0.9) THEN 'GOOD'
        WHEN (chm.month_1_retention >= bs.benchmark_month_1 * 0.7 
              AND chm.estimated_ltv >= bs.benchmark_ltv * 0.7) THEN 'FAIR'
        ELSE 'NEEDS_ATTENTION'
    END as cohort_health_status
FROM cohort_health_metrics chm
CROSS JOIN benchmark_scores bs
ORDER BY chm.cohort_month DESC;

---------------------------------------------------------------------------------------------------
-- KEY BUSINESS APPLICATIONS AND INSIGHTS
---------------------------------------------------------------------------------------------------

/*
CUSTOMER SUCCESS TEAMS:
- Identify at-risk customer segments for proactive intervention
- Optimize onboarding processes based on early retention patterns
- Design customer success programs targeting specific cohort needs

MARKETING TEAMS:  
- Compare acquisition channel effectiveness over customer lifetime
- Optimize customer acquisition cost (CAC) vs lifetime value (LTV) ratios
- Time marketing campaigns based on cohort behavior patterns

PRODUCT TEAMS:
- Measure product-market fit through retention pattern analysis
- Validate feature releases impact on customer engagement
- Identify optimal timing for product announcements and upgrades

FINANCE TEAMS:
- Forecast revenue from existing customer base
- Calculate customer lifetime value for financial planning
- Support pricing strategy decisions with retention insights

EXECUTIVE LEADERSHIP:
- Monitor business health through cohort performance trends
- Make strategic decisions about customer acquisition vs retention investment
- Benchmark performance against industry standards and internal goals

NEXT STEPS:
1. Implement basic cohort analysis for your customer base
2. Segment cohorts by acquisition channel, product, or customer characteristics
3. Build automated cohort dashboards for regular business monitoring
4. Develop predictive models based on cohort patterns
5. Create alert systems for declining cohort performance
*/
