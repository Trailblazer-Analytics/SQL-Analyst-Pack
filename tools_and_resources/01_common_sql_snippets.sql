/*
================================================================================
File: tools_and_resources/01_common_sql_snippets.sql
Topic: Common SQL Snippets and Templates for Business Analysis
Purpose: Comprehensive collection of reusable SQL patterns for analysts
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Updated: 2025-06-23
================================================================================

OVERVIEW:
This script serves as a comprehensive repository of common, reusable SQL snippets 
for frequent analytical tasks. These production-ready templates can be adapted for 
various business scenarios and database schemas.

PREREQUISITES:
- Knowledge of window functions, CTEs, and basic aggregations
- Understanding of database joins and filtering
- Familiarity with your specific database dialect

SQL COMPATIBILITY:
✅ PostgreSQL, SQL Server, Oracle, MySQL 8.0+, SQLite 3.25+
⚠️ Older MySQL versions may need alternative approaches (noted in snippets)

CONTENTS:
1. Top N Records Per Group (rankings, leaderboards)
2. Running Totals and Cumulative Calculations (financial analysis)
3. Pivot Data Transformation (reporting, dashboards)
4. First and Last Event Analysis (customer journeys)
5. Date Series Generation (time series analysis)
6. Session-Based Analytics (user behavior)
7. Customer Lifetime Value (business metrics)

USAGE:
Each snippet includes business context, technical explanation, and adaptation notes.
Copy the relevant pattern and modify table/column names for your use case.
================================================================================
*/

/*
================================================================================
SNIPPET 1: TOP N RECORDS PER GROUP
================================================================================

BUSINESS USE CASE:
Essential pattern for business analysis - finding top performers, best sellers,
highest value customers, or worst performing items within specific categories.
Common in sales analysis, product performance, and competitive rankings.

TECHNIQUE:
Uses ROW_NUMBER() window function with PARTITION BY to rank items within groups,
then filters to show only the top N results per group.

EXAMPLE APPLICATIONS:
- Top 3 salespeople by region
- Best-selling products per category
- Highest value customers by segment
- Most profitable items by business unit
================================================================================
*/

-- Find the top 3 best-selling tracks in each genre
WITH RankedTracks AS (
    SELECT
        g.Name AS Genre,
        t.Name AS TrackName,
        SUM(ii.Quantity) AS UnitsSold,
        ROW_NUMBER() OVER(PARTITION BY g.Name ORDER BY SUM(ii.Quantity) DESC) as Rank
    FROM
        genres g
    JOIN
        tracks t ON g.GenreId = t.GenreId
    JOIN
        invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY
        g.Name, t.Name
)
SELECT
    Genre,
    TrackName,
    UnitsSold
FROM
    RankedTracks
WHERE
    Rank <= 3
ORDER BY
    Genre, UnitsSold DESC;

-- ADAPTATION NOTES:
-- 1. Change 'g.Name' to your grouping column
-- 2. Change 'SUM(ii.Quantity)' to your ranking metric
-- 3. Adjust 'Rank <= 3' to desired top N count
-- 4. Use RANK() or DENSE_RANK() for tie handling
-- 5. Change ORDER BY DESC to ASC for bottom N records

/*
================================================================================
SNIPPET 2: RUNNING TOTALS AND CUMULATIVE CALCULATIONS
================================================================================

BUSINESS USE CASE:
Critical for financial analysis, growth tracking, and trend analysis.
Shows progressive accumulation of values over time - perfect for revenue tracking,
budget analysis, and performance monitoring.

TECHNIQUE:
Uses SUM() OVER() with ORDER BY to create cumulative calculations.
Can be adapted for running averages, counts, and other progressive metrics.

EXAMPLE APPLICATIONS:
- Cumulative monthly revenue
- Year-to-date sales figures
- Running customer acquisition counts
- Progressive budget consumption
================================================================================
*/

-- Calculate the cumulative monthly revenue over the entire history
WITH MonthlyRevenue AS (
    SELECT
        DATE(InvoiceDate, 'start of month') AS InvoiceMonth,
        SUM(Total) AS MonthlyTotal
    FROM
        invoices
    GROUP BY
        InvoiceMonth
)
SELECT
    InvoiceMonth,
    MonthlyTotal,
    SUM(MonthlyTotal) OVER (ORDER BY InvoiceMonth) AS RunningTotalRevenue,
    AVG(MonthlyTotal) OVER (ORDER BY InvoiceMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg
FROM
    MonthlyRevenue
ORDER BY
    InvoiceMonth;

-- ADAPTATION NOTES:
-- 1. Replace DATE() function with your database's date truncation function
-- 2. Change 'Total' to your metric column
-- 3. Adjust the ROWS BETWEEN clause for different moving averages
-- 4. Use PARTITION BY for running totals within groups
-- 5. Add WHERE clauses to limit date ranges

/*
================================================================================
SNIPPET 3: PIVOT DATA TRANSFORMATION
================================================================================

BUSINESS USE CASE:
Transform row-based data into columnar format for reporting and dashboards.
Essential for creating cross-tab reports, year-over-year comparisons,
and summary tables that stakeholders expect.

TECHNIQUE:
Uses conditional aggregation with CASE statements to pivot row data into columns.
More portable than database-specific PIVOT functions.

EXAMPLE APPLICATIONS:
- Sales by country per year
- Product performance by quarter
- Customer segments by channel
- Budget vs actual by department
================================================================================
*/

-- Show total sales for each country, with separate columns for each year
SELECT
    BillingCountry,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2009' THEN Total ELSE 0 END) AS Sales_2009,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2010' THEN Total ELSE 0 END) AS Sales_2010,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2011' THEN Total ELSE 0 END) AS Sales_2011,
    SUM(CASE WHEN STRFTIME('%Y', InvoiceDate) = '2012' THEN Total ELSE 0 END) AS Sales_2012,
    SUM(Total) AS TotalSales
