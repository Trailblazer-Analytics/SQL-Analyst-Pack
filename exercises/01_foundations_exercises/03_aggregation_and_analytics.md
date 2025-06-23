# Exercise 3: Advanced Aggregation and Window Functions

## Business Context

You're a senior data analyst at **FinTech Insights**, a financial services company. The executive team needs comprehensive analytics for their quarterly business review. You'll analyze transaction patterns, customer behavior trends, and performance metrics using advanced SQL aggregation and window functions.

## Learning Objectives

By completing this exercise, you will:

- Master advanced GROUP BY and aggregation functions
- Understand window functions and their business applications
- Learn to calculate running totals, moving averages, and rankings
- Practice building comprehensive analytical dashboards with SQL

## Database Schema

You'll be working with these tables:

```sql
-- accounts table
accounts (
    account_id INT PRIMARY KEY,
    customer_id INT,
    account_type VARCHAR(50), -- 'checking', 'savings', 'credit', 'investment'
    account_status VARCHAR(20), -- 'active', 'inactive', 'closed'
    opening_date DATE,
    current_balance DECIMAL(15,2),
    credit_limit DECIMAL(15,2)
)

-- transactions table
transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    transaction_date TIMESTAMP,
    transaction_type VARCHAR(50), -- 'deposit', 'withdrawal', 'transfer', 'payment'
    amount DECIMAL(15,2),
    category VARCHAR(50), -- 'groceries', 'entertainment', 'bills', etc.
    merchant_name VARCHAR(100),
    is_online BOOLEAN
)

-- customers table
customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    city VARCHAR(50),
    state VARCHAR(50),
    customer_segment VARCHAR(20), -- 'premium', 'standard', 'basic'
    registration_date DATE
)

-- products table
products (
    product_id INT PRIMARY KEY,
    customer_id INT,
    product_type VARCHAR(50), -- 'loan', 'credit_card', 'insurance'
    product_name VARCHAR(100),
    monthly_fee DECIMAL(10,2),
    interest_rate DECIMAL(5,4),
    signup_date DATE,
    status VARCHAR(20) -- 'active', 'inactive', 'cancelled'
)
```

## Tasks

### Task 1: Customer Transaction Analysis

**Business Question**: "What are the transaction patterns and trends for our customers over the past year?"

Create a comprehensive analysis showing:

- Monthly transaction volumes and amounts by customer segment
- Average transaction size trends over time
- Most popular transaction categories by month
- Peak transaction hours and days of the week

Requirements:

- Include rolling 3-month averages for transaction amounts
- Calculate month-over-month growth rates
- Identify seasonal patterns in spending

**Expected Skills**: Complex aggregations, window functions, date functions

### Task 2: Account Performance Metrics

**Business Question**: "How are our different account types performing in terms of growth and customer engagement?"

Build a query that shows:

- Account type performance with growth metrics
- Customer retention rates by account type
- Average account balance trends with percentile rankings
- Cross-selling success rates (customers with multiple account types)

Requirements:

- Use window functions for ranking and percentiles
- Calculate cumulative metrics
- Include year-over-year comparisons

**Expected Skills**: Window functions, CTEs, advanced aggregations

### Task 3: Customer Segmentation and Lifetime Value

**Business Question**: "What are the characteristics and value of our different customer segments?"

Analyze customer behavior showing:

- Customer lifetime value by segment
- Transaction frequency and recency analysis
- Product adoption patterns
- Revenue per customer trends over time

Requirements:

- Calculate RFM analysis (Recency, Frequency, Monetary)
- Use window functions for customer ranking
- Include cohort-based analysis

**Expected Skills**: Complex calculations, multiple CTEs, advanced analytics

### Task 4: Advanced Business Intelligence Dashboard

**Business Question**: "Create a comprehensive executive dashboard with key performance indicators."

Build queries for a dashboard showing:

- Daily/Monthly/Quarterly KPIs with trends
- Customer acquisition and churn metrics
- Revenue analysis by product and segment
- Predictive indicators and alerts

Requirements:

- Include multiple time horizons (daily, weekly, monthly, quarterly)
- Calculate leading and lagging indicators
- Use advanced window functions for forecasting trends

**Expected Skills**: All previous skills plus advanced business logic

## Starter Code

### Understanding Data Distribution

