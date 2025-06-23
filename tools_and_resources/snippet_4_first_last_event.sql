-- Snippet 4: Find the First and Last Event for Each User

-- Use Case: Find the date of the first and last purchase for each customer.
-- Technique: Use `MIN()` and `MAX()` aggregate functions grouped by the user.

SELECT
    CustomerId,
    MIN(InvoiceDate) AS FirstPurchaseDate,
    MAX(InvoiceDate) AS LastPurchaseDate
FROM
    invoices
GROUP BY
    CustomerId
ORDER BY
    CustomerId;
