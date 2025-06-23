/*
================================================================================
02_azure_synapse_and_data_factory.sql - Microsoft Azure Analytics Services
================================================================================

BUSINESS CONTEXT:
Azure Synapse Analytics is Microsoft's enterprise data warehouse solution that
brings together data integration, data warehousing, and analytics in a unified
platform. This script demonstrates how to leverage Azure's cloud-native SQL
capabilities for modern enterprise analytics.

LEARNING OBJECTIVES:
- Master Azure Synapse Analytics architecture and capabilities
- Implement data integration using Azure Data Factory
- Optimize queries for distributed Azure SQL pools
- Design scalable analytics solutions on Azure
- Integrate with Azure AI and machine learning services

REAL-WORLD SCENARIOS:
- Enterprise data warehouse modernization
- Real-time analytics and reporting
- Multi-source data integration pipelines
- Advanced analytics with Azure ML integration
*/

-- =============================================
-- SECTION 1: AZURE SYNAPSE ARCHITECTURE
-- =============================================

/*
BUSINESS SCENARIO: Global Retail Analytics Platform
A multinational retailer needs to consolidate data from 500+ stores,
e-commerce platforms, and supply chain systems for real-time analytics.
*/

-- Create a dedicated SQL pool for high-performance analytics
-- This would be done through Azure portal or ARM templates
/*
CREATE DEDICATED SQL POOL retailanalytics_pool (
    SERVICE_OBJECTIVE = 'DW1000c',
    MAX_SIZE = 10TB
);
*/

-- Design distributed tables for optimal performance
-- Using hash distribution for large fact tables
CREATE TABLE sales_transactions_distributed (
    transaction_id BIGINT NOT NULL,
    store_id INT NOT NULL,
    customer_id BIGINT,
    product_id INT NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_time TIME,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50),
    sales_channel VARCHAR(50),
    promotion_code VARCHAR(20),
    sales_rep_id INT
)
WITH (
    DISTRIBUTION = HASH(transaction_id),
    CLUSTERED COLUMNSTORE INDEX
);

-- Using round-robin distribution for dimension tables
CREATE TABLE products_dimension (
    product_id INT NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    unit_cost DECIMAL(10,2),
    list_price DECIMAL(10,2),
    product_size VARCHAR(50),
    color VARCHAR(50),
    weight_kg DECIMAL(8,3),
    supplier_id INT,
    created_date DATE,
    updated_date DATE
)
WITH (
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);

-- =============================================
-- SECTION 2: AZURE DATA FACTORY INTEGRATION
-- =============================================

/*
BUSINESS SCENARIO: Multi-Source Data Pipeline
Integrate data from on-premises SQL Server, cloud SaaS applications,
and real-time streaming sources into Azure Synapse.
*/

-- Create external data source for Azure Data Lake
CREATE EXTERNAL DATA SOURCE AzureDataLake
WITH (
    TYPE = HADOOP,
    LOCATION = 'abfss://raw-data@retaildatalake.dfs.core.windows.net/',
    CREDENTIAL = AzureStorageCredential
);

-- Create external file format for parquet files
CREATE EXTERNAL FILE FORMAT ParquetFormat
WITH (
    FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'snappy'
);

-- Create external table for data lake integration
CREATE EXTERNAL TABLE external_customer_behavior (
    customer_id BIGINT,
    session_id VARCHAR(100),
    page_views INT,
    session_duration_minutes INT,
    bounce_rate DECIMAL(5,4),
    conversion_flag BIT,
    device_type VARCHAR(50),
    browser VARCHAR(50),
    traffic_source VARCHAR(100),
    session_date DATE,
    session_hour INT
)
WITH (
    LOCATION = '/customer-behavior/year=2024/',
    DATA_SOURCE = AzureDataLake,
    FILE_FORMAT = ParquetFormat
);

-- =============================================
-- SECTION 3: DISTRIBUTED QUERY OPTIMIZATION
-- =============================================

/*
BUSINESS SCENARIO: Real-Time Sales Performance Dashboard
Generate executive dashboards with sub-second response times
across petabytes of historical and real-time data.
*/

