-- File: 11_cloud_platforms/01_aws_redshift_and_athena.sql
-- Topic: AWS Cloud Data Platforms - Redshift and Athena
-- Author: SQL Analyst Pack
-- Date: 2024

/*
PURPOSE:
Master Amazon Web Services (AWS) data platforms for enterprise-scale analytics.
Learn Redshift for data warehousing and Athena for serverless analytics.

BUSINESS APPLICATIONS:
- Enterprise data warehousing with petabyte scale
- Serverless analytics for cost-effective querying
- Data lake analytics and ad-hoc analysis
- Real-time business intelligence and reporting
- Cost-optimized analytics for variable workloads

REAL-WORLD SCENARIOS:
- E-commerce analyzing customer behavior at scale
- Financial services processing transaction data
- Media companies analyzing content consumption
- Healthcare organizations processing patient data
- Retail chains optimizing inventory and logistics

PLATFORM CAPABILITIES:
- Redshift: Columnar storage, MPP architecture, ML integration
- Athena: Serverless queries, pay-per-query, S3 integration
- Integration: Glue, QuickSight, EMR, Kinesis
*/

---------------------------------------------------------------------------------------------------
-- SECTION 1: AWS REDSHIFT DATA WAREHOUSE FUNDAMENTALS
---------------------------------------------------------------------------------------------------

-- Redshift Architecture Overview:
-- - Columnar storage for analytical workloads
-- - Massively Parallel Processing (MPP) 
-- - Automated backups and snapshots
-- - Integration with AWS ecosystem

-- Business Scenario: E-commerce company building enterprise data warehouse
-- Goal: Optimize for analytical queries and reporting performance
-- Key Requirements: Scalability, performance, cost-effectiveness

-- REDSHIFT TABLE DESIGN WITH DISTRIBUTION AND SORT KEYS
-- Proper table design is critical for Redshift performance

-- Customer dimension table with EVEN distribution
CREATE TABLE customers (
    customer_id INTEGER ENCODE ZSTD,
    first_name VARCHAR(50) ENCODE ZSTD,
    last_name VARCHAR(50) ENCODE ZSTD,
    email VARCHAR(100) ENCODE ZSTD,
    registration_date DATE ENCODE ZSTD,
    customer_segment VARCHAR(20) ENCODE ZSTD,
    lifetime_value DECIMAL(12,2) ENCODE ZSTD,
    country VARCHAR(50) ENCODE ZSTD,
    state VARCHAR(50) ENCODE ZSTD
)
DISTSTYLE EVEN
SORTKEY (customer_id, registration_date);

