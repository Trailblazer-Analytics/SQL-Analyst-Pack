# Exercise 6: Data Engineering and ETL Optimization

## Business Context

You're a senior data engineer at **GlobalTech Solutions**, a multinational company managing complex data pipelines across multiple business units. The data engineering team needs to optimize ETL processes, implement real-time data streaming, and ensure data quality across diverse data sources. Your role involves building production-grade data pipelines that serve thousands of analysts and business users.

## Learning Objectives

By completing this exercise, you will:

- Master advanced ETL pattern design and optimization
- Implement data quality monitoring and validation frameworks
- Build real-time streaming data pipelines
- Design data lakehouse architectures with SQL
- Create automated data lineage and governance systems

## Complex Data Architecture

You'll be working with a multi-source, multi-format data environment:

```sql
-- Source Systems Tables

-- CRM System (PostgreSQL)
crm_customers (
    customer_id BIGINT PRIMARY KEY,
    customer_uuid UUID UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address JSONB,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'crm'
)

-- ERP System (Oracle-style, large tables)
erp_orders (
    order_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    order_number VARCHAR(50),
    order_date DATE,
    total_amount DECIMAL(15,2),
    currency_code VARCHAR(3),
    status VARCHAR(20),
    sales_rep_id INTEGER,
    created_at TIMESTAMP,
    partition_date DATE -- Partitioned table
) PARTITION BY RANGE (partition_date)

-- E-commerce Platform (MongoDB-like JSONB)
ecommerce_events (
    event_id BIGINT PRIMARY KEY,
    session_id UUID,
    customer_id BIGINT,
    event_timestamp TIMESTAMP,
    event_type VARCHAR(50),
    event_data JSONB, -- Complex nested JSON
    page_url TEXT,
    user_agent TEXT,
    ip_address INET,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)

-- Financial System (High-frequency data)
financial_transactions (
    transaction_id BIGINT PRIMARY KEY,
    account_id BIGINT,
    transaction_timestamp TIMESTAMP(6), -- Microsecond precision
    amount DECIMAL(20,4),
    transaction_type VARCHAR(50),
    reference_data JSONB,
    batch_id VARCHAR(100),
    is_processed BOOLEAN DEFAULT FALSE
)

-- External Data Sources (APIs, Files)
external_market_data (
    symbol VARCHAR(10),
    timestamp TIMESTAMP,
    price DECIMAL(15,4),
    volume BIGINT,
    metadata JSONB,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)

-- Data Quality Tracking
data_quality_metrics (
    metric_id SERIAL PRIMARY KEY,
    source_table VARCHAR(100),
    metric_name VARCHAR(50),
    metric_value NUMERIC,
    threshold_value NUMERIC,
    status VARCHAR(20), -- 'pass', 'warn', 'fail'
    check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details JSONB
)
```

## ETL Challenges to Solve

### Challenge 1: Real-time Customer 360 Pipeline

**Business Requirement**: Create a unified customer view that updates in real-time from multiple source systems with different update patterns and data formats.

**Complexity Factors**:

- CRM updates during business hours (batch)
- E-commerce events are continuous (streaming)
- Financial transactions are high-frequency (micro-batches)
- Data deduplication across systems
- Handling late-arriving data and out-of-order events

### Challenge 2: High-Performance ETL for Financial Data

**Business Requirement**: Process millions of financial transactions per hour with sub-second latency requirements and ensure exactly-once processing guarantees.

**Complexity Factors**:

- High-frequency data ingestion (100K+ records/second)
- Complex business rules validation
- Real-time fraud detection integration
- Regulatory compliance requirements
- Cross-system transaction reconciliation

### Challenge 3: Data Lake to Data Lakehouse Migration

**Business Requirement**: Transform existing data lake architecture into a performant data lakehouse that supports both analytical and operational workloads.

**Complexity Factors**:

- Multiple file formats (Parquet, JSON, CSV, Avro)
- Schema evolution and versioning
- ACID transaction support
- Time travel and data versioning
- Automated data cataloging and governance

## Advanced ETL Solutions

### Challenge 1 Solution: Real-time Customer 360 Pipeline

