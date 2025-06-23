/*
    File: 04_lag_lead_and_value_comparisons.sql
    Topic: Window Functions
    Task: LAG, LEAD, and Value Comparisons
    Author: GitHub Copilot
    Date: 2024-07-15
    SQL Flavor: ANSI SQL
*/

-- =================================================================================================================================
-- Introduction to LAG and LEAD
-- =================================================================================================================================
--
-- `LAG` and `LEAD` are powerful window functions that allow you to access data from other rows in your result set
-- relative to the current row. This is extremely useful for making comparisons between rows, such as calculating
-- period-over-period changes.
--
-- - `LAG(column, offset, default)`: Accesses data from a *previous* row in the partition. `offset` is the number of rows to
--   look back (default is 1), and `default` is the value to return if the offset is outside the partition.
--
-- - `LEAD(column, offset, default)`: Accesses data from a *subsequent* row in the partition.
--
-- Both functions require an `ORDER BY` clause within the `OVER()` clause to establish a clear sequence of rows.
--
-- =================================================================================================================================
-- Step 1: Using `LAG` to Look at Previous Values
-- =================================================================================================================================
--
-- `LAG` is perfect for comparing a current value to a previous one, like calculating month-over-month growth.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 1: Find the previous invoice total for each customer
-- ---------------------------------------------------------------------------------------------------------------------------------
-- We partition by customer and order by date to create a chronological sequence of invoices for each customer.
-- `LAG(Total, 1, 0)` will get the `Total` from the previous row. If there is no previous row (i.e., it's the first invoice),
-- it will return the default value of 0.

SELECT
    CustomerId,
    InvoiceDate,
    Total AS CurrentInvoiceTotal,
    LAG(Total, 1, 0) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS PreviousInvoiceTotal
FROM
    invoices
ORDER BY
    CustomerId, InvoiceDate;

-- =================================================================================================================================
-- Step 2: Using `LEAD` to Look at Subsequent Values
-- =================================================================================================================================
--
-- `LEAD` is useful for seeing what happens *after* the current row. For example, calculating the time until the next event.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 2: For each invoice, show the date of the *next* invoice for that customer
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Here, we use `LEAD` on the `InvoiceDate` column itself.

SELECT
    CustomerId,
    InvoiceDate AS CurrentInvoiceDate,
    LEAD(InvoiceDate, 1) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS NextInvoiceDate
FROM
    invoices
ORDER BY
    CustomerId, InvoiceDate;

-- =================================================================================================================================
-- Step 3: Performing Calculations with `LAG` and `LEAD`
-- =================================================================================================================================
--
-- The real power of these functions comes from using their results in calculations.

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 3: Calculate the percentage change in sales from one month to the next
-- ---------------------------------------------------------------------------------------------------------------------------------
-- First, we aggregate sales into monthly totals.
WITH MonthlySales AS (
    SELECT
        strftime('%Y-%m-01', InvoiceDate) AS SalesMonth,
        SUM(Total) AS MonthlyTotal
    FROM
        invoices
    GROUP BY
        SalesMonth
),
-- Then, we use LAG to get the previous month's sales.
MonthlySalesWithLag AS (
    SELECT
        SalesMonth,
        MonthlyTotal,
        LAG(MonthlyTotal, 1, 0) OVER (ORDER BY SalesMonth) AS PreviousMonthTotal
    FROM
        MonthlySales
)
-- Finally, we calculate the percentage change.
SELECT
    SalesMonth,
    MonthlyTotal,
    PreviousMonthTotal,
    -- Avoid division by zero if PreviousMonthTotal is 0
    CASE
        WHEN PreviousMonthTotal = 0 THEN NULL
        ELSE (MonthlyTotal - PreviousMonthTotal) * 100.0 / PreviousMonthTotal
    END AS PercentageChange
FROM
    MonthlySalesWithLag
ORDER BY
    SalesMonth;

-- ---------------------------------------------------------------------------------------------------------------------------------
-- Example 4: Calculate the number of days between a customer's consecutive invoices
-- ---------------------------------------------------------------------------------------------------------------------------------
-- We can use `LEAD` to find the next invoice date and then use a date difference function.

SELECT
    CustomerId,
    InvoiceDate AS CurrentInvoiceDate,
    LEAD(InvoiceDate, 1) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS NextInvoiceDate,
    -- `julianday` is specific to SQLite for date differences. Other DBs have different functions (e.g., DATEDIFF in SQL Server).
    julianday(LEAD(InvoiceDate, 1) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate)) - julianday(InvoiceDate) AS DaysUntilNextInvoice
FROM
    invoices
ORDER BY
    CustomerId, InvoiceDate;

-- =================================================================================================================================
-- Practical Exercise
-- =================================================================================================================================

-- 1. For each employee, find out if their hire date was before or after their manager's hire date.
--    Hint: You need to join `employees` to itself to get the manager's hire date, then use LAG or LEAD if you want to compare with peers.
--    A simpler approach without LAG/LEAD is a self-join.
SELECT
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    e.HireDate AS EmployeeHireDate,
    m.FirstName || ' ' || m.LastName AS ManagerName,
    m.HireDate AS ManagerHireDate,
    CASE
        WHEN e.HireDate < m.HireDate THEN 'Hired Before Manager'
        WHEN e.HireDate > m.HireDate THEN 'Hired After Manager'
        ELSE 'Hired Same Day as Manager'
    END AS HireComparison
FROM
    employees e
LEFT JOIN
    employees m ON e.ReportsTo = m.EmployeeId
WHERE
    m.EmployeeId IS NOT NULL;

-- 2. Find the top 5 tracks that had the biggest percentage increase in sales from one invoice to the next.
--    This is a complex query that requires identifying individual track sales per invoice and then using LAG.
--    For simplicity, let's just calculate the change in invoice totals for customers.

WITH InvoiceChanges AS (
    SELECT
        CustomerId,
        InvoiceId,
        Total,
        LAG(Total, 1, 0) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS PreviousTotal
    FROM
        invoices
)
SELECT
    CustomerId,
    InvoiceId,
    Total,
    PreviousTotal,
    (Total - PreviousTotal) AS ChangeInTotal
FROM
    InvoiceChanges
ORDER BY
    ChangeInTotal DESC
LIMIT 10;

-- =================================================================================================================================
-- Conclusion
-- =================================================================================================================================
--
-- `LAG` and `LEAD` are essential tools for any analyst. They unlock the ability to perform powerful row-to-row
-- comparisons and calculations that would otherwise require complex and inefficient self-joins.
--
-- - Use `LAG` to look backwards in a sequence.
-- - Use `LEAD` to look forwards in a sequence.
-- - Always combine them with `PARTITION BY` and `ORDER BY` to correctly define the sequence.
--
-- This concludes our section on window functions. You now have the tools to perform sophisticated analysis
-- involving rankings, running totals, moving averages, and sequential comparisons.
--
-- =================================================================================================================================
