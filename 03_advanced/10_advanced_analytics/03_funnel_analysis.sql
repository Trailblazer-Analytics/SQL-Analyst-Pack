-- File: 10_advanced-analytics/03_funnel_analysis.sql
-- Topic: Funnel Analysis - Conversion Optimization and User Journey Mapping
-- Author: SQL Analyst Pack
-- Date: 2024

/*
PURPOSE:
Master funnel analysis to optimize conversion rates and understand user journey drop-off points.
This is essential for e-commerce, SaaS, mobile apps, and any business with multi-step processes.

BUSINESS APPLICATIONS:
- E-commerce checkout optimization
- SaaS trial-to-paid conversion analysis
- Mobile app onboarding improvement
- Marketing campaign effectiveness measurement
- Product feature adoption tracking
- Sales process optimization

REAL-WORLD SCENARIOS:
- Online retailer optimizing shopping cart abandonment
- SaaS company improving free trial conversions
- Mobile app reducing user onboarding drop-offs
- B2B company analyzing sales pipeline efficiency
- Media company tracking content engagement funnels

ADVANCED CONCEPTS:
- Multi-path funnel analysis
- Time-based conversion windows
- Cohorted funnel performance
- Attribution modeling in funnels
- Predictive funnel optimization
*/

---------------------------------------------------------------------------------------------------
-- SECTION 1: FUNNEL ANALYSIS FUNDAMENTALS
---------------------------------------------------------------------------------------------------

-- What is Funnel Analysis?
-- A systematic approach to measure user progression through predefined steps toward a goal.
-- Each step represents a conversion opportunity, and the analysis reveals where users drop off.

-- Why Funnel Analysis Matters:
-- 1. CONVERSION OPTIMIZATION: Identify biggest drop-off points for targeted improvements
-- 2. USER EXPERIENCE: Understand friction points in user journeys
-- 3. BUSINESS GROWTH: Optimize each step to maximize overall conversion rates
-- 4. RESOURCE ALLOCATION: Focus improvement efforts on highest-impact areas
-- 5. PERFORMANCE TRACKING: Monitor conversion improvements over time

-- Key Funnel Metrics:
-- - Step Completion Rate: % of users completing each step
-- - Step-to-Step Conversion: % moving from one step to the next
-- - Overall Conversion Rate: % completing the entire funnel
-- - Drop-off Rate: % of users abandoning at each step

-- Example Business Impact:
-- - Amazon improved checkout conversion by 12% through funnel analysis
-- - Dropbox increased trial-to-paid conversion by 15% using funnel optimization
-- - Netflix reduced subscription abandonment by 25% via funnel improvements

---------------------------------------------------------------------------------------------------
-- SECTION 2: E-COMMERCE CONVERSION FUNNEL ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: Online retailer optimizing checkout process
-- Goal: Identify where customers abandon their purchase journey
-- Funnel Steps: Homepage Visit → Product View → Add to Cart → Checkout → Purchase

-- Sample Data Structure
/*
CREATE TABLE user_events (
    user_id INT,
    event_timestamp TIMESTAMP,
    event_type VARCHAR(50),
    product_id INT,
    page_url VARCHAR(200),
    session_id VARCHAR(100)
);
*/
Step1_ActiveCustomers AS (
    SELECT DISTINCT CustomerId FROM invoices
),

-- Step 2: Identify customers who have purchased more than 5 tracks.
Step2_PurchasedOver5Tracks AS (
    SELECT CustomerId
    FROM invoice_items
    GROUP BY CustomerId
    HAVING COUNT(TrackId) > 5
),

-- Step 3: Identify customers who have purchased at least one 'Rock' track.
Step3_PurchasedRock AS (
    SELECT DISTINCT ii.CustomerId
    FROM invoice_items ii
    JOIN tracks t ON ii.TrackId = t.TrackId
    JOIN genres g ON t.GenreId = g.GenreId
    WHERE g.Name = 'Rock'
),

-- Step 4: Identify customers who have purchased at least one 'Jazz' track.
Step4_PurchasedJazz AS (
    SELECT DISTINCT ii.CustomerId
    FROM invoice_items ii
    JOIN tracks t ON ii.TrackId = t.TrackId
    JOIN genres g ON t.GenreId = g.GenreId
    WHERE g.Name = 'Jazz'
),

