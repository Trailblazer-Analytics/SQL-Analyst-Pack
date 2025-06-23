-- =====================================================
-- 10. Cloud Security and Governance
-- =====================================================
-- 
-- Master enterprise-grade security patterns, compliance
-- frameworks, and governance strategies for cloud data
-- platforms and multi-tenant analytics environments.
-- 
-- Business Value:
-- • Ensure regulatory compliance and data protection
-- • Implement zero-trust security architectures
-- • Establish comprehensive audit and monitoring
-- • Enable secure data sharing and collaboration
-- 
-- Key Concepts:
-- • Identity and Access Management (IAM)
-- • Data classification and protection
-- • Compliance automation and reporting
-- • Security monitoring and threat detection
-- =====================================================

-- =====================================================
-- Identity and Access Management (IAM)
-- =====================================================

-- Comprehensive user access analysis across cloud platforms
-- Implementing least privilege and role-based access control

WITH user_permissions_aws AS (
    SELECT 
        user_id,
        user_name,
        'AWS' as cloud_platform,
        policy_name,
        resource_arn,
        permission_type,
        access_level, -- READ, WRITE, ADMIN
        last_access_date,
        is_active,
        created_date
    FROM aws_iam.user_policies
    WHERE is_active = true
),
user_permissions_azure AS (
    SELECT 
        user_id,
        user_name,
        'Azure' as cloud_platform,
        role_name as policy_name,
        resource_id as resource_arn,
        permission_type,
        access_level,
        last_access_date,
        is_active,
        created_date
    FROM azure_ad.role_assignments
    WHERE is_active = true
),
user_permissions_gcp AS (
    SELECT 
        user_id,
        user_name,
        'GCP' as cloud_platform,
        role_name as policy_name,
        resource_name as resource_arn,
        permission_type,
        access_level,
        last_access_date,
        is_active,
        created_date
    FROM gcp_iam.member_bindings
    WHERE is_active = true
),
unified_permissions AS (
    SELECT * FROM user_permissions_aws
    UNION ALL
    SELECT * FROM user_permissions_azure
    UNION ALL
    SELECT * FROM user_permissions_gcp
),
access_analysis AS (
    SELECT 
        user_id,
        user_name,
        cloud_platform,
        COUNT(DISTINCT policy_name) as total_policies,
        COUNT(DISTINCT resource_arn) as total_resources,
        COUNT(CASE WHEN access_level = 'ADMIN' THEN 1 END) as admin_permissions,
        COUNT(CASE WHEN access_level = 'WRITE' THEN 1 END) as write_permissions,
        COUNT(CASE WHEN access_level = 'READ' THEN 1 END) as read_permissions,
        MAX(last_access_date) as last_activity,
        MIN(created_date) as first_permission_date,
        -- Calculate days since last access
        DATEDIFF(day, MAX(last_access_date), CURRENT_DATE) as days_since_last_access,
        -- Identify potential issues
        CASE 
            WHEN COUNT(CASE WHEN access_level = 'ADMIN' THEN 1 END) > 5 THEN 'EXCESSIVE_ADMIN_RIGHTS'
            WHEN DATEDIFF(day, MAX(last_access_date), CURRENT_DATE) > 90 THEN 'INACTIVE_USER'
            WHEN COUNT(DISTINCT resource_arn) > 100 THEN 'BROAD_ACCESS_SCOPE'
            ELSE 'NORMAL'
        END as risk_flag
    FROM unified_permissions
    GROUP BY 1, 2, 3
),
privilege_escalation_risk AS (
    SELECT 
        user_id,
        user_name,
        COUNT(DISTINCT cloud_platform) as cross_platform_access,
        SUM(admin_permissions) as total_admin_permissions,
        SUM(total_resources) as total_accessible_resources,
        MAX(days_since_last_access) as max_days_inactive,
        -- Calculate risk score
        CASE 
            WHEN SUM(admin_permissions) >= 10 THEN 40
            WHEN SUM(admin_permissions) >= 5 THEN 30
            WHEN SUM(admin_permissions) >= 1 THEN 20
            ELSE 0
        END +
        CASE 
            WHEN COUNT(DISTINCT cloud_platform) >= 3 THEN 30
            WHEN COUNT(DISTINCT cloud_platform) = 2 THEN 20
            ELSE 0
        END +
        CASE 
            WHEN MAX(days_since_last_access) > 180 THEN 30
            WHEN MAX(days_since_last_access) > 90 THEN 20
            WHEN MAX(days_since_last_access) > 30 THEN 10
            ELSE 0
        END as risk_score
    FROM access_analysis
    GROUP BY 1, 2
),
security_recommendations AS (
    SELECT 
        p.user_id,
        p.user_name,
        p.cross_platform_access,
        p.total_admin_permissions,
        p.total_accessible_resources,
        p.max_days_inactive,
        p.risk_score,
        -- Risk categorization
        CASE 
            WHEN p.risk_score >= 80 THEN 'CRITICAL'
            WHEN p.risk_score >= 60 THEN 'HIGH'
            WHEN p.risk_score >= 40 THEN 'MEDIUM'
            WHEN p.risk_score >= 20 THEN 'LOW'
            ELSE 'MINIMAL'
        END as risk_level,
        -- Specific recommendations
        CASE 
            WHEN p.total_admin_permissions >= 10 THEN 'REVIEW_AND_REDUCE_ADMIN_PRIVILEGES'
            WHEN p.max_days_inactive > 180 THEN 'DISABLE_INACTIVE_ACCOUNT'
            WHEN p.max_days_inactive > 90 THEN 'REVIEW_ACCESS_NECESSITY'
            WHEN p.cross_platform_access >= 3 THEN 'IMPLEMENT_JUST_IN_TIME_ACCESS'
            WHEN p.total_accessible_resources > 100 THEN 'APPLY_PRINCIPLE_OF_LEAST_PRIVILEGE'
            ELSE 'CONTINUE_MONITORING'
        END as recommendation
    FROM privilege_escalation_risk p
)
SELECT 
    user_name,
    cross_platform_access,
    total_admin_permissions,
    total_accessible_resources,
    max_days_inactive,
    risk_score,
    risk_level,
    recommendation