-- Optimized query using distribution key and partition elimination
WITH daily_sales_summary AS (
    SELECT 
        st.transaction_date,
        st.store_id,
        st.sales_channel,
        COUNT(*) as transaction_count,
        SUM(st.total_amount) as daily_revenue,
        AVG(st.total_amount) as avg_transaction_value,
        COUNT(DISTINCT st.customer_id) as unique_customers,
        SUM(st.quantity) as total_items_sold
    FROM sales_transactions_distributed st
    WHERE st.transaction_date >= DATEADD(day, -30, GETDATE())
    GROUP BY st.transaction_date, st.store_id, st.sales_channel
),
store_performance AS (
    SELECT 
        s.store_id,
        s.store_name,
        s.region,
        s.country,
        SUM(dss.daily_revenue) as total_revenue,
        AVG(dss.daily_revenue) as avg_daily_revenue,
        SUM(dss.transaction_count) as total_transactions,
        AVG(dss.unique_customers) as avg_daily_customers,
        -- Calculate growth rate vs previous period
        LAG(SUM(dss.daily_revenue), 30) OVER (
            PARTITION BY s.store_id 
            ORDER BY MAX(dss.transaction_date)
        ) as previous_period_revenue
    FROM daily_sales_summary dss
    JOIN stores_dimension s ON dss.store_id = s.store_id
    GROUP BY s.store_id, s.store_name, s.region, s.country
)
SELECT 
    sp.*,
    CASE 
        WHEN sp.previous_period_revenue > 0 
        THEN ((sp.total_revenue - sp.previous_period_revenue) / sp.previous_period_revenue) * 100
        ELSE NULL 
    END as revenue_growth_percent,
    -- Performance ranking within region
    ROW_NUMBER() OVER (
        PARTITION BY sp.region 
        ORDER BY sp.total_revenue DESC
    ) as regional_rank,
    -- Percentile performance
    PERCENT_RANK() OVER (
        ORDER BY sp.total_revenue
    ) as revenue_percentile
FROM store_performance sp
ORDER BY sp.total_revenue DESC;

-- =============================================
-- SECTION 4: MATERIALIZED VIEWS FOR PERFORMANCE
-- =============================================

/*
BUSINESS SCENARIO: Executive KPI Dashboard
Pre-aggregate complex calculations for instant dashboard loading
and consistent business metrics across the organization.
*/

-- Create materialized view for executive KPIs
CREATE MATERIALIZED VIEW mv_executive_kpis
WITH (DISTRIBUTION = ROUND_ROBIN)
AS
WITH monthly_metrics AS (
    SELECT 
        YEAR(st.transaction_date) as year,
        MONTH(st.transaction_date) as month,
        st.sales_channel,
        COUNT(*) as transaction_count,
        SUM(st.total_amount) as total_revenue,
        COUNT(DISTINCT st.customer_id) as unique_customers,
        COUNT(DISTINCT st.store_id) as active_stores,
        AVG(st.total_amount) as avg_order_value,
        
        -- Customer behavior metrics
        COUNT(DISTINCT CASE 
            WHEN customer_lifetime_orders.order_count = 1 
            THEN st.customer_id 
        END) as new_customers,
        
        COUNT(DISTINCT CASE 
            WHEN customer_lifetime_orders.order_count > 1 
            THEN st.customer_id 
        END) as returning_customers,
        
        -- Product performance
        SUM(st.quantity) as total_items_sold,
        COUNT(DISTINCT st.product_id) as unique_products_sold
        
    FROM sales_transactions_distributed st
    JOIN (
        SELECT 
            customer_id,
            COUNT(*) as order_count
        FROM sales_transactions_distributed
        GROUP BY customer_id
    ) customer_lifetime_orders ON st.customer_id = customer_lifetime_orders.customer_id
    WHERE st.transaction_date >= '2023-01-01'
    GROUP BY 
        YEAR(st.transaction_date),
        MONTH(st.transaction_date),
        st.sales_channel
)
SELECT 
    year,
    month,
    sales_channel,
    transaction_count,
    total_revenue,
    unique_customers,
    active_stores,
    avg_order_value,
    new_customers,
    returning_customers,
    
    -- Calculate retention rate
    CASE 
        WHEN (new_customers + returning_customers) > 0
        THEN (returning_customers * 1.0) / (new_customers + returning_customers) * 100
        ELSE 0 
    END as customer_retention_rate,
    
    -- Revenue per customer
    CASE 
        WHEN unique_customers > 0 
        THEN total_revenue / unique_customers 
        ELSE 0 
    END as revenue_per_customer,
    
    -- Items per transaction
    CASE 
        WHEN transaction_count > 0 
        THEN total_items_sold * 1.0 / transaction_count 
        ELSE 0 
    END as items_per_transaction,
    
    -- Monthly growth calculations
    LAG(total_revenue, 1) OVER (
        PARTITION BY sales_channel 
        ORDER BY year, month
    ) as previous_month_revenue,
    
    LAG(unique_customers, 1) OVER (
        PARTITION BY sales_channel 
        ORDER BY year, month
    ) as previous_month_customers
    
FROM monthly_metrics;

-- =============================================
-- SECTION 5: AZURE ML INTEGRATION
-- =============================================

