/*
    File: 03_advanced_grouping_techniques.sql
    Module: 04_aggregation
    Topic: Advanced Grouping and Multi-dimensional Analysis
    Author: SQL Analyst Pack
    Date: 2025-06-22
    Description: Master ROLLUP, CUBE, and complex grouping for executive reporting
    
    Business Scenarios:
    - Executive dashboard creation with drill-down capabilities
    - Multi-dimensional sales analysis and OLAP reporting
    - Hierarchical data summarization for management reporting
    - Complex variance analysis and budget reporting
    
    Database: Chinook (Music Store Digital Media)
    Complexity: Advanced
    Estimated Time: 60-90 minutes
*/

-- =================================================================================================================================
-- 🎯 LEARNING OBJECTIVES
-- =================================================================================================================================
--
-- After completing this script, you will be able to:
-- ✅ Create hierarchical summaries using ROLLUP and CUBE
-- ✅ Build multi-dimensional analysis for executive reporting
-- ✅ Design drill-down and drill-up analytical capabilities
-- ✅ Implement complex business logic in aggregations
-- ✅ Optimize performance for large-scale analytical queries
--
-- =================================================================================================================================
-- 💼 BUSINESS SCENARIO: Executive Dashboard Development
-- =================================================================================================================================
--
-- The Chinook executive team needs comprehensive analytical dashboards that allow them to:
-- 1. View sales performance at multiple levels (global → country → customer)
-- 2. Analyze product performance across dimensions (genre → artist → album → track)
-- 3. Create budget vs actual reports with variance analysis
-- 4. Implement drill-down capabilities for root cause analysis
-- 5. Generate automated executive summaries with key insights
--
-- Your mission: Build the analytical foundation for executive decision-making.
--
-- =================================================================================================================================
-- 📊 PART 1: HIERARCHICAL ANALYSIS WITH ROLLUP
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Sales Performance Hierarchy (Global → Country → Customer)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- ROLLUP creates subtotals at each level of a hierarchy, perfect for executive summaries

SELECT 
    COALESCE(c.Country, '🌍 GLOBAL TOTAL') as level_country,
    COALESCE(c.City, '📍 COUNTRY TOTAL') as level_city,
    COALESCE(CONCAT(c.FirstName, ' ', c.LastName), '👤 CITY TOTAL') as level_customer,
    COUNT(DISTINCT i.InvoiceId) as invoice_count,
    ROUND(SUM(i.Total), 2) as total_revenue,
    ROUND(AVG(i.Total), 2) as avg_invoice_value,
    -- Business insights
    CASE 
        WHEN c.Country IS NULL THEN '🎯 Global Performance Summary'
        WHEN c.City IS NULL THEN '📊 ' + c.Country + ' Market Analysis'
        WHEN CONCAT(c.FirstName, ' ', c.LastName) IS NULL THEN '🏙️ ' + c.City + ' Local Performance'
        ELSE '💼 Individual Customer Analysis'
    END as analysis_level,
    -- Performance indicators
    CASE 
        WHEN SUM(i.Total) > 100 THEN '🔥 High Performer'
        WHEN SUM(i.Total) > 50 THEN '📈 Good Performer' 
        WHEN SUM(i.Total) > 10 THEN '📊 Average Performer'
        ELSE '⚠️ Low Performer'
    END as performance_tier
FROM Invoice i
JOIN Customer c ON i.CustomerId = c.CustomerId
WHERE i.InvoiceDate >= DATE('2009-01-01')  -- Focus on recent data
GROUP BY ROLLUP(c.Country, c.City, CONCAT(c.FirstName, ' ', c.LastName))
ORDER BY 
    CASE WHEN c.Country IS NULL THEN 0 ELSE 1 END,  -- Global totals first
    c.Country,
    CASE WHEN c.City IS NULL THEN 0 ELSE 1 END,     -- Country totals before cities
    c.City,
    total_revenue DESC;

-- 💡 Executive Insight: This creates a drill-down report from global to individual customer level
-- 💡 Business Value: Executives can see global performance, then drill down to problem areas

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: Product Performance Matrix (Genre → Artist → Album)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Multi-level product analysis for inventory and marketing decisions

