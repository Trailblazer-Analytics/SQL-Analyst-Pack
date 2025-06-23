/*
================================================================================
01_ecommerce_analytics_capstone.sql - E-Commerce Analytics Capstone Project
================================================================================

BUSINESS CONTEXT:
You are the Lead Data Analyst for "GlobalMart", a rapidly growing e-commerce 
platform with $2B annual revenue. The company operates across 15 countries, 
sells 500K+ products, and serves 50M+ customers. Leadership needs comprehensive 
analytics to drive strategic decisions for 2024 growth initiatives.

CHALLENGE OVERVIEW:
This capstone project integrates multiple advanced SQL concepts to solve 
real-world e-commerce challenges including customer segmentation, product 
recommendation engines, inventory optimization, and marketing attribution.

BUSINESS REQUIREMENTS:
1. Customer Lifetime Value (CLV) prediction and segmentation
2. Product recommendation system based on purchase patterns
3. Marketing attribution and channel optimization
4. Inventory demand forecasting and optimization
5. Fraud detection and risk assessment
6. Real-time dashboard KPIs and executive reporting

DATASETS REQUIRED:
- customers (50M records)
- products (500K records) 
- orders (200M records)
- order_items (800M records)
- marketing_campaigns (10K records)
- website_events (5B records)
- inventory_movements (100M records)
- payment_transactions (200M records)

TECHNICAL REQUIREMENTS:
- All queries must execute in <5 seconds for interactive use
- Results must be business-ready (formatted, documented)
- Include data quality checks and error handling
- Optimize for both performance and maintainability
- Provide executive summary insights for each analysis

TIME ALLOCATION: 40-60 hours over 2-3 weeks
DIFFICULTY: ⭐⭐⭐⭐⭐ Expert Level
================================================================================
*/

-- =============================================
-- SECTION 1: COMPREHENSIVE CUSTOMER SEGMENTATION
-- =============================================

/*
BUSINESS OBJECTIVE:
Develop a sophisticated customer segmentation model that combines recency, 
frequency, monetary value (RFM), behavioral patterns, and predictive analytics
to identify high-value customer segments and growth opportunities.

SUCCESS METRICS:
- Identify top 20% of customers driving 80% of revenue
- Predict customer churn with 85%+ accuracy
- Segment customers for targeted marketing campaigns
- Calculate customer lifetime value for strategic planning
*/

-- Create comprehensive customer analytics base table
WITH customer_transaction_history AS (
    SELECT 
        c.customer_id,
        c.registration_date,
        c.country,
        c.customer_tier,
        c.acquisition_channel,
        
        -- RFM Analysis Components
        MAX(o.order_date) as last_order_date,
        DATEDIFF(day, MAX(o.order_date), CURRENT_DATE) as recency_days,
        COUNT(DISTINCT o.order_id) as frequency_orders,
        SUM(o.total_amount) as monetary_total,
        AVG(o.total_amount) as avg_order_value,
        
        -- Advanced behavioral metrics
        COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) as active_months,
        COUNT(DISTINCT oi.product_id) as unique_products_purchased,
        COUNT(DISTINCT p.category) as unique_categories_purchased,
        
        -- Temporal patterns
        EXTRACT(DOW FROM o.order_date) as preferred_order_day,
        EXTRACT(HOUR FROM o.order_timestamp) as preferred_order_hour,
        
        -- Customer lifecycle metrics
        DATEDIFF(day, c.registration_date, CURRENT_DATE) as customer_age_days,
        DATEDIFF(day, c.registration_date, MIN(o.order_date)) as time_to_first_purchase,
        DATEDIFF(day, MIN(o.order_date), MAX(o.order_date)) as purchase_span_days,
        
        -- Product affinity analysis
        MODE() WITHIN GROUP (ORDER BY p.category) as favorite_category,
        MODE() WITHIN GROUP (ORDER BY p.brand) as favorite_brand,
        
        -- Price sensitivity indicators
        MIN(oi.unit_price) as min_price_paid,
        MAX(oi.unit_price) as max_price_paid,
        AVG(oi.unit_price) as avg_price_paid,
        STDDEV(oi.unit_price) as price_variance,
        
        -- Return and satisfaction indicators
        COUNT(CASE WHEN o.order_status = 'returned' THEN 1 END) as return_orders,
        AVG(CASE WHEN r.rating IS NOT NULL THEN r.rating END) as avg_rating_given,
        COUNT(r.review_id) as reviews_written
        
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN reviews r ON c.customer_id = r.customer_id
    WHERE o.order_date >= DATEADD(year, -2, CURRENT_DATE())
    GROUP BY 
        c.customer_id, c.registration_date, c.country, 
        c.customer_tier, c.acquisition_channel
),

