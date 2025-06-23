/*
    File: 01_table_overview_and_counts.sql
    Module: 02_data_profiling
    Topic: Table Overview and Row Counts
    Author: SQL Analyst Pack
    Date: 2025-06-22
    Description: Learn to quickly assess database structure and data volume through systematic table profiling
    
    Business Scenarios:
    - New database handover and reconnaissance  
    - Data migration planning and assessment
    - Regular data volume monitoring and reporting
    - Database health checks and capacity planning
    
    Database: Chinook (Music Store Digital Media)
    Complexity: Beginner
    Estimated Time: 30-45 minutes
*/

-- =================================================================================================================================
-- 🎯 LEARNING OBJECTIVES
-- =================================================================================================================================
--
-- After completing this script, you will be able to:
-- ✅ Quickly assess the size and structure of any database
-- ✅ Generate comprehensive table inventory reports  
-- ✅ Identify the largest tables for optimization planning
-- ✅ Create automated database monitoring queries
-- ✅ Understand metadata retrieval techniques across different SQL platforms
--
-- =================================================================================================================================
-- 💼 BUSINESS SCENARIO: New Database Handover
-- =================================================================================================================================
--
-- You're a new data analyst at Chinook Digital Music, a company that sells music tracks online.
-- The previous analyst has left, and you need to quickly understand the database structure and
-- data volumes to prepare for your first stakeholder meeting. Management wants answers to:
--
-- 1. "How much data do we have in our systems?"
-- 2. "Which are our largest tables that might need performance attention?"  
-- 3. "What's the overall structure of our database?"
-- 4. "Are there any empty or unused tables we should know about?"
--
-- =================================================================================================================================
-- 📊 PART 1: QUICK DATABASE RECONNAISSANCE
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Get a High-Level Database Overview
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's start with the most basic question: "What tables do we have and how much data is in each?"
-- This is often the first query any analyst runs on a new database.

-- ANSI SQL approach using INFORMATION_SCHEMA (works on PostgreSQL, SQL Server, MySQL)
SELECT 
    table_schema,
    table_name,
    table_type,
    -- Note: INFORMATION_SCHEMA doesn't provide row counts, we'll add those next
    CASE 
        WHEN table_type = 'BASE TABLE' THEN 'Data Table'
        WHEN table_type = 'VIEW' THEN 'View'
        ELSE table_type
    END AS table_category
FROM information_schema.tables
WHERE table_schema NOT IN ('information_schema', 'pg_catalog', 'sys')  -- Exclude system schemas
    AND table_type = 'BASE TABLE'  -- Focus on actual data tables
ORDER BY table_schema, table_name;

-- 💡 Business Insight: This gives you the "table of contents" for your database
-- 💡 Pro Tip: Always exclude system schemas to focus on business data
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- PostgreSQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the 'public' schema.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQL Server
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the current database.
SELECT name AS table_name
FROM sys.objects
WHERE type = 'U'; -- 'U' stands for User Table

-- Or using INFORMATION_SCHEMA
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = 'Chinook'; -- Replace 'Chinook' with your DB name

-- ---------------------------------------------------------------------------------------------------------------------------------
-- MySQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the currently connected database.
SHOW TABLES;

-- Or using INFORMATION_SCHEMA
SELECT table_name
FROM information_schema.tables
WHERE table_schema = DATABASE(); -- DATABASE() returns the current database name

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQLite
-- ---------------------------------------------------------------------------------------------------------------------------------
-- List all tables in the database.
SELECT name
FROM sqlite_master
WHERE type = 'table' AND name NOT LIKE 'sqlite_%'; -- Excludes internal SQLite tables

-- =================================================================================================================================
-- Getting Row Counts for Tables
-- =================================================================================================================================
--
-- Counting rows is essential for understanding the size of your tables. While `SELECT COUNT(*)` is straightforward
-- for a single table, it can be tedious to run for every table. Many databases provide metadata or shortcuts
-- to get approximate or exact row counts more efficiently.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Get Row Count for a Single Table (Universal)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- This works in all SQL flavors.
SELECT COUNT(*) AS row_count
FROM "artists"; -- Using quotes for case-sensitivity if needed

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Get Row Counts for All Tables (Flavor-Specific)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Getting counts for all tables at once often requires a more advanced or flavor-specific approach.

