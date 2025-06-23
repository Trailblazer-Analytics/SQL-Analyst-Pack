-- ============================================================================
-- EXECUTIVE KPI DASHBOARD
-- Business Intelligence Scenario for SQL Analysts
-- ============================================================================

/* 
📊 BUSINESS CONTEXT:
The CEO needs a weekly executive dashboard that provides a high-level view of 
company performance. This dashboard will be reviewed every Monday morning 
in the executive team meeting.

🎯 STAKEHOLDER: Chief Executive Officer (CEO)
📅 FREQUENCY: Weekly (refreshed every Monday morning)
⏰ DEADLINE: Must be ready by 8:00 AM Monday for 9:00 AM executive meeting

🎯 BUSINESS REQUIREMENTS:
1. Revenue metrics with period-over-period comparisons
2. Customer acquisition and retention indicators  
3. Key operational efficiency metrics
4. Sales pipeline health indicators
5. Trend analysis to identify potential issues early

📈 SUCCESS METRICS:
- Enable data-driven decision making in executive meetings
- Provide early warning indicators for business performance
- Support quarterly planning and forecasting discussions
- Track progress against annual business goals
*/

-- ============================================================================
-- DATA STRUCTURE OVERVIEW
-- ============================================================================

/* 
Available Tables (sample data provided below):
- orders: Transaction data with customer, product, and revenue information
- customers: Customer demographics and acquisition details  
- products: Product catalog with categories and pricing
- sales_reps: Sales team information and territories
- targets: Monthly and quarterly business targets
*/

-- ============================================================================
-- SECTION 1: REVENUE PERFORMANCE DASHBOARD
-- ============================================================================

-- 🎯 Key Business Question: "How is our revenue performing vs. targets and trends?"