```sql
-- Create Customer 360 materialized view with incremental refresh
CREATE MATERIALIZED VIEW customer_360_mv AS
WITH customer_base AS (
    SELECT 
        customer_id,
        customer_uuid,
        first_name,
        last_name,
        email,
        phone,
        address,
        created_at as customer_since,
        updated_at as last_profile_update,
        'crm' as primary_source
    FROM crm_customers
    WHERE customer_id IS NOT NULL
),
order_metrics AS (
    SELECT 
        customer_id,
        COUNT(*) as total_orders,
        SUM(total_amount) as total_lifetime_value,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT currency_code) as currencies_used,
        MODE() WITHIN GROUP (ORDER BY currency_code) as primary_currency,
        COUNT(CASE WHEN order_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as orders_30d,
        COUNT(CASE WHEN order_date >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) as orders_90d
    FROM erp_orders
    WHERE status != 'cancelled'
    GROUP BY customer_id
),
engagement_metrics AS (
    SELECT 
        customer_id,
        COUNT(*) as total_events,
        COUNT(DISTINCT session_id) as total_sessions,
        COUNT(DISTINCT DATE(event_timestamp)) as active_days,
        MAX(event_timestamp) as last_activity,
        
        -- Event type analysis
        COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) as page_views,
        COUNT(CASE WHEN event_type = 'product_view' THEN 1 END) as product_views,
        COUNT(CASE WHEN event_type = 'add_to_cart' THEN 1 END) as cart_additions,
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) as online_purchases,
        
        -- Extract popular categories from event_data
        MODE() WITHIN GROUP (ORDER BY event_data->>'category') FILTER (
            WHERE event_data->>'category' IS NOT NULL
        ) as favorite_category,
        
        -- Device and channel analysis
        MODE() WITHIN GROUP (ORDER BY 
            CASE 
                WHEN user_agent ILIKE '%mobile%' THEN 'mobile'
                WHEN user_agent ILIKE '%tablet%' THEN 'tablet'
                ELSE 'desktop'
            END
        ) as preferred_device,
        
        -- Engagement scoring
        COUNT(*) * 1.0 + 
        COUNT(DISTINCT session_id) * 2.0 + 
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) * 10.0 as engagement_score
    FROM ecommerce_events
    WHERE customer_id IS NOT NULL
        AND event_timestamp >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY customer_id
),
financial_profile AS (
    SELECT 
        ft.account_id,
        -- Link to customer through order mapping
        o.customer_id,
        COUNT(*) as transaction_count,
        SUM(ft.amount) as total_transaction_amount,
        AVG(ft.amount) as avg_transaction_amount,
        MAX(ft.transaction_timestamp) as last_financial_activity,
        
        -- Transaction pattern analysis
        COUNT(CASE WHEN ft.transaction_type = 'payment' THEN 1 END) as payment_count,
        COUNT(CASE WHEN ft.transaction_type = 'refund' THEN 1 END) as refund_count,
        
        -- Risk indicators
        COUNT(CASE WHEN ft.amount < 0 THEN 1 END)::float / COUNT(*) as negative_transaction_rate
    FROM financial_transactions ft
    JOIN erp_orders o ON ft.reference_data->>'order_id' = o.order_number::text
    WHERE ft.is_processed = TRUE
        AND ft.transaction_timestamp >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY ft.account_id, o.customer_id
),
customer_segmentation AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_lifetime_value >= 10000 THEN 'VIP'
            WHEN total_lifetime_value >= 5000 THEN 'High Value'
            WHEN total_lifetime_value >= 1000 THEN 'Medium Value'
            WHEN total_lifetime_value > 0 THEN 'Low Value'
            ELSE 'Prospect'
        END as value_segment,
        
        CASE 
            WHEN last_order_date >= CURRENT_DATE - INTERVAL '30 days' THEN 'Active'
            WHEN last_order_date >= CURRENT_DATE - INTERVAL '90 days' THEN 'At Risk'
            WHEN last_order_date >= CURRENT_DATE - INTERVAL '180 days' THEN 'Dormant'
            ELSE 'Churned'
        END as activity_segment,
        
        CASE 
            WHEN engagement_score >= 1000 THEN 'High Engagement'
            WHEN engagement_score >= 500 THEN 'Medium Engagement'
            WHEN engagement_score >= 100 THEN 'Low Engagement'
            ELSE 'No Engagement'
        END as engagement_segment
    FROM customer_base cb
    LEFT JOIN order_metrics om ON cb.customer_id = om.customer_id
    LEFT JOIN engagement_metrics em ON cb.customer_id = em.customer_id
)
SELECT 
    cb.customer_id,
    cb.customer_uuid,
    cb.first_name,
    cb.last_name,
    cb.email,
    cb.customer_since,
    cb.last_profile_update,
    
    -- Order metrics
    COALESCE(om.total_orders, 0) as total_orders,
    COALESCE(om.total_lifetime_value, 0) as total_lifetime_value,
    om.first_order_date,
    om.last_order_date,
    COALESCE(om.avg_order_value, 0) as avg_order_value,
    om.primary_currency,
    COALESCE(om.orders_30d, 0) as orders_30d,
    COALESCE(om.orders_90d, 0) as orders_90d,
    
    -- Engagement metrics
    COALESCE(em.total_events, 0) as total_events,
    COALESCE(em.total_sessions, 0) as total_sessions,
    COALESCE(em.active_days, 0) as active_days,
    em.last_activity,
    em.favorite_category,
    em.preferred_device,
    COALESCE(em.engagement_score, 0) as engagement_score,
    
    -- Financial profile
    fp.transaction_count,
    fp.total_transaction_amount,
    fp.last_financial_activity,
    COALESCE(fp.negative_transaction_rate, 0) as risk_indicator,
    
    -- Segmentation
    cs.value_segment,
    cs.activity_segment,
    cs.engagement_segment,
    
    -- Computed metrics
    EXTRACT(days FROM CURRENT_DATE - cb.customer_since) as customer_age_days,
    CASE WHEN om.last_order_date IS NOT NULL 
         THEN EXTRACT(days FROM CURRENT_DATE - om.last_order_date)
         ELSE NULL END as days_since_last_order,
    
    -- Data freshness indicators
    CURRENT_TIMESTAMP as last_updated,
    CURRENT_TIMESTAMP - GREATEST(
        cb.last_profile_update,
        COALESCE(em.last_activity, cb.customer_since::timestamp),
        COALESCE(fp.last_financial_activity, cb.customer_since::timestamp)
    ) as data_staleness
    
FROM customer_base cb
LEFT JOIN order_metrics om ON cb.customer_id = om.customer_id
LEFT JOIN engagement_metrics em ON cb.customer_id = em.customer_id
LEFT JOIN financial_profile fp ON cb.customer_id = fp.customer_id
LEFT JOIN customer_segmentation cs ON cb.customer_id = cs.customer_id;

-- Create indexes for performance
CREATE UNIQUE INDEX idx_customer_360_customer_id ON customer_360_mv (customer_id);
CREATE INDEX idx_customer_360_segments ON customer_360_mv (value_segment, activity_segment);
CREATE INDEX idx_customer_360_updated ON customer_360_mv (last_updated);

-- Incremental refresh procedure
CREATE OR REPLACE FUNCTION refresh_customer_360_incremental()
RETURNS TABLE(rows_processed INTEGER, refresh_duration INTERVAL) AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    affected_customers INTEGER;
    last_refresh TIMESTAMP;
BEGIN
    -- Get last refresh timestamp
    SELECT COALESCE(MAX(last_updated), CURRENT_TIMESTAMP - INTERVAL '1 day') 
    INTO last_refresh 
    FROM customer_360_mv;
    
    -- Identify customers who need updates
    WITH customers_to_update AS (
        SELECT DISTINCT customer_id FROM (
            SELECT customer_id FROM crm_customers 
            WHERE updated_at > last_refresh
            UNION
            SELECT customer_id FROM erp_orders 
            WHERE created_at > last_refresh
            UNION
            SELECT customer_id FROM ecommerce_events 
            WHERE event_timestamp > last_refresh
        ) updated_customers
    )
    -- Delete stale records
    DELETE FROM customer_360_mv 
    WHERE customer_id IN (SELECT customer_id FROM customers_to_update);
    
    GET DIAGNOSTICS affected_customers = ROW_COUNT;
    
    -- Insert fresh data (reuse materialized view query with filter)
    INSERT INTO customer_360_mv
    SELECT * FROM (
        -- [Insert the full materialized view query here with WHERE filter]
        -- WHERE cb.customer_id IN (SELECT customer_id FROM customers_to_update)
    ) fresh_data;
    
    RETURN QUERY SELECT affected_customers, CURRENT_TIMESTAMP - start_time;
END;
$$ LANGUAGE plpgsql;

-- Schedule incremental refresh (example cron job)
-- */5 * * * * psql -d database -c "SELECT refresh_customer_360_incremental();"
```