FROM security_recommendations
ORDER BY risk_score DESC, total_admin_permissions DESC;

-- =====================================================
-- Data Classification and Protection
-- =====================================================

-- Automated data sensitivity classification and protection
-- Implementing data loss prevention and encryption policies

WITH sensitive_data_patterns AS (
    SELECT 
        database_name,
        schema_name,
        table_name,
        column_name,
        data_type,
        sample_values,
        -- Pattern matching for PII and sensitive data
        CASE 
            WHEN column_name ILIKE '%ssn%' OR column_name ILIKE '%social%security%' THEN 'SSN'
            WHEN column_name ILIKE '%credit%card%' OR column_name ILIKE '%ccn%' THEN 'CREDIT_CARD'
            WHEN column_name ILIKE '%email%' THEN 'EMAIL'
            WHEN column_name ILIKE '%phone%' OR column_name ILIKE '%mobile%' THEN 'PHONE'
            WHEN column_name ILIKE '%address%' OR column_name ILIKE '%street%' THEN 'ADDRESS'
            WHEN column_name ILIKE '%salary%' OR column_name ILIKE '%wage%' OR column_name ILIKE '%income%' THEN 'FINANCIAL'
            WHEN column_name ILIKE '%birth%date%' OR column_name ILIKE '%dob%' THEN 'BIRTH_DATE'
            WHEN column_name ILIKE '%passport%' OR column_name ILIKE '%license%' THEN 'ID_DOCUMENT'
            ELSE 'GENERAL'
        END as data_classification,
        -- Additional pattern checks in sample data
        CASE 
            WHEN sample_values LIKE '%[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]%' THEN 'POTENTIAL_SSN'
            WHEN sample_values LIKE '%[0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9]%' THEN 'POTENTIAL_CREDIT_CARD'
            WHEN sample_values LIKE '%@%.%' THEN 'POTENTIAL_EMAIL'
            ELSE 'NO_PATTERN_DETECTED'
        END as pattern_detected
    FROM information_schema.columns c
    LEFT JOIN data_profiling.sample_data s ON c.table_name = s.table_name AND c.column_name = s.column_name
    WHERE c.table_schema NOT IN ('information_schema', 'sys', 'metadata')
),
data_sensitivity_scoring AS (
    SELECT 
        database_name,
        schema_name,
        table_name,
        column_name,
        data_classification,
        pattern_detected,
        -- Assign sensitivity scores
        CASE data_classification
            WHEN 'SSN' THEN 100
            WHEN 'CREDIT_CARD' THEN 95
            WHEN 'ID_DOCUMENT' THEN 90
            WHEN 'FINANCIAL' THEN 85
            WHEN 'BIRTH_DATE' THEN 80
            WHEN 'ADDRESS' THEN 70
            WHEN 'PHONE' THEN 65
            WHEN 'EMAIL' THEN 60
            ELSE 20
        END +
        CASE pattern_detected
            WHEN 'POTENTIAL_SSN' THEN 50
            WHEN 'POTENTIAL_CREDIT_CARD' THEN 45
            WHEN 'POTENTIAL_EMAIL' THEN 20
            ELSE 0
        END as sensitivity_score,
        -- Determine required protection level
        CASE 
            WHEN data_classification IN ('SSN', 'CREDIT_CARD', 'ID_DOCUMENT') THEN 'RESTRICTED'
            WHEN data_classification IN ('FINANCIAL', 'BIRTH_DATE') THEN 'CONFIDENTIAL'
            WHEN data_classification IN ('ADDRESS', 'PHONE', 'EMAIL') THEN 'INTERNAL'
            ELSE 'PUBLIC'
        END as protection_level
    FROM sensitive_data_patterns
),
encryption_requirements AS (
    SELECT 
        database_name,
        schema_name,
        table_name,
        COUNT(*) as total_columns,
        COUNT(CASE WHEN protection_level = 'RESTRICTED' THEN 1 END) as restricted_columns,
        COUNT(CASE WHEN protection_level = 'CONFIDENTIAL' THEN 1 END) as confidential_columns,
        COUNT(CASE WHEN protection_level = 'INTERNAL' THEN 1 END) as internal_columns,
        MAX(sensitivity_score) as max_sensitivity_score,
        AVG(sensitivity_score) as avg_sensitivity_score,
        -- Determine table-level classification
        CASE 
            WHEN COUNT(CASE WHEN protection_level = 'RESTRICTED' THEN 1 END) > 0 THEN 'RESTRICTED'
            WHEN COUNT(CASE WHEN protection_level = 'CONFIDENTIAL' THEN 1 END) > 0 THEN 'CONFIDENTIAL'
            WHEN COUNT(CASE WHEN protection_level = 'INTERNAL' THEN 1 END) > 0 THEN 'INTERNAL'
            ELSE 'PUBLIC'
        END as table_classification,
        -- Required security controls
        CASE 
            WHEN COUNT(CASE WHEN protection_level = 'RESTRICTED' THEN 1 END) > 0 
            THEN 'COLUMN_LEVEL_ENCRYPTION,ACCESS_LOGGING,DLP_POLICIES'
            WHEN COUNT(CASE WHEN protection_level = 'CONFIDENTIAL' THEN 1 END) > 0 
            THEN 'TABLE_LEVEL_ENCRYPTION,ACCESS_LOGGING'
            WHEN COUNT(CASE WHEN protection_level = 'INTERNAL' THEN 1 END) > 0 
            THEN 'ACCESS_CONTROLS,AUDIT_LOGGING'
            ELSE 'BASIC_ACCESS_CONTROLS'
        END as required_controls
    FROM data_sensitivity_scoring
    GROUP BY 1, 2, 3
),
compliance_gap_analysis AS (
    SELECT 
        e.*,
        -- Check current encryption status (simulated)
        CASE 
            WHEN RANDOM() < 0.3 THEN 'ENCRYPTED'
            WHEN RANDOM() < 0.6 THEN 'PARTIAL_ENCRYPTION'
            ELSE 'UNENCRYPTED'
        END as current_encryption_status,
        -- Check access logging (simulated)
        CASE 
            WHEN RANDOM() < 0.4 THEN 'ENABLED'
            ELSE 'DISABLED'
        END as access_logging_status,
        -- Check DLP policies (simulated)
        CASE 
            WHEN RANDOM() < 0.2 THEN 'CONFIGURED'
            ELSE 'NOT_CONFIGURED'
        END as dlp_status
    FROM encryption_requirements e
)
SELECT 
    database_name,
    schema_name,
    table_name,
    table_classification,
    restricted_columns,
    confidential_columns,
    max_sensitivity_score,
    current_encryption_status,
    access_logging_status,
    dlp_status,
    required_controls,
    -- Compliance assessment
    CASE 
        WHEN table_classification = 'RESTRICTED' AND current_encryption_status != 'ENCRYPTED' THEN 'NON_COMPLIANT'
        WHEN table_classification = 'RESTRICTED' AND access_logging_status != 'ENABLED' THEN 'NON_COMPLIANT'
        WHEN table_classification = 'RESTRICTED' AND dlp_status != 'CONFIGURED' THEN 'NON_COMPLIANT'
        WHEN table_classification IN ('CONFIDENTIAL', 'INTERNAL') AND current_encryption_status = 'UNENCRYPTED' THEN 'PARTIALLY_COMPLIANT'
        ELSE 'COMPLIANT'
    END as compliance_status,
    -- Priority actions
    CASE 
        WHEN table_classification = 'RESTRICTED' AND current_encryption_status != 'ENCRYPTED' THEN 'IMPLEMENT_COLUMN_ENCRYPTION'
        WHEN table_classification = 'RESTRICTED' AND access_logging_status != 'ENABLED' THEN 'ENABLE_ACCESS_LOGGING'
        WHEN table_classification = 'RESTRICTED' AND dlp_status != 'CONFIGURED' THEN 'CONFIGURE_DLP_POLICIES'
        WHEN table_classification = 'CONFIDENTIAL' AND current_encryption_status = 'UNENCRYPTED' THEN 'IMPLEMENT_TABLE_ENCRYPTION'
        ELSE 'MAINTAIN_CURRENT_CONTROLS'
    END as recommended_action
