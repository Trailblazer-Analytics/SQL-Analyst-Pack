# SQL Style Guide for Analysts

## Overview

This style guide promotes consistent, readable SQL code across the SQL Analyst Pack. Following these conventions makes code easier to understand, maintain, and collaborate on.

## Core Principles

1. **Readability First**: Code should be self-documenting
2. **Consistency**: Use the same patterns throughout your analysis
3. **Clarity**: Prefer explicit over implicit
4. **Performance**: Write efficient queries that scale

## Formatting Rules

### Keywords and Functions

- **Use UPPERCASE** for SQL keywords and functions
- **Use lowercase** for table and column names

```sql
-- ✅ Good
SELECT 
    customer_id,
    customer_name,
    COUNT(*) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01'
GROUP BY c.customer_id, c.customer_name;

-- ❌ Avoid
select customer_id, customer_name, count(*) as order_count
from customers c join orders o on c.customer_id = o.customer_id
where o.order_date >= '2024-01-01'
group by c.customer_id, c.customer_name;
```

### Indentation and Line Breaks

- **Use 4 spaces** for indentation (no tabs)
- **Break long lines** at logical points
- **Align keywords** vertically when possible

```sql
-- ✅ Good
SELECT 
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    SUM(o.total_amount) AS total_spent,
    COUNT(o.order_id) AS order_count,
    AVG(o.total_amount) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.registration_date >= '2023-01-01'
    AND o.order_status = 'completed'
GROUP BY 
    c.customer_id,
    c.customer_name, 
    c.customer_segment
HAVING COUNT(o.order_id) >= 2
ORDER BY total_spent DESC;
```

### Commas and Operators

- **Use trailing commas** in SELECT lists
- **Put operators at the end** of lines when breaking
- **Use spaces around operators**

```sql
-- ✅ Good
SELECT 
    customer_id,
    customer_name,
    total_orders,
    (total_revenue / total_orders) AS avg_order_value,
    CASE 
        WHEN total_revenue > 1000 THEN 'High Value'
        WHEN total_revenue > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_tier
FROM customer_summary
WHERE total_orders > 0
    AND registration_date >= CURRENT_DATE - INTERVAL '365 days';

-- ❌ Avoid
SELECT customer_id
    , customer_name
    , total_orders
    , (total_revenue/total_orders) AS avg_order_value
FROM customer_summary
WHERE total_orders>0 AND
registration_date>=CURRENT_DATE-INTERVAL '365 days';
```

## Naming Conventions

### Tables and Columns

- **Use snake_case** for all identifiers
- **Use descriptive names** that explain the content
- **Avoid abbreviations** unless they're widely understood

```sql
-- ✅ Good
CREATE TABLE customer_order_summary (
    customer_id INTEGER,
    total_orders INTEGER,
    total_revenue DECIMAL(10,2),
    first_order_date DATE,
    last_order_date DATE,
    avg_days_between_orders DECIMAL(6,2)
);

-- ❌ Avoid
CREATE TABLE cust_ord_sum (
    cust_id INT,
    tot_ords INT,
    tot_rev DECIMAL(10,2),
    frst_ord_dt DATE,
    lst_ord_dt DATE,
    avg_days_btw_ords DECIMAL(6,2)
);
```

### Aliases

- **Use meaningful aliases** for tables
- **Use explicit AS keyword** for column aliases
- **Keep aliases short but clear**

```sql
-- ✅ Good
SELECT 
    c.customer_name,
    c.email,
    o.order_date,
    oi.quantity * oi.unit_price AS line_total
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id;

-- ❌ Avoid
SELECT 
    customers.customer_name,
    customers.email,
    orders.order_date,
    order_items.quantity * order_items.unit_price line_total
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN order_items ON orders.order_id = order_items.order_id;
```

## Query Structure

### SELECT Statement Order

1. SELECT (with column list)
2. FROM
3. JOIN (in logical order)
4. WHERE
5. GROUP BY
6. HAVING
7. ORDER BY
8. LIMIT/OFFSET

```sql
-- ✅ Recommended structure
SELECT 
    -- Column specifications
FROM main_table mt
JOIN related_table rt ON mt.id = rt.main_id
LEFT JOIN optional_table ot ON mt.id = ot.main_id
WHERE 
    -- Filter conditions
GROUP BY 
    -- Grouping columns
HAVING 
    -- Aggregate conditions
ORDER BY 
    -- Sorting specification
LIMIT 100;
```

### Common Table Expressions (CTEs)

- **Use CTEs** for complex logic instead of subqueries
- **Name CTEs descriptively**
- **Add comments** to explain complex CTEs

```sql
-- ✅ Good
WITH customer_metrics AS (
    -- Calculate basic customer metrics
    SELECT 
        customer_id,
        COUNT(*) AS total_orders,
        SUM(total_amount) AS total_spent,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE order_status = 'completed'
    GROUP BY customer_id
),
customer_segments AS (
    -- Assign customers to segments based on spending
    SELECT 
        customer_id,
        total_orders,
        total_spent,
        last_order_date,
        CASE 
            WHEN total_spent >= 1000 THEN 'VIP'
            WHEN total_spent >= 500 THEN 'Premium'
            ELSE 'Standard'
        END AS customer_segment
    FROM customer_metrics
)
SELECT 
    cs.customer_segment,
    COUNT(*) AS customer_count,
    AVG(cs.total_spent) AS avg_spending
FROM customer_segments cs
GROUP BY cs.customer_segment
ORDER BY avg_spending DESC;
```