-- Orders fact table with KEY distribution on customer_id
CREATE TABLE orders (
    order_id BIGINT ENCODE ZSTD,
    customer_id INTEGER ENCODE ZSTD,
    order_date DATE ENCODE ZSTD,
    order_value DECIMAL(12,2) ENCODE ZSTD,
    product_category VARCHAR(50) ENCODE ZSTD,
    shipping_cost DECIMAL(8,2) ENCODE ZSTD,
    tax_amount DECIMAL(8,2) ENCODE ZSTD,
    discount_amount DECIMAL(8,2) ENCODE ZSTD,
    payment_method VARCHAR(20) ENCODE ZSTD,
    order_status VARCHAR(20) ENCODE ZSTD
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (order_date, customer_id);

-- Product dimension with ALL distribution (small table)
CREATE TABLE products (
    product_id INTEGER ENCODE ZSTD,
    product_name VARCHAR(200) ENCODE ZSTD,
    category VARCHAR(50) ENCODE ZSTD,
    subcategory VARCHAR(50) ENCODE ZSTD,
    brand VARCHAR(50) ENCODE ZSTD,
    price DECIMAL(10,2) ENCODE ZSTD,
    cost DECIMAL(10,2) ENCODE ZSTD,
    margin_percent DECIMAL(5,2) ENCODE ZSTD,
    launch_date DATE ENCODE ZSTD
)
DISTSTYLE ALL
SORTKEY (category, subcategory, product_id);

-- REDSHIFT OPTIMIZATION TECHNIQUES

-- 1. Analyze table statistics for query optimizer
ANALYZE TABLE customers;
ANALYZE TABLE orders;
ANALYZE TABLE products;

-- 2. Vacuum tables to reclaim space and resort data
VACUUM customers;
VACUUM orders TO 75 PERCENT;  -- Only if needed

-- 3. Monitor query performance with system tables
SELECT 
    query,
    user_name,
    start_time,
    end_time,
    DATEDIFF(seconds, start_time, end_time) as duration_seconds,
    rows,
    bytes
FROM stl_query
WHERE start_time >= DATEADD(hour, -1, GETDATE())
ORDER BY duration_seconds DESC
LIMIT 10;

-- REDSHIFT WORKLOAD MANAGEMENT (WLM)
-- Configure query queues for different workload types

-- Example WLM configuration concepts:
/*
1. ETL Queue: 40% memory, 2 slots, long timeout
2. Reporting Queue: 30% memory, 5 slots, medium timeout  
3. Ad-hoc Queue: 20% memory, 3 slots, short timeout
4. System Queue: 10% memory, auto-managed
*/

-- Monitor WLM queue performance
SELECT 
    service_class,
    num_query_tasks,
    num_executed_queries,
    avg_execution_time,
    avg_queue_time,
    total_queue_time
FROM stv_wlm_service_class_state
ORDER BY service_class;

-- REDSHIFT ADVANCED ANALYTICS

-- Customer Lifetime Value Analysis with Window Functions
WITH customer_orders AS (
    SELECT 
        c.customer_id,
        c.customer_segment,
        c.registration_date,
        o.order_date,
        o.order_value,
        -- Calculate days since registration
        DATEDIFF(day, c.registration_date, o.order_date) as days_since_registration,
        -- Running total of customer spend
        SUM(o.order_value) OVER (
            PARTITION BY c.customer_id 
            ORDER BY o.order_date
        ) as cumulative_spend,
        -- Order sequence number
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id 
            ORDER BY o.order_date
        ) as order_sequence
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
),

customer_metrics AS (
    SELECT 
        customer_id,
        customer_segment,
        COUNT(*) as total_orders,
        SUM(order_value) as total_spend,
        AVG(order_value) as avg_order_value,
        MAX(cumulative_spend) as lifetime_value,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        DATEDIFF(day, MIN(order_date), MAX(order_date)) as customer_lifespan_days,
        -- Calculate average days between orders
        CASE 
            WHEN COUNT(*) > 1 THEN 
                DATEDIFF(day, MIN(order_date), MAX(order_date))::FLOAT / (COUNT(*) - 1)
            ELSE NULL 
        END as avg_days_between_orders
    FROM customer_orders
    GROUP BY customer_id, customer_segment
)

SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_orders), 2) as avg_orders_per_customer,
    ROUND(AVG(total_spend), 2) as avg_customer_spend,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    ROUND(AVG(customer_lifespan_days), 0) as avg_customer_lifespan_days,
    ROUND(AVG(avg_days_between_orders), 0) as avg_days_between_orders,
    -- Customer segment value scoring
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lifetime_value) as median_ltv,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY lifetime_value) as p90_ltv
FROM customer_metrics
GROUP BY customer_segment
ORDER BY avg_customer_spend DESC;

---------------------------------------------------------------------------------------------------
-- SECTION 2: AWS ATHENA SERVERLESS ANALYTICS
---------------------------------------------------------------------------------------------------

-- Athena Architecture Overview:
-- - Serverless query service for S3 data
-- - Pay-per-query pricing model
-- - Integration with AWS Glue Data Catalog
-- - Support for various data formats (Parquet, ORC, JSON, CSV)

-- Business Scenario: Data lake analytics for log files and streaming data
-- Goal: Cost-effective ad-hoc analytics without infrastructure management
-- Key Benefits: No servers to manage, automatic scaling, pay only for queries

-- ATHENA TABLE CREATION (External Tables)
-- Tables are metadata pointing to S3 data locations

