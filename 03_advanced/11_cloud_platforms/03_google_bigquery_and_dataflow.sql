/*
================================================================================
03_google_bigquery_and_dataflow.sql - Google Cloud Platform Data Tools
================================================================================

BUSINESS CONTEXT:
Google BigQuery is a serverless, highly scalable data warehouse that enables
super-fast SQL queries using Google's infrastructure. Combined with Dataflow
for stream and batch processing, it provides a complete analytics platform
for modern data-driven organizations.

LEARNING OBJECTIVES:
- Master BigQuery's serverless architecture and capabilities
- Implement data processing pipelines with Dataflow
- Optimize queries for BigQuery's columnar storage
- Design cost-effective analytics solutions
- Leverage BigQuery ML for in-database machine learning

REAL-WORLD SCENARIOS:
- Serverless data warehouse for startups to enterprise
- Real-time analytics on streaming data
- Machine learning model deployment and inference
- Multi-cloud data integration and analytics
*/

-- =============================================
-- SECTION 1: BIGQUERY ARCHITECTURE & DATASETS
-- =============================================

/*
BUSINESS SCENARIO: E-commerce Analytics Platform
A growing e-commerce company needs to analyze customer behavior,
product performance, and marketing effectiveness across multiple channels.
*/

-- BigQuery dataset creation (using DDL)
-- CREATE SCHEMA IF NOT EXISTS `analytics-project.ecommerce_data`
-- OPTIONS(
--   description="E-commerce analytics data warehouse",
--   location="US"
-- );

