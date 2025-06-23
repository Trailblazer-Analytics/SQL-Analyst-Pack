/*
================================================================================
File: tools_and_resources/snippet_2_running_totals.sql
Topic: Running Totals and Cumulative Calculations
Purpose: Calculate cumulative sums, running averages, and progressive metrics
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Updated: 2025-06-23
================================================================================

BUSINESS USE CASE:
Critical for financial analysis, growth tracking, and trend analysis.
Shows progressive accumulation of values over time - perfect for revenue tracking,
budget analysis, and performance monitoring.

TECHNIQUE:
Uses SUM() OVER() with ORDER BY to create cumulative calculations.
Can be adapted for running averages, counts, and other progressive metrics.

SQL COMPATIBILITY:
✅ PostgreSQL, SQL Server, Oracle, MySQL 8.0+, SQLite 3.25+
⚠️ Older MySQL versions need variable-based approach
================================================================================
*/

-- Snippet 2: Calculate Running Totals

-- Use Case: Calculate the cumulative monthly revenue over the entire history of the store.
-- Technique: Use `SUM() OVER()` with an `ORDER BY` clause to create a cumulative sum.

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
    SUM(MonthlyTotal) OVER (ORDER BY InvoiceMonth) AS RunningTotalRevenue
FROM
    MonthlyRevenue
ORDER BY
    InvoiceMonth;
