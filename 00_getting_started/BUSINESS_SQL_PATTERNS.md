# 💼 Business SQL Patterns: Essential Templates for Analysts

**Purpose:** Ready-to-use SQL templates for common business analysis scenarios  
**Target Audience:** New analysts, quick reference for experienced analysts  
**Time to Master:** 2-3 hours study, then bookmark for daily use

## 🚀 The Essential 8: Most Common Business Queries

### 1. 📊 **Performance Dashboard Template**
*Use Case: Monthly/weekly business performance summaries*

```sql
-- Standard business performance dashboard
WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) as month,
        SUM(revenue) as total_revenue,
        COUNT(DISTINCT customer_id) as unique_customers,
        COUNT(*) as total_transactions,
        AVG(revenue) as avg_transaction_value
    FROM sales_data 
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', transaction_date)
),
performance_with_growth AS (
    SELECT *,
        LAG(total_revenue) OVER (ORDER BY month) as prev_month_revenue,
        ROUND(
            ((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) 
             / LAG(total_revenue) OVER (ORDER BY month) * 100), 2
        ) as revenue_growth_pct
    FROM monthly_metrics
)
SELECT 
    month,
    total_revenue,
    unique_customers,
    total_transactions,
    avg_transaction_value,
    revenue_growth_pct,
    CASE 
        WHEN revenue_growth_pct > 10 THEN '🔥 Excellent'
        WHEN revenue_growth_pct > 0 THEN '✅ Positive'
        WHEN revenue_growth_pct > -5 THEN '⚠️ Caution'
        ELSE '🚨 Declining'
    END as performance_status
FROM performance_with_growth
ORDER BY month DESC;
```

### 2. 🏆 **Top N Analysis (Leaderboards)**
*Use Case: Top products, regions, customers, sales reps*

```sql
-- Top 10 performers with ranking and contribution analysis
WITH ranked_performance AS (
    SELECT 
        product_name,
        SUM(revenue) as total_revenue,
        COUNT(*) as sales_count,
        AVG(revenue) as avg_sale_value,
        RANK() OVER (ORDER BY SUM(revenue) DESC) as revenue_rank,
        ROW_NUMBER() OVER (ORDER BY SUM(revenue) DESC) as row_num
    FROM sales_data 
    WHERE transaction_date >= '2024-01-01'
    GROUP BY product_name
),
total_performance AS (
    SELECT SUM(total_revenue) as company_total_revenue
    FROM ranked_performance
)
SELECT 
    rp.product_name,
    rp.total_revenue,
    rp.sales_count,
    rp.avg_sale_value,
    rp.revenue_rank,
    ROUND((rp.total_revenue / tp.company_total_revenue * 100), 2) as revenue_contribution_pct,
    -- Cumulative percentage for Pareto analysis
    ROUND(
        SUM(rp.total_revenue) OVER (ORDER BY rp.total_revenue DESC) 
        / tp.company_total_revenue * 100, 2
    ) as cumulative_contribution_pct
FROM ranked_performance rp
CROSS JOIN total_performance tp
WHERE rp.row_num <= 10  -- Top 10 only
ORDER BY rp.total_revenue DESC;
```

### 3. 📈 **Trend Analysis (Period-over-Period)**
*Use Case: Month-over-month, year-over-year comparisons*

```sql
-- Period-over-period trend analysis
WITH period_comparison AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        SUM(order_total) as monthly_revenue,
        COUNT(*) as monthly_orders,
        -- Previous period comparisons
        LAG(SUM(order_total), 1) OVER (ORDER BY DATE_TRUNC('month', order_date)) as prev_month_revenue,
        LAG(SUM(order_total), 12) OVER (ORDER BY DATE_TRUNC('month', order_date)) as same_month_last_year,
        -- Moving averages
        AVG(SUM(order_total)) OVER (
            ORDER BY DATE_TRUNC('month', order_date) 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as three_month_avg
    FROM orders 
    WHERE order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    monthly_revenue,
    monthly_orders,
    prev_month_revenue,
    same_month_last_year,
    three_month_avg,
    
    -- Growth calculations
    CASE 
        WHEN prev_month_revenue IS NOT NULL THEN
            ROUND(((monthly_revenue - prev_month_revenue) / prev_month_revenue * 100), 2)
    END as mom_growth_pct,
    
    CASE 
        WHEN same_month_last_year IS NOT NULL THEN
            ROUND(((monthly_revenue - same_month_last_year) / same_month_last_year * 100), 2)
    END as yoy_growth_pct,
    
    -- Trend indicators
    CASE 
        WHEN monthly_revenue > three_month_avg * 1.1 THEN 'Above Trend'
        WHEN monthly_revenue < three_month_avg * 0.9 THEN 'Below Trend'
        ELSE 'On Trend'
    END as trend_status
    
FROM period_comparison
WHERE month >= CURRENT_DATE - INTERVAL '12 months'
ORDER BY month DESC;
```

