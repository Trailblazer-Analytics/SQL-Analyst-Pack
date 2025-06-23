# Exercise 5: Advanced Analytics and Statistical Modeling

## Business Context

You're a lead data scientist at **InsightCorp**, a data consulting company. Your clients need sophisticated statistical analysis and predictive modeling capabilities directly in SQL for real-time decision making. You'll build advanced analytics solutions that traditionally require specialized tools like R or Python, but implemented efficiently in SQL for production environments.

## Learning Objectives

By completing this exercise, you will:

- Master statistical functions and mathematical operations in SQL
- Build predictive models using regression techniques
- Implement time series analysis and forecasting
- Create advanced cohort and survival analysis
- Design A/B testing frameworks and statistical significance testing

## Database Schema

You'll be working with these analytical tables:

```sql
-- customers table
customers (
    customer_id BIGINT PRIMARY KEY,
    signup_date DATE,
    first_purchase_date DATE,
    customer_segment VARCHAR(20),
    geographic_region VARCHAR(50),
    acquisition_channel VARCHAR(30),
    is_churned BOOLEAN DEFAULT FALSE,
    churn_date DATE,
    lifetime_value DECIMAL(15,2)
)

-- transactions table
transactions (
    transaction_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    transaction_date DATE,
    transaction_amount DECIMAL(15,2),
    product_category VARCHAR(50),
    payment_method VARCHAR(30),
    discount_amount DECIMAL(15,2),
    is_refund BOOLEAN DEFAULT FALSE
)

-- experiments table (A/B testing)
experiments (
    experiment_id INTEGER PRIMARY KEY,
    experiment_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    control_group_size INTEGER,
    treatment_group_size INTEGER,
    hypothesis TEXT,
    success_metric VARCHAR(50)
)

-- experiment_participants table
experiment_participants (
    participant_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    experiment_id INTEGER,
    group_assignment VARCHAR(10), -- 'control' or 'treatment'
    assigned_date DATE,
    conversion_event BOOLEAN DEFAULT FALSE,
    conversion_date DATE,
    conversion_value DECIMAL(15,2)
)

-- web_analytics table
web_analytics (
    session_id VARCHAR(100) PRIMARY KEY,
    customer_id BIGINT,
    session_start TIMESTAMP,
    session_end TIMESTAMP,
    page_views INTEGER,
    bounce_rate DECIMAL(5,4),
    conversion_flag BOOLEAN,
    traffic_source VARCHAR(50),
    device_type VARCHAR(20)
)
```

## Advanced Analytics Tasks

### Task 1: Customer Lifetime Value Prediction

**Business Question**: "Can we predict customer lifetime value based on early behavioral indicators?"

Build a regression model to predict CLV using:

- Days to first purchase
- Average transaction amount in first 30 days
- Number of transactions in first 30 days
- Acquisition channel
- Geographic region

Requirements:

- Split data into training and testing sets
- Calculate model performance metrics (R², RMSE, MAE)
- Identify most important predictive features
- Generate predictions for new customers

### Task 2: Time Series Forecasting

**Business Question**: "What will our monthly revenue be for the next 6 months?"

Create forecasting models using:

- Linear regression with time trends
- Seasonal decomposition
- Moving averages with seasonality adjustment
- Exponential smoothing approximation

Requirements:

- Handle seasonal patterns and trends
- Calculate confidence intervals
- Validate predictions against holdout data
- Account for business cycles and external factors

### Task 3: Cohort Analysis and Survival Modeling

**Business Question**: "How do different customer acquisition cohorts behave over time, and what's the probability of churn?"

Implement comprehensive cohort analysis:

- Monthly cohort retention curves
- Revenue cohorts with lifetime value progression
- Survival analysis with hazard functions
- Churn probability modeling

Requirements:

- Calculate time-to-event metrics
- Build Kaplan-Meier survival curves
- Identify factors that influence retention
- Create early warning systems for churn risk

### Task 4: A/B Testing and Statistical Significance

**Business Question**: "How do we rigorously test product changes and measure their impact?"

Build a complete A/B testing framework:

- Statistical power calculations
- Sample size determination
- Significance testing (t-tests, chi-square)
- Effect size measurements
- Multiple testing corrections

Requirements:

- Handle different types of metrics (conversion rates, revenue, engagement)
- Account for selection bias and confounding variables
- Calculate confidence intervals and p-values
- Implement Bayesian A/B testing approaches

## Advanced Statistical Functions

### Custom Statistical Functions

