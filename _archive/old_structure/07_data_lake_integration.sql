/*
================================================================================
07_data_lake_integration.sql - Working with Data Lakes and Lake Houses
================================================================================

BUSINESS CONTEXT:
Modern enterprises store vast amounts of structured and unstructured data
in data lakes, requiring sophisticated integration strategies to enable
analytics across diverse data sources. This script demonstrates how to
effectively query, process, and analyze data lake contents using SQL.

LEARNING OBJECTIVES:
- Master data lake architecture and access patterns
- Implement effective schema-on-read strategies
- Process semi-structured and unstructured data at scale
- Design efficient ETL/ELT pipelines for data lakes
- Optimize performance for large-scale data lake queries

REAL-WORLD SCENARIOS:
- Media companies analyzing video metadata and user engagement
- IoT platforms processing sensor data from millions of devices
- Financial services analyzing unstructured market data feeds
- Healthcare organizations processing medical imaging and records
*/

-- =============================================
-- SECTION 1: DATA LAKE ARCHITECTURE PATTERNS
-- =============================================

/*
BUSINESS SCENARIO: IoT Platform Data Lake
A smart city IoT platform collects data from traffic sensors, air quality
monitors, energy meters, and surveillance cameras. Process this diverse
data to generate actionable insights for city management.
*/

-- Define external data sources for different data lake zones
-- Raw Zone: Unprocessed data as ingested
CREATE OR REPLACE EXTERNAL TABLE raw_sensor_data (
    device_id STRING,
    timestamp TIMESTAMP,
    sensor_type STRING,
    raw_payload STRING,  -- JSON payload as received
    ingestion_time TIMESTAMP,
    source_system STRING,
    data_quality_score FLOAT64
)
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://smart-city-datalake/raw/sensors/*/*'],
    hive_partition_uri_prefix = 'gs://smart-city-datalake/raw/sensors',
    require_hive_partition_filter = TRUE
);

-- Curated Zone: Cleaned and standardized data
CREATE OR REPLACE EXTERNAL TABLE curated_sensor_metrics (
    device_id STRING NOT NULL,
    measurement_timestamp TIMESTAMP NOT NULL,
    sensor_type STRING NOT NULL,
    location_lat FLOAT64,
    location_lng FLOAT64,
    district STRING,
    
    -- Standardized measurements
    temperature_celsius FLOAT64,
    humidity_percent FLOAT64,
    air_quality_index INT64,
    noise_level_db FLOAT64,
    traffic_count INT64,
    energy_consumption_kwh FLOAT64,
    
    -- Data lineage and quality
    processing_timestamp TIMESTAMP,
    data_quality_flags ARRAY<STRING>,
    source_file_path STRING
)
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://smart-city-datalake/curated/sensor-metrics/*/*'],
    hive_partition_uri_prefix = 'gs://smart-city-datalake/curated/sensor-metrics'
);

-- Analytics Zone: Business-ready aggregated data
CREATE OR REPLACE TABLE district_analytics_mart AS
WITH hourly_sensor_aggregates AS (
    SELECT 
        district,
        sensor_type,
        DATETIME_TRUNC(measurement_timestamp, HOUR) as measurement_hour,
        
        -- Environmental metrics
        AVG(temperature_celsius) as avg_temperature,
        AVG(humidity_percent) as avg_humidity,
        AVG(air_quality_index) as avg_air_quality,
        MAX(air_quality_index) as max_air_quality,
        AVG(noise_level_db) as avg_noise_level,
        MAX(noise_level_db) as max_noise_level,
        
        -- Infrastructure metrics
        SUM(traffic_count) as total_traffic_count,
        AVG(traffic_count) as avg_traffic_density,
        SUM(energy_consumption_kwh) as total_energy_consumption,
        
        -- Data quality metrics
        COUNT(*) as total_readings,
        COUNT(DISTINCT device_id) as active_devices,
        AVG(ARRAY_LENGTH(data_quality_flags)) as avg_quality_issues,
        
        -- Statistical measures for anomaly detection
        STDDEV(temperature_celsius) as temperature_stddev,
        STDDEV(air_quality_index) as air_quality_stddev,
        STDDEV(noise_level_db) as noise_stddev
        
    FROM curated_sensor_metrics
    WHERE measurement_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    GROUP BY district, sensor_type, DATETIME_TRUNC(measurement_timestamp, HOUR)
),