### 4. 👥 **Customer Segmentation (RFM Analysis)**
*Use Case: Customer behavior analysis, targeted marketing*

```sql
-- RFM Analysis: Recency, Frequency, Monetary segmentation
WITH customer_metrics AS (
    SELECT 
        customer_id,
        MAX(order_date) as last_order_date,
        COUNT(*) as order_frequency,
        SUM(order_total) as total_spent,
        AVG(order_total) as avg_order_value,
        -- Calculate recency in days
        CURRENT_DATE - MAX(order_date) as days_since_last_order
    FROM orders 
    WHERE order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT *,
        -- RFM Scoring (1-5 scale)
        NTILE(5) OVER (ORDER BY days_since_last_order ASC) as recency_score,
        NTILE(5) OVER (ORDER BY order_frequency DESC) as frequency_score,
        NTILE(5) OVER (ORDER BY total_spent DESC) as monetary_score
    FROM customer_metrics
),
customer_segments AS (
    SELECT *,
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'VIP Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost Customers'
            WHEN frequency_score >= 3 AND monetary_score <= 2 THEN 'Price Sensitive'
            ELSE 'Developing'
        END as customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_lifetime_value,
    ROUND(AVG(order_frequency), 2) as avg_order_frequency,
    ROUND(AVG(days_since_last_order), 1) as avg_days_since_last_order,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as segment_percentage
FROM customer_segments
GROUP BY customer_segment
ORDER BY avg_lifetime_value DESC;
```

### 5. 💰 **Cohort Analysis (Customer Lifetime Tracking)**
*Use Case: Customer retention, LTV analysis*

```sql
-- Monthly cohort analysis for customer retention
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month,
        DATE_TRUNC('month', order_date) as order_month
    FROM orders 
    GROUP BY customer_id, DATE_TRUNC('month', order_date)
),
cohort_data AS (
    SELECT 
        cohort_month,
        order_month,
        COUNT(DISTINCT customer_id) as customers,
        -- Calculate period number (0 = acquisition month, 1 = month 1, etc.)
        EXTRACT(YEAR FROM order_month) * 12 + EXTRACT(MONTH FROM order_month) -
        (EXTRACT(YEAR FROM cohort_month) * 12 + EXTRACT(MONTH FROM cohort_month)) as period_number
    FROM customer_cohorts 
    GROUP BY cohort_month, order_month
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM customer_cohorts 
    WHERE cohort_month = order_month
    GROUP BY cohort_month
)
SELECT 
    cd.cohort_month,
    cs.cohort_size,
    cd.period_number,
    cd.customers,
    ROUND(cd.customers * 100.0 / cs.cohort_size, 2) as retention_rate
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.cohort_month >= CURRENT_DATE - INTERVAL '12 months'
ORDER BY cd.cohort_month, cd.period_number;
```

### 6. 🔍 **Data Quality Assessment**
*Use Case: Data validation, data profiling*

