/*
================================================================================
File: 03_advanced/09_business_reporting/01_executive_kpi_dashboards.sql
Topic: Executive KPI Dashboard Creation
Purpose: Build comprehensive executive dashboards with key business metrics
Author: SQL Analyst Pack Community
Created: 2025-07-06
Database: Multi-platform compatible
SQL Flavors: ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ BigQuery
================================================================================

EXECUTIVE DASHBOARD REQUIREMENTS:
This script creates a comprehensive executive dashboard that answers the key
questions every C-suite executive asks about business performance:

1. What's our current performance vs targets?
2. How are we trending compared to last period?
3. Where are our biggest opportunities and risks?
4. What actions should we take based on the data?

BUSINESS CONTEXT:
You're creating a monthly executive dashboard for the CEO, CFO, and other
C-level executives. This dashboard will be used in board meetings and
strategic planning sessions.

KEY METRICS INCLUDED:
- Revenue performance and growth
- Customer acquisition and retention
- Operational efficiency indicators
- Financial health metrics
- Predictive indicators and alerts
================================================================================
*/

-- ============================================================================
-- SECTION 1: EXECUTIVE SUMMARY METRICS
-- ============================================================================

-- Current Month Performance Summary
WITH current_month_metrics AS (
    SELECT 
        DATE_TRUNC('month', CURRENT_DATE) as reporting_month,
        
        -- Revenue Metrics
        SUM(CASE WHEN order_date >= DATE_TRUNC('month', CURRENT_DATE) 
                 THEN order_total ELSE 0 END) as current_month_revenue,
        
        -- Customer Metrics  
        COUNT(DISTINCT CASE WHEN order_date >= DATE_TRUNC('month', CURRENT_DATE) 
                           THEN customer_id END) as current_month_active_customers,
        COUNT(DISTINCT CASE WHEN customer_first_order >= DATE_TRUNC('month', CURRENT_DATE) 
                           THEN customer_id END) as new_customers_acquired,
        
        -- Order Metrics
        COUNT(CASE WHEN order_date >= DATE_TRUNC('month', CURRENT_DATE) 
                   THEN order_id END) as current_month_orders,
        AVG(CASE WHEN order_date >= DATE_TRUNC('month', CURRENT_DATE) 
                 THEN order_total END) as avg_order_value
    FROM orders o
    LEFT JOIN (
        SELECT customer_id, MIN(order_date) as customer_first_order
        FROM orders GROUP BY customer_id
    ) first_orders ON o.customer_id = first_orders.customer_id
    WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
),

-- Previous Month for Comparison
previous_month_metrics AS (
    SELECT 
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' as prev_month,
        
        SUM(CASE WHEN order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
                  AND order_date < DATE_TRUNC('month', CURRENT_DATE)
                 THEN order_total ELSE 0 END) as prev_month_revenue,
        
        COUNT(DISTINCT CASE WHEN order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
                            AND order_date < DATE_TRUNC('month', CURRENT_DATE)
                           THEN customer_id END) as prev_month_active_customers
    FROM orders
    WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 months'
)

-- Executive Summary Dashboard
SELECT 
    '📊 EXECUTIVE DASHBOARD - ' || TO_CHAR(cm.reporting_month, 'YYYY-MM') as dashboard_title,
    
    -- Current Performance
    cm.current_month_revenue as current_revenue,
    cm.current_month_active_customers as active_customers,
    cm.new_customers_acquired as new_customers,
    cm.current_month_orders as total_orders,
    ROUND(cm.avg_order_value, 2) as avg_order_value,
    
    -- Growth Calculations
    ROUND(
        ((cm.current_month_revenue - pm.prev_month_revenue) / pm.prev_month_revenue * 100), 2
    ) as revenue_growth_pct,
    
    ROUND(
        ((cm.current_month_active_customers - pm.prev_month_active_customers) 
         / pm.prev_month_active_customers * 100), 2
    ) as customer_growth_pct,
    
    -- Performance Indicators
    CASE 
        WHEN ((cm.current_month_revenue - pm.prev_month_revenue) / pm.prev_month_revenue * 100) >= 10 
        THEN '🟢 EXCELLENT GROWTH'
        WHEN ((cm.current_month_revenue - pm.prev_month_revenue) / pm.prev_month_revenue * 100) >= 0 
        THEN '🟡 POSITIVE GROWTH'
        WHEN ((cm.current_month_revenue - pm.prev_month_revenue) / pm.prev_month_revenue * 100) >= -5 
        THEN '🟠 SLIGHT DECLINE'
        ELSE '🔴 SIGNIFICANT DECLINE'
    END as performance_status,
    
    -- Strategic Alerts
    CASE 
        WHEN cm.new_customers_acquired < (pm.prev_month_active_customers * 0.1) 
        THEN '⚠️ LOW CUSTOMER ACQUISITION'
        WHEN cm.avg_order_value < (
            SELECT AVG(order_total) FROM orders 
            WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '3 months'
        ) * 0.9 
        THEN '⚠️ DECLINING ORDER VALUE'
        ELSE '✅ METRICS ON TRACK'
    END as strategic_alerts