```sql
-- Transaction volume by month
SELECT 
    DATE_TRUNC('month', transaction_date) as month,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount
FROM transactions
WHERE transaction_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY month;

-- Customer segments overview
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(current_balance) as avg_balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.account_status = 'active'
GROUP BY customer_segment;

-- Account types distribution
SELECT 
    account_type,
    COUNT(*) as account_count,
    AVG(current_balance) as avg_balance,
    SUM(current_balance) as total_balance
FROM accounts
WHERE account_status = 'active'
GROUP BY account_type;
```

## Solutions

### Task 1 Solution: Customer Transaction Analysis

```sql
-- Customer Transaction Analysis with Trends
WITH monthly_transactions AS (
    SELECT 
        DATE_TRUNC('month', t.transaction_date) as month,
        c.customer_segment,
        t.category,
        EXTRACT(hour FROM t.transaction_date) as hour_of_day,
        EXTRACT(dow FROM t.transaction_date) as day_of_week,
        COUNT(*) as transaction_count,
        SUM(t.amount) as total_amount,
        AVG(t.amount) as avg_transaction_size
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', t.transaction_date), c.customer_segment, 
             t.category, EXTRACT(hour FROM t.transaction_date), 
             EXTRACT(dow FROM t.transaction_date)
),
segment_trends AS (
    SELECT 
        month,
        customer_segment,
        SUM(transaction_count) as monthly_transactions,
        SUM(total_amount) as monthly_amount,
        AVG(avg_transaction_size) as avg_size,
        -- Rolling 3-month average
        AVG(SUM(total_amount)) OVER (
            PARTITION BY customer_segment 
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as rolling_3m_avg,
        -- Month-over-month growth
        LAG(SUM(total_amount)) OVER (
            PARTITION BY customer_segment 
            ORDER BY month
        ) as prev_month_amount
    FROM monthly_transactions
    GROUP BY month, customer_segment
),
popular_categories AS (
    SELECT 
        month,
        category,
        SUM(total_amount) as category_amount,
        ROW_NUMBER() OVER (
            PARTITION BY month 
            ORDER BY SUM(total_amount) DESC
        ) as category_rank
    FROM monthly_transactions
    GROUP BY month, category
),
peak_hours AS (
    SELECT 
        hour_of_day,
        COUNT(*) as transaction_count,
        RANK() OVER (ORDER BY COUNT(*) DESC) as hour_rank
    FROM monthly_transactions
    GROUP BY hour_of_day
)
SELECT 
    st.month,
    st.customer_segment,
    st.monthly_transactions,
    st.monthly_amount,
    st.avg_size,
    st.rolling_3m_avg,
    ROUND(
        (st.monthly_amount - st.prev_month_amount) * 100.0 / st.prev_month_amount, 2
    ) as mom_growth_percent,
    pc.category as top_category,
    ph.hour_of_day as peak_hour
FROM segment_trends st
LEFT JOIN popular_categories pc ON st.month = pc.month AND pc.category_rank = 1
CROSS JOIN (SELECT hour_of_day FROM peak_hours WHERE hour_rank = 1) ph
ORDER BY st.month, st.customer_segment;
```

**Business Insight**: Identifies seasonal spending patterns and helps optimize marketing campaigns and resource allocation.

### Task 2 Solution: Account Performance Metrics

```sql
-- Account Performance with Growth and Retention Metrics
WITH account_metrics AS (
    SELECT 
        a.account_type,
        c.customer_segment,
        COUNT(DISTINCT a.account_id) as total_accounts,
        AVG(a.current_balance) as avg_balance,
        SUM(a.current_balance) as total_balance,
        -- Balance percentiles
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY a.current_balance) as balance_p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY a.current_balance) as balance_median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY a.current_balance) as balance_p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY a.current_balance) as balance_p90
    FROM accounts a
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE a.account_status = 'active'
    GROUP BY a.account_type, c.customer_segment
),
balance_trends AS (
    SELECT 
        a.account_type,
        DATE_TRUNC('month', t.transaction_date) as month,
        AVG(a.current_balance) as avg_monthly_balance,
        LAG(AVG(a.current_balance)) OVER (
            PARTITION BY a.account_type 
            ORDER BY DATE_TRUNC('month', t.transaction_date)
        ) as prev_month_balance
    FROM accounts a
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY a.account_type, DATE_TRUNC('month', t.transaction_date)
),
customer_retention AS (
    SELECT 
        a.account_type,
        COUNT(DISTINCT CASE 
            WHEN a.opening_date <= CURRENT_DATE - INTERVAL '12 months' 
            THEN a.customer_id 
        END) as customers_12m_ago,
        COUNT(DISTINCT CASE 
            WHEN a.opening_date <= CURRENT_DATE - INTERVAL '12 months' 
            AND a.account_status = 'active'
            THEN a.customer_id 
        END) as retained_customers,
        -- Cross-selling analysis
        AVG(customer_accounts.account_count) as avg_accounts_per_customer
    FROM accounts a
    JOIN (
        SELECT customer_id, COUNT(*) as account_count
        FROM accounts
        WHERE account_status = 'active'
        GROUP BY customer_id
    ) customer_accounts ON a.customer_id = customer_accounts.customer_id
    GROUP BY a.account_type
)
SELECT 
    am.account_type,
    am.customer_segment,
    am.total_accounts,
    am.avg_balance,
    am.balance_median,
    am.balance_p90,
    bt.avg_monthly_balance,
    ROUND(
        (bt.avg_monthly_balance - bt.prev_month_balance) * 100.0 / bt.prev_month_balance, 2
    ) as balance_growth_percent,
    ROUND(
        cr.retained_customers * 100.0 / cr.customers_12m_ago, 2
    ) as retention_rate_percent,
    cr.avg_accounts_per_customer
FROM account_metrics am
LEFT JOIN balance_trends bt ON am.account_type = bt.account_type
LEFT JOIN customer_retention cr ON am.account_type = cr.account_type
WHERE bt.month = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
ORDER BY am.account_type, am.customer_segment;
```