-- Now, we count the users at each stage of the funnel.
-- We use LEFT JOINs to ensure that we count users from one step only if they also
-- appear in the previous step.
FunnelCounts AS (
    SELECT
        '1. Active Customers' AS FunnelStep,
        COUNT(s1.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1

    UNION ALL

    SELECT
        '2. Purchased > 5 Tracks' AS FunnelStep,
        COUNT(s2.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1
    JOIN Step2_PurchasedOver5Tracks s2 ON s1.CustomerId = s2.CustomerId

    UNION ALL

    SELECT
        '3. Purchased Rock' AS FunnelStep,
        COUNT(s3.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1
    JOIN Step2_PurchasedOver5Tracks s2 ON s1.CustomerId = s2.CustomerId
    JOIN Step3_PurchasedRock s3 ON s2.CustomerId = s3.CustomerId

    UNION ALL

    SELECT
        '4. Purchased Rock & Jazz' AS FunnelStep,
        COUNT(s4.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1
    JOIN Step2_PurchasedOver5Tracks s2 ON s1.CustomerId = s2.CustomerId
    JOIN Step3_PurchasedRock s3 ON s2.CustomerId = s3.CustomerId
    JOIN Step4_PurchasedJazz s4 ON s3.CustomerId = s4.CustomerId
)

-- Finally, calculate the conversion rates between steps.
SELECT
    FunnelStep,
    UserCount,
    -- Use LAG to get the user count from the previous step.
    LAG(UserCount, 1, UserCount) OVER (ORDER BY FunnelStep) AS PreviousStepCount,
    -- Calculate the percentage conversion from the previous step.
    (CAST(UserCount AS REAL) * 100 / LAG(UserCount, 1, UserCount) OVER (ORDER BY FunnelStep)) AS ConversionRate_Vs_Previous_Step,
    -- Calculate the percentage conversion from the very first step.
    (CAST(UserCount AS REAL) * 100 / FIRST_VALUE(UserCount) OVER (ORDER BY FunnelStep)) AS ConversionRate_Vs_First_Step
FROM
    FunnelCounts
ORDER BY
    FunnelStep;

-- The output shows the number of users at each stage and the drop-off rate,
-- allowing an analyst to see that the biggest drop-off is between buying rock and also buying jazz.
-- This could lead to a recommendation to promote jazz playlists to rock fans.

-- BASIC E-COMMERCE FUNNEL ANALYSIS
-- Step-by-step conversion tracking for online retail

WITH
-- Step 1: Homepage visitors (entry point)
homepage_visitors AS (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE event_type = 'homepage_view'
    AND event_timestamp >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
),

-- Step 2: Product page viewers
product_viewers AS (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE event_type = 'product_view'
    AND user_id IN (SELECT user_id FROM homepage_visitors)
    AND event_timestamp >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
),

-- Step 3: Add to cart actions
cart_additions AS (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE event_type = 'add_to_cart'
    AND user_id IN (SELECT user_id FROM product_viewers)
    AND event_timestamp >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
),

-- Step 4: Checkout initiations
checkout_starts AS (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE event_type = 'checkout_start'
    AND user_id IN (SELECT user_id FROM cart_additions)
    AND event_timestamp >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
),

-- Step 5: Completed purchases
purchases AS (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE event_type = 'purchase_complete'
    AND user_id IN (SELECT user_id FROM checkout_starts)
    AND event_timestamp >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
),

-- Funnel aggregation and conversion calculation
funnel_steps AS (
    SELECT 'Step 1: Homepage' as step_name, 1 as step_order, COUNT(*) as users
    FROM homepage_visitors
    
    UNION ALL
    
    SELECT 'Step 2: Product View' as step_name, 2 as step_order, COUNT(*) as users
    FROM product_viewers
    
    UNION ALL
    
    SELECT 'Step 3: Add to Cart' as step_name, 3 as step_order, COUNT(*) as users
    FROM cart_additions
    
    UNION ALL
    
    SELECT 'Step 4: Checkout' as step_name, 4 as step_order, COUNT(*) as users
    FROM checkout_starts
    
    UNION ALL
    
    SELECT 'Step 5: Purchase' as step_name, 5 as step_order, COUNT(*) as users
    FROM purchases
)

SELECT 
    step_name,
    step_order,
    users as step_users,
    -- Step-to-step conversion rates
    ROUND(users * 100.0 / LAG(users) OVER (ORDER BY step_order), 2) as step_conversion_rate,
    -- Overall conversion from start
    ROUND(users * 100.0 / FIRST_VALUE(users) OVER (ORDER BY step_order), 2) as overall_conversion_rate,
    -- Drop-off analysis
    LAG(users) OVER (ORDER BY step_order) - users as users_dropped,
    ROUND((LAG(users) OVER (ORDER BY step_order) - users) * 100.0 / 
          LAG(users) OVER (ORDER BY step_order), 2) as drop_off_rate
FROM funnel_steps
ORDER BY step_order;

-- BUSINESS INSIGHTS:
-- - Identify the step with highest drop-off rate
-- - Focus optimization efforts on biggest conversion bottlenecks
-- - Track improvements in conversion rates over time
-- - Calculate revenue impact of conversion improvements

---------------------------------------------------------------------------------------------------
-- SECTION 3: TIME-WINDOWED FUNNEL ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: SaaS company analyzing trial-to-paid conversion
-- Challenge: Users can take different amounts of time to convert
-- Solution: Apply time windows to capture realistic user behavior

-- SaaS Trial Funnel with Time Windows
WITH user_trial_starts AS (
    SELECT 
        user_id,
        MIN(event_timestamp) as trial_start_date
    FROM user_events
    WHERE event_type = 'trial_signup'
    GROUP BY user_id
),

trial_funnel_steps AS (
    SELECT 
        uts.user_id,
        uts.trial_start_date,
        -- Step 2: Product usage within 7 days
        CASE WHEN EXISTS (
            SELECT 1 FROM user_events ue 
            WHERE ue.user_id = uts.user_id 
            AND ue.event_type = 'feature_usage'
            AND ue.event_timestamp BETWEEN uts.trial_start_date 
                AND uts.trial_start_date + INTERVAL '7 days'
        ) THEN 1 ELSE 0 END as used_product_7d,
        
        -- Step 3: Multiple sessions within 14 days
        CASE WHEN (
            SELECT COUNT(DISTINCT DATE(event_timestamp))
            FROM user_events ue 
            WHERE ue.user_id = uts.user_id 
            AND ue.event_type = 'session_start'
            AND ue.event_timestamp BETWEEN uts.trial_start_date 
                AND uts.trial_start_date + INTERVAL '14 days'
        ) >= 3 THEN 1 ELSE 0 END as multiple_sessions_14d,
        
        -- Step 4: Payment method added within 21 days
        CASE WHEN EXISTS (
            SELECT 1 FROM user_events ue 
            WHERE ue.user_id = uts.user_id 
            AND ue.event_type = 'payment_method_added'
            AND ue.event_timestamp BETWEEN uts.trial_start_date 
                AND uts.trial_start_date + INTERVAL '21 days'
        ) THEN 1 ELSE 0 END as payment_added_21d,
        
        -- Step 5: Converted to paid within 30 days
        CASE WHEN EXISTS (
            SELECT 1 FROM user_events ue 
            WHERE ue.user_id = uts.user_id 
            AND ue.event_type = 'subscription_start'
            AND ue.event_timestamp BETWEEN uts.trial_start_date 
                AND uts.trial_start_date + INTERVAL '30 days'
        ) THEN 1 ELSE 0 END as converted_30d
    FROM user_trial_starts uts
),

time_windowed_funnel AS (
    SELECT 
        'Trial Started' as step_name,
        1 as step_order,
        COUNT(*) as users
    FROM trial_funnel_steps
    
    UNION ALL
    
    SELECT 
        'Used Product (7d)' as step_name,
        2 as step_order,
        SUM(used_product_7d) as users
    FROM trial_funnel_steps
    
    UNION ALL
    
    SELECT 
        'Multiple Sessions (14d)' as step_name,
        3 as step_order,
        SUM(multiple_sessions_14d) as users
    FROM trial_funnel_steps
    
    UNION ALL
    
    SELECT 
        'Payment Added (21d)' as step_name,
        4 as step_order,
        SUM(payment_added_21d) as users
    FROM trial_funnel_steps
    
    UNION ALL
    
    SELECT 
        'Converted (30d)' as step_name,
        5 as step_order,
        SUM(converted_30d) as users
    FROM trial_funnel_steps
)

SELECT 
    step_name,
    users,
    ROUND(users * 100.0 / LAG(users) OVER (ORDER BY step_order), 2) as step_conversion_rate,
    ROUND(users * 100.0 / FIRST_VALUE(users) OVER (ORDER BY step_order), 2) as trial_to_step_rate
FROM time_windowed_funnel
ORDER BY step_order;

-- BUSINESS APPLICATION:
-- - Identify critical time windows for user engagement
-- - Optimize onboarding and activation strategies
-- - Design intervention campaigns at key drop-off points
-- - Set realistic conversion expectations based on time constraints

---------------------------------------------------------------------------------------------------
-- SECTION 4: MULTI-PATH FUNNEL ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: Mobile app with multiple user journey paths
-- Challenge: Users can reach the same goal through different paths
-- Solution: Track multiple possible conversion routes

-- Multi-Path Mobile App Funnel
WITH user_first_actions AS (
    SELECT 
        user_id,
        MIN(event_timestamp) as first_app_open,
        -- Identify primary entry method
        CASE 
            WHEN MIN(CASE WHEN event_type = 'tutorial_start' THEN event_timestamp END) IS NOT NULL 
                THEN 'tutorial_path'
            WHEN MIN(CASE WHEN event_type = 'social_login' THEN event_timestamp END) IS NOT NULL 
                THEN 'social_path'
            WHEN MIN(CASE WHEN event_type = 'email_signup' THEN event_timestamp END) IS NOT NULL 
                THEN 'email_path'
            ELSE 'direct_path'
        END as user_path
    FROM user_events
    WHERE event_type IN ('app_open', 'tutorial_start', 'social_login', 'email_signup')
    GROUP BY user_id
),

path_specific_funnels AS (
    SELECT 
        ufa.user_path,
        -- Common goal: user creates content
        COUNT(DISTINCT ufa.user_id) as path_users,
        
        -- Step 2: Profile completion (within 24 hours)
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_events ue 
                WHERE ue.user_id = ufa.user_id 
                AND ue.event_type = 'profile_completed'
                AND ue.event_timestamp <= ufa.first_app_open + INTERVAL '24 hours'
            ) THEN ufa.user_id 
        END) as completed_profile,
        
        -- Step 3: First content creation (within 48 hours)
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_events ue 
                WHERE ue.user_id = ufa.user_id 
                AND ue.event_type = 'content_created'
                AND ue.event_timestamp <= ufa.first_app_open + INTERVAL '48 hours'
            ) THEN ufa.user_id 
        END) as created_content,
        
        -- Step 4: Social interaction (within 72 hours)
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_events ue 
                WHERE ue.user_id = ufa.user_id 
                AND ue.event_type IN ('like_given', 'comment_posted', 'content_shared')
                AND ue.event_timestamp <= ufa.first_app_open + INTERVAL '72 hours'
            ) THEN ufa.user_id 
        END) as social_interaction,
        
        -- Step 5: Weekly active user (returns within 7 days)
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_events ue 
                WHERE ue.user_id = ufa.user_id 
                AND ue.event_type = 'app_open'
                AND ue.event_timestamp BETWEEN ufa.first_app_open + INTERVAL '24 hours'
                    AND ufa.first_app_open + INTERVAL '7 days'
            ) THEN ufa.user_id 
        END) as weekly_active
    FROM user_first_actions ufa
    GROUP BY ufa.user_path
)