-- PostgreSQL (using table metadata for approximate counts - very fast)
-- The `reltuples` column in `pg_class` stores an estimated row count.
SELECT
    c.relname AS table_name,
    c.reltuples AS approximate_row_count
FROM
    pg_class c
JOIN
    pg_namespace n ON c.relnamespace = n.oid
WHERE
    n.nspname = 'public' AND c.relkind = 'r' -- 'r' for regular table
ORDER BY
    c.relname;

-- SQL Server (using system views for exact counts)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.rows AS row_count
FROM
    sys.tables t
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN
    sys.partitions p ON t.object_id = p.object_id
WHERE
    p.index_id IN (0, 1) -- 0 for heap, 1 for clustered index
ORDER BY
    s.name, t.name;

-- MySQL (using INFORMATION_SCHEMA - can be slow on large databases)
-- The `TABLE_ROWS` column provides an estimated count for InnoDB tables.
SELECT
    table_name,
    table_rows AS approximate_row_count
FROM
    information_schema.tables
WHERE
    table_schema = DATABASE()
ORDER BY
    table_name;

-- Note on Dynamic SQL: For some databases, creating a script that iterates through table names
-- and executes `SELECT COUNT(*)` for each is a common pattern, especially if exact counts are required
-- and system tables are not preferred. This typically involves procedural code (e.g., PL/pgSQL, T-SQL).

-- =================================================================================================================================
-- Practical Exercise: Profile the Chinook Database
-- =================================================================================================================================

-- 1. List all tables in the Chinook database using the method for your SQL flavor.
--    (Example for SQLite)
SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';

-- 2. Get the row count for the 'invoices', 'customers', and 'tracks' tables.
SELECT 'invoices' AS table_name, COUNT(*) AS row_count FROM "invoices"
UNION ALL
SELECT 'customers', COUNT(*) FROM "customers"
UNION ALL
SELECT 'tracks', COUNT(*) FROM "tracks";

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Count Rows in Chinook Tables - Manual Approach
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Now let's get the actual data volumes. In the Chinook database, let's count rows in key business tables.
-- This manual approach helps you understand the relative importance of different tables.

-- Customer data - How many customers do we serve?
SELECT 'Customer' AS table_name, COUNT(*) AS row_count, 'Customer base size' AS business_meaning
FROM Customer

UNION ALL

-- Employee data - How many staff members?  
SELECT 'Employee' AS table_name, COUNT(*) AS row_count, 'Workforce size' AS business_meaning
FROM Employee

UNION ALL

-- Invoice data - How many orders/transactions?
SELECT 'Invoice' AS table_name, COUNT(*) AS row_count, 'Total transactions' AS business_meaning  
FROM Invoice

UNION ALL

-- Invoice line items - How many line items across all orders?
SELECT 'InvoiceLine' AS table_name, COUNT(*) AS row_count, 'Individual item sales' AS business_meaning
FROM InvoiceLine

UNION ALL

-- Track data - How large is our music catalog?
SELECT 'Track' AS table_name, COUNT(*) AS row_count, 'Music catalog size' AS business_meaning
FROM Track

UNION ALL

-- Album data - How many albums do we offer?
SELECT 'Album' AS table_name, COUNT(*) AS row_count, 'Album collection size' AS business_meaning
FROM Album

UNION ALL

-- Artist data - How many artists in our catalog?
SELECT 'Artist' AS table_name, COUNT(*) AS row_count, 'Artist roster size' AS business_meaning
FROM Artist

ORDER BY row_count DESC;

-- 💡 Business Insight: The largest tables (usually InvoiceLine, Track) are your "hot" tables
-- 💡 Performance Tip: These high-volume tables often need indexing and optimization attention

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Quick Table Size Summary with Business Context
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's create a more comprehensive summary that tells a business story

