-- =====================================================
-- 09. Multi-Cloud Strategies
-- =====================================================
-- 
-- Master multi-cloud data strategies, hybrid architectures,
-- and cloud-agnostic analytics solutions for enterprise
-- resilience and optimization.
-- 
-- Business Value:
-- • Avoid vendor lock-in and reduce dependency risks
-- • Optimize costs across multiple cloud providers
-- • Ensure high availability and disaster recovery
-- • Leverage best-of-breed services from each platform
-- 
-- Key Concepts:
-- • Cloud-native data federation
-- • Multi-cloud data governance
-- • Cross-platform cost optimization
-- • Hybrid deployment strategies
-- =====================================================

-- =====================================================
-- Multi-Cloud Data Federation
-- =====================================================

-- Unified view across AWS, Azure, and GCP data sources
-- Using cloud-agnostic SQL patterns

-- Cross-cloud customer 360 view
WITH aws_customer_data AS (
    -- Amazon Redshift customer data
    SELECT 
        customer_id,
        'AWS' as source_cloud,
        first_name,
        last_name,
        email,
        registration_date,
        customer_segment,
        lifetime_value,
        last_activity_date
    FROM aws_redshift.customers.customer_profiles
    WHERE is_active = true
),
azure_transaction_data AS (
    -- Azure Synapse transaction data
    SELECT 
        customer_id,
        'Azure' as source_cloud,
        transaction_date,
        transaction_amount,
        product_category,
        payment_method,
        transaction_status
    FROM azure_synapse.sales.transactions
    WHERE transaction_date >= DATEADD(month, -12, GETDATE())
),
gcp_behavioral_data AS (
    -- Google BigQuery behavioral data
    SELECT 
        customer_id,
        'GCP' as source_cloud,
        session_date,
        page_views,
        session_duration_minutes,
        conversion_events,
        device_type,
        traffic_source
    FROM gcp_bigquery.analytics.user_sessions
    WHERE session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
),
unified_customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.customer_segment,
        c.lifetime_value,
        c.registration_date,
        -- Transaction metrics from Azure
        COUNT(t.customer_id) as total_transactions,
        SUM(t.transaction_amount) as total_spend,
        AVG(t.transaction_amount) as avg_transaction_value,
        MAX(t.transaction_date) as last_transaction_date,
        -- Behavioral metrics from GCP
        COUNT(b.customer_id) as total_sessions,
        SUM(b.page_views) as total_page_views,
        AVG(b.session_duration_minutes) as avg_session_duration,
        SUM(b.conversion_events) as total_conversions
    FROM aws_customer_data c
    LEFT JOIN azure_transaction_data t ON c.customer_id = t.customer_id
    LEFT JOIN gcp_behavioral_data b ON c.customer_id = b.customer_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),
customer_scoring AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        customer_segment,
        total_transactions,
        total_spend,
        avg_transaction_value,
        total_sessions,
        total_conversions,
        -- Multi-dimensional scoring
        CASE 
            WHEN total_spend >= 5000 THEN 40
            WHEN total_spend >= 2000 THEN 30
            WHEN total_spend >= 500 THEN 20
            ELSE 10
        END as spend_score,
        CASE 
            WHEN total_transactions >= 20 THEN 30
            WHEN total_transactions >= 10 THEN 20
            WHEN total_transactions >= 5 THEN 15
            ELSE 5
        END as frequency_score,
        CASE 
            WHEN last_transaction_date >= CURRENT_DATE - INTERVAL '30' DAY THEN 30
            WHEN last_transaction_date >= CURRENT_DATE - INTERVAL '90' DAY THEN 20
            WHEN last_transaction_date >= CURRENT_DATE - INTERVAL '180' DAY THEN 10
            ELSE 0
        END as recency_score,
        -- Calculate conversion rate
        CASE 
            WHEN total_sessions > 0 THEN CAST(total_conversions AS FLOAT) / total_sessions 
            ELSE 0 
        END as conversion_rate
    FROM unified_customer_metrics
)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    customer_segment,
    total_spend,
    total_transactions,
    conversion_rate,
    spend_score + frequency_score + recency_score as total_customer_score,
    -- Strategic customer classification
    CASE 
        WHEN spend_score + frequency_score + recency_score >= 80 THEN 'CHAMPION'
        WHEN spend_score + frequency_score + recency_score >= 60 THEN 'LOYAL_CUSTOMER'
        WHEN spend_score + frequency_score + recency_score >= 40 THEN 'POTENTIAL_LOYALIST'
        WHEN recency_score <= 10 AND spend_score >= 20 THEN 'AT_RISK'
        WHEN recency_score = 0 THEN 'LOST_CUSTOMER'
        ELSE 'NEW_CUSTOMER'
    END as customer_classification,
    -- Cross-cloud data completeness
    CASE 
        WHEN total_transactions > 0 AND total_sessions > 0 THEN 'COMPLETE_PROFILE'
        WHEN total_transactions > 0 THEN 'MISSING_BEHAVIORAL_DATA'
        WHEN total_sessions > 0 THEN 'MISSING_TRANSACTION_DATA'
        ELSE 'INCOMPLETE_PROFILE'
    END as data_completeness_status