district_health_scores AS (
    SELECT 
        district,
        measurement_hour,
        
        -- Composite environmental health score (0-100)
        LEAST(100, GREATEST(0,
            -- Air quality component (40% weight)
            (CASE WHEN avg_air_quality <= 50 THEN 100
                  WHEN avg_air_quality <= 100 THEN 100 - (avg_air_quality - 50)
                  WHEN avg_air_quality <= 150 THEN 50 - (avg_air_quality - 100) * 0.5
                  ELSE 25 END) * 0.4 +
            
            -- Noise pollution component (30% weight)
            (CASE WHEN avg_noise_level <= 55 THEN 100
                  WHEN avg_noise_level <= 70 THEN 100 - (avg_noise_level - 55) * 3
                  ELSE 55 END) * 0.3 +
            
            -- Temperature comfort component (20% weight)
            (CASE WHEN avg_temperature BETWEEN 18 AND 24 THEN 100
                  WHEN avg_temperature BETWEEN 10 AND 30 THEN 80
                  ELSE 50 END) * 0.2 +
            
            -- Data reliability component (10% weight)
            (CASE WHEN avg_quality_issues <= 1 THEN 100
                  WHEN avg_quality_issues <= 3 THEN 80
                  ELSE 60 END) * 0.1
        )) as environmental_health_score,
        
        -- Infrastructure efficiency score
        CASE 
            WHEN total_energy_consumption / NULLIF(total_traffic_count, 0) <= 0.1 THEN 100
            WHEN total_energy_consumption / NULLIF(total_traffic_count, 0) <= 0.2 THEN 80
            WHEN total_energy_consumption / NULLIF(total_traffic_count, 0) <= 0.3 THEN 60
            ELSE 40
        END as infrastructure_efficiency_score,
        
        -- Anomaly indicators
        CASE 
            WHEN ABS(avg_temperature - 20) / NULLIF(temperature_stddev, 0) > 3 THEN 'Temperature Anomaly'
            WHEN ABS(avg_air_quality - 75) / NULLIF(air_quality_stddev, 0) > 3 THEN 'Air Quality Anomaly'
            WHEN ABS(avg_noise_level - 60) / NULLIF(noise_stddev, 0) > 3 THEN 'Noise Anomaly'
            ELSE 'Normal'
        END as anomaly_status,
        
        -- Aggregate base metrics for reporting
        MAX(CASE WHEN sensor_type = 'air_quality' THEN avg_air_quality END) as air_quality_index,
        MAX(CASE WHEN sensor_type = 'noise' THEN avg_noise_level END) as noise_level_db,
        MAX(CASE WHEN sensor_type = 'weather' THEN avg_temperature END) as temperature_celsius,
        MAX(CASE WHEN sensor_type = 'traffic' THEN total_traffic_count END) as traffic_volume,
        MAX(CASE WHEN sensor_type = 'energy' THEN total_energy_consumption END) as energy_consumption_kwh
        
    FROM hourly_sensor_aggregates
    GROUP BY district, measurement_hour
)

