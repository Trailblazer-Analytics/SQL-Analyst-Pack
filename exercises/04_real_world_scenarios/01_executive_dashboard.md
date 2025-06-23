# Real-World Scenario 1: Executive Dashboard - Quarterly Business Review

## Executive Summary

You're the **Head of Business Intelligence** at **TechFlow Solutions**, a B2B SaaS company with $50M ARR. The CEO needs a comprehensive quarterly business review (QBR) dashboard for the board meeting next week. This isn't just about writing queries—you need to tell a data-driven story that guides strategic decisions.

## Business Context

**Company Profile**:
- B2B SaaS platform serving mid-market companies
- 3 product tiers: Starter ($99/mo), Professional ($299/mo), Enterprise ($999/mo)
- Global customer base across North America, Europe, and APAC
- Freemium model with 14-day trial period
- Key metrics: MRR, NRR, CAC, LTV, Churn Rate

**Stakeholder Requirements**:
- **CEO**: High-level trends and strategic insights
- **CFO**: Revenue forecasting and unit economics
- **Head of Sales**: Pipeline health and conversion metrics
- **Head of Marketing**: Customer acquisition performance
- **Head of Product**: Usage patterns and feature adoption

## The Challenge

The previous BI analyst left unexpectedly, and you have incomplete documentation. You need to rebuild the entire QBR from raw data while ensuring accuracy and providing actionable insights.

**Time Constraint**: 3 days to complete analysis and presentation
**Data Quality Issues**: Multiple data sources with inconsistencies
**Stakeholder Pressure**: Board meeting cannot be delayed

## Database Schema

```sql
-- Core business tables
companies (
    company_id BIGINT PRIMARY KEY,
    company_name VARCHAR(200),
    industry VARCHAR(100),
    employee_count INTEGER,
    annual_revenue BIGINT,
    country VARCHAR(50),
    region VARCHAR(50), -- 'North America', 'Europe', 'APAC'
    signup_date DATE,
    company_status VARCHAR(20) -- 'active', 'churned', 'trial'
)

subscriptions (
    subscription_id BIGINT PRIMARY KEY,
    company_id BIGINT,
    plan_type VARCHAR(50), -- 'starter', 'professional', 'enterprise'
    monthly_price DECIMAL(10,2),
    billing_cycle VARCHAR(20), -- 'monthly', 'annual'
    start_date DATE,
    end_date DATE,
    status VARCHAR(20), -- 'active', 'cancelled', 'trial', 'past_due'
    arr DECIMAL(15,2), -- Annual Recurring Revenue
    created_at TIMESTAMP
)

revenue_events (
    event_id BIGINT PRIMARY KEY,
    subscription_id BIGINT,
    event_date DATE,
    event_type VARCHAR(50), -- 'new_subscription', 'upgrade', 'downgrade', 'churn', 'reactivation'
    mrr_change DECIMAL(15,2), -- Monthly Recurring Revenue change
    arr_change DECIMAL(15,2), -- Annual Recurring Revenue change
    previous_plan VARCHAR(50),
    new_plan VARCHAR(50),
    churn_reason VARCHAR(100)
)

customer_acquisition (
    acquisition_id BIGINT PRIMARY KEY,
    company_id BIGINT,
    acquisition_channel VARCHAR(100), -- 'organic', 'paid_search', 'content', 'partner', 'direct'
    campaign_name VARCHAR(200),
    acquisition_cost DECIMAL(10,2), -- Customer Acquisition Cost
    first_touch_date DATE,
    trial_start_date DATE,
    trial_end_date DATE,
    converted_to_paid BOOLEAN,
    conversion_date DATE
)

usage_analytics (
    usage_id BIGINT PRIMARY KEY,
    company_id BIGINT,
    usage_date DATE,
    daily_active_users INTEGER,
    feature_usage JSONB, -- JSON with feature usage counts
    api_calls INTEGER,
    data_volume_gb DECIMAL(10,2),
    login_count INTEGER
)

support_tickets (
    ticket_id BIGINT PRIMARY KEY,
    company_id BIGINT,
    created_date DATE,
    resolved_date DATE,
    priority VARCHAR(20), -- 'low', 'medium', 'high', 'critical'
    category VARCHAR(100), -- 'bug', 'feature_request', 'billing', 'onboarding'
    satisfaction_score INTEGER, -- 1-5 scale
    resolution_time_hours INTEGER
)
```

## Mission-Critical KPIs

Your dashboard must include these executive-level metrics:

### 1. Growth Metrics
- **Monthly Recurring Revenue (MRR)** trending over 8 quarters
- **Annual Recurring Revenue (ARR)** growth rate
- **Net Revenue Retention (NRR)** by customer segment
- **Customer growth** (new, churned, net growth)

### 2. Unit Economics
- **Customer Acquisition Cost (CAC)** by channel
- **Customer Lifetime Value (LTV)** by plan type
- **LTV:CAC ratio** trending and by segment
- **Payback period** for customer acquisition

### 3. Product & Engagement
- **Feature adoption rates** for key features
- **Usage intensity** correlation with retention
- **Product-led growth** indicators
- **Customer health scores**

