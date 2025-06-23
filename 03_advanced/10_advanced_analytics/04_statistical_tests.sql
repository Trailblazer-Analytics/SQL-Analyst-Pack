-- File: 10_advanced-analytics/04_statistical_tests.sql
-- Topic: Statistical Testing and A/B Testing - Data-Driven Decision Making
-- Author: SQL Analyst Pack
-- Date: 2024

/*
PURPOSE:
Master statistical testing in SQL to validate business hypotheses and drive data-driven decisions.
Essential for A/B testing, product experiments, marketing optimization, and business intelligence.

BUSINESS APPLICATIONS:
- A/B testing for website and app optimization
- Marketing campaign effectiveness measurement
- Product feature impact validation
- Customer segmentation statistical validation
- Business hypothesis testing and validation
- Conversion rate optimization experiments

REAL-WORLD SCENARIOS:
- E-commerce testing checkout flow variations
- SaaS company validating pricing strategy changes
- Marketing team comparing campaign performance
- Product team measuring feature adoption impact
- Sales team testing different outreach strategies

ADVANCED CONCEPTS:
- Hypothesis testing frameworks
- Statistical significance calculation
- Power analysis and sample size determination
- Multi-variant testing (MVT)
- Bayesian A/B testing approaches
- Sequential testing and early stopping
*/

---------------------------------------------------------------------------------------------------
-- SECTION 1: STATISTICAL TESTING FUNDAMENTALS
---------------------------------------------------------------------------------------------------

-- What is Statistical Testing?
-- A systematic approach to determine if observed differences in data are statistically significant
-- or just due to random chance. Critical for making confident business decisions.

-- Why Statistical Testing Matters:
-- 1. DECISION CONFIDENCE: Make data-driven decisions with statistical backing
-- 2. RISK MITIGATION: Avoid costly mistakes based on random variations
-- 3. OPTIMIZATION: Systematically improve products, processes, and strategies
-- 4. RESOURCE ALLOCATION: Invest in changes that have proven impact
-- 5. COMPETITIVE ADVANTAGE: Outperform competitors through systematic testing

-- Key Statistical Concepts:
-- - Null Hypothesis (H0): No difference exists between groups
-- - Alternative Hypothesis (H1): A significant difference exists
-- - P-value: Probability that results occurred by chance
-- - Statistical Significance: Typically p < 0.05 (95% confidence)
-- - Type I Error: False positive (rejecting true null hypothesis)
-- - Type II Error: False negative (failing to reject false null hypothesis)

-- Business Impact Examples:
-- - Netflix increased engagement 20% through systematic A/B testing
-- - Amazon improved conversion rates 15% via checkout optimization
-- - Google optimized ad revenue 12% using statistical experimentation

---------------------------------------------------------------------------------------------------
-- SECTION 2: A/B TESTING FRAMEWORK IN SQL
---------------------------------------------------------------------------------------------------

-- Business Scenario: E-commerce company testing new checkout flow
-- Goal: Determine if new checkout design increases conversion rates
-- Hypothesis: New design will improve conversion rate by at least 2%

-- Sample Data Structure
/*
CREATE TABLE ab_test_data (
    user_id INT,
    test_group VARCHAR(20), -- 'control' or 'treatment'
    experiment_start_date DATE,
    converted BOOLEAN,
    conversion_value DECIMAL(10,2),
    days_to_conversion INT
);
*/
-- - Group A: USA Customers
-- - Group B: Canada Customers
-- - Metric: Invoice Total

-- We can get all the necessary data in a single SQL query.

-- PostgreSQL, SQL Server, Oracle, MySQL, Snowflake Version:
SELECT
    BillingCountry AS TestGroup,
    COUNT(Total) AS SampleSize,
    AVG(Total) AS Mean,
    VAR_SAMP(Total) AS Variance,
    STDDEV_SAMP(Total) AS StandardDeviation
FROM
    invoices
WHERE
    BillingCountry IN ('USA', 'Canada')
GROUP BY
    BillingCountry;