FROM compliance_gap_analysis
ORDER BY 
    CASE table_classification 
        WHEN 'RESTRICTED' THEN 1 
        WHEN 'CONFIDENTIAL' THEN 2 
        WHEN 'INTERNAL' THEN 3 
        ELSE 4 
    END,
    max_sensitivity_score DESC;

-- =====================================================
-- Compliance Automation and Reporting
-- =====================================================

-- Automated compliance monitoring for GDPR, HIPAA, SOX, and PCI DSS
-- Generate compliance reports and identify violations

WITH compliance_requirements AS (
    SELECT 
        'GDPR' as regulation,
        'Data Subject Rights' as requirement,
        'RIGHT_TO_BE_FORGOTTEN' as control_type,
        'Ability to delete personal data on request' as description
    UNION ALL
    SELECT 'GDPR', 'Data Protection', 'ENCRYPTION_AT_REST', 'Personal data must be encrypted'
    UNION ALL
    SELECT 'GDPR', 'Consent Management', 'CONSENT_TRACKING', 'Track and manage user consent'
    UNION ALL
    SELECT 'HIPAA', 'PHI Protection', 'ACCESS_CONTROLS', 'Protected Health Information access controls'
    UNION ALL
    SELECT 'HIPAA', 'Audit Logging', 'AUDIT_TRAILS', 'Comprehensive audit trails for PHI access'
    UNION ALL
    SELECT 'SOX', 'Financial Data', 'SEGREGATION_OF_DUTIES', 'Separate financial data access'
    UNION ALL
    SELECT 'SOX', 'Change Management', 'CHANGE_APPROVAL', 'Approved changes to financial systems'
    UNION ALL
    SELECT 'PCI_DSS', 'Cardholder Data', 'SECURE_STORAGE', 'Secure storage of payment card data'
    UNION ALL
    SELECT 'PCI_DSS', 'Network Security', 'NETWORK_SEGMENTATION', 'Isolate cardholder data environment'
),
data_inventory AS (
    SELECT 
        database_name,
        table_name,
        column_name,
        -- Identify regulated data types
        CASE 
            WHEN column_name ILIKE '%email%' OR column_name ILIKE '%name%' OR column_name ILIKE '%address%' THEN 'PII_GDPR'
            WHEN column_name ILIKE '%health%' OR column_name ILIKE '%medical%' OR column_name ILIKE '%diagnosis%' THEN 'PHI_HIPAA'
            WHEN column_name ILIKE '%revenue%' OR column_name ILIKE '%financial%' OR column_name ILIKE '%accounting%' THEN 'FINANCIAL_SOX'
            WHEN column_name ILIKE '%card%' OR column_name ILIKE '%payment%' OR column_name ILIKE '%ccn%' THEN 'PAYMENT_PCI'
            ELSE 'GENERAL'
        END as data_type,
        current_encryption_status,
        access_logging_enabled,
        retention_period_days,
        last_accessed_date
    FROM data_catalog
    WHERE data_type != 'GENERAL'
),
control_implementation AS (
    SELECT 
        regulation,
        control_type,
        COUNT(CASE WHEN data_type LIKE CONCAT('%', regulation) THEN 1 END) as applicable_tables,
        -- Simulate control implementation status
        COUNT(CASE 
            WHEN control_type = 'ENCRYPTION_AT_REST' AND current_encryption_status = 'ENCRYPTED' THEN 1
            WHEN control_type = 'AUDIT_TRAILS' AND access_logging_enabled = true THEN 1
            WHEN control_type = 'ACCESS_CONTROLS' AND access_logging_enabled = true THEN 1
            -- Add more control checks as needed
        END) as implemented_controls,
        -- Calculate compliance percentage
        CASE 
            WHEN COUNT(CASE WHEN data_type LIKE CONCAT('%', regulation) THEN 1 END) > 0
            THEN ROUND(
                COUNT(CASE 
                    WHEN control_type = 'ENCRYPTION_AT_REST' AND current_encryption_status = 'ENCRYPTED' THEN 1
                    WHEN control_type = 'AUDIT_TRAILS' AND access_logging_enabled = true THEN 1
                    WHEN control_type = 'ACCESS_CONTROLS' AND access_logging_enabled = true THEN 1
                END) * 100.0 / 
                COUNT(CASE WHEN data_type LIKE CONCAT('%', regulation) THEN 1 END), 2
            )
            ELSE 100
        END as compliance_percentage
    FROM compliance_requirements r
    CROSS JOIN data_inventory d
    GROUP BY 1, 2
),
compliance_violations AS (
    SELECT 
        'GDPR' as regulation,
        'Data Retention Violation' as violation_type,
        database_name + '.' + table_name as resource,
        'Data retained beyond specified period' as description,
        'HIGH' as severity
    FROM data_inventory
    WHERE data_type = 'PII_GDPR' 
      AND retention_period_days > 2555 -- 7 years max for GDPR
    
    UNION ALL
    
    SELECT 
        'HIPAA' as regulation,
        'Unencrypted PHI' as violation_type,
        database_name + '.' + table_name as resource,
        'Protected Health Information not encrypted' as description,
        'CRITICAL' as severity
    FROM data_inventory
    WHERE data_type = 'PHI_HIPAA' 
      AND current_encryption_status != 'ENCRYPTED'
    
    UNION ALL
    
    SELECT 
        'PCI_DSS' as regulation,
        'Unprotected Cardholder Data' as violation_type,
        database_name + '.' + table_name as resource,
        'Payment card data not properly secured' as description,
        'CRITICAL' as severity
    FROM data_inventory
    WHERE data_type = 'PAYMENT_PCI' 
      AND current_encryption_status != 'ENCRYPTED'
),
compliance_dashboard AS (
    SELECT 
        r.regulation,
        r.requirement,
        ci.applicable_tables,
        ci.implemented_controls,
        ci.compliance_percentage,
        COUNT(cv.violation_type) as active_violations,
        COUNT(CASE WHEN cv.severity = 'CRITICAL' THEN 1 END) as critical_violations,
        COUNT(CASE WHEN cv.severity = 'HIGH' THEN 1 END) as high_violations,
        -- Overall compliance status
        CASE 
            WHEN COUNT(CASE WHEN cv.severity = 'CRITICAL' THEN 1 END) > 0 THEN 'NON_COMPLIANT'
            WHEN ci.compliance_percentage < 80 THEN 'PARTIALLY_COMPLIANT'
            WHEN ci.compliance_percentage < 95 THEN 'MOSTLY_COMPLIANT'
            ELSE 'COMPLIANT'
        END as compliance_status
    FROM compliance_requirements r
    LEFT JOIN control_implementation ci ON r.regulation = ci.regulation AND r.control_type = ci.control_type
    LEFT JOIN compliance_violations cv ON r.regulation = cv.regulation
    GROUP BY 1, 2, 3, 4, 5
)
SELECT 
    regulation,
    requirement,
    applicable_tables,
    implemented_controls,
    compliance_percentage,
    active_violations,
    critical_violations,
    high_violations,
    compliance_status,
    -- Remediation priority
    CASE 
        WHEN critical_violations > 0 THEN 'IMMEDIATE_ACTION_REQUIRED'
        WHEN high_violations > 0 THEN 'URGENT_ATTENTION_NEEDED'
        WHEN compliance_percentage < 80 THEN 'IMPROVEMENT_NEEDED'
        ELSE 'MAINTAIN_CURRENT_STATE'
    END as remediation_priority
