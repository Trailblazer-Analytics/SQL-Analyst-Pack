/*
Title: Cloud-Specific SQL Optimizations
Author: Alexander Nykolaiszyn
Created: 2023-08-12
Description: SQL optimization techniques specific to major cloud database platforms
*/

-- ==========================================
-- INTRODUCTION TO CLOUD SQL OPTIMIZATION
-- ==========================================
-- Cloud-based database services have unique optimization strategies
-- that differ from traditional on-premises databases.
-- This script covers optimization techniques for major cloud platforms.

-- ==========================================
-- 1. AZURE SQL DATABASE OPTIMIZATIONS
-- ==========================================

-- Enable Query Store to track query performance
ALTER DATABASE CURRENT SET QUERY_STORE = ON;
ALTER DATABASE CURRENT SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE,
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30),
    DATA_FLUSH_INTERVAL_SECONDS = 900,
    INTERVAL_LENGTH_MINUTES = 60,
    MAX_STORAGE_SIZE_MB = 1000,
    QUERY_CAPTURE_MODE = AUTO,
    SIZE_BASED_CLEANUP_MODE = AUTO
);

-- Using Elastic Query for cross-database querying
-- Create a database scoped credential
CREATE DATABASE SCOPED CREDENTIAL AzureBlobStorageCredential
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'your_sas_token_here';

-- Create an external data source
CREATE EXTERNAL DATA SOURCE AzureBlobStorage WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = 'https://youraccount.blob.core.windows.net/yourcontainer',
    CREDENTIAL = AzureBlobStorageCredential
);

-- Create an external file format
CREATE EXTERNAL FILE FORMAT CsvFormat WITH (
    FORMAT_TYPE = DELIMITEDTEXT,
    FORMAT_OPTIONS (
        FIELD_TERMINATOR = ',',
        STRING_DELIMITER = '"',
        FIRST_ROW = 2
    )
);

-- Create an external table
CREATE EXTERNAL TABLE ExternalSalesData (
    SaleID INT,
    ProductID INT,
    Quantity INT,
    Amount DECIMAL(10,2),
    SaleDate DATE
)
WITH (
    LOCATION = '/sales_data/*.csv',
    DATA_SOURCE = AzureBlobStorage,
    FILE_FORMAT = CsvFormat
);

-- Query across the external table
SELECT * FROM ExternalSalesData
WHERE SaleDate >= DATEADD(month, -3, GETDATE());

-- Using Columnstore indexes for analytics
CREATE CLUSTERED COLUMNSTORE INDEX CCI_SalesHistory
ON SalesHistory;