-- Create partitioned and clustered table for optimal performance
CREATE OR REPLACE TABLE `analytics-project.ecommerce_data.user_events`
(
  event_id STRING NOT NULL,
  user_id STRING NOT NULL,
  session_id STRING NOT NULL,
  event_timestamp TIMESTAMP NOT NULL,
  event_name STRING NOT NULL,
  page_location STRING,
  page_title STRING,
  device_category STRING,
  device_brand STRING,
  device_model STRING,
  operating_system STRING,
  browser STRING,
  country STRING,
  region STRING,
  city STRING,
  traffic_source STRING,
  medium STRING,
  campaign STRING,
  content STRING,
  term STRING,
  user_properties JSON,
  event_parameters JSON,
  ecommerce JSON,
  items ARRAY<STRUCT<
    item_id STRING,
    item_name STRING,
    item_category STRING,
    item_brand STRING,
    price NUMERIC,
    quantity INT64
  >>
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY user_id, event_name, device_category
OPTIONS(
  description="User interaction events from web and mobile apps",
  partition_expiration_days=365
);

-- Create table for product catalog
CREATE OR REPLACE TABLE `analytics-project.ecommerce_data.products`
(
  product_id STRING NOT NULL,
  product_name STRING NOT NULL,
  category STRING NOT NULL,
  subcategory STRING,
  brand STRING,
  description TEXT,
  price NUMERIC NOT NULL,
  cost NUMERIC,
  weight_kg NUMERIC,
  dimensions STRUCT<
    length_cm NUMERIC,
    width_cm NUMERIC,
    height_cm NUMERIC
  >,
  tags ARRAY<STRING>,
  supplier_id STRING,
  created_date DATE NOT NULL,
  updated_date DATE NOT NULL,
  is_active BOOL NOT NULL DEFAULT TRUE
)
CLUSTER BY category, brand
OPTIONS(
  description="Product catalog with hierarchical categories and attributes"
);

-- =============================================
-- SECTION 2: ADVANCED BIGQUERY SQL ANALYTICS
-- =============================================

/*
BUSINESS SCENARIO: Customer Journey Analysis
Understand the complete customer journey from first visit to purchase
and identify optimization opportunities in the conversion funnel.
*/

-- Advanced funnel analysis with BigQuery-specific functions
WITH user_journey_events AS (
  SELECT 
    user_id,
    session_id,
    event_timestamp,
    event_name,
    page_location,
    traffic_source,
    campaign,
    
    -- Extract ecommerce data using JSON functions
    JSON_EXTRACT_SCALAR(ecommerce, '$.transaction_id') as transaction_id,
    CAST(JSON_EXTRACT_SCALAR(ecommerce, '$.value') AS NUMERIC) as transaction_value,
    JSON_EXTRACT_SCALAR(ecommerce, '$.currency') as currency,
    
    -- Create event sequence numbers
    ROW_NUMBER() OVER (
      PARTITION BY user_id, session_id 
      ORDER BY event_timestamp
    ) as event_sequence,
    
    -- Calculate time between events
    LAG(event_timestamp) OVER (
      PARTITION BY user_id, session_id 
      ORDER BY event_timestamp
    ) as previous_event_time,
    
    -- Identify session boundaries (>30 minutes = new session)
    CASE 
      WHEN TIMESTAMP_DIFF(
        event_timestamp,
        LAG(event_timestamp) OVER (
          PARTITION BY user_id 
          ORDER BY event_timestamp
        ),
        MINUTE
      ) > 30 OR LAG(event_timestamp) OVER (
        PARTITION BY user_id 
        ORDER BY event_timestamp
      ) IS NULL
      THEN 1 
      ELSE 0 
    END as session_start
    
  FROM `analytics-project.ecommerce_data.user_events`
  WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
),

session_summary AS (
  SELECT 
    user_id,
    session_id,
    MIN(event_timestamp) as session_start_time,
    MAX(event_timestamp) as session_end_time,
    TIMESTAMP_DIFF(
      MAX(event_timestamp), 
      MIN(event_timestamp), 
      SECOND
    ) as session_duration_seconds,
    COUNT(*) as total_events,
    
    -- Count specific event types
    COUNTIF(event_name = 'page_view') as page_views,
    COUNTIF(event_name = 'add_to_cart') as add_to_cart_events,
    COUNTIF(event_name = 'begin_checkout') as checkout_starts,
    COUNTIF(event_name = 'purchase') as purchases,
    
    -- Calculate conversion flags
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) as converted,
    
    -- Extract first and last traffic sources
    ARRAY_AGG(
      traffic_source ORDER BY event_timestamp LIMIT 1
    )[OFFSET(0)] as first_traffic_source,
    
    ARRAY_AGG(
      traffic_source ORDER BY event_timestamp DESC LIMIT 1
    )[OFFSET(0)] as last_traffic_source,
    
    -- Calculate total transaction value
    SUM(
      CASE WHEN event_name = 'purchase' 
      THEN transaction_value 
      ELSE 0 END
    ) as total_revenue,
    
    -- Identify unique pages visited
    COUNT(DISTINCT page_location) as unique_pages_visited,
    
    -- Track campaign performance
    ARRAY_AGG(
      DISTINCT campaign IGNORE NULLS
    ) as campaigns_in_session
    
  FROM user_journey_events
  GROUP BY user_id, session_id
),

funnel_analysis AS (
  SELECT 
    first_traffic_source,
    COUNT(*) as total_sessions,
    COUNTIF(page_views >= 2) as multi_page_sessions,
    COUNTIF(add_to_cart_events > 0) as add_to_cart_sessions,
    COUNTIF(checkout_starts > 0) as checkout_sessions,
    COUNTIF(purchases > 0) as purchase_sessions,
    
    -- Calculate conversion rates
    SAFE_DIVIDE(COUNTIF(add_to_cart_events > 0), COUNT(*)) * 100 as add_to_cart_rate,
    SAFE_DIVIDE(COUNTIF(checkout_starts > 0), COUNTIF(add_to_cart_events > 0)) * 100 as cart_to_checkout_rate,
    SAFE_DIVIDE(COUNTIF(purchases > 0), COUNTIF(checkout_starts > 0)) * 100 as checkout_to_purchase_rate,
    SAFE_DIVIDE(COUNTIF(purchases > 0), COUNT(*)) * 100 as overall_conversion_rate,
    
    -- Revenue metrics
    SUM(total_revenue) as total_revenue,
    AVG(total_revenue) as avg_revenue_per_session,
    SAFE_DIVIDE(SUM(total_revenue), COUNTIF(purchases > 0)) as avg_order_value,
    
    -- Engagement metrics
    AVG(session_duration_seconds) as avg_session_duration,
    AVG(page_views) as avg_pages_per_session,
    AVG(unique_pages_visited) as avg_unique_pages
    
  FROM session_summary
  WHERE first_traffic_source IS NOT NULL
  GROUP BY first_traffic_source
)