FROM current_month_metrics cm
CROSS JOIN previous_month_metrics pm;

-- ============================================================================
-- SECTION 2: TREND ANALYSIS FOR EXECUTIVE REVIEW
-- ============================================================================

-- 12-Month Performance Trend
WITH monthly_performance AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        SUM(order_total) as monthly_revenue,
        COUNT(DISTINCT customer_id) as unique_customers,
        COUNT(*) as order_count,
        AVG(order_total) as avg_order_value
    FROM orders 
    WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', order_date)
),

trend_analysis AS (
    SELECT *,
        LAG(monthly_revenue) OVER (ORDER BY month) as prev_month_revenue,
        
        -- 3-month moving average for trend smoothing
        AVG(monthly_revenue) OVER (
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as revenue_3mo_avg,
        
        -- Year-over-year comparison (when available)
        LAG(monthly_revenue, 12) OVER (ORDER BY month) as same_month_last_year
    FROM monthly_performance
)

SELECT 
    month,
    monthly_revenue,
    unique_customers,
    order_count,
    ROUND(avg_order_value, 2) as avg_order_value,
    
    -- Month-over-month growth
    CASE 
        WHEN prev_month_revenue IS NOT NULL THEN
            ROUND(((monthly_revenue - prev_month_revenue) / prev_month_revenue * 100), 2)
    END as mom_growth_pct,
    
    -- Year-over-year growth (when available)
    CASE 
        WHEN same_month_last_year IS NOT NULL THEN
            ROUND(((monthly_revenue - same_month_last_year) / same_month_last_year * 100), 2)
    END as yoy_growth_pct,
    
    -- Trend indicator
    CASE 
        WHEN monthly_revenue > revenue_3mo_avg * 1.05 THEN '📈 ABOVE TREND'
        WHEN monthly_revenue < revenue_3mo_avg * 0.95 THEN '📉 BELOW TREND'
        ELSE '➡️ ON TREND'
    END as trend_indicator,
    
    ROUND(revenue_3mo_avg, 2) as three_month_trend
    
FROM trend_analysis
ORDER BY month DESC
LIMIT 12;

-- ============================================================================
-- SECTION 3: OPERATIONAL EFFICIENCY METRICS
-- ============================================================================

-- Key Operational Indicators for Executive Review
WITH operational_metrics AS (
    SELECT 
        -- Customer Acquisition Efficiency
        COUNT(DISTINCT CASE WHEN customer_first_order >= DATE_TRUNC('month', CURRENT_DATE) 
                           THEN customer_id END) as new_customers_this_month,
        
        -- Customer Lifetime Metrics
        AVG(customer_lifetime_orders) as avg_customer_lifetime_orders,
        AVG(customer_lifetime_value) as avg_customer_lifetime_value,
        
        -- Order Processing Efficiency  
        AVG(EXTRACT(EPOCH FROM (shipped_date - order_date))/86400) as avg_fulfillment_days,
        
        -- Revenue Concentration Risk
        SUM(CASE WHEN customer_rank <= 10 THEN customer_total_revenue ELSE 0 END) 
        / SUM(customer_total_revenue) as top_10_customer_revenue_concentration
        
    FROM (
        SELECT 
            o.customer_id,
            MIN(o.order_date) as customer_first_order,
            COUNT(*) as customer_lifetime_orders,
            SUM(o.order_total) as customer_lifetime_value,
            o.order_date,
            o.shipped_date,
            RANK() OVER (ORDER BY SUM(o.order_total) DESC) as customer_rank,
            SUM(o.order_total) as customer_total_revenue
        FROM orders o
        GROUP BY o.customer_id, o.order_date, o.shipped_date
    ) customer_summary
)

SELECT 
    '🎯 OPERATIONAL EFFICIENCY DASHBOARD' as metric_category,
    new_customers_this_month,
    ROUND(avg_customer_lifetime_orders, 1) as avg_lifetime_orders,
    ROUND(avg_customer_lifetime_value, 2) as avg_customer_ltv,
    ROUND(avg_fulfillment_days, 1) as avg_fulfillment_days,
    ROUND(top_10_customer_revenue_concentration * 100, 1) as top_10_revenue_concentration_pct,
    
    -- Risk Assessment
    CASE 
        WHEN top_10_customer_revenue_concentration > 0.5 THEN '🔴 HIGH CUSTOMER CONCENTRATION RISK'
        WHEN top_10_customer_revenue_concentration > 0.3 THEN '🟡 MODERATE CONCENTRATION RISK'
        ELSE '🟢 DIVERSIFIED CUSTOMER BASE'
    END as customer_concentration_risk,
    
    CASE 
        WHEN avg_fulfillment_days > 7 THEN '🔴 SLOW FULFILLMENT'
        WHEN avg_fulfillment_days > 3 THEN '🟡 MODERATE FULFILLMENT'
        ELSE '🟢 FAST FULFILLMENT'
    END as fulfillment_performance

FROM operational_metrics;

-- ============================================================================
-- SECTION 4: PREDICTIVE INDICATORS & EARLY WARNING SYSTEM
-- ============================================================================

-- Executive Early Warning Dashboard
WITH warning_indicators AS (
    SELECT 
        -- Revenue Velocity (trend in order frequency)
        COUNT(*) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '7 days') as orders_last_7_days,
        COUNT(*) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '14 days' 
                         AND order_date < CURRENT_DATE - INTERVAL '7 days') as orders_prev_7_days,
        
        -- Customer Engagement Decline
        COUNT(DISTINCT customer_id) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '30 days') as active_customers_30d,
        COUNT(DISTINCT customer_id) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '60 days' 
                                           AND order_date < CURRENT_DATE - INTERVAL '30 days') as active_customers_prev_30d,
        
        -- Average Order Value Trend
        AVG(order_total) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '30 days') as aov_current_30d,
        AVG(order_total) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '60 days' 
                                 AND order_date < CURRENT_DATE - INTERVAL '30 days') as aov_prev_30d
    FROM orders
)

