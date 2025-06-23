# Exercise 1: Data Exploration Basics 🟢

## Business Context

**Scenario**: You're a new analyst at TechMart, an e-commerce company. Your manager has asked you to get familiar with the company's customer and sales data. You need to perform initial data exploration to understand the dataset and identify key patterns.

**Stakeholder**: Sarah Chen, Marketing Director
**Business Need**: "I need to understand our customer base and recent sales trends to plan our Q3 marketing strategy."

## Learning Objectives

By completing this exercise, you will:
- Master basic SQL SELECT statements and data exploration
- Practice using essential SQL functions (COUNT, SUM, AVG, MIN, MAX)
- Learn to filter and sort data effectively
- Develop skills in data profiling and quality assessment
- Understand how to write business-focused SQL queries

## Dataset Description

You'll work with these tables from the TechMart database:

### customers
- `customer_id` (INTEGER): Unique customer identifier
- `customer_name` (VARCHAR): Customer full name
- `email` (VARCHAR): Customer email address
- `registration_date` (DATE): When customer registered
- `customer_segment` (VARCHAR): Premium, Standard, or VIP
- `city` (VARCHAR): Customer city
- `state` (VARCHAR): Customer state

### orders
- `order_id` (INTEGER): Unique order identifier
- `customer_id` (INTEGER): Links to customers table
- `order_date` (DATE): When order was placed
- `order_status` (VARCHAR): completed, shipped, processing, cancelled
- `total_amount` (DECIMAL): Order total in USD
- `payment_method` (VARCHAR): credit_card, debit_card, paypal

### products
- `product_id` (INTEGER): Unique product identifier
- `product_name` (VARCHAR): Product name
- `category` (VARCHAR): Product category
- `price` (DECIMAL): Product price in USD
- `stock_quantity` (INTEGER): Current inventory

## Tasks

### Task 1: Basic Data Exploration 🔍

**Question**: What does our customer data look like?

Write queries to answer:
1. How many total customers do we have?
2. What are the different customer segments and how many customers are in each?
3. What is the date range of customer registrations?
4. Show a sample of 10 customers with all their information.

**Business Value**: Understanding the scale and composition of our customer base.

### Task 2: Order Analysis 📊

**Question**: What does our order pattern look like?

Write queries to answer:
1. How many total orders have been placed?
2. What is the total revenue across all completed orders?
3. What is the average order value?
4. What are the different order statuses and their counts?
5. Show the 5 largest orders by total amount.

**Business Value**: Understanding sales volume, revenue, and order patterns.

### Task 3: Customer Behavior Insights 🎯

**Question**: How do our customers behave?

Write queries to answer:
1. Which customer has placed the most orders?
2. What is the total amount spent by each customer segment?
3. Find customers who have never placed an order.
4. Which payment method is most popular?
5. Show the newest 10 customers by registration date.

**Business Value**: Identifying customer patterns and potential issues.

### Task 4: Product Performance 📈

**Question**: How are our products performing?

Write queries to answer:
1. How many products do we have in each category?
2. What is the average price by product category?
3. Which products are running low on stock (less than 10 items)?
4. Show the 5 most expensive products.
5. What is the total inventory value (price × stock_quantity)?

**Business Value**: Understanding product portfolio and inventory status.

### Task 5: Data Quality Assessment ✅

**Question**: What data quality issues should we be aware of?

Write queries to check:
1. Are there any customers with missing email addresses?
2. Are there any orders with zero or negative amounts?
3. Are there any customers with duplicate email addresses?
4. Find any orders without a corresponding customer.
5. Are there any products with zero or negative prices?

**Business Value**: Ensuring data reliability for business decisions.

## Solutions

### Task 1 Solutions: Basic Data Exploration

```sql
-- 1. Total customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- 2. Customer segments breakdown
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS percentage
FROM customers
GROUP BY customer_segment
ORDER BY customer_count DESC;

-- 3. Customer registration date range
SELECT 
    MIN(registration_date) AS earliest_registration,
    MAX(registration_date) AS latest_registration,
    MAX(registration_date) - MIN(registration_date) AS date_range_days
FROM customers;

-- 4. Sample of 10 customers
SELECT 
    customer_id,
    customer_name,
    email,
    registration_date,
    customer_segment,
    city,
    state
FROM customers
ORDER BY registration_date DESC
LIMIT 10;
```

### Task 2 Solutions: Order Analysis

```sql
-- 1. Total orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- 2. Total revenue from completed orders
SELECT 
    SUM(total_amount) AS total_revenue,
    COUNT(*) AS completed_orders
FROM orders
WHERE order_status = 'completed';

-- 3. Average order value
SELECT 
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(AVG(CASE WHEN order_status = 'completed' THEN total_amount END), 2) AS avg_completed_order_value
FROM orders;

-- 4. Order status breakdown
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 5. Top 5 largest orders
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    order_status
FROM orders
ORDER BY total_amount DESC
LIMIT 5;
```