-- Create external table for web logs stored in S3
CREATE EXTERNAL TABLE web_logs (
    timestamp string,
    client_ip string,
    method string,
    uri string,
    status_code int,
    response_size bigint,
    user_agent string,
    referer string,
    session_id string,
    user_id string
)
PARTITIONED BY (
    year int,
    month int,
    day int
)
STORED AS PARQUET
LOCATION 's3://your-bucket/web-logs/'
TBLPROPERTIES (
    'projection.enabled' = 'true',
    'projection.year.type' = 'integer',
    'projection.year.range' = '2020,2030',
    'projection.month.type' = 'integer',
    'projection.month.range' = '1,12',
    'projection.day.type' = 'integer',
    'projection.day.range' = '1,31',
    'storage.location.template' = 's3://your-bucket/web-logs/year=${year}/month=${month}/day=${day}/'
);

-- Create external table for sales data
CREATE EXTERNAL TABLE sales_data (
    transaction_id string,
    product_id string,
    customer_id string,
    sale_amount decimal(10,2),
    quantity int,
    discount_percent decimal(5,2),
    sales_rep_id string,
    store_location string,
    payment_method string
)
PARTITIONED BY (
    sale_date string
)
STORED AS PARQUET
LOCATION 's3://your-bucket/sales-data/'
TBLPROPERTIES (
    'projection.enabled' = 'true',
    'projection.sale_date.type' = 'date',
    'projection.sale_date.range' = '2020-01-01,NOW',
    'projection.sale_date.format' = 'yyyy-MM-dd',
    'storage.location.template' = 's3://your-bucket/sales-data/sale_date=${sale_date}/'
);

-- ATHENA QUERY OPTIMIZATION TECHNIQUES

-- 1. Use partitioning to reduce data scanned
SELECT 
    status_code,
    COUNT(*) as request_count,
    SUM(response_size) as total_bytes
FROM web_logs
WHERE year = 2024 
    AND month = 6 
    AND day = 22  -- Partition pruning reduces cost
GROUP BY status_code
ORDER BY request_count DESC;

-- 2. Use columnar formats and compression
-- Parquet with GZIP compression can reduce costs by 90%

-- 3. Use LIMIT for exploratory queries
SELECT *
FROM sales_data
WHERE sale_date = '2024-06-22'
LIMIT 100;  -- Limits data processing

-- 4. Use approximate functions for large datasets
SELECT 
    store_location,
    APPROX_DISTINCT(customer_id) as unique_customers,
    APPROX_PERCENTILE(sale_amount, 0.5) as median_sale_amount,
    COUNT(*) as total_transactions
FROM sales_data
WHERE sale_date >= '2024-06-01'
GROUP BY store_location;

-- ATHENA BUSINESS ANALYTICS EXAMPLES

-- Web Traffic Analysis
WITH hourly_traffic AS (
    SELECT 
        year,
        month, 
        day,
        EXTRACT(hour FROM from_iso8601_timestamp(timestamp)) as hour,
        COUNT(*) as requests,
        COUNT(DISTINCT client_ip) as unique_visitors,
        SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) as error_count,
        AVG(response_size) as avg_response_size
    FROM web_logs
    WHERE year = 2024 AND month = 6 AND day = 22
    GROUP BY year, month, day, EXTRACT(hour FROM from_iso8601_timestamp(timestamp))
),

traffic_metrics AS (
    SELECT 
        hour,
        requests,
        unique_visitors,
        error_count,
        ROUND(error_count * 100.0 / requests, 2) as error_rate_percent,
        ROUND(avg_response_size / 1024.0, 2) as avg_response_size_kb,
        -- Compare to previous hour
        LAG(requests) OVER (ORDER BY hour) as prev_hour_requests,
        ROUND((requests - LAG(requests) OVER (ORDER BY hour)) * 100.0 / 
              LAG(requests) OVER (ORDER BY hour), 2) as hourly_growth_percent
    FROM hourly_traffic
)