```sql
-- Function to calculate correlation coefficient
CREATE OR REPLACE FUNCTION correlation(x NUMERIC[], y NUMERIC[])
RETURNS NUMERIC AS $$
DECLARE
    n INTEGER := array_length(x, 1);
    sum_x NUMERIC := (SELECT SUM(val) FROM unnest(x) val);
    sum_y NUMERIC := (SELECT SUM(val) FROM unnest(y) val);
    sum_xy NUMERIC := (SELECT SUM(x_val * y_val) FROM unnest(x, y) AS t(x_val, y_val));
    sum_x2 NUMERIC := (SELECT SUM(val * val) FROM unnest(x) val);
    sum_y2 NUMERIC := (SELECT SUM(val * val) FROM unnest(y) val);
    numerator NUMERIC;
    denominator NUMERIC;
BEGIN
    numerator := n * sum_xy - sum_x * sum_y;
    denominator := sqrt((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y));
    
    IF denominator = 0 THEN
        RETURN NULL;
    ELSE
        RETURN numerator / denominator;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate linear regression coefficients
CREATE OR REPLACE FUNCTION linear_regression_coef(x NUMERIC[], y NUMERIC[])
RETURNS TABLE(slope NUMERIC, intercept NUMERIC, r_squared NUMERIC) AS $$
DECLARE
    n INTEGER := array_length(x, 1);
    sum_x NUMERIC := (SELECT SUM(val) FROM unnest(x) val);
    sum_y NUMERIC := (SELECT SUM(val) FROM unnest(y) val);
    sum_xy NUMERIC := (SELECT SUM(x_val * y_val) FROM unnest(x, y) AS t(x_val, y_val));
    sum_x2 NUMERIC := (SELECT SUM(val * val) FROM unnest(x) val);
    sum_y2 NUMERIC := (SELECT SUM(val * val) FROM unnest(y) val);
    mean_x NUMERIC := sum_x / n;
    mean_y NUMERIC := sum_y / n;
    slope_val NUMERIC;
    intercept_val NUMERIC;
    ss_res NUMERIC;
    ss_tot NUMERIC;
    r_squared_val NUMERIC;
BEGIN
    slope_val := (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x);
    intercept_val := mean_y - slope_val * mean_x;
    
    -- Calculate R-squared
    ss_res := (SELECT SUM(power(y_val - (slope_val * x_val + intercept_val), 2)) 
               FROM unnest(x, y) AS t(x_val, y_val));
    ss_tot := (SELECT SUM(power(y_val - mean_y, 2)) FROM unnest(y) AS t(y_val));
    
    r_squared_val := 1 - (ss_res / NULLIF(ss_tot, 0));
    
    RETURN QUERY SELECT slope_val, intercept_val, r_squared_val;
END;
$$ LANGUAGE plpgsql;
```

## Solutions

### Task 1 Solution: Customer Lifetime Value Prediction

