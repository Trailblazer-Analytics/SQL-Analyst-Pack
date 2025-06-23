-- =====================================================
-- 08. Serverless SQL Processing
-- =====================================================
-- 
-- Master serverless analytics patterns and event-driven
-- SQL processing for modern, scalable applications.
-- 
-- Business Value:
-- • Reduce infrastructure costs with pay-per-use models
-- • Enable real-time event processing and analytics
-- • Build scalable, maintenance-free data pipelines
-- • Implement microservices-based analytics architecture
-- 
-- Key Concepts:
-- • Event-driven architecture patterns
-- • Serverless computing paradigms
-- • Real-time stream processing
-- • Auto-scaling analytics workloads
-- =====================================================

-- =====================================================
-- AWS Lambda + Athena Serverless Analytics
-- =====================================================

-- Event-driven data processing with AWS Lambda
-- Triggered by S3 events, API Gateway, or scheduled events

-- Lambda function pseudo-code for data processing
/*
Lambda Function: process_sales_data
Trigger: S3 PUT events on sales-data/ prefix

def lambda_handler(event, context):
    # Extract S3 event details
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    # Process new data file
    athena_query = f"""
    INSERT INTO processed_sales
    SELECT 
        sale_id,
        customer_id,
        product_id,
        sale_amount,
        sale_date,
        CURRENT_TIMESTAMP as processed_at,
        '{key}' as source_file
    FROM raw_sales_data
    WHERE ds = '{extract_date_from_key(key)}'
    """
    
    # Execute via Athena API
    execute_athena_query(athena_query)
*/

-- Athena queries for serverless analytics
-- Real-time sales performance dashboard
WITH real_time_sales AS (
    SELECT 
        DATE(sale_timestamp) as sale_date,
        HOUR(sale_timestamp) as sale_hour,
        product_category,
        region,
        SUM(sale_amount) as hourly_revenue,
        COUNT(*) as transaction_count,
        AVG(sale_amount) as avg_transaction_value
    FROM sales_stream
    WHERE sale_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24' HOUR
    GROUP BY 1, 2, 3, 4
),
performance_metrics AS (
    SELECT 
        sale_date,
        sale_hour,
        SUM(hourly_revenue) as total_revenue,
        SUM(transaction_count) as total_transactions,
        AVG(avg_transaction_value) as overall_avg_value,
        -- Calculate hourly growth rate
        LAG(SUM(hourly_revenue)) OVER (ORDER BY sale_date, sale_hour) as prev_hour_revenue,
        (SUM(hourly_revenue) - LAG(SUM(hourly_revenue)) OVER (ORDER BY sale_date, sale_hour)) 
        / NULLIF(LAG(SUM(hourly_revenue)) OVER (ORDER BY sale_date, sale_hour), 0) * 100 as growth_rate
    FROM real_time_sales
    GROUP BY 1, 2
)
SELECT 
    sale_date,
    sale_hour,
    total_revenue,
    total_transactions,
    overall_avg_value,
    COALESCE(growth_rate, 0) as hourly_growth_rate,
    -- Business alerts
    CASE 
        WHEN growth_rate < -20 THEN 'CRITICAL_DECLINE'
        WHEN growth_rate < -10 THEN 'WARNING_DECLINE'
        WHEN growth_rate > 50 THEN 'EXCEPTIONAL_GROWTH'
        WHEN growth_rate > 20 THEN 'STRONG_GROWTH'
        ELSE 'NORMAL'
    END as performance_alert
FROM performance_metrics
ORDER BY sale_date DESC, sale_hour DESC;

-- =====================================================
-- Azure Functions + Synapse Serverless
-- =====================================================

-- Event-driven customer behavior analysis
-- Triggered by Event Hub messages from web/mobile apps

