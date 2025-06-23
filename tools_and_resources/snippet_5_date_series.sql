-- Snippet 5: Generate a Date Series (Recursive CTE)

-- Use Case: Create a complete list of dates for a given month, useful for filling gaps in time-series data.
-- Technique: Use a recursive CTE to generate a series of dates.

-- SQLite / PostgreSQL / SQL Server / MySQL 8.0+
WITH DateSeries(Date) AS (
    -- Anchor: Start of the series
    SELECT '2023-01-01'
    UNION ALL
    -- Recursive part: Add one day until the end condition is met
    SELECT DATEADD(day, 1, Date)
    FROM DateSeries
    WHERE Date < '2023-01-31'
)
SELECT Date FROM DateSeries;

-- Note on Date Functions:
-- `DATEADD(day, 1, Date)` is SQL Server syntax.
-- PostgreSQL: `Date + INTERVAL '1 day'`
-- SQLite: `DATE(Date, '+1 day')`