-- 1.1 Current Month Revenue vs Target
SELECT 
    EXTRACT(YEAR FROM CURRENT_DATE) as current_year,
    EXTRACT(MONTH FROM CURRENT_DATE) as current_month,
    
    -- Current month revenue (month-to-date)
    COALESCE(SUM(CASE 
        WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
        AND EXTRACT(MONTH FROM order_date) = EXTRACT(MONTH FROM CURRENT_DATE)
        THEN total_amount 
    END), 0) as mtd_revenue,
    
    -- Monthly target (from targets table)
    COALESCE(MAX(CASE 
        WHEN EXTRACT(YEAR FROM target_date) = EXTRACT(YEAR FROM CURRENT_DATE)
        AND EXTRACT(MONTH FROM target_date) = EXTRACT(MONTH FROM CURRENT_DATE)
        THEN monthly_revenue_target 
    END), 0) as monthly_target,
    
    -- Target achievement percentage
    ROUND(
        COALESCE(SUM(CASE 
            WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            AND EXTRACT(MONTH FROM order_date) = EXTRACT(MONTH FROM CURRENT_DATE)
            THEN total_amount 
        END), 0) * 100.0 / 
        NULLIF(MAX(CASE 
            WHEN EXTRACT(YEAR FROM target_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            AND EXTRACT(MONTH FROM target_date) = EXTRACT(MONTH FROM CURRENT_DATE)
            THEN monthly_revenue_target 
        END), 0), 2
    ) as target_achievement_pct,
    
    -- Days remaining in month
    EXTRACT(DAY FROM (DATE_TRUNC('MONTH', CURRENT_DATE) + INTERVAL '1 MONTH' - INTERVAL '1 DAY')) - 
    EXTRACT(DAY FROM CURRENT_DATE) as days_remaining,
    
    -- Projected month-end revenue (based on current daily run rate)
    ROUND(
        COALESCE(SUM(CASE 
            WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            AND EXTRACT(MONTH FROM order_date) = EXTRACT(MONTH FROM CURRENT_DATE)
            THEN total_amount 
        END), 0) / EXTRACT(DAY FROM CURRENT_DATE) * 
        EXTRACT(DAY FROM (DATE_TRUNC('MONTH', CURRENT_DATE) + INTERVAL '1 MONTH' - INTERVAL '1 DAY')), 0
    ) as projected_month_end
    
FROM orders o
LEFT JOIN targets t ON DATE_TRUNC('MONTH', o.order_date) = DATE_TRUNC('MONTH', t.target_date)
WHERE o.order_date >= DATE_TRUNC('MONTH', CURRENT_DATE) - INTERVAL '1 MONTH'
   OR t.target_date >= DATE_TRUNC('MONTH', CURRENT_DATE) - INTERVAL '1 MONTH';

-- 1.2 Revenue Trend Analysis (Last 12 Months)
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('MONTH', order_date) as month,
        SUM(total_amount) as revenue,
        COUNT(DISTINCT order_id) as order_count,
        COUNT(DISTINCT customer_id) as customer_count,
        ROUND(SUM(total_amount) / COUNT(DISTINCT order_id), 2) as avg_order_value
    FROM orders 
    WHERE order_date >= DATE_TRUNC('MONTH', CURRENT_DATE) - INTERVAL '12 MONTHS'
    GROUP BY DATE_TRUNC('MONTH', order_date)
),
revenue_with_trends AS (
    SELECT 
        month,
        revenue,
        order_count,
        customer_count,
        avg_order_value,
        
        -- Month-over-month growth
        LAG(revenue, 1) OVER (ORDER BY month) as prev_month_revenue,
        ROUND(
            (revenue - LAG(revenue, 1) OVER (ORDER BY month)) * 100.0 / 
            NULLIF(LAG(revenue, 1) OVER (ORDER BY month), 0), 2
        ) as mom_growth_pct,
        
        -- Year-over-year growth 
        LAG(revenue, 12) OVER (ORDER BY month) as prev_year_revenue,
        ROUND(
            (revenue - LAG(revenue, 12) OVER (ORDER BY month)) * 100.0 / 
            NULLIF(LAG(revenue, 12) OVER (ORDER BY month), 0), 2
        ) as yoy_growth_pct,
        
        -- 3-month moving average
        ROUND(
            AVG(revenue) OVER (
                ORDER BY month 
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 0
        ) as three_month_avg
        
    FROM monthly_revenue
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') as month,
    revenue,
    prev_month_revenue,
    mom_growth_pct,
    yoy_growth_pct,
    three_month_avg,
    order_count,
    customer_count,
    avg_order_value,
    
    -- Trend indicators for dashboard alerts
    CASE 
        WHEN mom_growth_pct < -10 THEN '🔴 Declining'
        WHEN mom_growth_pct < 0 THEN '🟡 Flat'
        WHEN mom_growth_pct < 10 THEN '🟢 Growing'
        ELSE '🚀 Strong Growth'
    END as trend_indicator
    
FROM revenue_with_trends
ORDER BY month DESC;

-- ============================================================================
-- SECTION 2: CUSTOMER METRICS DASHBOARD  
-- ============================================================================

-- 🎯 Key Business Question: "How are we acquiring and retaining customers?"

-- 2.1 Customer Acquisition Metrics
WITH monthly_customers AS (
    SELECT 
        DATE_TRUNC('MONTH', first_order_date) as acquisition_month,
        COUNT(*) as new_customers,
        SUM(first_order_value) as new_customer_revenue,
        ROUND(AVG(first_order_value), 2) as avg_first_order_value
    FROM (
        SELECT 
            customer_id,
            MIN(order_date) as first_order_date,
            MIN(total_amount) as first_order_value
        FROM orders
        GROUP BY customer_id
    ) first_orders
    WHERE first_order_date >= DATE_TRUNC('MONTH', CURRENT_DATE) - INTERVAL '12 MONTHS'
    GROUP BY DATE_TRUNC('MONTH', first_order_date)
)
SELECT 
    TO_CHAR(acquisition_month, 'YYYY-MM') as month,
    new_customers,
    LAG(new_customers, 1) OVER (ORDER BY acquisition_month) as prev_month_customers,
    ROUND(
        (new_customers - LAG(new_customers, 1) OVER (ORDER BY acquisition_month)) * 100.0 / 
        NULLIF(LAG(new_customers, 1) OVER (ORDER BY acquisition_month), 0), 2
    ) as customer_acquisition_growth_pct,
    new_customer_revenue,
    avg_first_order_value,
    
    -- Customer acquisition efficiency indicators
    CASE 
        WHEN new_customers > LAG(new_customers, 1) OVER (ORDER BY acquisition_month) THEN '📈 Improving'
        WHEN new_customers = LAG(new_customers, 1) OVER (ORDER BY acquisition_month) THEN '➡️ Stable'  
        ELSE '📉 Declining'
    END as acquisition_trend
    
FROM monthly_customers
ORDER BY acquisition_month DESC;

-- 2.2 Customer Retention Analysis  
WITH customer_monthly_activity AS (
    SELECT 
        customer_id,
        DATE_TRUNC('MONTH', order_date) as month,
        SUM(total_amount) as monthly_spend,
        COUNT(*) as monthly_orders
    FROM orders
    WHERE order_date >= DATE_TRUNC('MONTH', CURRENT_DATE) - INTERVAL '6 MONTHS'
    GROUP BY customer_id, DATE_TRUNC('MONTH', order_date)
),
retention_cohorts AS (
    SELECT 
        month,
        COUNT(DISTINCT customer_id) as active_customers,
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM customer_monthly_activity cma2 
                WHERE cma2.customer_id = cma.customer_id 
                AND cma2.month = cma.month - INTERVAL '1 MONTH'
            ) THEN customer_id 
        END) as retained_customers,
        
        -- New customers this month
        COUNT(DISTINCT CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM customer_monthly_activity cma2 
                WHERE cma2.customer_id = cma.customer_id 
                AND cma2.month < cma.month
            ) THEN customer_id 
        END) as new_customers
    FROM customer_monthly_activity cma
    GROUP BY month
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') as month,
    active_customers,
    retained_customers,
    new_customers,
    active_customers - retained_customers - new_customers as reactivated_customers,
    
    -- Retention rate calculation
    ROUND(
        retained_customers * 100.0 / 
        NULLIF(LAG(active_customers, 1) OVER (ORDER BY month), 0), 2
    ) as retention_rate_pct,
    
    -- Customer health indicator
    CASE 
        WHEN retained_customers * 100.0 / NULLIF(LAG(active_customers, 1) OVER (ORDER BY month), 0) >= 80 
        THEN '🟢 Healthy'
        WHEN retained_customers * 100.0 / NULLIF(LAG(active_customers, 1) OVER (ORDER BY month), 0) >= 70 
        THEN '🟡 At Risk'
        ELSE '🔴 Concerning'
    END as retention_health
    
