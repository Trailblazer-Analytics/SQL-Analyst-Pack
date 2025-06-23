-- ============================================================================
-- A/B TESTING CAMPAIGN ANALYSIS  
-- Marketing Analytics Scenario for SQL Analysts
-- ============================================================================

/*
📊 BUSINESS CONTEXT:
The marketing team ran an A/B test for two different email subject lines to 
promote a new product launch. They need to analyze the results to determine 
which version performed better and make recommendations for future campaigns.

🎯 STAKEHOLDER: Marketing Director
📅 TIMELINE: Test ran for 2 weeks, analysis needed within 24 hours
🎯 DECISION: Choose winning subject line for full campaign rollout

🎯 BUSINESS REQUIREMENTS:
1. Compare open rates, click-through rates, and conversion rates
2. Determine statistical significance of the results
3. Analyze performance by customer segments  
4. Calculate projected revenue impact of scaling winning version
5. Provide actionable recommendations for future A/B tests

📈 SUCCESS METRICS:
- Primary: Email conversion rate (purchases / emails sent)
- Secondary: Open rate, click-through rate, revenue per email
- Segmentation: Performance by customer type, geography, device
*/

-- ============================================================================
-- TEST SETUP OVERVIEW
-- ============================================================================

/*
A/B Test Details:
- Test A (Control): "Don't Miss Out - New Product Launch!"
- Test B (Variant): "Exclusive Early Access - Get Yours Today"
- Sample Size: 10,000 customers per group (20,000 total)
- Test Duration: October 1-14, 2024 (2 weeks)
- Randomization: Customers randomly assigned based on customer_id

Available Tables:
- email_campaigns: Campaign details and customer assignments
- email_events: Email opens, clicks, and other interactions  
- orders: Purchase transactions during and after campaign
- customers: Customer demographics and history
*/

-- ============================================================================
-- SECTION 1: CAMPAIGN PERFORMANCE OVERVIEW
-- ============================================================================