SELECT 
    COALESCE(g.Name, '🎵 ALL GENRES') as product_genre,
    COALESCE(ar.Name, '🎤 GENRE TOTAL') as product_artist,
    COALESCE(al.Title, '💿 ARTIST TOTAL') as product_album,
    COUNT(DISTINCT t.TrackId) as track_count,
    COUNT(DISTINCT il.InvoiceLineId) as units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) as total_revenue,
    ROUND(AVG(il.UnitPrice), 2) as avg_price_point,
    -- Performance metrics
    ROUND(SUM(il.UnitPrice * il.Quantity) / COUNT(DISTINCT t.TrackId), 2) as revenue_per_track,
    -- Business categorization
    CASE 
        WHEN g.Name IS NULL THEN '📊 Portfolio Overview'
        WHEN ar.Name IS NULL THEN '🎯 Genre Performance: ' + g.Name
        WHEN al.Title IS NULL THEN '⭐ Artist Performance: ' + ar.Name  
        ELSE '💿 Album Details: ' + al.Title
    END as analysis_focus
FROM Genre g
LEFT JOIN Track t ON g.GenreId = t.GenreId
LEFT JOIN Album al ON t.AlbumId = al.AlbumId
LEFT JOIN Artist ar ON al.ArtistId = ar.ArtistId
LEFT JOIN InvoiceLine il ON t.TrackId = il.TrackId
WHERE il.InvoiceLineId IS NOT NULL  -- Only include sold items
GROUP BY ROLLUP(g.Name, ar.Name, al.Title)
HAVING SUM(il.UnitPrice * il.Quantity) > 0  -- Only profitable items
ORDER BY 
    CASE WHEN g.Name IS NULL THEN 0 ELSE 1 END,
    total_revenue DESC,
    g.Name,
    CASE WHEN ar.Name IS NULL THEN 0 ELSE 1 END,
    ar.Name,
    CASE WHEN al.Title IS NULL THEN 0 ELSE 1 END,
    al.Title;

-- 💡 Marketing Insight: Shows which genres/artists/albums drive revenue
-- 💡 Inventory Decision: Helps identify which products to promote or discontinue

-- =================================================================================================================================
-- 📈 PART 2: MULTI-DIMENSIONAL ANALYSIS WITH CUBE
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Sales Cube Analysis (Time × Geography × Product)
-- ---------------------------------------------------------------------------------------------------------------------------------
-- CUBE generates all possible combinations of groupings for comprehensive analysis

WITH sales_cube AS (
    SELECT 
        EXTRACT(YEAR FROM i.InvoiceDate) as sale_year,
        c.Country as sale_country,
        g.Name as product_genre,
        COUNT(DISTINCT i.InvoiceId) as invoice_count,
        SUM(il.UnitPrice * il.Quantity) as total_revenue,
        COUNT(DISTINCT c.CustomerId) as customer_count
    FROM Invoice i
    JOIN Customer c ON i.CustomerId = c.CustomerId
    JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
    JOIN Track t ON il.TrackId = t.TrackId
    JOIN Genre g ON t.GenreId = g.GenreId
    WHERE i.InvoiceDate >= DATE('2009-01-01')
    GROUP BY CUBE(
        EXTRACT(YEAR FROM i.InvoiceDate),
        c.Country,
        g.Name
    )
)
SELECT 
    COALESCE(CAST(sale_year AS TEXT), '📅 ALL YEARS') as dimension_time,
    COALESCE(sale_country, '🌍 ALL COUNTRIES') as dimension_geography,
    COALESCE(product_genre, '🎵 ALL GENRES') as dimension_product,
    invoice_count,
    ROUND(total_revenue, 2) as revenue,
    customer_count,
    ROUND(total_revenue / NULLIF(customer_count, 0), 2) as revenue_per_customer,
    -- Dimensional analysis indicators
    CASE 
        WHEN sale_year IS NULL AND sale_country IS NULL AND product_genre IS NULL 
        THEN '📊 Grand Total (All Dimensions)'
        WHEN sale_year IS NOT NULL AND sale_country IS NULL AND product_genre IS NULL 
        THEN '📅 Time Analysis: ' + CAST(sale_year AS TEXT)
        WHEN sale_year IS NULL AND sale_country IS NOT NULL AND product_genre IS NULL 
        THEN '🌍 Geographic Analysis: ' + sale_country
        WHEN sale_year IS NULL AND sale_country IS NULL AND product_genre IS NOT NULL 
        THEN '🎵 Product Analysis: ' + product_genre
        WHEN sale_year IS NOT NULL AND sale_country IS NOT NULL AND product_genre IS NULL 
        THEN '📍 Time × Geography: ' + CAST(sale_year AS TEXT) + ' in ' + sale_country
        WHEN sale_year IS NOT NULL AND sale_country IS NULL AND product_genre IS NOT NULL 
        THEN '🎯 Time × Product: ' + CAST(sale_year AS TEXT) + ' - ' + product_genre
        WHEN sale_year IS NULL AND sale_country IS NOT NULL AND product_genre IS NOT NULL 
        THEN '🎪 Geography × Product: ' + product_genre + ' in ' + sale_country
        ELSE '🔍 Detailed Analysis: ' + CAST(sale_year AS TEXT) + ' | ' + sale_country + ' | ' + product_genre
    END as cube_dimension