WITH table_sizes AS (
    SELECT 'Customer' AS table_name, COUNT(*) AS row_count, 'Primary' AS data_category FROM Customer
    UNION ALL
    SELECT 'Employee', COUNT(*), 'Primary' FROM Employee  
    UNION ALL
    SELECT 'Invoice', COUNT(*), 'Transaction' FROM Invoice
    UNION ALL
    SELECT 'InvoiceLine', COUNT(*), 'Transaction' FROM InvoiceLine
    UNION ALL
    SELECT 'Track', COUNT(*), 'Product' FROM Track
    UNION ALL
    SELECT 'Album', COUNT(*), 'Product' FROM Album
    UNION ALL
    SELECT 'Artist', COUNT(*), 'Product' FROM Artist
    UNION ALL
    SELECT 'Genre', COUNT(*), 'Reference' FROM Genre
    UNION ALL
    SELECT 'MediaType', COUNT(*), 'Reference' FROM MediaType
    UNION ALL
    SELECT 'Playlist', COUNT(*), 'Reference' FROM Playlist
    UNION ALL
    SELECT 'PlaylistTrack', COUNT(*), 'Reference' FROM PlaylistTrack
)
SELECT 
    data_category,
    table_name,
    row_count,
    -- Calculate percentage of total rows
    ROUND(row_count * 100.0 / SUM(row_count) OVER(), 2) AS percent_of_total,
    -- Add business context
    CASE 
        WHEN row_count = 0 THEN '⚠️ Empty - Investigate'
        WHEN row_count < 100 THEN '📋 Reference Data'
        WHEN row_count < 1000 THEN '👥 Core Business Data'
        ELSE '🔥 High Volume - Monitor Performance'
    END AS assessment
FROM table_sizes
ORDER BY data_category, row_count DESC;

-- 💡 Business Insight: This shows data distribution and highlights tables needing attention
-- 💡 Monitoring Tip: Tables with 0 rows might indicate data pipeline issues

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Database Growth Estimation
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Understanding current volumes helps estimate growth and storage needs

SELECT 
    'Total Rows Across All Tables' AS metric,
    (SELECT COUNT(*) FROM Customer) +
    (SELECT COUNT(*) FROM Employee) +
    (SELECT COUNT(*) FROM Invoice) +
    (SELECT COUNT(*) FROM InvoiceLine) +
    (SELECT COUNT(*) FROM Track) +
    (SELECT COUNT(*) FROM Album) +
    (SELECT COUNT(*) FROM Artist) +
    (SELECT COUNT(*) FROM Genre) +
    (SELECT COUNT(*) FROM MediaType) +
    (SELECT COUNT(*) FROM Playlist) +
    (SELECT COUNT(*) FROM PlaylistTrack) AS total_value

UNION ALL

SELECT 
    'Transaction Tables (Invoice + InvoiceLine)',
    (SELECT COUNT(*) FROM Invoice) + (SELECT COUNT(*) FROM InvoiceLine)

UNION ALL

SELECT 
    'Product Catalog (Track + Album + Artist)',
    (SELECT COUNT(*) FROM Track) + (SELECT COUNT(*) FROM Album) + (SELECT COUNT(*) FROM Artist)

UNION ALL

SELECT 
    'Customer-Facing Tables (Customer + Playlist)',
    (SELECT COUNT(*) FROM Customer) + (SELECT COUNT(*) FROM Playlist);

-- 💡 Business Application: Use this for capacity planning and growth projections
-- 💡 Architecture Tip: High transaction volumes may need different storage strategies

-- =================================================================================================================================
-- 📈 PART 2: PLATFORM-SPECIFIC APPROACHES
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- PostgreSQL-Specific: Using System Catalogs for More Detailed Information
-- ---------------------------------------------------------------------------------------------------------------------------------
-- PostgreSQL provides additional metadata through system catalogs

-- Uncomment if using PostgreSQL:
/*
SELECT 
    schemaname,
    tablename,
    -- PostgreSQL provides estimated row counts
    n_tup_ins AS inserts_total,
    n_tup_upd AS updates_total,
    n_tup_del AS deletes_total,
    n_live_tup AS estimated_rows,
    last_vacuum,
    last_analyze
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
*/