```sql
-- Comprehensive data quality assessment
WITH data_profile AS (
    SELECT 
        'customers' as table_name,
        COUNT(*) as total_records,
        COUNT(DISTINCT customer_id) as unique_customers,
        
        -- Null analysis
        COUNT(*) - COUNT(customer_name) as null_names,
        COUNT(*) - COUNT(email) as null_emails,
        COUNT(*) - COUNT(registration_date) as null_reg_dates,
        
        -- Data validity checks
        SUM(CASE WHEN email NOT LIKE '%@%' THEN 1 ELSE 0 END) as invalid_emails,
        SUM(CASE WHEN registration_date > CURRENT_DATE THEN 1 ELSE 0 END) as future_dates,
        
        -- Duplicates
        COUNT(*) - COUNT(DISTINCT customer_id) as duplicate_customer_ids,
        COUNT(*) - COUNT(DISTINCT email) as duplicate_emails
        
    FROM customers
),
quality_metrics AS (
    SELECT *,
        ROUND((total_records - null_names) * 100.0 / total_records, 2) as name_completeness_pct,
        ROUND((total_records - null_emails) * 100.0 / total_records, 2) as email_completeness_pct,
        ROUND((total_records - invalid_emails) * 100.0 / total_records, 2) as email_validity_pct,
        ROUND((total_records - duplicate_customer_ids) * 100.0 / total_records, 2) as id_uniqueness_pct
    FROM data_profile
)
SELECT 
    table_name,
    total_records,
    unique_customers,
    name_completeness_pct,
    email_completeness_pct,
    email_validity_pct,
    id_uniqueness_pct,
    
    -- Overall data quality score
    ROUND((name_completeness_pct + email_completeness_pct + email_validity_pct + id_uniqueness_pct) / 4, 2) as overall_quality_score,
    
    CASE 
        WHEN (name_completeness_pct + email_completeness_pct + email_validity_pct + id_uniqueness_pct) / 4 >= 95 THEN '🟢 Excellent'
        WHEN (name_completeness_pct + email_completeness_pct + email_validity_pct + id_uniqueness_pct) / 4 >= 85 THEN '🟡 Good'
        WHEN (name_completeness_pct + email_completeness_pct + email_validity_pct + id_uniqueness_pct) / 4 >= 70 THEN '🟠 Fair'
        ELSE '🔴 Poor'
    END as quality_rating
FROM quality_metrics;
```

### 7. 📋 **Financial Reporting (Budget vs Actual)**
*Use Case: Monthly closes, variance analysis*

```sql
-- Budget vs Actual variance analysis
WITH actual_performance AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) as month,
        department,
        SUM(CASE WHEN transaction_type = 'Revenue' THEN amount ELSE 0 END) as actual_revenue,
        SUM(CASE WHEN transaction_type = 'Expense' THEN amount ELSE 0 END) as actual_expenses
    FROM financial_transactions 
    WHERE EXTRACT(YEAR FROM transaction_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY DATE_TRUNC('month', transaction_date), department
),
budget_vs_actual AS (
    SELECT 
        b.month,
        b.department,
        b.budgeted_revenue,
        b.budgeted_expenses,
        COALESCE(a.actual_revenue, 0) as actual_revenue,
        COALESCE(a.actual_expenses, 0) as actual_expenses
    FROM budget_data b
    LEFT JOIN actual_performance a ON b.month = a.month AND b.department = a.department
    WHERE EXTRACT(YEAR FROM b.month) = EXTRACT(YEAR FROM CURRENT_DATE)
)
SELECT 
    month,
    department,
    budgeted_revenue,
    actual_revenue,
    budgeted_expenses,
    actual_expenses,
    
    -- Variance calculations
    actual_revenue - budgeted_revenue as revenue_variance,
    actual_expenses - budgeted_expenses as expense_variance,
    
    -- Percentage variances
    CASE 
        WHEN budgeted_revenue > 0 THEN 
            ROUND((actual_revenue - budgeted_revenue) / budgeted_revenue * 100, 2)
        ELSE NULL 
    END as revenue_variance_pct,
    
    CASE 
        WHEN budgeted_expenses > 0 THEN 
            ROUND((actual_expenses - budgeted_expenses) / budgeted_expenses * 100, 2)
        ELSE NULL 
    END as expense_variance_pct,
    
    -- Performance indicators
    CASE 
        WHEN actual_revenue >= budgeted_revenue * 1.05 THEN '🟢 Above Target'
        WHEN actual_revenue >= budgeted_revenue * 0.95 THEN '🟡 On Target'
        ELSE '🔴 Below Target'
    END as revenue_status,
    
    CASE 
        WHEN actual_expenses <= budgeted_expenses * 1.05 THEN '🟢 Under Budget'
        WHEN actual_expenses <= budgeted_expenses * 1.15 THEN '🟡 Near Budget'
        ELSE '🔴 Over Budget'
    END as expense_status
    
FROM budget_vs_actual
ORDER BY month DESC, department;
```

### 8. 🎯 **A/B Testing Analysis**
*Use Case: Campaign testing, conversion optimization*