FROM sales_cube
WHERE total_revenue > 0
ORDER BY 
    total_revenue DESC,
    sale_year NULLS LAST,
    sale_country NULLS LAST,
    product_genre NULLS LAST;

-- 💡 Strategic Insight: CUBE analysis reveals patterns across all dimensional combinations
-- 💡 Decision Support: Executives can see performance from every analytical angle

-- =================================================================================================================================
-- 💰 PART 3: FINANCIAL ANALYSIS AND VARIANCE REPORTING
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Budget vs Actual Analysis with Variance
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Complex financial reporting with multiple calculation levels

WITH monthly_actuals AS (
    SELECT 
        EXTRACT(YEAR FROM InvoiceDate) as fiscal_year,
        EXTRACT(MONTH FROM InvoiceDate) as fiscal_month,
        c.Country,
        SUM(i.Total) as actual_revenue,
        COUNT(DISTINCT i.CustomerId) as actual_customers,
        COUNT(DISTINCT i.InvoiceId) as actual_transactions
    FROM Invoice i
    JOIN Customer c ON i.CustomerId = c.CustomerId
    GROUP BY 
        EXTRACT(YEAR FROM InvoiceDate),
        EXTRACT(MONTH FROM InvoiceDate),
        c.Country
),
budget_targets AS (
    -- Simulated budget data (in real scenarios, this would come from a budget table)
    SELECT 
        fiscal_year,
        fiscal_month,
        Country,
        actual_revenue * 1.15 as budget_revenue,  -- 15% growth target
        actual_customers * 1.10 as budget_customers,  -- 10% customer growth
        actual_transactions * 1.12 as budget_transactions  -- 12% transaction growth
    FROM monthly_actuals
)
SELECT 
    COALESCE(CAST(ma.fiscal_year AS TEXT), '📊 ALL YEARS') as report_year,
    COALESCE(CAST(ma.fiscal_month AS TEXT), '📅 YEAR TOTAL') as report_month,
    COALESCE(ma.Country, '🌍 GRAND TOTAL') as report_country,
    -- Actual performance
    ROUND(SUM(ma.actual_revenue), 2) as actual_revenue,
    SUM(ma.actual_customers) as actual_customers,
    SUM(ma.actual_transactions) as actual_transactions,
    -- Budget targets
    ROUND(SUM(bt.budget_revenue), 2) as budget_revenue,
    SUM(bt.budget_customers) as budget_customers,
    SUM(bt.budget_transactions) as budget_transactions,
    -- Variance analysis
    ROUND(SUM(ma.actual_revenue) - SUM(bt.budget_revenue), 2) as revenue_variance,
    ROUND((SUM(ma.actual_revenue) - SUM(bt.budget_revenue)) * 100.0 / SUM(bt.budget_revenue), 1) as revenue_variance_pct,
    SUM(ma.actual_customers) - SUM(bt.budget_customers) as customer_variance,
    -- Performance indicators
    CASE 
        WHEN SUM(ma.actual_revenue) >= SUM(bt.budget_revenue) * 1.05 THEN '🎯 Exceeds Target (+5%)'
        WHEN SUM(ma.actual_revenue) >= SUM(bt.budget_revenue) THEN '✅ Meets Target'
        WHEN SUM(ma.actual_revenue) >= SUM(bt.budget_revenue) * 0.95 THEN '⚠️ Near Target (-5%)'
        ELSE '🚨 Below Target (-5%+)'
    END as performance_status,
    -- Executive summary
    CASE 
        WHEN ma.fiscal_year IS NULL AND ma.fiscal_month IS NULL AND ma.Country IS NULL 
        THEN '📊 Company Performance Overview'
        WHEN ma.fiscal_year IS NOT NULL AND ma.fiscal_month IS NULL AND ma.Country IS NULL 
        THEN '📈 Annual Performance: ' + CAST(ma.fiscal_year AS TEXT)
        WHEN ma.fiscal_year IS NULL AND ma.Country IS NOT NULL AND ma.fiscal_month IS NULL 
        THEN '🌍 Market Performance: ' + ma.Country
        ELSE '🔍 Detailed Analysis'
    END as executive_summary