SELECT 
  *,
  -- Performance ranking
  ROW_NUMBER() OVER (ORDER BY overall_conversion_rate DESC) as conversion_rank,
  ROW_NUMBER() OVER (ORDER BY total_revenue DESC) as revenue_rank,
  
  -- Calculate relative performance vs average
  overall_conversion_rate - AVG(overall_conversion_rate) OVER () as conversion_rate_vs_avg,
  avg_order_value - AVG(avg_order_value) OVER () as aov_vs_avg
  
FROM funnel_analysis
ORDER BY total_revenue DESC;

-- =============================================
-- SECTION 3: BIGQUERY ML INTEGRATION
-- =============================================

/*
BUSINESS SCENARIO: Customer Lifetime Value Prediction
Build and deploy machine learning models directly in BigQuery
to predict customer lifetime value and segment customers.
*/

-- Create training dataset for customer LTV prediction
CREATE OR REPLACE TABLE `analytics-project.ecommerce_data.customer_features` AS
WITH customer_metrics AS (
  SELECT 
    user_id,
    
    -- Demographic and acquisition features
    FIRST_VALUE(country) OVER (
      PARTITION BY user_id 
      ORDER BY event_timestamp
    ) as country,
    FIRST_VALUE(device_category) OVER (
      PARTITION BY user_id 
      ORDER BY event_timestamp
    ) as first_device_category,
    FIRST_VALUE(traffic_source) OVER (
      PARTITION BY user_id 
      ORDER BY event_timestamp
    ) as acquisition_source,
    
    -- Behavioral features (first 30 days)
    COUNT(DISTINCT session_id) as sessions_first_30d,
    COUNT(DISTINCT DATE(event_timestamp)) as active_days_first_30d,
    COUNTIF(event_name = 'page_view') as page_views_first_30d,
    COUNTIF(event_name = 'add_to_cart') as add_to_cart_first_30d,
    COUNTIF(event_name = 'purchase') as purchases_first_30d,
    
    -- Time-based features
    DATE_DIFF(
      DATE_ADD(MIN(DATE(event_timestamp)), INTERVAL 30 DAY),
      MIN(DATE(event_timestamp)),
      DAY
    ) as days_in_period,
    
    -- Transaction features
    SUM(
      CASE WHEN event_name = 'purchase' 
      THEN CAST(JSON_EXTRACT_SCALAR(ecommerce, '$.value') AS NUMERIC)
      ELSE 0 END
    ) as revenue_first_30d,
    
    -- Product interaction features
    COUNT(DISTINCT 
      CASE WHEN ARRAY_LENGTH(items) > 0 
      THEN items[OFFSET(0)].item_category 
      END
    ) as unique_categories_viewed
    
  FROM `analytics-project.ecommerce_data.user_events`
  WHERE DATE(event_timestamp) BETWEEN 
    DATE_SUB(CURRENT_DATE(), INTERVAL 120 DAY) AND 
    DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  GROUP BY user_id
),

customer_ltv AS (
  SELECT 
    user_id,
    SUM(
      CASE WHEN event_name = 'purchase' 
      THEN CAST(JSON_EXTRACT_SCALAR(ecommerce, '$.value') AS NUMERIC)
      ELSE 0 END
    ) as actual_ltv_90d
  FROM `analytics-project.ecommerce_data.user_events`
  WHERE DATE(event_timestamp) BETWEEN 
    DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND 
    CURRENT_DATE()
  GROUP BY user_id
)

