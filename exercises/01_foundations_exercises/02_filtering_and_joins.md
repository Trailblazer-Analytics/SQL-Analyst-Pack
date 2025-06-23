# Exercise 2: Advanced Filtering and Joins

## Business Context

You're working as a data analyst for **RetailFlow**, an e-commerce company. The marketing team needs insights about customer behavior and product performance to optimize their Q4 campaign strategy. You'll analyze customer orders, product categories, and regional performance.

## Learning Objectives

By completing this exercise, you will:

- Master complex WHERE clause conditions
- Understand different JOIN types and when to use them
- Practice combining multiple tables for business insights
- Learn to write efficient queries for large datasets

## Database Schema

You'll be working with these tables:

```sql
-- customers table
customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE,
    region VARCHAR(50),
    customer_tier VARCHAR(20) -- 'Bronze', 'Silver', 'Gold', 'Platinum'
)

-- products table
products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    unit_price DECIMAL(10,2),
    supplier_id INT
)

-- orders table
orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(20), -- 'pending', 'shipped', 'delivered', 'cancelled'
    total_amount DECIMAL(10,2),
    shipping_region VARCHAR(50)
)

-- order_items table
order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2)
)
```

## Tasks

### Task 1: Customer Segmentation Analysis
**Business Question**: "Which customer segments in each region generate the most revenue?"

Write a query that shows:
- Region
- Customer tier
- Number of customers
- Total revenue
- Average order value

Filter for:
- Only customers who have placed orders in 2024
- Exclude cancelled orders
- Only include regions with more than 100 customers

**Expected Skills**: Complex JOINs, GROUP BY, HAVING, filtering

### Task 2: Product Performance by Category
**Business Question**: "What are our top-performing product categories, and which ones are underperforming?"

Create a query that displays:
- Category and subcategory
- Total units sold
- Total revenue
- Number of unique customers who bought from this category
- Average discount given

Requirements:
- Include only products sold in the last 6 months
- Show categories with revenue > $10,000
- Order by total revenue descending

**Expected Skills**: Multi-table JOINs, date filtering, aggregations

### Task 3: Customer Loyalty Analysis
**Business Question**: "Which customers are our most loyal, and what patterns do they show?"

Find customers who meet ALL these criteria:
- Have placed orders in at least 3 different months in 2024
- Have ordered from at least 2 different product categories
- Have a total order value > $500
- Have never cancelled an order

Show:
- Customer details (name, email, tier, region)
- Number of orders
- Number of different categories purchased
- Total spent
- First and last order dates

**Expected Skills**: Multiple JOINs, complex WHERE conditions, date functions

### Task 4: Regional Performance Comparison
**Business Question**: "How do our different shipping regions compare in terms of customer satisfaction and profitability?"

Create a comprehensive regional analysis showing:
- Shipping region
- Total orders and revenue
- Average order processing time (assume 'delivered' orders take 3-7 days)
- Customer retention rate (customers who placed multiple orders)
- Most popular product category
- Average customer tier distribution

**Expected Skills**: Advanced JOINs, subqueries, window functions

## Starter Code

### Database Connection (if using Python)
```python
import pandas as pd
import sqlalchemy as sa

# Connect to your database
engine = sa.create_engine('your_connection_string')

# Function to run queries
def run_query(query):
    return pd.read_sql_query(query, engine)
```

### Sample Data Exploration Queries
```sql
-- Understand the data size
SELECT 
    'customers' as table_name, 
    COUNT(*) as row_count 
FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

-- Check date ranges
SELECT 
    MIN(order_date) as earliest_order,
    MAX(order_date) as latest_order
FROM orders;

-- Sample JOIN to verify relationships
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
LIMIT 10;
```

## Solutions

<details>
<summary>Click to reveal Task 1 Solution</summary>

```sql
-- Task 1: Customer Segmentation Analysis
SELECT 
    c.region,
    c.customer_tier,
    COUNT(DISTINCT c.customer_id) as customer_count,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE 
    EXTRACT(YEAR FROM o.order_date) = 2024
    AND o.order_status != 'cancelled'
GROUP BY c.region, c.customer_tier
HAVING COUNT(DISTINCT c.customer_id) > 100
ORDER BY c.region, total_revenue DESC;
```

**Business Insight**: This query helps identify which customer tiers drive the most value in each region, enabling targeted marketing strategies.

</details>

<details>
<summary>Click to reveal Task 2 Solution</summary>