SELECT 
    district,
    measurement_hour,
    ROUND(environmental_health_score, 1) as environmental_health_score,
    ROUND(infrastructure_efficiency_score, 1) as infrastructure_efficiency_score,
    anomaly_status,
    
    -- Key performance indicators
    ROUND(air_quality_index, 1) as air_quality_index,
    ROUND(noise_level_db, 1) as noise_level_db,
    ROUND(temperature_celsius, 1) as temperature_celsius,
    traffic_volume,
    ROUND(energy_consumption_kwh, 2) as energy_consumption_kwh,
    
    -- Business insights
    CASE 
        WHEN environmental_health_score >= 80 THEN 'Excellent'
        WHEN environmental_health_score >= 60 THEN 'Good'
        WHEN environmental_health_score >= 40 THEN 'Fair'
        ELSE 'Poor'
    END as environmental_rating,
    
    -- Recommendations based on composite scores
    CASE 
        WHEN environmental_health_score < 40 AND air_quality_index > 150 
        THEN 'Issue air quality alert and traffic restrictions'
        WHEN environmental_health_score < 60 AND noise_level_db > 70 
        THEN 'Investigate noise sources and implement mitigation'
        WHEN infrastructure_efficiency_score < 60 
        THEN 'Optimize energy usage and traffic flow'
        WHEN anomaly_status != 'Normal' 
        THEN 'Investigate sensor anomalies and validate readings'
        ELSE 'Continue monitoring'
    END as recommended_action
    
FROM district_health_scores
ORDER BY measurement_hour DESC, environmental_health_score ASC;

-- =============================================
-- SECTION 2: SCHEMA-ON-READ DATA PROCESSING
-- =============================================

/*
BUSINESS SCENARIO: Social Media Analytics
Process diverse social media data feeds with varying schemas and formats
to extract sentiment, engagement metrics, and trending topics.
*/

-- Define flexible schema for social media data lake
CREATE OR REPLACE EXTERNAL TABLE social_media_raw (
    post_id STRING,
    platform STRING,
    user_id STRING,
    timestamp_utc TIMESTAMP,
    content_type STRING,
    raw_json STRING  -- Flexible JSON content
)
OPTIONS (
    format = 'NEWLINE_DELIMITED_JSON',
    uris = ['gs://social-analytics-lake/raw/posts/*/*'],
    allow_jagged_rows = TRUE,
    ignore_unknown_values = TRUE
);

-- Schema-on-read processing with dynamic JSON parsing
WITH parsed_social_content AS (
    SELECT 
        post_id,
        platform,
        user_id,
        timestamp_utc,
        content_type,
        
        -- Platform-specific parsing using schema-on-read
        CASE platform
            WHEN 'twitter' THEN JSON_EXTRACT_SCALAR(raw_json, '$.text')
            WHEN 'facebook' THEN JSON_EXTRACT_SCALAR(raw_json, '$.message')
            WHEN 'instagram' THEN JSON_EXTRACT_SCALAR(raw_json, '$.caption.text')
            WHEN 'linkedin' THEN JSON_EXTRACT_SCALAR(raw_json, '$.content')
            ELSE JSON_EXTRACT_SCALAR(raw_json, '$.text')
        END as post_text,
        
        -- Extract engagement metrics with platform-specific logic
        CASE platform
            WHEN 'twitter' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.favorite_count') AS INT64)
            WHEN 'facebook' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.likes.summary.total_count') AS INT64)
            WHEN 'instagram' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.like_count') AS INT64)
            WHEN 'linkedin' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.numLikes') AS INT64)
            ELSE 0
        END as like_count,
        
        CASE platform
            WHEN 'twitter' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.retweet_count') AS INT64)
            WHEN 'facebook' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.shares.count') AS INT64)
            WHEN 'instagram' THEN 0  -- No native repost on Instagram
            WHEN 'linkedin' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.numShares') AS INT64)
            ELSE 0
        END as share_count,
        
        CASE platform
            WHEN 'twitter' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.reply_count') AS INT64)
            WHEN 'facebook' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.comments.summary.total_count') AS INT64)
            WHEN 'instagram' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.comments_count') AS INT64)
            WHEN 'linkedin' THEN CAST(JSON_EXTRACT_SCALAR(raw_json, '$.numComments') AS INT64)
            ELSE 0
        END as comment_count,
        
        -- Extract hashtags and mentions using JSON arrays
        ARRAY(
            SELECT AS STRUCT JSON_EXTRACT_SCALAR(hashtag, '$') as tag
            FROM UNNEST(JSON_EXTRACT_ARRAY(raw_json, '$.hashtags')) as hashtag
        ) as hashtags,
        
        ARRAY(
            SELECT AS STRUCT JSON_EXTRACT_SCALAR(mention, '$.screen_name') as username
            FROM UNNEST(JSON_EXTRACT_ARRAY(raw_json, '$.user_mentions')) as mention
        ) as mentions,
        
        -- Extract user information with flexible schema
        STRUCT(
            JSON_EXTRACT_SCALAR(raw_json, '$.user.id') as user_id,
            JSON_EXTRACT_SCALAR(raw_json, '$.user.screen_name') as username,
            CAST(JSON_EXTRACT_SCALAR(raw_json, '$.user.followers_count') AS INT64) as followers_count,
            JSON_EXTRACT_SCALAR(raw_json, '$.user.location') as location,
            CAST(JSON_EXTRACT_SCALAR(raw_json, '$.user.verified') AS BOOLEAN) as is_verified
        ) as user_info,
        
        -- Extract geolocation data when available
        CASE 
            WHEN JSON_EXTRACT_SCALAR(raw_json, '$.geo') IS NOT NULL
            THEN STRUCT(
                CAST(JSON_EXTRACT_SCALAR(raw_json, '$.geo.coordinates[0]') AS FLOAT64) as latitude,
                CAST(JSON_EXTRACT_SCALAR(raw_json, '$.geo.coordinates[1]') AS FLOAT64) as longitude
            )
            ELSE NULL
        END as geo_location
        
    FROM social_media_raw
    WHERE timestamp_utc >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
    AND raw_json IS NOT NULL
),

