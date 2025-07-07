/*
Marketing Attribution Analysis
=============================

This script analyzes marketing attribution to understand which channels
are driving the most valuable customers and conversions.

Business Focus: Marketing ROI, Channel Optimization, Attribution Modeling
Author: SQL Analyst Pack
*/

-- Marketing Channel Performance Summary
-- Shows overall performance metrics by marketing channel

WITH channel_performance AS (
    SELECT 
        c.acquisition_channel,
        COUNT(DISTINCT c.customer_id) as customers_acquired,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(o.order_total) as total_revenue,
        AVG(o.order_total) as avg_order_value,
        SUM(o.order_total) / COUNT(DISTINCT c.customer_id) as customer_lifetime_value,
        COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT c.customer_id) as orders_per_customer
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.acquisition_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY c.acquisition_channel
),
channel_costs AS (
    SELECT 
        channel_name,
        SUM(daily_spend) as total_spend
    FROM marketing_spend
    WHERE spend_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY channel_name
)
SELECT 
    cp.acquisition_channel,
    cp.customers_acquired,
    cp.total_orders,
    cp.total_revenue,
    cp.avg_order_value,
    cp.customer_lifetime_value,
    cp.orders_per_customer,
    COALESCE(cc.total_spend, 0) as marketing_spend,
    CASE 
        WHEN cc.total_spend > 0 THEN cp.total_revenue / cc.total_spend
        ELSE NULL 
    END as roas, -- Return on Ad Spend
    CASE 
        WHEN cc.total_spend > 0 THEN cc.total_spend / cp.customers_acquired
        ELSE NULL 
    END as customer_acquisition_cost
FROM channel_performance cp
LEFT JOIN channel_costs cc ON cp.acquisition_channel = cc.channel_name
ORDER BY cp.total_revenue DESC;

-- First-Touch vs Last-Touch Attribution Analysis
-- Compares revenue attribution between first and last marketing touchpoints

WITH customer_touchpoints AS (
    SELECT 
        customer_id,
        channel,
        touchpoint_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY touchpoint_date ASC) as first_touch_rank,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY touchpoint_date DESC) as last_touch_rank
    FROM marketing_touchpoints
    WHERE touchpoint_date >= CURRENT_DATE - INTERVAL '12 months'
),
first_touch AS (
    SELECT customer_id, channel as first_touch_channel
    FROM customer_touchpoints 
    WHERE first_touch_rank = 1
),
last_touch AS (
    SELECT customer_id, channel as last_touch_channel
    FROM customer_touchpoints 
    WHERE last_touch_rank = 1
),
customer_revenue AS (
    SELECT 
        customer_id,
        SUM(order_total) as total_revenue
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY customer_id
)
SELECT 
    'First Touch Attribution' as attribution_model,
    ft.first_touch_channel as channel,
    COUNT(DISTINCT ft.customer_id) as customers,
    SUM(cr.total_revenue) as attributed_revenue,
    AVG(cr.total_revenue) as avg_revenue_per_customer
FROM first_touch ft
JOIN customer_revenue cr ON ft.customer_id = cr.customer_id
GROUP BY ft.first_touch_channel

UNION ALL

SELECT 
    'Last Touch Attribution' as attribution_model,
    lt.last_touch_channel as channel,
    COUNT(DISTINCT lt.customer_id) as customers,
    SUM(cr.total_revenue) as attributed_revenue,
    AVG(cr.total_revenue) as avg_revenue_per_customer
FROM last_touch lt
JOIN customer_revenue cr ON lt.customer_id = cr.customer_id
GROUP BY lt.last_touch_channel

ORDER BY attribution_model, attributed_revenue DESC;

-- Campaign Performance Deep Dive
-- Analyzes individual campaign performance with conversion funnel metrics

SELECT 
    c.campaign_name,
    c.campaign_type,
    c.start_date,
    c.end_date,
    c.budget,
    
    -- Reach and Engagement Metrics
    SUM(cm.impressions) as total_impressions,
    SUM(cm.clicks) as total_clicks,
    SUM(cm.clicks) * 100.0 / NULLIF(SUM(cm.impressions), 0) as click_through_rate,
    
    -- Conversion Metrics
    COUNT(DISTINCT o.customer_id) as customers_converted,
    COUNT(DISTINCT o.order_id) as total_conversions,
    SUM(o.order_total) as total_revenue,
    
    -- Efficiency Metrics
    c.budget / NULLIF(COUNT(DISTINCT o.customer_id), 0) as cost_per_acquisition,
    SUM(o.order_total) / NULLIF(c.budget, 0) as return_on_ad_spend,
    
    -- Conversion Funnel
    SUM(cm.clicks) * 100.0 / NULLIF(COUNT(DISTINCT o.customer_id), 0) as clicks_to_customer_ratio

FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
LEFT JOIN orders o ON cm.customer_id = o.customer_id 
    AND o.order_date BETWEEN c.start_date AND c.end_date + INTERVAL '7 days' -- 7-day attribution window
WHERE c.start_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY c.campaign_id, c.campaign_name, c.campaign_type, c.start_date, c.end_date, c.budget
ORDER BY return_on_ad_spend DESC;

-- Cohort Analysis by Acquisition Channel
-- Analyzes customer retention by acquisition channel

