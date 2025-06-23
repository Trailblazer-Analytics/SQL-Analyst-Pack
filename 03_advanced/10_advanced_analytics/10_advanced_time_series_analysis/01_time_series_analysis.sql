/*
Title: Advanced Time Series Analysis with SQL
Author: Alexander Nykolaiszyn
Created: 2023-08-12
Description: Advanced techniques for analyzing time series data including forecasting, anomaly detection, and seasonality analysis
*/

-- ==========================================
-- INTRODUCTION TO TIME SERIES ANALYSIS IN SQL
-- ==========================================
-- Time series analysis is essential for understanding how data changes over time
-- and for making predictions about future values.

-- ==========================================
-- 1. SETTING UP EXAMPLE DATA
-- ==========================================

-- Daily sales table
CREATE TABLE daily_sales (
    date_id DATE PRIMARY KEY,
    sales_amount DECIMAL(12,2) NOT NULL,
    units_sold INT NOT NULL,
    promotion_active BOOLEAN NOT NULL,
    holiday BOOLEAN NOT NULL,
    weekday INT NOT NULL,  -- 0 = Sunday, 1 = Monday, etc.
    month INT NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
);

-- Generate 3 years of sample data
-- This would typically use a stored procedure or external script
-- Below is a simplified example using PostgreSQL's generate_series
-- For MS SQL Server, you would use a recursive CTE or tally table

-- PostgreSQL Example
INSERT INTO daily_sales (
    date_id,
    sales_amount,
    units_sold,
    promotion_active,
    holiday,
    weekday,
    month,
    quarter,
    year
)
SELECT
    date_series::DATE AS date_id,
    -- Base sales amount with trend, seasonality, and noise
    (
        10000 + -- Base level
        (date_series - '2020-01-01'::DATE) * 2 + -- Upward trend
        2000 * SIN((EXTRACT(DOY FROM date_series) / 365) * 2 * PI()) + -- Yearly seasonality
        1000 * SIN((EXTRACT(DOW FROM date_series) / 7) * 2 * PI()) + -- Weekly seasonality
        RANDOM() * 500 -- Random noise
    )::DECIMAL(12,2) AS sales_amount,
    
    -- Units sold (correlated with sales_amount)
    (
        500 +
        (date_series - '2020-01-01'::DATE) / 10 +
        100 * SIN((EXTRACT(DOY FROM date_series) / 365) * 2 * PI()) +
        50 * SIN((EXTRACT(DOW FROM date_series) / 7) * 2 * PI()) +
        RANDOM() * 25
    )::INT AS units_sold,
    
    -- Promotions (more common on weekends and during holidays)
    (RANDOM() < 0.2 OR EXTRACT(DOW FROM date_series) IN (0, 6))::BOOLEAN AS promotion_active,
    
    -- Holidays (simplified - just consider major US holidays)
    (
        (EXTRACT(MONTH FROM date_series) = 1 AND EXTRACT(DAY FROM date_series) = 1) OR -- New Year's
        (EXTRACT(MONTH FROM date_series) = 7 AND EXTRACT(DAY FROM date_series) = 4) OR -- Independence Day
        (EXTRACT(MONTH FROM date_series) = 12 AND EXTRACT(DAY FROM date_series) = 25) OR -- Christmas
        (EXTRACT(MONTH FROM date_series) = 11 AND EXTRACT(DAY FROM date_series) BETWEEN 22 AND 28 AND EXTRACT(DOW FROM date_series) = 4) -- Thanksgiving
    )::BOOLEAN AS holiday,
    
    EXTRACT(DOW FROM date_series)::INT AS weekday,
    EXTRACT(MONTH FROM date_series)::INT AS month,
    EXTRACT(QUARTER FROM date_series)::INT AS quarter,
    EXTRACT(YEAR FROM date_series)::INT AS year
FROM
    generate_series(
        '2020-01-01'::DATE,
        '2022-12-31'::DATE,
        '1 day'::INTERVAL
    ) AS date_series;

-- ==========================================
-- 2. BASIC TIME SERIES EXPLORATION
-- ==========================================

-- Calculate basic metrics
SELECT 
    year,
    quarter,
    SUM(sales_amount) AS total_sales,
    AVG(sales_amount) AS avg_daily_sales,
    STDDEV(sales_amount) AS sales_stddev,
    MIN(sales_amount) AS min_sales,
    MAX(sales_amount) AS max_sales,
    COUNT(*) AS days_count