FROM retention_cohorts
ORDER BY month DESC;

-- ============================================================================
-- SECTION 3: OPERATIONAL EFFICIENCY METRICS
-- ============================================================================

-- 🎯 Key Business Question: "How efficiently are we operating the business?"

-- 3.1 Sales Performance by Territory/Rep  
SELECT 
    sr.territory,
    sr.sales_rep_name,
    COUNT(DISTINCT o.order_id) as orders_count,
    ROUND(SUM(o.total_amount), 0) as total_revenue,
    ROUND(AVG(o.total_amount), 2) as avg_order_value,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    
    -- Performance vs territory average
    ROUND(
        SUM(o.total_amount) - AVG(SUM(o.total_amount)) OVER (PARTITION BY sr.territory), 0
    ) as vs_territory_avg,
    
    -- Rank within territory
    ROW_NUMBER() OVER (PARTITION BY sr.territory ORDER BY SUM(o.total_amount) DESC) as territory_rank,
    
    -- Performance indicators
    CASE 
        WHEN SUM(o.total_amount) > AVG(SUM(o.total_amount)) OVER (PARTITION BY sr.territory) * 1.2 
        THEN '⭐ Top Performer'
        WHEN SUM(o.total_amount) > AVG(SUM(o.total_amount)) OVER (PARTITION BY sr.territory) 
        THEN '✅ Above Average'
        WHEN SUM(o.total_amount) > AVG(SUM(o.total_amount)) OVER (PARTITION BY sr.territory) * 0.8 
        THEN '➡️ Average'
        ELSE '⚠️ Needs Attention'
    END as performance_status
    
