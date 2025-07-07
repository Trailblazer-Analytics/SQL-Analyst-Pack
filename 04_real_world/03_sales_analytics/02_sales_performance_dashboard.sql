/*
Sales Performance Dashboard
==========================

This script creates comprehensive sales performance metrics and KPIs
for sales managers and business analysts.

Business Focus: Sales Performance, Territory Analysis, Rep Performance
Author: SQL Analyst Pack
*/

-- Overall Sales Performance Summary
-- Key metrics for executive dashboard

SELECT 
    -- Current Period Metrics (Last 30 Days)
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(order_total) as total_revenue,
    AVG(order_total) as average_order_value,
    
    -- Previous Period Metrics (30-60 Days Ago)
    (SELECT COUNT(DISTINCT order_id) 
     FROM orders 
     WHERE order_date >= date('now', '-60 days') 
     AND order_date < date('now', '-30 days')) as prev_total_orders,
    
    (SELECT SUM(order_total) 
     FROM orders 
     WHERE order_date >= date('now', '-60 days') 
     AND order_date < date('now', '-30 days')) as prev_total_revenue,
    
    -- Growth Calculations
    ROUND(((SUM(order_total) - 
           (SELECT SUM(order_total) 
            FROM orders 
            WHERE order_date >= date('now', '-60 days') 
            AND order_date < date('now', '-30 days'))) / 
           NULLIF((SELECT SUM(order_total) 
                   FROM orders 
                   WHERE order_date >= date('now', '-60 days') 
                   AND order_date < date('now', '-30 days')), 0)) * 100, 2) as revenue_growth_pct

FROM orders 
WHERE order_date >= date('now', '-30 days');

-- Daily Sales Trend Analysis
-- Shows daily sales performance with moving averages

