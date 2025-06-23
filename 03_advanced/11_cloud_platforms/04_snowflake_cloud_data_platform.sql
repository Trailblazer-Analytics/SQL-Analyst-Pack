/*
================================================================================
04_snowflake_cloud_data_platform.sql - Snowflake Cloud Data Warehouse
================================================================================

BUSINESS CONTEXT:
Snowflake is a cloud-native data platform that provides data warehouse,
data lake, and data engineering capabilities with unique architecture
featuring separate compute and storage. This script demonstrates how to
leverage Snowflake's advanced features for enterprise-scale analytics.

LEARNING OBJECTIVES:
- Master Snowflake's unique architecture and capabilities
- Implement multi-cluster warehouses for scalability
- Leverage Time Travel and Zero-Copy Cloning features
- Design secure data sharing and marketplace integrations
- Optimize for Snowflake's columnar storage and caching

REAL-WORLD SCENARIOS:
- Enterprise data warehouse with elastic scaling
- Secure data sharing across organizations
- Data marketplace and monetization strategies
- Advanced analytics with semi-structured data
*/

-- =============================================
-- SECTION 1: SNOWFLAKE ARCHITECTURE SETUP
-- =============================================

/*
BUSINESS SCENARIO: Financial Services Data Platform
A financial services company needs to build a secure, scalable data platform
for risk analytics, regulatory reporting, and customer insights while ensuring
data governance and compliance.
*/

-- Create database and schemas with proper organization
CREATE OR REPLACE DATABASE financial_analytics
  COMMENT = 'Enterprise financial analytics data platform';

USE DATABASE financial_analytics;

-- Create schemas for different data domains
CREATE OR REPLACE SCHEMA raw_data
  COMMENT = 'Raw data from source systems';

CREATE OR REPLACE SCHEMA processed_data
  COMMENT = 'Cleaned and transformed data';

CREATE OR REPLACE SCHEMA analytics_mart
  COMMENT = 'Business-ready analytical datasets';

CREATE OR REPLACE SCHEMA secure_data
  COMMENT = 'Sensitive data with enhanced security';

-- Create dedicated warehouses for different workloads
CREATE OR REPLACE WAREHOUSE etl_warehouse
  WITH WAREHOUSE_SIZE = 'LARGE'
       AUTO_SUSPEND = 300  -- 5 minutes
       AUTO_RESUME = TRUE
       INITIALLY_SUSPENDED = TRUE
  COMMENT = 'ETL and data processing workloads';

CREATE OR REPLACE WAREHOUSE analytics_warehouse
  WITH WAREHOUSE_SIZE = 'MEDIUM'
       AUTO_SUSPEND = 60   -- 1 minute
       AUTO_RESUME = TRUE
       SCALING_POLICY = 'STANDARD'
       MIN_CLUSTER_COUNT = 1
       MAX_CLUSTER_COUNT = 3
  COMMENT = 'Interactive analytics and reporting';

CREATE OR REPLACE WAREHOUSE ml_warehouse
  WITH WAREHOUSE_SIZE = 'X-LARGE'
       AUTO_SUSPEND = 600  -- 10 minutes
       AUTO_RESUME = TRUE
  COMMENT = 'Machine learning and advanced analytics';

-- =============================================
-- SECTION 2: ADVANCED TABLE DESIGN
-- =============================================

USE SCHEMA processed_data;