FROM orders o
JOIN sales_reps sr ON o.sales_rep_id = sr.sales_rep_id
WHERE o.order_date >= DATE_TRUNC('MONTH', CURRENT_DATE) - INTERVAL '3 MONTHS'
GROUP BY sr.territory, sr.sales_rep_name, sr.sales_rep_id
ORDER BY sr.territory, total_revenue DESC;

-- ============================================================================
-- SECTION 4: EXECUTIVE SUMMARY & ALERTS
-- ============================================================================

-- 🎯 Key Business Question: "What needs immediate executive attention?"

-- 4.1 Executive Alert Dashboard
WITH current_month_metrics AS (
    SELECT 
        'Revenue Performance' as metric_category,
        COALESCE(SUM(total_amount), 0) as current_value,
        'Monthly Revenue Target' as comparison_basis,
        500000 as target_value, -- This would come from targets table
        'USD' as unit
    FROM orders 
    WHERE order_date >= DATE_TRUNC('MONTH', CURRENT_DATE)
    
    UNION ALL
    
    SELECT 
        'Customer Acquisition' as metric_category,
        COUNT(DISTINCT customer_id) as current_value,
        'Monthly Customer Target' as comparison_basis,
        150 as target_value, -- This would come from targets table  
        'Customers' as unit
    FROM orders
    WHERE order_date >= DATE_TRUNC('MONTH', CURRENT_DATE)
    AND customer_id IN (
        SELECT customer_id 
        FROM orders 
        GROUP BY customer_id 
        HAVING MIN(order_date) >= DATE_TRUNC('MONTH', CURRENT_DATE)
    )
)
SELECT 
    metric_category,
    current_value,
    target_value,
    unit,
    ROUND((current_value - target_value) * 100.0 / target_value, 1) as variance_pct,
    
    -- Alert level based on performance
    CASE 
        WHEN current_value >= target_value * 1.1 THEN '🟢 Exceeding Target'
        WHEN current_value >= target_value * 0.95 THEN '🟡 On Track'
        WHEN current_value >= target_value * 0.8 THEN '🟠 Below Target'
        ELSE '🔴 Critical - Needs Attention'
    END as alert_status,
    
    -- Recommended actions
    CASE 
        WHEN current_value < target_value * 0.8 THEN 'URGENT: Review strategy and resource allocation'
        WHEN current_value < target_value * 0.95 THEN 'Monitor closely and consider tactical adjustments'
        ELSE 'Continue current strategy'
    END as recommended_action
    
FROM current_month_metrics
ORDER BY variance_pct ASC;

-- ============================================================================
-- BUSINESS INSIGHTS & NEXT STEPS
-- ============================================================================

/*
🎯 KEY INSIGHTS FOR EXECUTIVE TEAM:

1. REVENUE PERFORMANCE:
   - Track actual vs projected monthly revenue
   - Monitor month-over-month and year-over-year growth trends
   - Identify any concerning patterns early

2. CUSTOMER HEALTH:
   - Customer acquisition rate and efficiency
   - Retention rates and churn patterns
   - New vs returning customer revenue mix

3. OPERATIONAL EFFICIENCY:
   - Sales team performance and territory analysis
   - Average order values and customer lifetime value
   - Resource allocation and productivity metrics

4. EARLY WARNING INDICATORS:
   - Revenue trend deviations from projections
   - Customer acquisition cost increases
   - Retention rate declines

💼 BUSINESS ACTIONS:
Based on this dashboard, executives can:
- Make informed decisions about resource allocation
- Identify underperforming areas requiring intervention
- Celebrate successes and replicate winning strategies
- Adjust quarterly forecasts and strategic plans

📊 DASHBOARD REFRESH:
This dashboard should be refreshed every Monday morning at 6:00 AM
to ensure data is current for the 9:00 AM executive meeting.

🔄 NEXT STEPS:
1. Automate dashboard refresh schedule
2. Add drill-down capabilities for deeper analysis
3. Include external market indicators for context
4. Develop predictive forecasting components
*/
