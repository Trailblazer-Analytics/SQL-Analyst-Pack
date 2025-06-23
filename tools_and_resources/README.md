# 🔧 Tools and Resources

**Purpose:** Practical utilities, templates, and quick reference materials for business analysts  
**Difficulty:** All Levels | **Prerequisites:** None | **Time:** As needed

This directory contains ready-to-use SQL snippets, templates, and reference materials to accelerate your daily analytical work.

## 📁 What's Included

### 📝 **SQL Snippets and Templates**
- **01_common_sql_snippets.sql** - Master collection of frequently used patterns
- **snippet_1_top_n_records.sql** - Find top N records per group (rankings, leaderboards)
- **snippet_2_running_totals.sql** - Calculate running totals and cumulative metrics
- **snippet_3_pivot_data.sql** - Transform rows to columns for reporting
- **snippet_4_first_last_event.sql** - Analyze first/last events (customer journeys)
- **snippet_5_date_series.sql** - Generate date ranges and time series
- **snippet_6_session_data.sql** - Analyze user sessions and behavior
- **snippet_7_customer_lifetime_value.sql** - Calculate customer value metrics

### 🎯 **Business Use Cases**
Each snippet is designed for common business analysis scenarios:
- **Sales Rankings**: Top products, regions, or salespeople
- **Financial Analysis**: Running totals, cumulative revenue
- **Customer Analytics**: Lifetime value, session analysis, journey mapping
- **Operational Reporting**: Time series analysis, trend identification
- **Dashboard Development**: Pivot tables, summary metrics

## � Quick Start

### Using SQL Snippets
1. Browse the snippet files to find relevant patterns
2. Copy the code that matches your use case
3. Adapt table and column names to your schema
4. Test the query in your environment

### Query Templates
```sql
-- Example: Use the customer analysis template
-- 1. Replace 'customers' with your table name
-- 2. Adjust column names as needed
-- 3. Customize the analysis metrics

SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_spending
FROM customers 
GROUP BY customer_segment;
```

## 📋 Featured Snippets

### Top N Records
```sql
-- Get top 10 customers by revenue
SELECT customer_id, total_revenue
FROM customers 
ORDER BY total_revenue DESC
LIMIT 10;
```

### Running Totals
```sql
-- Calculate running total of sales
SELECT 
    date,
    daily_sales,
    SUM(daily_sales) OVER (ORDER BY date) as running_total
FROM daily_sales
ORDER BY date;
```

### Pivot Data
```sql
-- Convert rows to columns for reporting
SELECT 
    product_category,
    SUM(CASE WHEN quarter = 'Q1' THEN sales ELSE 0 END) as Q1_sales,
    SUM(CASE WHEN quarter = 'Q2' THEN sales ELSE 0 END) as Q2_sales,
    SUM(CASE WHEN quarter = 'Q3' THEN sales ELSE 0 END) as Q3_sales,
    SUM(CASE WHEN quarter = 'Q4' THEN sales ELSE 0 END) as Q4_sales
FROM quarterly_sales
GROUP BY product_category;
```

## 🎯 How to Contribute

1. **Add New Snippets**: Submit commonly used patterns
2. **Improve Documentation**: Enhance explanations and examples
3. **Test Code**: Ensure snippets work across different SQL dialects
4. **Share Use Cases**: Provide real-world applications

## � Learning Integration

These tools integrate with the main learning modules:

- **Foundations**: Use basic snippets while learning core concepts
- **Intermediate**: Apply templates to analytical exercises  
- **Advanced**: Leverage optimization tools for performance tuning
- **Real World**: Use complete templates for project work

## �️ Contributing New Snippets

Have a useful pattern to share?

1. **Document the Business Use Case**: Why is this pattern useful?
2. **Include Sample Data**: Show how it works with examples  
3. **Test Across Databases**: Ensure compatibility notes are accurate
4. **Follow Naming Conventions**: Use descriptive, business-friendly names

---

**💡 Pro Tip:** These snippets are starting points - always adapt them to your specific business context and data structure!