-- Note on SQLite:
-- SQLite does not have built-in `VAR_SAMP` or `STDDEV_SAMP` functions.
-- You would need to calculate variance manually using the formula:
-- Variance = (SUM(x^2) - (SUM(x) * SUM(x)) / N) / (N - 1)
-- where x is the value (Total), and N is the sample size.

-- Example for SQLite (more complex):
/*
WITH GroupStats AS (
    SELECT
        BillingCountry AS TestGroup,
        COUNT(Total) AS SampleSize,
        SUM(Total) AS SumTotal,
        SUM(Total * Total) AS SumTotalSquared
    FROM
        invoices
    WHERE
        BillingCountry IN ('USA', 'Canada')
    GROUP BY
        BillingCountry
)
SELECT
    TestGroup,
    SampleSize,
    SumTotal / SampleSize AS Mean,
    -- Manual variance calculation
    (SumTotalSquared - (SumTotal * SumTotal) / SampleSize) / (SampleSize - 1) AS Variance
FROM
    GroupStats;
*/

---------------------------------------------------------------------------------------------------

-- Section 3: Interpreting the Results

-- The output of the SQL query might look something like this (hypothetical values):

-- TestGroup | SampleSize | Mean   | Variance
-- ----------|------------|--------|----------
-- USA       | 91         | 5.87   | 28.5
-- Canada    | 56         | 5.52   | 25.9

-- With this data, a data scientist or analyst can now:
-- 1. Plug these numbers into a t-test formula or software.
-- 2. Calculate the t-statistic and the p-value.
-- 3. Draw a conclusion: If the p-value is below a certain threshold (e.g., 0.05), they would
--    conclude that there is a statistically significant difference in average invoice totals
--    between USA and Canadian customers.

-- This script shows that while SQL is not a replacement for a statistical package, it is the
-- indispensable first step for preparing and aggregating data for rigorous analysis.

---------------------------------------------------------------------------------------------------
-- SECTION 2: A/B TESTING FRAMEWORK IN SQL (CONTINUED)
---------------------------------------------------------------------------------------------------

-- BASIC A/B TEST ANALYSIS
-- Statistical comparison of control vs treatment groups

WITH ab_test_results AS (
    SELECT 
        test_group,
        COUNT(*) as sample_size,
        SUM(CASE WHEN converted THEN 1 ELSE 0 END) as conversions,
        AVG(CASE WHEN converted THEN 1.0 ELSE 0.0 END) as conversion_rate,
        SUM(conversion_value) as total_revenue,
        AVG(conversion_value) as avg_revenue_per_user,
        STDDEV(CASE WHEN converted THEN 1.0 ELSE 0.0 END) as conversion_stddev,
        VAR_SAMP(CASE WHEN converted THEN 1.0 ELSE 0.0 END) as conversion_variance
    FROM ab_test_data
    WHERE experiment_start_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
    GROUP BY test_group
),

statistical_comparison AS (
    SELECT 
        c.test_group as control_group,
        c.sample_size as control_sample_size,
        c.conversion_rate as control_conversion_rate,
        c.conversion_stddev as control_stddev,
        
        t.test_group as treatment_group,
        t.sample_size as treatment_sample_size,
        t.conversion_rate as treatment_conversion_rate,
        t.conversion_stddev as treatment_stddev,
        
        -- Effect size calculation
        (t.conversion_rate - c.conversion_rate) as absolute_effect,
        ROUND((t.conversion_rate - c.conversion_rate) * 100.0 / c.conversion_rate, 2) as relative_effect_percent,
        
        -- Standard error calculation for two-proportion z-test
        SQRT(
            (c.conversion_rate * (1 - c.conversion_rate) / c.sample_size) +
            (t.conversion_rate * (1 - t.conversion_rate) / t.sample_size)
        ) as standard_error,
        
        -- Z-score calculation
        (t.conversion_rate - c.conversion_rate) / 
        SQRT(
            (c.conversion_rate * (1 - c.conversion_rate) / c.sample_size) +
            (t.conversion_rate * (1 - t.conversion_rate) / t.sample_size)
        ) as z_score
    FROM ab_test_results c
    CROSS JOIN ab_test_results t
    WHERE c.test_group = 'control' 
    AND t.test_group = 'treatment'
)

