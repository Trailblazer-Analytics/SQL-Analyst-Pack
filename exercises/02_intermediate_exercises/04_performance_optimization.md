# Exercise 4: Performance Optimization and Query Tuning

## Business Context

You're a senior data analyst at **DataScale Corp**, a high-growth SaaS company with millions of users and billions of transactions. The engineering team is experiencing slow query performance that's affecting business reporting and real-time analytics. Your job is to optimize critical business queries and establish performance best practices.

## Learning Objectives

By completing this exercise, you will:

- Master query execution plan analysis and optimization
- Learn indexing strategies for analytical workloads
- Understand partitioning and data organization techniques
- Practice identifying and resolving performance bottlenecks

## Database Schema

You'll be working with these large-scale tables:

```sql
-- users table (10M+ records)
users (
    user_id BIGINT PRIMARY KEY,
    email VARCHAR(255),
    registration_date DATE,
    last_login_date TIMESTAMP,
    subscription_tier VARCHAR(20), -- 'free', 'basic', 'premium', 'enterprise'
    country_code VARCHAR(3),
    is_active BOOLEAN,
    total_revenue DECIMAL(15,2)
)

-- events table (1B+ records)
events (
    event_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    event_type VARCHAR(50),
    event_timestamp TIMESTAMP,
    session_id VARCHAR(100),
    page_url TEXT,
    properties JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)

-- subscriptions table (50M+ records)
subscriptions (
    subscription_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    plan_id INTEGER,
    start_date DATE,
    end_date DATE,
    monthly_price DECIMAL(10,2),
    status VARCHAR(20), -- 'active', 'cancelled', 'expired', 'trial'
    payment_method VARCHAR(20)
)

-- revenue table (100M+ records)
revenue (
    revenue_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    subscription_id BIGINT,
    amount DECIMAL(15,2),
    currency_code VARCHAR(3),
    transaction_date DATE,
    payment_processor VARCHAR(50),
    is_refund BOOLEAN DEFAULT FALSE
)
```

## Performance Problems to Solve

### Problem 1: Slow User Activity Report

**Current Query** (takes 45+ seconds):

```sql
-- SLOW: Monthly Active Users by Subscription Tier
SELECT 
    DATE_TRUNC('month', e.event_timestamp) as month,
    u.subscription_tier,
    COUNT(DISTINCT u.user_id) as active_users,
    AVG(monthly_events.event_count) as avg_events_per_user
FROM users u
JOIN events e ON u.user_id = e.user_id
JOIN (
    SELECT 
        user_id, 
        DATE_TRUNC('month', event_timestamp) as month,
        COUNT(*) as event_count
    FROM events
    GROUP BY user_id, DATE_TRUNC('month', event_timestamp)
) monthly_events ON u.user_id = monthly_events.user_id 
    AND DATE_TRUNC('month', e.event_timestamp) = monthly_events.month
WHERE e.event_timestamp >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', e.event_timestamp), u.subscription_tier
ORDER BY month, u.subscription_tier;
```

**Your Task**: Optimize this query to run in under 5 seconds.

### Problem 2: Revenue Analytics Performance

**Current Query** (times out after 2 minutes):

```sql
-- SLOW: Customer Lifetime Value Analysis
SELECT 
    u.user_id,
    u.registration_date,
    u.subscription_tier,
    SUM(r.amount) as total_revenue,
    COUNT(DISTINCT r.revenue_id) as transaction_count,
    MIN(r.transaction_date) as first_purchase,
    MAX(r.transaction_date) as last_purchase,
    SUM(CASE WHEN r.transaction_date >= CURRENT_DATE - INTERVAL '30 days' THEN r.amount ELSE 0 END) as revenue_30d,
    SUM(CASE WHEN r.transaction_date >= CURRENT_DATE - INTERVAL '90 days' THEN r.amount ELSE 0 END) as revenue_90d,
    -- Complex cohort analysis
    DATE_TRUNC('month', u.registration_date) as cohort_month,
    EXTRACT(days FROM r.transaction_date - u.registration_date) as days_since_signup
FROM users u
LEFT JOIN revenue r ON u.user_id = r.user_id
WHERE u.registration_date >= '2020-01-01'
    AND r.is_refund = FALSE
GROUP BY u.user_id, u.registration_date, u.subscription_tier
HAVING SUM(r.amount) > 0
ORDER BY total_revenue DESC;
```