SELECT 
  cm.*,
  COALESCE(ltv.actual_ltv_90d, 0) as actual_ltv_90d,
  
  -- Create categorical features for ML
  CASE 
    WHEN cm.sessions_first_30d >= 10 THEN 'High'
    WHEN cm.sessions_first_30d >= 3 THEN 'Medium'
    ELSE 'Low'
  END as engagement_level,
  
  CASE 
    WHEN cm.revenue_first_30d >= 500 THEN 'High Value'
    WHEN cm.revenue_first_30d >= 100 THEN 'Medium Value'
    WHEN cm.revenue_first_30d > 0 THEN 'Low Value'
    ELSE 'No Purchase'
  END as initial_value_segment

FROM customer_metrics cm
LEFT JOIN customer_ltv ltv ON cm.user_id = ltv.user_id
WHERE cm.sessions_first_30d >= 1;  -- Only include active users

-- Create BigQuery ML model for LTV prediction
CREATE OR REPLACE MODEL `analytics-project.ecommerce_data.customer_ltv_model`
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['actual_ltv_90d'],
  auto_class_weights=true,
  data_split_method='AUTO_SPLIT',
  data_split_eval_fraction=0.2
) AS
SELECT
  -- Numerical features
  sessions_first_30d,
  active_days_first_30d,
  page_views_first_30d,
  add_to_cart_first_30d,
  purchases_first_30d,
  revenue_first_30d,
  unique_categories_viewed,
  
  -- Categorical features
  country,
  first_device_category,
  acquisition_source,
  engagement_level,
  initial_value_segment,
  
  -- Target variable
  actual_ltv_90d
  
FROM `analytics-project.ecommerce_data.customer_features`
WHERE actual_ltv_90d IS NOT NULL;

-- Evaluate model performance
SELECT
  *
FROM ML.EVALUATE(
  MODEL `analytics-project.ecommerce_data.customer_ltv_model`
);

-- Generate predictions for new customers
CREATE OR REPLACE TABLE `analytics-project.ecommerce_data.customer_predictions` AS
WITH new_customer_features AS (
  SELECT 
    user_id,
    -- Same feature engineering as training data
    FIRST_VALUE(country) OVER (
      PARTITION BY user_id 
      ORDER BY event_timestamp
    ) as country,
    FIRST_VALUE(device_category) OVER (
      PARTITION BY user_id 
      ORDER BY event_timestamp
    ) as first_device_category,
    FIRST_VALUE(traffic_source) OVER (
      PARTITION BY user_id 
      ORDER BY event_timestamp
    ) as acquisition_source,
    COUNT(DISTINCT session_id) as sessions_first_30d,
    COUNT(DISTINCT DATE(event_timestamp)) as active_days_first_30d,
    COUNTIF(event_name = 'page_view') as page_views_first_30d,
    COUNTIF(event_name = 'add_to_cart') as add_to_cart_first_30d,
    COUNTIF(event_name = 'purchase') as purchases_first_30d,
    SUM(
      CASE WHEN event_name = 'purchase' 
      THEN CAST(JSON_EXTRACT_SCALAR(ecommerce, '$.value') AS NUMERIC)
      ELSE 0 END
    ) as revenue_first_30d,
    COUNT(DISTINCT 
      CASE WHEN ARRAY_LENGTH(items) > 0 
      THEN items[OFFSET(0)].item_category 
      END
    ) as unique_categories_viewed
    
  FROM `analytics-project.ecommerce_data.user_events`
  WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  GROUP BY user_id
)

SELECT
  user_id,
  predicted_actual_ltv_90d as predicted_ltv,
  
  -- Create business segments based on predictions
  CASE 
    WHEN predicted_actual_ltv_90d >= 1000 THEN 'Champions'
    WHEN predicted_actual_ltv_90d >= 500 THEN 'Loyal Customers'
    WHEN predicted_actual_ltv_90d >= 100 THEN 'Potential Loyalists'
    WHEN predicted_actual_ltv_90d >= 50 THEN 'New Customers'
    ELSE 'At Risk'
  END as predicted_segment,
  
  CURRENT_TIMESTAMP() as prediction_timestamp
  