SELECT 
    hour,
    requests,
    unique_visitors,
    error_rate_percent,
    avg_response_size_kb,
    COALESCE(hourly_growth_percent, 0) as traffic_growth_percent,
    -- Traffic classification
    CASE 
        WHEN requests > 10000 THEN 'High Traffic'
        WHEN requests > 5000 THEN 'Medium Traffic'
        ELSE 'Low Traffic'
    END as traffic_level
FROM traffic_metrics
ORDER BY hour;

-- Sales Performance Analysis with Athena
WITH daily_sales AS (
    SELECT 
        sale_date,
        store_location,
        COUNT(*) as transaction_count,
        SUM(sale_amount) as total_revenue,
        AVG(sale_amount) as avg_transaction_value,
        SUM(quantity) as total_items_sold,
        COUNT(DISTINCT customer_id) as unique_customers,
        -- Calculate revenue per customer
        SUM(sale_amount) / COUNT(DISTINCT customer_id) as revenue_per_customer
    FROM sales_data
    WHERE sale_date >= '2024-06-01'
    GROUP BY sale_date, store_location
),

store_performance AS (
    SELECT 
        store_location,
        COUNT(DISTINCT sale_date) as active_days,
        SUM(total_revenue) as total_store_revenue,
        AVG(total_revenue) as avg_daily_revenue,
        SUM(unique_customers) as total_customers,
        AVG(revenue_per_customer) as avg_revenue_per_customer,
        -- Performance ranking
        RANK() OVER (ORDER BY SUM(total_revenue) DESC) as revenue_rank,
        RANK() OVER (ORDER BY AVG(revenue_per_customer) DESC) as efficiency_rank
    FROM daily_sales
    GROUP BY store_location
)

SELECT 
    store_location,
    total_store_revenue,
    ROUND(avg_daily_revenue, 2) as avg_daily_revenue,
    total_customers,
    ROUND(avg_revenue_per_customer, 2) as avg_revenue_per_customer,
    revenue_rank,
    efficiency_rank,
    -- Performance scoring
    CASE 
        WHEN revenue_rank <= 3 AND efficiency_rank <= 3 THEN 'Top Performer'
        WHEN revenue_rank <= 5 OR efficiency_rank <= 5 THEN 'Above Average'
        ELSE 'Needs Improvement'
    END as performance_category
FROM store_performance
ORDER BY total_store_revenue DESC;

---------------------------------------------------------------------------------------------------
-- SECTION 3: AWS COST OPTIMIZATION STRATEGIES
---------------------------------------------------------------------------------------------------

-- REDSHIFT COST OPTIMIZATION

-- 1. Right-size cluster based on workload
-- Monitor cluster utilization
SELECT 
    DATE_TRUNC('hour', start_time) as hour,
    AVG(CAST(cpu_percent AS FLOAT)) as avg_cpu_percent,
    AVG(CAST(memory_percent AS FLOAT)) as avg_memory_percent,
    COUNT(*) as active_queries
FROM stl_query_metrics
WHERE start_time >= DATEADD(day, -7, GETDATE())
GROUP BY DATE_TRUNC('hour', start_time)
ORDER BY hour;

-- 2. Use automatic table optimization
ALTER TABLE orders SET TABLE PROPERTIES (
    'auto_mv' = 'true',
    'auto_sort' = 'true'
);

-- 3. Implement pause/resume for development clusters
-- Can be automated with AWS Lambda

-- ATHENA COST OPTIMIZATION

-- 1. Query cost estimation
-- Use EXPLAIN to understand query execution
EXPLAIN 
SELECT store_location, SUM(sale_amount)
FROM sales_data
WHERE sale_date = '2024-06-22'
GROUP BY store_location;

-- 2. Optimize data formats and compression
-- Convert CSV to Parquet with compression
CREATE TABLE sales_data_optimized
WITH (
    format = 'PARQUET',
    parquet_compression = 'GZIP',
    partitioned_by = ARRAY['sale_date']
) AS
SELECT *
FROM sales_data_csv;

-- 3. Use result caching
-- Query results are cached for 24 hours by default

-- 4. Monitor query costs with CloudWatch metrics
-- Set up alerts for unexpected cost spikes