```sql
-- CLV Prediction Model with Feature Engineering
WITH customer_features AS (
    SELECT 
        c.customer_id,
        c.lifetime_value as actual_clv,
        c.acquisition_channel,
        c.geographic_region,
        c.customer_segment,
        -- Early behavioral features (first 30 days)
        EXTRACT(days FROM c.first_purchase_date - c.signup_date) as days_to_first_purchase,
        COALESCE(early_behavior.transaction_count_30d, 0) as transactions_30d,
        COALESCE(early_behavior.avg_transaction_amount_30d, 0) as avg_amount_30d,
        COALESCE(early_behavior.total_spent_30d, 0) as total_spent_30d,
        COALESCE(early_behavior.unique_categories_30d, 0) as categories_30d,
        COALESCE(early_behavior.refund_rate_30d, 0) as refund_rate_30d,
        -- Additional features
        CASE c.acquisition_channel 
            WHEN 'organic' THEN 1 WHEN 'social' THEN 2 WHEN 'paid' THEN 3 
            WHEN 'email' THEN 4 ELSE 0 END as channel_encoded,
        CASE c.geographic_region 
            WHEN 'North America' THEN 1 WHEN 'Europe' THEN 2 WHEN 'Asia' THEN 3 
            ELSE 0 END as region_encoded
    FROM customers c
    LEFT JOIN (
        SELECT 
            customer_id,
            COUNT(*) as transaction_count_30d,
            AVG(transaction_amount) as avg_transaction_amount_30d,
            SUM(transaction_amount) as total_spent_30d,
            COUNT(DISTINCT product_category) as unique_categories_30d,
            SUM(CASE WHEN is_refund THEN 1 ELSE 0 END)::float / COUNT(*) as refund_rate_30d
        FROM transactions t
        JOIN customers c ON t.customer_id = c.customer_id
        WHERE t.transaction_date BETWEEN c.signup_date AND c.signup_date + INTERVAL '30 days'
        GROUP BY customer_id
    ) early_behavior ON c.customer_id = early_behavior.customer_id
    WHERE c.lifetime_value > 0 
        AND c.signup_date <= CURRENT_DATE - INTERVAL '6 months' -- Mature customers only
),
data_split AS (
    SELECT 
        *,
        -- Random split: 70% training, 30% testing
        CASE WHEN MOD(customer_id, 10) < 7 THEN 'training' ELSE 'testing' END as dataset
    FROM customer_features
),
feature_stats AS (
    SELECT 
        AVG(days_to_first_purchase) as avg_days_to_purchase,
        STDDEV(days_to_first_purchase) as std_days_to_purchase,
        AVG(transactions_30d) as avg_transactions_30d,
        STDDEV(transactions_30d) as std_transactions_30d,
        AVG(avg_amount_30d) as avg_avg_amount,
        STDDEV(avg_amount_30d) as std_avg_amount,
        AVG(actual_clv) as avg_clv,
        STDDEV(actual_clv) as std_clv
    FROM data_split
    WHERE dataset = 'training'
),
normalized_features AS (
    SELECT 
        ds.*,
        -- Normalize features for regression
        (days_to_first_purchase - fs.avg_days_to_purchase) / NULLIF(fs.std_days_to_purchase, 0) as norm_days_to_purchase,
        (transactions_30d - fs.avg_transactions_30d) / NULLIF(fs.std_transactions_30d, 0) as norm_transactions_30d,
        (avg_amount_30d - fs.avg_avg_amount) / NULLIF(fs.std_avg_amount, 0) as norm_avg_amount,
        channel_encoded::float / 4.0 as norm_channel,
        region_encoded::float / 3.0 as norm_region
    FROM data_split ds
    CROSS JOIN feature_stats fs
),
regression_data AS (
    SELECT 
        dataset,
        customer_id,
        actual_clv,
        -- Simple multiple regression prediction
        (
            COALESCE(norm_days_to_purchase, 0) * -150 +
            COALESCE(norm_transactions_30d, 0) * 200 +
            COALESCE(norm_avg_amount, 0) * 180 +
            COALESCE(norm_channel, 0) * 100 +
            COALESCE(norm_region, 0) * 50 +
            500 -- intercept
        ) as predicted_clv
    FROM normalized_features
),
model_evaluation AS (
    SELECT 
        dataset,
        COUNT(*) as sample_size,
        -- Performance metrics
        CORR(actual_clv, predicted_clv) as correlation,
        -- R-squared approximation
        1 - (SUM(POWER(actual_clv - predicted_clv, 2)) / 
             SUM(POWER(actual_clv - AVG(actual_clv) OVER (PARTITION BY dataset), 2))) as r_squared,
        -- Mean Absolute Error
        AVG(ABS(actual_clv - predicted_clv)) as mae,
        -- Root Mean Square Error  
        SQRT(AVG(POWER(actual_clv - predicted_clv, 2))) as rmse,
        -- Mean Absolute Percentage Error
        AVG(ABS((actual_clv - predicted_clv) / NULLIF(actual_clv, 0)) * 100) as mape
    FROM regression_data
    GROUP BY dataset
),
feature_importance AS (
    SELECT 
        'days_to_first_purchase' as feature,
        CORR(norm_days_to_purchase, actual_clv) as correlation_with_clv
    FROM normalized_features
    WHERE dataset = 'training'
    UNION ALL
    SELECT 
        'transactions_30d',
        CORR(norm_transactions_30d, actual_clv)
    FROM normalized_features
    WHERE dataset = 'training'
    UNION ALL
    SELECT 
        'avg_amount_30d',
        CORR(norm_avg_amount, actual_clv)
    FROM normalized_features
    WHERE dataset = 'training'
)
-- Results summary
SELECT 
    'Model Performance' as metric_type,
    me.dataset,
    me.sample_size,
    ROUND(me.correlation, 3) as correlation,
    ROUND(me.r_squared, 3) as r_squared,
    ROUND(me.mae, 2) as mae,
    ROUND(me.rmse, 2) as rmse,
    ROUND(me.mape, 2) as mape_percent
FROM model_evaluation me

UNION ALL

SELECT 
    'Feature Importance' as metric_type,
    fi.feature as dataset,
    NULL as sample_size,
    ROUND(fi.correlation_with_clv, 3) as correlation,
    NULL as r_squared,
    NULL as mae,
    NULL as rmse,
    NULL as mape_percent
FROM feature_importance fi
ORDER BY metric_type, dataset;

-- Business Insight: Early transaction behavior is highly predictive of CLV
-- Use this model to identify high-value customers early and tailor experiences
```

