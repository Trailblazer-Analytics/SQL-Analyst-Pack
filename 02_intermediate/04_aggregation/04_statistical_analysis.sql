/*
    File: 04_statistical_analysis.sql
    Module: 04_aggregation
    Topic: Statistical Analysis and Advanced Analytics
    Author: SQL Analyst Pack
    Date: 2025-06-22
    Description: Advanced statistical functions and data science applications in SQL
    
    Business Scenarios:
    - Data science and machine learning preparation
    - Quality control and process improvement
    - Risk analysis and anomaly detection
    - Performance benchmarking and optimization
    
    Database: Chinook (Music Store Digital Media)
    Complexity: Advanced
    Estimated Time: 90-120 minutes
*/

-- =================================================================================================================================
-- 🎯 LEARNING OBJECTIVES
-- =================================================================================================================================
--
-- After completing this script, you will be able to:
-- ✅ Calculate advanced statistical measures (standard deviation, variance, percentiles)
-- ✅ Perform correlation analysis and identify relationships in data
-- ✅ Implement outlier detection and anomaly identification
-- ✅ Create statistical quality control and process monitoring
-- ✅ Build foundation for machine learning and predictive analytics
--
-- =================================================================================================================================
-- 💼 BUSINESS SCENARIO: Data Science and Analytics Excellence
-- =================================================================================================================================
--
-- Chinook's executive team wants to leverage advanced analytics to:
-- 1. Identify anomalies in sales patterns that might indicate fraud or data issues
-- 2. Understand customer behavior patterns for predictive modeling
-- 3. Implement statistical quality control for business processes
-- 4. Perform risk analysis and identify potential business threats
-- 5. Create data-driven insights for strategic planning and forecasting
--
-- Your mission: Transform Chinook into a data-driven organization using statistical analysis.
--
-- =================================================================================================================================
-- 📊 PART 1: DESCRIPTIVE STATISTICS AND DISTRIBUTION ANALYSIS
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Comprehensive Statistical Profile of Customer Purchases
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Understanding the full distribution of customer behavior

WITH customer_statistics AS (
    SELECT 
        c.CustomerId,
        c.FirstName + ' ' + c.LastName as customer_name,
        c.Country,
        COUNT(DISTINCT i.InvoiceId) as purchase_frequency,
        SUM(i.Total) as total_spent,
        AVG(i.Total) as avg_purchase_amount,
        MIN(i.Total) as min_purchase,
        MAX(i.Total) as max_purchase,
        STDDEV(i.Total) as purchase_stddev,
        VAR(i.Total) as purchase_variance,
        -- Calculate coefficient of variation (relative variability)
        CASE 
            WHEN AVG(i.Total) > 0 THEN STDDEV(i.Total) / AVG(i.Total)
            ELSE NULL
        END as coefficient_of_variation,
        -- Purchase recency analysis
        DATEDIFF(DAY, MIN(i.InvoiceDate), MAX(i.InvoiceDate)) as customer_lifespan_days,
        DATEDIFF(DAY, MAX(i.InvoiceDate), CURRENT_DATE) as days_since_last_purchase
    FROM Customer c
    JOIN Invoice i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
    HAVING COUNT(DISTINCT i.InvoiceId) >= 2  -- Only customers with multiple purchases
)
SELECT 
    Country,
    COUNT(*) as customer_count,
    -- Central tendency measures
    ROUND(AVG(total_spent), 2) as mean_total_spent,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_spent), 2) as median_total_spent,
    -- Variability measures
    ROUND(STDDEV(total_spent), 2) as stddev_total_spent,
    ROUND(VAR(total_spent), 2) as variance_total_spent,
    ROUND(AVG(coefficient_of_variation), 3) as avg_coefficient_variation,
    -- Distribution shape
    ROUND(MIN(total_spent), 2) as min_total_spent,
    ROUND(MAX(total_spent), 2) as max_total_spent,
    ROUND(MAX(total_spent) - MIN(total_spent), 2) as range_total_spent,
    -- Percentile analysis
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_spent), 2) as q1_total_spent,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_spent), 2) as q3_total_spent,
    ROUND(
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_spent) - 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_spent), 2
    ) as iqr_total_spent,
    -- Business insights
    CASE 
        WHEN STDDEV(total_spent) / AVG(total_spent) > 1.0 THEN '🌊 High Variability Market'
        WHEN STDDEV(total_spent) / AVG(total_spent) > 0.5 THEN '📊 Moderate Variability Market'
        ELSE '📈 Stable Market'
    END as market_stability,
    -- Customer behavior pattern
    ROUND(AVG(purchase_frequency), 1) as avg_purchase_frequency,
    ROUND(AVG(customer_lifespan_days), 0) as avg_customer_lifespan_days