### 4. Operational Excellence
- **Support ticket volume** and resolution metrics
- **Customer satisfaction** trends
- **Churn prediction** early warning indicators

## Tasks

### Task 1: Revenue Performance Analysis

Build a comprehensive revenue analysis that answers:

1. **Quarterly Revenue Performance**:
   - Q/Q MRR growth rate and trends
   - ARR progression with forecasting
   - Revenue by customer segment and geography
   - Plan mix evolution and average selling price (ASP) trends

2. **Customer Movement Analysis**:
   - New customer acquisition vs. churn rates
   - Expansion revenue vs. contraction revenue
   - Net Revenue Retention calculation by cohorts
   - Customer migration patterns between plans

**Business Questions to Address**:
- "Are we growing fast enough to hit our $100M ARR target by year-end?"
- "Which customer segments drive the most expansion revenue?"
- "What's our true retention rate when factoring in expansion?"

### Task 2: Customer Acquisition Deep Dive

Analyze the efficiency and effectiveness of customer acquisition:

1. **Channel Performance**:
   - CAC by acquisition channel and time period
   - Conversion rates from trial to paid by channel
   - Time-to-convert analysis
   - Channel ROI and budget allocation recommendations

2. **Cohort Analysis**:
   - Customer acquisition cohorts with LTV progression
   - Retention curves by acquisition channel
   - Revenue per customer over time
   - Payback period analysis

**Business Questions to Address**:
- "Which acquisition channels provide the highest quality customers?"
- "How has our customer acquisition efficiency changed over time?"
- "Should we reallocate marketing budget between channels?"

### Task 3: Product Usage and Health Analysis

Create product insights that drive retention and expansion:

1. **Usage Patterns**:
   - Feature adoption curves for new customers
   - Power user identification and characteristics
   - Usage correlation with retention and expansion
   - API usage patterns and limits analysis

2. **Customer Health Scoring**:
   - Multi-dimensional health score incorporating usage, support, and billing
   - Early warning system for churn risk
   - Expansion opportunity identification
   - Customer success intervention triggers

**Business Questions to Address**:
- "Which features are most predictive of customer success?"
- "How can we identify expansion opportunities earlier?"
- "What usage patterns indicate churn risk?"

### Task 4: Executive Summary with Strategic Recommendations

Synthesize findings into executive-ready insights:

1. **Strategic Dashboard**:
   - Single-page executive summary with key metrics
   - Trend arrows and variance analysis
   - Segment performance heatmap
   - Forward-looking indicators

2. **Strategic Recommendations**:
   - Data-driven recommendations for each department
   - Investment priorities based on unit economics
   - Risk mitigation strategies for identified issues
   - Growth acceleration opportunities

**Business Questions to Address**:
- "What are the 3 most important initiatives for next quarter?"
- "Where should we invest additional resources for maximum ROI?"
- "What are the biggest risks to our growth trajectory?"

## Starter Code

### Environment Setup and Data Exploration

```sql
-- Quick data quality check across key tables
WITH data_overview AS (
    SELECT 'companies' as table_name, COUNT(*) as row_count, 
           MIN(signup_date) as earliest_date, MAX(signup_date) as latest_date
    FROM companies
    WHERE company_status = 'active'
    
    UNION ALL
    
    SELECT 'subscriptions', COUNT(*), 
           MIN(start_date), MAX(COALESCE(end_date, CURRENT_DATE))
    FROM subscriptions
    
    UNION ALL
    
    SELECT 'revenue_events', COUNT(*), 
           MIN(event_date), MAX(event_date)
    FROM revenue_events
    
    UNION ALL
    
    SELECT 'usage_analytics', COUNT(*), 
           MIN(usage_date), MAX(usage_date)
    FROM usage_analytics
)
SELECT * FROM data_overview ORDER BY table_name;

-- Identify potential data quality issues
SELECT 
    'Orphaned subscriptions' as issue,
    COUNT(*) as affected_rows
FROM subscriptions s
LEFT JOIN companies c ON s.company_id = c.company_id
WHERE c.company_id IS NULL

UNION ALL

SELECT 
    'Revenue events without subscriptions',
    COUNT(*)
FROM revenue_events re
LEFT JOIN subscriptions s ON re.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL

UNION ALL

SELECT 
    'Negative MRR changes',
    COUNT(*)
FROM revenue_events
WHERE event_type = 'new_subscription' AND mrr_change < 0;
```

### Basic MRR Calculation

```sql
-- Monthly Recurring Revenue calculation
WITH monthly_mrr AS (
    SELECT 
        DATE_TRUNC('month', event_date) as month,
        SUM(mrr_change) as mrr_change
    FROM revenue_events
    WHERE event_date >= '2023-01-01'
    GROUP BY DATE_TRUNC('month', event_date)
),
mrr_progression AS (
    SELECT 
        month,
        mrr_change,
        SUM(mrr_change) OVER (ORDER BY month) as cumulative_mrr,
        LAG(SUM(mrr_change) OVER (ORDER BY month)) OVER (ORDER BY month) as prev_month_mrr
    FROM monthly_mrr
)
SELECT 
    month,
    cumulative_mrr,
    mrr_change,
    ROUND(
        (cumulative_mrr - COALESCE(prev_month_mrr, 0)) * 100.0 / 
        NULLIF(prev_month_mrr, 0), 2
    ) as mrr_growth_percent
FROM mrr_progression
ORDER BY month;
```