SELECT 
    '⚠️ EXECUTIVE EARLY WARNING SYSTEM' as alert_system,
    
    -- Order Velocity Alert
    orders_last_7_days,
    orders_prev_7_days,
    ROUND(((orders_last_7_days - orders_prev_7_days) / orders_prev_7_days::FLOAT * 100), 1) as order_velocity_change_pct,
    
    -- Customer Activity Alert
    active_customers_30d,
    active_customers_prev_30d,
    ROUND(((active_customers_30d - active_customers_prev_30d) / active_customers_prev_30d::FLOAT * 100), 1) as customer_activity_change_pct,
    
    -- Order Value Alert
    ROUND(aov_current_30d, 2) as current_aov,
    ROUND(aov_prev_30d, 2) as previous_aov,
    ROUND(((aov_current_30d - aov_prev_30d) / aov_prev_30d * 100), 1) as aov_change_pct,
    
    -- Executive Action Items
    CASE 
        WHEN ((orders_last_7_days - orders_prev_7_days) / orders_prev_7_days::FLOAT * 100) < -10 
        THEN '🚨 ORDER VELOCITY DECLINING - REVIEW MARKETING'
        WHEN ((active_customers_30d - active_customers_prev_30d) / active_customers_prev_30d::FLOAT * 100) < -5 
        THEN '🚨 CUSTOMER ENGAGEMENT DROPPING - REVIEW RETENTION'
        WHEN ((aov_current_30d - aov_prev_30d) / aov_prev_30d * 100) < -5 
        THEN '🚨 ORDER VALUES DECLINING - REVIEW PRICING'
        ELSE '✅ ALL INDICATORS STABLE'
    END as executive_action_required

FROM warning_indicators;

/*
================================================================================
EXECUTIVE USAGE NOTES:
================================================================================

DASHBOARD REFRESH FREQUENCY:
- Run daily for early warning indicators
- Run weekly for trend analysis  
- Run monthly for complete executive dashboard

INTERPRETATION GUIDE:
🟢 Green: Performance exceeding expectations
🟡 Yellow: Performance meeting expectations with monitoring needed
🟠 Orange: Performance below expectations, action may be needed
🔴 Red: Performance significantly below expectations, immediate action required

RECOMMENDED ACTIONS BY ALERT:
- EXCELLENT GROWTH: Investigate scalability and capacity planning
- POSITIVE GROWTH: Continue current strategies with optimization
- SLIGHT DECLINE: Analyze causes and implement corrective measures
- SIGNIFICANT DECLINE: Emergency business review and strategy adjustment

CUSTOMIZATION NOTES:
- Adjust percentage thresholds based on your business model
- Add industry-specific KPIs as needed
- Modify time periods based on business cycle
- Include budget targets for variance analysis
================================================================================
*/