FROM customer_statistics
GROUP BY Country
ORDER BY mean_total_spent DESC;

-- 💡 Data Science Insight: Coefficient of variation identifies markets with unpredictable customer behavior
-- 💡 Business Strategy: High variability markets need different approaches than stable markets

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Outlier Detection Using Statistical Methods
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Identify unusual transactions that might indicate fraud or data quality issues

WITH transaction_stats AS (
    SELECT 
        AVG(Total) as mean_amount,
        STDDEV(Total) as stddev_amount,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total) as q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total) as q3,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total) - 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total) as iqr
    FROM Invoice
),
outlier_analysis AS (
    SELECT 
        i.InvoiceId,
        i.InvoiceDate,
        c.FirstName + ' ' + c.LastName as customer_name,
        c.Country,
        i.Total as transaction_amount,
        ts.mean_amount,
        ts.stddev_amount,
        -- Z-Score calculation (standard deviations from mean)
        (i.Total - ts.mean_amount) / ts.stddev_amount as z_score,
        -- IQR method boundaries
        ts.q1 - 1.5 * ts.iqr as lower_bound_iqr,
        ts.q3 + 1.5 * ts.iqr as upper_bound_iqr,
        -- Outlier classification
        CASE 
            WHEN ABS((i.Total - ts.mean_amount) / ts.stddev_amount) > 3 THEN 'Extreme Outlier (>3σ)'
            WHEN ABS((i.Total - ts.mean_amount) / ts.stddev_amount) > 2 THEN 'Moderate Outlier (>2σ)'
            WHEN i.Total < ts.q1 - 1.5 * ts.iqr OR i.Total > ts.q3 + 1.5 * ts.iqr THEN 'IQR Outlier'
            ELSE 'Normal Transaction'
        END as outlier_type,
        -- Business risk assessment
        CASE 
            WHEN i.Total > ts.mean_amount + 3 * ts.stddev_amount THEN '🚨 High Value - Verify'
            WHEN i.Total < ts.mean_amount - 3 * ts.stddev_amount THEN '⚠️ Unusually Low - Check'
            WHEN ABS((i.Total - ts.mean_amount) / ts.stddev_amount) > 2 THEN '🔍 Review Required'
            ELSE '✅ Normal Range'
        END as risk_flag
    FROM Invoice i
    CROSS JOIN transaction_stats ts
    JOIN Customer c ON i.CustomerId = c.CustomerId
)
SELECT 
    outlier_type,
    COUNT(*) as transaction_count,
    ROUND(AVG(transaction_amount), 2) as avg_amount,
    ROUND(MIN(transaction_amount), 2) as min_amount,
    ROUND(MAX(transaction_amount), 2) as max_amount,
    ROUND(AVG(ABS(z_score)), 2) as avg_abs_z_score,
    -- Sample transactions for investigation
    STRING_AGG(
        CASE WHEN ABS(z_score) > 2 
        THEN CAST(InvoiceId AS TEXT) + ' ($' + CAST(ROUND(transaction_amount, 2) AS TEXT) + ')'
        ELSE NULL END, 
        ', '
    ) as sample_transactions,
    -- Business impact
    ROUND(SUM(transaction_amount), 2) as total_amount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage_of_transactions
FROM outlier_analysis
GROUP BY outlier_type
ORDER BY avg_abs_z_score DESC;

-- 💡 Fraud Detection: Extreme outliers may indicate fraudulent transactions
-- 💡 Data Quality: Unusual patterns help identify data entry errors