WITH monthly_cohorts AS (
    SELECT 
        c.customer_id,
        c.acquisition_channel,
        DATE_TRUNC('month', c.acquisition_date) as cohort_month,
        DATE_TRUNC('month', o.order_date) as order_month,
        EXTRACT(EPOCH FROM (DATE_TRUNC('month', o.order_date) - DATE_TRUNC('month', c.acquisition_date))) / (60*60*24*30) as months_since_acquisition
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.acquisition_date >= CURRENT_DATE - INTERVAL '12 months'
),
cohort_data AS (
    SELECT 
        acquisition_channel,
        cohort_month,
        months_since_acquisition,
        COUNT(DISTINCT customer_id) as customers
    FROM monthly_cohorts
    WHERE months_since_acquisition >= 0 AND months_since_acquisition <= 11
    GROUP BY acquisition_channel, cohort_month, months_since_acquisition
),
cohort_sizes AS (
    SELECT 
        acquisition_channel,
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM customers
    WHERE acquisition_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY acquisition_channel, DATE_TRUNC('month', acquisition_date)
)
SELECT 
    cd.acquisition_channel,
    cd.cohort_month,
    cs.cohort_size,
    cd.months_since_acquisition,
    cd.customers as active_customers,
    cd.customers * 100.0 / cs.cohort_size as retention_rate
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.acquisition_channel = cs.acquisition_channel 
    AND cd.cohort_month = cs.cohort_month
ORDER BY cd.acquisition_channel, cd.cohort_month, cd.months_since_acquisition;

-- Cross-Channel Customer Journey Analysis
-- Maps the customer journey across multiple marketing touchpoints

WITH customer_journeys AS (
    SELECT 
        mt.customer_id,
        STRING_AGG(mt.channel, ' -> ' ORDER BY mt.touchpoint_date) as customer_journey,
        COUNT(*) as touchpoint_count,
        MIN(mt.touchpoint_date) as first_touchpoint,
        MAX(mt.touchpoint_date) as last_touchpoint,
        MAX(mt.touchpoint_date) - MIN(mt.touchpoint_date) as journey_duration_days
    FROM marketing_touchpoints mt
    WHERE mt.touchpoint_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY mt.customer_id
),
journey_performance AS (
    SELECT 
        cj.customer_journey,
        cj.touchpoint_count,
        AVG(cj.journey_duration_days) as avg_journey_duration,
        COUNT(DISTINCT cj.customer_id) as customers,
        COUNT(DISTINCT o.customer_id) as converted_customers,
        COUNT(DISTINCT o.customer_id) * 100.0 / COUNT(DISTINCT cj.customer_id) as conversion_rate,
        SUM(o.order_total) as total_revenue,
        AVG(o.order_total) as avg_order_value
    FROM customer_journeys cj
    LEFT JOIN orders o ON cj.customer_id = o.customer_id
        AND o.order_date BETWEEN cj.first_touchpoint AND cj.last_touchpoint + INTERVAL '30 days'
    GROUP BY cj.customer_journey, cj.touchpoint_count
    HAVING COUNT(DISTINCT cj.customer_id) >= 10 -- Only show journeys with meaningful sample size
)
SELECT 
    customer_journey,
    touchpoint_count,
    customers,
    converted_customers,
    conversion_rate,
    total_revenue,
    avg_order_value,
    avg_journey_duration
FROM journey_performance
ORDER BY total_revenue DESC, conversion_rate DESC
LIMIT 20;

-- Marketing Mix Modeling - Channel Interaction Analysis
-- Analyzes how different marketing channels work together

WITH weekly_metrics AS (
    SELECT 
        DATE_TRUNC('week', spend_date) as week,
        channel_name,
        SUM(daily_spend) as weekly_spend,
        SUM(impressions) as weekly_impressions
    FROM marketing_spend
    WHERE spend_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('week', spend_date), channel_name
),
weekly_conversions AS (
    SELECT 
        DATE_TRUNC('week', o.order_date) as week,
        c.acquisition_channel,
        COUNT(DISTINCT o.order_id) as weekly_orders,
        SUM(o.order_total) as weekly_revenue
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('week', o.order_date), c.acquisition_channel
),
channel_combinations AS (
    SELECT 
        wm.week,
        COUNT(DISTINCT wm.channel_name) as active_channels,
        STRING_AGG(wm.channel_name, ', ' ORDER BY wm.weekly_spend DESC) as channel_mix,
        SUM(wm.weekly_spend) as total_weekly_spend
    FROM weekly_metrics wm
    WHERE wm.weekly_spend > 0
    GROUP BY wm.week
)
SELECT 
    cc.active_channels,
    cc.channel_mix,
    COUNT(*) as weeks_active,
    AVG(cc.total_weekly_spend) as avg_weekly_spend,
    AVG(wc.weekly_orders) as avg_weekly_orders,
    AVG(wc.weekly_revenue) as avg_weekly_revenue,
    AVG(wc.weekly_revenue) / AVG(cc.total_weekly_spend) as avg_roas
FROM channel_combinations cc
LEFT JOIN weekly_conversions wc ON cc.week = wc.week
GROUP BY cc.active_channels, cc.channel_mix
HAVING COUNT(*) >= 4 -- At least 4 weeks of data
ORDER BY avg_roas DESC;

/*
Business Insights from Marketing Attribution Analysis:

1. Channel Performance: Identify which marketing channels deliver the highest ROI
2. Attribution Modeling: Compare first-touch vs last-touch to understand customer journey value
3. Campaign Optimization: Analyze individual campaign performance for budget allocation
4. Customer Retention: Track how different acquisition channels affect long-term customer value
5. Journey Mapping: Understand multi-channel customer paths to optimize touchpoint strategy
6. Channel Synergy: Identify which combinations of marketing channels work best together

Key Metrics to Monitor:
- Customer Acquisition Cost (CAC) by channel
- Return on Ad Spend (ROAS) by campaign
- Customer Lifetime Value (CLV) by acquisition channel
- Attribution-adjusted revenue by touchpoint
- Cross-channel conversion rates
- Retention rates by cohort and channel

This analysis helps marketing teams allocate budgets more effectively and optimize
the customer acquisition funnel across all marketing channels.
*/