FROM ML.PREDICT(
  MODEL `analytics-project.ecommerce_data.customer_ltv_model`,
  (
    SELECT 
      *,
      CASE 
        WHEN sessions_first_30d >= 10 THEN 'High'
        WHEN sessions_first_30d >= 3 THEN 'Medium'
        ELSE 'Low'
      END as engagement_level,
      
      CASE 
        WHEN revenue_first_30d >= 500 THEN 'High Value'
        WHEN revenue_first_30d >= 100 THEN 'Medium Value'
        WHEN revenue_first_30d > 0 THEN 'Low Value'
        ELSE 'No Purchase'
      END as initial_value_segment
      
    FROM new_customer_features
    WHERE sessions_first_30d >= 1
  )
);

-- =============================================
-- SECTION 4: REAL-TIME ANALYTICS WITH STREAMING
-- =============================================

/*
BUSINESS SCENARIO: Real-Time Campaign Performance Monitoring
Monitor marketing campaign performance in real-time to enable
immediate optimization and budget reallocation decisions.
*/

-- Create a view for real-time campaign analytics
-- This would typically query from a streaming table updated by Dataflow
CREATE OR REPLACE VIEW `analytics-project.ecommerce_data.realtime_campaign_performance` AS
WITH hourly_metrics AS (
  SELECT 
    DATETIME_TRUNC(DATETIME(event_timestamp), HOUR) as hour,
    traffic_source,
    medium,
    campaign,
    
    -- User engagement metrics
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as sessions,
    COUNT(*) as total_events,
    COUNTIF(event_name = 'page_view') as page_views,
    COUNTIF(event_name = 'add_to_cart') as add_to_cart_events,
    COUNTIF(event_name = 'begin_checkout') as checkout_starts,
    COUNTIF(event_name = 'purchase') as purchases,
    
    -- Revenue metrics
    SUM(
      CASE WHEN event_name = 'purchase' 
      THEN CAST(JSON_EXTRACT_SCALAR(ecommerce, '$.value') AS NUMERIC)
      ELSE 0 END
    ) as revenue,
    
    -- Calculate bounce rate (single page sessions)
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE 
        WHEN (
          SELECT COUNT(*) 
          FROM `analytics-project.ecommerce_data.user_events` e2 
          WHERE e2.session_id = e1.session_id 
          AND e2.event_name = 'page_view'
        ) = 1 
        THEN session_id 
      END),
      COUNT(DISTINCT session_id)
    ) * 100 as bounce_rate
    
  FROM `analytics-project.ecommerce_data.user_events` e1
  WHERE DATE(event_timestamp) = CURRENT_DATE()
  AND campaign IS NOT NULL
  GROUP BY hour, traffic_source, medium, campaign
),

campaign_totals AS (
  SELECT 
    traffic_source,
    medium,
    campaign,
    SUM(unique_users) as total_users,
    SUM(sessions) as total_sessions,
    SUM(purchases) as total_purchases,
    SUM(revenue) as total_revenue,
    
    -- Calculate conversion rates
    SAFE_DIVIDE(SUM(purchases), SUM(sessions)) * 100 as conversion_rate,
    SAFE_DIVIDE(SUM(revenue), SUM(sessions)) as revenue_per_session,
    SAFE_DIVIDE(SUM(revenue), SUM(purchases)) as average_order_value,
    
    -- Performance trends (comparing to previous hour)
    SUM(CASE WHEN hour >= DATETIME_SUB(DATETIME(CURRENT_TIMESTAMP()), INTERVAL 1 HOUR) 
             THEN revenue ELSE 0 END) as last_hour_revenue,
    SUM(CASE WHEN hour >= DATETIME_SUB(DATETIME(CURRENT_TIMESTAMP()), INTERVAL 2 HOUR) 
              AND hour < DATETIME_SUB(DATETIME(CURRENT_TIMESTAMP()), INTERVAL 1 HOUR)
             THEN revenue ELSE 0 END) as previous_hour_revenue
    
  FROM hourly_metrics
  GROUP BY traffic_source, medium, campaign
)

