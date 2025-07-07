# 📊 Day 1 SQL Analyst Quick Reference

**Purpose:** Essential SQL patterns every business analyst needs on their first day  
**Time:** 30 minutes to review, bookmark for daily use  
**Level:** All levels - from intern to senior analyst

## 🚀 Emergency SQL Kit

### 📈 Top 5 Business Queries (Copy & Paste Ready)

#### 1. **Sales Performance Summary**
```sql
-- Quick sales overview by month
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as total_orders,
    SUM(order_total) as revenue,
    AVG(order_total) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders 
WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;
```

#### 2. **Customer Analysis Basics**
```sql
-- Customer behavior overview
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_lifetime_value,
    AVG(order_frequency) as avg_orders_per_customer
FROM customer_summary 
GROUP BY customer_segment
ORDER BY avg_lifetime_value DESC;
```

#### 3. **Top Performers (Products/Sales Reps/Regions)**
```sql
-- Top 10 by any metric - just change the fields
SELECT 
    product_name,
    SUM(quantity_sold) as total_quantity,
    SUM(revenue) as total_revenue,
    RANK() OVER (ORDER BY SUM(revenue) DESC) as revenue_rank
FROM sales_data 
WHERE date_period >= '2024-01-01'
GROUP BY product_name
ORDER BY total_revenue DESC
LIMIT 10;
```

#### 4. **Period-over-Period Comparison**
```sql
-- This month vs last month
SELECT 
    'This Month' as period,
    COUNT(*) as orders,
    SUM(revenue) as total_revenue
FROM orders 
WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE)

UNION ALL

SELECT 
    'Last Month' as period,
    COUNT(*) as orders,
    SUM(revenue) as total_revenue
FROM orders 
WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND order_date < DATE_TRUNC('month', CURRENT_DATE);
```

#### 5. **Data Quality Check**
```sql
-- Quick data health check
SELECT 
    'Total Records' as metric,
    COUNT(*) as value
FROM main_table

UNION ALL

SELECT 
    'Records with Missing Key Field',
    COUNT(*) 
FROM main_table 
WHERE important_field IS NULL

UNION ALL

SELECT 
    'Duplicate Records',
    COUNT(*) - COUNT(DISTINCT unique_id)
FROM main_table;
```

## 🔧 Essential Patterns for Daily Work

### 📊 **Aggregation Shortcuts**
```sql
-- Standard business metrics
SELECT 
    dimension_field,
    COUNT(*) as count,
    SUM(amount) as total,
    AVG(amount) as average,
    MIN(amount) as minimum,
    MAX(amount) as maximum,
    STDDEV(amount) as std_deviation
FROM your_table
GROUP BY dimension_field;
```

### 📅 **Date Filtering Made Simple**
```sql
-- Common date ranges
WHERE date_field >= CURRENT_DATE - INTERVAL '30 days'  -- Last 30 days
WHERE date_field >= DATE_TRUNC('month', CURRENT_DATE)  -- This month
WHERE date_field >= DATE_TRUNC('year', CURRENT_DATE)   -- This year
WHERE date_field >= '2024-01-01' AND date_field < '2024-04-01'  -- Q1 2024
```

### 🎯 **Filtering Like a Pro**
```sql
-- Multiple conditions
WHERE status IN ('active', 'pending')
  AND amount BETWEEN 100 AND 1000
  AND category LIKE '%digital%'
  AND created_date >= '2024-01-01';
```

## 🏆 Analyst Survival Kit

### ⚡ **When You Need Results Fast**

**Problem:** "I need the numbers for the meeting in 10 minutes!"

```sql
-- Template: Quick business summary
SELECT 
    [time_period],
    [key_metric_1],
    [key_metric_2],
    [comparison_metric]
FROM [main_business_table]
WHERE [recent_time_filter]
ORDER BY [time_period] DESC;
```

### 🔍 **When Data Looks Wrong**

**Problem:** "These numbers don't look right..."

```sql
-- Data validation queries
SELECT COUNT(*), MIN(date_field), MAX(date_field) FROM table_name;
SELECT column_name, COUNT(*) FROM table_name GROUP BY column_name ORDER BY 2 DESC;
SELECT * FROM table_name WHERE suspicious_field IS NULL OR suspicious_field < 0;
```

### 📈 **When You Need Trends**

**Problem:** "Show me how we're trending..."

```sql
-- Simple trend analysis
SELECT 
    DATE_TRUNC('week', date_field) as week,
    SUM(metric) as weekly_total,
    LAG(SUM(metric)) OVER (ORDER BY DATE_TRUNC('week', date_field)) as prev_week,
    SUM(metric) - LAG(SUM(metric)) OVER (ORDER BY DATE_TRUNC('week', date_field)) as change
FROM data_table
GROUP BY DATE_TRUNC('week', date_field)
ORDER BY week DESC;
```

## 🎯 Business Context Templates

### 💼 **Executive Summary Format**
```sql
-- Template for executive reporting
SELECT 
    'Total Revenue' as metric,
    CONCAT('$', FORMAT(SUM(revenue), 'N0')) as value,
    CONCAT('+', ROUND(percent_change, 1), '%') as vs_last_period
FROM financial_summary;
```

### 📊 **Department Scorecard**
```sql
-- Department performance template
SELECT 
    department,
    COUNT(*) as activities,
    SUM(budget_used) as spend,
    AVG(performance_score) as avg_performance,
    CASE 
        WHEN AVG(performance_score) >= 90 THEN '🟢 Excellent'
        WHEN AVG(performance_score) >= 70 THEN '🟡 Good'
        ELSE '🔴 Needs Attention'
    END as status
FROM department_metrics
GROUP BY department;
```

## 🆘 Troubleshooting Quick Fixes

### **Query Running Too Long?**
- Add `LIMIT 100` to test first
- Check if you have WHERE clauses on dates
- Make sure you're not doing cartesian joins

### **Getting Wrong Results?**
- Start with `SELECT COUNT(*)` to check data volume
- Add `DISTINCT` if you suspect duplicates
- Check for NULL values in key fields

### **Need to Explain Results?**
- Add comments to your SQL: `-- This calculates monthly revenue`
- Use descriptive column aliases: `SUM(amount) as total_revenue`
- Include data validation in your output

## 💡 Pro Tips for Daily Success

1. **Save This Page:** Bookmark for quick reference
2. **Customize Templates:** Replace field names with your actual schema
3. **Test Small:** Always run with LIMIT first
4. **Document Everything:** Comment your queries for future you
5. **Ask Questions:** When in doubt, validate with business stakeholders

---

**Remember:** Every senior analyst started with these basic patterns. Master these, and you'll handle 80% of daily analytical requests with confidence!