### Task 2 Solution: Time Series Forecasting

```sql
-- Monthly Revenue Forecasting with Seasonality
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) as month,
        SUM(transaction_amount - COALESCE(discount_amount, 0)) as revenue,
        COUNT(DISTINCT customer_id) as active_customers,
        COUNT(*) as transaction_count
    FROM transactions
    WHERE transaction_date >= '2020-01-01'
        AND is_refund = FALSE
    GROUP BY DATE_TRUNC('month', transaction_date)
),
time_series_features AS (
    SELECT 
        month,
        revenue,
        ROW_NUMBER() OVER (ORDER BY month) as time_index,
        EXTRACT(month FROM month) as month_of_year,
        EXTRACT(quarter FROM month) as quarter,
        -- Lag features
        LAG(revenue, 1) OVER (ORDER BY month) as revenue_lag1,
        LAG(revenue, 12) OVER (ORDER BY month) as revenue_lag12, -- year-over-year
        -- Moving averages
        AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as ma_3m,
        AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) as ma_6m,
        AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) as ma_12m
    FROM monthly_revenue
),
seasonal_decomposition AS (
    SELECT 
        *,
        -- Calculate seasonal indices
        AVG(revenue) OVER (PARTITION BY month_of_year) as seasonal_avg,
        AVG(revenue) OVER () as overall_avg,
        (AVG(revenue) OVER (PARTITION BY month_of_year) / AVG(revenue) OVER ()) as seasonal_index,
        -- Deseasonalized revenue
        revenue / (AVG(revenue) OVER (PARTITION BY month_of_year) / AVG(revenue) OVER ()) as deseasonalized_revenue
    FROM time_series_features
),
trend_analysis AS (
    SELECT 
        *,
        -- Linear trend calculation
        time_index,
        deseasonalized_revenue,
        -- Calculate trend using linear regression approximation
        AVG(deseasonalized_revenue) OVER () + 
        (CORR(time_index, deseasonalized_revenue) OVER () * 
         STDDEV(deseasonalized_revenue) OVER () / STDDEV(time_index) OVER ()) * 
        (time_index - AVG(time_index) OVER ()) as trend_component,
        -- Residual (noise)
        deseasonalized_revenue - (
            AVG(deseasonalized_revenue) OVER () + 
            (CORR(time_index, deseasonalized_revenue) OVER () * 
             STDDEV(deseasonalized_revenue) OVER () / STDDEV(time_index) OVER ()) * 
            (time_index - AVG(time_index) OVER ())
        ) as residual_component
    FROM seasonal_decomposition
    WHERE time_index > 12 -- Need enough history for seasonality
),
forecast_parameters AS (
    SELECT 
        -- Extract trend slope
        CORR(time_index, deseasonalized_revenue) * 
        STDDEV(deseasonalized_revenue) / STDDEV(time_index) as trend_slope,
        AVG(deseasonalized_revenue) as trend_intercept,
        AVG(time_index) as avg_time_index,
        STDDEV(residual_component) as forecast_error_std
    FROM trend_analysis
),
future_periods AS (
    SELECT 
        month + INTERVAL '1 month' * generate_series(1, 6) as forecast_month,
        (SELECT MAX(time_index) FROM trend_analysis) + generate_series(1, 6) as forecast_time_index
    FROM (SELECT MAX(month) as month FROM monthly_revenue) latest
),
forecasted_revenue AS (
    SELECT 
        fp.forecast_month,
        fp.forecast_time_index,
        EXTRACT(month FROM fp.forecast_month) as forecast_month_of_year,
        -- Base forecast (trend + seasonality)
        (
            params.trend_intercept + 
            params.trend_slope * (fp.forecast_time_index - params.avg_time_index)
        ) * seasonal.seasonal_index as forecast_revenue,
        -- Confidence intervals (±1.96 * standard error for 95% CI)
        (
            params.trend_intercept + 
            params.trend_slope * (fp.forecast_time_index - params.avg_time_index)
        ) * seasonal.seasonal_index - (1.96 * params.forecast_error_std) as forecast_lower_ci,
        (
            params.trend_intercept + 
            params.trend_slope * (fp.forecast_time_index - params.avg_time_index)
        ) * seasonal.seasonal_index + (1.96 * params.forecast_error_std) as forecast_upper_ci
    FROM future_periods fp
    CROSS JOIN forecast_parameters params
    LEFT JOIN (
        SELECT DISTINCT month_of_year, seasonal_index
        FROM seasonal_decomposition
    ) seasonal ON EXTRACT(month FROM fp.forecast_month) = seasonal.month_of_year
)
-- Historical vs Forecast Results
SELECT 
    'Historical' as data_type,
    month::date as period,
    revenue as actual_revenue,
    NULL as forecast_revenue,
    NULL as lower_ci,
    NULL as upper_ci
FROM monthly_revenue
WHERE month >= CURRENT_DATE - INTERVAL '12 months'

UNION ALL

SELECT 
    'Forecast' as data_type,
    forecast_month::date as period,
    NULL as actual_revenue,
    ROUND(forecast_revenue, 2) as forecast_revenue,
    ROUND(forecast_lower_ci, 2) as lower_ci,
    ROUND(forecast_upper_ci, 2) as upper_ci
FROM forecasted_revenue

ORDER BY period;

-- Business Insight: Incorporates seasonality and trends for accurate revenue planning
-- Use confidence intervals for risk assessment and scenario planning
```

