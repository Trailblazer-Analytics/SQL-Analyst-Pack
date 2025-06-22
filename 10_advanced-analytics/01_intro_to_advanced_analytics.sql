-- File: 10_advanced-analytics/01_intro_to_advanced_analytics.sql
-- Topic: Introduction to Advanced Analytics
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script provides an introduction to advanced analytical functions in SQL.
-- While basic analytics involve sums and averages, advanced analytics can include
-- more complex statistical measures like percentiles, which help in understanding
-- data distribution and identifying outliers.

-- Prerequisites:
-- A good understanding of aggregate functions and basic SQL concepts is required.
-- Knowledge of window functions is helpful but not strictly necessary for this script.

-- Dialect Compatibility:
-- The primary function shown here, `PERCENTILE_CONT`, is part of the SQL standard
-- and is supported by many modern database systems, including:
-- - PostgreSQL
-- - SQL Server
-- - Oracle
-- - Snowflake
-- - BigQuery
-- MySQL supports percentiles through other functions like `PERCENT_RANK`.
-- SQLite does not have a built-in percentile function.

---------------------------------------------------------------------------------------------------

-- Section 1: What are Advanced Analytics in SQL?

-- Advanced analytics in SQL go beyond simple `SUM`, `AVG`, `COUNT` operations.
-- They often involve statistical calculations that provide deeper insights into the data.
-- These can include:
-- - Percentiles and Quartiles: To understand data distribution.
-- - Cohort Analysis: To track user behavior over time.
-- - Funnel Analysis: To analyze conversion rates through a process.
-- - Statistical Tests: To validate hypotheses.

-- This script focuses on one of the most common advanced functions: calculating percentiles.

---------------------------------------------------------------------------------------------------

-- Section 2: Calculating Percentiles with PERCENTILE_CONT

-- A percentile is a measure indicating the value below which a given percentage of observations
-- in a group of observations falls. For example, the 90th percentile is the value below which
-- 90% of the data is found.

-- `PERCENTILE_CONT(fraction)` is an ordered-set aggregate function that computes a percentile
-- based on a continuous distribution of the column value.

-- Scenario: We want to find the 90th percentile of invoice totals to understand what
-- constitutes a high-value purchase in the Chinook store.

-- The syntax is `PERCENTILE_CONT(fraction) WITHIN GROUP (ORDER BY column_name)`

-- PostgreSQL, SQL Server, Oracle, Snowflake:
SELECT
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY Total) AS P90_InvoiceTotal
FROM
    invoices;

-- This query will return a single value. For instance, if the result is 50.00, it means
-- 90% of all invoices have a total amount less than or equal to $50.00.

---------------------------------------------------------------------------------------------------

-- Section 3: Calculating Multiple Percentiles

-- You can calculate multiple percentiles in the same query to get a better sense of the distribution.
-- Let's find the 25th (Q1), 50th (median), and 75th (Q3) percentiles.

-- PostgreSQL, SQL Server, Oracle, Snowflake:
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total) AS P25_InvoiceTotal,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Total) AS P50_MedianInvoiceTotal,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total) AS P75_InvoiceTotal
FROM
    invoices;

-- The median (50th percentile) is a particularly useful statistic as it is less sensitive
-- to outliers than the average (mean).

---------------------------------------------------------------------------------------------------

-- Section 4: Using Percentiles with PARTITION BY (as a Window Function)

-- We can also use `PERCENTILE_CONT` as a window function to calculate percentiles for different
-- subgroups within the data. For example, what is the median invoice total for each country?

-- Note: This syntax is more complex and support may vary.
-- PostgreSQL, SQL Server, Oracle, Snowflake support this.

SELECT DISTINCT
    BillingCountry,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Total) OVER (PARTITION BY BillingCountry) AS MedianInvoiceTotalByCountry
FROM
    invoices
ORDER BY
    BillingCountry;

-- This query calculates the median invoice total separately for each country, giving us a
-- powerful comparative view of purchasing behavior across different regions.

-- This introduction provides a glimpse into the power of advanced analytical functions in SQL.
-- The following scripts in this section will explore more specialized analytical techniques
-- like cohort and funnel analysis.