FROM 
    daily_sales
GROUP BY 
    year, quarter
ORDER BY 
    year, quarter;

-- Day-over-day changes
SELECT 
    date_id,
    sales_amount,
    LAG(sales_amount) OVER (ORDER BY date_id) AS prev_day_sales,
    sales_amount - LAG(sales_amount) OVER (ORDER BY date_id) AS day_over_day_change,
    (sales_amount - LAG(sales_amount) OVER (ORDER BY date_id)) / NULLIF(LAG(sales_amount) OVER (ORDER BY date_id), 0) * 100 AS pct_change
FROM 
    daily_sales
ORDER BY 
    date_id;

-- Week-over-week changes
SELECT 
    date_id,
    sales_amount,
    LAG(sales_amount, 7) OVER (ORDER BY date_id) AS prev_week_sales,
    sales_amount - LAG(sales_amount, 7) OVER (ORDER BY date_id) AS week_over_week_change,
    (sales_amount - LAG(sales_amount, 7) OVER (ORDER BY date_id)) / NULLIF(LAG(sales_amount, 7) OVER (ORDER BY date_id), 0) * 100 AS pct_change
FROM 
    daily_sales
ORDER BY 
    date_id;

-- ==========================================
-- 3. PATTERN DETECTION
-- ==========================================

-- Day of week patterns
SELECT 
    weekday,
    COUNT(*) AS num_days,
    AVG(sales_amount) AS avg_sales,
    STDDEV(sales_amount) AS sales_stddev,
    MIN(sales_amount) AS min_sales,
    MAX(sales_amount) AS max_sales
FROM 
    daily_sales
GROUP BY 
    weekday
ORDER BY 
    weekday;

-- Monthly patterns
SELECT 
    month,
    COUNT(*) AS num_days,
    AVG(sales_amount) AS avg_sales,
    STDDEV(sales_amount) AS sales_stddev,
    MIN(sales_amount) AS min_sales,
    MAX(sales_amount) AS max_sales
FROM 
    daily_sales
GROUP BY 
    month
ORDER BY 
    month;

-- Impact of promotions
SELECT 
    promotion_active,
    COUNT(*) AS num_days,
    AVG(sales_amount) AS avg_sales,
    AVG(units_sold) AS avg_units,
    AVG(sales_amount) / NULLIF(AVG(units_sold), 0) AS avg_price_per_unit
FROM 
    daily_sales
GROUP BY 
    promotion_active;

-- Impact of holidays
SELECT 
    holiday,
    COUNT(*) AS num_days,
    AVG(sales_amount) AS avg_sales,
    STDDEV(sales_amount) AS sales_stddev,
    MIN(sales_amount) AS min_sales,
    MAX(sales_amount) AS max_sales
FROM 
    daily_sales
GROUP BY 
    holiday;

-- ==========================================
-- 4. MOVING AVERAGES AND SMOOTHING
-- ==========================================

-- Simple moving averages
SELECT 
    date_id,
    sales_amount,
    AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7day,
    AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS ma_14day,
    AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS ma_30day
FROM 
    daily_sales
ORDER BY 
    date_id;

-- Weighted moving average (more weight to recent data)
SELECT 
    date_id,
    sales_amount,
    -- PostgreSQL example using window functions and arrays
    SUM(sales_amount * weight) / SUM(weight) AS weighted_ma_7day
FROM (
    SELECT 
        date_id,
        sales_amount,
        ROW_NUMBER() OVER (ORDER BY date_id DESC) AS rn,
        CASE ROW_NUMBER() OVER (ORDER BY date_id DESC)
            WHEN 1 THEN 7
            WHEN 2 THEN 6
            WHEN 3 THEN 5
            WHEN 4 THEN 4
            WHEN 5 THEN 3
            WHEN 6 THEN 2
            WHEN 7 THEN 1
            ELSE 0
        END AS weight
    FROM 
        daily_sales
) t
WHERE 
    rn <= 7
GROUP BY 
    date_id, sales_amount
ORDER BY 
    date_id;