content_analysis AS (
    SELECT 
        *,
        -- Text analysis using SQL functions
        LENGTH(post_text) as text_length,
        ARRAY_LENGTH(hashtags) as hashtag_count,
        ARRAY_LENGTH(mentions) as mention_count,
        
        -- Engagement rate calculation
        (like_count + share_count * 2 + comment_count * 3) as engagement_score,
        
        -- Sentiment analysis using keyword matching (simplified)
        CASE 
            WHEN REGEXP_CONTAINS(LOWER(post_text), r'\b(love|great|amazing|excellent|wonderful|fantastic)\b') 
            THEN 'positive'
            WHEN REGEXP_CONTAINS(LOWER(post_text), r'\b(hate|terrible|awful|horrible|disgusting|worst)\b') 
            THEN 'negative'
            ELSE 'neutral'
        END as sentiment,
        
        -- Content categorization
        CASE 
            WHEN REGEXP_CONTAINS(LOWER(post_text), r'\b(buy|sale|discount|offer|deal|price)\b') 
            THEN 'commercial'
            WHEN REGEXP_CONTAINS(LOWER(post_text), r'\b(news|breaking|update|report|announce)\b') 
            THEN 'news'
            WHEN REGEXP_CONTAINS(LOWER(post_text), r'\b(opinion|think|believe|feel|personal)\b') 
            THEN 'opinion'
            WHEN ARRAY_LENGTH(hashtags) > 5 
            THEN 'promotional'
            ELSE 'general'
        END as content_category,
        
        -- Viral potential scoring
        CASE 
            WHEN user_info.followers_count > 100000 AND engagement_score > 1000 THEN 'high'
            WHEN user_info.followers_count > 10000 AND engagement_score > 100 THEN 'medium'
            WHEN engagement_score > 50 THEN 'low'
            ELSE 'minimal'
        END as viral_potential
        
    FROM parsed_social_content
    WHERE post_text IS NOT NULL
),