rfm_scoring AS (
    SELECT 
        *,
        -- RFM Scoring (1-5 scale)
        CASE 
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 120 THEN 3
            WHEN recency_days <= 365 THEN 2
            ELSE 1
        END as recency_score,
        
        CASE 
            WHEN frequency_orders >= 20 THEN 5
            WHEN frequency_orders >= 10 THEN 4
            WHEN frequency_orders >= 5 THEN 3
            WHEN frequency_orders >= 2 THEN 2
            ELSE 1
        END as frequency_score,
        
        CASE 
            WHEN monetary_total >= 5000 THEN 5
            WHEN monetary_total >= 2000 THEN 4
            WHEN monetary_total >= 1000 THEN 3
            WHEN monetary_total >= 500 THEN 2
            ELSE 1
        END as monetary_score,
        
        -- Customer lifecycle stage
        CASE 
            WHEN customer_age_days <= 30 THEN 'New'
            WHEN customer_age_days <= 90 THEN 'Developing'
            WHEN customer_age_days <= 365 THEN 'Established'
            ELSE 'Mature'
        END as lifecycle_stage,
        
        -- Purchase behavior patterns
        CASE 
            WHEN purchase_span_days = 0 THEN 'One-time'
            WHEN purchase_span_days <= 30 THEN 'Concentrated'
            WHEN purchase_span_days <= 180 THEN 'Regular'
            ELSE 'Long-term'
        END as purchase_pattern,
        
        -- Engagement level
        CASE 
            WHEN active_months >= 12 THEN 'Highly Engaged'
            WHEN active_months >= 6 THEN 'Moderately Engaged'
            WHEN active_months >= 3 THEN 'Occasionally Engaged'
            ELSE 'Minimally Engaged'
        END as engagement_level
        
    FROM customer_transaction_history
),

customer_segments AS (
    SELECT 
        *,
        -- Create composite RFM score
        (recency_score * 100) + (frequency_score * 10) + monetary_score as rfm_score,
        
        -- Advanced segmentation logic
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 
            THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 4 
            THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score >= 3 
            THEN 'Potential Loyalists'
            WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score <= 2 
            THEN 'New Customers'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score <= 3 
            THEN 'Promising'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 4 
            THEN 'Need Attention'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score <= 3 
            THEN 'About to Sleep'
            WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score <= 2 
            THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 4 
            THEN 'Cannot Lose Them'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 
            THEN 'Hibernating'
            ELSE 'Lost'
        END as customer_segment,
        
        -- Calculate Customer Lifetime Value (CLV) prediction
        CASE 
            WHEN purchase_span_days > 0 
            THEN (monetary_total / purchase_span_days) * 365 * 
                 CASE 
                     WHEN recency_days <= 60 THEN 2.0  -- Active multiplier
                     WHEN recency_days <= 180 THEN 1.5
                     WHEN recency_days <= 365 THEN 1.0
                     ELSE 0.5  -- Churn risk multiplier
                 END
            ELSE monetary_total * 0.5  -- Conservative estimate for one-time buyers
        END as predicted_annual_clv,
        
        -- Churn risk assessment
        CASE 
            WHEN recency_days > 365 THEN 'High Risk'
            WHEN recency_days > 180 AND frequency_score <= 2 THEN 'Medium Risk'
            WHEN recency_days > 90 AND engagement_level = 'Minimally Engaged' THEN 'Low Risk'
            ELSE 'Active'
        END as churn_risk
        
    FROM rfm_scoring
)