-- Exponential smoothing (PostgreSQL recursive CTE example)
WITH RECURSIVE exp_smooth AS (
    -- Base case: first day
    SELECT 
        date_id,
        sales_amount,
        sales_amount AS smoothed_value,
        1 AS day_rank
    FROM 
        daily_sales
    WHERE 
        date_id = (SELECT MIN(date_id) FROM daily_sales)
    
    UNION ALL
    
    -- Recursive case: apply exponential smoothing formula
    SELECT 
        ds.date_id,
        ds.sales_amount,
        0.3 * ds.sales_amount + 0.7 * es.smoothed_value AS smoothed_value,
        es.day_rank + 1
    FROM 
        daily_sales ds
    JOIN 
        exp_smooth es ON ds.date_id = (es.date_id + INTERVAL '1 day')
)
SELECT 
    date_id,
    sales_amount,
    smoothed_value
FROM 
    exp_smooth
ORDER BY 
    date_id;

-- ==========================================
-- 5. SEASONALITY ANALYSIS
-- ==========================================

-- Calculating seasonality index by month
WITH monthly_sales AS (
    SELECT 
        year,
        month,
        AVG(sales_amount) AS avg_monthly_sales
    FROM 
        daily_sales
    GROUP BY 
        year, month
),
yearly_sales AS (
    SELECT 
        year,
        AVG(avg_monthly_sales) AS avg_yearly_sales
    FROM 
        monthly_sales
    GROUP BY 
        year
)
SELECT 
    ms.year,
    ms.month,
    ms.avg_monthly_sales,
    ys.avg_yearly_sales,
    ms.avg_monthly_sales / NULLIF(ys.avg_yearly_sales, 0) AS seasonality_index
FROM 
    monthly_sales ms
JOIN 
    yearly_sales ys ON ms.year = ys.year
ORDER BY 
    ms.year, ms.month;

-- Calculating day-of-week seasonality
WITH daily_avg AS (
    SELECT 
        weekday,
        AVG(sales_amount) AS avg_day_sales
    FROM 
        daily_sales
    GROUP BY 
        weekday
),
overall_avg AS (
    SELECT 
        AVG(sales_amount) AS avg_sales
    FROM 
        daily_sales
)
SELECT 
    da.weekday,
    da.avg_day_sales,
    oa.avg_sales,
    da.avg_day_sales / NULLIF(oa.avg_sales, 0) AS day_of_week_index
FROM 
    daily_avg da
CROSS JOIN 
    overall_avg oa
ORDER BY 
    da.weekday;

-- ==========================================
-- 6. TREND DECOMPOSITION
-- ==========================================

-- Decomposing time series into trend, seasonal, and residual components
-- PostgreSQL example using moving averages and seasonal indices

-- Step 1: Calculate the trend component using moving average
WITH trend AS (
    SELECT 
        date_id,
        sales_amount,
        AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING) AS trend_component
    FROM 
        daily_sales
),

-- Step 2: Calculate seasonal indices
seasonal_indices AS (
    WITH detrended AS (
        SELECT 
            date_id,
            sales_amount,
            trend_component,
            sales_amount / NULLIF(trend_component, 0) AS detrended_value,
            EXTRACT(DOW FROM date_id) AS weekday
        FROM 
            trend
        WHERE 
            trend_component IS NOT NULL
    )
    SELECT 
        weekday,
        AVG(detrended_value) AS seasonal_index
    FROM 
        detrended
    GROUP BY 
        weekday
),

-- Step 3: Combine everything
decomposition AS (
    SELECT 
        t.date_id,
        t.sales_amount,
        t.trend_component,
        si.seasonal_index,
        t.trend_component * si.seasonal_index AS seasonal_component,
        t.sales_amount / NULLIF(t.trend_component * si.seasonal_index, 0) AS residual_component
    FROM 
        trend t
    JOIN 
        seasonal_indices si ON EXTRACT(DOW FROM t.date_id) = si.weekday
    WHERE 
        t.trend_component IS NOT NULL
)

SELECT 
    date_id,
    sales_amount,
    trend_component,
    seasonal_index,
    seasonal_component,
    residual_component
FROM 
    decomposition
ORDER BY 
    date_id;

-- ==========================================
-- 7. ANOMALY DETECTION
-- ==========================================