SELECT 
    user_path,
    path_users,
    completed_profile,
    ROUND(completed_profile * 100.0 / path_users, 2) as profile_completion_rate,
    created_content,
    ROUND(created_content * 100.0 / completed_profile, 2) as content_creation_rate,
    social_interaction,
    ROUND(social_interaction * 100.0 / created_content, 2) as social_engagement_rate,
    weekly_active,
    ROUND(weekly_active * 100.0 / path_users, 2) as weekly_retention_rate
FROM path_specific_funnels
ORDER BY weekly_retention_rate DESC;

-- STRATEGIC INSIGHTS:
-- - Compare conversion effectiveness across different user paths
-- - Optimize onboarding flows for each user journey type
-- - Allocate marketing budget to highest-converting acquisition methods
-- - Design path-specific engagement strategies

---------------------------------------------------------------------------------------------------
-- SECTION 5: COHORTED FUNNEL ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: Product team wants to track funnel improvements over time
-- Goal: Compare funnel performance across different time periods or user cohorts
-- Application: Measure impact of product changes on conversion rates

-- Monthly Cohort Funnel Performance
WITH monthly_user_cohorts AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', MIN(event_timestamp)) as cohort_month
    FROM user_events
    WHERE event_type = 'user_registration'
    GROUP BY user_id
),

