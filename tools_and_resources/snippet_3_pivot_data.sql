-- Snippet 3: Pivot Data (Conditional Aggregation)

-- Use Case: Show total sales for each country, with a separate column for each year.
-- Technique: Use an aggregate function (`SUM`) with a `CASE` statement for each column you want to create.

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

-- Note on Date Functions:
-- `STRFTIME('%Y', ...)` is for SQLite/MySQL. 
-- PostgreSQL: `EXTRACT(YEAR FROM ...)`
-- SQL Server: `YEAR(...)`