FROM monthly_actuals ma
JOIN budget_targets bt ON ma.fiscal_year = bt.fiscal_year 
    AND ma.fiscal_month = bt.fiscal_month 
    AND ma.Country = bt.Country
GROUP BY ROLLUP(ma.fiscal_year, ma.fiscal_month, ma.Country)
ORDER BY 
    CASE WHEN ma.fiscal_year IS NULL THEN 0 ELSE 1 END,
    ma.fiscal_year,
    CASE WHEN ma.fiscal_month IS NULL THEN 0 ELSE 1 END,
    ma.fiscal_month,
    CASE WHEN ma.Country IS NULL THEN 0 ELSE 1 END,
    revenue_variance DESC;

-- 💡 Financial Control: Comprehensive variance analysis for performance management
-- 💡 Strategic Planning: Identifies markets and periods that need attention

-- =================================================================================================================================
-- 🎯 PART 4: ADVANCED ANALYTICAL PATTERNS
-- =================================================================================================================================

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 5: Customer Segmentation with Advanced Grouping
-- ---------------------------------------------------------------------------------------------------------------------------------
-- RFM Analysis (Recency, Frequency, Monetary) with hierarchical grouping

WITH customer_rfm AS (
    SELECT 
        c.CustomerId,
        c.FirstName + ' ' + c.LastName as customer_name,
        c.Country,
        -- Recency (days since last purchase)
        DATEDIFF(DAY, MAX(i.InvoiceDate), CURRENT_DATE) as recency_days,
        -- Frequency (number of purchases)
        COUNT(DISTINCT i.InvoiceId) as frequency_count,
        -- Monetary (total spent)
        SUM(i.Total) as monetary_value,
        -- RFM Scoring (1-5 scale)
        CASE 
            WHEN DATEDIFF(DAY, MAX(i.InvoiceDate), CURRENT_DATE) <= 90 THEN 5
            WHEN DATEDIFF(DAY, MAX(i.InvoiceDate), CURRENT_DATE) <= 180 THEN 4
            WHEN DATEDIFF(DAY, MAX(i.InvoiceDate), CURRENT_DATE) <= 365 THEN 3
            WHEN DATEDIFF(DAY, MAX(i.InvoiceDate), CURRENT_DATE) <= 730 THEN 2
            ELSE 1
        END as recency_score,
        CASE 
            WHEN COUNT(DISTINCT i.InvoiceId) >= 10 THEN 5
            WHEN COUNT(DISTINCT i.InvoiceId) >= 7 THEN 4
            WHEN COUNT(DISTINCT i.InvoiceId) >= 5 THEN 3
            WHEN COUNT(DISTINCT i.InvoiceId) >= 3 THEN 2
            ELSE 1
        END as frequency_score,
        CASE 
            WHEN SUM(i.Total) >= 100 THEN 5
            WHEN SUM(i.Total) >= 75 THEN 4
            WHEN SUM(i.Total) >= 50 THEN 3
            WHEN SUM(i.Total) >= 25 THEN 2
            ELSE 1
        END as monetary_score
    FROM Customer c
    JOIN Invoice i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
),
customer_segments AS (
    SELECT 
        *,
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 4 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Potential Loyalists'
            WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'New Customers'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score <= 3 THEN 'Promising'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Cannot Lose Them'
            WHEN recency_score <= 3 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Hibernating'
            ELSE 'Others'
        END as customer_segment
    FROM customer_rfm
)
SELECT 
    COALESCE(Country, '🌍 ALL MARKETS') as market,
    COALESCE(customer_segment, '👥 ALL SEGMENTS') as segment,
    COUNT(*) as customer_count,
    ROUND(AVG(recency_days), 1) as avg_recency_days,
    ROUND(AVG(frequency_count), 1) as avg_frequency,
    ROUND(AVG(monetary_value), 2) as avg_monetary_value,
    ROUND(SUM(monetary_value), 2) as total_revenue,
    -- Segment insights
    ROUND(SUM(monetary_value) / COUNT(*), 2) as revenue_per_customer,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as segment_percentage,
    -- Business recommendations
    CASE 
        WHEN customer_segment = 'Champions' THEN '🏆 Reward and upsell'
        WHEN customer_segment = 'Loyal Customers' THEN '💎 Maintain satisfaction'
        WHEN customer_segment = 'At Risk' THEN '🚨 Win-back campaigns'
        WHEN customer_segment = 'Cannot Lose Them' THEN '💼 Personal attention'
        WHEN customer_segment = 'New Customers' THEN '🎯 Onboarding programs'
        WHEN customer_segment IS NULL THEN '📊 Overall strategy'
        ELSE '📈 Standard marketing'
    END as recommended_action