-- =================================================================================================================================
-- 📈 PART 2: CORRELATION ANALYSIS AND RELATIONSHIP DISCOVERY
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Price-Volume Correlation Analysis
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Understanding relationships between price, volume, and revenue

WITH track_performance AS (
    SELECT 
        t.TrackId,
        t.Name as track_name,
        al.Title as album_title,
        ar.Name as artist_name,
        g.Name as genre,
        t.UnitPrice as track_price,
        COUNT(il.InvoiceLineId) as units_sold,
        SUM(il.UnitPrice * il.Quantity) as total_revenue,
        AVG(il.UnitPrice) as avg_selling_price,
        -- Price elasticity indicators
        t.UnitPrice as list_price,
        CASE 
            WHEN COUNT(il.InvoiceLineId) > 50 THEN 'High Volume'
            WHEN COUNT(il.InvoiceLineId) > 20 THEN 'Medium Volume'
            WHEN COUNT(il.InvoiceLineId) > 0 THEN 'Low Volume'
            ELSE 'No Sales'
        END as volume_category,
        CASE 
            WHEN t.UnitPrice >= 1.0 THEN 'Premium Price'
            WHEN t.UnitPrice >= 0.99 THEN 'Standard Price'
            ELSE 'Low Price'
        END as price_category
    FROM Track t
    JOIN Album al ON t.AlbumId = al.AlbumId
    JOIN Artist ar ON al.ArtistId = ar.ArtistId
    JOIN Genre g ON t.GenreId = g.GenreId
    LEFT JOIN InvoiceLine il ON t.TrackId = il.TrackId
    GROUP BY t.TrackId, t.Name, al.Title, ar.Name, g.Name, t.UnitPrice
),
correlation_analysis AS (
    SELECT 
        genre,
        price_category,
        volume_category,
        COUNT(*) as track_count,
        ROUND(AVG(track_price), 3) as avg_price,
        ROUND(AVG(units_sold), 1) as avg_units_sold,
        ROUND(AVG(total_revenue), 2) as avg_revenue,
        -- Correlation approximation using aggregated data
        ROUND(
            (SUM(track_price * units_sold) - SUM(track_price) * SUM(units_sold) / COUNT(*)) /
            SQRT(
                (SUM(track_price * track_price) - SUM(track_price) * SUM(track_price) / COUNT(*)) *
                (SUM(units_sold * units_sold) - SUM(units_sold) * SUM(units_sold) / COUNT(*))
            ), 3
        ) as price_volume_correlation
    FROM track_performance
    WHERE units_sold > 0  -- Only analyze tracks with sales
    GROUP BY genre, price_category, volume_category
)
SELECT 
    genre,
    price_category,
    track_count,
    avg_price,
    avg_units_sold,
    avg_revenue,
    price_volume_correlation,
    -- Business interpretation
    CASE 
        WHEN price_volume_correlation > 0.3 THEN '📈 Positive: Higher price = Higher volume'
        WHEN price_volume_correlation < -0.3 THEN '📉 Negative: Higher price = Lower volume'
        ELSE '↔️ Neutral: Price has little impact on volume'
    END as correlation_interpretation,
    -- Strategic recommendations
    CASE 
        WHEN price_volume_correlation > 0.3 AND price_category = 'Low Price' 
        THEN '💰 Consider price increase opportunity'
        WHEN price_volume_correlation < -0.3 AND price_category = 'Premium Price' 
        THEN '📊 Price sensitivity - consider promotions'
        WHEN avg_revenue > 50 THEN '🎯 High performer - maintain strategy'
        ELSE '🔍 Optimize pricing strategy'
    END as strategic_recommendation
FROM correlation_analysis
WHERE track_count >= 5  -- Only analyze categories with sufficient data
ORDER BY genre, price_volume_correlation DESC;

-- 💡 Pricing Strategy: Correlation analysis reveals optimal pricing opportunities
-- 💡 Revenue Optimization: Identify genres where price increases won't hurt volume

-- =================================================================================================================================
-- 🎯 PART 3: TIME SERIES ANALYSIS AND TREND DETECTION
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Advanced Time Series Statistical Analysis
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Seasonal patterns, trend analysis, and forecasting preparation