-- Create fact table with clustering for optimal performance
CREATE OR REPLACE TABLE transactions (
    transaction_id STRING NOT NULL,
    account_id STRING NOT NULL,
    customer_id STRING NOT NULL,
    transaction_timestamp TIMESTAMP_NTZ NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_type STRING NOT NULL,
    amount NUMBER(15,2) NOT NULL,
    currency STRING NOT NULL,
    merchant_id STRING,
    merchant_category STRING,
    transaction_channel STRING NOT NULL,
    location_country STRING,
    location_city STRING,
    risk_score NUMBER(5,4),
    fraud_flag BOOLEAN DEFAULT FALSE,
    processing_date DATE NOT NULL DEFAULT CURRENT_DATE(),
    
    -- Metadata fields
    source_system STRING NOT NULL,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY (transaction_date, customer_id, transaction_type)
COMMENT = 'Financial transactions with clustering for optimal query performance';

-- Create dimension table with SCD Type 2 implementation
CREATE OR REPLACE TABLE customers (
    customer_key STRING NOT NULL,  -- Surrogate key
    customer_id STRING NOT NULL,   -- Business key
    customer_name STRING NOT NULL,
    email STRING,
    phone STRING,
    date_of_birth DATE,
    account_opening_date DATE,
    customer_segment STRING,
    risk_rating STRING,
    kyc_status STRING,
    address_line1 STRING,
    address_line2 STRING,
    city STRING,
    state STRING,
    country STRING,
    postal_code STRING,
    
    -- SCD Type 2 fields
    effective_date DATE NOT NULL,
    expiry_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT pk_customers PRIMARY KEY (customer_key)
)
COMMENT = 'Customer dimension with SCD Type 2 for historical tracking';

-- Create table for semi-structured data (JSON)
CREATE OR REPLACE TABLE customer_interactions (
    interaction_id STRING NOT NULL,
    customer_id STRING NOT NULL,
    interaction_timestamp TIMESTAMP_NTZ NOT NULL,
    channel STRING NOT NULL,
    interaction_type STRING NOT NULL,
    
    -- Semi-structured data stored as VARIANT
    interaction_data VARIANT,
    
    -- Extracted fields for better performance
    session_duration NUMBER GENERATED ALWAYS AS (interaction_data:session_duration::NUMBER),
    pages_viewed NUMBER GENERATED ALWAYS AS (interaction_data:pages_viewed::NUMBER),
    products_viewed ARRAY GENERATED ALWAYS AS (interaction_data:products_viewed::ARRAY),
    
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY (interaction_timestamp, customer_id)
COMMENT = 'Customer interactions with semi-structured data';

-- =============================================
-- SECTION 3: TIME TRAVEL AND DATA VERSIONING
-- =============================================

/*
BUSINESS SCENARIO: Regulatory Compliance and Audit Trail
Financial institutions need to maintain historical data for regulatory
compliance and be able to query data as it existed at specific points in time.
*/

-- Enable extended Time Travel for compliance requirements
ALTER TABLE transactions SET DATA_RETENTION_TIME_IN_DAYS = 90;
ALTER TABLE customers SET DATA_RETENTION_TIME_IN_DAYS = 90;

-- Demonstrate Time Travel capabilities
-- Query data as it existed 1 hour ago
SELECT 
    transaction_date,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(risk_score) as avg_risk_score
FROM transactions AT(OFFSET => -3600)  -- 1 hour ago in seconds
WHERE transaction_date = CURRENT_DATE()
GROUP BY transaction_date;

-- Query data at a specific timestamp
SELECT 
    customer_id,
    customer_name,
    customer_segment,
    risk_rating
FROM customers AT(TIMESTAMP => '2024-01-15 09:00:00'::TIMESTAMP_NTZ)
WHERE country = 'USA'
AND is_current = TRUE;

-- Create a snapshot table for monthly regulatory reporting
CREATE OR REPLACE TABLE monthly_balance_snapshot
CLONE transactions AT(TIMESTAMP => DATEADD(month, -1, CURRENT_TIMESTAMP()));

-- =============================================
-- SECTION 4: SECURE DATA SHARING
-- =============================================

/*
BUSINESS SCENARIO: External Data Sharing with Partners
Share specific datasets with business partners, regulators, or data
consumers while maintaining security and governance controls.
*/

-- Create a secure view for external sharing
CREATE OR REPLACE SECURE VIEW analytics_mart.customer_summary AS
SELECT 
    -- Anonymized customer identifier
    SHA2(customer_id) as customer_hash,
    customer_segment,
    account_opening_date,
    country,
    
    -- Aggregated transaction metrics (last 12 months)
    COUNT(t.transaction_id) as transaction_count_12m,
    SUM(t.amount) as total_transaction_amount_12m,
    AVG(t.amount) as avg_transaction_amount,
    MAX(t.transaction_date) as last_transaction_date,
    
    -- Risk metrics (anonymized)
    CASE 
        WHEN AVG(t.risk_score) > 0.8 THEN 'High'
        WHEN AVG(t.risk_score) > 0.5 THEN 'Medium'
        ELSE 'Low'
    END as risk_category,
    
    -- Remove PII completely
    'MASKED' as customer_name,
    'MASKED' as email,
    'MASKED' as phone
    
FROM processed_data.customers c
JOIN processed_data.transactions t ON c.customer_id = t.customer_id
WHERE c.is_current = TRUE
AND t.transaction_date >= DATEADD(year, -1, CURRENT_DATE())
GROUP BY 
    customer_id, customer_segment, account_opening_date, 
    country, customer_name, email, phone;

-- Create a share for external partners
CREATE OR REPLACE SHARE partner_analytics_share
COMMENT = 'Anonymized customer analytics for partner use';

-- Grant access to specific objects in the share
GRANT USAGE ON DATABASE financial_analytics TO SHARE partner_analytics_share;
GRANT USAGE ON SCHEMA analytics_mart TO SHARE partner_analytics_share;
GRANT SELECT ON VIEW analytics_mart.customer_summary TO SHARE partner_analytics_share;

-- =============================================
-- SECTION 5: ADVANCED ANALYTICS WITH SNOWPARK
-- =============================================

/*
BUSINESS SCENARIO: Real-Time Fraud Detection
Implement sophisticated fraud detection algorithms using Snowflake's
native functions and integration with machine learning frameworks.
*/

USE WAREHOUSE ml_warehouse;

-- Create a comprehensive fraud detection analysis
WITH transaction_features AS (
    SELECT 
        t.transaction_id,
        t.customer_id,
        t.transaction_timestamp,
        t.amount,
        t.merchant_category,
        t.transaction_channel,
        t.location_country,
        
        -- Time-based features
        EXTRACT(HOUR FROM t.transaction_timestamp) as transaction_hour,
        EXTRACT(DOW FROM t.transaction_timestamp) as day_of_week,
        
        -- Customer behavior features
        LAG(t.transaction_timestamp) OVER (
            PARTITION BY t.customer_id 
            ORDER BY t.transaction_timestamp
        ) as previous_transaction_time,
        
        -- Calculate time since last transaction
        DATEDIFF(minute, 
            LAG(t.transaction_timestamp) OVER (
                PARTITION BY t.customer_id 
                ORDER BY t.transaction_timestamp
            ), 
            t.transaction_timestamp
        ) as minutes_since_last_transaction,
        
        -- Amount-based features
        AVG(t.amount) OVER (
            PARTITION BY t.customer_id 
            ORDER BY t.transaction_timestamp 
            ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
        ) as avg_amount_last_30_transactions,
        
        STDDEV(t.amount) OVER (
            PARTITION BY t.customer_id 
            ORDER BY t.transaction_timestamp 
            ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
        ) as stddev_amount_last_30_transactions,
        
        -- Location-based features
        LAG(t.location_country) OVER (
            PARTITION BY t.customer_id 
            ORDER BY t.transaction_timestamp
        ) as previous_country,
        
        -- Merchant pattern features
        COUNT(*) OVER (
            PARTITION BY t.customer_id, t.merchant_id 
            ORDER BY t.transaction_timestamp 
            RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
        ) as merchant_frequency_30d,
        
        -- Velocity features
        COUNT(*) OVER (
            PARTITION BY t.customer_id 
            ORDER BY t.transaction_timestamp 
            RANGE BETWEEN INTERVAL '1 hour' PRECEDING AND CURRENT ROW
        ) as transactions_last_hour,
        
        SUM(t.amount) OVER (
            PARTITION BY t.customer_id 
            ORDER BY t.transaction_timestamp 
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        ) as amount_last_24h
        
    FROM transactions t
    WHERE t.transaction_date >= DATEADD(day, -90, CURRENT_DATE())
),

fraud_scoring AS (
    SELECT 
        *,
        
        -- Calculate fraud risk indicators
        CASE 
            WHEN minutes_since_last_transaction < 1 AND amount > 1000 THEN 1
            ELSE 0 
        END as rapid_high_value_flag,
        
        CASE 
            WHEN location_country != previous_country 
            AND minutes_since_last_transaction < 60 THEN 1
            ELSE 0 
        END as location_velocity_flag,
        
        CASE 
            WHEN avg_amount_last_30_transactions > 0 
            AND amount > (avg_amount_last_30_transactions + 3 * stddev_amount_last_30_transactions) 
            THEN 1
            ELSE 0 
        END as amount_anomaly_flag,
        
        CASE 
            WHEN transaction_hour BETWEEN 2 AND 5 
            AND amount > 500 THEN 1
            ELSE 0 
        END as unusual_time_flag,
        
        CASE 
            WHEN transactions_last_hour >= 5 THEN 1
            ELSE 0 
        END as velocity_flag,
        
        CASE 
            WHEN merchant_frequency_30d = 1 
            AND amount > 1000 THEN 1
            ELSE 0 
        END as new_merchant_high_value_flag
        
    FROM transaction_features
),

comprehensive_fraud_analysis AS (
    SELECT 
        *,
        
        -- Calculate composite fraud score
        (rapid_high_value_flag * 0.25 +
         location_velocity_flag * 0.20 +
         amount_anomaly_flag * 0.20 +
         unusual_time_flag * 0.15 +
         velocity_flag * 0.10 +
         new_merchant_high_value_flag * 0.10) as fraud_score,
        
        -- Business rules for fraud classification
        CASE 
            WHEN (rapid_high_value_flag + location_velocity_flag + amount_anomaly_flag) >= 2 
            THEN 'HIGH_RISK'
            WHEN (rapid_high_value_flag + location_velocity_flag + amount_anomaly_flag + 
                  unusual_time_flag + velocity_flag + new_merchant_high_value_flag) >= 2 
            THEN 'MEDIUM_RISK'
            WHEN (rapid_high_value_flag + location_velocity_flag + amount_anomaly_flag + 
                  unusual_time_flag + velocity_flag + new_merchant_high_value_flag) = 1 
            THEN 'LOW_RISK'
            ELSE 'NORMAL'
        END as fraud_classification,
        
        -- Recommended actions
        CASE 
            WHEN (rapid_high_value_flag + location_velocity_flag + amount_anomaly_flag) >= 2 
            THEN 'BLOCK_TRANSACTION'
            WHEN fraud_score > 0.3 
            THEN 'MANUAL_REVIEW'
            WHEN fraud_score > 0.1 
            THEN 'ENHANCED_MONITORING'
            ELSE 'APPROVE'
        END as recommended_action
        
    FROM fraud_scoring
)

SELECT 
    transaction_id,
    customer_id,
    transaction_timestamp,
    amount,
    fraud_score,
    fraud_classification,
    recommended_action,
    
    -- Detailed breakdown for investigation
    OBJECT_CONSTRUCT(
        'rapid_high_value', rapid_high_value_flag,
        'location_velocity', location_velocity_flag,
        'amount_anomaly', amount_anomaly_flag,
        'unusual_time', unusual_time_flag,
        'velocity', velocity_flag,
        'new_merchant_high_value', new_merchant_high_value_flag,
        'minutes_since_last', minutes_since_last_transaction,
        'transactions_last_hour', transactions_last_hour,
        'amount_vs_avg', CASE 
            WHEN avg_amount_last_30_transactions > 0 
            THEN amount / avg_amount_last_30_transactions 
            ELSE NULL 
        END
    ) as fraud_indicators
    
FROM comprehensive_fraud_analysis
WHERE fraud_classification != 'NORMAL'
ORDER BY fraud_score DESC, transaction_timestamp DESC;

-- =============================================
-- SECTION 6: PERFORMANCE OPTIMIZATION
-- =============================================

/*
BUSINESS SCENARIO: Query Performance Optimization
Optimize complex analytical queries for sub-second response times
while managing compute costs effectively.
*/

-- Create materialized view for frequently accessed aggregations
CREATE OR REPLACE MATERIALIZED VIEW customer_monthly_summary AS
SELECT 
    customer_id,
    DATE_TRUNC('month', transaction_date) as month,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount,
    MAX(amount) as max_amount,
    COUNT(DISTINCT merchant_category) as unique_categories,
    COUNT(DISTINCT transaction_channel) as unique_channels,
    SUM(CASE WHEN fraud_flag THEN 1 ELSE 0 END) as fraud_transactions,
    AVG(risk_score) as avg_risk_score
FROM transactions
GROUP BY customer_id, DATE_TRUNC('month', transaction_date);

-- Create search optimization for frequently filtered columns
ALTER TABLE transactions ADD SEARCH OPTIMIZATION ON EQUALITY(customer_id, merchant_id);
ALTER TABLE customers ADD SEARCH OPTIMIZATION ON EQUALITY(customer_id, email);

-- Demonstrate query optimization techniques
WITH customer_risk_profile AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.risk_rating,
        
        -- Use materialized view for performance
        SUM(cms.total_amount) as ltv_12m,
        AVG(cms.avg_amount) as avg_transaction_amount,
        MAX(cms.max_amount) as max_transaction_amount,
        SUM(cms.fraud_transactions) as total_fraud_transactions,
        AVG(cms.avg_risk_score) as avg_risk_score,
        
        -- Calculate risk metrics
        CASE 
            WHEN SUM(cms.fraud_transactions) > 0 
            THEN SUM(cms.fraud_transactions) / SUM(cms.transaction_count) 
            ELSE 0 
        END as fraud_rate,
        
        -- Segment performance
        PERCENT_RANK() OVER (
            PARTITION BY c.customer_segment 
            ORDER BY SUM(cms.total_amount)
        ) as segment_value_percentile
        
    FROM customers c
    JOIN customer_monthly_summary cms ON c.customer_id = cms.customer_id
    WHERE c.is_current = TRUE
    AND cms.month >= DATEADD(year, -1, CURRENT_DATE())
    GROUP BY c.customer_id, c.customer_name, c.customer_segment, c.risk_rating
)

SELECT 
    customer_segment,
    risk_rating,
    COUNT(*) as customer_count,
    AVG(ltv_12m) as avg_ltv,
    MEDIAN(ltv_12m) as median_ltv,
    SUM(ltv_12m) as total_segment_value,
    AVG(fraud_rate) * 100 as avg_fraud_rate_pct,
    
    -- Top performers in each segment
    ARRAY_AGG(
        OBJECT_CONSTRUCT(
            'customer_id', customer_id,
            'ltv', ltv_12m,
            'percentile', segment_value_percentile
        )
    ) WITHIN GROUP (ORDER BY ltv_12m DESC) 
    LIMIT 5 as top_customers,
    
    -- Risk distribution
    SUM(CASE WHEN avg_risk_score > 0.7 THEN 1 ELSE 0 END) as high_risk_customers,
    SUM(CASE WHEN avg_risk_score <= 0.3 THEN 1 ELSE 0 END) as low_risk_customers
    
FROM customer_risk_profile
GROUP BY customer_segment, risk_rating
ORDER BY total_segment_value DESC;

/*
================================================================================
SNOWFLAKE BEST PRACTICES AND ADVANCED FEATURES
================================================================================

1. WAREHOUSE MANAGEMENT:
   - Use appropriate warehouse sizes for workloads
   - Enable auto-suspend to control costs
   - Use multi-cluster warehouses for high concurrency

2. TABLE DESIGN:
   - Choose clustering keys based on query patterns
   - Use VARIANT for semi-structured data
   - Implement proper data retention policies

3. SECURITY & GOVERNANCE:
   - Use secure views for sensitive data sharing
   - Implement row-level security where needed
   - Regular access reviews and auditing

4. PERFORMANCE OPTIMIZATION:
   - Use materialized views for frequently accessed aggregations
   - Enable search optimization for high-cardinality filters
   - Monitor query performance and adjust clustering

5. COST MANAGEMENT:
   - Monitor compute and storage costs separately
   - Use Time Travel and Fail-safe appropriately
   - Optimize data loading and transformation processes

6. DATA SHARING & COLLABORATION:
   - Leverage secure data sharing for external partnerships
   - Use Snowflake Marketplace for data monetization
   - Implement proper data governance frameworks
*/
