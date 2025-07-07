/*
================================================================================
File: 03_advanced/09_business_reporting/02_operational_reporting.sql
Topic: Operational Dashboard Creation for Department Managers
Purpose: Build daily/weekly operational dashboards for business operations
Author: SQL Analyst Pack Community
Created: 2025-07-06
Database: Multi-platform compatible
================================================================================

OPERATIONAL REPORTING REQUIREMENTS:
This script creates operational dashboards that help department managers
monitor day-to-day business performance and identify operational issues
that need immediate attention.

TARGET AUDIENCE:
- Operations Managers
- Department Heads  
- Team Leaders
- Process Managers

KEY OPERATIONAL METRICS:
- Daily/weekly performance indicators
- Process efficiency measures
- Resource utilization metrics
- Quality and exception monitoring
- Team productivity tracking
================================================================================
*/

-- Daily Operations Dashboard
WITH daily_performance AS (
    SELECT 
        order_date::DATE as business_date,
        COUNT(*) as daily_orders,
        SUM(order_total) as daily_revenue,
        COUNT(DISTINCT customer_id) as unique_customers,
        AVG(order_total) as avg_order_value,
        
        -- Operational efficiency metrics
        COUNT(*) FILTER (WHERE shipped_date IS NOT NULL) as shipped_orders,
        COUNT(*) FILTER (WHERE shipped_date IS NULL AND order_date < CURRENT_DATE - 1) as pending_shipments,
        
        -- Customer service metrics
        COUNT(*) FILTER (WHERE order_total > 1000) as high_value_orders,
        COUNT(*) FILTER (WHERE order_date = shipped_date) as same_day_shipments
        
    FROM orders 
    WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY order_date::DATE
)

SELECT 
    business_date,
    daily_orders,
    daily_revenue,
    unique_customers,
    ROUND(avg_order_value, 2) as avg_order_value,
    
    -- Operational KPIs
    ROUND((shipped_orders::FLOAT / daily_orders * 100), 1) as shipment_rate_pct,
    pending_shipments,
    high_value_orders,
    same_day_shipments,
    
    -- Performance vs 7-day average
    ROUND(
        daily_orders - AVG(daily_orders) OVER (
            ORDER BY business_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ), 0
    ) as orders_vs_7day_avg,
    
    -- Performance indicators
    CASE 
        WHEN daily_orders > AVG(daily_orders) OVER (
            ORDER BY business_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ) * 1.2 THEN '🟢 HIGH PERFORMANCE'
        WHEN daily_orders < AVG(daily_orders) OVER (
            ORDER BY business_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ) * 0.8 THEN '🔴 LOW PERFORMANCE'
        ELSE '🟡 NORMAL PERFORMANCE'
    END as performance_status

FROM daily_performance
ORDER BY business_date DESC;

/*
================================================================================
USAGE INSTRUCTIONS:
- Run daily for operations team morning briefings
- Monitor performance_status for immediate action items
- Track pending_shipments for fulfillment priorities
- Use for daily stand-up meetings and operational reviews
================================================================================
*/