FROM
    invoices
GROUP BY
    BillingCountry
ORDER BY
    TotalSales DESC;

-- ADAPTATION NOTES:
-- 1. Date Functions by Database:
--    SQLite/MySQL: STRFTIME('%Y', date_column)
--    PostgreSQL: EXTRACT(YEAR FROM date_column)
--    SQL Server: YEAR(date_column)
--    Oracle: EXTRACT(YEAR FROM date_column)
-- 2. Replace 'BillingCountry' with your grouping dimension
-- 3. Add/remove CASE statements for different pivot values
-- 4. Change aggregation function (SUM, COUNT, AVG) as needed
-- 5. Consider NULL handling with COALESCE for cleaner output

/*
================================================================================
SNIPPET 4: FIRST AND LAST EVENT ANALYSIS
================================================================================

BUSINESS USE CASE:
Track customer journey milestones, lifecycle events, and temporal patterns.
Critical for understanding customer acquisition, retention, and behavior patterns.
Essential for cohort analysis and customer segmentation.

TECHNIQUE:
Uses MIN/MAX with window functions or GROUP BY to identify first/last occurrences.
Can be extended for nth occurrence or event sequences.

EXAMPLE APPLICATIONS:
- Customer acquisition and last purchase dates
- First/last interaction by channel
- Product adoption timelines
- Support ticket patterns
================================================================================
*/

-- Find the date of the first and last purchase for each customer
SELECT
    c.FirstName + ' ' + c.LastName AS CustomerName,  -- SQL Server syntax
    MIN(i.InvoiceDate) AS FirstPurchase,
    MAX(i.InvoiceDate) AS LastPurchase,
    COUNT(i.InvoiceId) AS TotalPurchases,
    JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)) AS DaysBetweenFirstLast
FROM
    customers c
JOIN
    invoices i ON c.CustomerId = i.CustomerId
GROUP BY
    c.CustomerId, c.FirstName, c.LastName
ORDER BY
    FirstPurchase;

-- ADAPTATION NOTES:
-- 1. Replace JULIANDAY() with your database's date difference function:
--    PostgreSQL: date2 - date1
--    SQL Server: DATEDIFF(day, date1, date2)
--    MySQL: DATEDIFF(date2, date1)
-- 2. Add WHERE clauses for date range filtering
-- 3. Use window functions for more complex event sequences
-- 4. Consider using FIRST_VALUE/LAST_VALUE for additional event details

/*
================================================================================
SNIPPET 5: DATE SERIES GENERATION
================================================================================

BUSINESS USE CASE:
Create complete date ranges for time series analysis, gap filling, and reporting.
Essential for ensuring consistent time periods in dashboards and trend analysis,
even when data is missing for certain dates.

TECHNIQUE:
Uses recursive CTEs to generate continuous date sequences.
Can be adapted for different intervals (days, weeks, months).

EXAMPLE APPLICATIONS:
- Fill gaps in daily sales reports
- Create calendar tables for reporting
- Generate month/quarter series for budgeting
- Ensure complete time series for visualizations
================================================================================
*/

-- Create a complete list of dates for a given month
WITH RECURSIVE DateSeries AS (
    -- Base case: start date
    SELECT DATE('2023-01-01') AS SeriesDate
    
    UNION ALL
    
    -- Recursive case: add one day
    SELECT DATE(SeriesDate, '+1 day')
    FROM DateSeries
    WHERE SeriesDate < DATE('2023-01-31')
)
SELECT 
    SeriesDate,
    STRFTIME('%w', SeriesDate) AS DayOfWeek,
    STRFTIME('%W', SeriesDate) AS WeekOfYear
FROM DateSeries
ORDER BY SeriesDate;

-- Alternative: Generate monthly series for business planning
WITH RECURSIVE MonthSeries AS (
    SELECT DATE('2023-01-01') AS MonthStart
    UNION ALL
    SELECT DATE(MonthStart, '+1 month')
    FROM MonthSeries
    WHERE MonthStart < DATE('2023-12-01')
)
SELECT 
    MonthStart,
    STRFTIME('%Y-%m', MonthStart) AS YearMonth,
    STRFTIME('%m', MonthStart) AS MonthNumber
FROM MonthSeries;