**Business Insight**: Provides comprehensive account performance metrics for strategic planning and product optimization.

### Task 3 Solution: Customer Segmentation and Lifetime Value

```sql
-- Customer Lifetime Value and RFM Analysis
WITH customer_transactions AS (
    SELECT 
        c.customer_id,
        c.customer_segment,
        c.registration_date,
        COUNT(t.transaction_id) as total_transactions,
        SUM(t.amount) as total_spent,
        AVG(t.amount) as avg_transaction_amount,
        MAX(t.transaction_date) as last_transaction_date,
        MIN(t.transaction_date) as first_transaction_date,
        -- Recency (days since last transaction)
        CURRENT_DATE - MAX(t.transaction_date)::date as recency_days,
        -- Frequency (transactions per month since first transaction)
        COUNT(t.transaction_id)::float / 
        GREATEST(EXTRACT(days FROM CURRENT_DATE - MIN(t.transaction_date)::date) / 30.0, 1) as frequency_per_month
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY c.customer_id, c.customer_segment, c.registration_date
),
rfm_scores AS (
    SELECT 
        *,
        -- RFM Scoring (1-5 scale)
        CASE 
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END as recency_score,
        CASE 
            WHEN frequency_per_month >= 10 THEN 5
            WHEN frequency_per_month >= 5 THEN 4
            WHEN frequency_per_month >= 2 THEN 3
            WHEN frequency_per_month >= 1 THEN 2
            ELSE 1
        END as frequency_score,
        CASE 
            WHEN total_spent >= 10000 THEN 5
            WHEN total_spent >= 5000 THEN 4
            WHEN total_spent >= 2000 THEN 3
            WHEN total_spent >= 500 THEN 2
            ELSE 1
        END as monetary_score
    FROM customer_transactions
),
customer_ltv AS (
    SELECT 
        *,
        recency_score + frequency_score + monetary_score as rfm_total,
        -- Customer Lifetime Value calculation
        (total_spent / GREATEST(EXTRACT(days FROM CURRENT_DATE - registration_date) / 365.0, 0.1)) * 3 as estimated_annual_value,
        -- Customer segments based on RFM
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost Customers'
            ELSE 'Regular Customers'
        END as customer_type
    FROM rfm_scores
),
product_adoption AS (
    SELECT 
        c.customer_id,
        COUNT(DISTINCT p.product_type) as products_owned,
        STRING_AGG(DISTINCT p.product_type, ', ') as product_mix
    FROM customers c
    LEFT JOIN products p ON c.customer_id = p.customer_id
    WHERE p.status = 'active'
    GROUP BY c.customer_id
)
SELECT 
    ltv.customer_segment,
    ltv.customer_type,
    COUNT(*) as customer_count,
    AVG(ltv.total_spent) as avg_total_spent,
    AVG(ltv.estimated_annual_value) as avg_annual_value,
    AVG(ltv.recency_days) as avg_recency_days,
    AVG(ltv.frequency_per_month) as avg_frequency_per_month,
    AVG(pa.products_owned) as avg_products_per_customer,
    -- Customer rankings
    AVG(ltv.rfm_total) as avg_rfm_score,
    SUM(ltv.estimated_annual_value) as segment_total_value
FROM customer_ltv ltv
LEFT JOIN product_adoption pa ON ltv.customer_id = pa.customer_id
GROUP BY ltv.customer_segment, ltv.customer_type
ORDER BY segment_total_value DESC;
```