-- Z-score based anomaly detection
WITH stats AS (
    SELECT 
        AVG(sales_amount) AS mean_sales,
        STDDEV(sales_amount) AS stddev_sales
    FROM 
        daily_sales
),
z_scores AS (
    SELECT 
        ds.date_id,
        ds.sales_amount,
        (ds.sales_amount - s.mean_sales) / NULLIF(s.stddev_sales, 0) AS z_score
    FROM 
        daily_sales ds
    CROSS JOIN 
        stats s
)
SELECT 
    date_id,
    sales_amount,
    z_score,
    CASE
        WHEN ABS(z_score) > 3 THEN 'Extreme anomaly'
        WHEN ABS(z_score) > 2 THEN 'Significant anomaly'
        ELSE 'Normal'
    END AS anomaly_status
FROM 
    z_scores
WHERE 
    ABS(z_score) > 2
ORDER BY 
    ABS(z_score) DESC;

-- Moving average based anomaly detection
WITH moving_stats AS (
    SELECT 
        date_id,
        sales_amount,
        AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING) AS ma_sales,
        STDDEV(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING) AS ma_stddev
    FROM 
        daily_sales
),
deviations AS (
    SELECT 
        date_id,
        sales_amount,
        ma_sales,
        ma_stddev,
        (sales_amount - ma_sales) / NULLIF(ma_stddev, 0) AS deviation_score
    FROM 
        moving_stats
)
SELECT 
    date_id,
    sales_amount,
    ma_sales,
    deviation_score,
    CASE
        WHEN ABS(deviation_score) > 3 THEN 'Extreme anomaly'
        WHEN ABS(deviation_score) > 2 THEN 'Significant anomaly'
        ELSE 'Normal'
    END AS anomaly_status
FROM 
    deviations
WHERE 
    ABS(deviation_score) > 2
ORDER BY 
    ABS(deviation_score) DESC;

-- ==========================================
-- 8. FORECASTING MODELS
-- ==========================================

-- Simple linear regression for trend forecasting
WITH days_numbered AS (
    SELECT 
        date_id,
        sales_amount,
        ROW_NUMBER() OVER (ORDER BY date_id) AS day_num
    FROM 
        daily_sales
),
regression_params AS (
    SELECT 
        COUNT(*) AS n,
        AVG(day_num) AS avg_x,
        AVG(sales_amount) AS avg_y,
        REGR_SLOPE(sales_amount, day_num) AS slope,
        REGR_INTERCEPT(sales_amount, day_num) AS intercept
    FROM 
        days_numbered
)
SELECT 
    dn.date_id,
    dn.day_num,
    dn.sales_amount AS actual_sales,
    rp.intercept + rp.slope * dn.day_num AS predicted_sales,
    dn.sales_amount - (rp.intercept + rp.slope * dn.day_num) AS residual
FROM 
    days_numbered dn
CROSS JOIN 
    regression_params rp
ORDER BY 
    dn.date_id;

-- Multiple regression with seasonality and trend
-- This is a simplified example and would typically be done with a specialized tool
WITH predictors AS (
    SELECT 
        date_id,
        sales_amount,
        ROW_NUMBER() OVER (ORDER BY date_id) AS day_num, -- trend
        SIN(2 * PI() * EXTRACT(DOY FROM date_id) / 365) AS sin_yearly, -- yearly seasonality (sine)
        COS(2 * PI() * EXTRACT(DOY FROM date_id) / 365) AS cos_yearly, -- yearly seasonality (cosine)
        SIN(2 * PI() * EXTRACT(DOW FROM date_id) / 7) AS sin_weekly, -- weekly seasonality (sine)
        COS(2 * PI() * EXTRACT(DOW FROM date_id) / 7) AS cos_weekly, -- weekly seasonality (cosine)
        promotion_active::INT AS is_promotion,
        holiday::INT AS is_holiday
    FROM 
        daily_sales
)
-- For full implementation, use a statistical package or ML tool
-- to perform the regression analysis and generate predictions

-- ARIMA models would typically be implemented with specialized software
-- and then the results imported or called from SQL, as these models are
-- computationally intensive and require specialized libraries