-- Customer journey real-time processing
WITH customer_events AS (
    SELECT 
        customer_id,
        event_type,
        event_timestamp,
        page_url,
        product_id,
        session_id,
        device_type,
        -- Extract business-relevant timing
        DATEDIFF(minute, 
            LAG(event_timestamp) OVER (PARTITION BY customer_id, session_id ORDER BY event_timestamp),
            event_timestamp
        ) as time_since_last_event
    FROM customer_activity_stream
    WHERE event_timestamp >= DATEADD(hour, -1, GETDATE())
),
session_analysis AS (
    SELECT 
        customer_id,
        session_id,
        MIN(event_timestamp) as session_start,
        MAX(event_timestamp) as session_end,
        DATEDIFF(minute, MIN(event_timestamp), MAX(event_timestamp)) as session_duration,
        COUNT(*) as total_events,
        COUNT(DISTINCT page_url) as pages_visited,
        COUNT(CASE WHEN event_type = 'product_view' THEN 1 END) as product_views,
        COUNT(CASE WHEN event_type = 'add_to_cart' THEN 1 END) as cart_additions,
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) as purchases,
        SUM(CASE WHEN time_since_last_event > 30 THEN 1 ELSE 0 END) as long_pauses
    FROM customer_events
    GROUP BY customer_id, session_id
),
real_time_insights AS (
    SELECT 
        customer_id,
        session_id,
        session_duration,
        total_events,
        pages_visited,
        product_views,
        cart_additions,
        purchases,
        -- Calculate conversion metrics
        CASE WHEN product_views > 0 THEN CAST(cart_additions AS FLOAT) / product_views ELSE 0 END as view_to_cart_rate,
        CASE WHEN cart_additions > 0 THEN CAST(purchases AS FLOAT) / cart_additions ELSE 0 END as cart_to_purchase_rate,
        -- Engagement scoring
        CASE 
            WHEN purchases > 0 THEN 100
            WHEN cart_additions > 0 AND session_duration > 10 THEN 80
            WHEN product_views >= 3 AND session_duration > 5 THEN 60
            WHEN pages_visited >= 3 THEN 40
            ELSE 20
        END as engagement_score,
        -- Risk indicators
        CASE 
            WHEN long_pauses >= 3 THEN 'HIGH_ABANDONMENT_RISK'
            WHEN session_duration > 20 AND purchases = 0 THEN 'BROWSING_EXTENSIVELY'
            WHEN cart_additions > 0 AND purchases = 0 THEN 'CART_ABANDONMENT_RISK'
            ELSE 'NORMAL_BEHAVIOR'
        END as behavior_flag
    FROM session_analysis
)
SELECT 
    customer_id,
    session_id,
    engagement_score,
    behavior_flag,
    view_to_cart_rate,
    cart_to_purchase_rate,
    -- Generate real-time recommendations
    CASE 
        WHEN behavior_flag = 'CART_ABANDONMENT_RISK' THEN 'SEND_DISCOUNT_OFFER'
        WHEN behavior_flag = 'BROWSING_EXTENSIVELY' THEN 'PROVIDE_PRODUCT_RECOMMENDATIONS'
        WHEN engagement_score >= 80 THEN 'UPSELL_OPPORTUNITY'
        WHEN engagement_score < 30 THEN 'RE_ENGAGEMENT_NEEDED'
        ELSE 'CONTINUE_MONITORING'
    END as recommended_action
FROM real_time_insights
WHERE engagement_score IS NOT NULL
ORDER BY engagement_score DESC;

-- =====================================================
-- Google Cloud Functions + BigQuery
-- =====================================================

-- Serverless fraud detection system
-- Triggered by Pub/Sub messages from transaction systems