**Business Insight**: Enables targeted customer retention strategies and personalized product recommendations based on customer value and behavior patterns.

### Task 4 Solution: Executive Dashboard KPIs

```sql
-- Executive Dashboard with Comprehensive KPIs
WITH time_periods AS (
    SELECT 
        'daily' as period_type,
        DATE_TRUNC('day', CURRENT_DATE) as current_period,
        DATE_TRUNC('day', CURRENT_DATE - INTERVAL '1 day') as previous_period
    UNION ALL
    SELECT 
        'weekly',
        DATE_TRUNC('week', CURRENT_DATE),
        DATE_TRUNC('week', CURRENT_DATE - INTERVAL '1 week')
    UNION ALL
    SELECT 
        'monthly',
        DATE_TRUNC('month', CURRENT_DATE),
        DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
    UNION ALL
    SELECT 
        'quarterly',
        DATE_TRUNC('quarter', CURRENT_DATE),
        DATE_TRUNC('quarter', CURRENT_DATE - INTERVAL '3 months')
),
kpi_metrics AS (
    SELECT 
        tp.period_type,
        -- Revenue Metrics
        SUM(CASE WHEN t.transaction_date >= tp.current_period THEN t.amount ELSE 0 END) as current_revenue,
        SUM(CASE WHEN t.transaction_date >= tp.previous_period 
                 AND t.transaction_date < tp.current_period THEN t.amount ELSE 0 END) as previous_revenue,
        
        -- Transaction Metrics
        COUNT(CASE WHEN t.transaction_date >= tp.current_period THEN t.transaction_id END) as current_transactions,
        COUNT(CASE WHEN t.transaction_date >= tp.previous_period 
                   AND t.transaction_date < tp.current_period THEN t.transaction_id END) as previous_transactions,
        
        -- Customer Metrics
        COUNT(DISTINCT CASE WHEN t.transaction_date >= tp.current_period THEN a.customer_id END) as active_customers_current,
        COUNT(DISTINCT CASE WHEN t.transaction_date >= tp.previous_period 
                            AND t.transaction_date < tp.current_period THEN a.customer_id END) as active_customers_previous,
        
        -- Average Transaction Value
        AVG(CASE WHEN t.transaction_date >= tp.current_period THEN t.amount END) as avg_transaction_current,
        AVG(CASE WHEN t.transaction_date >= tp.previous_period 
                 AND t.transaction_date < tp.current_period THEN t.amount END) as avg_transaction_previous
    FROM time_periods tp
    CROSS JOIN transactions t
    JOIN accounts a ON t.account_id = a.account_id
    GROUP BY tp.period_type, tp.current_period, tp.previous_period
),
customer_acquisition AS (
    SELECT 
        tp.period_type,
        COUNT(CASE WHEN c.registration_date >= tp.current_period THEN c.customer_id END) as new_customers_current,
        COUNT(CASE WHEN c.registration_date >= tp.previous_period 
                   AND c.registration_date < tp.current_period THEN c.customer_id END) as new_customers_previous
    FROM time_periods tp
    CROSS JOIN customers c
    GROUP BY tp.period_type
),
churn_analysis AS (
    SELECT 
        tp.period_type,
        -- Customers who were active in previous period but not current
        COUNT(DISTINCT prev_active.customer_id) - COUNT(DISTINCT curr_active.customer_id) as churned_customers
    FROM time_periods tp
    LEFT JOIN (
        SELECT DISTINCT a.customer_id, DATE_TRUNC('day', t.transaction_date) as activity_date
        FROM accounts a
        JOIN transactions t ON a.account_id = t.account_id
    ) prev_active ON prev_active.activity_date >= tp.previous_period 
                  AND prev_active.activity_date < tp.current_period
    LEFT JOIN (
        SELECT DISTINCT a.customer_id, DATE_TRUNC('day', t.transaction_date) as activity_date
        FROM accounts a
        JOIN transactions t ON a.account_id = t.account_id
    ) curr_active ON curr_active.activity_date >= tp.current_period
                  AND curr_active.customer_id = prev_active.customer_id
    GROUP BY tp.period_type
),
predictive_indicators AS (
    SELECT 
        -- Leading indicators
        COUNT(DISTINCT CASE WHEN a.opening_date >= CURRENT_DATE - INTERVAL '7 days' 
                           THEN a.customer_id END) as new_accounts_7d,
        AVG(CASE WHEN t.transaction_date >= CURRENT_DATE - INTERVAL '7 days' 
                 THEN t.amount END) as avg_transaction_7d,
        
        -- Risk indicators
        COUNT(DISTINCT CASE WHEN a.current_balance < 100 AND a.account_type = 'checking' 
                           THEN a.customer_id END) as low_balance_customers,
        COUNT(DISTINCT CASE WHEN last_transaction.days_since_last > 30 
                           THEN last_transaction.customer_id END) as inactive_customers
    FROM accounts a
    LEFT JOIN transactions t ON a.account_id = t.account_id
    LEFT JOIN (
        SELECT 
            a.customer_id,
            CURRENT_DATE - MAX(t.transaction_date)::date as days_since_last
        FROM accounts a
        JOIN transactions t ON a.account_id = t.account_id
        GROUP BY a.customer_id
    ) last_transaction ON a.customer_id = last_transaction.customer_id
)
SELECT 
    km.period_type,
    km.current_revenue,
    km.previous_revenue,
    ROUND((km.current_revenue - km.previous_revenue) * 100.0 / NULLIF(km.previous_revenue, 0), 2) as revenue_growth_percent,
    
    km.current_transactions,
    km.previous_transactions,
    ROUND((km.current_transactions - km.previous_transactions) * 100.0 / NULLIF(km.previous_transactions, 0), 2) as transaction_growth_percent,
    
    km.active_customers_current,
    km.active_customers_previous,
    ca.new_customers_current,
    ch.churned_customers,
    
    km.avg_transaction_current,
    km.avg_transaction_previous,
    ROUND((km.avg_transaction_current - km.avg_transaction_previous) * 100.0 / NULLIF(km.avg_transaction_previous, 0), 2) as avg_transaction_growth_percent,
    
    -- Predictive indicators (only for daily period)
    CASE WHEN km.period_type = 'daily' THEN pi.new_accounts_7d END as new_accounts_7d,
    CASE WHEN km.period_type = 'daily' THEN pi.low_balance_customers END as at_risk_customers,
    CASE WHEN km.period_type = 'daily' THEN pi.inactive_customers END as inactive_customers
FROM kpi_metrics km
LEFT JOIN customer_acquisition ca ON km.period_type = ca.period_type
LEFT JOIN churn_analysis ch ON km.period_type = ch.period_type
CROSS JOIN predictive_indicators pi
ORDER BY 
    CASE km.period_type 
        WHEN 'daily' THEN 1 
        WHEN 'weekly' THEN 2 
        WHEN 'monthly' THEN 3 
        WHEN 'quarterly' THEN 4 
    END;
```

