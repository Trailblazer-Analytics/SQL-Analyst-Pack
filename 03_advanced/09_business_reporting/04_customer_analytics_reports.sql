/*
================================================================================
File: 03_advanced/09_business_reporting/04_customer_analytics_reports.sql
Topic: Customer Analytics and Lifetime Value Reporting
Purpose: Build comprehensive customer analytics reports for marketing and sales
Author: SQL Analyst Pack Community
Created: 2025-07-06
Database: Multi-platform compatible
================================================================================

CUSTOMER ANALYTICS REPORTING:
This script creates comprehensive customer analytics reports that help
marketing and sales teams understand customer behavior, lifetime value,
and segmentation for strategic decision making.

TARGET USERS:
- Marketing Directors and Campaign Managers
- Sales VPs and Account Managers
- Customer Success Teams
- Executive Leadership

KEY CUSTOMER REPORTS:
- Customer lifetime value analysis
- Customer segmentation and behavior
- Retention and churn analysis
- Customer acquisition metrics
- Revenue concentration analysis
================================================================================
*/

-- ============================================================================
-- SECTION 1: CUSTOMER LIFETIME VALUE ANALYSIS
-- ============================================================================

-- Comprehensive Customer LTV Analysis
WITH customer_metrics AS (
    SELECT 
        customer_id,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        COUNT(*) as total_orders,
        SUM(order_total) as lifetime_value,
        AVG(order_total) as avg_order_value,
        
        -- Calculate customer age in days
        CURRENT_DATE - MIN(order_date) as customer_age_days,
        MAX(order_date) - MIN(order_date) as active_period_days,
        
        -- Recency analysis
        CURRENT_DATE - MAX(order_date) as days_since_last_order
    FROM orders 
    GROUP BY customer_id
),

customer_ltv_segments AS (
    SELECT *,
        -- Calculate monthly revenue rate
        CASE 
            WHEN customer_age_days > 0 THEN 
                lifetime_value / (customer_age_days / 30.0)
            ELSE lifetime_value
        END as monthly_revenue_rate,
        
        -- LTV Segmentation
        NTILE(5) OVER (ORDER BY lifetime_value DESC) as ltv_quintile,
        
        -- Customer Lifecycle Stage
        CASE 
            WHEN days_since_last_order <= 30 THEN 'Active'
            WHEN days_since_last_order <= 90 THEN 'At Risk'
            WHEN days_since_last_order <= 180 THEN 'Dormant' 
            ELSE 'Lost'
        END as lifecycle_stage,
        
        -- Value Tier Classification
        CASE 
            WHEN lifetime_value >= 5000 THEN 'VIP'
            WHEN lifetime_value >= 2000 THEN 'High Value'
            WHEN lifetime_value >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END as value_tier
    FROM customer_metrics
)

-- Customer LTV Dashboard
SELECT 
    '👥 CUSTOMER LIFETIME VALUE ANALYSIS' as analytics_dashboard,
    
    -- Customer Segmentation Summary
    value_tier,
    lifecycle_stage,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_ltv,
    ROUND(SUM(lifetime_value), 2) as total_revenue,
    ROUND(AVG(total_orders), 1) as avg_orders_per_customer,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    ROUND(AVG(monthly_revenue_rate), 2) as avg_monthly_rate,
    
    -- Customer Distribution
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as customer_percentage,
    ROUND(SUM(lifetime_value) * 100.0 / SUM(SUM(lifetime_value)) OVER (), 2) as revenue_percentage,
    
    -- Strategic Insights
    CASE 
        WHEN value_tier = 'VIP' AND lifecycle_stage = 'At Risk' 
        THEN '🚨 HIGH VALUE CUSTOMER AT RISK'
        WHEN value_tier = 'VIP' AND lifecycle_stage = 'Active' 
        THEN '🌟 VIP CUSTOMERS - MAINTAIN EXCELLENCE'
        WHEN value_tier IN ('High Value', 'Medium Value') AND lifecycle_stage = 'Lost'
        THEN '🎯 WIN-BACK CAMPAIGN OPPORTUNITY'
        WHEN value_tier = 'Low Value' AND lifecycle_stage = 'Active'
        THEN '📈 GROWTH POTENTIAL - UPSELL OPPORTUNITY'
        ELSE '✅ MONITOR REGULAR ENGAGEMENT'
    END as strategic_action
    
