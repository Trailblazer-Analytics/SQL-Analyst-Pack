/*
================================================================================
File: tools_and_resources/snippet_7_customer_lifetime_value.sql
Topic: Customer Lifetime Value (CLV) Analysis
Purpose: Calculate comprehensive customer value metrics for retention and marketing
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Updated: 2025-06-23
================================================================================

BUSINESS USE CASE:
Essential for customer relationship management, marketing campaign targeting,
and retention strategy. Helps identify high-value customers, optimize marketing
spend, and predict future revenue from customer base.

TECHNIQUE:
Combines multiple aggregations (SUM, COUNT, AVG) to calculate total spend,
purchase frequency, average order value, and derived CLV metrics.

SQL COMPATIBILITY:
✅ All major SQL databases (uses standard aggregation functions)
⚠️ Date functions may need adjustment for specific databases
================================================================================
*/

-- Snippet 7: Calculate Customer Lifetime Value (CLV)

-- Use Case: Calculate total revenue, average order value, and purchase frequency per customer.
-- Technique: Combine multiple aggregations to create a comprehensive customer analysis.

SELECT
    c.CustomerId,
    c.FirstName,
    c.LastName,
    c.Country,
    COUNT(DISTINCT i.InvoiceId) AS TotalOrders,
    SUM(i.Total) AS TotalRevenue,
    AVG(i.Total) AS AverageOrderValue,
    MIN(i.InvoiceDate) AS FirstPurchaseDate,
    MAX(i.InvoiceDate) AS LastPurchaseDate,
    -- Calculate days between first and last purchase
    CASE 
        WHEN COUNT(DISTINCT i.InvoiceId) > 1 
        THEN (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)))
        ELSE 0 
    END AS CustomerLifespanDays,
    -- Calculate purchase frequency (orders per year)
    CASE 
        WHEN COUNT(DISTINCT i.InvoiceId) > 1 AND 
             (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate))) > 0
        THEN (COUNT(DISTINCT i.InvoiceId) * 365.0) / 
             (JULIANDAY(MAX(i.InvoiceDate)) - JULIANDAY(MIN(i.InvoiceDate)))
        ELSE COUNT(DISTINCT i.InvoiceId)
    END AS OrdersPerYear
FROM
    customers c
LEFT JOIN
    invoices i ON c.CustomerId = i.CustomerId
GROUP BY
    c.CustomerId, c.FirstName, c.LastName, c.Country
HAVING
    COUNT(DISTINCT i.InvoiceId) > 0  -- Only customers with purchases
ORDER BY
    TotalRevenue DESC;

-- This comprehensive customer analysis helps identify:
-- - High-value customers (by total revenue)
-- - Frequent buyers (by orders per year)
-- - Recent vs. long-term customers (by purchase dates)
-- - Geographic patterns (by country)