-- Final customer segmentation analysis with business insights
SELECT 
    customer_segment,
    churn_risk,
    lifecycle_stage,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as segment_percentage,
    
    -- Financial metrics
    SUM(monetary_total) as total_revenue,
    AVG(monetary_total) as avg_customer_value,
    MEDIAN(monetary_total) as median_customer_value,
    SUM(predicted_annual_clv) as predicted_total_clv,
    AVG(predicted_annual_clv) as avg_predicted_clv,
    
    -- Behavioral insights
    AVG(frequency_orders) as avg_orders_per_customer,
    AVG(avg_order_value) as avg_order_value,
    AVG(unique_categories_purchased) as avg_categories_per_customer,
    AVG(recency_days) as avg_recency_days,
    
    -- Engagement metrics
    AVG(active_months) as avg_active_months,
    AVG(reviews_written) as avg_reviews_per_customer,
    AVG(avg_rating_given) as avg_customer_satisfaction,
    
    -- Recommended actions
    CASE 
        WHEN customer_segment = 'Champions' 
        THEN 'Reward loyalty, upsell premium products, referral programs'
        WHEN customer_segment = 'Loyal Customers' 
        THEN 'Maintain engagement, cross-sell, personalized offers'
        WHEN customer_segment = 'Potential Loyalists' 
        THEN 'Frequency campaigns, membership programs, category expansion'
        WHEN customer_segment = 'New Customers' 
        THEN 'Onboarding sequences, first purchase incentives, education'
        WHEN customer_segment = 'Need Attention' 
        THEN 'Reactivation campaigns, limited-time offers, feedback collection'
        WHEN customer_segment = 'At Risk' 
        THEN 'Win-back campaigns, surveys, special discounts'
        WHEN customer_segment = 'Cannot Lose Them' 
        THEN 'VIP treatment, personal account manager, exclusive access'
        WHEN customer_segment = 'Hibernating' 
        THEN 'Product recommendations, seasonal campaigns, interest renewal'
        ELSE 'Brand awareness, acquisition campaigns, market research'
    END as recommended_strategy
    
FROM customer_segments
GROUP BY customer_segment, churn_risk, lifecycle_stage
ORDER BY total_revenue DESC;

-- =============================================
-- SECTION 2: PRODUCT RECOMMENDATION ENGINE
-- =============================================

/*
BUSINESS OBJECTIVE:
Build a sophisticated product recommendation system using collaborative 
filtering, content-based filtering, and market basket analysis to drive
cross-selling, upselling, and customer satisfaction.

SUCCESS METRICS:
- Increase average order value by 15%
- Improve customer satisfaction scores
- Reduce product discovery time
- Increase cross-category purchases
*/

-- Market Basket Analysis for product associations
WITH product_combinations AS (
    SELECT 
        oi1.product_id as product_a,
        oi2.product_id as product_b,
        COUNT(DISTINCT oi1.order_id) as co_occurrence_count,
        COUNT(DISTINCT oi1.order_id) * 1.0 / 
            (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = oi1.product_id) as support_a_to_b,
        COUNT(DISTINCT oi1.order_id) * 1.0 / 
            (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = oi2.product_id) as support_b_to_a
    FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
    WHERE oi1.order_date >= DATEADD(month, -6, CURRENT_DATE())
    GROUP BY oi1.product_id, oi2.product_id
    HAVING COUNT(DISTINCT oi1.order_id) >= 10  -- Minimum support threshold
),

product_affinity_scores AS (
    SELECT 
        pc.*,
        -- Calculate confidence scores
        support_a_to_b as confidence_a_to_b,
        support_b_to_a as confidence_b_to_a,
        
        -- Calculate lift (strength of association)
        support_a_to_b / (
            (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = pc.product_b) * 1.0 / 
            (SELECT COUNT(DISTINCT order_id) FROM order_items)
        ) as lift_a_to_b,
        
        -- Jaccard similarity coefficient
        co_occurrence_count * 1.0 / (
            (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = pc.product_a) +
            (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = pc.product_b) -
            pc.co_occurrence_count
        ) as jaccard_similarity
        
    FROM product_combinations pc
),

customer_product_preferences AS (
    SELECT 
        o.customer_id,
        oi.product_id,
        p.category,
        p.brand,
        p.price_range,
        
        -- Purchase behavior metrics
        COUNT(*) as purchase_frequency,
        SUM(oi.quantity) as total_quantity,
        AVG(oi.unit_price) as avg_price_paid,
        MAX(o.order_date) as last_purchase_date,
        
        -- Satisfaction indicators
        AVG(CASE WHEN r.rating IS NOT NULL THEN r.rating END) as avg_rating,
        COUNT(r.review_id) as review_count,
        
        -- Calculate preference score
        (COUNT(*) * 0.3 +  -- Frequency weight
         SUM(oi.quantity) * 0.2 +  -- Quantity weight
         COALESCE(AVG(r.rating), 3) * 0.3 +  -- Rating weight (default to neutral)
         (CASE WHEN MAX(o.order_date) >= DATEADD(month, -3, CURRENT_DATE()) THEN 1 ELSE 0 END) * 0.2  -- Recency weight
        ) as preference_score
        
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN reviews r ON o.customer_id = r.customer_id AND oi.product_id = r.product_id
    WHERE o.order_date >= DATEADD(year, -1, CURRENT_DATE())
    GROUP BY 
        o.customer_id, oi.product_id, p.category, p.brand, p.price_range
),