-- Real-time transaction scoring
WITH transaction_features AS (
    SELECT 
        transaction_id,
        customer_id,
        merchant_id,
        amount,
        transaction_timestamp,
        location_lat,
        location_lng,
        payment_method,
        -- Time-based features
        EXTRACT(HOUR FROM transaction_timestamp) as hour_of_day,
        EXTRACT(DAYOFWEEK FROM transaction_timestamp) as day_of_week,
        -- Customer velocity features
        COUNT(*) OVER (
            PARTITION BY customer_id 
            ORDER BY transaction_timestamp 
            RANGE BETWEEN INTERVAL 1 HOUR PRECEDING AND CURRENT ROW
        ) as transactions_last_hour,
        SUM(amount) OVER (
            PARTITION BY customer_id 
            ORDER BY transaction_timestamp 
            RANGE BETWEEN INTERVAL 1 HOUR PRECEDING AND CURRENT ROW
        ) as spend_last_hour,
        -- Location features
        LAG(location_lat) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) as prev_lat,
        LAG(location_lng) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) as prev_lng,
        LAG(transaction_timestamp) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) as prev_timestamp
    FROM transactions_stream
    WHERE transaction_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
),
risk_scoring AS (
    SELECT 
        transaction_id,
        customer_id,
        amount,
        transaction_timestamp,
        -- Risk factors calculation
        CASE WHEN amount > 1000 THEN 25 ELSE 0 END as high_amount_risk,
        CASE WHEN transactions_last_hour > 5 THEN 30 ELSE 0 END as velocity_risk,
        CASE WHEN hour_of_day BETWEEN 22 AND 6 THEN 15 ELSE 0 END as time_risk,
        CASE 
            WHEN prev_lat IS NOT NULL AND prev_lng IS NOT NULL THEN
                CASE 
                    WHEN ST_DISTANCE(
                        ST_GEOGPOINT(location_lng, location_lat),
                        ST_GEOGPOINT(prev_lng, prev_lat)
                    ) > 100000 -- 100km
                    AND TIMESTAMP_DIFF(transaction_timestamp, prev_timestamp, MINUTE) < 60
                    THEN 40
                    ELSE 0
                END
            ELSE 0
        END as location_risk,
        -- Merchant risk (simplified)
        CASE 
            WHEN merchant_id IN (
                SELECT merchant_id 
                FROM high_risk_merchants 
                WHERE status = 'FLAGGED'
            ) THEN 35 
            ELSE 0 
        END as merchant_risk
    FROM transaction_features
),
final_scoring AS (
    SELECT 
        transaction_id,
        customer_id,
        amount,
        transaction_timestamp,
        high_amount_risk + velocity_risk + time_risk + location_risk + merchant_risk as total_risk_score,
        high_amount_risk,
        velocity_risk,
        time_risk,
        location_risk,
        merchant_risk
    FROM risk_scoring
)
SELECT 
    transaction_id,
    customer_id,
    amount,
    total_risk_score,
    CASE 
        WHEN total_risk_score >= 80 THEN 'BLOCK_TRANSACTION'
        WHEN total_risk_score >= 50 THEN 'REQUIRE_ADDITIONAL_AUTH'
        WHEN total_risk_score >= 30 THEN 'FLAG_FOR_REVIEW'
        ELSE 'APPROVE'
    END as recommendation,
    STRUCT(
        high_amount_risk as high_amount,
        velocity_risk as velocity,
        time_risk as unusual_time,
        location_risk as location_jump,
        merchant_risk as merchant_risk
    ) as risk_factors,
    transaction_timestamp
FROM final_scoring
ORDER BY total_risk_score DESC;

-- =====================================================
-- Snowflake + Serverless Integration
-- =====================================================

-- Event-driven data quality monitoring
-- Using Snowflake's cloud functions and streaming capabilities

-- Real-time data quality dashboard
CREATE OR REPLACE STREAM data_quality_events ON TABLE raw_customer_data;