SELECT 
    control_group,
    control_sample_size,
    ROUND(control_conversion_rate * 100, 2) as control_conversion_rate_percent,
    
    treatment_group,
    treatment_sample_size,
    ROUND(treatment_conversion_rate * 100, 2) as treatment_conversion_rate_percent,
    
    ROUND(absolute_effect * 100, 2) as absolute_lift_percent,
    relative_effect_percent as relative_lift_percent,
    
    ROUND(z_score, 3) as z_score,
    -- Statistical significance interpretation
    CASE 
        WHEN ABS(z_score) >= 2.58 THEN 'Highly Significant (p < 0.01)'
        WHEN ABS(z_score) >= 1.96 THEN 'Significant (p < 0.05)'
        WHEN ABS(z_score) >= 1.65 THEN 'Marginally Significant (p < 0.10)'
        ELSE 'Not Significant (p >= 0.10)'
    END as significance_level,
    
    -- Business recommendation
    CASE 
        WHEN ABS(z_score) >= 1.96 AND relative_effect_percent > 0 THEN 'IMPLEMENT TREATMENT'
        WHEN ABS(z_score) >= 1.96 AND relative_effect_percent < 0 THEN 'KEEP CONTROL'
        ELSE 'CONTINUE TESTING'
    END as business_recommendation
FROM statistical_comparison;

-- BUSINESS INTERPRETATION:
-- - Z-score > 1.96 indicates statistical significance at 95% confidence
-- - Relative lift shows business impact magnitude
-- - Combine statistical significance with business significance for decisions

---------------------------------------------------------------------------------------------------
-- SECTION 3: STATISTICAL POWER AND SAMPLE SIZE ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: Planning A/B test sample size requirements
-- Goal: Determine how many users needed to detect meaningful differences
-- Application: Test planning and resource allocation

-- Sample Size Estimation for A/B Tests
WITH test_parameters AS (
    SELECT 
        0.10 as baseline_conversion_rate,  -- Current conversion rate (10%)
        0.02 as minimum_detectable_effect, -- Minimum improvement we care about (2 percentage points)
        0.05 as alpha,                     -- Type I error rate (5%)
        0.20 as beta,                      -- Type II error rate (20%, so 80% power)
        1.96 as z_alpha,                   -- Critical value for alpha = 0.05
        0.84 as z_beta                     -- Critical value for beta = 0.20
    FROM (SELECT 1) dummy
),

sample_size_calculation AS (
    SELECT 
        tp.*,
        -- Cohen's formula for two-proportion test
        POWER(tp.z_alpha + tp.z_beta, 2) * 
        (tp.baseline_conversion_rate * (1 - tp.baseline_conversion_rate) + 
         (tp.baseline_conversion_rate + tp.minimum_detectable_effect) * 
         (1 - tp.baseline_conversion_rate - tp.minimum_detectable_effect)) /
        POWER(tp.minimum_detectable_effect, 2) as required_sample_size_per_group
    FROM test_parameters tp
),

power_analysis AS (
    SELECT 
        *,
        required_sample_size_per_group * 2 as total_sample_size_needed,
        -- Time estimation based on traffic
        CASE 
            WHEN required_sample_size_per_group * 2 <= 1000 THEN '1-2 weeks'
            WHEN required_sample_size_per_group * 2 <= 5000 THEN '2-4 weeks'
            WHEN required_sample_size_per_group * 2 <= 10000 THEN '1-2 months'
            ELSE '2+ months'
        END as estimated_test_duration
    FROM sample_size_calculation
)

SELECT 
    ROUND(baseline_conversion_rate * 100, 1) as current_conversion_rate_percent,
    ROUND(minimum_detectable_effect * 100, 1) as minimum_lift_percent,
    ROUND((1 - beta) * 100, 0) as statistical_power_percent,
    ROUND(alpha * 100, 0) as significance_level_percent,
    CEIL(required_sample_size_per_group) as users_per_group,
    CEIL(total_sample_size_needed) as total_users_needed,
    estimated_test_duration,
    -- Business planning insights
    CASE 
        WHEN total_sample_size_needed > 50000 THEN 'Consider larger effect size or longer test'
        WHEN total_sample_size_needed < 1000 THEN 'Quick test - can run multiple iterations'
        ELSE 'Reasonable test size for most businesses'
    END as planning_recommendation