## Business Logic

### Comments and Documentation

- **Add comments** for complex business logic
- **Explain WHY**, not just what
- **Use consistent comment style**

```sql
-- Customer Lifetime Value Analysis
-- Calculates CLV using historical purchase data and predicted retention
-- Business rule: Only include customers with 2+ orders for accuracy

WITH customer_purchase_history AS (
    SELECT 
        customer_id,
        COUNT(*) AS total_orders,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_order_value,
        -- Calculate average days between orders for retention modeling
        AVG(EXTRACT(DAY FROM order_date - LAG(order_date) 
            OVER (PARTITION BY customer_id ORDER BY order_date))) AS avg_days_between_orders
    FROM orders
    WHERE order_status = 'completed'
        AND order_date >= '2023-01-01'  -- Focus on recent behavior
    GROUP BY customer_id
    HAVING COUNT(*) >= 2  -- Business requirement: minimum 2 orders
)
SELECT 
    customer_id,
    total_revenue,
    avg_order_value,
    -- CLV calculation: (avg order value * purchase frequency * customer lifespan)
    (avg_order_value * (365.0 / NULLIF(avg_days_between_orders, 0)) * 2.5) AS estimated_clv
FROM customer_purchase_history
WHERE avg_days_between_orders IS NOT NULL;
```

### Date and Time Handling

- **Be explicit** about date ranges
- **Use standard formats** for date literals
- **Handle time zones** appropriately

```sql
-- ✅ Good
SELECT 
    DATE_TRUNC('month', order_date) AS order_month,
    COUNT(*) AS monthly_orders
FROM orders
WHERE order_date >= '2024-01-01'::DATE
    AND order_date < '2025-01-01'::DATE  -- Explicit end boundary
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;

-- ❌ Avoid ambiguous date handling
SELECT 
    DATE_PART('month', order_date),
    COUNT(*)
FROM orders
WHERE order_date > '2024'  -- Unclear format
GROUP BY DATE_PART('month', order_date);
```

## Performance Guidelines

### JOIN Optimization

- **Use appropriate JOIN types**
- **Filter early** with WHERE clauses
- **Join on indexed columns** when possible

```sql
-- ✅ Efficient join with early filtering
SELECT 
    c.customer_name,
    SUM(o.total_amount) AS recent_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'  -- Filter before aggregation
    AND c.customer_segment IN ('VIP', 'Premium')         -- Reduce join size
GROUP BY c.customer_id, c.customer_name;
```

### Window Functions

- **Use window functions** for analytical queries
- **Partition appropriately** for performance
- **Consider ordering** for deterministic results

```sql
-- ✅ Good window function usage
SELECT 
    customer_id,
    order_date,
    total_amount,
    -- Running total by customer
    SUM(total_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY order_date 
        ROWS UNBOUNDED PRECEDING
    ) AS running_total,
    -- Rank orders by amount within customer
    RANK() OVER (
        PARTITION BY customer_id 
        ORDER BY total_amount DESC
    ) AS order_rank
FROM orders
WHERE order_status = 'completed'
ORDER BY customer_id, order_date;
```

## Tools and Automation

### SQLFluff Integration

This project uses SQLFluff for automated code quality checking. Run:

```bash
# Check all SQL files
sqlfluff lint **/*.sql

# Fix formatting issues automatically
sqlfluff fix **/*.sql

# Check specific file
sqlfluff lint path/to/query.sql
```

### VS Code Integration

The project includes VS Code settings for:

- SQL formatting on save
- SQLFluff integration
- Syntax highlighting
- IntelliSense for SQL

### Pre-commit Hooks

Automatically check SQL quality before commits:

```bash
# Install pre-commit hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## Quick Checklist

Before submitting SQL code, verify:

- [ ] Keywords are UPPERCASE
- [ ] Table/column names are lowercase_snake_case
- [ ] Proper indentation (4 spaces)
- [ ] Trailing commas in SELECT lists
- [ ] Meaningful table aliases
- [ ] Explicit column aliases with AS
- [ ] Comments for complex business logic
- [ ] Efficient JOIN conditions
- [ ] Appropriate WHERE clause filtering
- [ ] Consistent date format handling

## Examples by Use Case

### Data Exploration

```sql
-- Quick data profiling query
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customers,
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    AVG(total_amount) AS avg_order_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount) AS median_order_value
FROM orders
WHERE order_status = 'completed';
```

### Business Reporting

```sql
-- Monthly revenue report with growth metrics
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS revenue,
        COUNT(*) AS order_count,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM orders
    WHERE order_status = 'completed'
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    revenue,
    order_count,
    unique_customers,
    -- Month-over-month growth
    (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100 AS revenue_growth_pct,
    -- Year-over-year comparison
    LAG(revenue, 12) OVER (ORDER BY month) AS revenue_same_month_last_year
FROM monthly_revenue
ORDER BY month DESC;
```

---

**Remember**: Good SQL style makes your analysis more maintainable, collaborative, and professional. When in doubt, prioritize readability!
