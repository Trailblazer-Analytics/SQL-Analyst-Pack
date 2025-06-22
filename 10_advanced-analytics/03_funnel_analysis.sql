-- File: 10_advanced-analytics/03_funnel_analysis.sql
-- Topic: Funnel Analysis
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates how to perform funnel analysis in SQL. Funnel analysis is used to
-- track the flow of users through a specific sequence of events (a "funnel"), such as from
-- landing on a website to making a purchase. It helps identify where users drop off.

-- Prerequisites:
-- This is an advanced topic that requires a solid understanding of:
-- - Common Table Expressions (CTEs)
-- - Joins (especially LEFT JOINs)
-- - Aggregate functions
-- - Window functions (optional but useful for calculating conversion rates)

-- Dialect Compatibility:
-- The query structure using CTEs is widely supported. The final step using the LAG window
-- function is available in most modern databases like PostgreSQL, SQL Server, Oracle, SQLite 3.25+,
-- and MySQL 8.0+.

---------------------------------------------------------------------------------------------------

-- Section 1: What is Funnel Analysis?

-- A funnel represents a series of steps a user takes to reach a goal. For example:
-- 1. Visit Homepage -> 2. View Product -> 3. Add to Cart -> 4. Purchase

-- Funnel analysis measures the number of users who complete each step and calculates the
-- conversion rate between steps. This is crucial for understanding user behavior and
-- optimizing a product or process.

---------------------------------------------------------------------------------------------------

-- Section 2: Performing Funnel Analysis in SQL

-- The Chinook database doesn't have a classic user event log, so we will create a
-- hypothetical funnel based on customer purchasing behavior to demonstrate the technique.

-- Our Funnel Steps:
-- 1. All customers who have ever made a purchase.
-- 2. Of those, customers who have purchased more than 5 tracks in total.
-- 3. Of those, customers who have purchased at least one 'Rock' track.
-- 4. Of those, customers who have ALSO purchased at least one 'Jazz' track (showing exploration).

-- We will use CTEs to define the set of users who completed each step.

WITH
-- Step 1: Define the initial population (all customers with at least one invoice).
Step1_ActiveCustomers AS (
    SELECT DISTINCT CustomerId FROM invoices
),

-- Step 2: Identify customers who have purchased more than 5 tracks.
Step2_PurchasedOver5Tracks AS (
    SELECT CustomerId
    FROM invoice_items
    GROUP BY CustomerId
    HAVING COUNT(TrackId) > 5
),

-- Step 3: Identify customers who have purchased at least one 'Rock' track.
Step3_PurchasedRock AS (
    SELECT DISTINCT ii.CustomerId
    FROM invoice_items ii
    JOIN tracks t ON ii.TrackId = t.TrackId
    JOIN genres g ON t.GenreId = g.GenreId
    WHERE g.Name = 'Rock'
),

-- Step 4: Identify customers who have purchased at least one 'Jazz' track.
Step4_PurchasedJazz AS (
    SELECT DISTINCT ii.CustomerId
    FROM invoice_items ii
    JOIN tracks t ON ii.TrackId = t.TrackId
    JOIN genres g ON t.GenreId = g.GenreId
    WHERE g.Name = 'Jazz'
),

-- Now, we count the users at each stage of the funnel.
-- We use LEFT JOINs to ensure that we count users from one step only if they also
-- appear in the previous step.
FunnelCounts AS (
    SELECT
        '1. Active Customers' AS FunnelStep,
        COUNT(s1.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1

    UNION ALL

    SELECT
        '2. Purchased > 5 Tracks' AS FunnelStep,
        COUNT(s2.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1
    JOIN Step2_PurchasedOver5Tracks s2 ON s1.CustomerId = s2.CustomerId

    UNION ALL

    SELECT
        '3. Purchased Rock' AS FunnelStep,
        COUNT(s3.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1
    JOIN Step2_PurchasedOver5Tracks s2 ON s1.CustomerId = s2.CustomerId
    JOIN Step3_PurchasedRock s3 ON s2.CustomerId = s3.CustomerId

    UNION ALL

    SELECT
        '4. Purchased Rock & Jazz' AS FunnelStep,
        COUNT(s4.CustomerId) AS UserCount
    FROM Step1_ActiveCustomers s1
    JOIN Step2_PurchasedOver5Tracks s2 ON s1.CustomerId = s2.CustomerId
    JOIN Step3_PurchasedRock s3 ON s2.CustomerId = s3.CustomerId
    JOIN Step4_PurchasedJazz s4 ON s3.CustomerId = s4.CustomerId
)

-- Finally, calculate the conversion rates between steps.
SELECT
    FunnelStep,
    UserCount,
    -- Use LAG to get the user count from the previous step.
    LAG(UserCount, 1, UserCount) OVER (ORDER BY FunnelStep) AS PreviousStepCount,
    -- Calculate the percentage conversion from the previous step.
    (CAST(UserCount AS REAL) * 100 / LAG(UserCount, 1, UserCount) OVER (ORDER BY FunnelStep)) AS ConversionRate_Vs_Previous_Step,
    -- Calculate the percentage conversion from the very first step.
    (CAST(UserCount AS REAL) * 100 / FIRST_VALUE(UserCount) OVER (ORDER BY FunnelStep)) AS ConversionRate_Vs_First_Step
FROM
    FunnelCounts
ORDER BY
    FunnelStep;

-- The output shows the number of users at each stage and the drop-off rate,
-- allowing an analyst to see that the biggest drop-off is between buying rock and also buying jazz.
-- This could lead to a recommendation to promote jazz playlists to rock fans.