### Challenge 2 Solution: High-Performance Financial ETL

```sql
-- High-Performance Financial Transaction Processing Pipeline

-- Create staging table for incoming transactions
CREATE TABLE financial_transactions_staging (
    staging_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT,
    account_id BIGINT,
    transaction_timestamp TIMESTAMP(6),
    amount DECIMAL(20,4),
    transaction_type VARCHAR(50),
    reference_data JSONB,
    batch_id VARCHAR(100),
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'processed', 'failed'
    error_message TEXT,
    retry_count INTEGER DEFAULT 0
);

-- Create partitioned production table for performance
CREATE TABLE financial_transactions_processed (
    transaction_id BIGINT PRIMARY KEY,
    account_id BIGINT,
    transaction_timestamp TIMESTAMP(6),
    amount DECIMAL(20,4),
    transaction_type VARCHAR(50),
    reference_data JSONB,
    batch_id VARCHAR(100),
    
    -- Computed fields for fast queries
    date_partition DATE GENERATED ALWAYS AS (transaction_timestamp::date) STORED,
    amount_abs DECIMAL(20,4) GENERATED ALWAYS AS (ABS(amount)) STORED,
    is_large_amount BOOLEAN GENERATED ALWAYS AS (ABS(amount) > 10000) STORED,
    
    -- Audit fields
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_duration_ms INTEGER,
    validation_status VARCHAR(20) DEFAULT 'valid',
    risk_score DECIMAL(5,2)
) PARTITION BY RANGE (date_partition);

-- Create monthly partitions
DO $$ 
DECLARE 
    start_date DATE := '2024-01-01';
    end_date DATE := '2025-12-31';
    current_date DATE := start_date;
BEGIN
    WHILE current_date <= end_date LOOP
        EXECUTE format('CREATE TABLE financial_transactions_processed_%s PARTITION OF financial_transactions_processed 
                       FOR VALUES FROM (%L) TO (%L)',
                       to_char(current_date, 'YYYY_MM'),
                       current_date,
                       current_date + INTERVAL '1 month');
        current_date := current_date + INTERVAL '1 month';
    END LOOP;
END $$;

-- Real-time fraud detection function
CREATE OR REPLACE FUNCTION detect_fraud_indicators(
    p_account_id BIGINT,
    p_amount DECIMAL(20,4),
    p_transaction_timestamp TIMESTAMP,
    p_transaction_type VARCHAR(50)
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    risk_score DECIMAL(5,2) := 0;
    recent_transactions INTEGER;
    avg_amount DECIMAL(20,4);
    velocity_score DECIMAL(5,2);
    amount_deviation DECIMAL(5,2);
BEGIN
    -- Velocity check: transactions in last hour
    SELECT COUNT(*), COALESCE(AVG(amount_abs), 0)
    INTO recent_transactions, avg_amount
    FROM financial_transactions_processed
    WHERE account_id = p_account_id
        AND transaction_timestamp >= p_transaction_timestamp - INTERVAL '1 hour'
        AND date_partition >= CURRENT_DATE - 1;
    
    -- High velocity indicator
    velocity_score := LEAST(recent_transactions * 10, 50);
    
    -- Amount deviation from normal
    IF avg_amount > 0 THEN
        amount_deviation := LEAST(ABS(p_amount - avg_amount) / avg_amount * 20, 30);
    END IF;
    
    -- Large amount flag
    IF ABS(p_amount) > 50000 THEN
        risk_score := risk_score + 20;
    END IF;
    
    -- Off-hours transactions
    IF EXTRACT(hour FROM p_transaction_timestamp) NOT BETWEEN 8 AND 18 THEN
        risk_score := risk_score + 10;
    END IF;
    
    -- Weekend transactions
    IF EXTRACT(dow FROM p_transaction_timestamp) IN (0, 6) THEN
        risk_score := risk_score + 5;
    END IF;
    
    RETURN LEAST(velocity_score + amount_deviation + risk_score, 100);
END;
$$ LANGUAGE plpgsql;

-- High-performance batch processing function
CREATE OR REPLACE FUNCTION process_financial_batch(
    p_batch_size INTEGER DEFAULT 10000,
    p_max_processing_time INTERVAL DEFAULT '5 minutes'
)
RETURNS TABLE(
    processed_count INTEGER,
    failed_count INTEGER,
    avg_processing_ms NUMERIC,
    batch_duration INTERVAL
) AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
    processed_records INTEGER := 0;
    failed_records INTEGER := 0;
    total_processing_ms BIGINT := 0;
    record_processing_start TIMESTAMP;
    record_processing_ms INTEGER;
    staging_record RECORD;
    fraud_score DECIMAL(5,2);
BEGIN
    -- Process staging records in batches
    FOR staging_record IN 
        SELECT * FROM financial_transactions_staging 
        WHERE processing_status = 'pending'
        ORDER BY ingestion_timestamp
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    LOOP
        -- Check if we've exceeded max processing time
        IF CURRENT_TIMESTAMP - start_time > p_max_processing_time THEN
            EXIT;
        END IF;
        
        record_processing_start := CURRENT_TIMESTAMP;
        
        BEGIN
            -- Update status to processing
            UPDATE financial_transactions_staging 
            SET processing_status = 'processing'
            WHERE staging_id = staging_record.staging_id;
            
            -- Validate transaction
            IF staging_record.transaction_id IS NULL OR 
               staging_record.account_id IS NULL OR 
               staging_record.amount IS NULL THEN
                RAISE EXCEPTION 'Invalid transaction data';
            END IF;
            
            -- Calculate fraud score
            fraud_score := detect_fraud_indicators(
                staging_record.account_id,
                staging_record.amount,
                staging_record.transaction_timestamp,
                staging_record.transaction_type
            );
            
            -- Calculate processing duration
            record_processing_ms := EXTRACT(epoch FROM CURRENT_TIMESTAMP - record_processing_start) * 1000;
            
            -- Insert into production table
            INSERT INTO financial_transactions_processed (
                transaction_id,
                account_id,
                transaction_timestamp,
                amount,
                transaction_type,
                reference_data,
                batch_id,
                processing_duration_ms,
                risk_score,
                validation_status
            ) VALUES (
                staging_record.transaction_id,
                staging_record.account_id,
                staging_record.transaction_timestamp,
                staging_record.amount,
                staging_record.transaction_type,
                staging_record.reference_data,
                staging_record.batch_id,
                record_processing_ms,
                fraud_score,
                CASE WHEN fraud_score > 70 THEN 'high_risk' 
                     WHEN fraud_score > 40 THEN 'medium_risk' 
                     ELSE 'valid' END
            )
            ON CONFLICT (transaction_id) DO UPDATE SET
                processing_duration_ms = EXCLUDED.processing_duration_ms,
                risk_score = EXCLUDED.risk_score,
                processed_at = CURRENT_TIMESTAMP;
            
            -- Mark as processed
            UPDATE financial_transactions_staging 
            SET processing_status = 'processed',
                processing_duration_ms = record_processing_ms
            WHERE staging_id = staging_record.staging_id;
            
            processed_records := processed_records + 1;
            total_processing_ms := total_processing_ms + record_processing_ms;
            
        EXCEPTION 
            WHEN OTHERS THEN
                -- Handle processing errors
                UPDATE financial_transactions_staging 
                SET processing_status = 'failed',
                    error_message = SQLERRM,
                    retry_count = retry_count + 1
                WHERE staging_id = staging_record.staging_id;
                
                failed_records := failed_records + 1;
                
                -- Log error for monitoring
                INSERT INTO data_quality_metrics (source_table, metric_name, metric_value, status, details)
                VALUES ('financial_transactions_staging', 'processing_error', staging_record.staging_id, 'fail',
                        jsonb_build_object('error', SQLERRM, 'transaction_id', staging_record.transaction_id));
        END;
    END LOOP;
    
    RETURN QUERY SELECT 
        processed_records,
        failed_records,
        CASE WHEN processed_records > 0 THEN total_processing_ms::numeric / processed_records ELSE 0 END,
        CURRENT_TIMESTAMP - start_time;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for high-performance queries
CREATE INDEX CONCURRENTLY idx_financial_processed_account_timestamp 
    ON financial_transactions_processed (account_id, transaction_timestamp DESC);

CREATE INDEX CONCURRENTLY idx_financial_processed_risk_score 
    ON financial_transactions_processed (risk_score DESC) 
    WHERE validation_status != 'valid';

CREATE INDEX CONCURRENTLY idx_financial_staging_status 
    ON financial_transactions_staging (processing_status, ingestion_timestamp);

-- Monitoring and alerting view
CREATE VIEW financial_processing_monitor AS
SELECT 
    DATE_TRUNC('minute', ingestion_timestamp) as minute_bucket,
    COUNT(*) as total_transactions,
    COUNT(CASE WHEN processing_status = 'processed' THEN 1 END) as processed_count,
    COUNT(CASE WHEN processing_status = 'failed' THEN 1 END) as failed_count,
    COUNT(CASE WHEN processing_status = 'pending' THEN 1 END) as pending_count,
    AVG(processing_duration_ms) as avg_processing_ms,
    MAX(processing_duration_ms) as max_processing_ms,
    
    -- SLA indicators (95% processed within 1 second)
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY processing_duration_ms) as p95_processing_ms,
    COUNT(CASE WHEN processing_duration_ms > 1000 THEN 1 END)::float / 
    NULLIF(COUNT(CASE WHEN processing_status != 'pending' THEN 1 END), 0) * 100 as sla_breach_rate
FROM financial_transactions_staging
WHERE ingestion_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
GROUP BY DATE_TRUNC('minute', ingestion_timestamp)
ORDER BY minute_bucket DESC;
```