-- Serverless data quality checks
WITH quality_metrics AS (
    SELECT 
        CURRENT_TIMESTAMP as check_timestamp,
        'customer_data' as table_name,
        -- Completeness checks
        COUNT(*) as total_records,
        COUNT(customer_id) as non_null_customer_id,
        COUNT(email) as non_null_email,
        COUNT(phone) as non_null_phone,
        COUNT(address) as non_null_address,
        -- Validity checks
        COUNT(CASE WHEN email RLIKE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN 1 END) as valid_emails,
        COUNT(CASE WHEN phone RLIKE '^\\+?[1-9]\\d{1,14}$' THEN 1 END) as valid_phones,
        COUNT(CASE WHEN customer_id IS NOT NULL AND customer_id != '' THEN 1 END) as valid_customer_ids,
        -- Uniqueness checks
        COUNT(DISTINCT customer_id) as unique_customer_ids,
        COUNT(DISTINCT email) as unique_emails,
        -- Freshness checks
        MAX(created_timestamp) as latest_record,
        MIN(created_timestamp) as earliest_record
    FROM data_quality_events
    WHERE METADATA$ACTION = 'INSERT'
),
quality_scores AS (
    SELECT 
        check_timestamp,
        table_name,
        total_records,
        -- Calculate quality percentages
        ROUND((non_null_customer_id::FLOAT / NULLIF(total_records, 0)) * 100, 2) as customer_id_completeness,
        ROUND((non_null_email::FLOAT / NULLIF(total_records, 0)) * 100, 2) as email_completeness,
        ROUND((valid_emails::FLOAT / NULLIF(non_null_email, 0)) * 100, 2) as email_validity,
        ROUND((valid_phones::FLOAT / NULLIF(non_null_phone, 0)) * 100, 2) as phone_validity,
        ROUND((unique_customer_ids::FLOAT / NULLIF(total_records, 0)) * 100, 2) as customer_id_uniqueness,
        ROUND((unique_emails::FLOAT / NULLIF(non_null_email, 0)) * 100, 2) as email_uniqueness,
        DATEDIFF('hour', latest_record, CURRENT_TIMESTAMP) as data_age_hours
    FROM quality_metrics
),
quality_assessment AS (
    SELECT 
        *,
        -- Overall quality score
        (customer_id_completeness + email_completeness + email_validity + 
         phone_validity + customer_id_uniqueness + email_uniqueness) / 6 as overall_quality_score,
        -- Quality flags
        CASE 
            WHEN customer_id_completeness < 95 THEN 'CRITICAL: Missing Customer IDs'
            WHEN email_validity < 80 THEN 'WARNING: Invalid Email Formats'
            WHEN customer_id_uniqueness < 99 THEN 'ERROR: Duplicate Customer IDs'
            WHEN data_age_hours > 24 THEN 'WARNING: Stale Data'
            ELSE 'GOOD'
        END as quality_status
    FROM quality_scores
)
SELECT 
    check_timestamp,
    table_name,
    total_records,
    overall_quality_score,
    quality_status,
    customer_id_completeness,
    email_completeness,
    email_validity,
    phone_validity,
    customer_id_uniqueness,
    email_uniqueness,
    data_age_hours,
    -- Automated actions
    CASE 
        WHEN overall_quality_score < 70 THEN 'ALERT_DATA_TEAM'
        WHEN quality_status LIKE 'CRITICAL%' THEN 'BLOCK_DOWNSTREAM_PROCESSING'
        WHEN quality_status LIKE 'ERROR%' THEN 'TRIGGER_DATA_CLEANUP'
        WHEN quality_status LIKE 'WARNING%' THEN 'NOTIFY_STAKEHOLDERS'
        ELSE 'CONTINUE_PROCESSING'
    END as recommended_action
FROM quality_assessment;

-- =====================================================
-- Multi-Platform Serverless Orchestration
-- =====================================================

-- Cross-platform serverless data pipeline
-- Combining multiple cloud providers for optimal cost/performance