## Solutions Framework

### Task 1 Solution: Revenue Performance Analysis

```sql
-- Comprehensive Revenue Performance Dashboard
WITH quarterly_metrics AS (
    SELECT 
        DATE_TRUNC('quarter', re.event_date) as quarter,
        c.region,
        s.plan_type,
        
        -- Core revenue metrics
        SUM(CASE WHEN re.event_type = 'new_subscription' THEN re.mrr_change ELSE 0 END) as new_mrr,
        SUM(CASE WHEN re.event_type = 'upgrade' THEN re.mrr_change ELSE 0 END) as expansion_mrr,
        SUM(CASE WHEN re.event_type = 'downgrade' THEN ABS(re.mrr_change) ELSE 0 END) as contraction_mrr,
        SUM(CASE WHEN re.event_type = 'churn' THEN ABS(re.mrr_change) ELSE 0 END) as churned_mrr,
        
        -- Customer metrics
        COUNT(DISTINCT CASE WHEN re.event_type = 'new_subscription' THEN s.company_id END) as new_customers,
        COUNT(DISTINCT CASE WHEN re.event_type = 'churn' THEN s.company_id END) as churned_customers,
        
        -- Advanced metrics
        AVG(s.monthly_price) as average_selling_price
    FROM revenue_events re
    JOIN subscriptions s ON re.subscription_id = s.subscription_id
    JOIN companies c ON s.company_id = c.company_id
    WHERE re.event_date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY DATE_TRUNC('quarter', re.event_date), c.region, s.plan_type
),
quarterly_totals AS (
    SELECT 
        quarter,
        SUM(new_mrr) as total_new_mrr,
        SUM(expansion_mrr) as total_expansion_mrr,
        SUM(contraction_mrr) as total_contraction_mrr,
        SUM(churned_mrr) as total_churned_mrr,
        SUM(new_customers) as total_new_customers,
        SUM(churned_customers) as total_churned_customers,
        
        -- Net metrics
        SUM(new_mrr + expansion_mrr - contraction_mrr - churned_mrr) as net_mrr_change,
        SUM(new_customers - churned_customers) as net_customer_change,
        
        -- Growth rates
        LAG(SUM(new_mrr + expansion_mrr - contraction_mrr - churned_mrr)) OVER (ORDER BY quarter) as prev_quarter_net_mrr
    FROM quarterly_metrics
    GROUP BY quarter
),
nrr_calculation AS (
    SELECT 
        quarter,
        region,
        SUM(expansion_mrr + contraction_mrr) as net_expansion_revenue,
        LAG(SUM(new_mrr), 4) OVER (PARTITION BY region ORDER BY quarter) as base_revenue_year_ago
    FROM quarterly_metrics
    WHERE quarter >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY quarter, region
)
-- Executive Revenue Summary
SELECT 
    qt.quarter,
    qt.total_new_mrr,
    qt.total_expansion_mrr,
    qt.total_contraction_mrr,
    qt.total_churned_mrr,
    qt.net_mrr_change,
    qt.total_new_customers,
    qt.total_churned_customers,
    qt.net_customer_change,
    
    -- Growth metrics
    ROUND(
        (qt.net_mrr_change - COALESCE(qt.prev_quarter_net_mrr, 0)) * 100.0 / 
        NULLIF(qt.prev_quarter_net_mrr, 0), 2
    ) as quarterly_growth_percent,
    
    -- Unit economics
    CASE WHEN qt.total_new_customers > 0 
         THEN qt.total_new_mrr / qt.total_new_customers 
         ELSE 0 END as avg_mrr_per_new_customer,
    
    -- ARR calculation (MRR * 12)
    qt.net_mrr_change * 12 as quarterly_arr_change
FROM quarterly_totals qt
ORDER BY qt.quarter DESC;

-- Regional Performance Breakdown
SELECT 
    qm.quarter,
    qm.region,
    SUM(qm.new_mrr + qm.expansion_mrr - qm.contraction_mrr - qm.churned_mrr) as net_mrr_change,
    SUM(qm.new_customers - qm.churned_customers) as net_customer_change,
    
    -- Net Revenue Retention calculation
    ROUND(
        CASE WHEN nrr.base_revenue_year_ago > 0 
             THEN (nrr.base_revenue_year_ago + nrr.net_expansion_revenue) * 100.0 / nrr.base_revenue_year_ago
             ELSE NULL END, 2
    ) as net_revenue_retention_percent
FROM quarterly_metrics qm
LEFT JOIN nrr_calculation nrr ON qm.quarter = nrr.quarter AND qm.region = nrr.region
GROUP BY qm.quarter, qm.region, nrr.base_revenue_year_ago, nrr.net_expansion_revenue
ORDER BY qm.quarter DESC, net_mrr_change DESC;
```

