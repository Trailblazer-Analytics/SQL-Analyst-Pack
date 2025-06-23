/*
================================================================================
05_distributed_sql_concepts.sql - Understanding Distributed Computing
================================================================================

BUSINESS CONTEXT:
Modern enterprises generate data at unprecedented scales that exceed the
capabilities of traditional single-node databases. Distributed SQL systems
enable organizations to process petabytes of data across multiple machines
while maintaining ACID properties and familiar SQL interfaces.

LEARNING OBJECTIVES:
- Understand distributed database architecture and trade-offs
- Master data partitioning and sharding strategies
- Implement distributed query optimization techniques
- Design fault-tolerant and scalable data systems
- Optimize cross-node data operations and joins

REAL-WORLD SCENARIOS:
- Global e-commerce platforms with regional data centers
- Financial institutions with regulatory data residency requirements
- IoT platforms processing millions of sensor readings per second
- Social media platforms with billions of user interactions daily
*/

-- =============================================
-- SECTION 1: DATA PARTITIONING STRATEGIES
-- =============================================

/*
BUSINESS SCENARIO: Global E-Commerce Platform
A multinational e-commerce company needs to distribute customer and order
data across multiple regions for compliance and performance optimization.
*/

-- Horizontal Partitioning (Sharding) by Geographic Region
-- This demonstrates logical partitioning concepts that would be implemented
-- across multiple database nodes or cloud regions

-- Create partitioned customer table by region
CREATE TABLE customers_distributed (
    customer_id BIGINT NOT NULL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    registration_date DATE NOT NULL,
    region VARCHAR(10) NOT NULL,  -- Partition key
    country VARCHAR(3) NOT NULL,
    
    -- Customer lifecycle data
    customer_segment VARCHAR(50),
    lifetime_value DECIMAL(12,2),
    last_login_date DATE,
    account_status VARCHAR(20),
    
    -- Compliance and privacy
    gdpr_consent BOOLEAN DEFAULT FALSE,
    marketing_consent BOOLEAN DEFAULT FALSE,
    data_retention_date DATE,
    
    PRIMARY KEY (customer_id, region)  -- Composite key including partition key
) 
-- Conceptual partitioning logic (implementation varies by platform)
PARTITION BY LIST (region) (
    PARTITION customers_americas VALUES ('US', 'CA', 'BR', 'MX'),
    PARTITION customers_europe VALUES ('UK', 'DE', 'FR', 'IT'),
    PARTITION customers_apac VALUES ('JP', 'AU', 'SG', 'IN'),
    PARTITION customers_other VALUES (DEFAULT)
);

-- Create orders table with date-based partitioning and region co-location
CREATE TABLE orders_distributed (
    order_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    order_date DATE NOT NULL,
    region VARCHAR(10) NOT NULL,  -- Co-location key
    
    -- Order details
    total_amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    payment_method VARCHAR(50),
    shipping_address_id BIGINT,
    
    -- Business metrics
    processing_time_minutes INT,
    fulfillment_center_id VARCHAR(20),
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    
    PRIMARY KEY (order_id, order_date, region)
)
-- Multi-dimensional partitioning: by date for time-series queries and region for locality
PARTITION BY RANGE (order_date) SUBPARTITION BY LIST (region) (
    PARTITION orders_2024_q1 VALUES LESS THAN ('2024-04-01') (
        SUBPARTITION q1_americas VALUES ('US', 'CA', 'BR', 'MX'),
        SUBPARTITION q1_europe VALUES ('UK', 'DE', 'FR', 'IT'),
        SUBPARTITION q1_apac VALUES ('JP', 'AU', 'SG', 'IN')
    ),
    PARTITION orders_2024_q2 VALUES LESS THAN ('2024-07-01') (
        SUBPARTITION q2_americas VALUES ('US', 'CA', 'BR', 'MX'),
        SUBPARTITION q2_europe VALUES ('UK', 'DE', 'FR', 'IT'),
        SUBPARTITION q2_apac VALUES ('JP', 'AU', 'SG', 'IN')
    )
    -- Additional partitions would be defined for remaining quarters
);

-- =============================================
-- SECTION 2: DISTRIBUTED QUERY OPTIMIZATION
-- =============================================