FROM compliance_dashboard
ORDER BY 
    CASE compliance_status 
        WHEN 'NON_COMPLIANT' THEN 1 
        WHEN 'PARTIALLY_COMPLIANT' THEN 2 
        WHEN 'MOSTLY_COMPLIANT' THEN 3 
        ELSE 4 
    END,
    critical_violations DESC,
    high_violations DESC;

-- =====================================================
-- Security Monitoring and Threat Detection
-- =====================================================

-- Real-time security monitoring and anomaly detection
-- Identify potential data breaches and unauthorized access

WITH user_activity_baseline AS (
    SELECT 
        user_id,
        user_name,
        AVG(daily_queries) as avg_daily_queries,
        AVG(data_accessed_gb) as avg_data_accessed_gb,
        AVG(session_duration_minutes) as avg_session_duration,
        STDDEV(daily_queries) as stddev_queries,
        STDDEV(data_accessed_gb) as stddev_data_accessed,
        COUNT(DISTINCT access_date) as total_active_days
    FROM user_activity_log
    WHERE access_date >= CURRENT_DATE - 30
    GROUP BY 1, 2
),
current_activity AS (
    SELECT 
        user_id,
        user_name,
        access_date,
        daily_queries,
        data_accessed_gb,
        session_duration_minutes,
        access_time,
        ip_address,
        location_country,
        device_type,
        query_types,
        tables_accessed
    FROM user_activity_log
    WHERE access_date >= CURRENT_DATE - 1
),
anomaly_detection AS (
    SELECT 
        ca.user_id,
        ca.user_name,
        ca.access_date,
        ca.daily_queries,
        ca.data_accessed_gb,
        ca.session_duration_minutes,
        ca.ip_address,
        ca.location_country,
        ca.device_type,
        ub.avg_daily_queries,
        ub.avg_data_accessed_gb,
        ub.avg_session_duration,
        -- Calculate anomaly scores
        CASE 
            WHEN ub.stddev_queries > 0 
            THEN ABS(ca.daily_queries - ub.avg_daily_queries) / ub.stddev_queries 
            ELSE 0 
        END as query_anomaly_score,
        CASE 
            WHEN ub.stddev_data_accessed > 0 
            THEN ABS(ca.data_accessed_gb - ub.avg_data_accessed_gb) / ub.stddev_data_accessed 
            ELSE 0 
        END as data_access_anomaly_score,
        -- Time-based anomalies
        CASE 
            WHEN EXTRACT(HOUR FROM ca.access_time) BETWEEN 22 AND 6 THEN 2
            WHEN EXTRACT(HOUR FROM ca.access_time) BETWEEN 18 AND 22 THEN 1
            ELSE 0
        END as time_anomaly_score,
        -- Location-based anomalies (simplified)
        CASE 
            WHEN ca.location_country != 'US' THEN 3
            ELSE 0
        END as location_anomaly_score
    FROM current_activity ca
    LEFT JOIN user_activity_baseline ub ON ca.user_id = ub.user_id
),
threat_assessment AS (
    SELECT 
        user_id,
        user_name,
        access_date,
        daily_queries,
        data_accessed_gb,
        ip_address,
        location_country,
        device_type,
        query_anomaly_score,
        data_access_anomaly_score,
        time_anomaly_score,
        location_anomaly_score,
        -- Calculate total risk score
        query_anomaly_score * 10 + 
        data_access_anomaly_score * 15 + 
        time_anomaly_score * 5 + 
        location_anomaly_score * 8 as total_risk_score,
        -- Identify specific threat indicators
        CASE 
            WHEN query_anomaly_score > 3 THEN 'UNUSUAL_QUERY_VOLUME'
            WHEN data_access_anomaly_score > 3 THEN 'UNUSUAL_DATA_ACCESS'
            WHEN time_anomaly_score >= 2 THEN 'OFF_HOURS_ACCESS'
            WHEN location_anomaly_score >= 3 THEN 'FOREIGN_ACCESS'
            ELSE 'NORMAL_ACTIVITY'
        END as primary_threat_indicator
    FROM anomaly_detection
),
security_alerts AS (
    SELECT 
        user_id,
        user_name,
        access_date,
        total_risk_score,
        primary_threat_indicator,
        daily_queries,
        data_accessed_gb,
        ip_address,
        location_country,
        -- Risk categorization
        CASE 
            WHEN total_risk_score >= 50 THEN 'CRITICAL'
            WHEN total_risk_score >= 30 THEN 'HIGH'
            WHEN total_risk_score >= 15 THEN 'MEDIUM'
            WHEN total_risk_score >= 5 THEN 'LOW'
            ELSE 'MINIMAL'
        END as risk_level,
        -- Recommended actions
        CASE 
            WHEN total_risk_score >= 50 THEN 'IMMEDIATE_ACCOUNT_SUSPENSION'
            WHEN total_risk_score >= 30 THEN 'MANDATORY_MFA_VERIFICATION'
            WHEN total_risk_score >= 15 THEN 'ENHANCED_MONITORING'
            WHEN total_risk_score >= 5 THEN 'NOTIFY_SECURITY_TEAM'
            ELSE 'CONTINUE_MONITORING'
        END as recommended_action,
        -- Additional context
        CASE 
            WHEN primary_threat_indicator = 'UNUSUAL_DATA_ACCESS' AND data_accessed_gb > 100 THEN 'POTENTIAL_DATA_EXFILTRATION'
            WHEN primary_threat_indicator = 'FOREIGN_ACCESS' THEN 'POTENTIAL_UNAUTHORIZED_ACCESS'
            WHEN primary_threat_indicator = 'OFF_HOURS_ACCESS' AND daily_queries > 100 THEN 'POTENTIAL_AUTOMATED_ATTACK'
            ELSE 'REQUIRES_INVESTIGATION'
        END as threat_context
    FROM threat_assessment
    WHERE total_risk_score > 0
)
SELECT 
    user_name,
    access_date,
    risk_level,
    total_risk_score,
    primary_threat_indicator,
    threat_context,
    recommended_action,
    daily_queries,
    data_accessed_gb,
    ip_address,
    location_country