**Business Insight**: Provides executives with comprehensive KPIs and predictive indicators for data-driven decision making.

## Extension Exercises

### Advanced Challenge 1: Forecasting and Trend Analysis

Build predictive models using SQL to forecast:

- Monthly revenue trends using linear regression
- Customer churn probability based on transaction patterns
- Seasonal adjustment factors for business planning

### Advanced Challenge 2: Advanced Cohort Analysis

Create comprehensive cohort analysis showing:

- Customer acquisition cohorts by month
- Revenue cohorts with retention curves
- Product adoption cohorts across customer segments

### Advanced Challenge 3: Real-time Analytics

Design queries for real-time dashboards:

- Streaming transaction alerts and anomaly detection
- Real-time customer segmentation updates
- Dynamic pricing optimization based on transaction patterns

## Business Impact

These advanced analytics enable:

- **Executive Leadership**: Comprehensive KPI dashboards for strategic decisions
- **Marketing Teams**: Customer segmentation and lifetime value optimization
- **Product Teams**: Account performance insights for product development
- **Risk Management**: Predictive indicators for customer churn and credit risk

## Key Learning Outcomes

✅ **Advanced Aggregations**: Master complex GROUP BY operations and statistical functions  
✅ **Window Functions**: Use ROW_NUMBER, RANK, LAG/LEAD, and moving averages  
✅ **Business Intelligence**: Build comprehensive analytical dashboards  
✅ **Performance Optimization**: Write efficient queries for large-scale analytics  
✅ **Predictive Analytics**: Use SQL for forecasting and trend analysis

---

**Next Exercise**: `04_performance_optimization.md` - Query optimization and performance tuning