/*
BUSINESS SCENARIO: Real-Time Customer Analytics
Generate real-time customer insights across globally distributed data
while minimizing cross-region data transfer and latency.
*/

-- Partition-aware query: Customer analysis within region (no cross-partition joins)
WITH regional_customer_metrics AS (
    SELECT 
        c.region,
        c.customer_segment,
        
        -- Customer metrics (computed locally within each partition)
        COUNT(*) as customer_count,
        AVG(c.lifetime_value) as avg_ltv,
        COUNT(CASE WHEN c.last_login_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as active_customers,
        
        -- Recent order metrics (partition-aligned join)
        COUNT(o.order_id) as total_orders_30d,
        SUM(o.total_amount) as total_revenue_30d,
        AVG(o.total_amount) as avg_order_value,
        
        -- Performance metrics
        AVG(o.processing_time_minutes) as avg_processing_time,
        COUNT(CASE WHEN o.actual_delivery_date <= o.estimated_delivery_date THEN 1 END) * 100.0 / 
            COUNT(CASE WHEN o.actual_delivery_date IS NOT NULL THEN 1 END) as on_time_delivery_rate
        
    FROM customers_distributed c
    LEFT JOIN orders_distributed o ON c.customer_id = o.customer_id 
        AND c.region = o.region  -- Partition-aligned join (efficient)
        AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
    
    WHERE c.region = 'US'  -- Partition pruning: only scan US partition
    GROUP BY c.region, c.customer_segment
),

segment_performance_analysis AS (
    SELECT 
        region,
        customer_segment,
        customer_count,
        avg_ltv,
        
        -- Calculate relative performance within region
        avg_ltv - AVG(avg_ltv) OVER (PARTITION BY region) as ltv_vs_regional_avg,
        PERCENT_RANK() OVER (PARTITION BY region ORDER BY avg_ltv) as ltv_percentile_in_region,
        
        -- Operational efficiency metrics
        total_revenue_30d,
        avg_order_value,
        avg_processing_time,
        on_time_delivery_rate,
        
        -- Growth and engagement indicators
        active_customers * 100.0 / customer_count as activity_rate,
        total_orders_30d * 1.0 / NULLIF(active_customers, 0) as orders_per_active_customer,
        
        -- Business health score (composite metric)
        (
            (ltv_percentile_in_region * 0.3) +
            (LEAST(on_time_delivery_rate / 95.0, 1.0) * 0.2) +
            (LEAST((active_customers * 100.0 / customer_count) / 80.0, 1.0) * 0.2) +
            (LEAST(avg_order_value / 150.0, 1.0) * 0.15) +
            (LEAST(100.0 / NULLIF(avg_processing_time, 0) / 10.0, 1.0) * 0.15)
        ) * 100 as segment_health_score
        
    FROM regional_customer_metrics
)

SELECT 
    *,
    -- Strategic recommendations based on performance
    CASE 
        WHEN segment_health_score >= 80 THEN 'Expand Investment'
        WHEN segment_health_score >= 60 THEN 'Optimize Operations'
        WHEN segment_health_score >= 40 THEN 'Strategic Review Required'
        ELSE 'Immediate Intervention Needed'
    END as strategic_recommendation,
    
    -- Tactical action items
    CASE 
        WHEN activity_rate < 50 THEN 'Focus on customer re-engagement'
        WHEN on_time_delivery_rate < 90 THEN 'Improve fulfillment processes'
        WHEN avg_processing_time > 120 THEN 'Optimize order processing'
        WHEN orders_per_active_customer < 1.5 THEN 'Increase purchase frequency'
        ELSE 'Maintain current excellence'
    END as primary_action_item
    
FROM segment_performance_analysis
ORDER BY segment_health_score DESC;

-- =============================================
-- SECTION 3: CROSS-PARTITION ANALYTICS
-- =============================================

/*
BUSINESS SCENARIO: Global Business Intelligence
Generate consolidated insights across all regions while understanding
the performance implications of cross-partition operations.
*/

-- Global customer segmentation with distributed aggregation
-- Note: This query requires data movement across partitions and should be used judiciously
WITH global_customer_aggregates AS (
    -- First, compute aggregates within each partition to minimize data movement
    SELECT 
        region,
        customer_segment,
        COUNT(*) as segment_customers,
        SUM(lifetime_value) as segment_total_ltv,
        AVG(lifetime_value) as segment_avg_ltv,
        COUNT(CASE WHEN last_login_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as segment_active_customers,
        
        -- Statistical measures for global comparison
        STDDEV(lifetime_value) as segment_ltv_stddev,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lifetime_value) as segment_ltv_median,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY lifetime_value) as segment_ltv_p95
        
    FROM customers_distributed
    GROUP BY region, customer_segment
),