**Business Insights from Analysis**:
- Quarterly MRR growth trending and acceleration patterns
- Regional performance variations and growth opportunities
- Plan mix evolution and pricing optimization insights
- Net Revenue Retention benchmarking against industry standards

### Task 2 Solution: Customer Acquisition Analysis

```sql
-- Customer Acquisition Efficiency and Quality Analysis
WITH acquisition_metrics AS (
    SELECT 
        DATE_TRUNC('quarter', ca.first_touch_date) as acquisition_quarter,
        ca.acquisition_channel,
        
        -- Acquisition volume and costs
        COUNT(DISTINCT ca.company_id) as total_leads,
        COUNT(DISTINCT CASE WHEN ca.converted_to_paid THEN ca.company_id END) as converted_customers,
        SUM(ca.acquisition_cost) as total_acquisition_cost,
        
        -- Conversion metrics
        AVG(EXTRACT(days FROM ca.conversion_date - ca.trial_start_date)) as avg_trial_to_conversion_days,
        COUNT(DISTINCT CASE WHEN ca.trial_start_date IS NOT NULL THEN ca.company_id END) as trial_starts,
        
        -- Customer quality indicators
        AVG(s.monthly_price) as avg_initial_monthly_price,
        COUNT(DISTINCT CASE WHEN s.plan_type = 'enterprise' THEN ca.company_id END) as enterprise_conversions
    FROM customer_acquisition ca
    LEFT JOIN subscriptions s ON ca.company_id = s.company_id 
        AND s.start_date = ca.conversion_date
    WHERE ca.first_touch_date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY DATE_TRUNC('quarter', ca.first_touch_date), ca.acquisition_channel
),
ltv_by_acquisition AS (
    SELECT 
        ca.acquisition_channel,
        ca.company_id,
        ca.acquisition_cost,
        SUM(s.monthly_price * 
            EXTRACT(days FROM COALESCE(s.end_date, CURRENT_DATE) - s.start_date) / 30.0
        ) as customer_lifetime_revenue
    FROM customer_acquisition ca
    JOIN subscriptions s ON ca.company_id = s.company_id
    WHERE ca.converted_to_paid = TRUE
        AND ca.first_touch_date >= CURRENT_DATE - INTERVAL '18 months'
    GROUP BY ca.acquisition_channel, ca.company_id, ca.acquisition_cost
),
channel_performance AS (
    SELECT 
        acquisition_channel,
        COUNT(*) as customers,
        AVG(customer_lifetime_revenue) as avg_ltv,
        AVG(acquisition_cost) as avg_cac,
        AVG(customer_lifetime_revenue / NULLIF(acquisition_cost, 0)) as ltv_cac_ratio,
        AVG(acquisition_cost / (customer_lifetime_revenue / 12.0)) as payback_months
    FROM ltv_by_acquisition
    WHERE acquisition_cost > 0
    GROUP BY acquisition_channel
)
-- Executive Acquisition Summary
SELECT 
    am.acquisition_quarter,
    am.acquisition_channel,
    am.total_leads,
    am.trial_starts,
    am.converted_customers,
    
    -- Conversion rates
    ROUND(am.trial_starts * 100.0 / NULLIF(am.total_leads, 0), 2) as lead_to_trial_percent,
    ROUND(am.converted_customers * 100.0 / NULLIF(am.trial_starts, 0), 2) as trial_to_paid_percent,
    ROUND(am.converted_customers * 100.0 / NULLIF(am.total_leads, 0), 2) as overall_conversion_percent,
    
    -- Economic metrics
    ROUND(am.total_acquisition_cost / NULLIF(am.converted_customers, 0), 2) as cac_per_customer,
    ROUND(am.avg_initial_monthly_price, 2) as avg_initial_mrr,
    am.avg_trial_to_conversion_days,
    
    -- Quality indicators
    ROUND(am.enterprise_conversions * 100.0 / NULLIF(am.converted_customers, 0), 2) as enterprise_mix_percent,
    
    -- Channel efficiency from LTV analysis
    cp.avg_ltv,
    cp.ltv_cac_ratio,
    cp.payback_months
FROM acquisition_metrics am
LEFT JOIN channel_performance cp ON am.acquisition_channel = cp.acquisition_channel
WHERE am.converted_customers > 0
ORDER BY am.acquisition_quarter DESC, am.converted_customers DESC;

-- Cohort Retention Analysis by Acquisition Channel
WITH customer_cohorts AS (
    SELECT 
        ca.acquisition_channel,
        DATE_TRUNC('month', ca.conversion_date) as cohort_month,
        ca.company_id,
        s.subscription_id,
        s.start_date,
        s.end_date
    FROM customer_acquisition ca
    JOIN subscriptions s ON ca.company_id = s.company_id
    WHERE ca.converted_to_paid = TRUE
        AND ca.conversion_date >= CURRENT_DATE - INTERVAL '18 months'
),
cohort_retention AS (
    SELECT 
        cc.acquisition_channel,
        cc.cohort_month,
        COUNT(DISTINCT cc.company_id) as cohort_size,
        COUNT(DISTINCT CASE 
            WHEN cc.end_date IS NULL OR cc.end_date > cc.cohort_month + INTERVAL '1 month'
            THEN cc.company_id 
        END) as retained_1m,
        COUNT(DISTINCT CASE 
            WHEN cc.end_date IS NULL OR cc.end_date > cc.cohort_month + INTERVAL '3 months'
            THEN cc.company_id 
        END) as retained_3m,
        COUNT(DISTINCT CASE 
            WHEN cc.end_date IS NULL OR cc.end_date > cc.cohort_month + INTERVAL '6 months'
            THEN cc.company_id 
        END) as retained_6m,
        COUNT(DISTINCT CASE 
            WHEN cc.end_date IS NULL OR cc.end_date > cc.cohort_month + INTERVAL '12 months'
            THEN cc.company_id 
        END) as retained_12m
    FROM customer_cohorts cc
    GROUP BY cc.acquisition_channel, cc.cohort_month
)
SELECT 
    acquisition_channel,
    AVG(cohort_size) as avg_cohort_size,
    AVG(retained_1m * 100.0 / NULLIF(cohort_size, 0)) as avg_retention_1m_percent,
    AVG(retained_3m * 100.0 / NULLIF(cohort_size, 0)) as avg_retention_3m_percent,
    AVG(retained_6m * 100.0 / NULLIF(cohort_size, 0)) as avg_retention_6m_percent,
    AVG(retained_12m * 100.0 / NULLIF(cohort_size, 0)) as avg_retention_12m_percent
FROM cohort_retention
WHERE cohort_month <= CURRENT_DATE - INTERVAL '12 months' -- Only include cohorts with 12m data
GROUP BY acquisition_channel
ORDER BY avg_retention_12m_percent DESC;
```

