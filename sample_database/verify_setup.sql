-- =====================================================
-- SQL Analyst Pack - Database Verification Script
-- =====================================================
-- Run this after setup to verify everything is working correctly

\echo '🔍 SQL Analyst Pack - Database Verification'
\echo '=========================================='
\echo ''

-- Check if we're connected to the right database
SELECT 
    current_database() as database_name,
    current_user as connected_user,
    version() as postgres_version;

\echo ''
\echo '📊 Table Verification:'
\echo '---------------------'

-- Verify all tables exist and have data
WITH table_stats AS (
    SELECT 
        schemaname,
        tablename,
        n_tup_ins as inserts,
        n_tup_upd as updates,
        n_tup_del as deletes,
        n_live_tup as live_rows
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
)
SELECT 
    CASE 
        WHEN tablename LIKE '%ecommerce%' THEN '🛒 E-commerce'
        WHEN tablename LIKE '%financial%' THEN '💰 Financial' 
        WHEN tablename LIKE '%iot%' THEN '🌡️ IoT'
        WHEN tablename IN ('Customer', 'Invoice', 'Track', 'Artist', 'Album') THEN '🎵 Chinook'
        ELSE '📋 Other'
    END as category,
    tablename as table_name,
    live_rows as record_count
FROM table_stats
ORDER BY category, tablename;

\echo ''
\echo '🔗 Relationship Verification:'
\echo '----------------------------'

-- Check foreign key relationships
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

\echo ''
\echo '📈 Sample Data Preview:'
\echo '----------------------'

-- Show sample records from each major table
\echo 'Chinook Sample (Music Store):'
SELECT 'Customer' as table_type, FirstName, LastName, Country FROM Customer LIMIT 3;

\echo ''
\echo 'E-commerce Sample:'
SELECT 'User' as table_type, user_id, signup_date, country, device_type FROM ecommerce_users LIMIT 3;

\echo ''
\echo 'Financial Sample:'
SELECT 'Customer' as table_type, customer_id, age, income_level, country FROM financial_customers LIMIT 3;

\echo ''
\echo 'IoT Sample:'
SELECT 'Device' as table_type, device_id, device_name, device_type, location FROM iot_devices LIMIT 3;

\echo ''
\echo '⚡ Index Verification:'
\echo '--------------------'

-- Check if performance indexes are created
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND indexname NOT LIKE '%pkey'
ORDER BY tablename, indexname;

\echo ''
\echo '👁️ View Verification:'
\echo '-------------------'

-- Check if analysis views exist
SELECT 
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
ORDER BY viewname;

\echo ''
\echo '🎯 Quick Analysis Tests:'
\echo '----------------------'

-- Test basic aggregation capabilities
\echo 'Testing aggregation functions:'
SELECT 
    COUNT(*) as total_customers,
    COUNT(DISTINCT Country) as unique_countries,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM BirthDate)) as avg_employee_age
FROM Customer c
LEFT JOIN Employee e ON c.SupportRepId = e.EmployeeId;

-- Test window functions
\echo ''
\echo 'Testing window functions:'
SELECT 
    CustomerId,
    Total,
    ROW_NUMBER() OVER (ORDER BY Total DESC) as invoice_rank,
    ROUND(AVG(Total) OVER (), 2) as overall_avg
FROM Invoice 
LIMIT 5;

-- Test date functions
\echo ''
\echo 'Testing date/time functions:'
SELECT 
    DATE_TRUNC('month', InvoiceDate) as invoice_month,
    COUNT(*) as invoice_count,
    SUM(Total) as monthly_revenue
FROM Invoice
GROUP BY DATE_TRUNC('month', InvoiceDate)
ORDER BY invoice_month DESC
LIMIT 3;

\echo ''
\echo '✅ Database Verification Complete!'
\echo ''
\echo 'Next Steps:'
\echo '1. ✅ Database is properly set up and functional'
\echo '2. 📚 Start learning with: 01_foundations/'
\echo '3. 🧪 Try the sample queries in each module'
\echo '4. 🎯 Work through the exercises systematically'
\echo ''
\echo 'Happy SQL Learning! 🚀'