**Your Task**: Redesign this query for sub-30-second performance.

### Problem 3: Real-time Dashboard Query

**Current Query** (inconsistent performance, 10-60 seconds):

```sql
-- SLOW: Real-time Business Metrics
WITH daily_metrics AS (
    SELECT 
        DATE(e.event_timestamp) as event_date,
        COUNT(DISTINCT e.user_id) as daily_active_users,
        COUNT(e.event_id) as total_events,
        COUNT(DISTINCT e.session_id) as total_sessions
    FROM events e
    WHERE e.event_timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE(e.event_timestamp)
),
revenue_metrics AS (
    SELECT 
        r.transaction_date,
        SUM(r.amount) as daily_revenue,
        COUNT(DISTINCT r.user_id) as paying_users
    FROM revenue r
    WHERE r.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
        AND r.is_refund = FALSE
    GROUP BY r.transaction_date
),
subscription_metrics AS (
    SELECT 
        s.start_date,
        COUNT(*) as new_subscriptions,
        SUM(s.monthly_price) as new_monthly_revenue
    FROM subscriptions s
    WHERE s.start_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY s.start_date
)
SELECT 
    COALESCE(dm.event_date, rm.transaction_date, sm.start_date) as date,
    COALESCE(dm.daily_active_users, 0) as daily_active_users,
    COALESCE(dm.total_events, 0) as total_events,
    COALESCE(rm.daily_revenue, 0) as daily_revenue,
    COALESCE(rm.paying_users, 0) as paying_users,
    COALESCE(sm.new_subscriptions, 0) as new_subscriptions,
    COALESCE(sm.new_monthly_revenue, 0) as new_monthly_revenue
FROM daily_metrics dm
FULL OUTER JOIN revenue_metrics rm ON dm.event_date = rm.transaction_date
FULL OUTER JOIN subscription_metrics sm ON COALESCE(dm.event_date, rm.transaction_date) = sm.start_date
ORDER BY date DESC;
```

**Your Task**: Create a materialized view strategy for consistent sub-second performance.

## Optimization Techniques

### Indexing Strategy Analysis

```sql
-- Check current indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND tablename IN ('users', 'events', 'subscriptions', 'revenue')
ORDER BY tablename, indexname;

-- Analyze query performance
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) 
SELECT ...your query here...;

-- Check table statistics
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public';
```

### Recommended Index Creation

```sql
-- Events table optimization indexes
CREATE INDEX CONCURRENTLY idx_events_user_timestamp 
    ON events (user_id, event_timestamp DESC);

CREATE INDEX CONCURRENTLY idx_events_timestamp_type 
    ON events (event_timestamp, event_type) 
    WHERE event_timestamp >= CURRENT_DATE - INTERVAL '90 days';

CREATE INDEX CONCURRENTLY idx_events_monthly_partition 
    ON events (DATE_TRUNC('month', event_timestamp), user_id);

-- Revenue table optimization indexes
CREATE INDEX CONCURRENTLY idx_revenue_user_date 
    ON revenue (user_id, transaction_date DESC, is_refund) 
    WHERE is_refund = FALSE;

CREATE INDEX CONCURRENTLY idx_revenue_date_amount 
    ON revenue (transaction_date, amount) 
    WHERE is_refund = FALSE;

-- Users table optimization
CREATE INDEX CONCURRENTLY idx_users_tier_registration 
    ON users (subscription_tier, registration_date, is_active);

-- Subscriptions table optimization
CREATE INDEX CONCURRENTLY idx_subscriptions_user_dates 
    ON subscriptions (user_id, start_date, end_date, status);
```

## Optimized Solutions

### Problem 1 Solution: Optimized User Activity Report