cohort_funnel_metrics AS (
    SELECT 
        muc.cohort_month,
        COUNT(DISTINCT muc.user_id) as cohort_size,
        
        -- Funnel step conversions by cohort
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_events ue 
                WHERE ue.user_id = muc.user_id 
                AND ue.event_type = 'onboarding_completed'
                AND DATE_TRUNC('month', ue.event_timestamp) = muc.cohort_month
            ) THEN muc.user_id 
        END) as completed_onboarding,
        
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_events ue 
                WHERE ue.user_id = muc.user_id 
                AND ue.event_type = 'first_purchase'
                AND ue.event_timestamp <= muc.cohort_month + INTERVAL '30 days'
            ) THEN muc.user_id 
        END) as first_purchase_30d,
        
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_events ue 
                WHERE ue.user_id = muc.user_id 
                AND ue.event_type = 'repeat_purchase'
                AND ue.event_timestamp <= muc.cohort_month + INTERVAL '90 days'
            ) THEN muc.user_id 
        END) as repeat_purchase_90d
    FROM monthly_user_cohorts muc
    WHERE muc.cohort_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
    GROUP BY muc.cohort_month
)

SELECT 
    cohort_month,
    cohort_size,
    completed_onboarding,
    ROUND(completed_onboarding * 100.0 / cohort_size, 2) as onboarding_rate,
    first_purchase_30d,
    ROUND(first_purchase_30d * 100.0 / completed_onboarding, 2) as purchase_conversion_rate,
    repeat_purchase_90d,
    ROUND(repeat_purchase_90d * 100.0 / first_purchase_30d, 2) as repeat_purchase_rate,
    -- Overall funnel conversion
    ROUND(repeat_purchase_90d * 100.0 / cohort_size, 2) as end_to_end_conversion,
    -- Month-over-month improvement
    ROUND((repeat_purchase_90d * 100.0 / cohort_size) - 
          LAG(repeat_purchase_90d * 100.0 / cohort_size) OVER (ORDER BY cohort_month), 2) as mom_improvement