FROM power_analysis;

-- PLANNING INSIGHTS:
-- - Higher baseline rates require smaller samples
-- - Smaller effect sizes require larger samples
-- - Balance statistical rigor with business timeline constraints

---------------------------------------------------------------------------------------------------
-- SECTION 4: MULTI-VARIANT TESTING (MVT)
---------------------------------------------------------------------------------------------------

-- Business Scenario: Testing multiple variations simultaneously
-- Goal: Compare multiple treatments against control efficiently
-- Challenge: Control for multiple comparisons problem

-- Multi-Variant Test Analysis
WITH mvt_results AS (
    SELECT 
        test_variant,
        COUNT(*) as sample_size,
        SUM(CASE WHEN converted THEN 1 ELSE 0 END) as conversions,
        AVG(CASE WHEN converted THEN 1.0 ELSE 0.0 END) as conversion_rate,
        STDDEV(CASE WHEN converted THEN 1.0 ELSE 0.0 END) as conversion_stddev,
        SUM(conversion_value) as total_revenue,
        AVG(conversion_value) as avg_revenue_per_user
    FROM ab_test_data
    WHERE test_group IN ('control', 'variant_a', 'variant_b', 'variant_c')
    GROUP BY test_variant
),

control_baseline AS (
    SELECT conversion_rate as control_rate, sample_size as control_sample
    FROM mvt_results 
    WHERE test_variant = 'control'
),

variant_comparisons AS (
    SELECT 
        mvt.test_variant,
        mvt.sample_size,
        mvt.conversion_rate,
        mvt.total_revenue,
        cb.control_rate,
        
        -- Effect size vs control
        (mvt.conversion_rate - cb.control_rate) as absolute_effect,
        ROUND((mvt.conversion_rate - cb.control_rate) * 100.0 / cb.control_rate, 2) as relative_effect_percent,
        
        -- Z-test vs control
        (mvt.conversion_rate - cb.control_rate) / 
        SQRT(
            (cb.control_rate * (1 - cb.control_rate) / cb.control_sample) +
            (mvt.conversion_rate * (1 - mvt.conversion_rate) / mvt.sample_size)
        ) as z_score_vs_control,
        
        -- Bonferroni correction for multiple comparisons
        0.05 / 3 as bonferroni_alpha  -- 3 comparisons, so alpha = 0.05/3
    FROM mvt_results mvt
    CROSS JOIN control_baseline cb
    WHERE mvt.test_variant != 'control'
)

SELECT 
    test_variant,
    sample_size,
    ROUND(conversion_rate * 100, 2) as conversion_rate_percent,
    ROUND(relative_effect_percent, 2) as lift_vs_control_percent,
    ROUND(z_score_vs_control, 3) as z_score,
    
    -- Significance with Bonferroni correction
    CASE 
        WHEN ABS(z_score_vs_control) >= 2.81 THEN 'Significant (Bonferroni corrected)'  -- ~0.017 for two-tailed
        WHEN ABS(z_score_vs_control) >= 1.96 THEN 'Significant (uncorrected, may be false positive)'
        ELSE 'Not Significant'
    END as significance_status,
    
    -- Business ranking
    RANK() OVER (ORDER BY conversion_rate DESC) as performance_rank,
    
    -- Revenue impact
    ROUND(total_revenue, 0) as total_revenue,
    
    -- Business recommendation  
    CASE 
        WHEN ABS(z_score_vs_control) >= 2.81 AND relative_effect_percent > 0 THEN 'WINNER'
        WHEN ABS(z_score_vs_control) >= 2.81 AND relative_effect_percent < 0 THEN 'LOSER'
        ELSE 'INCONCLUSIVE'
    END as test_result
FROM variant_comparisons
ORDER BY conversion_rate DESC;