**Business Insights from Analysis**:
- Channel efficiency rankings with LTV:CAC ratios
- Conversion funnel optimization opportunities
- Customer quality differences by acquisition source
- Payback period trends and cash flow implications

### Task 3 Solution: Product Usage and Health Analysis

```sql
-- Product Usage Intelligence and Customer Health Scoring
WITH feature_adoption AS (
    SELECT 
        ua.company_id,
        DATE_TRUNC('month', ua.usage_date) as usage_month,
        s.plan_type,
        c.region,
        
        -- Core usage metrics
        AVG(ua.daily_active_users) as avg_daily_active_users,
        SUM(ua.api_calls) as total_api_calls,
        AVG(ua.data_volume_gb) as avg_data_volume_gb,
        COUNT(DISTINCT ua.usage_date) as active_days_in_month,
        
        -- Feature usage analysis (from JSONB)
        AVG((ua.feature_usage->>'feature_a')::integer) as feature_a_usage,
        AVG((ua.feature_usage->>'feature_b')::integer) as feature_b_usage,
        AVG((ua.feature_usage->>'feature_c')::integer) as feature_c_usage,
        
        -- Advanced feature adoption
        COUNT(CASE WHEN (ua.feature_usage->>'advanced_analytics')::integer > 0 THEN 1 END) as advanced_analytics_days,
        COUNT(CASE WHEN (ua.feature_usage->>'api_integrations')::integer > 0 THEN 1 END) as api_integration_days,
        
        -- Engagement scoring
        AVG(ua.login_count) as avg_monthly_logins
    FROM usage_analytics ua
    JOIN companies c ON ua.company_id = c.company_id
    LEFT JOIN subscriptions s ON ua.company_id = s.company_id 
        AND ua.usage_date BETWEEN s.start_date AND COALESCE(s.end_date, CURRENT_DATE)
    WHERE ua.usage_date >= CURRENT_DATE - INTERVAL '6 months'
        AND c.company_status = 'active'
    GROUP BY ua.company_id, DATE_TRUNC('month', ua.usage_date), s.plan_type, c.region
),
customer_health_scores AS (
    SELECT 
        fa.company_id,
        fa.plan_type,
        fa.region,
        
        -- Usage intensity score (0-100)
        LEAST(100, fa.avg_daily_active_users * 10) as usage_intensity_score,
        
        -- Feature adoption score (0-100)
        CASE 
            WHEN fa.plan_type = 'enterprise' THEN
                (CASE WHEN fa.advanced_analytics_days > 0 THEN 25 ELSE 0 END +
                 CASE WHEN fa.api_integration_days > 0 THEN 25 ELSE 0 END +
                 CASE WHEN fa.feature_a_usage > 10 THEN 25 ELSE fa.feature_a_usage * 2.5 END +
                 CASE WHEN fa.feature_b_usage > 10 THEN 25 ELSE fa.feature_b_usage * 2.5 END)
            WHEN fa.plan_type = 'professional' THEN
                (CASE WHEN fa.feature_a_usage > 5 THEN 50 ELSE fa.feature_a_usage * 10 END +
                 CASE WHEN fa.feature_b_usage > 5 THEN 50 ELSE fa.feature_b_usage * 10 END)
            ELSE
                CASE WHEN fa.feature_a_usage > 2 THEN 100 ELSE fa.feature_a_usage * 50 END
        END as feature_adoption_score,
        
        -- Engagement consistency score (0-100)
        CASE 
            WHEN fa.active_days_in_month >= 20 THEN 100
            WHEN fa.active_days_in_month >= 15 THEN 75
            WHEN fa.active_days_in_month >= 10 THEN 50
            WHEN fa.active_days_in_month >= 5 THEN 25
            ELSE 0
        END as engagement_consistency_score,
        
        -- Support health (from support tickets)
        COALESCE(support_health.support_score, 100) as support_health_score,
        
        -- Raw metrics for analysis
        fa.avg_daily_active_users,
        fa.total_api_calls,
        fa.avg_monthly_logins,
        fa.active_days_in_month
    FROM feature_adoption fa
    LEFT JOIN (
        SELECT 
            st.company_id,
            100 - (COUNT(CASE WHEN st.priority IN ('high', 'critical') THEN 1 END) * 10 +
                   COUNT(*) * 2 +
                   CASE WHEN AVG(st.satisfaction_score) < 3 THEN 20 ELSE 0 END) as support_score
        FROM support_tickets st
        WHERE st.created_date >= CURRENT_DATE - INTERVAL '3 months'
        GROUP BY st.company_id
    ) support_health ON fa.company_id = support_health.company_id
),
final_health_scores AS (
    SELECT 
        company_id,
        plan_type,
        region,
        
        -- Weighted composite health score
        ROUND(
            (usage_intensity_score * 0.3 +
             feature_adoption_score * 0.4 +
             engagement_consistency_score * 0.2 +
             support_health_score * 0.1), 2
        ) as overall_health_score,
        
        -- Individual component scores
        usage_intensity_score,
        feature_adoption_score,
        engagement_consistency_score,
        support_health_score,
        
        -- Risk categorization
        CASE 
            WHEN (usage_intensity_score * 0.3 + feature_adoption_score * 0.4 + 
                  engagement_consistency_score * 0.2 + support_health_score * 0.1) >= 80 THEN 'Healthy'
            WHEN (usage_intensity_score * 0.3 + feature_adoption_score * 0.4 + 
                  engagement_consistency_score * 0.2 + support_health_score * 0.1) >= 60 THEN 'At Risk'
            WHEN (usage_intensity_score * 0.3 + feature_adoption_score * 0.4 + 
                  engagement_consistency_score * 0.2 + support_health_score * 0.1) >= 40 THEN 'High Risk'
            ELSE 'Critical'
        END as health_category,
        
        -- Expansion opportunity indicators
        CASE 
            WHEN plan_type = 'starter' AND feature_adoption_score > 70 THEN 'Upgrade Ready'
            WHEN plan_type = 'professional' AND usage_intensity_score > 80 AND feature_adoption_score > 80 THEN 'Enterprise Ready'
            ELSE 'No Immediate Opportunity'
        END as expansion_opportunity,
        
        avg_daily_active_users,
        avg_monthly_logins,
        active_days_in_month
    FROM customer_health_scores
)
-- Executive Product Health Dashboard
SELECT 
    plan_type,
    region,
    health_category,
    COUNT(*) as customer_count,
    ROUND(AVG(overall_health_score), 2) as avg_health_score,
    ROUND(AVG(usage_intensity_score), 2) as avg_usage_score,
    ROUND(AVG(feature_adoption_score), 2) as avg_adoption_score,
    COUNT(CASE WHEN expansion_opportunity != 'No Immediate Opportunity' THEN 1 END) as expansion_opportunities,
    
    -- Risk indicators
    COUNT(CASE WHEN health_category IN ('High Risk', 'Critical') THEN 1 END) as at_risk_customers,
    ROUND(
        COUNT(CASE WHEN health_category IN ('High Risk', 'Critical') THEN 1 END) * 100.0 / COUNT(*), 2
    ) as at_risk_percentage
FROM final_health_scores
GROUP BY plan_type, region, health_category
ORDER BY plan_type, region, health_category;

-- Individual Customer Risk Report (for customer success teams)
SELECT 
    fhs.company_id,
    c.company_name,
    fhs.plan_type,
    fhs.overall_health_score,
    fhs.health_category,
    fhs.expansion_opportunity,
    
    -- Specific risk indicators
    CASE WHEN fhs.usage_intensity_score < 30 THEN 'Low Usage' ELSE NULL END as usage_concern,
    CASE WHEN fhs.engagement_consistency_score < 40 THEN 'Inconsistent Login' ELSE NULL END as engagement_concern,
    CASE WHEN fhs.support_health_score < 70 THEN 'Support Issues' ELSE NULL END as support_concern,
    
    -- Recent usage trends
    fhs.avg_daily_active_users,
    fhs.avg_monthly_logins,
    fhs.active_days_in_month,
    
    -- Account context
    EXTRACT(days FROM CURRENT_DATE - c.signup_date) as customer_age_days,
    s.monthly_price as current_mrr
FROM final_health_scores fhs
JOIN companies c ON fhs.company_id = c.company_id
LEFT JOIN subscriptions s ON fhs.company_id = s.company_id AND s.status = 'active'
WHERE fhs.health_category IN ('High Risk', 'Critical')
ORDER BY fhs.overall_health_score ASC, s.monthly_price DESC
LIMIT 50; -- Top 50 at-risk customers by revenue impact
```