/*
BUSINESS SCENARIO: Predictive Analytics Integration
Integrate Azure Machine Learning models for customer lifetime value
prediction and demand forecasting directly in SQL queries.
*/

-- Create external table for ML model predictions
CREATE EXTERNAL TABLE ml_customer_predictions (
    customer_id BIGINT,
    predicted_lifetime_value DECIMAL(12,2),
    churn_probability DECIMAL(5,4),
    customer_segment VARCHAR(50),
    next_purchase_probability DECIMAL(5,4),
    prediction_date DATE,
    model_version VARCHAR(20)
)
WITH (
    LOCATION = '/ml-predictions/customer-ltv/',
    DATA_SOURCE = AzureDataLake,
    FILE_FORMAT = ParquetFormat
);

-- Business intelligence query combining transactional data with ML predictions
WITH customer_360_view AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.email,
        c.registration_date,
        c.customer_tier,
        
        -- Historical performance
        COUNT(st.transaction_id) as total_orders,
        SUM(st.total_amount) as total_spent,
        AVG(st.total_amount) as avg_order_value,
        MAX(st.transaction_date) as last_purchase_date,
        DATEDIFF(day, MAX(st.transaction_date), GETDATE()) as days_since_last_purchase,
        
        -- ML predictions
        mlp.predicted_lifetime_value,
        mlp.churn_probability,
        mlp.customer_segment,
        mlp.next_purchase_probability,
        
        -- Business rules
        CASE 
            WHEN mlp.churn_probability > 0.7 THEN 'High Risk'
            WHEN mlp.churn_probability > 0.4 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END as churn_risk_category,
        
        CASE 
            WHEN mlp.predicted_lifetime_value > 5000 THEN 'High Value'
            WHEN mlp.predicted_lifetime_value > 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END as value_segment
        
    FROM customers_dimension c
    LEFT JOIN sales_transactions_distributed st ON c.customer_id = st.customer_id
    LEFT JOIN ml_customer_predictions mlp ON c.customer_id = mlp.customer_id
        AND mlp.prediction_date = (
            SELECT MAX(prediction_date) 
            FROM ml_customer_predictions mlp2 
            WHERE mlp2.customer_id = c.customer_id
        )
    GROUP BY 
        c.customer_id, c.customer_name, c.email, c.registration_date, c.customer_tier,
        mlp.predicted_lifetime_value, mlp.churn_probability, mlp.customer_segment, 
        mlp.next_purchase_probability
)
SELECT 
    cv.*,
    -- Recommended actions based on ML insights
    CASE 
        WHEN cv.churn_risk_category = 'High Risk' AND cv.value_segment = 'High Value'
        THEN 'Urgent Retention Campaign'
        WHEN cv.churn_risk_category = 'High Risk' AND cv.value_segment = 'Medium Value'
        THEN 'Retention Outreach'
        WHEN cv.value_segment = 'High Value' AND cv.next_purchase_probability > 0.6
        THEN 'Upsell Opportunity'
        WHEN cv.days_since_last_purchase > 90
        THEN 'Re-engagement Campaign'
        ELSE 'Standard Marketing'
    END as recommended_action,
    
    -- ROI calculation for retention efforts
    CASE 
        WHEN cv.churn_probability > 0.5
        THEN cv.predicted_lifetime_value * cv.churn_probability * 0.3  -- 30% retention success rate
        ELSE 0
    END as potential_retention_value
    
FROM customer_360_view cv
WHERE cv.total_orders > 0  -- Active customers only
ORDER BY cv.predicted_lifetime_value DESC, cv.churn_probability DESC;

-- =============================================
-- SECTION 6: REAL-TIME ANALYTICS WITH SYNAPSE LINK
-- =============================================

/*
BUSINESS SCENARIO: Real-Time Inventory Management
Monitor inventory levels and sales velocity in real-time to prevent
stockouts and optimize purchasing decisions.
*/