trending_analysis AS (
    SELECT 
        platform,
        content_category,
        sentiment,
        
        -- Content metrics
        COUNT(*) as total_posts,
        COUNT(DISTINCT user_id) as unique_users,
        AVG(engagement_score) as avg_engagement,
        SUM(like_count) as total_likes,
        SUM(share_count) as total_shares,
        SUM(comment_count) as total_comments,
        
        -- Trending hashtags
        ARRAY_AGG(
            STRUCT(hashtag.tag as tag, COUNT(*) as frequency)
            ORDER BY COUNT(*) DESC
            LIMIT 10
        ) as top_hashtags,
        
        -- Geographic distribution
        COUNT(CASE WHEN geo_location IS NOT NULL THEN 1 END) as geotagged_posts,
        APPROX_TOP_COUNT(user_info.location, 5) as top_locations,
        
        -- Influencer analysis
        COUNT(CASE WHEN user_info.is_verified THEN 1 END) as verified_user_posts,
        AVG(user_info.followers_count) as avg_follower_count,
        
        -- Viral content identification
        COUNT(CASE WHEN viral_potential = 'high' THEN 1 END) as high_viral_posts,
        MAX(engagement_score) as max_engagement_score
        
    FROM content_analysis,
    UNNEST(hashtags) as hashtag
    GROUP BY platform, content_category, sentiment
)

SELECT 
    platform,
    content_category,
    sentiment,
    total_posts,
    unique_users,
    ROUND(avg_engagement, 1) as avg_engagement_score,
    
    -- Engagement metrics
    total_likes,
    total_shares,
    total_comments,
    total_likes + total_shares + total_comments as total_interactions,
    
    -- Content insights
    ROUND(total_posts * 100.0 / SUM(total_posts) OVER (PARTITION BY platform), 2) as category_share_percent,
    ROUND(avg_engagement / AVG(avg_engagement) OVER (PARTITION BY platform), 2) as engagement_index,
    
    -- Trending indicators
    high_viral_posts,
    max_engagement_score,
    verified_user_posts,
    ROUND(avg_follower_count, 0) as avg_follower_count,
    
    -- Top hashtags summary
    (SELECT STRING_AGG(hashtag.tag, ', ') 
     FROM UNNEST(top_hashtags) as hashtag 
     WHERE hashtag.frequency >= 10) as popular_hashtags,
    
    -- Geographic insights
    geotagged_posts,
    (SELECT location.value 
     FROM UNNEST(top_locations) as location 
     ORDER BY location.count DESC 
     LIMIT 1) as primary_location,
    
    -- Strategic insights
    CASE 
        WHEN avg_engagement > 100 AND sentiment = 'positive' 
        THEN 'Amplify positive sentiment'
        WHEN avg_engagement > 50 AND sentiment = 'negative' 
        THEN 'Address negative feedback'
        WHEN high_viral_posts > 0 
        THEN 'Monitor viral content trends'
        WHEN total_posts > 1000 
        THEN 'High volume category - optimize content strategy'
        ELSE 'Standard monitoring'
    END as strategic_recommendation
    
FROM trending_analysis
WHERE total_posts >= 10  -- Filter out low-volume categories
ORDER BY platform, avg_engagement DESC;

/*
================================================================================
DATA LAKE INTEGRATION BEST PRACTICES AND ADVANCED PATTERNS
================================================================================

1. DATA LAKE ARCHITECTURE:
   - Implement medallion architecture (bronze/silver/gold)
   - Use proper partitioning and file organization strategies
   - Establish clear data governance and lineage tracking
   - Implement data quality monitoring throughout the pipeline

2. SCHEMA EVOLUTION:
   - Design for schema flexibility and evolution
   - Use schema registries for structured data
   - Implement backward compatibility strategies
   - Plan for data type conversions and migrations

3. QUERY OPTIMIZATION:
   - Leverage partition pruning and predicate pushdown
   - Use columnar formats (Parquet, ORC) for analytics
   - Implement proper indexing strategies
   - Cache frequently accessed data

4. DATA PROCESSING PATTERNS:
   - Use ELT over ETL for cloud-scale processing
   - Implement incremental processing strategies
   - Design for idempotent operations
   - Use event-driven architectures for real-time processing

5. SECURITY AND COMPLIANCE:
   - Implement fine-grained access controls
   - Use encryption at rest and in transit
   - Establish data retention and purging policies
   - Monitor data access and usage patterns

6. COST OPTIMIZATION:
   - Use appropriate storage classes for different data tiers
   - Implement data lifecycle management
   - Optimize compute resource usage
   - Monitor and optimize storage and processing costs
*/