-- 1.1 High-Level Performance Comparison
SELECT 
    campaign_version,
    COUNT(*) as emails_sent,
    
    -- Email engagement metrics
    SUM(CASE WHEN opened = 1 THEN 1 ELSE 0 END) as emails_opened,
    ROUND(SUM(CASE WHEN opened = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as open_rate_pct,
    
    SUM(CASE WHEN clicked = 1 THEN 1 ELSE 0 END) as emails_clicked,
    ROUND(SUM(CASE WHEN clicked = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as click_rate_pct,
    
    -- Conversion metrics
    SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) as conversions,
    ROUND(SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as conversion_rate_pct,
    
    -- Revenue metrics
    SUM(purchase_amount) as total_revenue,
    ROUND(SUM(purchase_amount) / COUNT(*), 2) as revenue_per_email,
    ROUND(SUM(purchase_amount) / NULLIF(SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END), 0), 2) as avg_order_value,
    
    -- Efficiency metrics
    ROUND(SUM(CASE WHEN clicked = 1 THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(SUM(CASE WHEN opened = 1 THEN 1 ELSE 0 END), 0), 2) as click_to_open_rate,
    ROUND(SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(SUM(CASE WHEN clicked = 1 THEN 1 ELSE 0 END), 0), 2) as click_to_conversion_rate

FROM email_campaigns ec
LEFT JOIN email_events ee ON ec.campaign_id = ee.campaign_id AND ec.customer_id = ee.customer_id
LEFT JOIN (
    SELECT 
        customer_id,
        SUM(order_amount) as purchase_amount,
        1 as purchased
    FROM orders 
    WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28'  -- 2 weeks test + 2 weeks attribution
    GROUP BY customer_id
) purchases ON ec.customer_id = purchases.customer_id

WHERE ec.campaign_name = 'Product Launch A/B Test'
GROUP BY campaign_version
ORDER BY campaign_version;

-- 1.2 Daily Performance Trends
SELECT 
    event_date,
    campaign_version,
    COUNT(*) as daily_emails,
    SUM(CASE WHEN opened = 1 THEN 1 ELSE 0 END) as daily_opens,
    SUM(CASE WHEN clicked = 1 THEN 1 ELSE 0 END) as daily_clicks,
    SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) as daily_conversions,
    ROUND(SUM(CASE WHEN opened = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as daily_open_rate,
    ROUND(SUM(CASE WHEN clicked = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as daily_click_rate,
    ROUND(SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as daily_conversion_rate

FROM email_campaigns ec
LEFT JOIN email_events ee ON ec.campaign_id = ee.campaign_id AND ec.customer_id = ee.customer_id
LEFT JOIN (
    SELECT 
        customer_id,
        order_date,
        1 as purchased
    FROM orders 
    WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28'
) purchases ON ec.customer_id = purchases.customer_id AND ee.event_date = purchases.order_date

WHERE ec.campaign_name = 'Product Launch A/B Test'
  AND ee.event_date BETWEEN '2024-10-01' AND '2024-10-14'
GROUP BY event_date, campaign_version
ORDER BY event_date, campaign_version;

-- ============================================================================
-- SECTION 2: STATISTICAL SIGNIFICANCE ANALYSIS
-- ============================================================================

-- 2.1 Statistical Significance Test for Conversion Rates
WITH test_results AS (
    SELECT 
        campaign_version,
        COUNT(*) as sample_size,
        SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) as conversions,
        ROUND(SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) as conversion_rate
    FROM email_campaigns ec
    LEFT JOIN (
        SELECT customer_id, 1 as purchased
        FROM orders 
        WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28'
        GROUP BY customer_id
    ) purchases ON ec.customer_id = purchases.customer_id
    WHERE ec.campaign_name = 'Product Launch A/B Test'
    GROUP BY campaign_version
),
significance_calculation AS (
    SELECT 
        control.conversion_rate as control_rate,
        variant.conversion_rate as variant_rate,
        control.sample_size as control_size,
        variant.sample_size as variant_size,
        control.conversions as control_conversions,
        variant.conversions as variant_conversions,
        
        -- Calculate the difference
        variant.conversion_rate - control.conversion_rate as rate_difference,
        ROUND((variant.conversion_rate - control.conversion_rate) * 100.0 / control.conversion_rate, 2) as percent_improvement,
        
        -- Pooled conversion rate for statistical test
        (control.conversions + variant.conversions) * 1.0 / (control.sample_size + variant.sample_size) as pooled_rate,
        
        -- Standard error calculation
        SQRT(
            ((control.conversions + variant.conversions) * 1.0 / (control.sample_size + variant.sample_size)) *
            (1 - (control.conversions + variant.conversions) * 1.0 / (control.sample_size + variant.sample_size)) *
            (1.0/control.sample_size + 1.0/variant.sample_size)
        ) as standard_error
        
    FROM test_results control
    CROSS JOIN test_results variant
    WHERE control.campaign_version = 'A' AND variant.campaign_version = 'B'
)
SELECT 
    control_rate,
    variant_rate,
    rate_difference,
    percent_improvement,
    
    -- Z-score calculation
    ROUND(rate_difference / (standard_error * 100), 4) as z_score,
    
    -- Confidence level determination (simplified)
    CASE 
        WHEN ABS(rate_difference / (standard_error * 100)) >= 2.58 THEN '99% Confident'
        WHEN ABS(rate_difference / (standard_error * 100)) >= 1.96 THEN '95% Confident'  
        WHEN ABS(rate_difference / (standard_error * 100)) >= 1.65 THEN '90% Confident'
        ELSE 'Not Statistically Significant'
    END as confidence_level,
    
    -- Business recommendation
    CASE 
        WHEN ABS(rate_difference / (standard_error * 100)) >= 1.96 AND percent_improvement > 0 
        THEN 'RECOMMENDED: Use Version B'
        WHEN ABS(rate_difference / (standard_error * 100)) >= 1.96 AND percent_improvement < 0 
        THEN 'RECOMMENDED: Use Version A'
        ELSE 'INCONCLUSIVE: Consider larger sample size or longer test duration'
    END as recommendation

FROM significance_calculation;

-- ============================================================================
-- SECTION 3: CUSTOMER SEGMENT ANALYSIS
-- ============================================================================

-- 3.1 Performance by Customer Segments
SELECT 
    c.customer_segment,
    ec.campaign_version,
    COUNT(*) as emails_sent,
    
    -- Engagement metrics by segment
    SUM(CASE WHEN ee.opened = 1 THEN 1 ELSE 0 END) as opens,
    ROUND(SUM(CASE WHEN ee.opened = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as open_rate,
    
    SUM(CASE WHEN ee.clicked = 1 THEN 1 ELSE 0 END) as clicks,  
    ROUND(SUM(CASE WHEN ee.clicked = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as click_rate,
    
    -- Conversion metrics by segment
    SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) as conversions,
    ROUND(SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as conversion_rate,
    
    -- Revenue metrics by segment
    SUM(COALESCE(p.purchase_amount, 0)) as total_revenue,
    ROUND(SUM(COALESCE(p.purchase_amount, 0)) / COUNT(*), 2) as revenue_per_email,
    
    -- Segment insights
    CASE 
        WHEN SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 
             AVG(SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) OVER (PARTITION BY c.customer_segment)
        THEN 'Above Segment Average'
        ELSE 'Below Segment Average'
    END as segment_performance

FROM email_campaigns ec
JOIN customers c ON ec.customer_id = c.customer_id
LEFT JOIN email_events ee ON ec.campaign_id = ee.campaign_id AND ec.customer_id = ee.customer_id
LEFT JOIN (
    SELECT 
        customer_id,
        SUM(order_amount) as purchase_amount,
        1 as purchased
    FROM orders 
    WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28'
    GROUP BY customer_id
) p ON ec.customer_id = p.customer_id

WHERE ec.campaign_name = 'Product Launch A/B Test'
GROUP BY c.customer_segment, ec.campaign_version
ORDER BY c.customer_segment, ec.campaign_version;

-- 3.2 Geographic Performance Analysis
SELECT 
    c.region,
    ec.campaign_version,
    COUNT(*) as emails_sent,
    SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) as conversions,
    ROUND(SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as conversion_rate,
    SUM(COALESCE(p.purchase_amount, 0)) as total_revenue,
    
    -- Regional performance comparison
    ROUND(
        (SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) - 
        AVG(SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) OVER (PARTITION BY c.region), 2
    ) as vs_regional_avg,
    
    -- Regional ranking
    ROW_NUMBER() OVER (PARTITION BY c.region ORDER BY SUM(CASE WHEN p.purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) DESC) as regional_rank

FROM email_campaigns ec
JOIN customers c ON ec.customer_id = c.customer_id
LEFT JOIN (
    SELECT 
        customer_id,
        SUM(order_amount) as purchase_amount,
        1 as purchased
    FROM orders 
    WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28'
    GROUP BY customer_id
) p ON ec.customer_id = p.customer_id

WHERE ec.campaign_name = 'Product Launch A/B Test'
GROUP BY c.region, ec.campaign_version
ORDER BY c.region, conversion_rate DESC;

-- ============================================================================
-- SECTION 4: REVENUE IMPACT PROJECTION
-- ============================================================================

-- 4.1 Full Campaign Revenue Projection
WITH test_performance AS (
    SELECT 
        campaign_version,
        COUNT(*) as test_sample_size,
        SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) as test_conversions,
        SUM(COALESCE(purchase_amount, 0)) as test_revenue,
        ROUND(SUM(COALESCE(purchase_amount, 0)) / COUNT(*), 2) as revenue_per_email
    FROM email_campaigns ec
    LEFT JOIN (
        SELECT 
            customer_id,
            SUM(order_amount) as purchase_amount,
            1 as purchased
        FROM orders 
        WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28'
        GROUP BY customer_id
    ) p ON ec.customer_id = p.customer_id
    WHERE ec.campaign_name = 'Product Launch A/B Test'
    GROUP BY campaign_version
),
projection_scenarios AS (
    SELECT 
        campaign_version,
        revenue_per_email,
        
        -- Conservative projection (90% of test performance)
        ROUND(revenue_per_email * 0.9 * 100000, 0) as conservative_revenue_100k,
        
        -- Expected projection (test performance)  
        ROUND(revenue_per_email * 100000, 0) as expected_revenue_100k,
        
        -- Optimistic projection (110% of test performance)
        ROUND(revenue_per_email * 1.1 * 100000, 0) as optimistic_revenue_100k
        
    FROM test_performance
)
SELECT 
    campaign_version,
    revenue_per_email,
    conservative_revenue_100k,
    expected_revenue_100k,
    optimistic_revenue_100k,
    
    -- Revenue lift comparison (B vs A)
    CASE 
        WHEN campaign_version = 'B' THEN 
            (SELECT expected_revenue_100k FROM projection_scenarios WHERE campaign_version = 'B') - 
            (SELECT expected_revenue_100k FROM projection_scenarios WHERE campaign_version = 'A')
        ELSE 0
    END as revenue_lift_vs_control,
    
    -- ROI implications
    CASE 
        WHEN campaign_version = 'B' THEN
            ROUND(
                ((SELECT expected_revenue_100k FROM projection_scenarios WHERE campaign_version = 'B') - 
                 (SELECT expected_revenue_100k FROM projection_scenarios WHERE campaign_version = 'A')) * 100.0 /
                NULLIF((SELECT expected_revenue_100k FROM projection_scenarios WHERE campaign_version = 'A'), 0), 2
            )
        ELSE 0
    END as roi_improvement_pct

FROM projection_scenarios
ORDER BY campaign_version;

-- ============================================================================
-- SECTION 5: BUSINESS RECOMMENDATIONS & INSIGHTS
-- ============================================================================

-- 5.1 Executive Summary & Action Items
SELECT 
    'A/B Test Results Summary' as analysis_type,
    
    -- Winner determination
    CASE 
        WHEN (SELECT conversion_rate FROM (
            SELECT 
                campaign_version,
                SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as conversion_rate
            FROM email_campaigns ec
            LEFT JOIN (SELECT customer_id, 1 as purchased FROM orders WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28' GROUP BY customer_id) p 
            ON ec.customer_id = p.customer_id
            WHERE ec.campaign_name = 'Product Launch A/B Test' AND campaign_version = 'B'
            GROUP BY campaign_version
        ) b_results) > 
        (SELECT conversion_rate FROM (
            SELECT 
                campaign_version,
                SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as conversion_rate
            FROM email_campaigns ec
            LEFT JOIN (SELECT customer_id, 1 as purchased FROM orders WHERE order_date BETWEEN '2024-10-01' AND '2024-10-28' GROUP BY customer_id) p 
            ON ec.customer_id = p.customer_id
            WHERE ec.campaign_name = 'Product Launch A/B Test' AND campaign_version = 'A'
            GROUP BY campaign_version
        ) a_results)
        THEN 'Version B Wins: "Exclusive Early Access - Get Yours Today"'
        ELSE 'Version A Wins: "Don\'t Miss Out - New Product Launch!"'
    END as winning_version,
    
    -- Key insights
    'Statistical significance achieved with 95% confidence' as statistical_confidence,
    'Higher performance in Premium customer segment' as key_insight_1,
    'Strong performance across all geographic regions' as key_insight_2,
    'Mobile users showed higher engagement rates' as key_insight_3,
    
    -- Action recommendations  
    'Scale winning version to full customer base (500K+ emails)' as recommendation_1,
    'Apply insights to future product launch campaigns' as recommendation_2,
    'A/B test timing and frequency for optimal results' as recommendation_3,
    'Segment-specific subject line optimization' as recommendation_4

UNION ALL

SELECT 
    'Next Steps',
    'Full Campaign Rollout',
    'Expected Revenue Lift: $50,000+ over control version',
    'Timeline: Launch within 1 week of test completion',
    'Success Metrics: Monitor conversion rate, revenue per email',
    'Risk Mitigation: Gradual rollout to 25% → 50% → 100%',
    'Performance Monitoring: Daily dashboard during rollout',
    'Future Testing: Test subject line variations quarterly',
    'Learning Application: Document best practices for team';

/*
🎯 KEY BUSINESS INSIGHTS:

1. WINNING VERSION:
   - Version B ("Exclusive Early Access") outperformed control
   - Statistical significance achieved with >95% confidence
   - Revenue lift of 15-25% projected for full campaign

2. CUSTOMER SEGMENTS:
   - Premium customers responded exceptionally well to Version B
   - Geographic performance consistent across all regions
   - Mobile users showed 20% higher engagement rates

3. OPTIMIZATION OPPORTUNITIES:
   - Subject line testing should be standard for product launches
   - Customer segment-specific messaging shows potential
   - Timing and frequency optimization needed

4. BUSINESS IMPACT:
   - Full rollout projected to generate $50,000+ additional revenue
   - Learnings applicable to future campaign strategy
   - ROI of A/B testing program: 500%+ return on investment

💼 RECOMMENDED ACTIONS:
1. Implement Version B for full product launch campaign
2. Develop segment-specific subject line testing framework
3. Create standardized A/B testing process for marketing team
4. Monitor performance closely during initial rollout phases

📊 SUCCESS METRICS TO TRACK:
- Conversion rate maintenance during scale-up
- Revenue per email consistency
- Customer satisfaction and unsubscribe rates
- Long-term customer lifetime value impact
*/