FROM customer_ltv_segments
GROUP BY value_tier, lifecycle_stage
ORDER BY 
    CASE value_tier 
        WHEN 'VIP' THEN 1 
        WHEN 'High Value' THEN 2 
        WHEN 'Medium Value' THEN 3 
        ELSE 4 
    END,
    CASE lifecycle_stage 
        WHEN 'Active' THEN 1 
        WHEN 'At Risk' THEN 2 
        WHEN 'Dormant' THEN 3 
        ELSE 4 
    END;

-- ============================================================================
-- SECTION 2: CUSTOMER RETENTION AND CHURN ANALYSIS  
-- ============================================================================

-- Monthly Cohort Retention Analysis
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month,
        MIN(order_date) as first_order_date
    FROM orders 
    GROUP BY customer_id
),

monthly_activity AS (
    SELECT 
        c.customer_id,
        c.cohort_month,
        DATE_TRUNC('month', o.order_date) as activity_month,
        SUM(o.order_total) as monthly_revenue
    FROM customer_cohorts c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.cohort_month, DATE_TRUNC('month', o.order_date)
),

cohort_analysis AS (
    SELECT 
        cohort_month,
        activity_month,
        COUNT(DISTINCT customer_id) as active_customers,
        SUM(monthly_revenue) as cohort_revenue,
        
        -- Calculate period number (0 = acquisition month, 1 = month 1, etc.)
        EXTRACT(YEAR FROM activity_month) * 12 + EXTRACT(MONTH FROM activity_month) -
        (EXTRACT(YEAR FROM cohort_month) * 12 + EXTRACT(MONTH FROM cohort_month)) as period_number
    FROM monthly_activity
    GROUP BY cohort_month, activity_month
),

cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(*) as cohort_size,
        SUM(monthly_revenue) as acquisition_revenue
    FROM monthly_activity
    WHERE cohort_month = activity_month
    GROUP BY cohort_month
)

-- Retention Dashboard
SELECT 
    '📊 CUSTOMER RETENTION ANALYSIS' as retention_dashboard,
    ca.cohort_month,
    cs.cohort_size as initial_customers,
    ca.period_number as months_after_acquisition,
    ca.active_customers,
    ca.cohort_revenue,
    
    -- Retention Rate
    ROUND(ca.active_customers * 100.0 / cs.cohort_size, 2) as retention_rate_pct,
    
    -- Revenue Retention
    ROUND(ca.cohort_revenue / cs.acquisition_revenue * 100, 2) as revenue_retention_pct,
    
    -- Cohort Performance Assessment
    CASE 
        WHEN ca.period_number = 1 AND ca.active_customers * 100.0 / cs.cohort_size > 80 
        THEN '🟢 EXCELLENT MONTH 1 RETENTION'
        WHEN ca.period_number = 3 AND ca.active_customers * 100.0 / cs.cohort_size > 60 
        THEN '🟢 STRONG QUARTER 1 RETENTION'
        WHEN ca.period_number = 6 AND ca.active_customers * 100.0 / cs.cohort_size > 40 
        THEN '🟡 MODERATE 6-MONTH RETENTION'
        WHEN ca.period_number = 12 AND ca.active_customers * 100.0 / cs.cohort_size > 25 
        THEN '🟡 ACCEPTABLE ANNUAL RETENTION'
        WHEN ca.period_number >= 6 AND ca.active_customers * 100.0 / cs.cohort_size < 20 
        THEN '🔴 LOW LONG-TERM RETENTION'
        ELSE '🟠 MONITOR RETENTION TRENDS'
    END as retention_assessment
    
FROM cohort_analysis ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
WHERE ca.cohort_month >= CURRENT_DATE - INTERVAL '12 months'
  AND ca.period_number <= 12
ORDER BY ca.cohort_month DESC, ca.period_number;

-- ============================================================================
-- SECTION 3: CUSTOMER ACQUISITION METRICS
-- ============================================================================