-- Pipeline coordination view (conceptual)
WITH pipeline_status AS (
    SELECT 
        pipeline_id,
        pipeline_name,
        stage_name,
        cloud_provider,
        function_name,
        execution_timestamp,
        execution_duration_ms,
        execution_status,
        cost_usd,
        records_processed,
        -- Performance metrics
        records_processed / (execution_duration_ms / 1000.0) as records_per_second,
        cost_usd / NULLIF(records_processed, 0) * 1000000 as cost_per_million_records
    FROM serverless_execution_log
    WHERE execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1' HOUR
),
pipeline_performance AS (
    SELECT 
        pipeline_name,
        cloud_provider,
        COUNT(*) as total_executions,
        SUM(records_processed) as total_records,
        SUM(execution_duration_ms) / 1000.0 as total_execution_time_seconds,
        SUM(cost_usd) as total_cost,
        AVG(records_per_second) as avg_throughput,
        AVG(cost_per_million_records) as avg_cost_per_million,
        COUNT(CASE WHEN execution_status = 'SUCCESS' THEN 1 END) as successful_executions,
        COUNT(CASE WHEN execution_status = 'FAILED' THEN 1 END) as failed_executions
    FROM pipeline_status
    GROUP BY 1, 2
),
cost_optimization_insights AS (
    SELECT 
        pipeline_name,
        -- Compare costs across providers
        MAX(CASE WHEN cloud_provider = 'AWS' THEN avg_cost_per_million END) as aws_cost_per_million,
        MAX(CASE WHEN cloud_provider = 'Azure' THEN avg_cost_per_million END) as azure_cost_per_million,
        MAX(CASE WHEN cloud_provider = 'GCP' THEN avg_cost_per_million END) as gcp_cost_per_million,
        -- Compare performance across providers
        MAX(CASE WHEN cloud_provider = 'AWS' THEN avg_throughput END) as aws_throughput,
        MAX(CASE WHEN cloud_provider = 'Azure' THEN avg_throughput END) as azure_throughput,
        MAX(CASE WHEN cloud_provider = 'GCP' THEN avg_throughput END) as gcp_throughput,
        -- Reliability metrics
        MAX(CASE WHEN cloud_provider = 'AWS' THEN successful_executions::FLOAT / total_executions END) as aws_success_rate,
        MAX(CASE WHEN cloud_provider = 'Azure' THEN successful_executions::FLOAT / total_executions END) as azure_success_rate,
        MAX(CASE WHEN cloud_provider = 'GCP' THEN successful_executions::FLOAT / total_executions END) as gcp_success_rate
    FROM pipeline_performance
    GROUP BY 1
)
SELECT 
    pipeline_name,
    -- Cost recommendations
    CASE 
        WHEN aws_cost_per_million <= COALESCE(azure_cost_per_million, aws_cost_per_million + 1) 
         AND aws_cost_per_million <= COALESCE(gcp_cost_per_million, aws_cost_per_million + 1)
        THEN 'AWS_MOST_COST_EFFECTIVE'
        WHEN azure_cost_per_million <= COALESCE(gcp_cost_per_million, azure_cost_per_million + 1)
        THEN 'AZURE_MOST_COST_EFFECTIVE'
        ELSE 'GCP_MOST_COST_EFFECTIVE'
    END as cost_recommendation,
    -- Performance recommendations
    CASE 
        WHEN aws_throughput >= COALESCE(azure_throughput, 0) 
         AND aws_throughput >= COALESCE(gcp_throughput, 0)
        THEN 'AWS_HIGHEST_PERFORMANCE'
        WHEN azure_throughput >= COALESCE(gcp_throughput, 0)
        THEN 'AZURE_HIGHEST_PERFORMANCE'
        ELSE 'GCP_HIGHEST_PERFORMANCE'
    END as performance_recommendation,
    -- Reliability recommendations
    CASE 
        WHEN aws_success_rate >= COALESCE(azure_success_rate, 0) 
         AND aws_success_rate >= COALESCE(gcp_success_rate, 0)
        THEN 'AWS_MOST_RELIABLE'
        WHEN azure_success_rate >= COALESCE(gcp_success_rate, 0)
        THEN 'AZURE_MOST_RELIABLE'
        ELSE 'GCP_MOST_RELIABLE'
    END as reliability_recommendation,
    aws_cost_per_million,
    azure_cost_per_million,
    gcp_cost_per_million,
    aws_throughput,
    azure_throughput,
    gcp_throughput
FROM cost_optimization_insights;

-- =====================================================
-- Event-Driven Architecture Patterns
-- =====================================================

-- Microservices analytics coordination
-- Using event sourcing and CQRS patterns