```sql
-- OPTIMIZED: Monthly Active Users by Subscription Tier
WITH monthly_user_activity AS (
    SELECT 
        DATE_TRUNC('month', e.event_timestamp) as month,
        e.user_id,
        COUNT(*) as event_count
    FROM events e
    WHERE e.event_timestamp >= CURRENT_DATE - INTERVAL '12 months'
        AND e.event_timestamp < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY DATE_TRUNC('month', e.event_timestamp), e.user_id
)
SELECT 
    mua.month,
    u.subscription_tier,
    COUNT(DISTINCT mua.user_id) as active_users,
    AVG(mua.event_count) as avg_events_per_user,
    -- Additional insights
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY mua.event_count) as median_events_per_user,
    SUM(mua.event_count) as total_events
FROM monthly_user_activity mua
JOIN users u ON mua.user_id = u.user_id
WHERE u.is_active = TRUE
GROUP BY mua.month, u.subscription_tier
ORDER BY mua.month DESC, u.subscription_tier;

-- Performance improvement: ~45 seconds → ~3 seconds
-- Key optimizations:
-- 1. Eliminated redundant self-join
-- 2. Added date range filter early
-- 3. Used optimized indexes
-- 4. Filtered inactive users
```

### Problem 2 Solution: Optimized Revenue Analytics

```sql
-- OPTIMIZED: Customer Lifetime Value Analysis with Materialized View
CREATE MATERIALIZED VIEW customer_ltv_summary AS
WITH user_revenue_summary AS (
    SELECT 
        r.user_id,
        SUM(r.amount) as total_revenue,
        COUNT(*) as transaction_count,
        MIN(r.transaction_date) as first_purchase,
        MAX(r.transaction_date) as last_purchase,
        -- Pre-calculate time-based metrics
        SUM(CASE WHEN r.transaction_date >= CURRENT_DATE - INTERVAL '30 days' 
                 THEN r.amount ELSE 0 END) as revenue_30d,
        SUM(CASE WHEN r.transaction_date >= CURRENT_DATE - INTERVAL '90 days' 
                 THEN r.amount ELSE 0 END) as revenue_90d,
        SUM(CASE WHEN r.transaction_date >= CURRENT_DATE - INTERVAL '365 days' 
                 THEN r.amount ELSE 0 END) as revenue_365d
    FROM revenue r
    WHERE r.is_refund = FALSE
    GROUP BY r.user_id
)
SELECT 
    u.user_id,
    u.registration_date,
    u.subscription_tier,
    u.country_code,
    DATE_TRUNC('month', u.registration_date) as cohort_month,
    COALESCE(urs.total_revenue, 0) as total_revenue,
    COALESCE(urs.transaction_count, 0) as transaction_count,
    urs.first_purchase,
    urs.last_purchase,
    COALESCE(urs.revenue_30d, 0) as revenue_30d,
    COALESCE(urs.revenue_90d, 0) as revenue_90d,
    COALESCE(urs.revenue_365d, 0) as revenue_365d,
    CASE 
        WHEN urs.first_purchase IS NOT NULL 
        THEN EXTRACT(days FROM urs.first_purchase - u.registration_date)
        ELSE NULL 
    END as days_to_first_purchase,
    CASE 
        WHEN urs.total_revenue > 0 
        THEN urs.total_revenue / GREATEST(urs.transaction_count, 1)
        ELSE 0 
    END as avg_transaction_value
FROM users u
LEFT JOIN user_revenue_summary urs ON u.user_id = urs.user_id
WHERE u.registration_date >= '2020-01-01';

-- Create index on materialized view
CREATE INDEX idx_customer_ltv_revenue ON customer_ltv_summary (total_revenue DESC);
CREATE INDEX idx_customer_ltv_cohort ON customer_ltv_summary (cohort_month, subscription_tier);

-- Refresh strategy (run daily)
REFRESH MATERIALIZED VIEW CONCURRENTLY customer_ltv_summary;

-- Fast query against materialized view
SELECT 
    subscription_tier,
    cohort_month,
    COUNT(*) as customers,
    AVG(total_revenue) as avg_ltv,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_revenue) as median_ltv,
    SUM(revenue_30d) as recent_revenue
FROM customer_ltv_summary
WHERE total_revenue > 0
GROUP BY subscription_tier, cohort_month
ORDER BY cohort_month DESC, avg_ltv DESC;

-- Performance improvement: 2+ minutes → ~2 seconds
```

