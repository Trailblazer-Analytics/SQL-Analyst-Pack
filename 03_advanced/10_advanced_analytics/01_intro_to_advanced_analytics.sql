-- File: 10_advanced-analytics/01_intro_to_advanced_analytics.sql
-- Topic: Introduction to Advanced Analytics - Foundation Concepts and Business Metrics
-- Author: SQL Analyst Pack
-- Date: 2024

/*
PURPOSE:
Transform your SQL skills from basic reporting to strategic business intelligence.
This script introduces advanced analytical concepts that drive data-driven decision making
and unlock deeper business insights.

BUSINESS APPLICATIONS:
- Executive dashboard KPI calculations
- Customer lifetime value modeling
- Market segmentation and targeting
- Performance benchmarking and analysis
- Predictive analytics foundations

PREREQUISITE SKILLS:
- Window functions mastery (Module 05)
- Advanced aggregations (Module 04)  
- Date/time analysis (Module 06)
- Text analysis techniques (Module 07)

ADVANCED CONCEPTS COVERED:
- Statistical measures and distributions
- Percentile analysis and outlier detection
- Customer segmentation frameworks
- Business metric calculations
- Performance benchmarking systems
*/

---------------------------------------------------------------------------------------------------
-- SECTION 1: ADVANCED ANALYTICS FOUNDATIONS
---------------------------------------------------------------------------------------------------

-- What differentiates advanced analytics from basic reporting?
-- Basic: COUNT, SUM, AVG (what happened?)
-- Advanced: Percentiles, cohorts, forecasting (why did it happen? what will happen?)

-- Example: Traditional vs Advanced Customer Analysis
-- Traditional: Average order value = $50
-- Advanced: 
--   - 50th percentile (median) = $35 (more representative)
--   - 90th percentile = $120 (high-value customer threshold) 
--   - Customer segments based on purchase behavior
--   - Lifetime value predictions

---------------------------------------------------------------------------------------------------
-- SECTION 2: STATISTICAL MEASURES FOR BUSINESS INSIGHTS  
---------------------------------------------------------------------------------------------------

-- Advanced Analytics Framework: The Five Pillars of Business Intelligence
-- 1. DESCRIPTIVE: What happened? (percentiles, distributions)
-- 2. DIAGNOSTIC: Why did it happen? (correlation analysis)  
-- 3. PREDICTIVE: What will happen? (trend analysis, forecasting)
-- 4. PRESCRIPTIVE: What should we do? (optimization models)
-- 5. COGNITIVE: Can we automate decisions? (AI-driven insights)

-- Business Use Case: E-commerce Revenue Optimization
-- Challenge: Understanding customer value distribution to optimize pricing and promotions
-- Solution: Statistical profiling of customer behavior patterns

-- Sample Data Structure (for examples)
CREATE TABLE customer_orders (
    customer_id INT,
    order_date DATE,
    order_value DECIMAL(10,2),
    product_category VARCHAR(50),
    acquisition_channel VARCHAR(50)
);

-- PERCENTILE ANALYSIS FOR CUSTOMER SEGMENTATION
-- Traditional approach: All customers with orders above average are "high-value"
-- Problem: Average is skewed by outliers
-- Advanced approach: Use percentiles for more accurate segmentation

-- Customer Value Distribution Analysis
WITH customer_stats AS (
    SELECT 
        -- Statistical measures for customer segmentation
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_value) AS q1_25th_percentile,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY order_value) AS q2_median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_value) AS q3_75th_percentile,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY order_value) AS p90_high_value,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY order_value) AS p95_premium,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY order_value) AS p99_ultra_premium,
        AVG(order_value) AS average_order_value,
        COUNT(*) AS total_orders
    FROM customer_orders
),
customer_segments AS (
    SELECT 
        customer_id,
        order_value,
        -- Dynamic customer segmentation based on percentiles
        CASE 
            WHEN order_value >= (SELECT p99_ultra_premium FROM customer_stats) THEN 'Ultra Premium (Top 1%)'
            WHEN order_value >= (SELECT p95_premium FROM customer_stats) THEN 'Premium (Top 5%)'
            WHEN order_value >= (SELECT p90_high_value FROM customer_stats) THEN 'High Value (Top 10%)'
            WHEN order_value >= (SELECT q3_75th_percentile FROM customer_stats) THEN 'Above Average (Top 25%)'
            WHEN order_value >= (SELECT q2_median FROM customer_stats) THEN 'Average (Top 50%)'
            ELSE 'Below Average'
        END AS customer_segment,
        -- Percentile rank for each customer
        PERCENT_RANK() OVER (ORDER BY order_value) AS percentile_rank
    FROM customer_orders
)
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(order_value), 2) as avg_segment_value,
    ROUND(MIN(order_value), 2) as min_value,
    ROUND(MAX(order_value), 2) as max_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as segment_percentage
FROM customer_segments
GROUP BY customer_segment
ORDER BY avg_segment_value DESC;