-- MVT INSIGHTS:
-- - Bonferroni correction prevents false positives from multiple testing
-- - Rank variants by both statistical significance and business impact
-- - Consider revenue impact alongside conversion rate improvements

---------------------------------------------------------------------------------------------------
-- SECTION 5: SEQUENTIAL TESTING AND EARLY STOPPING
---------------------------------------------------------------------------------------------------

-- Business Scenario: Monitor test results continuously for early wins
-- Goal: Stop tests early when results are conclusive
-- Benefit: Faster decision making and resource optimization

-- Sequential Test Monitoring
WITH daily_test_results AS (
    SELECT 
        experiment_start_date,
        test_group,
        COUNT(*) as daily_users,
        SUM(CASE WHEN converted THEN 1 ELSE 0 END) as daily_conversions,
        SUM(COUNT(*)) OVER (
            PARTITION BY test_group 
            ORDER BY experiment_start_date
        ) as cumulative_users,
        SUM(SUM(CASE WHEN converted THEN 1 ELSE 0 END)) OVER (
            PARTITION BY test_group 
            ORDER BY experiment_start_date
        ) as cumulative_conversions
    FROM ab_test_data
    GROUP BY experiment_start_date, test_group
),

sequential_analysis AS (
    SELECT 
        dtr.experiment_start_date,
        dtr.test_group,
        dtr.cumulative_users,
        dtr.cumulative_conversions,
        dtr.cumulative_conversions::DECIMAL / dtr.cumulative_users as cumulative_conversion_rate,
        
        -- Calculate running z-score
        LAG(dtr.cumulative_conversions::DECIMAL / dtr.cumulative_users) OVER (
            PARTITION BY dtr.experiment_start_date 
            ORDER BY dtr.test_group
        ) as other_group_rate,
        
        LAG(dtr.cumulative_users) OVER (
            PARTITION BY dtr.experiment_start_date 
            ORDER BY dtr.test_group
        ) as other_group_users
    FROM daily_test_results dtr
),

stopping_analysis AS (
    SELECT 
        experiment_start_date,
        MAX(CASE WHEN test_group = 'control' THEN cumulative_conversion_rate END) as control_rate,
        MAX(CASE WHEN test_group = 'treatment' THEN cumulative_conversion_rate END) as treatment_rate,
        MAX(CASE WHEN test_group = 'control' THEN cumulative_users END) as control_users,
        MAX(CASE WHEN test_group = 'treatment' THEN cumulative_users END) as treatment_users,
        
        -- Sequential z-score calculation
        (MAX(CASE WHEN test_group = 'treatment' THEN cumulative_conversion_rate END) -
         MAX(CASE WHEN test_group = 'control' THEN cumulative_conversion_rate END)) /
        SQRT(
            (MAX(CASE WHEN test_group = 'control' THEN cumulative_conversion_rate END) * 
             (1 - MAX(CASE WHEN test_group = 'control' THEN cumulative_conversion_rate END)) / 
             MAX(CASE WHEN test_group = 'control' THEN cumulative_users END)) +
            (MAX(CASE WHEN test_group = 'treatment' THEN cumulative_conversion_rate END) * 
             (1 - MAX(CASE WHEN test_group = 'treatment' THEN cumulative_conversion_rate END)) / 
             MAX(CASE WHEN test_group = 'treatment' THEN cumulative_users END))
        ) as sequential_z_score,
        
        -- O'Brien-Fleming boundary adjustment for sequential testing
        2.96 / SQRT(ROW_NUMBER() OVER (ORDER BY experiment_start_date)) as stopping_boundary
    FROM sequential_analysis
    WHERE other_group_rate IS NOT NULL
    GROUP BY experiment_start_date
)