global_benchmarks AS (
    -- Compute global benchmarks from regional aggregates
    SELECT 
        customer_segment,
        SUM(segment_customers) as global_customers,
        SUM(segment_total_ltv) / SUM(segment_customers) as global_avg_ltv,
        SQRT(SUM(segment_customers * POWER(segment_ltv_stddev, 2)) / SUM(segment_customers)) as global_ltv_stddev,
        
        -- Weighted regional performance metrics
        SUM(segment_active_customers) * 100.0 / SUM(segment_customers) as global_activity_rate,
        
        -- Regional distribution analysis
        COUNT(DISTINCT region) as regions_with_segment,
        MAX(segment_customers) as largest_regional_segment,
        MIN(segment_customers) as smallest_regional_segment
        
    FROM global_customer_aggregates
    GROUP BY customer_segment
),

regional_vs_global_analysis AS (
    SELECT 
        gca.region,
        gca.customer_segment,
        gca.segment_customers,
        gca.segment_avg_ltv,
        
        -- Global context
        gb.global_avg_ltv,
        gb.global_activity_rate,
        gb.regions_with_segment,
        
        -- Performance relative to global benchmarks
        (gca.segment_avg_ltv - gb.global_avg_ltv) / NULLIF(gb.global_ltv_stddev, 0) as ltv_z_score,
        gca.segment_customers * 100.0 / gb.global_customers as regional_market_share,
        
        -- Regional competitive position
        RANK() OVER (
            PARTITION BY gca.customer_segment 
            ORDER BY gca.segment_avg_ltv DESC
        ) as regional_ltv_rank,
        
        ROW_NUMBER() OVER (
            PARTITION BY gca.customer_segment 
            ORDER BY gca.segment_customers DESC
        ) as regional_size_rank,
        
        -- Strategic insights
        CASE 
            WHEN gca.segment_avg_ltv > gb.global_avg_ltv * 1.2 THEN 'Premium Market'
            WHEN gca.segment_avg_ltv > gb.global_avg_ltv * 0.8 THEN 'Core Market'
            ELSE 'Value Market'
        END as market_positioning,
        
        -- Growth opportunity assessment
        CASE 
            WHEN gca.segment_customers < gb.largest_regional_segment * 0.5 
                 AND gca.segment_avg_ltv > gb.global_avg_ltv 
            THEN 'High Growth Potential'
            WHEN gca.segment_customers > gb.largest_regional_segment * 0.8 
            THEN 'Market Saturation Risk'
            ELSE 'Stable Growth'
        END as growth_opportunity
        
    FROM global_customer_aggregates gca
    JOIN global_benchmarks gb ON gca.customer_segment = gb.customer_segment
)

SELECT 
    region,
    customer_segment,
    segment_customers,
    segment_avg_ltv,
    regional_market_share,
    market_positioning,
    growth_opportunity,
    
    -- Executive summary metrics
    CONCAT(
        'Rank #', regional_ltv_rank, ' of ', regions_with_segment, 
        ' regions for LTV (', 
        CASE WHEN ltv_z_score > 0 THEN '+' ELSE '' END,
        ROUND(ltv_z_score, 2), ' std devs from global avg)'
    ) as competitive_position,
    
    -- Strategic recommendations
    CASE 
        WHEN market_positioning = 'Premium Market' AND growth_opportunity = 'High Growth Potential'
        THEN 'INVEST AGGRESSIVELY - Premium market with growth potential'
        WHEN market_positioning = 'Premium Market' AND growth_opportunity = 'Market Saturation Risk'
        THEN 'OPTIMIZE OPERATIONS - Protect premium position'
        WHEN market_positioning = 'Value Market' AND growth_opportunity = 'High Growth Potential'
        THEN 'STRATEGIC DEVELOPMENT - Build market position'
        WHEN growth_opportunity = 'Market Saturation Risk'
        THEN 'MARKET EXPANSION - Explore adjacent segments'
        ELSE 'MAINTAIN STRATEGY - Continue current approach'
    END as strategic_recommendation
    