```sql
-- Task 2: Product Performance by Category
SELECT 
    p.category,
    p.subcategory,
    SUM(oi.quantity) as total_units_sold,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100)) as total_revenue,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    AVG(oi.discount_percent) as avg_discount_percent
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE 
    o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    AND o.order_status != 'cancelled'
GROUP BY p.category, p.subcategory
HAVING SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent/100)) > 10000
ORDER BY total_revenue DESC;
```

**Business Insight**: Identifies top-performing categories and helps optimize inventory and marketing spend.

</details>

<details>
<summary>Click to reveal Task 3 Solution</summary>

```sql
-- Task 3: Customer Loyalty Analysis
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.customer_tier,
        c.region,
        COUNT(DISTINCT o.order_id) as order_count,
        COUNT(DISTINCT EXTRACT(YEAR_MONTH FROM o.order_date)) as months_active,
        COUNT(DISTINCT p.category) as categories_purchased,
        SUM(o.total_amount) as total_spent,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.customer_tier, c.region
)
SELECT *
FROM customer_metrics
WHERE 
    months_active >= 3
    AND categories_purchased >= 2
    AND total_spent > 500
    AND cancelled_orders = 0
ORDER BY total_spent DESC;
```

**Business Insight**: Identifies your most valuable loyal customers for VIP programs and retention strategies.

</details>

<details>
<summary>Click to reveal Task 4 Solution</summary>

```sql
-- Task 4: Regional Performance Comparison
WITH regional_stats AS (
    SELECT 
        o.shipping_region,
        COUNT(o.order_id) as total_orders,
        SUM(o.total_amount) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(CASE WHEN o.order_status = 'delivered' THEN 5.0 ELSE NULL END) as avg_processing_days
    FROM orders o
    WHERE o.order_status != 'cancelled'
    GROUP BY o.shipping_region
),
customer_retention AS (
    SELECT 
        o.shipping_region,
        COUNT(DISTINCT o.customer_id) as total_customers,
        COUNT(DISTINCT CASE WHEN order_count > 1 THEN o.customer_id END) as repeat_customers
    FROM orders o
    JOIN (
        SELECT customer_id, COUNT(*) as order_count
        FROM orders
        WHERE order_status != 'cancelled'
        GROUP BY customer_id
    ) customer_orders ON o.customer_id = customer_orders.customer_id
    GROUP BY o.shipping_region
),
popular_categories AS (
    SELECT DISTINCT
        o.shipping_region,
        FIRST_VALUE(p.category) OVER (
            PARTITION BY o.shipping_region 
            ORDER BY SUM(oi.quantity) DESC
        ) as most_popular_category
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status != 'cancelled'
    GROUP BY o.shipping_region, p.category
)
SELECT 
    rs.shipping_region,
    rs.total_orders,
    rs.total_revenue,
    rs.avg_processing_days,
    ROUND(cr.repeat_customers * 100.0 / cr.total_customers, 2) as retention_rate_percent,
    pc.most_popular_category
FROM regional_stats rs
JOIN customer_retention cr ON rs.shipping_region = cr.shipping_region
JOIN popular_categories pc ON rs.shipping_region = pc.shipping_region
ORDER BY rs.total_revenue DESC;
```

**Business Insight**: Comprehensive regional analysis for optimizing logistics, marketing, and customer service strategies.

</details>

## Extension Exercises

### Advanced Challenge 1: Time Series Analysis
Create a query that shows monthly revenue trends by customer tier, including:
- Month-over-month growth rate
- Rolling 3-month average
- Year-over-year comparison

### Advanced Challenge 2: Cohort Analysis
Build a customer cohort analysis showing:
- Customer acquisition by month
- Retention rates by cohort
- Revenue per cohort over time

### Advanced Challenge 3: Product Recommendation Engine
Design queries to identify:
- Products frequently bought together
- Customers similar to a given customer
- Recommended products for each customer segment

## Business Impact

These exercises simulate real analyst work:
- **Marketing Teams** use customer segmentation for campaign targeting
- **Product Managers** use category analysis for inventory decisions
- **Operations Teams** use regional analysis for logistics optimization
- **Executive Teams** use loyalty analysis for strategic planning

## Key Learning Outcomes

✅ **Complex JOIN Operations**: Master INNER, LEFT, RIGHT, and FULL JOINs  
✅ **Advanced Filtering**: Use multiple conditions, date ranges, and NOT EXISTS  
✅ **Business Metrics**: Calculate KPIs like retention rates and growth metrics  
✅ **Performance Optimization**: Write efficient queries for large datasets  
✅ **Real-world Problem Solving**: Translate business questions into SQL

---

**Next Exercise**: `03_aggregation_and_analytics.md` - Advanced aggregations and window functions