-- BUSINESS INSIGHT: This analysis helps marketing teams:
-- 1. Set appropriate spending limits for promotional campaigns
-- 2. Create targeted messaging for different customer segments  
-- 3. Optimize inventory based on demand patterns
-- 4. Design loyalty programs with appropriate tier thresholds

---------------------------------------------------------------------------------------------------
-- SECTION 3: OUTLIER DETECTION FOR DATA QUALITY
---------------------------------------------------------------------------------------------------

-- Business Problem: Identifying unusual transactions that may indicate:
-- - Data quality issues
-- - Fraudulent activity  
-- - System errors
-- - Exceptional business opportunities

-- Interquartile Range (IQR) Method for Outlier Detection
WITH order_statistics AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_value) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_value) AS q3
    FROM customer_orders
),
outlier_bounds AS (
    SELECT 
        q1,
        q3,
        (q3 - q1) AS iqr,
        (q1 - 1.5 * (q3 - q1)) AS lower_bound,
        (q3 + 1.5 * (q3 - q1)) AS upper_bound
    FROM order_statistics
)
SELECT 
    customer_id,
    order_date,
    order_value,
    CASE 
        WHEN order_value < (SELECT lower_bound FROM outlier_bounds) THEN 'Unusually Low'
        WHEN order_value > (SELECT upper_bound FROM outlier_bounds) THEN 'Unusually High'
        ELSE 'Normal Range'
    END AS outlier_status,
    -- Z-score for additional context
    ROUND(
        (order_value - AVG(order_value) OVER ()) / 
        STDDEV(order_value) OVER (), 2
    ) AS z_score
FROM customer_orders
WHERE order_value < (SELECT lower_bound FROM outlier_bounds)
   OR order_value > (SELECT upper_bound FROM outlier_bounds)
ORDER BY ABS(order_value - (SELECT (q1 + q3) / 2 FROM order_statistics)) DESC;

-- BUSINESS APPLICATION: Risk Management and Quality Assurance
-- - Flag transactions requiring manual review
-- - Identify potential fraud patterns
-- - Discover emerging customer behavior trends
-- - Validate data integrity across systems

---------------------------------------------------------------------------------------------------
-- SECTION 4: DISTRIBUTION ANALYSIS FOR MARKET INSIGHTS
---------------------------------------------------------------------------------------------------

-- Understanding how your metrics are distributed provides crucial business insights:
-- - Normal distribution: Predictable, stable market
-- - Skewed distribution: Opportunity for optimization
-- - Bimodal distribution: Distinct customer segments
-- - Uniform distribution: May indicate data quality issues

-- Revenue Distribution Analysis by Product Category
WITH distribution_analysis AS (
    SELECT 
        product_category,
        COUNT(*) as order_count,
        ROUND(AVG(order_value), 2) as mean_value,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_value), 2) as median_value,
        ROUND(STDDEV(order_value), 2) as std_deviation,
        ROUND(MIN(order_value), 2) as min_value,
        ROUND(MAX(order_value), 2) as max_value,
        -- Distribution shape indicators
        ROUND(
            (AVG(order_value) - PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_value)) / 
            STDDEV(order_value), 2
        ) as skewness_indicator
    FROM customer_orders
    GROUP BY product_category
),
category_insights AS (
    SELECT 
        *,
        CASE 
            WHEN ABS(skewness_indicator) < 0.5 THEN 'Symmetric Distribution'
            WHEN skewness_indicator > 0.5 THEN 'Right Skewed (Few High Values)'
            ELSE 'Left Skewed (Few Low Values)'
        END as distribution_shape,
        CASE 
            WHEN std_deviation / mean_value < 0.3 THEN 'Low Variability'
            WHEN std_deviation / mean_value < 0.7 THEN 'Moderate Variability'
            ELSE 'High Variability'
        END as variability_level
    FROM distribution_analysis
)
SELECT 
    product_category,
    order_count,
    mean_value,
    median_value,
    distribution_shape,
    variability_level,
    -- Business recommendations based on distribution
    CASE 
        WHEN distribution_shape = 'Right Skewed (Few High Values)' THEN 'Focus on premium customer acquisition'
        WHEN distribution_shape = 'Left Skewed (Few Low Values)' THEN 'Optimize for volume sales'
        WHEN variability_level = 'High Variability' THEN 'Develop targeted pricing strategies'
        ELSE 'Maintain current strategy'
    END as strategic_recommendation
FROM category_insights
ORDER BY mean_value DESC;

---------------------------------------------------------------------------------------------------
-- SECTION 5: COHORT ANALYSIS FOUNDATION
---------------------------------------------------------------------------------------------------

-- Cohort analysis tracks groups of customers over time to understand:
-- - Customer retention patterns
-- - Lifetime value development  
-- - Product adoption cycles
-- - Seasonal behavior trends

