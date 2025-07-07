# 🎯 Day 1 Analyst Survival Guide

**Scenario:** You just started as a SQL Analyst. Your manager needs results by Friday. Here's your playbook.

## 🚨 Week 1 Emergency Kit

### Day 1: Environment Check
```sql
-- Test your database connection
SELECT CURRENT_DATE, CURRENT_TIME, VERSION();

-- Identify available tables
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Quick row counts for main tables
SELECT 
    'customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 
    'orders' as table_name, COUNT(*) as row_count FROM orders
UNION ALL  
SELECT 
    'products' as table_name, COUNT(*) as row_count FROM products;
```

### Day 2: Business Overview
```sql
-- Get the lay of the land
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(order_total) as monthly_revenue,
    AVG(order_total) as avg_order_value
FROM orders 
WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;
```

### Day 3-5: First Analysis
Use the [Business SQL Patterns](./BUSINESS_SQL_PATTERNS.md) to create your first insights:

1. **Performance Dashboard** - Show the trend
2. **Top N Analysis** - Find the winners  
3. **Customer Segmentation** - Know your customers

## 📊 First Week Deliverables

### 1. **Business Health Check** (30 minutes)
```sql
-- Key metrics summary
WITH current_period AS (
    SELECT 
        COUNT(DISTINCT customer_id) as active_customers,
        SUM(order_total) as total_revenue,
        COUNT(*) as total_orders,
        AVG(order_total) as avg_order_value
    FROM orders 
    WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE)
),
previous_period AS (
    SELECT 
        COUNT(DISTINCT customer_id) as prev_active_customers,
        SUM(order_total) as prev_total_revenue,
        COUNT(*) as prev_total_orders
    FROM orders 
    WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
      AND order_date < DATE_TRUNC('month', CURRENT_DATE)
)
SELECT 
    'Current Month' as period,
    cp.active_customers,
    cp.total_revenue,
    cp.total_orders,
    cp.avg_order_value,
    
    -- Growth calculations
    ROUND((cp.active_customers - pp.prev_active_customers) * 100.0 / pp.prev_active_customers, 2) as customer_growth_pct,
    ROUND((cp.total_revenue - pp.prev_total_revenue) * 100.0 / pp.prev_total_revenue, 2) as revenue_growth_pct
FROM current_period cp, previous_period pp;
```

### 2. **Data Quality Report** (15 minutes)
```sql
-- Quick data quality check
SELECT 
    'Data Quality Assessment' as report_type,
    
    -- Customer data quality
    COUNT(*) as total_customers,
    COUNT(customer_name) as customers_with_names,
    COUNT(email) as customers_with_emails,
    COUNT(DISTINCT email) as unique_emails,
    
    -- Percentage calculations
    ROUND(COUNT(customer_name) * 100.0 / COUNT(*), 2) as name_completeness_pct,
    ROUND(COUNT(email) * 100.0 / COUNT(*), 2) as email_completeness_pct,
    
    -- Data issues
    SUM(CASE WHEN email NOT LIKE '%@%' THEN 1 ELSE 0 END) as invalid_emails,
    COUNT(*) - COUNT(DISTINCT customer_id) as duplicate_ids
    
FROM customers;
```

### 3. **Quick Wins Identification** (45 minutes)
```sql
-- Find immediate opportunities
WITH customer_value AS (
    SELECT 
        customer_id,
        COUNT(*) as order_count,
        SUM(order_total) as lifetime_value,
        MAX(order_date) as last_order_date,
        CURRENT_DATE - MAX(order_date) as days_since_last_order
    FROM orders 
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count >= 5 AND lifetime_value >= 1000 AND days_since_last_order <= 30 THEN 'VIP Active'
        WHEN order_count >= 3 AND days_since_last_order BETWEEN 31 AND 90 THEN 'Valuable At Risk'
        WHEN order_count = 1 AND days_since_last_order <= 30 THEN 'New Customer'
        WHEN days_since_last_order > 90 THEN 'Churned'
        ELSE 'Regular'
    END as customer_segment,
    
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_lifetime_value,
    ROUND(AVG(days_since_last_order), 1) as avg_days_since_last_order
    
FROM customer_value
GROUP BY 
    CASE 
        WHEN order_count >= 5 AND lifetime_value >= 1000 AND days_since_last_order <= 30 THEN 'VIP Active'
        WHEN order_count >= 3 AND days_since_last_order BETWEEN 31 AND 90 THEN 'Valuable At Risk'
        WHEN order_count = 1 AND days_since_last_order <= 30 THEN 'New Customer'
        WHEN days_since_last_order > 90 THEN 'Churned'
        ELSE 'Regular'
    END
ORDER BY avg_lifetime_value DESC;
```