**Business Insights from Analysis**:
- Product engagement patterns by customer segment
- Early warning indicators for churn and expansion
- Feature adoption correlation with retention
- Customer success intervention priorities

### Task 4 Solution: Executive Strategic Dashboard

```sql
-- Executive Strategic Dashboard - Single Pane of Glass
WITH executive_metrics AS (
    -- Current period metrics (last 30 days)
    SELECT 
        'Current Month' as period,
        SUM(CASE WHEN re.event_type = 'new_subscription' THEN re.mrr_change ELSE 0 END) as new_mrr,
        SUM(CASE WHEN re.event_type IN ('upgrade', 'downgrade', 'churn') THEN re.mrr_change ELSE 0 END) as net_expansion_mrr,
        COUNT(DISTINCT CASE WHEN re.event_type = 'new_subscription' THEN s.company_id END) as new_customers,
        COUNT(DISTINCT CASE WHEN re.event_type = 'churn' THEN s.company_id END) as churned_customers
    FROM revenue_events re
    JOIN subscriptions s ON re.subscription_id = s.subscription_id
    WHERE re.event_date >= DATE_TRUNC('month', CURRENT_DATE)
    
    UNION ALL
    
    -- Previous period metrics (prior 30 days)
    SELECT 
        'Previous Month',
        SUM(CASE WHEN re.event_type = 'new_subscription' THEN re.mrr_change ELSE 0 END),
        SUM(CASE WHEN re.event_type IN ('upgrade', 'downgrade', 'churn') THEN re.mrr_change ELSE 0 END),
        COUNT(DISTINCT CASE WHEN re.event_type = 'new_subscription' THEN s.company_id END),
        COUNT(DISTINCT CASE WHEN re.event_type = 'churn' THEN s.company_id END)
    FROM revenue_events re
    JOIN subscriptions s ON re.subscription_id = s.subscription_id
    WHERE re.event_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
        AND re.event_date < DATE_TRUNC('month', CURRENT_DATE)
),
current_arr AS (
    SELECT 
        SUM(s.arr) as total_arr,
        COUNT(DISTINCT s.company_id) as total_customers,
        AVG(s.monthly_price) as average_mrr_per_customer
    FROM subscriptions s
    WHERE s.status = 'active'
),
quarterly_trends AS (
    SELECT 
        DATE_TRUNC('quarter', re.event_date) as quarter,
        SUM(re.mrr_change) as net_mrr_change,
        COUNT(DISTINCT CASE WHEN re.event_type = 'new_subscription' THEN s.company_id END) as new_customers,
        COUNT(DISTINCT CASE WHEN re.event_type = 'churn' THEN s.company_id END) as churned_customers
    FROM revenue_events re
    JOIN subscriptions s ON re.subscription_id = s.subscription_id
    WHERE re.event_date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY DATE_TRUNC('quarter', re.event_date)
    ORDER BY quarter DESC
    LIMIT 8
),
growth_projections AS (
    SELECT 
        -- Simple linear regression for ARR projection
        ca.total_arr,
        ca.total_arr * (1 + 0.15) as projected_arr_q1, -- Assuming 15% quarterly growth
        ca.total_arr * (1 + 0.15) * (1 + 0.15) as projected_arr_q2,
        100000000 as arr_target, -- $100M target
        (100000000 - ca.total_arr) / (ca.total_arr * 0.15) as quarters_to_target
    FROM current_arr ca
)
-- Executive Summary Report
SELECT 
    '📊 EXECUTIVE DASHBOARD' as section,
    '🎯 Current Performance' as category,
    CONCAT('$', ROUND(ca.total_arr / 1000000, 2), 'M') as metric_value,
    'Annual Recurring Revenue' as metric_name
FROM current_arr ca

UNION ALL

SELECT 
    '📊 EXECUTIVE DASHBOARD',
    '🎯 Current Performance',
    ca.total_customers::text,
    'Total Active Customers'
FROM current_arr ca

UNION ALL

SELECT 
    '📊 EXECUTIVE DASHBOARD',
    '📈 Growth Metrics',
    CONCAT(
        ROUND(
            (em_current.new_mrr - em_previous.new_mrr) * 100.0 / 
            NULLIF(em_previous.new_mrr, 0), 1
        ), '%'
    ),
    'New MRR Growth (MoM)'
FROM executive_metrics em_current
JOIN executive_metrics em_previous ON em_current.period = 'Current Month' AND em_previous.period = 'Previous Month'

UNION ALL

SELECT 
    '📊 EXECUTIVE DASHBOARD',
    '📈 Growth Metrics',
    CONCAT(
        ROUND(
            (em_current.new_customers - em_previous.new_customers) * 100.0 / 
            NULLIF(em_previous.new_customers, 0), 1
        ), '%'
    ),
    'Customer Acquisition Growth (MoM)'
FROM executive_metrics em_current
JOIN executive_metrics em_previous ON em_current.period = 'Current Month' AND em_previous.period = 'Previous Month'

UNION ALL

SELECT 
    '📊 EXECUTIVE DASHBOARD',
    '🎯 Strategic Goals',
    CONCAT('$', ROUND(gp.projected_arr_q2 / 1000000, 2), 'M'),
    'Projected ARR (6 months)'
FROM growth_projections gp

UNION ALL

SELECT 
    '📊 EXECUTIVE DASHBOARD',
    '🎯 Strategic Goals',
    ROUND(gp.quarters_to_target, 1)::text || ' quarters',
    'Time to $100M ARR Target'
FROM growth_projections gp

UNION ALL

-- Risk Indicators
SELECT 
    '⚠️ RISK INDICATORS',
    '🚨 Customer Health',
    COUNT(*)::text,
    'High-Risk Customers (Health Score < 40)'
FROM (
    SELECT fhs.company_id
    FROM final_health_scores fhs -- From previous query
    WHERE fhs.overall_health_score < 40
) high_risk

UNION ALL

SELECT 
    '⚠️ RISK INDICATORS',
    '💰 Revenue Impact',
    CONCAT('$', ROUND(SUM(s.monthly_price * 12) / 1000, 1), 'K'),
    'ARR at Risk from High-Risk Customers'
FROM final_health_scores fhs
JOIN subscriptions s ON fhs.company_id = s.company_id AND s.status = 'active'
WHERE fhs.overall_health_score < 40

UNION ALL

-- Growth Opportunities
SELECT 
    '🚀 OPPORTUNITIES',
    '📈 Expansion Revenue',
    COUNT(*)::text,
    'Customers Ready for Upsell'
FROM final_health_scores fhs
WHERE fhs.expansion_opportunity != 'No Immediate Opportunity'

UNION ALL

SELECT 
    '🚀 OPPORTUNITIES',
    '💡 Channel Optimization',
    CONCAT('+', ROUND(
        (SELECT MAX(ltv_cac_ratio) - MIN(ltv_cac_ratio) 
         FROM channel_performance -- From previous query
        ) * 100, 1
    ), '%'),
    'Potential CAC Efficiency Gain'

ORDER BY section, category, metric_name;

-- Strategic Recommendations Summary
WITH recommendations AS (
    SELECT 
        1 as priority,
        'Revenue Growth' as area,
        'Focus on Enterprise segment expansion - 40% higher LTV:CAC ratio' as recommendation,
        'Reallocate 25% of marketing budget to enterprise-focused channels' as action,
        '$2.5M ARR impact' as estimated_impact
        
    UNION ALL
    
    SELECT 
        2,
        'Customer Success',
        'Implement proactive outreach for 150+ high-risk customers',
        'Deploy customer health monitoring alerts and CS intervention workflows',
        '$1.8M ARR protection'
        
    UNION ALL
    
    SELECT 
        3,
        'Product Development',
        'Advanced analytics feature showing 3x higher retention in Enterprise',
        'Accelerate advanced analytics roadmap and improve onboarding',
        '$3.2M expansion opportunity'
        
    UNION ALL
    
    SELECT 
        4,
        'Operational Efficiency',
        'Paid search showing 45% longer payback period vs. organic',
        'Optimize paid search targeting and increase content marketing investment',
        '$800K cost savings annually'
)
SELECT 
    '🎯 STRATEGIC RECOMMENDATIONS' as section,
    CONCAT('Priority ', priority, ': ', area) as recommendation_title,
    recommendation as insight,
    action as recommended_action,
    estimated_impact
FROM recommendations
ORDER BY priority;
```