FROM customer_scoring
ORDER BY total_customer_score DESC;

-- =====================================================
-- Multi-Cloud Cost Optimization
-- =====================================================

-- Cross-platform cost analysis and optimization
-- Compare costs and performance across providers

WITH aws_costs AS (
    SELECT 
        service_name,
        resource_type,
        region,
        DATE(usage_date) as usage_date,
        'AWS' as cloud_provider,
        SUM(usage_hours) as total_usage_hours,
        SUM(cost_usd) as total_cost_usd,
        AVG(cost_per_hour) as avg_cost_per_hour
    FROM aws_billing.cost_and_usage
    WHERE usage_date >= CURRENT_DATE - INTERVAL '30' DAY
      AND service_name IN ('Amazon Redshift', 'Amazon Athena', 'AWS Glue', 'Amazon EMR')
    GROUP BY 1, 2, 3, 4, 5
),
azure_costs AS (
    SELECT 
        service_name,
        resource_type,
        region,
        DATE(usage_date) as usage_date,
        'Azure' as cloud_provider,
        SUM(usage_hours) as total_usage_hours,
        SUM(cost_usd) as total_cost_usd,
        AVG(cost_per_hour) as avg_cost_per_hour
    FROM azure_billing.consumption_details
    WHERE usage_date >= CURRENT_DATE - INTERVAL '30' DAY
      AND service_name IN ('Azure Synapse Analytics', 'Azure Data Factory', 'Azure Databricks')
    GROUP BY 1, 2, 3, 4, 5
),
gcp_costs AS (
    SELECT 
        service_name,
        resource_type,
        region,
        DATE(usage_date) as usage_date,
        'GCP' as cloud_provider,
        SUM(usage_hours) as total_usage_hours,
        SUM(cost_usd) as total_cost_usd,
        AVG(cost_per_hour) as avg_cost_per_hour
    FROM gcp_billing.cloud_billing_export
    WHERE usage_date >= CURRENT_DATE - INTERVAL '30' DAY
      AND service_name IN ('BigQuery', 'Cloud Dataflow', 'Cloud Dataproc', 'Cloud Composer')
    GROUP BY 1, 2, 3, 4, 5
),
unified_costs AS (
    SELECT * FROM aws_costs
    UNION ALL
    SELECT * FROM azure_costs
    UNION ALL
    SELECT * FROM gcp_costs
),
cost_comparison AS (
    SELECT 
        service_name,
        resource_type,
        region,
        cloud_provider,
        SUM(total_usage_hours) as monthly_usage_hours,
        SUM(total_cost_usd) as monthly_cost_usd,
        AVG(avg_cost_per_hour) as avg_hourly_rate,
        COUNT(DISTINCT usage_date) as active_days
    FROM unified_costs
    GROUP BY 1, 2, 3, 4
),
cross_cloud_analysis AS (
    SELECT 
        service_name,
        resource_type,
        region,
        -- Cost by provider
        MAX(CASE WHEN cloud_provider = 'AWS' THEN monthly_cost_usd END) as aws_monthly_cost,
        MAX(CASE WHEN cloud_provider = 'Azure' THEN monthly_cost_usd END) as azure_monthly_cost,
        MAX(CASE WHEN cloud_provider = 'GCP' THEN monthly_cost_usd END) as gcp_monthly_cost,
        -- Usage by provider
        MAX(CASE WHEN cloud_provider = 'AWS' THEN monthly_usage_hours END) as aws_usage_hours,
        MAX(CASE WHEN cloud_provider = 'Azure' THEN monthly_usage_hours END) as azure_usage_hours,
        MAX(CASE WHEN cloud_provider = 'GCP' THEN monthly_usage_hours END) as gcp_usage_hours,
        -- Rates by provider
        MAX(CASE WHEN cloud_provider = 'AWS' THEN avg_hourly_rate END) as aws_hourly_rate,
        MAX(CASE WHEN cloud_provider = 'Azure' THEN avg_hourly_rate END) as azure_hourly_rate,
        MAX(CASE WHEN cloud_provider = 'GCP' THEN avg_hourly_rate END) as gcp_hourly_rate
    FROM cost_comparison
    GROUP BY 1, 2, 3
),
optimization_insights AS (
    SELECT 
        service_name,
        resource_type,
        region,
        COALESCE(aws_monthly_cost, 0) as aws_cost,
        COALESCE(azure_monthly_cost, 0) as azure_cost,
        COALESCE(gcp_monthly_cost, 0) as gcp_cost,
        COALESCE(aws_hourly_rate, 0) as aws_rate,
        COALESCE(azure_hourly_rate, 0) as azure_rate,
        COALESCE(gcp_hourly_rate, 0) as gcp_rate,
        -- Identify lowest cost provider
        CASE 
            WHEN COALESCE(aws_hourly_rate, 999999) <= COALESCE(azure_hourly_rate, 999999) 
             AND COALESCE(aws_hourly_rate, 999999) <= COALESCE(gcp_hourly_rate, 999999)
            THEN 'AWS'
            WHEN COALESCE(azure_hourly_rate, 999999) <= COALESCE(gcp_hourly_rate, 999999)
            THEN 'Azure'
            ELSE 'GCP'
        END as lowest_cost_provider,
        -- Calculate potential savings
        LEAST(
            COALESCE(aws_hourly_rate, 999999),
            COALESCE(azure_hourly_rate, 999999),
            COALESCE(gcp_hourly_rate, 999999)
        ) as lowest_hourly_rate
    FROM cross_cloud_analysis
)
SELECT 
    service_name,
    resource_type,
    region,
    lowest_cost_provider,
    aws_cost,
    azure_cost,
    gcp_cost,
    aws_rate,
    azure_rate,
    gcp_rate,
    lowest_hourly_rate,
    -- Calculate potential monthly savings
    CASE 
        WHEN lowest_cost_provider = 'AWS' AND azure_cost > 0
        THEN (azure_rate - aws_rate) * COALESCE(azure_usage_hours, 0)
        WHEN lowest_cost_provider = 'AWS' AND gcp_cost > 0
        THEN (gcp_rate - aws_rate) * COALESCE(gcp_usage_hours, 0)
        WHEN lowest_cost_provider = 'Azure' AND aws_cost > 0
        THEN (aws_rate - azure_rate) * COALESCE(aws_usage_hours, 0)
        WHEN lowest_cost_provider = 'Azure' AND gcp_cost > 0
        THEN (gcp_rate - azure_rate) * COALESCE(gcp_usage_hours, 0)
        WHEN lowest_cost_provider = 'GCP' AND aws_cost > 0
        THEN (aws_rate - gcp_rate) * COALESCE(aws_usage_hours, 0)
        WHEN lowest_cost_provider = 'GCP' AND azure_cost > 0
        THEN (azure_rate - gcp_rate) * COALESCE(azure_usage_hours, 0)
        ELSE 0
    END as potential_monthly_savings,
    -- Optimization recommendation
    CASE 
        WHEN lowest_cost_provider = 'AWS' AND (azure_cost > 0 OR gcp_cost > 0)
        THEN 'MIGRATE_TO_AWS'
        WHEN lowest_cost_provider = 'Azure' AND (aws_cost > 0 OR gcp_cost > 0)
        THEN 'MIGRATE_TO_AZURE'
        WHEN lowest_cost_provider = 'GCP' AND (aws_cost > 0 OR azure_cost > 0)
        THEN 'MIGRATE_TO_GCP'
        ELSE 'CURRENT_OPTIMAL'
    END as recommendation