### Task 3 Solutions: Customer Behavior Insights

```sql
-- 1. Customer with most orders
SELECT 
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.customer_segment
ORDER BY total_orders DESC
LIMIT 1;

-- 2. Total spending by customer segment
SELECT 
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS customers_in_segment,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(CASE WHEN o.order_status = 'completed' THEN o.total_amount END), 0) AS total_revenue,
    ROUND(AVG(CASE WHEN o.order_status = 'completed' THEN o.total_amount END), 2) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;

-- 3. Customers who have never placed an order
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    c.registration_date,
    c.customer_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL
ORDER BY c.registration_date DESC;

-- 4. Most popular payment method
SELECT 
    payment_method,
    COUNT(*) AS usage_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
WHERE payment_method IS NOT NULL
GROUP BY payment_method
ORDER BY usage_count DESC;

-- 5. Newest 10 customers
SELECT 
    customer_id,
    customer_name,
    email,
    registration_date,
    customer_segment,
    city,
    state
FROM customers
ORDER BY registration_date DESC
LIMIT 10;
```

### Task 4 Solutions: Product Performance

```sql
-- 1. Product count by category
SELECT 
    category,
    COUNT(*) AS product_count
FROM products
GROUP BY category
ORDER BY product_count DESC;

-- 2. Average price by category
SELECT 
    category,
    COUNT(*) AS product_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(MAX(price), 2) AS max_price
FROM products
GROUP BY category
ORDER BY avg_price DESC;

-- 3. Low stock products (less than 10 items)
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity
FROM products
WHERE stock_quantity < 10
ORDER BY stock_quantity ASC, category;

-- 4. Top 5 most expensive products
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity
FROM products
ORDER BY price DESC
LIMIT 5;

-- 5. Total inventory value
SELECT 
    SUM(price * stock_quantity) AS total_inventory_value,
    COUNT(*) AS total_products,
    ROUND(AVG(price * stock_quantity), 2) AS avg_product_inventory_value
FROM products;
```

### Task 5 Solutions: Data Quality Assessment

```sql
-- 1. Customers with missing email addresses
SELECT 
    customer_id,
    customer_name,
    registration_date,
    customer_segment
FROM customers
WHERE email IS NULL OR email = '';

-- 2. Orders with zero or negative amounts
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    order_status
FROM orders
WHERE total_amount <= 0;

-- 3. Customers with duplicate email addresses
SELECT 
    email,
    COUNT(*) AS customer_count,
    STRING_AGG(customer_name, ', ') AS customers_with_email
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

-- 4. Orders without corresponding customers
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.total_amount
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5. Products with zero or negative prices
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity
FROM products
WHERE price <= 0;
```

## Analysis and Insights 💡

### Key Findings Template

Based on your query results, document your findings:

**Customer Base Analysis:**
- Total customers: [your result]
- Largest segment: [your result]
- Registration period: [your result]

**Sales Performance:**
- Total orders: [your result]
- Revenue: [your result]
- Average order value: [your result]

**Data Quality Issues:**
- Missing emails: [your result]
- Invalid orders: [your result]
- Other issues: [your findings]

### Business Recommendations

1. **Customer Segment Focus**: [Based on segment analysis]
2. **Payment Method Optimization**: [Based on payment analysis]
3. **Inventory Management**: [Based on stock analysis]
4. **Data Quality Improvements**: [Based on quality checks]

## Extensions for Further Practice 🚀

### Extension 1: Time-Based Analysis
Analyze customer registration trends by month and identify seasonal patterns.

### Extension 2: Geographic Analysis
Examine customer distribution by state and identify regional opportunities.

### Extension 3: Customer Lifecycle
Calculate the time between customer registration and first order.

### Extension 4: Product Category Deep Dive
Analyze the relationship between product categories and customer segments.

### Extension 5: Order Timing Patterns
Examine order patterns by day of week or time of day (if timestamp data available).

## Real-World Application 🌟

### How This Exercise Applies to Your Work:
1. **Regular Data Exploration**: These techniques help you understand any new dataset
2. **Data Quality Monitoring**: Regular quality checks prevent analysis errors
3. **Business Reporting**: These queries form the foundation of business reports
4. **Stakeholder Communication**: Results can be easily shared with non-technical teams

### Next Steps:
- Practice these queries with your own data
- Modify queries to answer different business questions
- Build on these basics for more complex analysis
- Document your findings for team sharing

---

**Completion Time**: 2-3 hours
**Difficulty**: 🟢 Beginner
**Next Exercise**: [Exercise 2: Customer Analysis Fundamentals](./02_customer_analysis_fundamentals.md)