FROM security_alerts
ORDER BY total_risk_score DESC, access_date DESC;

-- =====================================================
-- Data Lineage and Impact Analysis
-- =====================================================

-- Track data flow and assess impact of security incidents
-- Essential for breach notification and remediation

WITH data_lineage AS (
    SELECT 
        source_table,
        target_table,
        transformation_type,
        pipeline_name,
        last_run_timestamp,
        data_volume_processed,
        contains_pii,
        contains_phi,
        contains_financial_data
    FROM etl_lineage_log
    WHERE last_run_timestamp >= CURRENT_DATE - 7
),
security_incident AS (
    -- Simulated security incident
    SELECT 
        'customer_raw_data.personal_info' as compromised_table,
        '2024-01-15 14:30:00' as incident_timestamp,
        'Unauthorized access detected' as incident_description,
        'HIGH' as severity_level
),
impact_propagation AS (
    WITH RECURSIVE lineage_trace AS (
        -- Base case: directly compromised table
        SELECT 
            si.compromised_table as table_name,
            0 as propagation_level,
            si.incident_timestamp,
            'DIRECTLY_COMPROMISED' as impact_type
        FROM security_incident si
        
        UNION ALL
        
        -- Recursive case: downstream tables
        SELECT 
            dl.target_table as table_name,
            lt.propagation_level + 1,
            si.incident_timestamp,
            CASE 
                WHEN lt.propagation_level = 0 THEN 'IMMEDIATELY_IMPACTED'
                WHEN lt.propagation_level <= 2 THEN 'POTENTIALLY_IMPACTED'
                ELSE 'INDIRECTLY_IMPACTED'
            END as impact_type
        FROM lineage_trace lt
        JOIN data_lineage dl ON lt.table_name = dl.source_table
        JOIN security_incident si ON si.compromised_table = lt.table_name OR lt.propagation_level > 0
        WHERE lt.propagation_level < 5 -- Limit recursion depth
    )
    SELECT DISTINCT * FROM lineage_trace
),
breach_notification_requirements AS (
    SELECT 
        ip.table_name,
        ip.propagation_level,
        ip.impact_type,
        dl.contains_pii,
        dl.contains_phi,
        dl.contains_financial_data,
        -- Determine notification requirements
        CASE 
            WHEN dl.contains_phi = true THEN 'HIPAA_BREACH_NOTIFICATION_REQUIRED'
            WHEN dl.contains_pii = true THEN 'GDPR_BREACH_NOTIFICATION_REQUIRED'
            WHEN dl.contains_financial_data = true THEN 'SOX_INCIDENT_REPORTING_REQUIRED'
            ELSE 'INTERNAL_NOTIFICATION_ONLY'
        END as notification_requirement,
        -- Calculate notification timeline
        CASE 
            WHEN dl.contains_phi = true THEN '60_HOURS'
            WHEN dl.contains_pii = true THEN '72_HOURS'
            WHEN dl.contains_financial_data = true THEN '24_HOURS'
            ELSE 'NO_DEADLINE'
        END as notification_deadline,
        -- Estimate affected records (simplified)
        CASE 
            WHEN ip.impact_type = 'DIRECTLY_COMPROMISED' THEN 1000000
            WHEN ip.impact_type = 'IMMEDIATELY_IMPACTED' THEN 750000
            WHEN ip.impact_type = 'POTENTIALLY_IMPACTED' THEN 500000
            ELSE 100000
        END as estimated_affected_records
    FROM impact_propagation ip
    LEFT JOIN data_lineage dl ON ip.table_name = dl.target_table
)
SELECT 
    table_name,
    propagation_level,
    impact_type,
    notification_requirement,
    notification_deadline,
    estimated_affected_records,
    contains_pii,
    contains_phi,
    contains_financial_data,
    -- Priority for remediation
    CASE 
        WHEN contains_phi = true AND impact_type = 'DIRECTLY_COMPROMISED' THEN 'CRITICAL_PRIORITY'
        WHEN contains_pii = true AND impact_type IN ('DIRECTLY_COMPROMISED', 'IMMEDIATELY_IMPACTED') THEN 'HIGH_PRIORITY'
        WHEN contains_financial_data = true THEN 'MEDIUM_PRIORITY'
        ELSE 'LOW_PRIORITY'
    END as remediation_priority