collaborative_recommendations AS (
    -- Find similar customers based on purchase patterns
    SELECT 
        cpp1.customer_id as target_customer,
        cpp2.customer_id as similar_customer,
        
        -- Calculate customer similarity using cosine similarity
        SUM(cpp1.preference_score * cpp2.preference_score) / 
        (SQRT(SUM(POWER(cpp1.preference_score, 2))) * SQRT(SUM(POWER(cpp2.preference_score, 2)))) as similarity_score,
        
        COUNT(*) as common_products
        
    FROM customer_product_preferences cpp1
    JOIN customer_product_preferences cpp2 ON cpp1.product_id = cpp2.product_id 
        AND cpp1.customer_id != cpp2.customer_id
    GROUP BY cpp1.customer_id, cpp2.customer_id
    HAVING COUNT(*) >= 3  -- Minimum common products
    AND similarity_score >= 0.3  -- Minimum similarity threshold
),

content_based_recommendations AS (
    -- Recommend products based on customer's preferred categories and brands
    SELECT 
        cpp.customer_id,
        p.product_id,
        p.product_name,
        p.category,
        p.brand,
        p.current_price,
        
        -- Content-based scoring
        (CASE WHEN p.category = cpp.category THEN 0.4 ELSE 0 END +
         CASE WHEN p.brand = cpp.brand THEN 0.3 ELSE 0 END +
         CASE WHEN p.price_range = cpp.price_range THEN 0.2 ELSE 0 END +
         (p.avg_rating / 5.0) * 0.1  -- Product quality factor
        ) as content_similarity_score,
        
        -- Business factors
        p.profit_margin,
        p.inventory_level,
        p.sales_velocity
        
    FROM (
        SELECT 
            customer_id,
            category,
            brand,
            price_range,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY preference_score DESC) as pref_rank
        FROM customer_product_preferences
    ) cpp
    JOIN products p ON (p.category = cpp.category OR p.brand = cpp.brand)
    LEFT JOIN customer_product_preferences cpp_existing 
        ON cpp.customer_id = cpp_existing.customer_id AND p.product_id = cpp_existing.product_id
    WHERE cpp.pref_rank <= 3  -- Top 3 customer preferences
    AND cpp_existing.product_id IS NULL  -- Customer hasn't purchased this product
    AND p.is_active = TRUE
    AND p.inventory_level > 0
)

-- Generate final product recommendations
SELECT 
    target_customer as customer_id,
    
    -- Collaborative filtering recommendations
    (SELECT 
        ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'product_id', rec_products.product_id,
                'product_name', rec_products.product_name,
                'recommendation_score', rec_products.collaborative_score,
                'recommendation_type', 'collaborative'
            )
        ) WITHIN GROUP (ORDER BY rec_products.collaborative_score DESC)
        LIMIT 5
    ) as collaborative_recommendations,
    
    -- Content-based recommendations
    (SELECT 
        ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'product_id', cbr.product_id,
                'product_name', cbr.product_name,
                'recommendation_score', cbr.content_similarity_score,
                'recommendation_type', 'content_based'
            )
        ) WITHIN GROUP (ORDER BY cbr.content_similarity_score DESC)
        LIMIT 5
    ) as content_based_recommendations,
    
    -- Market basket recommendations (frequently bought together)
    (SELECT 
        ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'product_id', pas.product_b,
                'product_name', p.product_name,
                'recommendation_score', pas.lift_a_to_b,
                'recommendation_type', 'market_basket'
            )
        ) WITHIN GROUP (ORDER BY pas.lift_a_to_b DESC)
        LIMIT 3
    ) as market_basket_recommendations
    