FROM cohort_funnel_metrics
ORDER BY cohort_month;

-- PERFORMANCE TRACKING INSIGHTS:
-- - Monitor funnel performance improvements over time
-- - Identify impact of product changes on conversion rates
-- - Compare seasonal variations in funnel performance
-- - Set benchmarks for future cohort performance

---------------------------------------------------------------------------------------------------
-- SECTION 6: ATTRIBUTION FUNNEL ANALYSIS
---------------------------------------------------------------------------------------------------

-- Business Scenario: Marketing team needs multi-touch attribution
-- Challenge: Users interact with multiple marketing touchpoints before converting
-- Solution: Track and weight marketing attribution throughout the funnel

-- Multi-Touch Attribution Funnel
WITH user_marketing_touches AS (
    SELECT 
        user_id,
        event_timestamp,
        CASE 
            WHEN event_type = 'email_click' THEN 'email'
            WHEN event_type = 'social_click' THEN 'social'
            WHEN event_type = 'search_click' THEN 'search'
            WHEN event_type = 'display_click' THEN 'display'
            WHEN event_type = 'direct_visit' THEN 'direct'
        END as marketing_channel,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_timestamp) as touch_sequence
    FROM user_events
    WHERE event_type IN ('email_click', 'social_click', 'search_click', 'display_click', 'direct_visit')
),