-- Event store analysis for business insights
WITH event_stream AS (
    SELECT 
        event_id,
        aggregate_id,
        event_type,
        event_data,
        event_timestamp,
        correlation_id,
        causation_id,
        user_id,
        -- Extract business events
        CASE 
            WHEN event_type = 'OrderPlaced' THEN JSON_EXTRACT_SCALAR(event_data, '$.order_total')::DECIMAL
            WHEN event_type = 'PaymentProcessed' THEN JSON_EXTRACT_SCALAR(event_data, '$.payment_amount')::DECIMAL
            ELSE NULL
        END as monetary_value,
        CASE 
            WHEN event_type = 'CustomerRegistered' THEN JSON_EXTRACT_SCALAR(event_data, '$.customer_segment')
            WHEN event_type = 'OrderPlaced' THEN JSON_EXTRACT_SCALAR(event_data, '$.customer_id')
            ELSE NULL
        END as customer_context
    FROM event_store
    WHERE event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1' HOUR
),
business_metrics AS (
    SELECT 
        DATE_TRUNC('minute', event_timestamp) as time_window,
        -- Revenue metrics
        SUM(CASE WHEN event_type = 'OrderPlaced' THEN monetary_value ELSE 0 END) as orders_revenue,
        SUM(CASE WHEN event_type = 'PaymentProcessed' THEN monetary_value ELSE 0 END) as payments_revenue,
        -- Volume metrics
        COUNT(CASE WHEN event_type = 'OrderPlaced' THEN 1 END) as orders_count,
        COUNT(CASE WHEN event_type = 'PaymentProcessed' THEN 1 END) as payments_count,
        COUNT(CASE WHEN event_type = 'CustomerRegistered' THEN 1 END) as new_customers,
        -- Operational metrics
        COUNT(CASE WHEN event_type = 'OrderCancelled' THEN 1 END) as cancelled_orders,
        COUNT(CASE WHEN event_type = 'PaymentFailed' THEN 1 END) as failed_payments,
        COUNT(DISTINCT correlation_id) as unique_sessions,
        COUNT(DISTINCT user_id) as active_users
    FROM event_stream
    GROUP BY 1
),
real_time_kpis AS (
    SELECT 
        time_window,
        orders_revenue,
        payments_revenue,
        orders_count,
        payments_count,
        new_customers,
        cancelled_orders,
        failed_payments,
        active_users,
        -- Calculate business KPIs
        CASE WHEN orders_count > 0 THEN orders_revenue / orders_count ELSE 0 END as avg_order_value,
        CASE WHEN orders_count > 0 THEN cancelled_orders::FLOAT / orders_count ELSE 0 END as cancellation_rate,
        CASE WHEN payments_count > 0 THEN failed_payments::FLOAT / payments_count ELSE 0 END as payment_failure_rate,
        payments_revenue - orders_revenue as revenue_gap
    FROM business_metrics
)
SELECT 
    time_window,
    orders_revenue,
    payments_revenue,
    orders_count,
    new_customers,
    active_users,
    avg_order_value,
    cancellation_rate * 100 as cancellation_rate_pct,
    payment_failure_rate * 100 as payment_failure_rate_pct,
    revenue_gap,
    -- Business alerts
    CASE 
        WHEN cancellation_rate > 0.1 THEN 'HIGH_CANCELLATION_ALERT'
        WHEN payment_failure_rate > 0.05 THEN 'PAYMENT_SYSTEM_ALERT'
        WHEN ABS(revenue_gap) > orders_revenue * 0.1 THEN 'REVENUE_DISCREPANCY_ALERT'
        WHEN orders_count = 0 AND time_window > CURRENT_TIMESTAMP - INTERVAL '5' MINUTE THEN 'NO_ORDERS_ALERT'
        ELSE 'NORMAL_OPERATIONS'
    END as system_status
FROM real_time_kpis
ORDER BY time_window DESC;

-- =====================================================
-- Serverless Cost Optimization
-- =====================================================

-- Automated cost optimization recommendations
-- Based on usage patterns and performance metrics