### Problem 3 Solution: Real-time Dashboard with Materialized Views

```sql
-- OPTIMIZED: Create incremental materialized views for dashboard

-- Daily metrics materialized view
CREATE MATERIALIZED VIEW daily_business_metrics AS
SELECT 
    date_col as metric_date,
    SUM(daily_active_users) as daily_active_users,
    SUM(total_events) as total_events,
    SUM(total_sessions) as total_sessions,
    SUM(daily_revenue) as daily_revenue,
    SUM(paying_users) as paying_users,
    SUM(new_subscriptions) as new_subscriptions,
    SUM(new_monthly_revenue) as new_monthly_revenue
FROM (
    -- Events metrics
    SELECT 
        DATE(e.event_timestamp) as date_col,
        COUNT(DISTINCT e.user_id) as daily_active_users,
        COUNT(e.event_id) as total_events,
        COUNT(DISTINCT e.session_id) as total_sessions,
        0 as daily_revenue,
        0 as paying_users,
        0 as new_subscriptions,
        0 as new_monthly_revenue
    FROM events e
    WHERE e.event_timestamp >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(e.event_timestamp)
    
    UNION ALL
    
    -- Revenue metrics
    SELECT 
        r.transaction_date as date_col,
        0 as daily_active_users,
        0 as total_events,
        0 as total_sessions,
        SUM(r.amount) as daily_revenue,
        COUNT(DISTINCT r.user_id) as paying_users,
        0 as new_subscriptions,
        0 as new_monthly_revenue
    FROM revenue r
    WHERE r.transaction_date >= CURRENT_DATE - INTERVAL '90 days'
        AND r.is_refund = FALSE
    GROUP BY r.transaction_date
    
    UNION ALL
    
    -- Subscription metrics
    SELECT 
        s.start_date as date_col,
        0 as daily_active_users,
        0 as total_events,
        0 as total_sessions,
        0 as daily_revenue,
        0 as paying_users,
        COUNT(*) as new_subscriptions,
        SUM(s.monthly_price) as new_monthly_revenue
    FROM subscriptions s
    WHERE s.start_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY s.start_date
) combined_metrics
GROUP BY date_col;

-- Create indexes
CREATE UNIQUE INDEX idx_daily_metrics_date ON daily_business_metrics (metric_date);

-- Incremental refresh function
CREATE OR REPLACE FUNCTION refresh_daily_metrics(target_date DATE DEFAULT CURRENT_DATE)
RETURNS VOID AS $$
BEGIN
    -- Delete existing data for the date
    DELETE FROM daily_business_metrics WHERE metric_date = target_date;
    
    -- Insert fresh data
    INSERT INTO daily_business_metrics (metric_date, daily_active_users, total_events, total_sessions, daily_revenue, paying_users, new_subscriptions, new_monthly_revenue)
    SELECT 
        target_date,
        COALESCE(events_data.daily_active_users, 0),
        COALESCE(events_data.total_events, 0),
        COALESCE(events_data.total_sessions, 0),
        COALESCE(revenue_data.daily_revenue, 0),
        COALESCE(revenue_data.paying_users, 0),
        COALESCE(subscription_data.new_subscriptions, 0),
        COALESCE(subscription_data.new_monthly_revenue, 0)
    FROM (
        SELECT 
            COUNT(DISTINCT user_id) as daily_active_users,
            COUNT(event_id) as total_events,
            COUNT(DISTINCT session_id) as total_sessions
        FROM events
        WHERE DATE(event_timestamp) = target_date
    ) events_data
    FULL OUTER JOIN (
        SELECT 
            SUM(amount) as daily_revenue,
            COUNT(DISTINCT user_id) as paying_users
        FROM revenue
        WHERE transaction_date = target_date AND is_refund = FALSE
    ) revenue_data ON TRUE
    FULL OUTER JOIN (
        SELECT 
            COUNT(*) as new_subscriptions,
            SUM(monthly_price) as new_monthly_revenue
        FROM subscriptions
        WHERE start_date = target_date
    ) subscription_data ON TRUE;
END;
$$ LANGUAGE plpgsql;

-- Fast dashboard query (sub-second performance)
SELECT 
    metric_date,
    daily_active_users,
    total_events,
    daily_revenue,
    paying_users,
    new_subscriptions,
    -- Add growth calculations
    LAG(daily_active_users) OVER (ORDER BY metric_date) as prev_day_users,
    ROUND(
        (daily_active_users - LAG(daily_active_users) OVER (ORDER BY metric_date)) * 100.0 / 
        NULLIF(LAG(daily_active_users) OVER (ORDER BY metric_date), 0), 2
    ) as user_growth_percent,
    -- 7-day rolling averages
    AVG(daily_active_users) OVER (ORDER BY metric_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as avg_users_7d,
    AVG(daily_revenue) OVER (ORDER BY metric_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as avg_revenue_7d
FROM daily_business_metrics
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY metric_date DESC;

-- Performance improvement: 10-60 seconds → ~0.5 seconds
```

