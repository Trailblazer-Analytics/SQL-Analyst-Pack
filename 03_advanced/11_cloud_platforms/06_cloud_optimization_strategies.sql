/*
================================================================================
06_cloud_optimization_strategies.sql - Performance Tuning for Cloud
================================================================================

BUSINESS CONTEXT:
Cloud data platforms offer unprecedented scale and flexibility, but require
specific optimization strategies to achieve optimal performance and cost
efficiency. This script covers advanced techniques for tuning queries,
managing resources, and optimizing costs across major cloud platforms.

LEARNING OBJECTIVES:
- Master cloud-specific query optimization techniques
- Implement cost-effective resource management strategies
- Design performance monitoring and alerting systems
- Optimize data storage and retrieval patterns
- Balance performance, cost, and scalability requirements

REAL-WORLD SCENARIOS:
- SaaS platforms optimizing multi-tenant query performance
- Financial services ensuring sub-second regulatory reporting
- E-commerce platforms handling Black Friday traffic spikes
- Data science teams optimizing ML pipeline performance
*/

-- =============================================
-- SECTION 1: QUERY PERFORMANCE OPTIMIZATION
-- =============================================

/*
BUSINESS SCENARIO: Multi-Tenant SaaS Platform
A SaaS platform serves 10,000+ customers with varying data sizes and
query patterns. Optimize performance while maintaining cost efficiency
and ensuring fair resource allocation across tenants.
*/

-- Create tenant-optimized table structure
CREATE TABLE saas_events_optimized (
    tenant_id STRING NOT NULL,           -- Partition key for isolation
    event_id STRING NOT NULL,
    user_id STRING NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    event_type STRING NOT NULL,
    event_data JSON,
    
    -- Pre-computed aggregation columns for performance
    event_hour INT GENERATED ALWAYS AS (EXTRACT(HOUR FROM event_timestamp)),
    event_date DATE GENERATED ALWAYS AS (DATE(event_timestamp)),
    event_month STRING GENERATED ALWAYS AS (FORMAT_DATE('%Y-%m', DATE(event_timestamp))),
    
    -- Tenant classification for optimization
    tenant_tier STRING,  -- 'enterprise', 'professional', 'basic'
    tenant_region STRING,
    
    -- Performance optimization fields
    processed_flag BOOLEAN DEFAULT FALSE,
    batch_id STRING,
    processing_time_ms INT
)
-- Optimal partitioning and clustering strategy
PARTITION BY tenant_id
CLUSTER BY event_date, event_type, user_id
OPTIONS (
    description = "Multi-tenant events table optimized for per-tenant analytics",
    partition_expiration_days = 365
);

-- Performance-optimized tenant analytics query
WITH tenant_performance_metrics AS (
    SELECT 
        tenant_id,
        tenant_tier,
        event_date,
        
        -- Event volume metrics
        COUNT(*) as daily_events,
        COUNT(DISTINCT user_id) as daily_active_users,
        COUNT(DISTINCT event_type) as event_types_used,
        
        -- Performance metrics
        AVG(processing_time_ms) as avg_processing_time,
        PERCENTILE_CONT(processing_time_ms, 0.95) as p95_processing_time,
        COUNT(CASE WHEN processing_time_ms > 1000 THEN 1 END) as slow_events,
        
        -- Usage pattern analysis
        COUNT(CASE WHEN event_hour BETWEEN 9 AND 17 THEN 1 END) as business_hours_events,
        COUNT(CASE WHEN event_hour NOT BETWEEN 9 AND 17 THEN 1 END) as off_hours_events,
        
        -- Data volume indicators
        AVG(LENGTH(TO_JSON_STRING(event_data))) as avg_event_size_bytes,
        SUM(LENGTH(TO_JSON_STRING(event_data))) as total_data_bytes
        
    FROM saas_events_optimized
    WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    AND tenant_id = 'tenant_12345'  -- Partition pruning for single tenant
    GROUP BY tenant_id, tenant_tier, event_date
),