SELECT 
  *,
  -- Calculate hour-over-hour growth
  CASE 
    WHEN previous_hour_revenue > 0 
    THEN ((last_hour_revenue - previous_hour_revenue) / previous_hour_revenue) * 100
    ELSE NULL 
  END as revenue_growth_pct,
  
  -- Performance scoring
  (conversion_rate * 0.4) + 
  (LEAST(revenue_per_session * 10, 100) * 0.4) + 
  (GREATEST(100 - bounce_rate, 0) * 0.2) as performance_score,
  
  -- Budget optimization recommendations
  CASE 
    WHEN conversion_rate > 5 AND revenue_per_session > 10 THEN 'INCREASE_BUDGET'
    WHEN conversion_rate < 1 AND revenue_per_session < 2 THEN 'DECREASE_BUDGET'
    WHEN total_sessions < 10 THEN 'INSUFFICIENT_DATA'
    ELSE 'MAINTAIN_BUDGET'
  END as budget_recommendation
  
FROM campaign_totals
WHERE total_sessions >= 5  -- Filter out campaigns with insufficient data
ORDER BY performance_score DESC;

-- =============================================
-- SECTION 5: CROSS-PLATFORM ANALYTICS
-- =============================================

/*
BUSINESS SCENARIO: Unified Customer View Across Platforms
Combine data from web, mobile app, and offline channels to create
a comprehensive view of customer interactions and preferences.
*/