-- ADAPTATION NOTES:
-- 1. Recursive CTE syntax varies by database:
--    PostgreSQL: WITH RECURSIVE name AS (...)
--    SQL Server: WITH name AS (...) 
--    Oracle: Use CONNECT BY LEVEL instead
-- 2. Date functions vary:
--    SQLite: DATE(date, '+1 day')
--    PostgreSQL: date + INTERVAL '1 day'
--    SQL Server: DATEADD(day, 1, date)
-- 3. Adjust start/end dates for your analysis period
-- 4. Consider performance limits on large date ranges

/*
================================================================================
SNIPPET 6: SESSION-BASED ANALYTICS
================================================================================

BUSINESS USE CASE:
Analyze user behavior patterns, engagement sessions, and activity clustering.
Critical for understanding user engagement, session duration, and behavior flows.
Common in web analytics, app usage analysis, and customer journey mapping.

TECHNIQUE:
Uses LAG window function to identify session breaks based on time gaps,
then groups activities into logical sessions for analysis.

EXAMPLE APPLICATIONS:
- Website session analysis
- Customer purchase sessions
- Support ticket clustering
- User engagement patterns
================================================================================
*/

-- Group customer purchases into sessions (30+ minutes apart = new session)
WITH CustomerSessions AS (
    SELECT
        CustomerId,
        InvoiceDate,
        Total,
        -- Check if this purchase is more than 30 minutes after the previous one
        CASE 
            WHEN JULIANDAY(InvoiceDate) - JULIANDAY(LAG(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate)) > (30.0/1440.0) 
                OR LAG(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) IS NULL
            THEN 1 
            ELSE 0 
        END AS NewSession
    FROM invoices
),
SessionNumbers AS (
    SELECT
        CustomerId,
        InvoiceDate,
        Total,
        SUM(NewSession) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS SessionNumber
    FROM CustomerSessions
)
SELECT
    CustomerId,
    SessionNumber,
    COUNT(*) AS PurchasesInSession,
    SUM(Total) AS SessionRevenue,
    MIN(InvoiceDate) AS SessionStart,
    MAX(InvoiceDate) AS SessionEnd
FROM SessionNumbers
GROUP BY CustomerId, SessionNumber
ORDER BY CustomerId, SessionNumber;

-- ADAPTATION NOTES:
-- 1. Adjust session timeout: 30.0/1440.0 = 30 minutes (1440 minutes in a day)
-- 2. Replace JULIANDAY with your database's date arithmetic
-- 3. Modify session definition criteria as needed
-- 4. Add additional session metrics (duration, page views, etc.)
-- 5. Consider using LEAD for forward-looking session analysis

/*
================================================================================
SNIPPET 7: CUSTOMER LIFETIME VALUE (CLV) CALCULATION
================================================================================

BUSINESS USE CASE:
Calculate comprehensive customer value metrics for segmentation, targeting,
and retention strategies. Essential for understanding customer profitability
and making data-driven marketing and service decisions.

TECHNIQUE:
Combines aggregation, date arithmetic, and business logic calculations
to derive meaningful customer value indicators and behavioral patterns.

EXAMPLE APPLICATIONS:
- Customer segmentation for marketing
- Retention program targeting
- Sales performance analysis
- Revenue forecasting and planning
================================================================================
*/

-- Calculate comprehensive customer lifetime value metrics
SELECT
    c.CustomerId,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.Country,
    COUNT(i.InvoiceId) AS TotalOrders,
    SUM(i.Total) AS TotalRevenue,
    AVG(i.Total) AS AverageOrderValue,
    MIN(i.InvoiceDate) AS FirstPurchase,
    MAX(i.InvoiceDate) AS LastPurchase,
    -- Calculate customer lifespan in days
    JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)) AS CustomerLifespanDays,
    -- Calculate purchase frequency (orders per month)
    CASE 
        WHEN JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)) > 0 
        THEN COUNT(i.InvoiceId) * 30.0 / (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)))
        ELSE COUNT(i.InvoiceId)
    END AS PurchaseFrequencyPerMonth,
    -- Customer value score (revenue * frequency weight)
    SUM(i.Total) * 
    CASE 
        WHEN COUNT(i.InvoiceId) > 5 THEN 1.5  -- High frequency bonus
        WHEN COUNT(i.InvoiceId) > 2 THEN 1.2  -- Medium frequency bonus
        ELSE 1.0
    END AS CustomerValueScore
FROM
    customers c
JOIN
    invoices i ON c.CustomerId = i.CustomerId
GROUP BY
    c.CustomerId, c.FirstName, c.LastName, c.Country
HAVING
    COUNT(i.InvoiceId) >= 1  -- Only customers with at least one purchase
ORDER BY
    CustomerValueScore DESC;

-- ADAPTATION NOTES:
-- 1. Adjust frequency thresholds and multipliers for your business
-- 2. Replace JULIANDAY with appropriate date functions for your database
-- 3. Add recency factors for more sophisticated CLV models
-- 4. Consider seasonal adjustments for purchase patterns
-- 5. Include cost data for profit-based CLV calculations
-- 6. Add customer acquisition date for cohort analysis