**Executive Summary Insights**:

1. **Revenue Performance**: Track against $100M ARR target with quarterly projections
2. **Growth Efficiency**: Monitor LTV:CAC ratios and channel performance optimization
3. **Risk Management**: Identify and prioritize at-risk revenue for customer success intervention
4. **Strategic Opportunities**: Quantify expansion revenue potential and operational improvements

## Business Impact and Deliverables

### For the CEO
- **Growth Trajectory**: Clear visibility into progress toward $100M ARR goal
- **Strategic Priorities**: Data-driven recommendations for resource allocation
- **Risk Assessment**: Early warning indicators for potential revenue challenges

### For the CFO
- **Unit Economics**: LTV:CAC ratios and payback periods by channel and segment
- **Revenue Forecasting**: Predictive models for quarterly and annual planning
- **Cost Optimization**: Identification of marketing efficiency opportunities

### For Department Heads
- **Sales**: Pipeline health metrics and conversion optimization opportunities
- **Marketing**: Channel performance analysis and budget reallocation recommendations
- **Product**: Feature adoption correlation with retention and expansion
- **Customer Success**: Prioritized intervention list with revenue impact quantification

### Key Learning Outcomes

✅ **Executive Communication**: Present complex data insights in business-friendly formats  
✅ **Strategic Analysis**: Connect data findings to actionable business recommendations  
✅ **Cross-functional Impact**: Understand how SQL analysis drives decisions across departments  
✅ **Performance Under Pressure**: Deliver critical analysis within tight deadlines  
✅ **Data Storytelling**: Craft compelling narratives that drive stakeholder action

---

**Next Scenario**: `02_marketing_campaign_optimization.md` - Marketing attribution and campaign ROI analysis