## Performance Monitoring

### Query Performance Tracking

```sql
-- Create performance monitoring table
CREATE TABLE query_performance_log (
    log_id SERIAL PRIMARY KEY,
    query_name VARCHAR(100),
    execution_time_ms INTEGER,
    rows_returned INTEGER,
    execution_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_name VARCHAR(50),
    query_hash VARCHAR(64)
);

-- Function to log query performance
CREATE OR REPLACE FUNCTION log_query_performance(
    p_query_name VARCHAR(100),
    p_execution_time_ms INTEGER,
    p_rows_returned INTEGER
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO query_performance_log (query_name, execution_time_ms, rows_returned, user_name, query_hash)
    VALUES (p_query_name, p_execution_time_ms, p_rows_returned, current_user, md5(p_query_name));
END;
$$ LANGUAGE plpgsql;

-- Performance monitoring dashboard
SELECT 
    query_name,
    COUNT(*) as execution_count,
    AVG(execution_time_ms) as avg_execution_time_ms,
    MIN(execution_time_ms) as min_execution_time_ms,
    MAX(execution_time_ms) as max_execution_time_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_execution_time_ms,
    AVG(rows_returned) as avg_rows_returned
FROM query_performance_log
WHERE execution_timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY query_name
ORDER BY avg_execution_time_ms DESC;
```

## Best Practices and Guidelines

### Indexing Strategy

1. **Composite Indexes**: Order columns by selectivity (most selective first)
2. **Partial Indexes**: Use WHERE clauses for frequently filtered data
3. **Covering Indexes**: Include frequently queried columns to avoid table lookups
4. **Index Maintenance**: Monitor index usage and remove unused indexes

### Query Optimization Checklist

- [ ] Use appropriate WHERE clause filtering early
- [ ] Avoid SELECT * in production queries
- [ ] Use EXISTS instead of IN for subqueries when possible
- [ ] Consider LIMIT for large result sets
- [ ] Use appropriate JOIN types (INNER vs LEFT)
- [ ] Leverage window functions instead of self-joins
- [ ] Consider materialized views for complex aggregations
- [ ] Use EXPLAIN ANALYZE to understand execution plans

### Materialized View Strategy

1. **Refresh Frequency**: Balance freshness vs. performance
2. **Incremental Updates**: Use triggers or scheduled jobs for large views
3. **Indexing**: Create appropriate indexes on materialized views
4. **Dependencies**: Track and manage view dependencies

## Business Impact

These optimizations enable:

- **Real-time Dashboards**: Sub-second query performance for executive reporting
- **Customer Analytics**: Fast customer segmentation and lifetime value analysis
- **Operational Efficiency**: Reduced database load and improved system reliability
- **Cost Savings**: Lower compute costs and better resource utilization

## Key Learning Outcomes

✅ **Query Optimization**: Master execution plan analysis and query tuning  
✅ **Indexing Strategy**: Design efficient indexes for analytical workloads  
✅ **Materialized Views**: Implement caching strategies for complex analytics  
✅ **Performance Monitoring**: Establish performance tracking and alerting  
✅ **Scalability**: Design queries that perform well as data grows

---

**Next Exercise**: `05_advanced_analytics.md` - Statistical analysis and predictive modeling with SQL