FROM optimization_insights
WHERE aws_cost > 0 OR azure_cost > 0 OR gcp_cost > 0
ORDER BY potential_monthly_savings DESC;

-- =====================================================
-- Multi-Cloud Data Governance
-- =====================================================

-- Unified data governance across cloud platforms
-- Ensuring compliance and data quality standards

WITH data_catalog_aws AS (
    SELECT 
        database_name,
        table_name,
        column_name,
        data_type,
        'AWS' as cloud_platform,
        'Glue Data Catalog' as catalog_service,
        is_pii,
        classification_level,
        last_updated,
        data_owner,
        retention_policy_days
    FROM aws_glue.data_catalog.columns
    WHERE database_name NOT LIKE 'temp_%'
),
data_catalog_azure AS (
    SELECT 
        database_name,
        table_name,
        column_name,
        data_type,
        'Azure' as cloud_platform,
        'Azure Purview' as catalog_service,
        is_pii,
        classification_level,
        last_updated,
        data_owner,
        retention_policy_days
    FROM azure_purview.catalog.columns
    WHERE database_name NOT LIKE 'temp_%'
),
data_catalog_gcp AS (
    SELECT 
        database_name,
        table_name,
        column_name,
        data_type,
        'GCP' as cloud_platform,
        'Cloud Data Catalog' as catalog_service,
        is_pii,
        classification_level,
        last_updated,
        data_owner,
        retention_policy_days
    FROM gcp_datacatalog.catalog.columns
    WHERE database_name NOT LIKE 'temp_%'
),
unified_catalog AS (
    SELECT * FROM data_catalog_aws
    UNION ALL
    SELECT * FROM data_catalog_azure
    UNION ALL
    SELECT * FROM data_catalog_gcp
),
governance_compliance AS (
    SELECT 
        cloud_platform,
        database_name,
        table_name,
        COUNT(*) as total_columns,
        COUNT(CASE WHEN is_pii = true THEN 1 END) as pii_columns,
        COUNT(CASE WHEN classification_level IS NOT NULL THEN 1 END) as classified_columns,
        COUNT(CASE WHEN data_owner IS NOT NULL THEN 1 END) as owned_columns,
        COUNT(CASE WHEN retention_policy_days IS NOT NULL THEN 1 END) as retention_defined_columns,
        -- Compliance scores
        ROUND(COUNT(CASE WHEN classification_level IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as classification_compliance_pct,
        ROUND(COUNT(CASE WHEN data_owner IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as ownership_compliance_pct,
        ROUND(COUNT(CASE WHEN retention_policy_days IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as retention_compliance_pct
    FROM unified_catalog
    GROUP BY 1, 2, 3
),
governance_gaps AS (
    SELECT 
        cloud_platform,
        database_name,
        table_name,
        total_columns,
        pii_columns,
        classification_compliance_pct,
        ownership_compliance_pct,
        retention_compliance_pct,
        -- Overall governance score
        (classification_compliance_pct + ownership_compliance_pct + retention_compliance_pct) / 3 as overall_governance_score,
        -- Identify critical gaps
        CASE 
            WHEN pii_columns > 0 AND classification_compliance_pct < 100 THEN 'CRITICAL: Unclassified PII'
            WHEN ownership_compliance_pct < 50 THEN 'HIGH: Missing Data Ownership'
            WHEN retention_compliance_pct < 50 THEN 'MEDIUM: Missing Retention Policies'
            WHEN classification_compliance_pct < 80 THEN 'LOW: Incomplete Classification'
            ELSE 'COMPLIANT'
        END as governance_status
    FROM governance_compliance
)
SELECT 
    cloud_platform,
    database_name,
    table_name,
    total_columns,
    pii_columns,
    ROUND(overall_governance_score, 2) as governance_score,
    governance_status,
    classification_compliance_pct,
    ownership_compliance_pct,
    retention_compliance_pct,
    -- Recommended actions
    CASE 
        WHEN governance_status LIKE 'CRITICAL%' THEN 'IMMEDIATE_ACTION_REQUIRED'
        WHEN governance_status = 'HIGH: Missing Data Ownership' THEN 'ASSIGN_DATA_OWNERS'
        WHEN governance_status = 'MEDIUM: Missing Retention Policies' THEN 'DEFINE_RETENTION_POLICIES'
        WHEN governance_status = 'LOW: Incomplete Classification' THEN 'COMPLETE_DATA_CLASSIFICATION'
        ELSE 'MAINTAIN_CURRENT_STANDARDS'
    END as recommended_action
FROM governance_gaps
ORDER BY 
    CASE governance_status 
        WHEN 'CRITICAL: Unclassified PII' THEN 1
        WHEN 'HIGH: Missing Data Ownership' THEN 2
        WHEN 'MEDIUM: Missing Retention Policies' THEN 3
        WHEN 'LOW: Incomplete Classification' THEN 4
        ELSE 5
    END,
    pii_columns DESC,
    overall_governance_score ASC;

-- =====================================================
-- Multi-Cloud Disaster Recovery
-- =====================================================

-- Cross-cloud backup and disaster recovery monitoring
-- Ensuring business continuity across platforms

WITH backup_status_aws AS (
    SELECT 
        database_name,
        table_name,
        'AWS' as primary_cloud,
        'S3' as backup_location,
        backup_timestamp,
        backup_size_gb,
        backup_type,
        recovery_point_objective_hours,
        recovery_time_objective_hours,
        backup_success
    FROM aws_s3.backup_logs
    WHERE backup_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
),
backup_status_azure AS (
    SELECT 
        database_name,
        table_name,
        'Azure' as primary_cloud,
        'Blob Storage' as backup_location,
        backup_timestamp,
        backup_size_gb,
        backup_type,
        recovery_point_objective_hours,
        recovery_time_objective_hours,
        backup_success
    FROM azure_storage.backup_logs
    WHERE backup_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
),
backup_status_gcp AS (
    SELECT 
        database_name,
        table_name,
        'GCP' as primary_cloud,
        'Cloud Storage' as backup_location,
        backup_timestamp,
        backup_size_gb,
        backup_type,
        recovery_point_objective_hours,
        recovery_time_objective_hours,
        backup_success
    FROM gcp_storage.backup_logs
    WHERE backup_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
),
unified_backup_status AS (
    SELECT * FROM backup_status_aws
    UNION ALL
    SELECT * FROM backup_status_azure
    UNION ALL
    SELECT * FROM backup_status_gcp
),
dr_readiness AS (
    SELECT 
        primary_cloud,
        database_name,
        table_name,
        COUNT(*) as total_backups,
        COUNT(CASE WHEN backup_success = true THEN 1 END) as successful_backups,
        MAX(backup_timestamp) as last_successful_backup,
        SUM(backup_size_gb) as total_backup_size_gb,
        AVG(recovery_point_objective_hours) as avg_rpo_hours,
        AVG(recovery_time_objective_hours) as avg_rto_hours,
        -- Calculate backup success rate
        ROUND(COUNT(CASE WHEN backup_success = true THEN 1 END) * 100.0 / COUNT(*), 2) as backup_success_rate,
        -- Check if backup is recent enough
        CASE 
            WHEN MAX(backup_timestamp) >= CURRENT_TIMESTAMP - INTERVAL '24' HOUR THEN 'CURRENT'
            WHEN MAX(backup_timestamp) >= CURRENT_TIMESTAMP - INTERVAL '48' HOUR THEN 'WARNING'
            ELSE 'CRITICAL'
        END as backup_freshness_status
    FROM unified_backup_status
    GROUP BY 1, 2, 3
),
cross_cloud_redundancy AS (
    SELECT 
        database_name,
        table_name,
        COUNT(DISTINCT primary_cloud) as cloud_redundancy_count,
        STRING_AGG(primary_cloud, ', ') as available_clouds,
        MIN(backup_success_rate) as min_backup_success_rate,
        MAX(backup_success_rate) as max_backup_success_rate,
        MIN(avg_rpo_hours) as best_rpo_hours,
        MIN(avg_rto_hours) as best_rto_hours,
        -- Determine redundancy level
        CASE 
            WHEN COUNT(DISTINCT primary_cloud) >= 3 THEN 'TRIPLE_REDUNDANCY'
            WHEN COUNT(DISTINCT primary_cloud) = 2 THEN 'DUAL_REDUNDANCY'
            WHEN COUNT(DISTINCT primary_cloud) = 1 THEN 'SINGLE_CLOUD_ONLY'
            ELSE 'NO_BACKUP'
        END as redundancy_level
    FROM dr_readiness
    GROUP BY 1, 2
),
dr_assessment AS (
    SELECT 
        d.database_name,
        d.table_name,
        r.redundancy_level,
        r.available_clouds,
        r.min_backup_success_rate,
        r.best_rpo_hours,
        r.best_rto_hours,
        d.backup_freshness_status,
        -- Calculate overall DR score
        CASE 
            WHEN r.redundancy_level = 'TRIPLE_REDUNDANCY' AND r.min_backup_success_rate >= 95 THEN 100
            WHEN r.redundancy_level = 'DUAL_REDUNDANCY' AND r.min_backup_success_rate >= 90 THEN 80
            WHEN r.redundancy_level = 'SINGLE_CLOUD_ONLY' AND r.min_backup_success_rate >= 95 THEN 60
            WHEN r.redundancy_level = 'SINGLE_CLOUD_ONLY' AND r.min_backup_success_rate >= 80 THEN 40
            ELSE 20
        END as dr_readiness_score,
        -- Risk assessment
        CASE 
            WHEN r.redundancy_level = 'NO_BACKUP' THEN 'CRITICAL: No Backup Strategy'
            WHEN r.redundancy_level = 'SINGLE_CLOUD_ONLY' AND r.min_backup_success_rate < 80 THEN 'HIGH: Unreliable Single Cloud Backup'
            WHEN d.backup_freshness_status = 'CRITICAL' THEN 'HIGH: Stale Backup Data'
            WHEN r.redundancy_level = 'SINGLE_CLOUD_ONLY' THEN 'MEDIUM: Single Point of Failure'
            WHEN r.min_backup_success_rate < 95 THEN 'MEDIUM: Backup Reliability Issues'
            ELSE 'LOW: Well Protected'
        END as risk_level
    FROM dr_readiness d
    JOIN cross_cloud_redundancy r ON d.database_name = r.database_name AND d.table_name = r.table_name
)
SELECT 
    database_name,
    table_name,
    redundancy_level,
    available_clouds,
    dr_readiness_score,
    risk_level,
    min_backup_success_rate,
    best_rpo_hours,
    best_rto_hours,
    backup_freshness_status,
    -- Recommendations
    CASE 
        WHEN risk_level LIKE 'CRITICAL%' THEN 'IMPLEMENT_BACKUP_STRATEGY_IMMEDIATELY'
        WHEN risk_level LIKE 'HIGH%' AND redundancy_level = 'SINGLE_CLOUD_ONLY' THEN 'ADD_CROSS_CLOUD_REDUNDANCY'
        WHEN risk_level LIKE 'HIGH%' THEN 'IMPROVE_BACKUP_RELIABILITY'
        WHEN risk_level LIKE 'MEDIUM%' AND redundancy_level = 'SINGLE_CLOUD_ONLY' THEN 'CONSIDER_MULTI_CLOUD_BACKUP'
        WHEN min_backup_success_rate < 95 THEN 'OPTIMIZE_BACKUP_PROCESSES'
        ELSE 'MAINTAIN_CURRENT_DR_STRATEGY'
    END as recommendation
FROM dr_assessment
ORDER BY 
    CASE risk_level 
        WHEN 'CRITICAL: No Backup Strategy' THEN 1
        WHEN 'HIGH: Unreliable Single Cloud Backup' THEN 2
        WHEN 'HIGH: Stale Backup Data' THEN 3
        WHEN 'MEDIUM: Single Point of Failure' THEN 4
        WHEN 'MEDIUM: Backup Reliability Issues' THEN 5
        ELSE 6
    END,
    dr_readiness_score ASC;

-- =====================================================
-- Multi-Cloud Performance Benchmarking
-- =====================================================

-- Compare query performance across cloud platforms
-- For workload optimization and placement decisions

WITH query_performance_aws AS (
    SELECT 
        query_id,
        'AWS Redshift' as platform,
        query_type,
        data_size_gb,
        execution_time_seconds,
        cpu_utilization_pct,
        memory_usage_gb,
        io_operations,
        cost_usd,
        execution_timestamp
    FROM aws_redshift.query_performance_log
    WHERE execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30' DAY
      AND execution_time_seconds > 0
),
query_performance_azure AS (
    SELECT 
        query_id,
        'Azure Synapse' as platform,
        query_type,
        data_size_gb,
        execution_time_seconds,
        cpu_utilization_pct,
        memory_usage_gb,
        io_operations,
        cost_usd,
        execution_timestamp
    FROM azure_synapse.query_performance_log
    WHERE execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30' DAY
      AND execution_time_seconds > 0
),
query_performance_gcp AS (
    SELECT 
        query_id,
        'Google BigQuery' as platform,
        query_type,
        data_size_gb,
        execution_time_seconds,
        cpu_utilization_pct,
        memory_usage_gb,
        io_operations,
        cost_usd,
        execution_timestamp
    FROM gcp_bigquery.query_performance_log
    WHERE execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30' DAY
      AND execution_time_seconds > 0
),
unified_performance AS (
    SELECT * FROM query_performance_aws
    UNION ALL
    SELECT * FROM query_performance_azure
    UNION ALL
    SELECT * FROM query_performance_gcp
),
performance_benchmarks AS (
    SELECT 
        platform,
        query_type,
        COUNT(*) as total_queries,
        AVG(execution_time_seconds) as avg_execution_time,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_seconds) as median_execution_time,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_seconds) as p95_execution_time,
        AVG(cost_usd) as avg_cost_per_query,
        AVG(cpu_utilization_pct) as avg_cpu_utilization,
        AVG(memory_usage_gb) as avg_memory_usage,
        -- Calculate performance per dollar
        AVG(data_size_gb / NULLIF(execution_time_seconds, 0)) as avg_throughput_gb_per_sec,
        AVG(data_size_gb / NULLIF(cost_usd, 0)) as avg_data_per_dollar_gb
    FROM unified_performance
    GROUP BY 1, 2
),
cross_platform_comparison AS (
    SELECT 
        query_type,
        -- Performance metrics by platform
        MAX(CASE WHEN platform = 'AWS Redshift' THEN avg_execution_time END) as aws_avg_time,
        MAX(CASE WHEN platform = 'Azure Synapse' THEN avg_execution_time END) as azure_avg_time,
        MAX(CASE WHEN platform = 'Google BigQuery' THEN avg_execution_time END) as gcp_avg_time,
        -- Cost metrics by platform
        MAX(CASE WHEN platform = 'AWS Redshift' THEN avg_cost_per_query END) as aws_avg_cost,
        MAX(CASE WHEN platform = 'Azure Synapse' THEN avg_cost_per_query END) as azure_avg_cost,
        MAX(CASE WHEN platform = 'Google BigQuery' THEN avg_cost_per_query END) as gcp_avg_cost,
        -- Throughput metrics by platform
        MAX(CASE WHEN platform = 'AWS Redshift' THEN avg_throughput_gb_per_sec END) as aws_throughput,
        MAX(CASE WHEN platform = 'Azure Synapse' THEN avg_throughput_gb_per_sec END) as azure_throughput,
        MAX(CASE WHEN platform = 'Google BigQuery' THEN avg_throughput_gb_per_sec END) as gcp_throughput,
        -- Value metrics by platform
        MAX(CASE WHEN platform = 'AWS Redshift' THEN avg_data_per_dollar_gb END) as aws_value,
        MAX(CASE WHEN platform = 'Azure Synapse' THEN avg_data_per_dollar_gb END) as azure_value,
        MAX(CASE WHEN platform = 'Google BigQuery' THEN avg_data_per_dollar_gb END) as gcp_value
    FROM performance_benchmarks
    GROUP BY 1
),
platform_rankings AS (
    SELECT 
        query_type,
        -- Performance rankings (lower time = better)
        CASE 
            WHEN COALESCE(aws_avg_time, 999999) <= COALESCE(azure_avg_time, 999999) 
             AND COALESCE(aws_avg_time, 999999) <= COALESCE(gcp_avg_time, 999999)
            THEN 'AWS_FASTEST'
            WHEN COALESCE(azure_avg_time, 999999) <= COALESCE(gcp_avg_time, 999999)
            THEN 'Azure_FASTEST'
            ELSE 'GCP_FASTEST'
        END as performance_leader,
        -- Cost rankings (lower cost = better)
        CASE 
            WHEN COALESCE(aws_avg_cost, 999999) <= COALESCE(azure_avg_cost, 999999) 
             AND COALESCE(aws_avg_cost, 999999) <= COALESCE(gcp_avg_cost, 999999)
            THEN 'AWS_CHEAPEST'
            WHEN COALESCE(azure_avg_cost, 999999) <= COALESCE(gcp_avg_cost, 999999)
            THEN 'Azure_CHEAPEST'
            ELSE 'GCP_CHEAPEST'
        END as cost_leader,
        -- Value rankings (higher value = better)
        CASE 
            WHEN COALESCE(aws_value, 0) >= COALESCE(azure_value, 0) 
             AND COALESCE(aws_value, 0) >= COALESCE(gcp_value, 0)
            THEN 'AWS_BEST_VALUE'
            WHEN COALESCE(azure_value, 0) >= COALESCE(gcp_value, 0)
            THEN 'Azure_BEST_VALUE'
            ELSE 'GCP_BEST_VALUE'
        END as value_leader,
        aws_avg_time,
        azure_avg_time,
        gcp_avg_time,
        aws_avg_cost,
        azure_avg_cost,
        gcp_avg_cost
    FROM cross_platform_comparison
)
SELECT 
    query_type,
    performance_leader,
    cost_leader,
    value_leader,
    ROUND(aws_avg_time, 2) as aws_avg_execution_time,
    ROUND(azure_avg_time, 2) as azure_avg_execution_time,
    ROUND(gcp_avg_time, 2) as gcp_avg_execution_time,
    ROUND(aws_avg_cost, 4) as aws_avg_cost_usd,
    ROUND(azure_avg_cost, 4) as azure_avg_cost_usd,
    ROUND(gcp_avg_cost, 4) as gcp_avg_cost_usd,
    -- Workload placement recommendation
    CASE 
        WHEN performance_leader = cost_leader AND performance_leader = value_leader 
        THEN CONCAT(REPLACE(performance_leader, '_FASTEST', ''), '_OPTIMAL_FOR_ALL_METRICS')
        WHEN performance_leader = cost_leader 
        THEN CONCAT(REPLACE(performance_leader, '_FASTEST', ''), '_OPTIMAL_FOR_PERFORMANCE_AND_COST')
        WHEN cost_leader = value_leader 
        THEN CONCAT(REPLACE(cost_leader, '_CHEAPEST', ''), '_OPTIMAL_FOR_COST_AND_VALUE')
        WHEN query_type LIKE '%ANALYTICS%' 
        THEN CONCAT(REPLACE(performance_leader, '_FASTEST', ''), '_RECOMMENDED_FOR_ANALYTICS')
        WHEN query_type LIKE '%REPORTING%' 
        THEN CONCAT(REPLACE(cost_leader, '_CHEAPEST', ''), '_RECOMMENDED_FOR_REPORTING')
        ELSE 'EVALUATE_BASED_ON_SPECIFIC_REQUIREMENTS'
    END as placement_recommendation
FROM platform_rankings
ORDER BY query_type;

-- =====================================================
-- Best Practices Summary
-- =====================================================

/*
Multi-Cloud Strategy Best Practices:

1. Data Architecture
   - Design cloud-agnostic data models
   - Implement standard APIs and interfaces
   - Use open data formats (Parquet, Delta Lake)
   - Establish data federation patterns

2. Cost Management
   - Implement cross-cloud cost monitoring
   - Use reserved instances strategically
   - Optimize data transfer costs
   - Leverage spot/preemptible instances

3. Governance & Compliance
   - Maintain unified data catalogs
   - Implement consistent security policies
   - Establish cross-cloud audit trails
   - Ensure regulatory compliance

4. Disaster Recovery
   - Design for multi-cloud redundancy
   - Test recovery procedures regularly
   - Automate failover processes
   - Monitor backup integrity

5. Performance Optimization
   - Benchmark workloads across platforms
   - Optimize data placement strategies
   - Implement intelligent workload routing
   - Monitor performance continuously

6. Vendor Management
   - Avoid deep platform lock-in
   - Negotiate favorable terms across vendors
   - Maintain skill diversity across platforms
   - Plan migration strategies
*/
