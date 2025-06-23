/*
    File: 02_column_profiling_and_types.sql
    Module: 02_data_profiling
    Topic: Column Analysis and Data Type Validation
    Author: SQL Analyst Pack
    Date: 2025-06-22
    Description: Deep dive into column structure, data types, and field characteristics
    
    Business Scenarios:
    - Data migration and schema validation
    - API integration and data type mapping
    - Data quality auditing and compliance
    - Database optimization and storage planning
    
    Database: Chinook (Music Store Digital Media)
    Complexity: Beginner to Intermediate
    Estimated Time: 45-60 minutes
*/

-- =================================================================================================================================
-- 🎯 LEARNING OBJECTIVES
-- =================================================================================================================================
--
-- After completing this script, you will be able to:
-- ✅ Analyze column structures and data types systematically
-- ✅ Identify potential data type issues and optimization opportunities
-- ✅ Validate schema consistency across environments
-- ✅ Create comprehensive data dictionaries and documentation
-- ✅ Assess data storage efficiency and design quality
--
-- =================================================================================================================================
-- 💼 BUSINESS SCENARIO: Schema Analysis for Data Migration
-- =================================================================================================================================
--
-- The Chinook Digital Music company is planning a major system upgrade and needs to:
-- 1. Document current database schema for migration planning
-- 2. Identify data type inefficiencies that increase storage costs
-- 3. Validate that all columns have appropriate data types for business rules
-- 4. Create technical documentation for the development team
-- 5. Ensure compliance with data governance standards
--
-- Your task: Provide a comprehensive column analysis and recommendations.
--
-- =================================================================================================================================
-- 📊 PART 1: SYSTEMATIC COLUMN PROFILING
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Comprehensive Customer Table Column Analysis
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Let's start with the Customer table - one of the most critical business entities

SELECT
    column_name,
    ordinal_position,
    data_type,
    CASE 
        WHEN character_maximum_length IS NOT NULL 
        THEN data_type + '(' + CAST(character_maximum_length AS VARCHAR(10)) + ')'
        WHEN numeric_precision IS NOT NULL AND numeric_scale IS NOT NULL
        THEN data_type + '(' + CAST(numeric_precision AS VARCHAR(10)) + ',' + CAST(numeric_scale AS VARCHAR(10)) + ')'
        WHEN numeric_precision IS NOT NULL
        THEN data_type + '(' + CAST(numeric_precision AS VARCHAR(10)) + ')'
        ELSE data_type
    END AS full_data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name LIKE '%Id' THEN '🔑 Identifier'
        WHEN column_name LIKE '%Name%' OR column_name LIKE '%First%' OR column_name LIKE '%Last%' THEN '👤 Personal Info'
        WHEN column_name LIKE '%Email%' OR column_name LIKE '%Phone%' OR column_name LIKE '%Fax%' THEN '📞 Contact Info'
        WHEN column_name LIKE '%Address%' OR column_name LIKE '%City%' OR column_name LIKE '%State%' OR column_name LIKE '%Country%' THEN '🏠 Address Info'
        WHEN column_name LIKE '%Date%' OR column_name LIKE '%Time%' THEN '📅 Temporal Data'
        ELSE '📋 Other'
    END AS business_category,
    -- Data quality assessment
    CASE 
        WHEN is_nullable = 'YES' AND column_name LIKE '%Id' THEN '⚠️ Potential Issue: ID field allows nulls'
        WHEN is_nullable = 'NO' AND column_name LIKE '%Email%' THEN '✅ Good: Required contact field'
        WHEN character_maximum_length > 255 AND column_name NOT LIKE '%Address%' THEN '💾 Large field - review if necessary'
        WHEN is_nullable = 'YES' THEN '📝 Optional field'
        ELSE '✅ Standard configuration'
    END AS quality_assessment
FROM information_schema.columns
WHERE table_name = 'Customer'
ORDER BY ordinal_position;

-- 💡 Business Insight: This reveals data design patterns and potential issues
-- 💡 Migration Planning: Full data type info helps with target system mapping

-- =================================================================================================================================
-- Flavor-Specific Examples for Describing Table Structure
-- =================================================================================================================================
--
-- While `INFORMATION_SCHEMA` is standard, some databases offer convenient shortcuts to describe a table.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- PostgreSQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `\d` command in the `psql` client provides a detailed description of a table.
-- This is a command-line shortcut, not an SQL query.
-- \d employees

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQL Server
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `sp_help` stored procedure gives a comprehensive overview of a table or any other object.
EXEC sp_help 'dbo.employees';

-- A more focused procedure for columns is `sp_columns`.
EXEC sp_columns 'employees';

-- ---------------------------------------------------------------------------------------------------------------------------------
-- MySQL
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `DESCRIBE` or `EXPLAIN` statement is a concise way to see a table's structure.
DESCRIBE employees;
-- or
EXPLAIN employees;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- SQLite
-- ---------------------------------------------------------------------------------------------------------------------------------
-- The `PRAGMA` statement is used to query database metadata. `table_info` returns column details.
PRAGMA table_info(employees);

-- =================================================================================================================================
-- Practical Exercise: Profile Columns in the Chinook Database
-- =================================================================================================================================

-- 1. Get the column profile for the 'tracks' table.
--    Use the INFORMATION_SCHEMA query or the specific command for your database flavor.
--    (Example for ANSI SQL)
SELECT
    column_name,
    data_type,
    is_nullable,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM
    information_schema.columns
WHERE
    table_name = 'tracks'
ORDER BY
    ordinal_position;

-- 2. Describe the structure of the 'invoices' table using your database's shortcut command.
--    (Example for SQLite)
PRAGMA table_info(invoices);

--    (Example for MySQL)
--    DESCRIBE invoices;

--    (Example for SQL Server)
--    EXEC sp_help 'dbo.invoices';

-- 3. Find out which columns in the 'customers' table can accept NULL values.
SELECT
    column_name,
    is_nullable
FROM
    information_schema.columns
WHERE
    table_name = 'customers' AND is_nullable = 'YES';

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- Understanding column properties is fundamental to data analysis. It informs how you query data (e.g., knowing
-- date formats), how you clean it (e.g., handling nulls), and how you join tables (e.g., matching data types).
-- Always take the time to profile your columns before proceeding with more complex analysis.
--
-- Next, we will explore data quality issues like NULL values and inconsistencies.
--
-- =================================================================================================================================