performance_trends AS (
    SELECT 
        *,
        -- Calculate 7-day moving averages for trend analysis
        AVG(daily_events) OVER (
            ORDER BY event_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as events_7d_avg,
        
        AVG(avg_processing_time) OVER (
            ORDER BY event_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as processing_time_7d_avg,
        
        -- Performance degradation detection
        avg_processing_time - LAG(avg_processing_time, 7) OVER (ORDER BY event_date) as processing_time_week_change,
        
        -- Resource utilization patterns
        total_data_bytes / (1024 * 1024) as daily_data_mb,
        business_hours_events * 100.0 / NULLIF(daily_events, 0) as business_hours_percentage,
        
        -- Anomaly detection using statistical bounds
        ABS(daily_events - AVG(daily_events) OVER ()) / 
            NULLIF(STDDEV(daily_events) OVER (), 0) as events_z_score
        
    FROM tenant_performance_metrics
),

optimization_recommendations AS (
    SELECT 
        tenant_id,
        tenant_tier,
        event_date,
        daily_events,
        avg_processing_time,
        processing_time_week_change,
        events_z_score,
        
        -- Performance classification
        CASE 
            WHEN avg_processing_time <= 100 AND p95_processing_time <= 500 THEN 'Excellent'
            WHEN avg_processing_time <= 250 AND p95_processing_time <= 1000 THEN 'Good'
            WHEN avg_processing_time <= 500 AND p95_processing_time <= 2000 THEN 'Acceptable'
            ELSE 'Needs Optimization'
        END as performance_rating,
        
        -- Resource optimization suggestions
        CASE 
            WHEN daily_events > 1000000 AND tenant_tier = 'basic' 
            THEN 'Upgrade to Professional tier recommended'
            WHEN avg_processing_time > 500 AND business_hours_percentage > 80 
            THEN 'Consider dedicated compute resources'
            WHEN daily_data_mb > 1000 AND tenant_tier != 'enterprise' 
            THEN 'Data archiving strategy needed'
            WHEN events_z_score > 3 
            THEN 'Investigate traffic spike causes'
            WHEN processing_time_week_change > 100 
            THEN 'Performance regression detected'
            ELSE 'Performance within expected ranges'
        END as optimization_recommendation,
        
        -- Cost optimization insights
        CASE 
            WHEN business_hours_percentage < 30 AND tenant_tier = 'enterprise' 
            THEN 'Consider scheduled scaling for off-hours'
            WHEN slow_events > daily_events * 0.1 
            THEN 'Query optimization required'
            WHEN event_types_used < 5 AND tenant_tier = 'professional' 
            THEN 'Feature utilization review recommended'
            ELSE 'Cost allocation appropriate'
        END as cost_optimization_insight
        
    FROM performance_trends
)

SELECT 
    tenant_id,
    tenant_tier,
    event_date,
    daily_events,
    ROUND(avg_processing_time, 2) as avg_processing_time_ms,
    performance_rating,
    optimization_recommendation,
    cost_optimization_insight,
    
    -- Executive summary score (0-100)
    LEAST(
        CASE performance_rating
            WHEN 'Excellent' THEN 100
            WHEN 'Good' THEN 85
            WHEN 'Acceptable' THEN 70
            ELSE 50
        END +
        CASE 
            WHEN optimization_recommendation LIKE '%within expected%' THEN 0
            WHEN optimization_recommendation LIKE '%Upgrade%' THEN -10
            WHEN optimization_recommendation LIKE '%dedicated%' THEN -15
            ELSE -20
        END,
        100
    ) as overall_health_score
    
FROM optimization_recommendations
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY event_date DESC, overall_health_score ASC;

-- =============================================
-- SECTION 2: COST OPTIMIZATION STRATEGIES
-- =============================================

/*
BUSINESS SCENARIO: BI Team Cost Management
A business intelligence team needs to optimize cloud data warehouse costs
while maintaining query performance for critical business reports and
ad-hoc analysis workloads.
*/

-- Create cost tracking and optimization table
CREATE TABLE query_cost_analysis (
    query_id STRING NOT NULL,
    user_id STRING NOT NULL,
    query_timestamp TIMESTAMP NOT NULL,
    
    -- Query characteristics
    query_text STRING,
    query_type STRING,  -- 'report', 'adhoc', 'etl', 'ml'
    complexity_score INT,  -- 1-10 scale
    
    -- Resource consumption
    bytes_processed BIGINT,
    bytes_billed BIGINT,
    slot_hours NUMERIC,
    execution_time_ms BIGINT,
    
    -- Cost metrics
    estimated_cost_usd NUMERIC(10,4),
    actual_cost_usd NUMERIC(10,4),
    
    -- Performance metrics
    cache_hit BOOLEAN,
    materialized_view_used BOOLEAN,
    partition_pruning_applied BOOLEAN,
    
    -- Business context
    department STRING,
    priority_level STRING,  -- 'critical', 'important', 'routine'
    business_impact STRING
);

-- Cost optimization analysis with business impact assessment
WITH cost_efficiency_analysis AS (
    SELECT 
        DATE(query_timestamp) as query_date,
        department,
        query_type,
        priority_level,
        
        -- Volume metrics
        COUNT(*) as total_queries,
        COUNT(DISTINCT user_id) as unique_users,
        
        -- Cost metrics
        SUM(actual_cost_usd) as total_cost,
        AVG(actual_cost_usd) as avg_cost_per_query,
        SUM(bytes_processed) / (1024*1024*1024*1024) as total_tb_processed,
        SUM(slot_hours) as total_slot_hours,
        
        -- Efficiency metrics
        AVG(bytes_processed / NULLIF(execution_time_ms, 0) * 1000) as avg_throughput_bytes_per_sec,
        COUNT(CASE WHEN cache_hit THEN 1 END) * 100.0 / COUNT(*) as cache_hit_rate,
        COUNT(CASE WHEN materialized_view_used THEN 1 END) * 100.0 / COUNT(*) as mv_usage_rate,
        COUNT(CASE WHEN partition_pruning_applied THEN 1 END) * 100.0 / COUNT(*) as partition_pruning_rate,
        
        -- Cost per business value
        SUM(actual_cost_usd) / NULLIF(COUNT(CASE WHEN priority_level = 'critical' THEN 1 END), 0) as cost_per_critical_query,
        
        -- Optimization opportunities
        SUM(CASE WHEN NOT cache_hit AND query_type = 'report' THEN actual_cost_usd ELSE 0 END) as cacheable_report_cost,
        SUM(CASE WHEN NOT materialized_view_used AND complexity_score >= 7 THEN actual_cost_usd ELSE 0 END) as mv_opportunity_cost,
        SUM(CASE WHEN NOT partition_pruning_applied THEN actual_cost_usd ELSE 0 END) as partition_optimization_cost
        
    FROM query_cost_analysis
    WHERE query_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    GROUP BY DATE(query_timestamp), department, query_type, priority_level
),

cost_optimization_recommendations AS (
    SELECT 
        query_date,
        department,
        query_type,
        total_cost,
        total_queries,
        cache_hit_rate,
        mv_usage_rate,
        partition_pruning_rate,
        
        -- Potential savings calculations
        cacheable_report_cost * 0.9 as cache_optimization_savings,  -- 90% cost reduction from caching
        mv_opportunity_cost * 0.6 as materialized_view_savings,     -- 60% cost reduction from MVs
        partition_optimization_cost * 0.4 as partition_savings,     -- 40% cost reduction from pruning
        
        -- Total optimization potential
        (cacheable_report_cost * 0.9 + 
         mv_opportunity_cost * 0.6 + 
         partition_optimization_cost * 0.4) as total_potential_savings,
        
        -- Efficiency ratings
        CASE 
            WHEN cache_hit_rate >= 80 THEN 'Excellent'
            WHEN cache_hit_rate >= 60 THEN 'Good'
            WHEN cache_hit_rate >= 40 THEN 'Fair'
            ELSE 'Poor'
        END as cache_efficiency_rating,
        
        CASE 
            WHEN mv_usage_rate >= 50 THEN 'Excellent'
            WHEN mv_usage_rate >= 30 THEN 'Good'
            WHEN mv_usage_rate >= 15 THEN 'Fair'
            ELSE 'Poor'
        END as mv_efficiency_rating,
        
        -- ROI prioritization for optimization efforts
        CASE 
            WHEN total_potential_savings > total_cost * 0.3 THEN 'High Priority'
            WHEN total_potential_savings > total_cost * 0.15 THEN 'Medium Priority'
            WHEN total_potential_savings > total_cost * 0.05 THEN 'Low Priority'
            ELSE 'Optimized'
        END as optimization_priority
        
    FROM cost_efficiency_analysis
),

department_cost_summary AS (
    SELECT 
        department,
        SUM(total_cost) as dept_total_cost,
        AVG(total_cost) as dept_avg_daily_cost,
        SUM(total_potential_savings) as dept_total_savings_opportunity,
        
        -- Department efficiency score
        (AVG(CASE cache_efficiency_rating WHEN 'Excellent' THEN 4 WHEN 'Good' THEN 3 WHEN 'Fair' THEN 2 ELSE 1 END) +
         AVG(CASE mv_efficiency_rating WHEN 'Excellent' THEN 4 WHEN 'Good' THEN 3 WHEN 'Fair' THEN 2 ELSE 1 END)) / 2 as efficiency_score,
        
        -- Strategic recommendations
        STRING_AGG(DISTINCT 
            CASE optimization_priority
                WHEN 'High Priority' THEN CONCAT(query_type, ': Immediate optimization needed')
                WHEN 'Medium Priority' THEN CONCAT(query_type, ': Schedule optimization')
                WHEN 'Low Priority' THEN CONCAT(query_type, ': Monitor performance')
                ELSE CONCAT(query_type, ': Well optimized')
            END,
            '; '
        ) as optimization_roadmap
        
    FROM cost_optimization_recommendations
    GROUP BY department
)

SELECT 
    department,
    ROUND(dept_total_cost, 2) as monthly_cost_usd,
    ROUND(dept_avg_daily_cost, 2) as avg_daily_cost_usd,
    ROUND(dept_total_savings_opportunity, 2) as potential_monthly_savings_usd,
    ROUND(dept_total_savings_opportunity * 100.0 / dept_total_cost, 1) as savings_percentage,
    ROUND(efficiency_score, 1) as efficiency_score_out_of_4,
    
    -- Executive summary
    CASE 
        WHEN efficiency_score >= 3.5 THEN 'Excellent cost efficiency'
        WHEN efficiency_score >= 2.5 THEN 'Good cost management with improvement opportunities'
        WHEN efficiency_score >= 1.5 THEN 'Significant optimization potential'
        ELSE 'Urgent cost optimization required'
    END as executive_summary,
    
    optimization_roadmap,
    
    -- Annual impact projection
    ROUND(dept_total_savings_opportunity * 12, 0) as annual_savings_potential_usd
    
FROM department_cost_summary
ORDER BY dept_total_cost DESC;

-- =============================================
-- SECTION 3: WORKLOAD MANAGEMENT & SCALING
-- =============================================

/*
BUSINESS SCENARIO: Dynamic Workload Scaling
An analytics platform needs to automatically scale resources based on
workload patterns while maintaining SLA commitments and cost efficiency.
*/

-- Create workload monitoring and scaling logic
WITH workload_patterns AS (
    SELECT 
        EXTRACT(HOUR FROM query_timestamp) as hour_of_day,
        EXTRACT(DAYOFWEEK FROM query_timestamp) as day_of_week,
        department,
        query_type,
        
        -- Workload characteristics
        COUNT(*) as queries_per_hour,
        AVG(execution_time_ms) as avg_execution_time,
        SUM(slot_hours) as total_slot_hours,
        MAX(slot_hours) as peak_slot_usage,
        
        -- SLA metrics
        COUNT(CASE WHEN execution_time_ms <= 30000 THEN 1 END) * 100.0 / COUNT(*) as sla_compliance_rate,
        PERCENTILE_CONT(execution_time_ms, 0.95) as p95_execution_time,
        
        -- Resource efficiency
        AVG(bytes_processed / NULLIF(slot_hours, 0)) as bytes_per_slot_hour,
        AVG(actual_cost_usd / NULLIF(slot_hours, 0)) as cost_per_slot_hour
        
    FROM query_cost_analysis
    WHERE query_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
    GROUP BY 
        EXTRACT(HOUR FROM query_timestamp),
        EXTRACT(DAYOFWEEK FROM query_timestamp),
        department,
        query_type
),

scaling_recommendations AS (
    SELECT 
        hour_of_day,
        CASE day_of_week
            WHEN 1 THEN 'Sunday'
            WHEN 2 THEN 'Monday'
            WHEN 3 THEN 'Tuesday'
            WHEN 4 THEN 'Wednesday'
            WHEN 5 THEN 'Thursday'
            WHEN 6 THEN 'Friday'
            WHEN 7 THEN 'Saturday'
        END as day_name,
        
        -- Aggregate workload metrics
        SUM(queries_per_hour) as total_queries,
        SUM(total_slot_hours) as total_slots_needed,
        MAX(peak_slot_usage) as peak_slot_requirement,
        AVG(sla_compliance_rate) as avg_sla_compliance,
        
        -- Scaling decisions based on workload patterns
        CASE 
            WHEN SUM(total_slot_hours) >= 1000 THEN 'XLARGE'  -- Enterprise scale
            WHEN SUM(total_slot_hours) >= 500 THEN 'LARGE'    -- High demand
            WHEN SUM(total_slot_hours) >= 200 THEN 'MEDIUM'   -- Standard
            WHEN SUM(total_slot_hours) >= 50 THEN 'SMALL'     -- Light usage
            ELSE 'MINIMAL'                                     -- Off-peak
        END as recommended_cluster_size,
        
        -- Auto-scaling triggers
        CASE 
            WHEN AVG(sla_compliance_rate) < 90 AND SUM(total_slot_hours) > 100 
            THEN 'SCALE_UP_IMMEDIATE'
            WHEN AVG(sla_compliance_rate) < 95 AND SUM(queries_per_hour) > 1000 
            THEN 'SCALE_UP_PROACTIVE'
            WHEN SUM(total_slot_hours) < 50 AND AVG(sla_compliance_rate) > 98 
            THEN 'SCALE_DOWN_OPPORTUNITY'
            ELSE 'MAINTAIN_CURRENT'
        END as scaling_action,
        
        -- Cost impact estimation
        CASE 
            WHEN SUM(total_slot_hours) >= 1000 THEN SUM(total_slot_hours) * 0.08  -- $0.08/slot-hour enterprise rate
            WHEN SUM(total_slot_hours) >= 200 THEN SUM(total_slot_hours) * 0.10   -- $0.10/slot-hour standard rate
            ELSE SUM(total_slot_hours) * 0.12                                      -- $0.12/slot-hour on-demand rate
        END as estimated_hourly_cost,
        
        -- Performance prediction
        CASE 
            WHEN AVG(sla_compliance_rate) >= 98 THEN 'Excellent performance expected'
            WHEN AVG(sla_compliance_rate) >= 95 THEN 'Good performance expected'
            WHEN AVG(sla_compliance_rate) >= 90 THEN 'Acceptable performance with monitoring'
            ELSE 'Performance issues likely - immediate scaling required'
        END as performance_forecast
        
    FROM workload_patterns
    GROUP BY hour_of_day, day_of_week
),

weekly_scaling_schedule AS (
    SELECT 
        day_name,
        hour_of_day,
        recommended_cluster_size,
        scaling_action,
        ROUND(estimated_hourly_cost, 2) as hourly_cost_usd,
        performance_forecast,
        
        -- Generate scaling schedule
        CONCAT(
            day_name, ' ', 
            LPAD(CAST(hour_of_day AS STRING), 2, '0'), ':00 - ',
            recommended_cluster_size, ' cluster (',
            scaling_action, ')'
        ) as scaling_schedule_entry,
        
        -- Weekly cost projection
        estimated_hourly_cost * 7 as weekly_cost_usd,
        
        -- Efficiency metrics
        total_slots_needed / NULLIF(total_queries, 0) as slots_per_query,
        
        -- Business hour classification
        CASE 
            WHEN day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') 
                 AND hour_of_day BETWEEN 8 AND 18 
            THEN 'Business Hours'
            WHEN day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') 
            THEN 'Extended Hours'
            ELSE 'Weekend'
        END as time_classification
        
    FROM scaling_recommendations
)

SELECT 
    time_classification,
    COUNT(*) as time_periods,
    STRING_AGG(recommended_cluster_size) as cluster_sizes_needed,
    SUM(weekly_cost_usd) as time_period_weekly_cost,
    AVG(slots_per_query) as avg_efficiency,
    
    -- Optimization opportunities
    CASE 
        WHEN time_classification = 'Weekend' AND AVG(estimated_hourly_cost) > 50 
        THEN 'Consider weekend cluster shutdown'
        WHEN time_classification = 'Extended Hours' AND COUNT(*) > 8 
        THEN 'Evaluate extended hours necessity'
        WHEN time_classification = 'Business Hours' AND SUM(weekly_cost_usd) > 5000 
        THEN 'High cost period - review workload efficiency'
        ELSE 'Optimal scaling configuration'
    END as optimization_opportunity,
    
    -- Summary recommendations
    ARRAY_AGG(scaling_schedule_entry ORDER BY 
        CASE day_name 
            WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3 
            WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6 
            ELSE 7 END, 
        hour_of_day
    ) as detailed_schedule
    
FROM weekly_scaling_schedule
GROUP BY time_classification
ORDER BY 
    CASE time_classification 
        WHEN 'Business Hours' THEN 1 
        WHEN 'Extended Hours' THEN 2 
        ELSE 3 
    END;

/*
================================================================================
CLOUD OPTIMIZATION BEST PRACTICES AND ADVANCED STRATEGIES
================================================================================

1. QUERY OPTIMIZATION:
   - Use clustering and partitioning effectively
   - Implement proper WHERE clause filtering
   - Leverage materialized views for repeated computations
   - Cache frequently accessed data
   - Optimize JOIN operations and data distribution

2. COST MANAGEMENT:
   - Monitor slot/compute usage continuously
   - Implement query cost budgets and alerts
   - Use scheduled scaling for predictable workloads
   - Optimize storage costs with proper data lifecycle
   - Leverage spot/preemptible instances where appropriate

3. RESOURCE SCALING:
   - Implement auto-scaling based on workload patterns
   - Use workload isolation for different priority levels
   - Monitor SLA compliance and adjust resources accordingly
   - Plan for peak traffic and seasonal variations
   - Balance performance requirements with cost constraints

4. PERFORMANCE MONITORING:
   - Track query performance trends over time
   - Identify and optimize slow-running queries
   - Monitor resource utilization and bottlenecks
   - Implement alerting for performance degradation
   - Regular performance reviews and optimization cycles

5. CLOUD PLATFORM SPECIFICS:
   - BigQuery: Use clustering, partitioning, and streaming inserts
   - Snowflake: Leverage auto-suspend, multi-cluster warehouses
   - Redshift: Optimize distribution keys and sort keys
   - Azure Synapse: Use proper resource classes and workload management

6. BUSINESS ALIGNMENT:
   - Align resource allocation with business priorities
   - Implement charge-back models for cost accountability
   - Regular cost-benefit analysis of optimization initiatives
   - Balance immediate costs with long-term scalability needs
   - Ensure optimization efforts support business objectives
*/