## 💼 How to Present Your First Analysis

### 1. **Executive Summary** (1 slide)
- Current month performance vs last month
- 3 key insights in bullet points
- 1 immediate recommendation

### 2. **Supporting Data** (2-3 slides)
- Show the trend charts
- Highlight top performers  
- Include data quality note

### 3. **Next Steps** (1 slide)
- What you'll analyze next week
- What data you need access to
- Questions for stakeholders

## 🎯 Week 1 Success Metrics

✅ **Connected to database and can run queries**  
✅ **Identified key business tables and relationships**  
✅ **Created first business performance report**  
✅ **Found at least 3 actionable insights**  
✅ **Documented data quality issues**  
✅ **Presented findings to manager/team**

## 💡 Pro Tips for New Analysts

### 1. **Ask the Right Questions First**
- "What are the most important KPIs for this business?"
- "What reports does the team currently rely on?"
- "What decisions are you trying to make with this data?"
- "What problems are you hoping I can help solve?"

### 2. **Start Simple, Then Go Deep**
- Week 1: Basic counts and trends
- Week 2: Customer analysis
- Week 3: Product/channel analysis  
- Week 4: Advanced analytics

### 3. **Document Everything**
```sql
-- Always include context in your queries
-- Business Question: What's our month-over-month revenue growth?
-- Stakeholder: Sarah (Marketing Director)
-- Date: 2024-01-15
-- Expected Result: Percentage growth by month

SELECT 
    DATE_TRUNC('month', order_date) as month,
    SUM(order_total) as monthly_revenue,
    LAG(SUM(order_total)) OVER (ORDER BY DATE_TRUNC('month', order_date)) as prev_month_revenue,
    ROUND(
        (SUM(order_total) - LAG(SUM(order_total)) OVER (ORDER BY DATE_TRUNC('month', order_date))) 
        / LAG(SUM(order_total)) OVER (ORDER BY DATE_TRUNC('month', order_date)) * 100, 2
    ) as growth_percentage
FROM orders 
WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;
```

### 4. **Build Your Analyst Toolkit**
- Save your working queries in organized files
- Create templates for common analysis types
- Keep a glossary of business terms and definitions
- Maintain relationships with data owners

## 🆘 When You Get Stuck

### Database Connection Issues
```sql
-- Test your connection
SELECT 'Connection works!' as status;

-- Check your permissions
SELECT current_user, session_user, current_schema();
```

### Strange Results
```sql
-- Always validate your data
SELECT MIN(order_date), MAX(order_date), COUNT(*) FROM orders;

-- Check for nulls
SELECT COUNT(*) - COUNT(order_total) as null_order_totals FROM orders;

-- Look for duplicates
SELECT customer_id, COUNT(*) as duplicate_count 
FROM customers 
GROUP BY customer_id 
HAVING COUNT(*) > 1;
```

### Performance Problems
```sql
-- Check query execution plan
EXPLAIN ANALYZE 
SELECT customer_id, SUM(order_total) 
FROM orders 
GROUP BY customer_id;

-- Add LIMIT for testing
SELECT * FROM large_table LIMIT 100;
```

## 🚀 Ready for Week 2?

Once you've mastered Week 1, move on to:
- **[Foundations Module](../01_foundations/)** - Deepen your SQL skills
- **[Real World Scenarios](../04_real_world/)** - Industry-specific analysis
- **[Business SQL Patterns](./BUSINESS_SQL_PATTERNS.md)** - Advanced templates

---

**Remember:** Every expert was once a beginner. Focus on understanding the business first, then let the data tell the story. You've got this! 💪