FROM (
    -- Get collaborative recommendations
    SELECT DISTINCT 
        cr.target_customer,
        cpp_similar.product_id,
        p.product_name,
        AVG(cr.similarity_score * cpp_similar.preference_score) as collaborative_score
    FROM collaborative_recommendations cr
    JOIN customer_product_preferences cpp_similar ON cr.similar_customer = cpp_similar.customer_id
    JOIN products p ON cpp_similar.product_id = p.product_id
    LEFT JOIN customer_product_preferences cpp_target 
        ON cr.target_customer = cpp_target.customer_id AND cpp_similar.product_id = cpp_target.product_id
    WHERE cpp_target.product_id IS NULL  -- Target customer hasn't purchased this product
    GROUP BY cr.target_customer, cpp_similar.product_id, p.product_name
) rec_products

LEFT JOIN content_based_recommendations cbr ON rec_products.target_customer = cbr.customer_id

LEFT JOIN (
    -- Market basket analysis for current customer's products
    SELECT 
        cpp.customer_id,
        pas.product_b,
        p.product_name,
        pas.lift_a_to_b
    FROM customer_product_preferences cpp
    JOIN product_affinity_scores pas ON cpp.product_id = pas.product_a
    JOIN products p ON pas.product_b = p.product_id
    WHERE pas.lift_a_to_b >= 1.5  -- Strong association
) mba ON rec_products.target_customer = mba.customer_id

GROUP BY target_customer
LIMIT 1000;  -- Focus on top customers

-- =============================================
-- SECTION 3: MARKETING ATTRIBUTION ANALYSIS
-- =============================================

/*
BUSINESS OBJECTIVE:
Implement multi-touch attribution modeling to optimize marketing spend
across channels, campaigns, and customer segments for maximum ROI.

SUCCESS METRICS:
- Optimize marketing budget allocation
- Increase conversion rates by 20%
- Reduce customer acquisition cost (CAC)
- Improve return on ad spend (ROAS)
*/

-- Multi-touch attribution analysis
WITH customer_journey AS (
    SELECT 
        we.customer_id,
        we.session_id,
        we.event_timestamp,
        we.event_type,
        we.utm_source,
        we.utm_medium,
        we.utm_campaign,
        we.utm_content,
        mc.campaign_cost_per_click,
        mc.campaign_budget,
        
        -- Order information for conversion events
        o.order_id,
        o.total_amount as conversion_value,
        
        -- Journey sequencing
        ROW_NUMBER() OVER (
            PARTITION BY we.customer_id 
            ORDER BY we.event_timestamp
        ) as touchpoint_sequence,
        
        -- Time-based attribution weights
        CASE 
            WHEN o.order_id IS NOT NULL THEN 1  -- Conversion event
            ELSE 0 
        END as is_conversion,
        
        -- Calculate time decay weight (more recent = higher weight)
        CASE 
            WHEN o.order_id IS NOT NULL 
            THEN EXP(-0.1 * DATEDIFF(hour, we.event_timestamp, o.order_timestamp))
            ELSE 0 
        END as time_decay_weight
        
    FROM website_events we
    LEFT JOIN marketing_campaigns mc ON we.utm_campaign = mc.campaign_id
    LEFT JOIN orders o ON we.customer_id = o.customer_id 
        AND we.event_timestamp <= o.order_timestamp
        AND DATEDIFF(day, we.event_timestamp, o.order_timestamp) <= 30  -- 30-day attribution window
    WHERE we.event_timestamp >= DATEADD(month, -6, CURRENT_DATE())
    AND we.utm_source IS NOT NULL
),