### Challenge 3 Solution: Data Lakehouse Architecture

```sql
-- Data Lakehouse Implementation with Delta Lake-style features

-- Create versioned tables with ACID properties
CREATE TABLE lakehouse_customers (
    customer_id BIGINT,
    customer_data JSONB,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    version_number INTEGER,
    operation_type VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    transaction_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, version_number)
);

-- Create current view (latest version only)
CREATE VIEW lakehouse_customers_current AS
SELECT 
    customer_id,
    customer_data,
    effective_from,
    effective_to,
    version_number,
    operation_type,
    created_at
FROM lakehouse_customers lc1
WHERE version_number = (
    SELECT MAX(version_number) 
    FROM lakehouse_customers lc2 
    WHERE lc1.customer_id = lc2.customer_id
)
AND operation_type != 'DELETE'
AND (effective_to IS NULL OR effective_to > CURRENT_TIMESTAMP);

-- Time travel function
CREATE OR REPLACE FUNCTION time_travel_customers(travel_timestamp TIMESTAMP)
RETURNS TABLE(
    customer_id BIGINT,
    customer_data JSONB,
    effective_from TIMESTAMP,
    version_number INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lc.customer_id,
        lc.customer_data,
        lc.effective_from,
        lc.version_number
    FROM lakehouse_customers lc
    WHERE lc.effective_from <= travel_timestamp
        AND (lc.effective_to IS NULL OR lc.effective_to > travel_timestamp)
        AND lc.operation_type != 'DELETE'
        AND lc.version_number = (
            SELECT MAX(version_number)
            FROM lakehouse_customers lc2
            WHERE lc2.customer_id = lc.customer_id
                AND lc2.effective_from <= travel_timestamp
                AND (lc2.effective_to IS NULL OR lc2.effective_to > travel_timestamp)
        );
END;
$$ LANGUAGE plpgsql;

-- Schema evolution framework
CREATE TABLE schema_evolution_log (
    evolution_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100),
    schema_version INTEGER,
    evolution_type VARCHAR(50), -- 'ADD_COLUMN', 'DROP_COLUMN', 'MODIFY_COLUMN', 'ADD_CONSTRAINT'
    ddl_statement TEXT,
    backward_compatible BOOLEAN,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100)
);

-- Data quality framework for lakehouse
CREATE OR REPLACE FUNCTION validate_data_quality(
    p_table_name VARCHAR(100),
    p_validation_rules JSONB
)
RETURNS TABLE(
    rule_name VARCHAR(100),
    status VARCHAR(20),
    message TEXT,
    affected_rows INTEGER
) AS $$
DECLARE
    rule_record RECORD;
    validation_query TEXT;
    rule_result RECORD;
BEGIN
    FOR rule_record IN SELECT * FROM jsonb_each(p_validation_rules) LOOP
        -- Build dynamic validation query based on rule type
        CASE rule_record.key
            WHEN 'not_null_check' THEN
                validation_query := format(
                    'SELECT ''%s'' as rule_name, 
                     CASE WHEN COUNT(*) = 0 THEN ''PASS'' ELSE ''FAIL'' END as status,
                     format(''Found %s null values'', COUNT(*)) as message,
                     COUNT(*) as affected_rows
                     FROM %I WHERE %I IS NULL',
                    rule_record.key, p_table_name, rule_record.value
                );
            
            WHEN 'unique_check' THEN
                validation_query := format(
                    'SELECT ''%s'' as rule_name,
                     CASE WHEN COUNT(*) = 0 THEN ''PASS'' ELSE ''FAIL'' END as status,
                     format(''Found %s duplicate values'', COUNT(*)) as message,
                     COUNT(*) as affected_rows
                     FROM (SELECT %I, COUNT(*) as cnt FROM %I GROUP BY %I HAVING COUNT(*) > 1) duplicates',
                    rule_record.key, rule_record.value, p_table_name, rule_record.value
                );
            
            WHEN 'range_check' THEN
                validation_query := format(
                    'SELECT ''%s'' as rule_name,
                     CASE WHEN COUNT(*) = 0 THEN ''PASS'' ELSE ''FAIL'' END as status,
                     format(''Found %s values outside range'', COUNT(*)) as message,
                     COUNT(*) as affected_rows
                     FROM %I WHERE NOT (%s)',
                    rule_record.key, p_table_name, rule_record.value
                );
                
            ELSE
                validation_query := format(
                    'SELECT ''%s'' as rule_name, ''SKIP'' as status, ''Unknown rule type'' as message, 0 as affected_rows',
                    rule_record.key
                );
        END CASE;
        
        -- Execute validation query
        FOR rule_result IN EXECUTE validation_query LOOP
            RETURN QUERY SELECT 
                rule_result.rule_name::VARCHAR(100),
                rule_result.status::VARCHAR(20),
                rule_result.message::TEXT,
                rule_result.affected_rows::INTEGER;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Automated data catalog
CREATE TABLE data_catalog (
    catalog_id SERIAL PRIMARY KEY,
    database_name VARCHAR(100),
    schema_name VARCHAR(100),
    table_name VARCHAR(100),
    column_name VARCHAR(100),
    data_type VARCHAR(100),
    is_nullable BOOLEAN,
    column_description TEXT,
    business_owner VARCHAR(100),
    technical_owner VARCHAR(100),
    data_classification VARCHAR(50), -- 'public', 'internal', 'confidential', 'restricted'
    tags JSONB,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(database_name, schema_name, table_name, column_name)
);

-- Function to auto-populate catalog from information_schema
CREATE OR REPLACE FUNCTION refresh_data_catalog()
RETURNS INTEGER AS $$
DECLARE
    catalog_count INTEGER := 0;
BEGIN
    INSERT INTO data_catalog (
        database_name, schema_name, table_name, column_name, 
        data_type, is_nullable, last_updated
    )
    SELECT 
        table_catalog,
        table_schema,
        table_name,
        column_name,
        data_type,
        is_nullable = 'YES',
        CURRENT_TIMESTAMP
    FROM information_schema.columns
    WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
    ON CONFLICT (database_name, schema_name, table_name, column_name) 
    DO UPDATE SET
        data_type = EXCLUDED.data_type,
        is_nullable = EXCLUDED.is_nullable,
        last_updated = CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS catalog_count = ROW_COUNT;
    RETURN catalog_count;
END;
$$ LANGUAGE plpgsql;

-- Data lineage tracking
CREATE TABLE data_lineage (
    lineage_id SERIAL PRIMARY KEY,
    source_table VARCHAR(200),
    source_column VARCHAR(100),
    target_table VARCHAR(200),
    target_column VARCHAR(100),
    transformation_logic TEXT,
    pipeline_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance optimization with automated statistics
CREATE OR REPLACE FUNCTION optimize_table_statistics()
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_summary TEXT := '';
BEGIN
    FOR table_record IN 
        SELECT schemaname, tablename, n_tup_ins + n_tup_upd + n_tup_del as changes
        FROM pg_stat_user_tables 
        WHERE (n_tup_ins + n_tup_upd + n_tup_del) > 1000
        AND (last_analyze IS NULL OR last_analyze < CURRENT_TIMESTAMP - INTERVAL '1 day')
    LOOP
        EXECUTE format('ANALYZE %I.%I', table_record.schemaname, table_record.tablename);
        result_summary := result_summary || format('Analyzed %s.%s (%s changes); ', 
                                                  table_record.schemaname, 
                                                  table_record.tablename, 
                                                  table_record.changes);
    END LOOP;
    
    RETURN COALESCE(result_summary, 'No tables needed analysis');
END;
$$ LANGUAGE plpgsql;
```