FROM regional_vs_global_analysis
ORDER BY customer_segment, regional_ltv_rank;

-- =============================================
-- SECTION 4: DISTRIBUTED TRANSACTION PATTERNS
-- =============================================

/*
BUSINESS SCENARIO: Distributed Order Processing
Implement consistent order processing across multiple regions with
inventory management, payment processing, and fulfillment coordination.
*/

-- Distributed transaction simulation using compensating actions pattern
-- This demonstrates logical transaction handling across distributed systems

-- Create distributed inventory table
CREATE TABLE inventory_distributed (
    product_id BIGINT NOT NULL,
    warehouse_id VARCHAR(20) NOT NULL,
    region VARCHAR(10) NOT NULL,
    available_quantity INT NOT NULL,
    reserved_quantity INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (product_id, warehouse_id, region)
) PARTITION BY LIST (region);

-- Saga pattern for distributed order processing
-- Step 1: Reserve inventory across multiple warehouses
WITH order_requirements AS (
    SELECT 
        12345 as order_id,
        'US' as order_region,
        ARRAY[
            ROW(101, 2, 'WEST_COAST'),
            ROW(102, 1, 'EAST_COAST'),
            ROW(103, 3, 'CENTRAL')
        ] as items  -- (product_id, quantity, preferred_warehouse)
),

inventory_availability_check AS (
    SELECT 
        i.product_id,
        i.warehouse_id,
        i.region,
        i.available_quantity,
        oi.required_quantity,
        
        -- Check if sufficient inventory is available
        CASE 
            WHEN i.available_quantity >= oi.required_quantity THEN 'AVAILABLE'
            WHEN i.available_quantity > 0 THEN 'PARTIAL'
            ELSE 'UNAVAILABLE'
        END as availability_status,
        
        -- Calculate potential allocation
        LEAST(i.available_quantity, oi.required_quantity) as can_allocate,
        oi.required_quantity - LEAST(i.available_quantity, oi.required_quantity) as shortage,
        
        -- Alternative warehouse options
        SUM(i2.available_quantity) OVER (
            PARTITION BY i.product_id 
            ORDER BY 
                CASE WHEN i2.warehouse_id = oi.preferred_warehouse THEN 1 ELSE 2 END,
                i2.available_quantity DESC
        ) as cumulative_regional_inventory
        
    FROM order_requirements or
    CROSS JOIN UNNEST(or.items) as oi(product_id, required_quantity, preferred_warehouse)
    JOIN inventory_distributed i ON oi.product_id = i.product_id 
        AND i.region = or.order_region
    LEFT JOIN inventory_distributed i2 ON i.product_id = i2.product_id 
        AND i2.region = or.order_region
),

inventory_allocation_plan AS (
    SELECT 
        order_id,
        product_id,
        required_quantity,
        
        -- Optimal allocation strategy
        ARRAY_AGG(
            CASE WHEN can_allocate > 0 
            THEN ROW(warehouse_id, can_allocate, availability_status)
            END
            ORDER BY 
                CASE WHEN warehouse_id = preferred_warehouse THEN 1 ELSE 2 END,
                can_allocate DESC
        ) as allocation_plan,
        
        SUM(can_allocate) as total_allocated,
        MAX(required_quantity) - SUM(can_allocate) as total_shortage,
        
        -- Order fulfillment feasibility
        CASE 
            WHEN SUM(can_allocate) >= MAX(required_quantity) THEN 'COMPLETE_FULFILLMENT'
            WHEN SUM(can_allocate) >= MAX(required_quantity) * 0.8 THEN 'PARTIAL_FULFILLMENT'
            ELSE 'INSUFFICIENT_INVENTORY'
        END as fulfillment_status
        
    FROM inventory_availability_check iac
    CROSS JOIN order_requirements or
    GROUP BY order_id, product_id, required_quantity, preferred_warehouse
),