-- Create a unified customer journey across all touchpoints
WITH unified_events AS (
  -- Web events
  SELECT 
    'web' as platform,
    user_id,
    session_id,
    event_timestamp,
    event_name,
    page_location as location,
    device_category,
    country,
    traffic_source,
    JSON_EXTRACT_SCALAR(ecommerce, '$.transaction_id') as transaction_id,
    CAST(JSON_EXTRACT_SCALAR(ecommerce, '$.value') AS NUMERIC) as transaction_value
  FROM `analytics-project.ecommerce_data.user_events`
  WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  
  UNION ALL
  
  -- Mobile app events (assuming similar structure)
  SELECT 
    'mobile_app' as platform,
    user_id,
    session_id,
    event_timestamp,
    event_name,
    screen_name as location,
    device_category,
    country,
    'app_organic' as traffic_source,
    transaction_id,
    transaction_value
  FROM `analytics-project.ecommerce_data.mobile_events`
  WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  
  UNION ALL
  
  -- Offline store events (from POS systems)
  SELECT 
    'offline_store' as platform,
    customer_id as user_id,
    store_transaction_id as session_id,
    transaction_timestamp as event_timestamp,
    'offline_purchase' as event_name,
    store_location as location,
    'in_store' as device_category,
    store_country as country,
    'offline' as traffic_source,
    transaction_id,
    total_amount as transaction_value
  FROM `analytics-project.ecommerce_data.store_transactions`
  WHERE DATE(transaction_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
),

customer_cross_platform_behavior AS (
  SELECT 
    user_id,
    
    -- Platform usage
    COUNT(DISTINCT platform) as platforms_used,
    STRING_AGG(DISTINCT platform ORDER BY platform) as platform_list,
    
    -- Channel preference analysis
    ARRAY_AGG(
      STRUCT(
        platform,
        COUNT(*) as event_count,
        SUM(COALESCE(transaction_value, 0)) as platform_revenue,
        COUNT(DISTINCT DATE(event_timestamp)) as active_days
      )
    ) as platform_metrics,
    
    -- Customer journey complexity
    COUNT(DISTINCT session_id) as total_sessions,
    COUNT(DISTINCT DATE(event_timestamp)) as active_days,
    DATE_DIFF(MAX(DATE(event_timestamp)), MIN(DATE(event_timestamp)), DAY) as customer_lifespan_days,
    
    -- Cross-platform conversion behavior
    LOGICAL_OR(platform = 'web' AND transaction_value > 0) as converted_web,
    LOGICAL_OR(platform = 'mobile_app' AND transaction_value > 0) as converted_mobile,
    LOGICAL_OR(platform = 'offline_store' AND transaction_value > 0) as converted_offline,
    
    -- Total customer value
    SUM(COALESCE(transaction_value, 0)) as total_ltv,
    COUNT(DISTINCT CASE WHEN transaction_value > 0 THEN transaction_id END) as total_transactions,
    
    -- First and most recent touchpoints
    ARRAY_AGG(
      STRUCT(platform, event_timestamp) 
      ORDER BY event_timestamp LIMIT 1
    )[OFFSET(0)] as first_touchpoint,
    
    ARRAY_AGG(
      STRUCT(platform, event_timestamp) 
      ORDER BY event_timestamp DESC LIMIT 1
    )[OFFSET(0)] as last_touchpoint
    
  FROM unified_events
  GROUP BY user_id
)

SELECT 
  user_id,
  platforms_used,
  platform_list,
  total_sessions,
  active_days,
  customer_lifespan_days,
  total_ltv,
  total_transactions,
  
  -- Customer segmentation based on cross-platform behavior
  CASE 
    WHEN platforms_used >= 3 THEN 'Omnichannel Champion'
    WHEN platforms_used = 2 AND converted_web AND converted_mobile THEN 'Digital Native'
    WHEN platforms_used = 2 AND converted_offline THEN 'Hybrid Shopper'
    WHEN converted_offline AND NOT (converted_web OR converted_mobile) THEN 'Store Loyal'
    WHEN converted_web OR converted_mobile THEN 'Digital Only'
    ELSE 'Browser'
  END as customer_segment,
  
  -- Channel effectiveness for this customer
  first_touchpoint.platform as acquisition_channel,
  last_touchpoint.platform as latest_channel,
  
  -- Revenue distribution across platforms
  SAFE_DIVIDE(
    (SELECT SUM(pm.platform_revenue) FROM UNNEST(platform_metrics) pm WHERE pm.platform = 'web'),
    total_ltv
  ) * 100 as web_revenue_share,
  
  SAFE_DIVIDE(
    (SELECT SUM(pm.platform_revenue) FROM UNNEST(platform_metrics) pm WHERE pm.platform = 'mobile_app'),
    total_ltv
  ) * 100 as mobile_revenue_share,
  
  SAFE_DIVIDE(
    (SELECT SUM(pm.platform_revenue) FROM UNNEST(platform_metrics) pm WHERE pm.platform = 'offline_store'),
    total_ltv
  ) * 100 as offline_revenue_share,
  
  -- Engagement consistency across platforms
  CASE 
    WHEN customer_lifespan_days > 0 
    THEN active_days / customer_lifespan_days 
    ELSE 0 
  END as engagement_consistency_score
  
FROM customer_cross_platform_behavior
WHERE total_sessions >= 3  -- Focus on engaged customers
ORDER BY total_ltv DESC, platforms_used DESC;

/*
================================================================================
BIGQUERY BEST PRACTICES AND OPTIMIZATION STRATEGIES
================================================================================

1. PARTITIONING & CLUSTERING:
   - Partition by date for time-series data
   - Cluster by frequently filtered columns
   - Use partition expiration for cost management

2. QUERY OPTIMIZATION:
   - Use APPROX functions for large datasets
   - Leverage WITH clauses for complex queries
   - Avoid SELECT * in production queries

3. COST MANAGEMENT:
   - Use query labels for cost tracking
   - Implement dataset-level access controls
   - Monitor slot usage and optimize accordingly

4. JSON HANDLING:
   - Use JSON_EXTRACT functions for nested data
   - Consider flattening frequently accessed JSON fields
   - Use ARRAY and STRUCT for complex data types

5. MACHINE LEARNING:
   - Feature engineering directly in SQL
   - Use AUTO_SPLIT for automatic train/test splitting
   - Regularly retrain models with fresh data

6. REAL-TIME ANALYTICS:
   - Use streaming inserts for low-latency updates
   - Implement proper deduplication strategies
   - Design for eventual consistency in streaming scenarios
*/