```sql
-- A/B test statistical analysis with confidence intervals
WITH test_results AS (
    SELECT 
        test_group,
        COUNT(*) as participants,
        SUM(CASE WHEN converted = TRUE THEN 1 ELSE 0 END) as conversions,
        ROUND(AVG(CASE WHEN converted = TRUE THEN 1.0 ELSE 0.0 END) * 100, 2) as conversion_rate_pct
    FROM ab_test_data 
    WHERE test_name = 'email_campaign_q1_2024'
    GROUP BY test_group
),
statistical_analysis AS (
    SELECT 
        tr.*,
        -- Calculate standard error for confidence intervals
        SQRT(
            (conversion_rate_pct / 100) * (1 - conversion_rate_pct / 100) / participants
        ) as standard_error
    FROM test_results tr
),
control_metrics AS (
    SELECT conversion_rate_pct as control_conversion_rate
    FROM statistical_analysis 
    WHERE test_group = 'Control'
)
SELECT 
    sa.test_group,
    sa.participants,
    sa.conversions,
    sa.conversion_rate_pct,
    
    -- Confidence intervals (95%)
    ROUND(sa.conversion_rate_pct - (1.96 * sa.standard_error * 100), 2) as lower_ci_95,
    ROUND(sa.conversion_rate_pct + (1.96 * sa.standard_error * 100), 2) as upper_ci_95,
    
    -- Comparison to control
    CASE 
        WHEN sa.test_group != 'Control' THEN
            ROUND(sa.conversion_rate_pct - cm.control_conversion_rate, 2)
        ELSE NULL 
    END as lift_percentage_points,
    
    CASE 
        WHEN sa.test_group != 'Control' AND cm.control_conversion_rate > 0 THEN
            ROUND((sa.conversion_rate_pct - cm.control_conversion_rate) / cm.control_conversion_rate * 100, 2)
        ELSE NULL 
    END as relative_lift_pct,
    
    -- Statistical significance indicator
    CASE 
        WHEN sa.test_group != 'Control' AND sa.participants >= 100 AND 
             ABS(sa.conversion_rate_pct - cm.control_conversion_rate) > (1.96 * sa.standard_error * 100) 
        THEN '✅ Statistically Significant'
        WHEN sa.test_group != 'Control' 
        THEN '❌ Not Significant'
        ELSE 'Control Group'
    END as significance_status
    
FROM statistical_analysis sa
CROSS JOIN control_metrics cm
ORDER BY sa.conversion_rate_pct DESC;
```

## 🛠️ How to Use These Templates

### 1. **Adaptation Checklist**
- [ ] Update table and column names to match your schema
- [ ] Adjust date ranges for your business cycle
- [ ] Modify business rules to fit your industry
- [ ] Test with a small dataset first

### 2. **Customization Tips**
- **Add your business metrics**: Revenue, units, customers, etc.
- **Include your specific filters**: Product categories, regions, customer types
- **Adjust time periods**: Weekly, monthly, quarterly based on your reporting needs
- **Add your KPIs**: Industry-specific metrics and benchmarks

### 3. **Quick Reference Guide**

| Business Question | Template to Use | Key Metrics |
|-------------------|-----------------|-------------|
| "How did we perform this month?" | Performance Dashboard | Revenue, customers, growth % |
| "Who are our top customers/products?" | Top N Analysis | Rankings, contribution % |
| "Are we growing or declining?" | Trend Analysis | Period-over-period growth |
| "Which customers should we focus on?" | Customer Segmentation | RFM scores, segments |
| "How well do we retain customers?" | Cohort Analysis | Retention rates by month |
| "Is our data reliable?" | Data Quality Assessment | Completeness, validity % |
| "Are we meeting our budget?" | Financial Reporting | Variance analysis |
| "Did our campaign work?" | A/B Testing Analysis | Conversion rates, statistical significance |

## 🎯 Next Steps

1. **Save this as a bookmark** - You'll reference these patterns constantly
2. **Practice with your data** - Adapt one template per week to your actual business data
3. **Build your library** - Add your own company-specific variations
4. **Share with your team** - These patterns become team standards

## 💡 Pro Tips for Business Analysts

1. **Always include business context** in your queries (comments explaining what the numbers mean)
2. **Add data validation** checks to catch unusual results
3. **Include time stamps** in your results for audit trails
4. **Use meaningful column names** that business stakeholders understand
5. **Add performance indicators** (🟢🟡🔴) to make results scannable

---
**💼 Remember:** These templates are starting points. The real value comes from understanding the business logic behind them and adapting them to your specific organizational needs.
