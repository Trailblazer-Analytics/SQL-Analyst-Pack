-- Snippet 6: Calculating Session-like Data

-- Use Case: Group customer purchases into "sessions" where each session is defined as a series of
-- purchases made within 24 hours of the previous one.
-- Technique: Use `LAG` to find the time since the last purchase and a cumulative `SUM` to create a session ID.

WITH PurchaseGaps AS (
    SELECT
        CustomerId,
        InvoiceDate,
        -- Calculate hours since last purchase for this customer
        (JULIANDAY(InvoiceDate) - JULIANDAY(LAG(InvoiceDate, 1, InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate))) * 24 AS HoursSinceLastPurchase
    FROM
        invoices
),
SessionIdentifier AS (
    SELECT
        CustomerId,
        InvoiceDate,
        -- If the gap is > 24 hours, it's a new session. Create a flag.
        CASE WHEN HoursSinceLastPurchase > 24 THEN 1 ELSE 0 END AS IsNewSession
    FROM
        PurchaseGaps
)
SELECT
    CustomerId,
    InvoiceDate,
    -- The session ID is the cumulative sum of the IsNewSession flags.
    SUM(IsNewSession) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS SessionId
FROM
    SessionIdentifier
ORDER BY
    CustomerId, InvoiceDate;

-- Note on Date Functions:
-- `JULIANDAY` is SQLite-specific. Use `EXTRACT(EPOCH FROM ...)` in PostgreSQL or `DATEDIFF` in SQL Server.