WITH daily_sales AS (
    SELECT 
        CAST(InvoiceDate AS DATE) as sale_date,
        COUNT(DISTINCT InvoiceId) as transaction_count,
        SUM(Total) as daily_revenue,
        COUNT(DISTINCT CustomerId) as unique_customers,
        EXTRACT(YEAR FROM InvoiceDate) as sale_year,
        EXTRACT(MONTH FROM InvoiceDate) as sale_month,
        EXTRACT(DAYOFWEEK FROM InvoiceDate) as day_of_week,
        -- Seasonal indicators
        CASE 
            WHEN EXTRACT(MONTH FROM InvoiceDate) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM InvoiceDate) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM InvoiceDate) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Fall'
        END as season
    FROM Invoice
    GROUP BY CAST(InvoiceDate AS DATE)
),
time_series_stats AS (
    SELECT 
        sale_date,
        daily_revenue,
        -- Moving averages
        AVG(daily_revenue) OVER (
            ORDER BY sale_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as moving_avg_7day,
        AVG(daily_revenue) OVER (
            ORDER BY sale_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) as moving_avg_30day,
        -- Volatility measures
        STDDEV(daily_revenue) OVER (
            ORDER BY sale_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) as rolling_stddev_30day,
        -- Trend detection
        daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY sale_date) as day_over_day_change,
        daily_revenue - LAG(daily_revenue, 7) OVER (ORDER BY sale_date) as week_over_week_change,
        -- Percentile ranking for anomaly detection
        PERCENT_RANK() OVER (ORDER BY daily_revenue) as revenue_percentile,
        sale_year,
        sale_month,
        day_of_week,
        season
    FROM daily_sales
)
SELECT 
    season,
    EXTRACT(MONTH FROM sale_date) as month,
    COUNT(*) as days_count,
    ROUND(AVG(daily_revenue), 2) as avg_daily_revenue,
    ROUND(STDDEV(daily_revenue), 2) as revenue_volatility,
    ROUND(MIN(daily_revenue), 2) as min_daily_revenue,
    ROUND(MAX(daily_revenue), 2) as max_daily_revenue,
    -- Trend analysis
    ROUND(AVG(day_over_day_change), 2) as avg_daily_change,
    ROUND(STDDEV(day_over_day_change), 2) as daily_change_volatility,
    -- Seasonality indicators
    ROUND(AVG(daily_revenue) / AVG(AVG(daily_revenue)) OVER (), 2) as seasonal_index,
    -- Quality control limits (3-sigma)
    ROUND(AVG(daily_revenue) + 3 * STDDEV(daily_revenue), 2) as upper_control_limit,
    ROUND(AVG(daily_revenue) - 3 * STDDEV(daily_revenue), 2) as lower_control_limit,
    -- Business insights
    CASE 
        WHEN STDDEV(daily_revenue) / AVG(daily_revenue) > 0.5 THEN '🌊 High Volatility Period'
        WHEN AVG(daily_revenue) / AVG(AVG(daily_revenue)) OVER () > 1.1 THEN '📈 Peak Season'
        WHEN AVG(daily_revenue) / AVG(AVG(daily_revenue)) OVER () < 0.9 THEN '📉 Low Season'
        ELSE '📊 Normal Period'
    END as business_pattern
FROM time_series_stats
WHERE sale_date >= DATE('2008-01-01')  -- Focus on complete years
GROUP BY season, EXTRACT(MONTH FROM sale_date)
ORDER BY EXTRACT(MONTH FROM sale_date);

-- 💡 Seasonal Planning: Statistical analysis reveals optimal timing for promotions
-- 💡 Inventory Management: Volatility measures help plan stock levels

-- =================================================================================================================================
-- 🔬 PART 4: ADVANCED STATISTICAL QUALITY CONTROL
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 5: Statistical Process Control for Business Operations
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Implementing Six Sigma quality control principles using SQL