-- Customer Acquisition Analysis
WITH acquisition_metrics AS (
    SELECT 
        DATE_TRUNC('month', first_order_date) as acquisition_month,
        acquisition_channel,
        COUNT(*) as new_customers,
        SUM(first_order_value) as acquisition_revenue,
        AVG(first_order_value) as avg_first_order_value,
        SUM(total_acquisition_cost) as total_acquisition_cost
    FROM (
        SELECT 
            customer_id,
            MIN(order_date) as first_order_date,
            COALESCE(acquisition_channel, 'Unknown') as acquisition_channel,
            (SELECT order_total FROM orders WHERE customer_id = o.customer_id ORDER BY order_date LIMIT 1) as first_order_value,
            COALESCE(acquisition_cost, 50) as total_acquisition_cost  -- Default CAC if not tracked
        FROM orders o
        LEFT JOIN customer_acquisition ca ON o.customer_id = ca.customer_id
        GROUP BY customer_id, acquisition_channel, acquisition_cost
    ) first_orders
    GROUP BY DATE_TRUNC('month', first_order_date), acquisition_channel
),

ltv_by_channel AS (
    SELECT 
        acquisition_channel,
        AVG(lifetime_value) as avg_customer_ltv,
        COUNT(*) as total_customers
    FROM customer_ltv_segments cls
    LEFT JOIN customer_acquisition ca ON cls.customer_id = ca.customer_id
    GROUP BY acquisition_channel
)

-- Customer Acquisition Dashboard  
SELECT 
    '🎯 CUSTOMER ACQUISITION PERFORMANCE' as acquisition_dashboard,
    am.acquisition_month,
    am.acquisition_channel,
    am.new_customers,
    am.acquisition_revenue,
    ROUND(am.avg_first_order_value, 2) as avg_first_order,
    am.total_acquisition_cost,
    
    -- CAC and LTV Metrics
    ROUND(am.total_acquisition_cost / am.new_customers, 2) as cost_per_acquisition,
    ROUND(lbc.avg_customer_ltv, 2) as avg_channel_ltv,
    
    -- ROI Analysis
    ROUND(lbc.avg_customer_ltv / (am.total_acquisition_cost / am.new_customers), 2) as ltv_to_cac_ratio,
    ROUND((lbc.avg_customer_ltv - (am.total_acquisition_cost / am.new_customers)) * am.new_customers, 2) as net_channel_value,
    
    -- Channel Performance Assessment
    CASE 
        WHEN lbc.avg_customer_ltv / (am.total_acquisition_cost / am.new_customers) >= 3.0 
        THEN '🟢 EXCELLENT ROI - SCALE UP'
        WHEN lbc.avg_customer_ltv / (am.total_acquisition_cost / am.new_customers) >= 2.0 
        THEN '🟡 GOOD ROI - CONTINUE'
        WHEN lbc.avg_customer_ltv / (am.total_acquisition_cost / am.new_customers) >= 1.0 
        THEN '🟠 BREAK-EVEN - OPTIMIZE'
        ELSE '🔴 LOSING MONEY - PAUSE/FIX'
    END as channel_performance,
    
    -- Strategic Recommendations
    CASE 
        WHEN lbc.avg_customer_ltv / (am.total_acquisition_cost / am.new_customers) >= 3.0 
             AND am.new_customers < 100
        THEN '💡 HIGH ROI + LOW VOLUME: INCREASE INVESTMENT'
        WHEN lbc.avg_customer_ltv / (am.total_acquisition_cost / am.new_customers) < 1.5 
             AND am.new_customers > 200
        THEN '⚠️ LOW ROI + HIGH VOLUME: URGENT OPTIMIZATION NEEDED'
        WHEN am.avg_first_order_value > lbc.avg_customer_ltv * 0.8
        THEN '🔍 HIGH FIRST ORDER: INVESTIGATE RETENTION'
        ELSE '✅ BALANCED PERFORMANCE: MAINTAIN CURRENT APPROACH'
    END as strategic_recommendation

FROM acquisition_metrics am
LEFT JOIN ltv_by_channel lbc ON am.acquisition_channel = lbc.acquisition_channel
WHERE am.acquisition_month >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY am.acquisition_month DESC, net_channel_value DESC;