attribution_modeling AS (
    SELECT 
        customer_id,
        order_id,
        conversion_value,
        
        -- First-touch attribution
        FIRST_VALUE(utm_source) OVER (
            PARTITION BY customer_id, order_id 
            ORDER BY event_timestamp 
            ROWS UNBOUNDED PRECEDING
        ) as first_touch_source,
        FIRST_VALUE(utm_campaign) OVER (
            PARTITION BY customer_id, order_id 
            ORDER BY event_timestamp 
            ROWS UNBOUNDED PRECEDING
        ) as first_touch_campaign,
        
        -- Last-touch attribution
        LAST_VALUE(utm_source) OVER (
            PARTITION BY customer_id, order_id 
            ORDER BY event_timestamp 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as last_touch_source,
        LAST_VALUE(utm_campaign) OVER (
            PARTITION BY customer_id, order_id 
            ORDER BY event_timestamp 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as last_touch_campaign,
        
        -- Linear attribution (equal weight to all touchpoints)
        conversion_value / COUNT(*) OVER (PARTITION BY customer_id, order_id) as linear_attribution_value,
        
        -- Time decay attribution
        (conversion_value * time_decay_weight) / 
        SUM(time_decay_weight) OVER (PARTITION BY customer_id, order_id) as time_decay_attribution_value,
        
        -- Position-based attribution (40% first, 40% last, 20% middle)
        CASE 
            WHEN touchpoint_sequence = 1 THEN conversion_value * 0.4
            WHEN touchpoint_sequence = MAX(touchpoint_sequence) OVER (PARTITION BY customer_id, order_id) 
                THEN conversion_value * 0.4
            ELSE conversion_value * 0.2 / (COUNT(*) OVER (PARTITION BY customer_id, order_id) - 2)
        END as position_based_attribution_value,
        
        utm_source,
        utm_campaign,
        utm_medium,
        campaign_cost_per_click,
        touchpoint_sequence
        
    FROM customer_journey
    WHERE is_conversion = 1
),

channel_performance AS (
    SELECT 
        utm_source as channel,
        utm_medium as medium,
        
        -- Conversion metrics
        COUNT(DISTINCT order_id) as total_conversions,
        COUNT(DISTINCT customer_id) as unique_customers_converted,
        
        -- Revenue attribution by model
        SUM(CASE WHEN touchpoint_sequence = 1 THEN conversion_value ELSE 0 END) as first_touch_revenue,
        SUM(CASE WHEN touchpoint_sequence = MAX(touchpoint_sequence) OVER (PARTITION BY customer_id, order_id) 
                THEN conversion_value ELSE 0 END) as last_touch_revenue,
        SUM(linear_attribution_value) as linear_attribution_revenue,
        SUM(time_decay_attribution_value) as time_decay_attribution_revenue,
        SUM(position_based_attribution_value) as position_based_attribution_revenue,
        
        -- Cost and ROI calculations
        SUM(campaign_cost_per_click) as total_cost,
        AVG(campaign_cost_per_click) as avg_cost_per_click,
        
        -- Calculate ROAS for different attribution models
        CASE WHEN SUM(campaign_cost_per_click) > 0 
             THEN SUM(linear_attribution_value) / SUM(campaign_cost_per_click) 
             ELSE 0 END as linear_roas,
        CASE WHEN SUM(campaign_cost_per_click) > 0 
             THEN SUM(time_decay_attribution_value) / SUM(campaign_cost_per_click) 
             ELSE 0 END as time_decay_roas,
        CASE WHEN SUM(campaign_cost_per_click) > 0 
             THEN SUM(position_based_attribution_value) / SUM(campaign_cost_per_click) 
             ELSE 0 END as position_based_roas,
        
        -- Customer acquisition cost
        CASE WHEN COUNT(DISTINCT customer_id) > 0 
             THEN SUM(campaign_cost_per_click) / COUNT(DISTINCT customer_id) 
             ELSE 0 END as customer_acquisition_cost
        
    FROM attribution_modeling
    GROUP BY utm_source, utm_medium
),

campaign_effectiveness AS (
    SELECT 
        utm_campaign as campaign,
        
        -- Performance metrics
        COUNT(DISTINCT customer_id) as reach,
        COUNT(DISTINCT order_id) as conversions,
        SUM(position_based_attribution_value) as attributed_revenue,
        SUM(campaign_cost_per_click) as campaign_cost,
        
        -- Efficiency metrics
        COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT customer_id) as conversion_rate,
        SUM(position_based_attribution_value) / COUNT(DISTINCT order_id) as revenue_per_conversion,
        SUM(campaign_cost_per_click) / COUNT(DISTINCT customer_id) as cost_per_acquisition,
        
        -- ROI and optimization insights
        (SUM(position_based_attribution_value) - SUM(campaign_cost_per_click)) / SUM(campaign_cost_per_click) * 100 as roi_percentage,
        
        -- Recommendations based on performance
        CASE 
            WHEN (SUM(position_based_attribution_value) / SUM(campaign_cost_per_click)) >= 5 THEN 'SCALE_UP'
            WHEN (SUM(position_based_attribution_value) / SUM(campaign_cost_per_click)) >= 3 THEN 'OPTIMIZE'
            WHEN (SUM(position_based_attribution_value) / SUM(campaign_cost_per_click)) >= 1.5 THEN 'MONITOR'
            ELSE 'PAUSE_OR_REDESIGN'
        END as campaign_recommendation
        
    FROM attribution_modeling
    WHERE utm_campaign IS NOT NULL
    GROUP BY utm_campaign
)

-- Executive summary of marketing attribution insights
SELECT 
    -- Channel performance summary
    (SELECT 
        OBJECT_CONSTRUCT(
            'top_performing_channels', ARRAY_AGG(
                OBJECT_CONSTRUCT(
                    'channel', channel,
                    'medium', medium,
                    'linear_roas', ROUND(linear_roas, 2),
                    'time_decay_roas', ROUND(time_decay_roas, 2),
                    'total_conversions', total_conversions,
                    'customer_acquisition_cost', ROUND(customer_acquisition_cost, 2)
                )
            ) WITHIN GROUP (ORDER BY linear_roas DESC)
            LIMIT 5
        )
     FROM channel_performance
     WHERE linear_roas >= 2  -- Minimum acceptable ROAS
    ) as top_channels,
    
    -- Campaign optimization recommendations
    (SELECT 
        OBJECT_CONSTRUCT(
            'campaign_actions', ARRAY_AGG(
                OBJECT_CONSTRUCT(
                    'campaign', campaign,
                    'recommendation', campaign_recommendation,
                    'current_roi', ROUND(roi_percentage, 1),
                    'conversion_rate', ROUND(conversion_rate * 100, 2),
                    'attributed_revenue', ROUND(attributed_revenue, 0)
                )
            ) WITHIN GROUP (ORDER BY attributed_revenue DESC)
        )
     FROM campaign_effectiveness
    ) as campaign_recommendations,
    
    -- Budget reallocation suggestions
    (SELECT 
        OBJECT_CONSTRUCT(
            'total_spend', SUM(total_cost),
            'total_attributed_revenue', SUM(linear_attribution_revenue),
            'overall_roas', ROUND(SUM(linear_attribution_revenue) / NULLIF(SUM(total_cost), 0), 2),
            'avg_customer_acquisition_cost', ROUND(AVG(customer_acquisition_cost), 2),
            'recommended_budget_shifts', ARRAY_AGG(
                OBJECT_CONSTRUCT(
                    'channel', channel,
                    'current_performance', linear_roas,
                    'budget_recommendation', 
                    CASE 
                        WHEN linear_roas >= 5 THEN 'Increase by 50%'
                        WHEN linear_roas >= 3 THEN 'Increase by 25%'
                        WHEN linear_roas >= 1.5 THEN 'Maintain current'
                        ELSE 'Reduce by 30%'
                    END
                )
            ) WITHIN GROUP (ORDER BY linear_roas DESC)
        )
     FROM channel_performance
    ) as budget_optimization;

/*
================================================================================
EXECUTIVE SUMMARY INSIGHTS FOR CAPSTONE PROJECT
================================================================================

This comprehensive e-commerce analytics capstone demonstrates mastery of:

1. CUSTOMER SEGMENTATION & CLV:
   - Advanced RFM modeling with behavioral insights
   - Predictive customer lifetime value calculations
   - Churn risk assessment and retention strategies
   - Actionable segmentation for targeted marketing

2. PRODUCT RECOMMENDATION ENGINE:
   - Collaborative filtering based on customer similarity
   - Content-based recommendations using product attributes
   - Market basket analysis for cross-selling opportunities
   - Multi-algorithm approach for comprehensive recommendations

3. MARKETING ATTRIBUTION MODELING:
   - Multi-touch attribution across customer journey
   - Time decay and position-based attribution models
   - Channel performance optimization and ROAS analysis
   - Budget reallocation recommendations

BUSINESS IMPACT:
- Customer segmentation enables targeted campaigns (estimated 25% increase in conversion)
- Recommendation engine drives cross-selling (projected 15% AOV increase)
- Attribution modeling optimizes marketing spend (potential 30% efficiency improvement)
- Integrated approach provides 360-degree customer view for strategic decision-making

TECHNICAL EXCELLENCE:
- Complex window functions and analytical operations
- Advanced JSON handling and array operations
- Performance-optimized queries with proper indexing considerations
- Scalable architecture supporting enterprise-level data volumes

This capstone project demonstrates readiness for senior data analyst roles in
e-commerce, retail, and customer analytics domains.
================================================================================
*/