WITH process_metrics AS (
    SELECT 
        EXTRACT(YEAR FROM i.InvoiceDate) as year,
        EXTRACT(MONTH FROM i.InvoiceDate) as month,
        c.Country,
        e.FirstName + ' ' + e.LastName as employee_name,
        -- Process metrics
        COUNT(DISTINCT i.InvoiceId) as transactions_processed,
        SUM(i.Total) as revenue_generated,
        AVG(i.Total) as avg_transaction_value,
        STDDEV(i.Total) as transaction_variability,
        COUNT(DISTINCT i.CustomerId) as customers_served,
        -- Efficiency metrics
        SUM(i.Total) / COUNT(DISTINCT i.InvoiceId) as revenue_per_transaction,
        COUNT(DISTINCT i.CustomerId) / COUNT(DISTINCT i.InvoiceId) as customers_per_transaction,
        -- Time-based metrics
        AVG(DATEDIFF(DAY, i.InvoiceDate, LAG(i.InvoiceDate) OVER (
            PARTITION BY c.Country 
            ORDER BY i.InvoiceDate
        ))) as avg_days_between_purchases
    FROM Invoice i
    JOIN Customer c ON i.CustomerId = c.CustomerId
    LEFT JOIN Employee e ON c.SupportRepId = e.EmployeeId
    GROUP BY 
        EXTRACT(YEAR FROM i.InvoiceDate),
        EXTRACT(MONTH FROM i.InvoiceDate),
        c.Country,
        e.FirstName,
        e.LastName
),
control_limits AS (
    SELECT 
        Country,
        AVG(revenue_per_transaction) as mean_rpt,
        STDDEV(revenue_per_transaction) as stddev_rpt,
        AVG(transactions_processed) as mean_transactions,
        STDDEV(transactions_processed) as stddev_transactions,
        AVG(transaction_variability) as mean_variability,
        STDDEV(transaction_variability) as stddev_variability
    FROM process_metrics
    GROUP BY Country
)
SELECT 
    pm.Country,
    pm.year,
    pm.month,
    pm.employee_name,
    pm.transactions_processed,
    ROUND(pm.revenue_per_transaction, 2) as revenue_per_transaction,
    ROUND(pm.transaction_variability, 2) as transaction_variability,
    -- Control chart analysis
    ROUND(cl.mean_rpt, 2) as target_rpt,
    ROUND(cl.mean_rpt + 3 * cl.stddev_rpt, 2) as upper_control_limit,
    ROUND(cl.mean_rpt - 3 * cl.stddev_rpt, 2) as lower_control_limit,
    -- Process capability
    CASE 
        WHEN pm.revenue_per_transaction > cl.mean_rpt + 3 * cl.stddev_rpt THEN '🚨 Above UCL - Special Cause'
        WHEN pm.revenue_per_transaction < cl.mean_rpt - 3 * cl.stddev_rpt THEN '⚠️ Below LCL - Investigation Needed'
        WHEN pm.revenue_per_transaction > cl.mean_rpt + 2 * cl.stddev_rpt THEN '📈 Above 2σ - Monitor'
        WHEN pm.revenue_per_transaction < cl.mean_rpt - 2 * cl.stddev_rpt THEN '📉 Below 2σ - Monitor'
        ELSE '✅ In Control'
    END as process_status,
    -- Performance rating
    CASE 
        WHEN ABS(pm.revenue_per_transaction - cl.mean_rpt) / cl.stddev_rpt <= 1 THEN '⭐⭐⭐ Excellent'
        WHEN ABS(pm.revenue_per_transaction - cl.mean_rpt) / cl.stddev_rpt <= 2 THEN '⭐⭐ Good'
        WHEN ABS(pm.revenue_per_transaction - cl.mean_rpt) / cl.stddev_rpt <= 3 THEN '⭐ Acceptable'
        ELSE '🔧 Needs Improvement'
    END as performance_rating,
    -- Statistical measures
    ROUND(
        (pm.revenue_per_transaction - cl.mean_rpt) / cl.stddev_rpt, 2
    ) as z_score,
    ROUND(
        CASE 
            WHEN cl.stddev_rpt > 0 THEN (6 * cl.stddev_rpt) / (6 * cl.stddev_rpt)
            ELSE NULL 
        END, 3
    ) as process_capability_cp