### Task 3 Solution: Cohort Analysis and Survival Modeling

```sql
-- Comprehensive Cohort Analysis with Survival Curves
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', signup_date) as cohort_month,
        signup_date,
        CASE WHEN is_churned THEN churn_date ELSE NULL END as churn_date,
        CASE WHEN is_churned THEN EXTRACT(days FROM churn_date - signup_date) ELSE NULL END as days_to_churn,
        lifetime_value
    FROM customers
    WHERE signup_date >= '2022-01-01'
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(*) as cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
monthly_retention AS (
    SELECT 
        cc.cohort_month,
        generate_series(0, 24) as months_since_signup,
        cs.cohort_size
    FROM customer_cohorts cc
    JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
    GROUP BY cc.cohort_month, cs.cohort_size
),
retention_data AS (
    SELECT 
        mr.cohort_month,
        mr.months_since_signup,
        mr.cohort_size,
        COUNT(t.customer_id) as active_customers,
        COUNT(t.customer_id)::float / mr.cohort_size as retention_rate,
        -- Revenue retention
        COALESCE(SUM(t.transaction_amount), 0) as cohort_revenue,
        COALESCE(AVG(t.transaction_amount), 0) as avg_revenue_per_active_customer
    FROM monthly_retention mr
    LEFT JOIN customer_cohorts cc ON mr.cohort_month = cc.cohort_month
    LEFT JOIN transactions t ON cc.customer_id = t.customer_id
        AND t.transaction_date >= cc.signup_date + (mr.months_since_signup * INTERVAL '1 month')
        AND t.transaction_date < cc.signup_date + ((mr.months_since_signup + 1) * INTERVAL '1 month')
        AND t.is_refund = FALSE
    WHERE mr.cohort_month + (mr.months_since_signup * INTERVAL '1 month') <= CURRENT_DATE
    GROUP BY mr.cohort_month, mr.months_since_signup, mr.cohort_size
),
survival_analysis AS (
    SELECT 
        cc.cohort_month,
        days_to_churn,
        COUNT(*) as churned_count,
        -- Kaplan-Meier survival function approximation
        SUM(COUNT(*)) OVER (PARTITION BY cc.cohort_month ORDER BY days_to_churn ROWS UNBOUNDED PRECEDING) as cumulative_churned,
        cs.cohort_size,
        1 - (SUM(COUNT(*)) OVER (PARTITION BY cc.cohort_month ORDER BY days_to_churn ROWS UNBOUNDED PRECEDING)::float / cs.cohort_size) as survival_probability
    FROM customer_cohorts cc
    JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
    WHERE cc.churn_date IS NOT NULL
    GROUP BY cc.cohort_month, days_to_churn, cs.cohort_size
),
hazard_function AS (
    SELECT 
        cohort_month,
        days_to_churn,
        churned_count,
        LAG(survival_probability, 1, 1) OVER (PARTITION BY cohort_month ORDER BY days_to_churn) as prev_survival_prob,
        survival_probability,
        -- Hazard rate (instantaneous risk of churning)
        churned_count::float / 
        (LAG(survival_probability, 1, 1) OVER (PARTITION BY cohort_month ORDER BY days_to_churn) * 
         (SELECT cohort_size FROM cohort_sizes WHERE cohort_month = survival_analysis.cohort_month)
        ) as hazard_rate
    FROM survival_analysis
),
ltv_cohorts AS (
    SELECT 
        cohort_month,
        months_since_signup,
        cohort_size,
        SUM(cohort_revenue) OVER (PARTITION BY cohort_month ORDER BY months_since_signup) as cumulative_revenue,
        SUM(cohort_revenue) OVER (PARTITION BY cohort_month ORDER BY months_since_signup) / cohort_size as revenue_per_customer,
        retention_rate
    FROM retention_data
)
-- Cohort Retention Analysis
SELECT 
    'Retention Analysis' as analysis_type,
    cohort_month::date as cohort,
    months_since_signup as period,
    cohort_size::text as metric1,
    ROUND(retention_rate * 100, 2)::text as metric2,
    ROUND(revenue_per_customer, 2)::text as metric3
FROM retention_data
WHERE cohort_month >= '2023-01-01' AND months_since_signup <= 12

UNION ALL

-- Survival Analysis Summary
SELECT 
    'Survival Analysis' as analysis_type,
    cohort_month::date as cohort,
    FLOOR(days_to_churn / 30) as period, -- Convert to months
    ROUND(AVG(survival_probability) * 100, 2)::text as metric1,
    ROUND(AVG(hazard_rate) * 1000, 4)::text as metric2, -- per 1000 customers
    COUNT(*)::text as metric3
FROM hazard_function
WHERE cohort_month >= '2023-01-01' AND days_to_churn <= 365
GROUP BY cohort_month, FLOOR(days_to_churn / 30)

UNION ALL

-- LTV Progression
SELECT 
    'LTV Progression' as analysis_type,
    cohort_month::date as cohort,
    months_since_signup as period,
    ROUND(cumulative_revenue, 2)::text as metric1,
    ROUND(revenue_per_customer, 2)::text as metric2,
    ROUND(retention_rate * 100, 2)::text as metric3
FROM ltv_cohorts
WHERE cohort_month >= '2023-01-01' AND months_since_signup <= 12

ORDER BY analysis_type, cohort, period;

-- Business Insight: Identifies critical retention periods and high-value cohorts
-- Use survival analysis to predict churn timing and optimize intervention strategies
```

