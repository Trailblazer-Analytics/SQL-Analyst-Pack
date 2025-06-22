-- File: 10_advanced-analytics/02_cohort_analysis.sql
-- Topic: Cohort Analysis
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates how to perform cohort analysis, a powerful technique for understanding
-- user retention over time. It groups users into cohorts based on a shared characteristic
-- (e.g., sign-up date) and tracks their behavior over subsequent periods.

-- Prerequisites:
-- This is an advanced topic requiring strong knowledge of:
-- - Common Table Expressions (CTEs)
-- - Window Functions
-- - Date manipulation functions
-- - Joins and aggregations

-- Dialect Compatibility:
-- The query structure is complex and relies heavily on date functions, which vary significantly
-- across SQL dialects. The main example is written for SQLite, but notes are provided for
-- PostgreSQL, SQL Server, and MySQL.

---------------------------------------------------------------------------------------------------

-- Section 1: What is Cohort Analysis?

-- Cohort analysis groups users into "cohorts" based on when they started using a product
-- (e.g., their acquisition month). It then tracks how many of those users remain active
-- in the following months or weeks. The output is typically a triangular matrix showing
-- retention rates.

-- Why is it useful?
-- - It reveals how user retention is changing over time.
-- - It helps measure the impact of product changes on user loyalty.
-- - It provides a more accurate picture of retention than a single, site-wide average.

---------------------------------------------------------------------------------------------------

-- Section 2: Performing Cohort Analysis in SQL

-- We will analyze customer retention in the Chinook database.
-- - Cohort: Customers grouped by the month of their first purchase.
-- - Activity: A customer is considered "active" in a month if they made at least one purchase.

-- The query involves several steps, broken down using CTEs.

-- SQLite / PostgreSQL Version
WITH
-- Step 1: Determine the cohort for each customer (the month of their first purchase).
CustomerCohorts AS (
    SELECT
        CustomerId,
        MIN(DATE(InvoiceDate, 'start of month')) AS CohortMonth
    FROM
        invoices
    GROUP BY
        CustomerId
),

-- Step 2: Calculate the monthly activity for each customer.
MonthlyActivity AS (
    SELECT DISTINCT
        CustomerId,
        DATE(InvoiceDate, 'start of month') AS ActivityMonth
    FROM
        invoices
),

-- Step 3: Join cohorts with their monthly activity and calculate the month number.
-- The month number is the number of months that have passed since the cohort month.
CohortActivity AS (
    SELECT
        ma.CustomerId,
        cc.CohortMonth,
        ma.ActivityMonth,
        -- Calculate the difference in months between activity and cohort month.
        -- This logic is highly dialect-specific.
        (CAST(STRFTIME('%Y', ma.ActivityMonth) AS INTEGER) - CAST(STRFTIME('%Y', cc.CohortMonth) AS INTEGER)) * 12 +
        (CAST(STRFTIME('%m', ma.ActivityMonth) AS INTEGER) - CAST(STRFTIME('%m', cc.CohortMonth) AS INTEGER)) AS MonthNumber
    FROM
        MonthlyActivity ma
    JOIN
        CustomerCohorts cc ON ma.CustomerId = cc.CustomerId
),

-- Step 4: Count the number of unique customers in each cohort for each month number.
CohortSize AS (
    SELECT
        CohortMonth,
        MonthNumber,
        COUNT(DISTINCT CustomerId) AS ActiveCustomers
    FROM
        CohortActivity
    GROUP BY
        CohortMonth, MonthNumber
),

-- Step 5: Get the initial size of each cohort (number of customers in Month 0).
InitialCohortSize AS (
    SELECT
        CohortMonth,
        ActiveCustomers AS TotalCohortSize
    FROM
        CohortSize
    WHERE
        MonthNumber = 0
)

-- Final Step: Join the cohort sizes to calculate retention percentages and pivot the data.
SELECT
    cs.CohortMonth,
    ics.TotalCohortSize,
    cs.MonthNumber,
    cs.ActiveCustomers,
    -- Calculate retention rate
    (CAST(cs.ActiveCustomers AS REAL) / ics.TotalCohortSize) * 100 AS RetentionPercentage
FROM
    CohortSize cs
JOIN
    InitialCohortSize ics ON cs.CohortMonth = ics.CohortMonth
ORDER BY
    cs.CohortMonth, cs.MonthNumber;

-- To create the classic cohort chart, you would pivot the results of this query,
-- with CohortMonth as rows, MonthNumber as columns, and RetentionPercentage as values.
-- Most SQL dialects require conditional aggregation for pivoting.

-- Example of Pivoting (for a few months):
/*
SELECT
    CohortMonth,
    TotalCohortSize,
    MAX(CASE WHEN MonthNumber = 0 THEN RetentionPercentage END) AS Month_0,
    MAX(CASE WHEN MonthNumber = 1 THEN RetentionPercentage END) AS Month_1,
    MAX(CASE WHEN MonthNumber = 2 THEN RetentionPercentage END) AS Month_2,
    MAX(CASE WHEN MonthNumber = 3 THEN RetentionPercentage END) AS Month_3
FROM (
    SELECT
        cs.CohortMonth,
        ics.TotalCohortSize,
        cs.MonthNumber,
        (CAST(cs.ActiveCustomers AS REAL) / ics.TotalCohortSize) * 100 AS RetentionPercentage
    FROM
        CohortSize cs
    JOIN
        InitialCohortSize ics ON cs.CohortMonth = ics.CohortMonth
) AS SubQuery
GROUP BY
    CohortMonth, TotalCohortSize
ORDER BY
    CohortMonth;
*/

---------------------------------------------------------------------------------------------------

-- Dialect-Specific Notes for Month Difference Calculation:

-- PostgreSQL:
-- `(EXTRACT(YEAR FROM ma.ActivityMonth) - EXTRACT(YEAR FROM cc.CohortMonth)) * 12 +`
-- `(EXTRACT(MONTH FROM ma.ActivityMonth) - EXTRACT(MONTH FROM cc.CohortMonth)) AS MonthNumber`

-- SQL Server:
-- `DATEDIFF(month, cc.CohortMonth, ma.ActivityMonth) AS MonthNumber`

-- MySQL:
-- `PERIOD_DIFF(DATE_FORMAT(ma.ActivityMonth, '%Y%m'), DATE_FORMAT(cc.CohortMonth, '%Y%m')) AS MonthNumber`

-- This script provides a foundational template for cohort analysis. The real power comes from
-- adapting it to specific business questions and visualizing the resulting data.