SELECT 
    experiment_start_date,
    control_users + treatment_users as total_sample_size,
    ROUND(control_rate * 100, 2) as control_rate_percent,
    ROUND(treatment_rate * 100, 2) as treatment_rate_percent,
    ROUND((treatment_rate - control_rate) * 100, 2) as absolute_lift_percent,
    ROUND(sequential_z_score, 3) as sequential_z_score,
    ROUND(stopping_boundary, 3) as stopping_boundary,
    
    -- Early stopping decision
    CASE 
        WHEN ABS(sequential_z_score) >= stopping_boundary THEN 'STOP TEST - SIGNIFICANT RESULT'
        WHEN control_users + treatment_users >= 10000 THEN 'STOP TEST - SUFFICIENT SAMPLE'
        ELSE 'CONTINUE TESTING'
    END as stopping_decision,
    
    -- Confidence in result
    CASE 
        WHEN ABS(sequential_z_score) >= stopping_boundary THEN 'HIGH CONFIDENCE'
        WHEN ABS(sequential_z_score) >= 1.96 THEN 'MODERATE CONFIDENCE'
        ELSE 'LOW CONFIDENCE'
    END as confidence_level
FROM stopping_analysis
ORDER BY experiment_start_date DESC
LIMIT 7;  -- Last 7 days

-- SEQUENTIAL TESTING BENEFITS:
-- - Stop tests early when results are conclusive
-- - Reduce opportunity cost of continuing ineffective tests
-- - Maintain statistical rigor with proper boundary adjustments
-- - Optimize resource allocation across multiple experiments

---------------------------------------------------------------------------------------------------
-- SECTION 6: BUSINESS METRIC VALIDATION
---------------------------------------------------------------------------------------------------

-- Business Scenario: Validate business KPI improvements beyond primary metrics
-- Goal: Ensure improvements don't negatively impact other important metrics
-- Application: Holistic business impact assessment

-- Comprehensive Business Metrics Validation
WITH business_metrics AS (
    SELECT 
        test_group,
        -- Primary metrics
        COUNT(*) as total_users,
        AVG(CASE WHEN converted THEN 1.0 ELSE 0.0 END) as conversion_rate,
        
        -- Revenue metrics
        SUM(conversion_value) as total_revenue,
        AVG(conversion_value) as avg_revenue_per_user,
        AVG(CASE WHEN converted THEN conversion_value END) as avg_order_value,
        
        -- Engagement metrics
        AVG(days_to_conversion) as avg_days_to_conversion,
        COUNT(CASE WHEN days_to_conversion <= 1 THEN 1 END)::DECIMAL / COUNT(*) as same_day_conversion_rate,
        
        -- Quality metrics (assuming additional data available)
        -- AVG(customer_satisfaction_score) as avg_satisfaction,
        -- AVG(support_tickets_created) as avg_support_tickets,
        
        -- Calculate confidence intervals for key metrics
        conversion_rate - 1.96 * SQRT(conversion_rate * (1 - conversion_rate) / COUNT(*)) as conversion_rate_ci_lower,
        conversion_rate + 1.96 * SQRT(conversion_rate * (1 - conversion_rate) / COUNT(*)) as conversion_rate_ci_upper
    FROM ab_test_data
    GROUP BY test_group
),

metric_comparisons AS (
    SELECT 
        c.test_group as control_group,
        t.test_group as treatment_group,
        
        -- Conversion rate comparison
        ROUND((t.conversion_rate - c.conversion_rate) * 100, 2) as conversion_lift_percent,
        CASE 
            WHEN t.conversion_rate_ci_lower > c.conversion_rate_ci_upper THEN 'SIGNIFICANT IMPROVEMENT'
            WHEN t.conversion_rate_ci_upper < c.conversion_rate_ci_lower THEN 'SIGNIFICANT DECLINE'
            ELSE 'NO SIGNIFICANT DIFFERENCE'
        END as conversion_significance,
        
        -- Revenue comparison
        ROUND((t.avg_revenue_per_user - c.avg_revenue_per_user) * 100.0 / c.avg_revenue_per_user, 2) as revenue_per_user_change_percent,
        ROUND((t.avg_order_value - c.avg_order_value) * 100.0 / c.avg_order_value, 2) as avg_order_value_change_percent,
        
        -- Speed to conversion
        ROUND(t.avg_days_to_conversion - c.avg_days_to_conversion, 1) as days_to_conversion_change,
        ROUND((t.same_day_conversion_rate - c.same_day_conversion_rate) * 100, 2) as same_day_conversion_change_percent,
        
        -- Overall business health score
        CASE 
            WHEN (t.conversion_rate > c.conversion_rate AND 
                  t.avg_revenue_per_user >= c.avg_revenue_per_user * 0.95 AND
                  t.avg_days_to_conversion <= c.avg_days_to_conversion * 1.1) THEN 'HEALTHY IMPROVEMENT'
            WHEN (t.conversion_rate > c.conversion_rate BUT 
                  t.avg_revenue_per_user < c.avg_revenue_per_user * 0.9) THEN 'CONVERSION UP, REVENUE CONCERN'
            WHEN (t.avg_revenue_per_user > c.avg_revenue_per_user BUT 
                  t.conversion_rate < c.conversion_rate * 0.95) THEN 'REVENUE UP, CONVERSION CONCERN'
            ELSE 'MIXED RESULTS'
        END as overall_business_impact
    FROM business_metrics c
    CROSS JOIN business_metrics t
    WHERE c.test_group = 'control' AND t.test_group = 'treatment'
)