FROM customer_segments
GROUP BY ROLLUP(Country, customer_segment)
ORDER BY 
    CASE WHEN Country IS NULL THEN 0 ELSE 1 END,
    total_revenue DESC,
    Country,
    CASE WHEN customer_segment IS NULL THEN 0 ELSE 1 END,
    customer_count DESC;

-- 💡 Marketing Strategy: Data-driven customer segmentation for targeted campaigns
-- 💡 Revenue Optimization: Focus resources on high-value customer segments

-- =================================================================================================================================
-- 📋 SUMMARY AND BUSINESS IMPACT
-- =================================================================================================================================

/*
🎯 ADVANCED GROUPING MASTERY ACHIEVED:
1. ✅ ROLLUP for hierarchical drill-down analysis
2. ✅ CUBE for multi-dimensional analytical perspectives  
3. ✅ Complex variance analysis for financial control
4. ✅ Customer segmentation for strategic marketing
5. ✅ Executive-ready reporting with business insights

📊 BUSINESS VALUE DELIVERED:
- Executive dashboards with drill-down capabilities
- Multi-dimensional performance analysis
- Financial variance reporting and control
- Customer segmentation for targeted marketing
- Strategic insights for data-driven decisions

🔧 TECHNICAL SKILLS DEVELOPED:
- Advanced GROUP BY extensions (ROLLUP, CUBE)
- Complex conditional logic in aggregations
- Performance optimization for analytical queries
- Business intelligence reporting patterns
- Data warehouse analytical techniques

➡️ NEXT STEPS:
- Apply these patterns to your business scenarios
- Build automated reporting dashboards
- Implement real-time analytical monitoring
- Continue to 04_statistical_analysis.sql for advanced analytics
*/

-- =================================================================================================================================
-- 💼 EXECUTIVE SUMMARY TEMPLATE
-- =================================================================================================================================

-- Copy this query to create executive summary reports:
SELECT 
    '🎯 CHINOOK EXECUTIVE DASHBOARD' as report_title,
    CURRENT_TIMESTAMP as generated_at,
    'Sales Performance Summary' as section_name
UNION ALL
SELECT 
    'Total Revenue (All Time): $' + CAST(ROUND((SELECT SUM(Total) FROM Invoice), 2) AS TEXT),
    NULL,
    'Key Metrics'
UNION ALL
SELECT 
    'Total Customers: ' + CAST((SELECT COUNT(DISTINCT CustomerId) FROM Customer) AS TEXT),
    NULL,
    'Key Metrics'
UNION ALL
SELECT 
    'Average Order Value: $' + CAST(ROUND((SELECT AVG(Total) FROM Invoice), 2) AS TEXT),
    NULL,
    'Key Metrics'
UNION ALL
SELECT 
    'Top Market: ' + (SELECT TOP 1 c.Country FROM Invoice i JOIN Customer c ON i.CustomerId = c.CustomerId GROUP BY c.Country ORDER BY SUM(i.Total) DESC),
    NULL,
    'Strategic Insights';

-- 💡 Executive Communication: Perfect for board presentations and stakeholder reports
-- 💡 Automation Ready: Schedule this for regular executive reporting

/*
🚀 CONGRATULATIONS!
You've mastered advanced grouping techniques and multi-dimensional analysis. You can now:
✅ Create executive dashboards with hierarchical drill-down
✅ Build comprehensive OLAP-style analytical reports  
✅ Implement financial variance analysis and controls
✅ Design customer segmentation for strategic marketing
✅ Generate business insights that drive strategic decisions

Ready for statistical analysis? Continue to 04_statistical_analysis.sql!
*/