-- Basic Monthly Cohort Analysis
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month,
        DATE_TRUNC('month', order_date) as order_month
    FROM customer_orders
    GROUP BY customer_id, DATE_TRUNC('month', order_date)
),
cohort_data AS (
    SELECT 
        cohort_month,
        order_month,
        COUNT(DISTINCT customer_id) as customers,
        -- Calculate months since first purchase
        EXTRACT(MONTH FROM AGE(order_month, cohort_month)) as month_number
    FROM customer_cohorts
    GROUP BY cohort_month, order_month
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM customer_orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    cd.cohort_month,
    cd.month_number,
    cd.customers,
    cs.cohort_size,
    ROUND(cd.customers * 100.0 / cs.cohort_size, 2) as retention_rate
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_number <= 12  -- Focus on first year
ORDER BY cd.cohort_month, cd.month_number;

-- BUSINESS INSIGHT: Use retention rates to:
-- 1. Identify most valuable acquisition periods
-- 2. Predict customer lifetime value
-- 3. Optimize onboarding and engagement strategies
-- 4. Forecast future revenue from existing customers

---------------------------------------------------------------------------------------------------
-- SECTION 6: PERFORMANCE BENCHMARKING FRAMEWORK
---------------------------------------------------------------------------------------------------

-- Create performance benchmarks using percentile-based scoring
-- This approach is more robust than simple averages and provides actionable insights

-- Customer Performance Scoring System
WITH performance_metrics AS (
    SELECT 
        customer_id,
        COUNT(*) as order_frequency,
        AVG(order_value) as avg_order_value,
        SUM(order_value) as total_spent,
        MAX(order_date) as last_order_date,
        MIN(order_date) as first_order_date,
        EXTRACT(DAYS FROM (MAX(order_date) - MIN(order_date))) as customer_lifespan_days
    FROM customer_orders
    GROUP BY customer_id
),
percentile_benchmarks AS (
    SELECT 
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY order_frequency) as freq_benchmark,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY avg_order_value) as aov_benchmark,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_spent) as spend_benchmark
    FROM performance_metrics
),
customer_scores AS (
    SELECT 
        pm.*,
        -- Performance scoring (0-100 scale)
        CASE 
            WHEN pm.order_frequency >= pb.freq_benchmark THEN 100
            ELSE ROUND(pm.order_frequency * 100.0 / pb.freq_benchmark, 0)
        END as frequency_score,
        CASE 
            WHEN pm.avg_order_value >= pb.aov_benchmark THEN 100
            ELSE ROUND(pm.avg_order_value * 100.0 / pb.aov_benchmark, 0)
        END as monetary_score,
        CASE 
            WHEN pm.total_spent >= pb.spend_benchmark THEN 100
            ELSE ROUND(pm.total_spent * 100.0 / pb.spend_benchmark, 0)
        END as loyalty_score
    FROM performance_metrics pm
    CROSS JOIN percentile_benchmarks pb
)
SELECT 
    customer_id,
    frequency_score,
    monetary_score,
    loyalty_score,
    ROUND((frequency_score + monetary_score + loyalty_score) / 3.0, 0) as overall_score,
    CASE 
        WHEN ROUND((frequency_score + monetary_score + loyalty_score) / 3.0, 0) >= 80 THEN 'Champion'
        WHEN ROUND((frequency_score + monetary_score + loyalty_score) / 3.0, 0) >= 60 THEN 'Loyal Customer'
        WHEN ROUND((frequency_score + monetary_score + loyalty_score) / 3.0, 0) >= 40 THEN 'Potential Loyalist'
        ELSE 'Needs Attention'
    END as customer_tier
FROM customer_scores
ORDER BY overall_score DESC;

-- BUSINESS APPLICATION: Customer Relationship Management
-- - Identify top customers for VIP treatment
-- - Target at-risk customers with retention campaigns
-- - Optimize marketing spend based on customer potential
-- - Design tiered service levels and benefits

---------------------------------------------------------------------------------------------------
-- KEY TAKEAWAYS: ADVANCED ANALYTICS PRINCIPLES
---------------------------------------------------------------------------------------------------

/*
1. BEYOND AVERAGES: Use percentiles and distributions for more accurate insights
2. SEGMENT EVERYTHING: Group analysis provides actionable business intelligence
3. TRACK OVER TIME: Cohort analysis reveals customer lifecycle patterns
4. BENCHMARK PERFORMANCE: Percentile-based scoring is more robust than averages
5. BUSINESS CONTEXT: Always connect statistical insights to business decisions

NEXT STEPS:
- Practice cohort analysis with your customer data
- Implement percentile-based customer segmentation
- Build performance dashboards using these frameworks
- Explore predictive analytics using historical patterns

ADVANCED MODULES TO EXPLORE:
- Module 11: Funnel Analysis and Conversion Optimization
- Module 12: A/B Testing and Statistical Validation  
- Module 13: Time Series Analysis and Forecasting
- Module 14: Customer Lifetime Value Modeling
*/