SELECT 
    control_group,
    treatment_group,
    conversion_lift_percent,
    conversion_significance,
    revenue_per_user_change_percent,
    avg_order_value_change_percent,
    days_to_conversion_change,
    same_day_conversion_change_percent,
    overall_business_impact,
    
    -- Final recommendation
    CASE 
        WHEN overall_business_impact = 'HEALTHY IMPROVEMENT' AND conversion_significance = 'SIGNIFICANT IMPROVEMENT' 
            THEN 'STRONG RECOMMENDATION: IMPLEMENT'
        WHEN overall_business_impact IN ('CONVERSION UP, REVENUE CONCERN', 'REVENUE UP, CONVERSION CONCERN') 
            THEN 'INVESTIGATE TRADE-OFFS BEFORE DECIDING'
        WHEN conversion_significance = 'NO SIGNIFICANT DIFFERENCE' 
            THEN 'NO CLEAR WINNER: CONTINUE TESTING OR TRY NEW APPROACH'
        ELSE 'NOT RECOMMENDED: STICK WITH CONTROL'
    END as final_recommendation
FROM metric_comparisons;

---------------------------------------------------------------------------------------------------
-- SECTION 7: AUTOMATED TEST MONITORING AND ALERTING
---------------------------------------------------------------------------------------------------

-- Business Scenario: Operations team needs automated test health monitoring
-- Goal: Detect test issues and anomalies automatically
-- Application: Ensure test validity and catch problems early

-- Automated Test Health Monitoring
WITH test_health_metrics AS (
    SELECT 
        experiment_start_date,
        test_group,
        COUNT(*) as daily_sample_size,
        AVG(CASE WHEN converted THEN 1.0 ELSE 0.0 END) as daily_conversion_rate,
        
        -- Calculate expected metrics based on historical data
        0.10 as expected_conversion_rate,  -- Based on historical average
        100 as expected_daily_sample_size, -- Based on traffic estimates
        
        -- Deviation calculations
        ABS(AVG(CASE WHEN converted THEN 1.0 ELSE 0.0 END) - 0.10) / 0.10 as conversion_rate_deviation,
        ABS(COUNT(*) - 100.0) / 100.0 as sample_size_deviation
    FROM ab_test_data
    WHERE experiment_start_date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY experiment_start_date, test_group
),

test_alerts AS (
    SELECT 
        experiment_start_date,
        test_group,
        daily_sample_size,
        daily_conversion_rate,
        
        -- Alert conditions
        CASE 
            WHEN sample_size_deviation > 0.5 THEN 'CRITICAL: Sample size 50%+ off target'
            WHEN sample_size_deviation > 0.3 THEN 'WARNING: Sample size 30%+ off target'
            ELSE 'OK'
        END as sample_size_alert,
        
        CASE 
            WHEN conversion_rate_deviation > 0.8 THEN 'CRITICAL: Conversion rate 80%+ off historical'
            WHEN conversion_rate_deviation > 0.5 THEN 'WARNING: Conversion rate 50%+ off historical'
            ELSE 'OK'
        END as conversion_rate_alert,
        
        -- Test balance check
        COUNT(*) OVER (PARTITION BY experiment_start_date) as groups_running,
        
        -- Statistical power monitoring
        CASE 
            WHEN SUM(daily_sample_size) OVER (PARTITION BY test_group ORDER BY experiment_start_date) < 500 
                THEN 'INSUFFICIENT SAMPLE FOR MEANINGFUL RESULTS'
            ELSE 'ADEQUATE SAMPLE SIZE'
        END as power_status
    FROM test_health_metrics
),