user_conversion_paths AS (
    SELECT 
        umt.user_id,
        STRING_AGG(umt.marketing_channel, ' → ' ORDER BY umt.touch_sequence) as attribution_path,
        COUNT(*) as total_touches,
        MIN(umt.event_timestamp) as first_touch,
        MAX(umt.event_timestamp) as last_touch,
        -- Conversion indicators
        EXISTS (
            SELECT 1 FROM user_events ue 
            WHERE ue.user_id = umt.user_id 
            AND ue.event_type = 'signup_completed'
        ) as converted_signup,
        EXISTS (
            SELECT 1 FROM user_events ue 
            WHERE ue.user_id = umt.user_id 
            AND ue.event_type = 'purchase_completed'
        ) as converted_purchase
    FROM user_marketing_touches umt
    GROUP BY umt.user_id
),

attribution_analysis AS (
    SELECT 
        attribution_path,
        COUNT(*) as path_frequency,
        SUM(CASE WHEN converted_signup THEN 1 ELSE 0 END) as signup_conversions,
        SUM(CASE WHEN converted_purchase THEN 1 ELSE 0 END) as purchase_conversions,
        ROUND(AVG(total_touches), 1) as avg_touches_to_conversion,
        ROUND(AVG(EXTRACT(DAYS FROM (last_touch - first_touch))), 1) as avg_days_to_conversion
    FROM user_conversion_paths
    GROUP BY attribution_path
    HAVING COUNT(*) >= 10  -- Focus on statistically significant paths
)

SELECT 
    attribution_path,
    path_frequency,
    signup_conversions,
    ROUND(signup_conversions * 100.0 / path_frequency, 2) as signup_conversion_rate,
    purchase_conversions,
    ROUND(purchase_conversions * 100.0 / path_frequency, 2) as purchase_conversion_rate,
    avg_touches_to_conversion,
    avg_days_to_conversion,
    -- Marketing efficiency scoring
    ROUND(purchase_conversions * 100.0 / avg_touches_to_conversion, 2) as efficiency_score
FROM attribution_analysis
ORDER BY purchase_conversion_rate DESC, path_frequency DESC;

-- MARKETING OPTIMIZATION INSIGHTS:
-- - Identify most effective marketing channel combinations
-- - Understand typical customer journey complexity
-- - Optimize marketing budget allocation across channels
-- - Design cross-channel marketing campaigns

---------------------------------------------------------------------------------------------------
-- SECTION 7: REAL-TIME FUNNEL MONITORING
---------------------------------------------------------------------------------------------------

-- Business Scenario: Operations team needs live funnel performance monitoring
-- Goal: Detect funnel performance issues in real-time
-- Application: Alert system for sudden conversion rate drops

-- Real-Time Funnel Health Monitoring
WITH current_hour_funnel AS (
    SELECT 
        DATE_TRUNC('hour', event_timestamp) as hour_bucket,
        COUNT(DISTINCT CASE WHEN event_type = 'landing_page_view' THEN user_id END) as landing_views,
        COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN user_id END) as product_views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) as cart_adds,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) as checkout_starts,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN user_id END) as purchases
    FROM user_events
    WHERE event_timestamp >= DATE_TRUNC('hour', CURRENT_TIMESTAMP - INTERVAL '24 hours')
    GROUP BY DATE_TRUNC('hour', event_timestamp)
),