### Task 4 Solution: A/B Testing Framework

```sql
-- Comprehensive A/B Testing Analysis Framework
WITH experiment_summary AS (
    SELECT 
        e.experiment_id,
        e.experiment_name,
        e.start_date,
        e.end_date,
        e.success_metric,
        COUNT(CASE WHEN ep.group_assignment = 'control' THEN ep.participant_id END) as control_size,
        COUNT(CASE WHEN ep.group_assignment = 'treatment' THEN ep.participant_id END) as treatment_size,
        -- Control group metrics
        COUNT(CASE WHEN ep.group_assignment = 'control' AND ep.conversion_event THEN ep.participant_id END) as control_conversions,
        AVG(CASE WHEN ep.group_assignment = 'control' THEN ep.conversion_value END) as control_avg_value,
        STDDEV(CASE WHEN ep.group_assignment = 'control' THEN ep.conversion_value END) as control_std_value,
        -- Treatment group metrics  
        COUNT(CASE WHEN ep.group_assignment = 'treatment' AND ep.conversion_event THEN ep.participant_id END) as treatment_conversions,
        AVG(CASE WHEN ep.group_assignment = 'treatment' THEN ep.conversion_value END) as treatment_avg_value,
        STDDEV(CASE WHEN ep.group_assignment = 'treatment' THEN ep.conversion_value END) as treatment_std_value
    FROM experiments e
    JOIN experiment_participants ep ON e.experiment_id = ep.experiment_id
    WHERE ep.assigned_date BETWEEN e.start_date AND e.end_date
    GROUP BY e.experiment_id, e.experiment_name, e.start_date, e.end_date, e.success_metric
),
statistical_tests AS (
    SELECT 
        *,
        -- Conversion rate calculations
        control_conversions::float / NULLIF(control_size, 0) as control_conversion_rate,
        treatment_conversions::float / NULLIF(treatment_size, 0) as treatment_conversion_rate,
        
        -- Effect size calculations
        (treatment_conversions::float / NULLIF(treatment_size, 0)) - 
        (control_conversions::float / NULLIF(control_size, 0)) as absolute_effect,
        
        ((treatment_conversions::float / NULLIF(treatment_size, 0)) - 
         (control_conversions::float / NULLIF(control_size, 0))) / 
        NULLIF((control_conversions::float / NULLIF(control_size, 0)), 0) as relative_effect,
        
        -- Standard errors for proportion tests
        SQRT(
            ((control_conversions::float / NULLIF(control_size, 0)) * 
             (1 - control_conversions::float / NULLIF(control_size, 0)) / NULLIF(control_size, 0)) +
            ((treatment_conversions::float / NULLIF(treatment_size, 0)) * 
             (1 - treatment_conversions::float / NULLIF(treatment_size, 0)) / NULLIF(treatment_size, 0))
        ) as proportion_se,
        
        -- Standard error for revenue/value tests
        SQRT(
            POWER(COALESCE(control_std_value, 0), 2) / NULLIF(control_size, 0) +
            POWER(COALESCE(treatment_std_value, 0), 2) / NULLIF(treatment_size, 0)
        ) as value_se
    FROM experiment_summary
),
significance_tests AS (
    SELECT 
        *,
        -- Z-score for proportion test
        absolute_effect / NULLIF(proportion_se, 0) as z_score_proportion,
        
        -- Z-score for value test
        (COALESCE(treatment_avg_value, 0) - COALESCE(control_avg_value, 0)) / NULLIF(value_se, 0) as z_score_value,
        
        -- Critical values (two-tailed test, α = 0.05)
        1.96 as critical_value_95,
        2.576 as critical_value_99,
        
        -- Confidence intervals for proportion difference
        absolute_effect - (1.96 * proportion_se) as prop_diff_ci_lower,
        absolute_effect + (1.96 * proportion_se) as prop_diff_ci_upper,
        
        -- Confidence intervals for value difference
        (COALESCE(treatment_avg_value, 0) - COALESCE(control_avg_value, 0)) - (1.96 * value_se) as value_diff_ci_lower,
        (COALESCE(treatment_avg_value, 0) - COALESCE(control_avg_value, 0)) + (1.96 * value_se) as value_diff_ci_upper
    FROM statistical_tests
),
power_analysis AS (
    SELECT 
        *,
        -- Statistical power approximation (simplified)
        CASE 
            WHEN ABS(z_score_proportion) >= critical_value_95 THEN 'Significant at 95%'
            WHEN ABS(z_score_proportion) >= 1.645 THEN 'Significant at 90%'
            ELSE 'Not Significant'
        END as proportion_significance,
        
        CASE 
            WHEN ABS(z_score_value) >= critical_value_95 THEN 'Significant at 95%'
            WHEN ABS(z_score_value) >= 1.645 THEN 'Significant at 90%'
            ELSE 'Not Significant'
        END as value_significance,
        
        -- Sample size recommendation for future tests
        POWER(
            (1.96 + 1.28) / -- Z_α/2 + Z_β for 80% power
            NULLIF(ABS(absolute_effect) / SQRT(
                control_conversion_rate * (1 - control_conversion_rate) * 
                (1/control_size + 1/treatment_size)
            ), 0), 2
        ) * 2 as recommended_sample_size_per_group
    FROM significance_tests
),
bayesian_analysis AS (
    SELECT 
        *,
        -- Bayesian credible intervals (Beta distribution approximation)
        -- Using Jeffrey's prior: Beta(0.5, 0.5)
        (control_conversions + 0.5) / (control_size + 1) as control_posterior_mean,
        (treatment_conversions + 0.5) / (treatment_size + 1) as treatment_posterior_mean,
        
        -- Probability that treatment is better than control (simplified)
        CASE 
            WHEN treatment_conversion_rate > control_conversion_rate AND 
                 ABS(z_score_proportion) >= 1.96 THEN 
                0.95 + (ABS(z_score_proportion) - 1.96) * 0.01 -- Approximate
            WHEN treatment_conversion_rate > control_conversion_rate THEN 
                0.50 + (ABS(z_score_proportion) / 1.96) * 0.45
            ELSE 
                0.50 - (ABS(z_score_proportion) / 1.96) * 0.45
        END as prob_treatment_better
    FROM power_analysis
)
-- Final A/B Testing Results
SELECT 
    experiment_name,
    start_date,
    end_date,
    success_metric,
    
    -- Sample sizes
    control_size,
    treatment_size,
    
    -- Conversion rates
    ROUND(control_conversion_rate * 100, 2) as control_conversion_pct,
    ROUND(treatment_conversion_rate * 100, 2) as treatment_conversion_pct,
    
    -- Effect sizes
    ROUND(absolute_effect * 100, 3) as absolute_effect_pct,
    ROUND(relative_effect * 100, 2) as relative_effect_pct,
    
    -- Statistical significance
    proportion_significance,
    ROUND(z_score_proportion, 3) as z_score,
    
    -- Confidence intervals
    ROUND(prop_diff_ci_lower * 100, 3) as effect_ci_lower_pct,
    ROUND(prop_diff_ci_upper * 100, 3) as effect_ci_upper_pct,
    
    -- Bayesian results
    ROUND(prob_treatment_better * 100, 1) as prob_treatment_better_pct,
    
    -- Recommendations
    CASE 
        WHEN proportion_significance LIKE '%95%' AND relative_effect > 0.05 THEN 'Implement Treatment'
        WHEN proportion_significance LIKE '%95%' AND relative_effect < -0.05 THEN 'Keep Control'
        WHEN proportion_significance = 'Not Significant' THEN 'Continue Testing'
        ELSE 'Inconclusive'
    END as recommendation,
    
    ROUND(recommended_sample_size_per_group) as recommended_future_sample_size
    
FROM bayesian_analysis
ORDER BY experiment_id;

-- Business Insight: Provides rigorous statistical framework for decision-making
-- Includes both frequentist and Bayesian approaches for comprehensive analysis
```