summary_alerts AS (
    SELECT 
        experiment_start_date,
        COUNT(*) as total_alerts,
        COUNT(CASE WHEN sample_size_alert LIKE 'CRITICAL%' OR conversion_rate_alert LIKE 'CRITICAL%' THEN 1 END) as critical_alerts,
        COUNT(CASE WHEN sample_size_alert LIKE 'WARNING%' OR conversion_rate_alert LIKE 'WARNING%' THEN 1 END) as warning_alerts,
        
        -- Overall test health
        CASE 
            WHEN COUNT(CASE WHEN sample_size_alert LIKE 'CRITICAL%' OR conversion_rate_alert LIKE 'CRITICAL%' THEN 1 END) > 0 
                THEN 'UNHEALTHY - IMMEDIATE ATTENTION REQUIRED'
            WHEN COUNT(CASE WHEN sample_size_alert LIKE 'WARNING%' OR conversion_rate_alert LIKE 'WARNING%' THEN 1 END) > 0 
                THEN 'CAUTION - MONITOR CLOSELY'
            ELSE 'HEALTHY'
        END as overall_test_health
    FROM test_alerts
    GROUP BY experiment_start_date
)

SELECT 
    experiment_start_date,
    overall_test_health,
    critical_alerts,
    warning_alerts,
    total_alerts,
    
    -- Actionable recommendations
    CASE 
        WHEN overall_test_health = 'UNHEALTHY - IMMEDIATE ATTENTION REQUIRED' 
            THEN 'PAUSE TEST - INVESTIGATE DATA QUALITY ISSUES'
        WHEN overall_test_health = 'CAUTION - MONITOR CLOSELY' 
            THEN 'CONTINUE WITH INCREASED MONITORING'
        ELSE 'CONTINUE NORMAL OPERATIONS'
    END as recommended_action
FROM summary_alerts
ORDER BY experiment_start_date DESC;

---------------------------------------------------------------------------------------------------
-- KEY BUSINESS APPLICATIONS AND INSIGHTS
---------------------------------------------------------------------------------------------------

/*
PRODUCT TEAMS:
- Test feature changes with statistical rigor
- Measure user experience improvements objectively  
- Validate product-market fit hypotheses
- Optimize conversion funnels systematically

MARKETING TEAMS:
- Test campaign variations for maximum ROI
- Validate messaging and creative effectiveness
- Optimize ad spend allocation based on proven performance
- Measure brand and engagement impact

E-COMMERCE TEAMS:
- Test pricing strategies and promotional offers
- Optimize checkout and purchase flows
- Validate merchandising and recommendation strategies
- Measure revenue impact of site changes

DATA SCIENCE TEAMS:
- Provide statistical foundation for business decisions
- Design statistically valid experiments
- Monitor test health and validity automatically
- Build experimentation platforms and frameworks

EXECUTIVE LEADERSHIP:
- Make confident decisions based on statistical evidence
- Understand business impact magnitude and significance
- Optimize resource allocation toward proven improvements
- Build data-driven culture throughout organization

NEXT STEPS:
1. Implement basic A/B testing framework for key business metrics
2. Set up automated monitoring and alerting for test health
3. Train teams on statistical significance interpretation
4. Build experimentation calendar and prioritization framework
5. Integrate statistical testing into product development cycle

ADVANCED TECHNIQUES TO EXPLORE:
- Bayesian A/B testing for faster decision making
- Multi-armed bandit optimization
- Causal inference and treatment effect estimation
- Machine learning for personalized experimentation
*/