-- Holt-Winters triple exponential smoothing
-- This is a simplified implementation
WITH RECURSIVE hw_model AS (
    -- Initialize with first data point
    SELECT 
        date_id,
        sales_amount,
        sales_amount AS level,
        0 AS trend,
        1.0 AS seasonal, -- assume multiplicative seasonality
        7 AS seasonality_period, -- weekly seasonality
        1 AS day_rank
    FROM 
        daily_sales
    WHERE 
        date_id = (SELECT MIN(date_id) FROM daily_sales)
    
    UNION ALL
    
    -- Apply Holt-Winters recursively
    SELECT 
        ds.date_id,
        ds.sales_amount,
        -- Update level
        0.2 * (ds.sales_amount / seasonal) + 0.8 * (level + trend) AS level,
        -- Update trend
        0.1 * (level - prev_level) + 0.9 * trend AS trend,
        -- Update seasonal factor
        0.3 * (ds.sales_amount / (level + trend)) + 0.7 * seasonal AS seasonal,
        seasonality_period,
        day_rank + 1
    FROM (
        SELECT 
            hw.date_id,
            hw.level,
            LAG(hw.level) OVER (ORDER BY hw.date_id) AS prev_level,
            hw.trend,
            COALESCE(
                (SELECT hwp.seasonal FROM hw_model hwp WHERE hwp.day_rank = hw.day_rank - seasonality_period + 1),
                1.0
            ) AS seasonal,
            hw.seasonality_period,
            hw.day_rank
        FROM 
            hw_model hw
    ) hw
    JOIN 
        daily_sales ds ON ds.date_id = (hw.date_id + INTERVAL '1 day')
    WHERE 
        hw.day_rank < 100 -- Limit for demonstration
)
SELECT 
    date_id,
    sales_amount,
    level,
    trend,
    seasonal,
    (level + trend) * seasonal AS forecast
FROM 
    hw_model
ORDER BY 
    date_id;

-- ==========================================
-- 9. FORECASTING EVALUATION
-- ==========================================

-- Calculate forecast accuracy metrics
WITH forecast_comparison AS (
    SELECT 
        date_id,
        sales_amount AS actual,
        -- Assume we have a forecast from a separate model
        LAG(sales_amount, 7) OVER (ORDER BY date_id) AS naive_forecast -- simple 7-day lag as naive forecast
    FROM 
        daily_sales
    WHERE 
        date_id >= '2021-01-01'
)
SELECT 
    -- Mean Absolute Error (MAE)
    AVG(ABS(actual - naive_forecast)) AS mae,
    
    -- Mean Absolute Percentage Error (MAPE)
    AVG(ABS(actual - naive_forecast) / NULLIF(actual, 0)) * 100 AS mape,
    
    -- Root Mean Square Error (RMSE)
    SQRT(AVG(POWER(actual - naive_forecast, 2))) AS rmse,
    
    -- Mean Error (ME) - to check for bias
    AVG(actual - naive_forecast) AS me,
    
    -- R-squared (coefficient of determination)
    1 - (SUM(POWER(actual - naive_forecast, 2)) / NULLIF(SUM(POWER(actual - AVG(actual), 2)), 0)) AS r_squared
FROM 
    forecast_comparison
WHERE 
    naive_forecast IS NOT NULL;

-- ==========================================
-- 10. ADVANCED TIME SERIES TECHNIQUES
-- ==========================================

-- Identifying change points in time series
WITH change_points AS (
    SELECT 
        date_id,
        sales_amount,
        AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS avg_before,
        AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 0 FOLLOWING AND 15 FOLLOWING) AS avg_after,
        STDDEV(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS std_before,
        STDDEV(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 0 FOLLOWING AND 15 FOLLOWING) AS std_after
    FROM 
        daily_sales
)
SELECT 
    date_id,
    sales_amount,
    avg_before,
    avg_after,
    std_before,
    std_after,
    ABS(avg_after - avg_before) / ((std_before + std_after) / 2) AS change_magnitude,
    CASE
        WHEN ABS(avg_after - avg_before) / ((std_before + std_after) / 2) > 2 THEN 'Significant change'
        ELSE 'Normal variation'
    END AS change_point_status
FROM 
    change_points
WHERE 
    avg_before IS NOT NULL AND avg_after IS NOT NULL
ORDER BY 
    change_magnitude DESC;

