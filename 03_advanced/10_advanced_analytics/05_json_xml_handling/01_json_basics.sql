/*
Title: JSON Data Handling in SQL
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Description: Introduction to working with JSON data in SQL across different database platforms
*/

-- ==========================================
-- INTRODUCTION TO JSON IN SQL
-- ==========================================
-- Modern SQL databases provide robust support for storing, querying, and manipulating JSON data.
-- This script demonstrates common JSON operations across different database platforms.

-- ==========================================
-- 1. STORING JSON DATA
-- ==========================================

-- PostgreSQL
CREATE TABLE IF NOT EXISTS customer_preferences_pg (
    customer_id INT PRIMARY KEY,
    preferences JSONB, -- JSONB is binary JSON format with indexing support
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SQL Server
-- SQL Server 2016+ supports JSON as NVARCHAR with JSON functions
CREATE TABLE IF NOT EXISTS customer_preferences_mssql (
    customer_id INT PRIMARY KEY,
    preferences NVARCHAR(MAX) CHECK (ISJSON(preferences) = 1),
    last_updated DATETIME2 DEFAULT CURRENT_TIMESTAMP
);

-- MySQL
CREATE TABLE IF NOT EXISTS customer_preferences_mysql (
    customer_id INT PRIMARY KEY,
    preferences JSON,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. INSERTING JSON DATA
-- ==========================================

-- PostgreSQL
INSERT INTO customer_preferences_pg (customer_id, preferences)
VALUES (
    1,
    '{"theme": "dark", "notifications": {"email": true, "sms": false}, "categories": ["electronics", "books"]}'::JSONB
);

-- SQL Server
INSERT INTO customer_preferences_mssql (customer_id, preferences)
VALUES (
    1,
    N'{"theme": "dark", "notifications": {"email": true, "sms": false}, "categories": ["electronics", "books"]}'
);

-- MySQL
INSERT INTO customer_preferences_mysql (customer_id, preferences)
VALUES (
    1,
    '{"theme": "dark", "notifications": {"email": true, "sms": false}, "categories": ["electronics", "books"]}'
);

-- ==========================================
-- 3. QUERYING JSON DATA
-- ==========================================

-- PostgreSQL - Extract a scalar value
SELECT 
    customer_id,
    preferences->>'theme' AS theme
FROM customer_preferences_pg;

-- PostgreSQL - Extract a nested value
SELECT 
    customer_id,
    preferences->'notifications'->>'email' AS email_notifications
FROM customer_preferences_pg;

-- PostgreSQL - Filter based on JSON properties
SELECT 
    customer_id
FROM customer_preferences_pg
WHERE preferences->>'theme' = 'dark';

-- SQL Server - Extract a scalar value
SELECT 
    customer_id,
    JSON_VALUE(preferences, '$.theme') AS theme
FROM customer_preferences_mssql;

-- SQL Server - Extract a nested value
SELECT 
    customer_id,
    JSON_VALUE(preferences, '$.notifications.email') AS email_notifications
FROM customer_preferences_mssql;

-- SQL Server - Filter based on JSON properties
SELECT 
    customer_id
FROM customer_preferences_mssql
WHERE JSON_VALUE(preferences, '$.theme') = 'dark';

-- MySQL - Extract a scalar value
SELECT 
    customer_id,
    JSON_EXTRACT(preferences, '$.theme') AS theme
FROM customer_preferences_mysql;

-- MySQL - Extract a nested value
SELECT 
    customer_id,
    JSON_EXTRACT(preferences, '$.notifications.email') AS email_notifications
FROM customer_preferences_mysql;

-- MySQL - Filter based on JSON properties (note the ->> operator is equivalent to JSON_UNQUOTE(JSON_EXTRACT()))
SELECT 
    customer_id
FROM customer_preferences_mysql
WHERE preferences->>'$.theme' = 'dark';

-- ==========================================
-- 4. WORKING WITH JSON ARRAYS
-- ==========================================

-- PostgreSQL - Unnest a JSON array
SELECT 
    customer_id,
    jsonb_array_elements_text(preferences->'categories') AS category
FROM customer_preferences_pg;

-- SQL Server - Use OPENJSON to work with arrays
SELECT 
    p.customer_id,
    c.value AS category
FROM customer_preferences_mssql p
CROSS APPLY OPENJSON(p.preferences, '$.categories') c;

-- MySQL - Use JSON_TABLE to work with arrays
SELECT 
    p.customer_id,
    c.category
FROM customer_preferences_mysql p,
JSON_TABLE(
    p.preferences->'$.categories',
    '$[*]' COLUMNS (category VARCHAR(255) PATH '$')
) AS c;

-- ==========================================
-- 5. UPDATING JSON DATA
-- ==========================================

-- PostgreSQL - Update a specific property
UPDATE customer_preferences_pg
SET preferences = jsonb_set(preferences, '{theme}', '"light"')
WHERE customer_id = 1;

-- PostgreSQL - Add a new property
UPDATE customer_preferences_pg
SET preferences = preferences || '{"language": "en"}'::jsonb
WHERE customer_id = 1;

-- SQL Server - Update a specific property
UPDATE customer_preferences_mssql
SET preferences = JSON_MODIFY(preferences, '$.theme', 'light')
WHERE customer_id = 1;

-- SQL Server - Add a new property
UPDATE customer_preferences_mssql
SET preferences = JSON_MODIFY(preferences, '$.language', 'en')
WHERE customer_id = 1;

-- MySQL - Update a specific property
UPDATE customer_preferences_mysql
SET preferences = JSON_SET(preferences, '$.theme', 'light')
WHERE customer_id = 1;

-- MySQL - Add a new property
UPDATE customer_preferences_mysql
SET preferences = JSON_SET(preferences, '$.language', 'en')
WHERE customer_id = 1;

-- ==========================================
-- 6. INDEXING JSON DATA
-- ==========================================

-- PostgreSQL - GIN index for efficient querying
CREATE INDEX idx_preferences_gin ON customer_preferences_pg USING GIN (preferences);

-- PostgreSQL - Functional index for a specific property
CREATE INDEX idx_theme ON customer_preferences_pg ((preferences->>'theme'));

-- SQL Server - No direct JSON indexing, but you can use computed columns
ALTER TABLE customer_preferences_mssql
ADD theme AS JSON_VALUE(preferences, '$.theme');

CREATE INDEX idx_theme ON customer_preferences_mssql (theme);

-- MySQL - Functional index for a specific property
CREATE INDEX idx_theme ON customer_preferences_mysql ((preferences->>'$.theme'));

-- ==========================================
-- 7. ADVANCED JSON OPERATIONS
-- ==========================================

-- PostgreSQL - Aggregating JSON objects
SELECT jsonb_agg(preferences) AS all_preferences
FROM customer_preferences_pg;

-- PostgreSQL - Merging JSON objects
SELECT jsonb_object_agg(customer_id, preferences) AS customer_preferences_map
FROM customer_preferences_pg;

-- SQL Server - Aggregating JSON objects
SELECT (
    SELECT p.preferences
    FROM customer_preferences_mssql p
    FOR JSON AUTO
) AS all_preferences;

-- MySQL - Aggregating JSON objects
SELECT JSON_ARRAYAGG(preferences) AS all_preferences
FROM customer_preferences_mysql;

-- ==========================================
-- 8. REAL-WORLD EXAMPLE: CUSTOMER ANALYTICS
-- ==========================================

-- Analyze which product categories are most popular
-- PostgreSQL version
SELECT 
    jsonb_array_elements_text(preferences->'categories') AS category,
    COUNT(*) AS customer_count
FROM customer_preferences_pg
GROUP BY category
ORDER BY customer_count DESC;

-- Find customers who prefer email but not SMS notifications
-- PostgreSQL version
SELECT 
    customer_id,
    preferences->'notifications'->>'email' AS email_pref,
    preferences->'notifications'->>'sms' AS sms_pref
FROM customer_preferences_pg
WHERE 
    (preferences->'notifications'->>'email')::boolean = true AND
    (preferences->'notifications'->>'sms')::boolean = false;

-- ==========================================
-- BEST PRACTICES
-- ==========================================

-- 1. Use appropriate JSON data types for your database
-- 2. Consider normalization vs. denormalization tradeoffs
-- 3. Index frequently queried JSON properties
-- 4. Be aware of performance implications for complex JSON operations
-- 5. Validate JSON schema where possible
-- 6. Use JSON functions specific to your database platform for optimal performance

-- ==========================================
-- CLEANUP (UNCOMMENT TO RUN)
-- ==========================================

-- DROP TABLE IF EXISTS customer_preferences_pg;
-- DROP TABLE IF EXISTS customer_preferences_mssql;
-- DROP TABLE IF EXISTS customer_preferences_mysql;
