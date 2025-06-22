-- 01_intro_to_date_time.sql
--
-- Title: Introduction to Date/Time Functions
-- Description: Basic examples of working with dates and times in SQL.
-- Use Cases: Viewing current date/time, formatting dates, simple calculations.
-- Learning Objectives:
--   - Retrieve current date/time
--   - Format and cast date/time values
-- SQL Flavor Notes:
--   - Supported: PostgreSQL, MySQL, SQL Server, Oracle, SQLite, BigQuery, Snowflake

-- Get current date and time
SELECT CURRENT_DATE AS today, CURRENT_TIME AS now;

-- Format a date (PostgreSQL example)
SELECT TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') AS formatted_date;

-- Add days to a date
SELECT CURRENT_DATE + INTERVAL '7 days' AS one_week_later;