hourly_conversion_rates AS (
    SELECT 
        hour_bucket,
        landing_views,
        product_views,
        cart_adds,
        checkout_starts,
        purchases,
        -- Calculate hourly conversion rates
        ROUND(product_views * 100.0 / NULLIF(landing_views, 0), 2) as landing_to_product_rate,
        ROUND(cart_adds * 100.0 / NULLIF(product_views, 0), 2) as product_to_cart_rate,
        ROUND(checkout_starts * 100.0 / NULLIF(cart_adds, 0), 2) as cart_to_checkout_rate,
        ROUND(purchases * 100.0 / NULLIF(checkout_starts, 0), 2) as checkout_to_purchase_rate,
        ROUND(purchases * 100.0 / NULLIF(landing_views, 0), 2) as overall_conversion_rate
    FROM current_hour_funnel
),

funnel_health_alerts AS (
    SELECT 
        *,
        -- Compare to 24-hour rolling average
        AVG(overall_conversion_rate) OVER (
            ORDER BY hour_bucket 
            ROWS BETWEEN 23 PRECEDING AND 1 PRECEDING
        ) as avg_24h_conversion,
        -- Detect significant drops
        CASE 
            WHEN overall_conversion_rate < 
                (AVG(overall_conversion_rate) OVER (
                    ORDER BY hour_bucket 
                    ROWS BETWEEN 23 PRECEDING AND 1 PRECEDING
                ) * 0.7) THEN 'CRITICAL_DROP'
            WHEN overall_conversion_rate < 
                (AVG(overall_conversion_rate) OVER (
                    ORDER BY hour_bucket 
                    ROWS BETWEEN 23 PRECEDING AND 1 PRECEDING
                ) * 0.85) THEN 'WARNING'
            ELSE 'NORMAL'
        END as health_status
    FROM hourly_conversion_rates
)

SELECT 
    hour_bucket,
    overall_conversion_rate,
    avg_24h_conversion,
    health_status,
    landing_to_product_rate,
    product_to_cart_rate,
    cart_to_checkout_rate,
    checkout_to_purchase_rate,
    -- Specific alerts for each step
    CASE 
        WHEN landing_to_product_rate < avg_24h_conversion * 0.8 THEN 'Product Page Issue'
        WHEN product_to_cart_rate < avg_24h_conversion * 0.8 THEN 'Cart Conversion Issue'
        WHEN cart_to_checkout_rate < avg_24h_conversion * 0.8 THEN 'Checkout Issue'
        WHEN checkout_to_purchase_rate < avg_24h_conversion * 0.8 THEN 'Payment Issue'
        ELSE 'No Issues Detected'
    END as specific_alert
FROM funnel_health_alerts
WHERE hour_bucket >= DATE_TRUNC('hour', CURRENT_TIMESTAMP - INTERVAL '4 hours')
ORDER BY hour_bucket DESC;

---------------------------------------------------------------------------------------------------
-- KEY BUSINESS APPLICATIONS AND INSIGHTS
---------------------------------------------------------------------------------------------------

/*
E-COMMERCE TEAMS:
- Optimize checkout flow to reduce cart abandonment
- Identify product page issues affecting conversions
- A/B test funnel improvements and measure impact
- Monitor seasonal conversion patterns

SAAS COMPANIES:
- Improve trial-to-paid conversion rates
- Optimize user onboarding and activation flows
- Track feature adoption within conversion funnels
- Identify high-value user behavior patterns

MOBILE APP TEAMS:
- Reduce user onboarding drop-offs
- Optimize in-app purchase funnels
- Track user engagement progression
- Compare different user acquisition sources

MARKETING TEAMS:
- Understand multi-touch attribution across funnels
- Optimize marketing spend based on conversion data
- Design targeted campaigns for different funnel stages
- Track campaign effectiveness through conversion impact

PRODUCT TEAMS:
- Identify product friction points affecting conversions
- Measure feature impact on user progression
- Design experiments to improve conversion rates
- Monitor product-market fit through funnel metrics

NEXT STEPS:
1. Implement basic funnel analysis for your key conversion process
2. Add time windows appropriate for your business model
3. Set up real-time monitoring and alerting
4. Create cohort-based funnel tracking for performance improvements
5. Build attribution models for multi-touch customer journeys

ADVANCED TECHNIQUES TO EXPLORE:
- Machine learning models for conversion prediction
- Dynamic funnel definition based on user behavior
- Personalized funnel experiences based on segments
- Integration with business intelligence platforms
*/