WITH cost_analysis AS (
    SELECT 
        DATE(execution_timestamp) as execution_date,
        HOUR(execution_timestamp) as execution_hour,
        cloud_provider,
        service_type,
        function_name,
        SUM(execution_duration_ms) as total_duration_ms,
        SUM(memory_used_mb * execution_duration_ms / 1000) as memory_seconds,
        SUM(cost_usd) as total_cost,
        COUNT(*) as execution_count,
        AVG(execution_duration_ms) as avg_duration_ms,
        MAX(execution_duration_ms) as max_duration_ms
    FROM serverless_execution_log
    WHERE execution_timestamp >= CURRENT_DATE - INTERVAL '7' DAY
    GROUP BY 1, 2, 3, 4, 5
),
optimization_opportunities AS (
    SELECT 
        function_name,
        cloud_provider,
        service_type,
        SUM(total_cost) as weekly_cost,
        AVG(avg_duration_ms) as avg_execution_time,
        MAX(max_duration_ms) as peak_execution_time,
        SUM(execution_count) as total_executions,
        -- Identify optimization patterns
        CASE 
            WHEN AVG(avg_duration_ms) < 1000 AND SUM(total_cost) > 10 THEN 'OVER_PROVISIONED'
            WHEN MAX(max_duration_ms) > 300000 THEN 'NEEDS_OPTIMIZATION'
            WHEN SUM(execution_count) < 100 THEN 'LOW_USAGE'
            WHEN AVG(avg_duration_ms) > 30000 THEN 'CONSIDER_CONTAINERIZATION'
            ELSE 'OPTIMAL'
        END as optimization_category
    FROM cost_analysis
    GROUP BY 1, 2, 3
)
SELECT 
    function_name,
    cloud_provider,
    service_type,
    weekly_cost,
    avg_execution_time,
    total_executions,
    optimization_category,
    -- Specific recommendations
    CASE 
        WHEN optimization_category = 'OVER_PROVISIONED' 
        THEN 'Reduce memory allocation by 25-50%'
        WHEN optimization_category = 'NEEDS_OPTIMIZATION' 
        THEN 'Refactor code for better performance'
        WHEN optimization_category = 'LOW_USAGE' 
        THEN 'Consider consolidating with other functions'
        WHEN optimization_category = 'CONSIDER_CONTAINERIZATION' 
        THEN 'Migrate to container-based service'
        ELSE 'Continue current configuration'
    END as recommendation,
    -- Estimated savings
    CASE 
        WHEN optimization_category = 'OVER_PROVISIONED' 
        THEN weekly_cost * 0.3
        WHEN optimization_category = 'NEEDS_OPTIMIZATION' 
        THEN weekly_cost * 0.2
        WHEN optimization_category = 'LOW_USAGE' 
        THEN weekly_cost * 0.5
        ELSE 0
    END as estimated_weekly_savings
FROM optimization_opportunities
WHERE optimization_category != 'OPTIMAL'
ORDER BY estimated_weekly_savings DESC;

-- =====================================================
-- Performance Monitoring & Alerting
-- =====================================================

-- Real-time serverless performance dashboard
-- Monitor SLAs and trigger automated responses