-- Query real-time data from Cosmos DB through Synapse Link
-- This demonstrates analytical queries on operational data
WITH real_time_inventory AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.supplier_id,
        
        -- Current inventory levels (from operational system)
        inventory.current_stock,
        inventory.reorder_point,
        inventory.max_stock_level,
        inventory.last_updated,
        
        -- Recent sales velocity (last 7 days)
        ISNULL(recent_sales.units_sold_7d, 0) as units_sold_7d,
        ISNULL(recent_sales.avg_daily_sales, 0) as avg_daily_sales,
        
        -- Calculate days of inventory remaining
        CASE 
            WHEN recent_sales.avg_daily_sales > 0 
            THEN inventory.current_stock / recent_sales.avg_daily_sales
            ELSE 999  -- Effectively infinite if no recent sales
        END as days_of_inventory_remaining,
        
        -- Stockout risk assessment
        CASE 
            WHEN inventory.current_stock <= inventory.reorder_point THEN 'IMMEDIATE_REORDER'
            WHEN (inventory.current_stock / NULLIF(recent_sales.avg_daily_sales, 0)) <= 7 THEN 'HIGH_RISK'
            WHEN (inventory.current_stock / NULLIF(recent_sales.avg_daily_sales, 0)) <= 14 THEN 'MEDIUM_RISK'
            ELSE 'LOW_RISK'
        END as stockout_risk
        
    FROM products_dimension p
    
    -- Real-time inventory data from operational systems (Synapse Link)
    LEFT JOIN OPENROWSET(
        BULK 'https://retailcosmosdb.documents.azure.com:443/',
        FORMAT = 'CosmosDB',
        CONNECTION = 'Account=retailcosmosdb;Database=inventory'
    ) AS inventory ON p.product_id = inventory.product_id
    
    -- Recent sales data
    LEFT JOIN (
        SELECT 
            product_id,
            SUM(quantity) as units_sold_7d,
            AVG(CAST(quantity as FLOAT)) as avg_daily_sales
        FROM sales_transactions_distributed
        WHERE transaction_date >= DATEADD(day, -7, GETDATE())
        GROUP BY product_id
    ) recent_sales ON p.product_id = recent_sales.product_id
),
supplier_performance AS (
    SELECT 
        s.supplier_id,
        s.supplier_name,
        s.lead_time_days,
        s.reliability_score,
        COUNT(ri.product_id) as products_managed,
        SUM(CASE WHEN ri.stockout_risk IN ('IMMEDIATE_REORDER', 'HIGH_RISK') THEN 1 ELSE 0 END) as high_risk_products,
        AVG(ri.days_of_inventory_remaining) as avg_days_inventory
    FROM real_time_inventory ri
    JOIN suppliers_dimension s ON ri.supplier_id = s.supplier_id
    GROUP BY s.supplier_id, s.supplier_name, s.lead_time_days, s.reliability_score
)
SELECT 
    ri.*,
    s.supplier_name,
    s.lead_time_days,
    s.reliability_score,
    
    -- Recommended order quantity based on lead time and sales velocity
    CASE 
        WHEN ri.avg_daily_sales > 0
        THEN CEILING(ri.avg_daily_sales * (s.lead_time_days + 7)) -- Lead time + 1 week buffer
        ELSE ri.reorder_point * 2  -- Conservative reorder for slow-moving items
    END as recommended_order_quantity,
    
    -- Priority scoring for purchasing decisions
    (
        CASE ri.stockout_risk
            WHEN 'IMMEDIATE_REORDER' THEN 100
            WHEN 'HIGH_RISK' THEN 75
            WHEN 'MEDIUM_RISK' THEN 50
            ELSE 25
        END +
        (ri.avg_daily_sales * 10) +  -- Higher priority for fast-moving items
        (100 - s.reliability_score)   -- Lower reliability = higher priority
    ) as purchasing_priority_score
    
FROM real_time_inventory ri
JOIN suppliers_dimension s ON ri.supplier_id = s.supplier_id
WHERE ri.stockout_risk IN ('IMMEDIATE_REORDER', 'HIGH_RISK', 'MEDIUM_RISK')
ORDER BY purchasing_priority_score DESC, ri.days_of_inventory_remaining ASC;

/*
================================================================================
AZURE SYNAPSE BEST PRACTICES AND PERFORMANCE TIPS
================================================================================

1. DISTRIBUTION STRATEGIES:
   - Use HASH distribution for large fact tables (>2GB)
   - Use ROUND_ROBIN for small dimension tables
   - Choose distribution keys that minimize data movement

2. COLUMNSTORE OPTIMIZATION:
   - Aim for rowgroup sizes of 1M rows
   - Use appropriate compression
   - Monitor columnstore health with DMVs

3. WORKLOAD MANAGEMENT:
   - Use workload isolation for predictable performance
   - Configure appropriate resource classes
   - Monitor resource utilization

4. INTEGRATION PATTERNS:
   - Use PolyBase for efficient data loading
   - Leverage Synapse Link for real-time analytics
   - Implement proper error handling in pipelines

5. COST OPTIMIZATION:
   - Pause dedicated SQL pools when not in use
   - Use serverless SQL for ad-hoc queries
   - Monitor storage and compute costs separately

6. SECURITY CONSIDERATIONS:
   - Implement row-level security for multi-tenant scenarios
   - Use Azure AD authentication
   - Encrypt sensitive data at rest and in transit
*/