-- Compensating action: Inventory reservation with rollback capability
inventory_reservation_log AS (
    SELECT 
        iap.order_id,
        iap.product_id,
        allocation.warehouse_id,
        allocation.allocated_quantity,
        CURRENT_TIMESTAMP as reservation_timestamp,
        
        -- Generate reservation ID for tracking and potential rollback
        CONCAT(iap.order_id, '-', iap.product_id, '-', allocation.warehouse_id, '-', 
               EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)) as reservation_id,
        
        -- Compensation action SQL (for rollback if needed)
        CONCAT(
            'UPDATE inventory_distributed SET reserved_quantity = reserved_quantity - ',
            allocation.allocated_quantity,
            ' WHERE product_id = ', iap.product_id,
            ' AND warehouse_id = ''', allocation.warehouse_id, '''',
            ' AND region = ''US'';'
        ) as rollback_sql
        
    FROM inventory_allocation_plan iap
    CROSS JOIN UNNEST(iap.allocation_plan) as allocation(warehouse_id, allocated_quantity, status)
    WHERE iap.fulfillment_status IN ('COMPLETE_FULFILLMENT', 'PARTIAL_FULFILLMENT')
)

-- Final order processing decision with distributed coordination
SELECT 
    order_id,
    fulfillment_status,
    
    -- Order summary
    COUNT(DISTINCT product_id) as unique_products,
    SUM(total_allocated) as total_items_allocated,
    SUM(total_shortage) as total_items_short,
    
    -- Fulfillment complexity (number of warehouses involved)
    COUNT(DISTINCT allocation.warehouse_id) as warehouses_required,
    
    -- Estimated fulfillment timeline
    CASE 
        WHEN COUNT(DISTINCT allocation.warehouse_id) = 1 THEN '1-2 days'
        WHEN COUNT(DISTINCT allocation.warehouse_id) <= 3 THEN '2-4 days'
        ELSE '4-7 days'
    END as estimated_delivery_time,
    
    -- Business decision logic
    CASE 
        WHEN fulfillment_status = 'COMPLETE_FULFILLMENT' THEN 'APPROVE_ORDER'
        WHEN fulfillment_status = 'PARTIAL_FULFILLMENT' AND SUM(total_shortage) <= 1 
        THEN 'APPROVE_WITH_BACKORDER'
        WHEN fulfillment_status = 'PARTIAL_FULFILLMENT' 
        THEN 'CUSTOMER_APPROVAL_REQUIRED'
        ELSE 'REJECT_ORDER'
    END as processing_decision,
    
    -- Detailed allocation breakdown for operations team
    ARRAY_AGG(
        CONCAT(
            'Product ', product_id, ': ',
            total_allocated, ' from ', warehouses_required, ' warehouses',
            CASE WHEN total_shortage > 0 THEN CONCAT(' (', total_shortage, ' short)') ELSE '' END
        )
    ) as fulfillment_details
    
FROM inventory_allocation_plan iap
CROSS JOIN UNNEST(iap.allocation_plan) as allocation(warehouse_id, allocated_quantity, status)
GROUP BY order_id, fulfillment_status;

/*
================================================================================
DISTRIBUTED SQL BEST PRACTICES AND PERFORMANCE CONSIDERATIONS
================================================================================

1. PARTITIONING STRATEGIES:
   - Choose partition keys based on query patterns
   - Co-locate related data (customer + orders in same partition)
   - Avoid cross-partition joins when possible
   - Use partition pruning to limit scanned data

2. QUERY OPTIMIZATION:
   - Push computations to data locality
   - Minimize data movement between nodes
   - Use partition-aware joins
   - Aggregate locally before global operations

3. TRANSACTION PATTERNS:
   - Implement saga pattern for distributed transactions
   - Use compensating actions for rollback
   - Design for eventual consistency
   - Plan for partition failures

4. PERFORMANCE MONITORING:
   - Track cross-partition query costs
   - Monitor data distribution skew
   - Measure query response times by partition
   - Optimize hot partitions

5. DATA MODELING:
   - Design with distribution in mind
   - Denormalize for query performance
   - Use materialized views for cross-partition aggregates
   - Plan for data growth and rebalancing

6. BUSINESS CONSIDERATIONS:
   - Balance consistency vs availability
   - Plan for regulatory compliance (data residency)
   - Design for disaster recovery scenarios
   - Consider network latency between regions
*/