-- Granger causality test (simplified)
-- In practice, would use specialized statistical software
WITH lagged_data AS (
    SELECT 
        a.date_id,
        a.sales_amount,
        b.promotion_active AS promotion_lag1,
        c.promotion_active AS promotion_lag2,
        d.promotion_active AS promotion_lag3
    FROM 
        daily_sales a
    LEFT JOIN 
        daily_sales b ON a.date_id = b.date_id + INTERVAL '1 day'
    LEFT JOIN 
        daily_sales c ON a.date_id = c.date_id + INTERVAL '2 day'
    LEFT JOIN 
        daily_sales d ON a.date_id = d.date_id + INTERVAL '3 day'
)
-- This would be followed by a regression analysis to test for causality

-- ==========================================
-- 11. PRACTICAL APPLICATIONS
-- ==========================================

-- Sales forecasting for inventory planning
WITH forecast_data AS (
    -- Assume we have a forecast model that gives us these values
    -- In practice, this would come from a more sophisticated model
    SELECT 
        date_id,
        sales_amount AS actual_sales,
        units_sold AS actual_units,
        -- Simple 4-week moving average for demonstration
        AVG(units_sold) OVER (ORDER BY date_id ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING) AS forecast_units,
        -- Add some buffer for safety stock
        1.2 * AVG(units_sold) OVER (ORDER BY date_id ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING) AS recommended_stock
    FROM 
        daily_sales
)
SELECT 
    date_id,
    actual_units,
    forecast_units,
    recommended_stock,
    actual_units - forecast_units AS forecast_error,
    CASE
        WHEN actual_units > recommended_stock THEN 'Stock out risk'
        WHEN actual_units < forecast_units * 0.8 THEN 'Overstock risk'
        ELSE 'Adequate inventory'
    END AS inventory_status
FROM 
    forecast_data
WHERE 
    date_id >= '2022-01-01'
ORDER BY 
    date_id;

-- Anomaly detection for fraud or system issues
WITH daily_stats AS (
    SELECT 
        date_id,
        sales_amount,
        units_sold,
        AVG(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS avg_sales,
        STDDEV(sales_amount) OVER (ORDER BY date_id ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS stddev_sales,
        AVG(units_sold) OVER (ORDER BY date_id ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS avg_units,
        STDDEV(units_sold) OVER (ORDER BY date_id ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS stddev_units,
        sales_amount / NULLIF(units_sold, 0) AS avg_price
    FROM 
        daily_sales
)
SELECT 
    date_id,
    sales_amount,
    units_sold,
    avg_sales,
    (sales_amount - avg_sales) / NULLIF(stddev_sales, 0) AS sales_z_score,
    (units_sold - avg_units) / NULLIF(stddev_units, 0) AS units_z_score,
    avg_price,
    CASE
        WHEN ABS((sales_amount - avg_sales) / NULLIF(stddev_sales, 0)) > 3 THEN 'Anomalous sales'
        WHEN ABS((units_sold - avg_units) / NULLIF(stddev_units, 0)) > 3 THEN 'Anomalous units'
        ELSE 'Normal'
    END AS anomaly_status
FROM 
    daily_stats
WHERE 
    date_id >= '2022-01-01'
    AND (
        ABS((sales_amount - avg_sales) / NULLIF(stddev_sales, 0)) > 3
        OR ABS((units_sold - avg_units) / NULLIF(stddev_units, 0)) > 3
    )
ORDER BY 
    date_id;

-- ==========================================
-- 12. BEST PRACTICES FOR TIME SERIES ANALYSIS
-- ==========================================

/*
Time Series Analysis Best Practices:

1. Data Preparation
   - Ensure consistent time intervals
   - Handle missing values appropriately
   - Check for and address outliers
   - Normalize/standardize data when necessary

2. Exploration
   - Visualize data before modeling
   - Decompose into trend, seasonality, and residuals
   - Check for stationarity
   - Identify cyclic patterns and seasonality

3. Modeling
   - Start with simple models (e.g., moving averages)
   - Progress to more complex models as needed
   - Consider multiple models and ensemble approaches
   - Validate models on holdout data

4. Evaluation
   - Use appropriate metrics (MAE, MAPE, RMSE)
   - Consider business impact of errors
   - Test forecasts against naive benchmarks
   - Regularly retrain models with new data

5. Implementation
   - Automate the forecasting process
   - Build monitoring for forecast accuracy
   - Create alerts for significant deviations
   - Document assumptions and limitations
*/