WITH daily_sales AS (
    SELECT 
        date(order_date) as sale_date,
        COUNT(*) as daily_orders,
        SUM(order_total) as daily_revenue,
        AVG(order_total) as daily_avg_order_value
    FROM orders
    WHERE order_date >= date('now', '-90 days')
    GROUP BY date(order_date)
),
sales_with_trends AS (
    SELECT 
        sale_date,
        daily_orders,
        daily_revenue,
        daily_avg_order_value,
        
        -- 7-day moving average
        AVG(daily_revenue) OVER (
            ORDER BY sale_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as revenue_7day_ma,
        
        -- Week-over-week growth
        LAG(daily_revenue, 7) OVER (ORDER BY sale_date) as revenue_7days_ago,
        
        -- Day of week analysis
        CASE strftime('%w', sale_date)
            WHEN '0' THEN 'Sunday'
            WHEN '1' THEN 'Monday'
            WHEN '2' THEN 'Tuesday'
            WHEN '3' THEN 'Wednesday'
            WHEN '4' THEN 'Thursday'
            WHEN '5' THEN 'Friday'
            WHEN '6' THEN 'Saturday'
        END as day_of_week
    FROM daily_sales
)
SELECT 
    sale_date,
    daily_orders,
    daily_revenue,
    daily_avg_order_value,
    revenue_7day_ma,
    day_of_week,
    CASE 
        WHEN revenue_7days_ago > 0 THEN 
            ROUND(((daily_revenue - revenue_7days_ago) / revenue_7days_ago) * 100, 2)
        ELSE NULL 
    END as week_over_week_growth_pct
FROM sales_with_trends
ORDER BY sale_date DESC
LIMIT 30;

-- Sales Rep Performance Analysis
-- Individual sales representative performance metrics

WITH rep_performance AS (
    SELECT 
        sr.rep_id,
        sr.rep_name,
        sr.territory,
        sr.hire_date,
        
        -- Current Period (Last 30 Days)
        COUNT(DISTINCT o.order_id) as orders_count,
        SUM(o.order_total) as total_sales,
        AVG(o.order_total) as avg_deal_size,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        
        -- Pipeline metrics
        (SELECT COUNT(*) 
         FROM opportunities opp 
         WHERE opp.assigned_rep_id = sr.rep_id 
         AND opp.stage IN ('Proposal', 'Negotiation')) as active_opportunities,
        
        (SELECT SUM(opp.estimated_value) 
         FROM opportunities opp 
         WHERE opp.assigned_rep_id = sr.rep_id 
         AND opp.stage IN ('Proposal', 'Negotiation')) as pipeline_value
        
    FROM sales_reps sr
    LEFT JOIN orders o ON sr.rep_id = o.assigned_rep_id
        AND o.order_date >= date('now', '-30 days')
    GROUP BY sr.rep_id, sr.rep_name, sr.territory, sr.hire_date
),
territory_averages AS (
    SELECT 
        territory,
        AVG(total_sales) as territory_avg_sales
    FROM rep_performance
    GROUP BY territory
)
SELECT 
    rp.rep_id,
    rp.rep_name,
    rp.territory,
    rp.orders_count,
    rp.total_sales,
    rp.avg_deal_size,
    rp.unique_customers,
    rp.active_opportunities,
    rp.pipeline_value,
    ta.territory_avg_sales,
    
    -- Performance vs Territory Average
    CASE 
        WHEN ta.territory_avg_sales > 0 THEN 
            ROUND((rp.total_sales / ta.territory_avg_sales) * 100, 1)
        ELSE 0 
    END as performance_vs_territory_avg,
    
    -- Rep tenure
    ROUND((julianday('now') - julianday(rp.hire_date)) / 365.25, 1) as years_tenure,
    
    -- Performance rating
    CASE 
        WHEN rp.total_sales >= ta.territory_avg_sales * 1.2 THEN 'Excellent'
        WHEN rp.total_sales >= ta.territory_avg_sales * 1.0 THEN 'Good'
        WHEN rp.total_sales >= ta.territory_avg_sales * 0.8 THEN 'Needs Improvement'
        ELSE 'Underperforming'
    END as performance_rating

FROM rep_performance rp
LEFT JOIN territory_averages ta ON rp.territory = ta.territory
ORDER BY rp.total_sales DESC;

-- Product Sales Analysis
-- Product performance metrics and trends

SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    
    -- Sales Metrics
    SUM(oi.quantity) as units_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    COUNT(DISTINCT oi.order_id) as orders_containing_product,
    
    -- Performance Metrics
    AVG(oi.quantity) as avg_quantity_per_order,
    SUM(oi.quantity * oi.unit_price) / SUM(oi.quantity) as avg_selling_price,
    
    -- Market Share within Category
    SUM(oi.quantity * oi.unit_price) * 100.0 / 
        (SELECT SUM(oi2.quantity * oi2.unit_price) 
         FROM order_items oi2 
         JOIN products p2 ON oi2.product_id = p2.product_id 
         JOIN orders o2 ON oi2.order_id = o2.order_id
         WHERE p2.category = p.category 
         AND o2.order_date >= date('now', '-30 days')) as category_market_share_pct,
    
    -- Trend Analysis (Last 7 vs Previous 7 Days)
    (SELECT SUM(oi3.quantity * oi3.unit_price)
     FROM order_items oi3
     JOIN orders o3 ON oi3.order_id = o3.order_id
     WHERE oi3.product_id = p.product_id
     AND o3.order_date >= date('now', '-7 days')) as last_7_days_revenue,
     
    (SELECT SUM(oi4.quantity * oi4.unit_price)
     FROM order_items oi4
     JOIN orders o4 ON oi4.order_id = o4.order_id
     WHERE oi4.product_id = p.product_id
     AND o4.order_date >= date('now', '-14 days')
     AND o4.order_date < date('now', '-7 days')) as prev_7_days_revenue

FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date >= date('now', '-30 days')
GROUP BY p.product_id, p.product_name, p.category, p.unit_price
ORDER BY total_revenue DESC
LIMIT 50;

-- Customer Segment Sales Analysis
-- Sales performance by customer segments

WITH customer_segments AS (
    SELECT 
        customer_id,
        SUM(order_total) as lifetime_value,
        COUNT(*) as order_count,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        
        -- Segmentation Logic
        CASE 
            WHEN SUM(order_total) >= 5000 THEN 'VIP'
            WHEN SUM(order_total) >= 1000 THEN 'High Value'
            WHEN SUM(order_total) >= 250 THEN 'Medium Value'
            ELSE 'Low Value'
        END as customer_segment,
        
        CASE 
            WHEN COUNT(*) >= 10 THEN 'Frequent'
            WHEN COUNT(*) >= 3 THEN 'Regular'
            ELSE 'Occasional'
        END as purchase_frequency
        
    FROM orders
    GROUP BY customer_id
),
segment_performance AS (
    SELECT 
        cs.customer_segment,
        cs.purchase_frequency,
        COUNT(DISTINCT cs.customer_id) as customer_count,
        
        -- Recent Performance (Last 30 Days)
        COUNT(DISTINCT CASE 
            WHEN o.order_date >= date('now', '-30 days') 
            THEN o.order_id END) as recent_orders,
        SUM(CASE 
            WHEN o.order_date >= date('now', '-30 days') 
            THEN o.order_total ELSE 0 END) as recent_revenue,
        
        -- Average Metrics
        AVG(cs.lifetime_value) as avg_lifetime_value,
        AVG(cs.order_count) as avg_order_frequency,
        
        -- Retention Metrics
        COUNT(DISTINCT CASE 
            WHEN o.order_date >= date('now', '-30 days') 
            THEN cs.customer_id END) * 100.0 / 
            COUNT(DISTINCT cs.customer_id) as retention_rate_30d
            
    FROM customer_segments cs
    LEFT JOIN orders o ON cs.customer_id = o.customer_id
    GROUP BY cs.customer_segment, cs.purchase_frequency
)
SELECT 
    customer_segment,
    purchase_frequency,
    customer_count,
    recent_orders,
    recent_revenue,
    avg_lifetime_value,
    avg_order_frequency,
    retention_rate_30d,
    
    -- Revenue per Customer Segment
    recent_revenue / NULLIF(customer_count, 0) as revenue_per_customer,
    
    -- Segment Contribution
    recent_revenue * 100.0 / 
        (SELECT SUM(recent_revenue) FROM segment_performance) as segment_revenue_contribution_pct

FROM segment_performance
ORDER BY recent_revenue DESC;

-- Sales Forecast Based on Historical Trends
-- Simple trend-based sales forecasting

WITH monthly_sales AS (
    SELECT 
        strftime('%Y-%m', order_date) as month,
        SUM(order_total) as monthly_revenue,
        COUNT(*) as monthly_orders
    FROM orders
    WHERE order_date >= date('now', '-12 months')
    GROUP BY strftime('%Y-%m', order_date)
    ORDER BY month
),
sales_with_growth AS (
    SELECT 
        month,
        monthly_revenue,
        monthly_orders,
        LAG(monthly_revenue, 1) OVER (ORDER BY month) as prev_month_revenue,
        LAG(monthly_revenue, 12) OVER (ORDER BY month) as same_month_last_year
    FROM monthly_sales
),
growth_rates AS (
    SELECT 
        month,
        monthly_revenue,
        
        -- Month-over-month growth
        CASE 
            WHEN prev_month_revenue > 0 THEN 
                (monthly_revenue - prev_month_revenue) / prev_month_revenue
            ELSE 0 
        END as mom_growth_rate,
        
        -- Year-over-year growth
        CASE 
            WHEN same_month_last_year > 0 THEN 
                (monthly_revenue - same_month_last_year) / same_month_last_year
            ELSE 0 
        END as yoy_growth_rate
        
    FROM sales_with_growth
    WHERE prev_month_revenue IS NOT NULL
)
SELECT 
    month,
    monthly_revenue,
    ROUND(mom_growth_rate * 100, 2) as mom_growth_pct,
    ROUND(yoy_growth_rate * 100, 2) as yoy_growth_pct,
    
    -- Simple forecast for next month (based on average growth)
    ROUND(monthly_revenue * (1 + (
        SELECT AVG(mom_growth_rate) 
        FROM growth_rates 
        WHERE month >= date('now', '-6 months', 'start of month')
    )), 0) as next_month_forecast,
    
    -- Trend indicator
    CASE 
        WHEN mom_growth_rate > 0.05 THEN 'Strong Growth'
        WHEN mom_growth_rate > 0 THEN 'Moderate Growth'
        WHEN mom_growth_rate > -0.05 THEN 'Stable'
        ELSE 'Declining'
    END as trend_status

FROM growth_rates
ORDER BY month DESC
LIMIT 12;

/*
Business Insights from Sales Performance Analysis:

1. Executive Dashboard: Monitor key sales metrics and growth rates
2. Daily Trends: Identify sales patterns and seasonal effects
3. Rep Performance: Track individual and territory performance
4. Product Analysis: Understand product mix and category performance
5. Customer Segmentation: Analyze customer value and retention
6. Sales Forecasting: Predict future performance based on trends

Key Performance Indicators (KPIs):
- Total Revenue and Growth Rate
- Average Order Value (AOV)
- Sales Rep Performance vs Territory Average
- Product Market Share within Categories
- Customer Retention Rate by Segment
- Month-over-Month and Year-over-Year Growth

This analysis helps sales managers:
- Identify top performers and areas needing support
- Optimize product mix and pricing strategies
- Improve customer retention and segment targeting
- Make data-driven sales forecasts and targets
- Monitor daily performance against goals
*/