## Data Pipeline Orchestration

### Automated Data Quality Monitoring

```sql
-- Comprehensive data quality monitoring system
CREATE TABLE dq_rule_definitions (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(100) UNIQUE,
    table_name VARCHAR(100),
    rule_type VARCHAR(50), -- 'completeness', 'uniqueness', 'validity', 'accuracy', 'consistency'
    rule_expression TEXT,
    threshold_value DECIMAL(10,4),
    severity VARCHAR(20), -- 'info', 'warning', 'error', 'critical'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data quality rules
INSERT INTO dq_rule_definitions (rule_name, table_name, rule_type, rule_expression, threshold_value, severity) VALUES
('customer_email_not_null', 'crm_customers', 'completeness', 'email IS NOT NULL', 0.95, 'error'),
('customer_id_unique', 'crm_customers', 'uniqueness', 'customer_id', 1.0, 'critical'),
('order_amount_positive', 'erp_orders', 'validity', 'total_amount > 0', 0.99, 'warning'),
('transaction_timestamp_recent', 'financial_transactions', 'accuracy', 'transaction_timestamp >= CURRENT_DATE - INTERVAL ''7 days''', 0.8, 'info');

-- Data quality execution engine
CREATE OR REPLACE FUNCTION execute_data_quality_checks()
RETURNS TABLE(
    rule_name VARCHAR(100),
    table_name VARCHAR(100),
    rule_type VARCHAR(50),
    passed BOOLEAN,
    score DECIMAL(10,4),
    threshold_value DECIMAL(10,4),
    severity VARCHAR(20),
    message TEXT
) AS $$
DECLARE
    rule_def RECORD;
    check_query TEXT;
    result_record RECORD;
    total_rows INTEGER;
    passed_rows INTEGER;
    quality_score DECIMAL(10,4);
BEGIN
    FOR rule_def IN SELECT * FROM dq_rule_definitions WHERE is_active = TRUE LOOP
        BEGIN
            -- Get total row count
            EXECUTE format('SELECT COUNT(*) FROM %I', rule_def.table_name) INTO total_rows;
            
            -- Build and execute quality check query
            CASE rule_def.rule_type
                WHEN 'completeness' THEN
                    check_query := format('SELECT COUNT(*) FROM %I WHERE %s', 
                                        rule_def.table_name, rule_def.rule_expression);
                WHEN 'uniqueness' THEN
                    check_query := format('SELECT COUNT(DISTINCT %s) FROM %I', 
                                        rule_def.rule_expression, rule_def.table_name);
                WHEN 'validity' THEN
                    check_query := format('SELECT COUNT(*) FROM %I WHERE %s', 
                                        rule_def.table_name, rule_def.rule_expression);
                WHEN 'accuracy' THEN
                    check_query := format('SELECT COUNT(*) FROM %I WHERE %s', 
                                        rule_def.table_name, rule_def.rule_expression);
                ELSE
                    check_query := format('SELECT 0');
            END CASE;
            
            EXECUTE check_query INTO passed_rows;
            
            -- Calculate quality score
            quality_score := CASE 
                WHEN total_rows = 0 THEN 0 
                ELSE passed_rows::DECIMAL / total_rows 
            END;
            
            -- Log results
            INSERT INTO data_quality_metrics (
                source_table, metric_name, metric_value, threshold_value, 
                status, details
            ) VALUES (
                rule_def.table_name,
                rule_def.rule_name,
                quality_score,
                rule_def.threshold_value,
                CASE WHEN quality_score >= rule_def.threshold_value THEN 'pass' ELSE 'fail' END,
                jsonb_build_object(
                    'total_rows', total_rows,
                    'passed_rows', passed_rows,
                    'rule_type', rule_def.rule_type,
                    'severity', rule_def.severity
                )
            );
            
            RETURN QUERY SELECT 
                rule_def.rule_name,
                rule_def.table_name,
                rule_def.rule_type,
                quality_score >= rule_def.threshold_value as passed,
                quality_score,
                rule_def.threshold_value,
                rule_def.severity,
                format('Quality score: %.2f%% (threshold: %.2f%%)', 
                       quality_score * 100, rule_def.threshold_value * 100) as message;
                       
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO data_quality_metrics (
                    source_table, metric_name, metric_value, status, details
                ) VALUES (
                    rule_def.table_name,
                    rule_def.rule_name || '_error',
                    0,
                    'fail',
                    jsonb_build_object('error', SQLERRM)
                );
                
                RETURN QUERY SELECT 
                    rule_def.rule_name,
                    rule_def.table_name,
                    rule_def.rule_type,
                    FALSE as passed,
                    0::DECIMAL(10,4) as score,
                    rule_def.threshold_value,
                    'critical'::VARCHAR(20) as severity,
                    format('Error executing rule: %s', SQLERRM) as message;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

## Business Impact and Applications

These advanced ETL and data engineering solutions enable:

- **Real-time Decision Making**: Sub-second data availability for critical business processes
- **Data Governance**: Automated quality monitoring and compliance tracking
- **Scalable Architecture**: Handle petabyte-scale data with efficient processing
- **Cost Optimization**: Reduce infrastructure costs through efficient pipeline design
- **Risk Management**: Real-time fraud detection and data quality alerts

## Key Learning Outcomes

✅ **Advanced ETL Patterns**: Master complex data integration and transformation techniques  
✅ **Real-time Processing**: Build streaming and micro-batch processing systems  
✅ **Data Quality Engineering**: Implement comprehensive validation and monitoring frameworks  
✅ **Lakehouse Architecture**: Design modern data platform architectures  
✅ **Performance Optimization**: Build high-throughput, low-latency data pipelines

---

**Next Exercise**: `07_machine_learning_sql.md` - Implementing ML algorithms and feature engineering in SQL