-- Using Memory-optimized tables for high-throughput OLTP
CREATE TABLE dbo.OrderProcessing (
    OrderID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    INDEX IX_CustomerID HASH (CustomerID) WITH (BUCKET_COUNT = 1000000)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

-- ==========================================
-- 2. AMAZON REDSHIFT OPTIMIZATIONS
-- ==========================================

-- Distribution key selection
CREATE TABLE customer_sales (
    sale_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    store_id BIGINT NOT NULL,
    sale_amount DECIMAL(10,2),
    sale_date DATE NOT NULL
)
DISTKEY(customer_id)
SORTKEY(sale_date);

-- Using VACUUM to reclaim space and resort rows
VACUUM DELETE ONLY customer_sales;  -- Reclaim space from deleted rows
VACUUM SORT ONLY customer_sales;    -- Resort rows according to sort key
VACUUM FULL customer_sales;         -- Both DELETE and SORT

-- Using ANALYZE to update statistics
ANALYZE customer_sales;
ANALYZE PREDICATE COLUMNS;  -- Only analyze columns used in predicates

-- Workload Management (WLM) configuration
-- In Redshift console or via API, configure:
-- - Concurrency scaling
-- - Short query acceleration
-- - Query monitoring rules
-- - User group query priority

-- Using Redshift Spectrum for external data
CREATE EXTERNAL SCHEMA spectrum_schema
FROM DATA CATALOG
DATABASE 'external_db'
IAM_ROLE 'arn:aws:iam::account-id:role/redshift-spectrum-role'
CREATE EXTERNAL DATABASE IF NOT EXISTS;

CREATE EXTERNAL TABLE spectrum_schema.external_sales (
    sale_id BIGINT,
    customer_id BIGINT,
    product_id BIGINT,
    sale_amount DECIMAL(10,2),
    sale_date DATE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://your-bucket/path/to/data/';

SELECT * FROM spectrum_schema.external_sales
WHERE sale_date >= DATEADD(month, -3, CURRENT_DATE);

-- ==========================================
-- 3. GOOGLE BIGQUERY OPTIMIZATIONS
-- ==========================================

-- Partitioning tables
CREATE OR REPLACE TABLE mydataset.sales_partitioned
PARTITION BY DATE(transaction_timestamp)
AS SELECT * FROM mydataset.sales;

-- Clustering tables
CREATE OR REPLACE TABLE mydataset.sales_clustered
PARTITION BY DATE(transaction_timestamp)
CLUSTER BY customer_id, product_id
AS SELECT * FROM mydataset.sales;

-- Using views for access patterns
CREATE OR REPLACE VIEW mydataset.recent_sales AS
SELECT *
FROM mydataset.sales_partitioned
WHERE DATE(transaction_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- Using authorized views for data access control
-- In another project:
CREATE OR REPLACE VIEW authorized_project.sales_view AS
SELECT * FROM mydataset.sales_partitioned;

-- Materialized views for performance
CREATE MATERIALIZED VIEW mydataset.daily_sales_summary
PARTITION BY date
AS SELECT
  DATE(transaction_timestamp) AS date,
  product_id,
  SUM(quantity) AS total_quantity,
  SUM(amount) AS total_amount
FROM
  mydataset.sales_partitioned
GROUP BY 1, 2;

-- ==========================================
-- 4. SNOWFLAKE OPTIMIZATIONS
-- ==========================================

-- Creating and using virtual warehouses
CREATE WAREHOUSE analytics_wh
WITH WAREHOUSE_SIZE = 'LARGE'
AUTO_SUSPEND = 300
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE analytics_wh;

-- Creating and using a transient table
CREATE TRANSIENT TABLE sales_staging (
    sale_id NUMBER,
    customer_id NUMBER,
    product_id NUMBER,
    sale_amount DECIMAL(10,2),
    sale_date DATE
);

-- Using table clustering
CREATE OR REPLACE TABLE sales_clustered (
    sale_id NUMBER,
    customer_id NUMBER,
    product_id NUMBER,
    sale_amount DECIMAL(10,2),
    sale_date DATE
)
CLUSTER BY (sale_date);

-- Using time-travel for data recovery
CREATE OR REPLACE TABLE sales_history (
    sale_id NUMBER,
    customer_id NUMBER,
    product_id NUMBER,
    sale_amount DECIMAL(10,2),
    sale_date DATE
)
DATA_RETENTION_TIME_IN_DAYS = 90;

-- Query data as of a specific time
SELECT * FROM sales_history AT(TIMESTAMP => 'your-timestamp'::timestamp);
SELECT * FROM sales_history BEFORE(STATEMENT => 'your-query-id');

-- Using resource monitors
CREATE RESOURCE MONITOR monthly_limit
WITH CREDIT_QUOTA = 1000
FREQUENCY = MONTHLY
START_TIMESTAMP = IMMEDIATELY
TRIGGERS
  ON 75 PERCENT DO NOTIFY
  ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE analytics_wh SET RESOURCE_MONITOR = monthly_limit;

-- ==========================================
-- 5. CROSS-PLATFORM OPTIMIZATION STRATEGIES
-- ==========================================

-- 1. Use appropriate data types (smaller is better)
CREATE TABLE optimized_sales (
    sale_id INTEGER,         -- Instead of BIGINT if possible
    customer_id INTEGER,     -- Instead of BIGINT if possible
    product_id SMALLINT,     -- Instead of INTEGER if possible
    quantity SMALLINT,       -- Instead of INTEGER if possible
    sale_amount DECIMAL(10,2),
    sale_date DATE           -- Instead of TIMESTAMP if only date is needed
);

-- 2. Implement lifecycle policies for data
-- Partition data by time periods
CREATE TABLE sales_history_partitioned (
    sale_id INTEGER,
    customer_id INTEGER,
    product_id SMALLINT,
    quantity SMALLINT,
    sale_amount DECIMAL(10,2),
    sale_date DATE,
    sale_year INTEGER,
    sale_month INTEGER
);

-- 3. Cost-aware query patterns
-- Avoid SELECT * in production
SELECT customer_id, SUM(sale_amount) AS total_sales
FROM sales_history_partitioned
WHERE sale_year = 2023 AND sale_month = 6
GROUP BY customer_id;

-- Use approximate functions for large datasets when exact precision isn't needed
-- Examples in different dialects:
-- BigQuery: APPROX_COUNT_DISTINCT(customer_id)
-- Redshift: APPROXIMATE COUNT(DISTINCT customer_id)
-- Snowflake: APPROX_COUNT_DISTINCT(customer_id)

-- 4. Connection pooling
-- Implement at application level or use services like:
-- - AWS RDS Proxy
-- - Azure SQL Connection Pooling
-- - Cloud SQL Proxy (GCP)

-- 5. Caching strategies
-- Use materialized views or result caching where available

-- ==========================================
-- 6. MONITORING & OPTIMIZATION WORKFLOW
-- ==========================================

/*
Cloud Database Optimization Workflow:

1. Establish Performance Baselines
   - Capture query patterns
   - Document expected performance
   - Set up monitoring alerts

2. Regular Review Cycles
   - Weekly/monthly performance reviews
   - Cost optimization reviews
   - Capacity planning

3. Continuous Improvement Process
   - Identify top resource-consuming queries
   - Apply targeted optimizations
   - Measure impact
   - Document learnings

4. Cost Management
   - Right-size compute resources
   - Implement auto-scaling
   - Schedule resources for off-hours
   - Use cost allocation tags/labels

5. Security Considerations
   - Regular permission audits
   - Data encryption
   - Network security
   - Access logging and monitoring
*/