---------------------------------------------------------------------------------------------------
-- SECTION 4: AWS INTEGRATION AND AUTOMATION
---------------------------------------------------------------------------------------------------

-- REDSHIFT INTEGRATION WITH AWS SERVICES

-- 1. Load data from S3 using COPY command
COPY orders
FROM 's3://your-bucket/orders/'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
FORMAT AS PARQUET
TIMEFORMAT AS 'YYYY-MM-DD HH:MI:SS';

-- 2. Unload query results to S3
UNLOAD ('SELECT * FROM customer_metrics WHERE customer_segment = ''VIP''')
TO 's3://your-bucket/exports/vip-customers/'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
FORMAT AS PARQUET
ALLOWOVERWRITE;

-- 3. Schedule ETL with AWS Glue or Lambda
-- Example of automated daily aggregation

-- ATHENA INTEGRATION PATTERNS

-- 1. Use AWS Glue crawlers to auto-discover schema
-- Crawlers can automatically create tables from S3 data

-- 2. Query results can be saved to S3 for further processing
-- Results can feed into ML pipelines or other analytics tools

-- 3. Integration with QuickSight for visualization
-- Athena serves as data source for business intelligence

---------------------------------------------------------------------------------------------------
-- SECTION 5: MONITORING AND PERFORMANCE TUNING
---------------------------------------------------------------------------------------------------

-- REDSHIFT MONITORING QUERIES

-- Find slow-running queries
SELECT 
    query,
    user_name,
    database,
    query_text,
    start_time,
    end_time,
    DATEDIFF(seconds, start_time, end_time) as duration_seconds
FROM stl_query
WHERE DATEDIFF(seconds, start_time, end_time) > 300  -- Queries > 5 minutes
    AND start_time >= DATEADD(day, -1, GETDATE())
ORDER BY duration_seconds DESC;

-- Monitor table skew and distribution
SELECT 
    schema_name,
    table_name,
    size_in_mb,
    pct_skew_across_slices,
    pct_slices_populated
FROM svv_table_info
WHERE pct_skew_across_slices > 10  -- Tables with significant skew
ORDER BY pct_skew_across_slices DESC;

-- ATHENA MONITORING

-- Query execution metrics are available in AWS CloudWatch
-- Key metrics: Data scanned, query execution time, failed queries

-- Use AWS X-Ray for detailed query performance analysis
-- Track query patterns and identify optimization opportunities

---------------------------------------------------------------------------------------------------
-- KEY BUSINESS APPLICATIONS AND INSIGHTS
---------------------------------------------------------------------------------------------------

/*
ENTERPRISE DATA WAREHOUSING:
- Redshift provides petabyte-scale analytics with consistent performance
- Columnar storage and MPP architecture optimize for analytical workloads
- Integration with BI tools enables self-service analytics
- Automated backup and disaster recovery ensure business continuity

COST-EFFECTIVE ANALYTICS:
- Athena enables serverless analytics with pay-per-query pricing
- No infrastructure to manage reduces operational overhead
- Automatic scaling handles variable workloads efficiently
- Integration with S3 provides unlimited storage capacity

DATA LAKE ANALYTICS:
- Query structured and semi-structured data without ETL
- Support for multiple data formats (Parquet, ORC, JSON, CSV)
- Partition projection reduces query costs and improves performance
- Integration with AWS Glue provides automated schema discovery

BUSINESS INTELLIGENCE:
- Real-time dashboards with QuickSight integration
- Self-service analytics for business users
- Automated reporting and alerting capabilities
- Mobile-friendly analytics for executive decision making

NEXT STEPS:
1. Set up AWS account and configure IAM roles
2. Create Redshift cluster or configure Athena access
3. Practice with sample datasets and business scenarios
4. Implement cost monitoring and optimization strategies
5. Integrate with existing business intelligence tools

ADVANCED CONCEPTS TO EXPLORE:
- Redshift Spectrum for querying S3 data from Redshift
- Machine learning integration with SageMaker
- Real-time analytics with Kinesis integration
- Advanced security with VPC and encryption
*/
