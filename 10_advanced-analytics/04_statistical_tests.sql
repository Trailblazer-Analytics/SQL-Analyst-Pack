-- File: 10_advanced-analytics/04_statistical_tests.sql
-- Topic: Statistical Tests in SQL
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script explains the role of SQL in statistical testing (like A/B testing).
-- While most SQL dialects lack built-in functions for complex statistical tests (e.g., t-tests),
-- SQL is essential for aggregating the data required to perform these tests.
-- We will demonstrate how to calculate the necessary inputs for a two-sample t-test.

-- Prerequisites:
-- Strong understanding of aggregate functions (`COUNT`, `AVG`, `SUM`).
-- Familiarity with statistical concepts (mean, variance, standard deviation) is highly beneficial.

-- Dialect Compatibility:
-- The script uses standard aggregate functions. Functions for variance (`VAR_SAMP`) and
-- standard deviation (`STDDEV_SAMP`) are widely supported in PostgreSQL, SQL Server, Oracle,
-- MySQL, and Snowflake. SQLite requires custom functions or manual calculation.

---------------------------------------------------------------------------------------------------

-- Section 1: The Role of SQL in Statistical Testing

-- Statistical tests help us determine if an observed effect is statistically significant or
-- just due to random chance. A common example is an A/B test, where we compare two versions
-- (A and B) of something to see which one performs better.

-- SQL's job is not to run the test itself, but to:
-- 1. Define the two groups (e.g., Control Group A, Treatment Group B).
-- 2. Calculate the key metrics for each group (e.g., conversion rate, average purchase value).
-- 3. Compute the necessary statistics for the test (mean, variance, sample size).

-- The results from the SQL query are then plugged into a statistical tool or formula
-- (in Python, R, or even an online calculator) to get a p-value.

---------------------------------------------------------------------------------------------------

-- Section 2: Calculating Inputs for a Two-Sample T-Test

-- A two-sample t-test is used to determine if there is a significant difference between the
-- means of two independent groups.

-- To perform this test, we need three pieces of information for each group:
-- 1. The mean (average) of the metric being tested.
-- 2. The variance of the metric.
-- 3. The sample size (number of observations).

-- Scenario: Let's conduct a hypothetical A/B test. We want to see if customers from the USA
-- have a significantly different average invoice total compared to customers from Canada.
-- - Group A: USA Customers
-- - Group B: Canada Customers
-- - Metric: Invoice Total

-- We can get all the necessary data in a single SQL query.

-- PostgreSQL, SQL Server, Oracle, MySQL, Snowflake Version:
SELECT
    BillingCountry AS TestGroup,
    COUNT(Total) AS SampleSize,
    AVG(Total) AS Mean,
    VAR_SAMP(Total) AS Variance,
    STDDEV_SAMP(Total) AS StandardDeviation
FROM
    invoices
WHERE
    BillingCountry IN ('USA', 'Canada')
GROUP BY
    BillingCountry;

-- Note on SQLite:
-- SQLite does not have built-in `VAR_SAMP` or `STDDEV_SAMP` functions.
-- You would need to calculate variance manually using the formula:
-- Variance = (SUM(x^2) - (SUM(x) * SUM(x)) / N) / (N - 1)
-- where x is the value (Total), and N is the sample size.

-- Example for SQLite (more complex):
/*
WITH GroupStats AS (
    SELECT
        BillingCountry AS TestGroup,
        COUNT(Total) AS SampleSize,
        SUM(Total) AS SumTotal,
        SUM(Total * Total) AS SumTotalSquared
    FROM
        invoices
    WHERE
        BillingCountry IN ('USA', 'Canada')
    GROUP BY
        BillingCountry
)
SELECT
    TestGroup,
    SampleSize,
    SumTotal / SampleSize AS Mean,
    -- Manual variance calculation
    (SumTotalSquared - (SumTotal * SumTotal) / SampleSize) / (SampleSize - 1) AS Variance
FROM
    GroupStats;
*/

---------------------------------------------------------------------------------------------------

-- Section 3: Interpreting the Results

-- The output of the SQL query might look something like this (hypothetical values):

-- TestGroup | SampleSize | Mean   | Variance
-- ----------|------------|--------|----------
-- USA       | 91         | 5.87   | 28.5
-- Canada    | 56         | 5.52   | 25.9

-- With this data, a data scientist or analyst can now:
-- 1. Plug these numbers into a t-test formula or software.
-- 2. Calculate the t-statistic and the p-value.
-- 3. Draw a conclusion: If the p-value is below a certain threshold (e.g., 0.05), they would
--    conclude that there is a statistically significant difference in average invoice totals
--    between USA and Canadian customers.

-- This script shows that while SQL is not a replacement for a statistical package, it is the
-- indispensable first step for preparing and aggregating data for rigorous analysis.