FROM process_metrics pm
JOIN control_limits cl ON pm.Country = cl.Country
WHERE pm.transactions_processed >= 5  -- Only analyze periods with sufficient data
ORDER BY pm.Country, pm.year, pm.month, ABS((pm.revenue_per_transaction - cl.mean_rpt) / cl.stddev_rpt) DESC;

-- 💡 Quality Control: Statistical process control identifies performance variations
-- 💡 Continuous Improvement: Data-driven approach to optimizing business processes

-- =================================================================================================================================
-- 📋 SUMMARY AND ADVANCED ANALYTICS ROADMAP
-- =================================================================================================================================

/*
🎯 STATISTICAL ANALYSIS MASTERY ACHIEVED:
1. ✅ Descriptive statistics and distribution analysis
2. ✅ Outlier detection and anomaly identification
3. ✅ Correlation analysis and relationship discovery  
4. ✅ Time series analysis and trend detection
5. ✅ Statistical process control and quality management

📊 DATA SCIENCE FOUNDATIONS BUILT:
- Statistical measures for ML feature engineering
- Outlier detection for data quality and fraud prevention
- Correlation analysis for feature selection
- Time series analysis for forecasting preparation
- Quality control for operational excellence

🔬 ADVANCED TECHNIQUES IMPLEMENTED:
- Z-score and IQR outlier detection
- Pearson correlation approximation in SQL
- Moving averages and volatility analysis
- Six Sigma statistical process control
- Percentile analysis and distribution profiling

🚀 BUSINESS IMPACT DELIVERED:
- Data-driven quality control systems
- Fraud detection and risk management
- Process optimization and efficiency monitoring
- Strategic insights for pricing and operations
- Foundation for predictive analytics and ML

➡️ NEXT STEPS FOR DATA SCIENCE EXCELLENCE:
- Implement real-time anomaly detection systems
- Build predictive models using statistical foundations
- Create automated quality monitoring dashboards
- Develop advanced forecasting capabilities
- Apply machine learning to business optimization
*/

-- =================================================================================================================================
-- 💼 DATA SCIENCE EXECUTIVE SUMMARY
-- =================================================================================================================================

-- Advanced analytics summary for executive reporting:
WITH executive_statistics AS (
    SELECT 
        'Customer Behavior Analysis' as metric_category,
        'Average Purchase Amount' as metric_name,
        ROUND(AVG(Total), 2) as metric_value,
        'USD' as unit,
        ROUND(STDDEV(Total), 2) as variability
    FROM Invoice
    
    UNION ALL
    
    SELECT 
        'Quality Control',
        'Process Stability Score',
        ROUND(
            100 * (1 - STDDEV(Total) / AVG(Total)), 1
        ),
        'Percentage',
        NULL
    FROM Invoice
    
    UNION ALL
    
    SELECT 
        'Risk Management',
        'Outlier Transaction Rate',
        ROUND(
            SUM(CASE WHEN ABS(Total - (SELECT AVG(Total) FROM Invoice)) > 3 * (SELECT STDDEV(Total) FROM Invoice) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
        ),
        'Percentage',
        NULL
    FROM Invoice
)
SELECT 
    metric_category,
    metric_name,
    CAST(metric_value AS TEXT) + ' ' + unit as formatted_value,
    CASE 
        WHEN metric_name LIKE '%Stability%' AND metric_value > 90 THEN '🎯 Excellent Process Control'
        WHEN metric_name LIKE '%Outlier%' AND metric_value < 1 THEN '✅ Low Risk Profile'
        WHEN metric_name LIKE '%Purchase%' THEN '💰 Revenue Insight: $' + CAST(metric_value AS TEXT)
        ELSE '📊 Key Performance Indicator'
    END as business_interpretation
FROM executive_statistics
ORDER BY metric_category, metric_name;

/*
🚀 CONGRATULATIONS ON STATISTICAL MASTERY!
You've completed advanced statistical analysis and built the foundation for:
✅ Data science and machine learning projects
✅ Quality control and process improvement
✅ Risk management and fraud detection
✅ Advanced business intelligence and analytics
✅ Predictive modeling and forecasting

Ready to put it all together? Continue to the next intermediate module or start applying these techniques to your own business challenges!
*/