FROM breach_notification_requirements
ORDER BY 
    CASE impact_type 
        WHEN 'DIRECTLY_COMPROMISED' THEN 1
        WHEN 'IMMEDIATELY_IMPACTED' THEN 2
        WHEN 'POTENTIALLY_IMPACTED' THEN 3
        ELSE 4
    END,
    estimated_affected_records DESC;

-- =====================================================
-- Best Practices Summary
-- =====================================================

/*
Cloud Security and Governance Best Practices:

1. Identity and Access Management
   - Implement zero-trust architecture
   - Use multi-factor authentication
   - Apply principle of least privilege
   - Regular access reviews and certifications
   - Just-in-time access for administrative tasks

2. Data Protection
   - Classify data by sensitivity level
   - Implement encryption at rest and in transit
   - Use tokenization for sensitive data
   - Deploy data loss prevention (DLP) tools
   - Maintain data inventory and lineage

3. Compliance Automation
   - Automate compliance monitoring
   - Generate regular compliance reports
   - Implement policy-as-code frameworks
   - Maintain audit trails and evidence
   - Regular compliance assessments

4. Threat Detection and Response
   - Deploy security information and event management (SIEM)
   - Implement user and entity behavior analytics (UEBA)
   - Use machine learning for anomaly detection
   - Maintain incident response procedures
   - Regular security training and awareness

5. Governance Framework
   - Establish data governance committees
   - Define clear roles and responsibilities
   - Implement change management processes
   - Regular policy reviews and updates
   - Vendor risk management programs

6. Monitoring and Alerting
   - Real-time security monitoring
   - Automated alert generation
   - Integration with security orchestration tools
   - Regular penetration testing
   - Continuous security assessments
*/