-- 💡 PostgreSQL Advantage: Built-in statistics for performance monitoring

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQL Server-Specific: Using sys.dm_db_partition_stats
-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQL Server provides detailed partition statistics

-- Uncomment if using SQL Server:
/*
SELECT 
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS table_name,
    SUM(p.rows) AS row_count,
    SUM(a.total_pages) * 8 / 1024 AS total_space_mb,
    SUM(a.used_pages) * 8 / 1024 AS used_space_mb
FROM sys.dm_db_partition_stats p
JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE p.object_id > 100  -- Exclude system tables
    AND p.index_id IN (0, 1)  -- Clustered index or heap
GROUP BY p.object_id
ORDER BY row_count DESC;
*/

-- 💡 SQL Server Advantage: Includes storage information alongside row counts

-- =================================================================================================================================
-- 🎯 PART 3: AUTOMATED TABLE PROFILING APPROACH
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 5: Automated Table Discovery and Profiling
-- ---------------------------------------------------------------------------------------------------------------------------------
-- This approach works when you need to profile unknown databases quickly

-- First, let's identify all user tables (this works across most platforms)
SELECT 
    table_name,
    CASE 
        WHEN table_name LIKE '%Customer%' OR table_name LIKE '%User%' THEN 'Customer Data'
        WHEN table_name LIKE '%Invoice%' OR table_name LIKE '%Order%' OR table_name LIKE '%Transaction%' THEN 'Transaction Data'
        WHEN table_name LIKE '%Product%' OR table_name LIKE '%Track%' OR table_name LIKE '%Album%' THEN 'Product Data'
        WHEN table_name LIKE '%Employee%' OR table_name LIKE '%Staff%' THEN 'Employee Data'
        ELSE 'Other'
    END AS data_category,
    'SELECT ''' + table_name + ''' AS table_name, COUNT(*) AS row_count FROM ' + table_name AS count_query
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
    AND table_schema NOT IN ('information_schema', 'pg_catalog', 'sys', 'mysql', 'performance_schema')
ORDER BY data_category, table_name;

-- 💡 Pro Tip: Copy the count_query column results and execute them to get row counts
-- 💡 Automation: This approach can be used to generate dynamic SQL for any database

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 6: Table Profiling Template for Regular Monitoring
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Create a reusable template for ongoing database monitoring

-- Template: Database Health Check Report
SELECT 
    '=== CHINOOK DATABASE HEALTH CHECK ===' AS report_section,
    CURRENT_TIMESTAMP AS report_generated,
    'Database Overview' AS section_name
    
UNION ALL

SELECT 
    'Core Business Tables',
    NULL,
    'Customer: ' + CAST((SELECT COUNT(*) FROM Customer) AS VARCHAR(10)) + ' records'
    
UNION ALL

SELECT 
    '',
    NULL,
    'Invoices: ' + CAST((SELECT COUNT(*) FROM Invoice) AS VARCHAR(10)) + ' records'
    
UNION ALL

SELECT 
    '',
    NULL,
    'Tracks: ' + CAST((SELECT COUNT(*) FROM Track) AS VARCHAR(10)) + ' records'

UNION ALL

SELECT 
    'Data Quality Flags',
    NULL,
    CASE 
        WHEN (SELECT COUNT(*) FROM Customer WHERE Email IS NULL) > 0 
        THEN '⚠️ ' + CAST((SELECT COUNT(*) FROM Customer WHERE Email IS NULL) AS VARCHAR(10)) + ' customers missing email'
        ELSE '✅ All customers have email addresses'
    END;

-- 💡 Reporting Tip: This creates a standardized health check report
-- 💡 Automation: Schedule this query to run daily/weekly for monitoring

-- =================================================================================================================================
-- 🔍 PART 4: TROUBLESHOOTING AND PERFORMANCE CONSIDERATIONS
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 7: Identifying Tables That Need Attention
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Use table sizes to identify performance optimization opportunities

WITH performance_analysis AS (
    SELECT 'InvoiceLine' AS table_name, (SELECT COUNT(*) FROM InvoiceLine) AS row_count
    UNION ALL
    SELECT 'Track', (SELECT COUNT(*) FROM Track)
    UNION ALL
    SELECT 'PlaylistTrack', (SELECT COUNT(*) FROM PlaylistTrack)
    UNION ALL
    SELECT 'Invoice', (SELECT COUNT(*) FROM Invoice)
    UNION ALL
    SELECT 'Customer', (SELECT COUNT(*) FROM Customer)
)
SELECT 
    table_name,
    row_count,
    CASE 
        WHEN row_count > 10000 THEN 'High Priority - Consider indexing, partitioning'
        WHEN row_count > 1000 THEN 'Medium Priority - Monitor query performance' 
        WHEN row_count > 100 THEN 'Low Priority - Standard monitoring'
        ELSE 'Reference Data - Archive if not actively used'
    END AS optimization_priority,
    CASE 
        WHEN row_count > 10000 THEN 'Create indexes on frequently joined columns'
        WHEN row_count > 1000 THEN 'Monitor for slow queries'
        ELSE 'No immediate action needed'
    END AS recommended_action
FROM performance_analysis
ORDER BY row_count DESC;

-- 💡 Performance Insight: Largest tables often drive query performance issues
-- 💡 Proactive Monitoring: Use this to prioritize optimization efforts

-- =================================================================================================================================
-- 📋 SUMMARY AND NEXT STEPS
-- =================================================================================================================================

/*
🎯 KEY TAKEAWAYS:
1. Always start with table row counts for database reconnaissance
2. Categorize tables by business function (customer, transaction, product, reference)
3. Identify high-volume tables that need performance attention
4. Create reusable templates for ongoing monitoring
5. Use business context to make data volumes meaningful

📊 WHAT WE LEARNED ABOUT CHINOOK:
- InvoiceLine is likely the largest table (transaction detail)
- Track table contains the product catalog
- Customer table shows customer base size
- Reference tables (Genre, MediaType) are small and stable

🔧 RECOMMENDED ACTIONS:
1. Index the largest tables on commonly joined columns
2. Set up monitoring for unexpected growth in transaction tables  
3. Create alerts for empty tables that should contain data
4. Document table purposes for new team members

➡️ NEXT STEPS:
- Move to 02_column_profiling_and_types.sql to analyze data structure
- Apply these techniques to your own databases
- Create automated monitoring scripts for production systems
*/

-- =================================================================================================================================
-- 💼 BUSINESS PRESENTATION TEMPLATE
-- =================================================================================================================================

-- Use this query to create executive-friendly reports:
SELECT 
    'Chinook Digital Music Database Overview' AS report_title,
    CURRENT_TIMESTAMP AS generated_at
    
UNION ALL

SELECT 
    'Total Customer Base: ' + CAST((SELECT COUNT(*) FROM Customer) AS VARCHAR(10)),
    NULL
    
UNION ALL

SELECT 
    'Music Catalog Size: ' + CAST((SELECT COUNT(*) FROM Track) AS VARCHAR(10)) + ' tracks across ' + 
    CAST((SELECT COUNT(*) FROM Album) AS VARCHAR(10)) + ' albums',
    NULL
    
UNION ALL

SELECT 
    'Total Transactions: ' + CAST((SELECT COUNT(*) FROM Invoice) AS VARCHAR(10)) + ' invoices with ' + 
    CAST((SELECT COUNT(*) FROM InvoiceLine) AS VARCHAR(10)) + ' line items',
    NULL
    
UNION ALL

SELECT 
    'Workforce: ' + CAST((SELECT COUNT(*) FROM Employee) AS VARCHAR(10)) + ' employees',
    NULL;

-- 💡 Executive Summary: Perfect for stakeholder reports and documentation
-- 💡 Communication: Translate technical row counts into business metrics

/*
🚀 CONGRATULATIONS!
You've completed the table overview and counts analysis. You now know how to:
✅ Quickly assess any database structure and size
✅ Identify high-priority tables for optimization
✅ Create business-friendly reports from technical data
✅ Set up monitoring for ongoing database health

Ready for the next challenge? Continue to 02_column_profiling_and_types.sql!
*/