## Advanced Analytics Applications

### Real-time Scoring System

```sql
-- Create real-time customer scoring function
CREATE OR REPLACE FUNCTION calculate_customer_score(
    p_customer_id BIGINT,
    p_score_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    customer_id BIGINT,
    clv_score NUMERIC,
    churn_risk_score NUMERIC,
    engagement_score NUMERIC,
    overall_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH customer_metrics AS (
        SELECT 
            $1 as customer_id,
            -- CLV indicators
            COALESCE(SUM(t.transaction_amount), 0) as total_spent,
            COUNT(t.transaction_id) as transaction_count,
            MAX(t.transaction_date) as last_transaction,
            
            -- Engagement indicators
            COUNT(DISTINCT DATE_TRUNC('month', t.transaction_date)) as active_months,
            COUNT(DISTINCT t.product_category) as category_diversity
        FROM transactions t
        WHERE t.customer_id = $1
            AND t.transaction_date >= $2 - INTERVAL '12 months'
            AND t.is_refund = FALSE
    )
    SELECT 
        cm.customer_id,
        -- CLV Score (0-100)
        LEAST(100, (cm.total_spent / 50)::numeric) as clv_score,
        
        -- Churn Risk Score (0-100, higher = more risk)
        CASE 
            WHEN cm.last_transaction IS NULL THEN 100
            WHEN EXTRACT(days FROM $2 - cm.last_transaction) > 90 THEN 80
            WHEN EXTRACT(days FROM $2 - cm.last_transaction) > 60 THEN 60
            WHEN EXTRACT(days FROM $2 - cm.last_transaction) > 30 THEN 40
            ELSE 20
        END as churn_risk_score,
        
        -- Engagement Score (0-100)
        LEAST(100, (cm.active_months * 8 + cm.category_diversity * 10)::numeric) as engagement_score,
        
        -- Overall Score (weighted average)
        (
            LEAST(100, (cm.total_spent / 50)::numeric) * 0.4 + -- CLV weight
            (100 - CASE 
                WHEN cm.last_transaction IS NULL THEN 100
                WHEN EXTRACT(days FROM $2 - cm.last_transaction) > 90 THEN 80
                WHEN EXTRACT(days FROM $2 - cm.last_transaction) > 60 THEN 60
                WHEN EXTRACT(days FROM $2 - cm.last_transaction) > 30 THEN 40
                ELSE 20
            END) * 0.3 + -- Churn risk weight (inverted)
            LEAST(100, (cm.active_months * 8 + cm.category_diversity * 10)::numeric) * 0.3 -- Engagement weight
        ) as overall_score
    FROM customer_metrics cm;
END;
$$ LANGUAGE plpgsql;
```

## Business Impact and Applications

These advanced analytics capabilities enable:

- **Predictive Customer Management**: Identify high-value customers early and predict churn
- **Revenue Forecasting**: Accurate financial planning with confidence intervals
- **Product Optimization**: Rigorous A/B testing for feature releases
- **Risk Assessment**: Statistical models for credit and business risk evaluation
- **Real-time Personalization**: Dynamic customer scoring for personalized experiences

## Key Learning Outcomes

✅ **Statistical Modeling**: Build regression and forecasting models in SQL  
✅ **Experimental Design**: Implement rigorous A/B testing frameworks  
✅ **Survival Analysis**: Model time-to-event data and customer lifecycles  
✅ **Bayesian Methods**: Apply Bayesian statistics for decision-making  
✅ **Real-time Analytics**: Create production-ready scoring systems

---

**Next Exercise**: `06_data_engineering.md` - ETL processes and data pipeline optimization