WITH performance_metrics AS (
    SELECT 
        function_name,
        cloud_provider,
        execution_timestamp,
        execution_duration_ms,
        memory_used_mb,
        cpu_utilization_pct,
        error_type,
        http_status_code,
        -- Performance categories
        CASE 
            WHEN execution_duration_ms <= 1000 THEN 'EXCELLENT'
            WHEN execution_duration_ms <= 5000 THEN 'GOOD'
            WHEN execution_duration_ms <= 10000 THEN 'ACCEPTABLE'
            WHEN execution_duration_ms <= 30000 THEN 'SLOW'
            ELSE 'CRITICAL'
        END as performance_tier,
        CASE 
            WHEN error_type IS NULL AND http_status_code BETWEEN 200 AND 299 THEN 'SUCCESS'
            WHEN http_status_code BETWEEN 400 AND 499 THEN 'CLIENT_ERROR'
            WHEN http_status_code BETWEEN 500 AND 599 THEN 'SERVER_ERROR'
            WHEN error_type IS NOT NULL THEN 'FUNCTION_ERROR'
            ELSE 'UNKNOWN'
        END as execution_status
    FROM serverless_execution_log
    WHERE execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '15' MINUTE
),
sla_monitoring AS (
    SELECT 
        function_name,
        cloud_provider,
        COUNT(*) as total_executions,
        COUNT(CASE WHEN execution_status = 'SUCCESS' THEN 1 END) as successful_executions,
        COUNT(CASE WHEN performance_tier IN ('EXCELLENT', 'GOOD') THEN 1 END) as fast_executions,
        AVG(execution_duration_ms) as avg_response_time,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_duration_ms) as p95_response_time,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY execution_duration_ms) as p99_response_time,
        -- SLA calculations
        COUNT(CASE WHEN execution_status = 'SUCCESS' THEN 1 END)::FLOAT / COUNT(*) * 100 as availability_pct,
        COUNT(CASE WHEN execution_duration_ms <= 5000 THEN 1 END)::FLOAT / COUNT(*) * 100 as performance_sla_pct
    FROM performance_metrics
    GROUP BY 1, 2
),
alert_triggers AS (
    SELECT 
        function_name,
        cloud_provider,
        total_executions,
        availability_pct,
        performance_sla_pct,
        avg_response_time,
        p95_response_time,
        p99_response_time,
        -- Alert conditions
        CASE 
            WHEN availability_pct < 99.9 THEN 'CRITICAL_AVAILABILITY'
            WHEN availability_pct < 99.95 THEN 'WARNING_AVAILABILITY'
            ELSE 'OK_AVAILABILITY'
        END as availability_status,
        CASE 
            WHEN performance_sla_pct < 95 THEN 'CRITICAL_PERFORMANCE'
            WHEN performance_sla_pct < 98 THEN 'WARNING_PERFORMANCE'
            ELSE 'OK_PERFORMANCE'
        END as performance_status,
        CASE 
            WHEN p99_response_time > 30000 THEN 'CRITICAL_LATENCY'
            WHEN p95_response_time > 10000 THEN 'WARNING_LATENCY'
            ELSE 'OK_LATENCY'
        END as latency_status
    FROM sla_monitoring
)
SELECT 
    function_name,
    cloud_provider,
    total_executions,
    ROUND(availability_pct, 2) as availability_pct,
    ROUND(performance_sla_pct, 2) as performance_sla_pct,
    ROUND(avg_response_time, 0) as avg_response_time_ms,
    ROUND(p95_response_time, 0) as p95_response_time_ms,
    ROUND(p99_response_time, 0) as p99_response_time_ms,
    availability_status,
    performance_status,
    latency_status,
    -- Overall health score
    CASE 
        WHEN availability_status LIKE 'CRITICAL%' OR performance_status LIKE 'CRITICAL%' OR latency_status LIKE 'CRITICAL%'
        THEN 'CRITICAL'
        WHEN availability_status LIKE 'WARNING%' OR performance_status LIKE 'WARNING%' OR latency_status LIKE 'WARNING%'
        THEN 'WARNING'
        ELSE 'HEALTHY'
    END as overall_health,
    -- Automated actions
    CASE 
        WHEN availability_status = 'CRITICAL_AVAILABILITY' THEN 'SCALE_OUT_IMMEDIATELY'
        WHEN performance_status = 'CRITICAL_PERFORMANCE' THEN 'INCREASE_MEMORY_ALLOCATION'
        WHEN latency_status = 'CRITICAL_LATENCY' THEN 'OPTIMIZE_CODE_OR_SCALE'
        WHEN availability_status LIKE 'WARNING%' THEN 'MONITOR_CLOSELY'
        ELSE 'CONTINUE_NORMAL_OPERATIONS'
    END as recommended_action
FROM alert_triggers
ORDER BY 
    CASE overall_health WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
    total_executions DESC;

-- =====================================================
-- Best Practices Summary
-- =====================================================

/*
Serverless SQL Processing Best Practices:

1. Event-Driven Architecture
   - Design for idempotency
   - Use correlation IDs for tracing
   - Implement circuit breakers
   - Handle failures gracefully

2. Cost Optimization
   - Right-size memory allocations
   - Optimize cold start times
   - Use appropriate timeout settings
   - Monitor and alert on costs

3. Performance Optimization
   - Minimize package sizes
   - Reuse connections when possible
   - Implement efficient error handling
   - Use async processing patterns

4. Security & Compliance
   - Implement least privilege access
   - Encrypt data in transit and at rest
   - Audit all serverless executions
   - Monitor for anomalous behavior

5. Monitoring & Observability
   - Implement comprehensive logging
   - Use distributed tracing
   - Set up meaningful alerts
   - Track business metrics

6. Scalability Patterns
   - Design for horizontal scaling
   - Implement backpressure handling
   - Use appropriate concurrency limits
   - Plan for peak load scenarios
*/