-- ============================================================================
-- SECTION 4: REVENUE CONCENTRATION AND RISK ANALYSIS
-- ============================================================================

-- Customer Revenue Concentration Analysis
WITH revenue_concentration AS (
    SELECT 
        customer_id,
        lifetime_value,
        ROW_NUMBER() OVER (ORDER BY lifetime_value DESC) as revenue_rank,
        SUM(lifetime_value) OVER () as total_company_revenue
    FROM customer_ltv_segments
),

concentration_analysis AS (
    SELECT 
        -- Top customer segments
        SUM(CASE WHEN revenue_rank <= 1 THEN lifetime_value ELSE 0 END) as top_1_customer_revenue,
        SUM(CASE WHEN revenue_rank <= 5 THEN lifetime_value ELSE 0 END) as top_5_customer_revenue,
        SUM(CASE WHEN revenue_rank <= 10 THEN lifetime_value ELSE 0 END) as top_10_customer_revenue,
        SUM(CASE WHEN revenue_rank <= 20 THEN lifetime_value ELSE 0 END) as top_20_customer_revenue,
        
        MAX(total_company_revenue) as total_revenue,
        COUNT(*) as total_customers
    FROM revenue_concentration
)

-- Revenue Concentration Dashboard
SELECT 
    '📊 REVENUE CONCENTRATION ANALYSIS' as concentration_dashboard,
    total_customers,
    total_revenue,
    
    -- Concentration Metrics
    top_1_customer_revenue,
    top_5_customer_revenue,
    top_10_customer_revenue,
    top_20_customer_revenue,
    
    -- Concentration Percentages
    ROUND(top_1_customer_revenue / total_revenue * 100, 2) as top_1_customer_pct,
    ROUND(top_5_customer_revenue / total_revenue * 100, 2) as top_5_customer_pct,
    ROUND(top_10_customer_revenue / total_revenue * 100, 2) as top_10_customer_pct,
    ROUND(top_20_customer_revenue / total_revenue * 100, 2) as top_20_customer_pct,
    
    -- Risk Assessment
    CASE 
        WHEN top_1_customer_revenue / total_revenue > 0.20 THEN '🔴 CRITICAL: Single Customer Risk'
        WHEN top_5_customer_revenue / total_revenue > 0.50 THEN '🟠 HIGH: Customer Concentration Risk'
        WHEN top_10_customer_revenue / total_revenue > 0.60 THEN '🟡 MODERATE: Monitor Top Customers'
        ELSE '🟢 LOW: Well Diversified Revenue'
    END as concentration_risk_level,
    
    -- Strategic Actions
    CASE 
        WHEN top_1_customer_revenue / total_revenue > 0.15 
        THEN '🎯 PRIORITY: Diversify customer base, reduce single customer dependency'
        WHEN top_5_customer_revenue / total_revenue > 0.40 
        THEN '💼 STRATEGY: Expand customer acquisition, retain top customers'
        WHEN top_20_customer_revenue / total_revenue < 0.30 
        THEN '🚀 OPPORTUNITY: Focus on growing mid-tier customers'
        ELSE '✅ BALANCED: Maintain current customer portfolio approach'
    END as strategic_action_required

FROM concentration_analysis;

/*
================================================================================
CUSTOMER ANALYTICS AUTOMATION NOTES:
================================================================================

RECOMMENDED REPORTING SCHEDULE:
- Weekly: Customer acquisition metrics and alerts
- Monthly: LTV analysis and retention dashboard
- Quarterly: Cohort analysis and strategic review
- Annually: Complete customer portfolio assessment

KEY BUSINESS INSIGHTS:
- Identify high-value customers at risk of churn
- Optimize customer acquisition channel investment
- Monitor customer concentration risk
- Track lifetime value trends by segment

ACTIONABLE OUTPUTS:
- Customer lists for targeted retention campaigns
- Channel performance data for marketing budget allocation
- Early warning alerts for customer concentration risk
- LTV projections for financial planning

INTEGRATION OPPORTUNITIES:
- Export VIP customer lists to CRM systems
- Trigger automated retention campaigns for at-risk customers
- Feed LTV data into marketing attribution models
- Create executive dashboards with real-time customer metrics
================================================================================
*/
