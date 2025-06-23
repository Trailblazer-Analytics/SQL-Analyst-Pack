# Data Analysis Workflows: SQL + Python Integration

## Overview

This section demonstrates comprehensive data analysis workflows that combine SQL's data processing power with Python's analytical capabilities. These workflows are designed for business analysts who need to perform complex analysis efficiently.

## Workflow Patterns

### 1. Data Profiling and Quality Assessment

**Business Need**: Understand data quality before analysis
**SQL Role**: Aggregate statistics, identify patterns
**Python Role**: Advanced statistics, visualization, reporting

```python
# Example: Automated Data Quality Report
def comprehensive_data_profile(table_name, engine):
    """Generate comprehensive data quality report"""
    
    # SQL for basic statistics
    profile_query = f"""
    SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT customer_id) as unique_customers,
        MIN(order_date) as earliest_date,
        MAX(order_date) as latest_date,
        AVG(order_amount) as avg_order_amount,
        STDDEV(order_amount) as stddev_order_amount
    FROM {table_name}
    """
    
    basic_stats = pd.read_sql_query(profile_query, engine)
    
    # Detailed data for Python analysis
    sample_data = pd.read_sql_query(f"SELECT * FROM {table_name} LIMIT 10000", engine)
    
    # Python analysis
    quality_report = {
        'basic_stats': basic_stats,
        'null_percentages': sample_data.isnull().sum() / len(sample_data) * 100,
        'data_types': sample_data.dtypes,
        'duplicates': sample_data.duplicated().sum(),
        'outliers': detect_outliers(sample_data)
    }
    
    return quality_report
```

### 2. Time Series Analysis

**Business Need**: Understand trends and seasonality
**SQL Role**: Date aggregations, window functions
**Python Role**: Advanced time series analysis, forecasting

```python
# SQL for time-based aggregations
time_series_query = """
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as orders,
    SUM(order_amount) as revenue,
    AVG(order_amount) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders
WHERE order_date >= '2023-01-01'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month
"""

# Python for trend analysis
monthly_data = pd.read_sql_query(time_series_query, engine)
monthly_data['month'] = pd.to_datetime(monthly_data['month'])
monthly_data.set_index('month', inplace=True)

# Calculate growth rates
monthly_data['revenue_growth'] = monthly_data['revenue'].pct_change()
monthly_data['order_growth'] = monthly_data['orders'].pct_change()

# Seasonal decomposition
from statsmodels.tsa.seasonal import seasonal_decompose
decomposition = seasonal_decompose(monthly_data['revenue'], model='multiplicative')
```

### 3. Customer Behavior Analysis

**Business Need**: Understand customer patterns and lifecycle
**SQL Role**: Customer aggregations, cohort definitions
**Python Role**: Statistical analysis, clustering, visualization

```python
# SQL for customer behavior metrics
customer_behavior_query = """
WITH customer_metrics AS (
    SELECT 
        customer_id,
        MIN(order_date) as first_order,
        MAX(order_date) as last_order,
        COUNT(*) as total_orders,
        SUM(order_amount) as total_spent,
        AVG(order_amount) as avg_order_value,
        AVG(EXTRACT(DAY FROM order_date - LAG(order_date) 
            OVER (PARTITION BY customer_id ORDER BY order_date))) as avg_days_between_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    cm.*,
    EXTRACT(DAY FROM CURRENT_DATE - cm.last_order) as days_since_last_order,
    c.acquisition_channel,
    c.customer_tier
FROM customer_metrics cm
JOIN customers c ON cm.customer_id = c.customer_id
WHERE cm.total_orders >= 2  -- Focus on repeat customers
"""

behavior_data = pd.read_sql_query(customer_behavior_query, engine)

# Python for clustering analysis
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# Prepare features for clustering
features = ['total_orders', 'total_spent', 'avg_order_value', 'days_since_last_order']
X = behavior_data[features].fillna(0)

# Standardize features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Perform clustering
kmeans = KMeans(n_clusters=5, random_state=42)
behavior_data['cluster'] = kmeans.fit_predict(X_scaled)
```

### 4. Product Performance Analysis

**Business Need**: Optimize product portfolio and pricing
**SQL Role**: Product aggregations, sales analysis
**Python Role**: Statistical testing, correlation analysis

```python
# SQL for product performance
product_analysis_query = """
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    COUNT(oi.order_item_id) as units_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    AVG(oi.unit_price) as avg_selling_price,
    COUNT(DISTINCT oi.order_id) as orders_containing_product,
    
    -- Performance metrics
    SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT oi.order_id) as revenue_per_order,
    COUNT(oi.order_item_id) / COUNT(DISTINCT oi.order_id) as units_per_order
    
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_date >= '2024-01-01'
GROUP BY p.product_id, p.product_name, p.category, p.price
HAVING COUNT(oi.order_item_id) > 0
ORDER BY total_revenue DESC
"""

product_data = pd.read_sql_query(product_analysis_query, engine)

# Python for advanced analysis
import scipy.stats as stats

# Price elasticity analysis
product_data['price_tier'] = pd.qcut(product_data['price'], q=4, labels=['Low', 'Medium', 'High', 'Premium'])

# Statistical tests
price_revenue_correlation = stats.pearsonr(product_data['price'], product_data['total_revenue'])
print(f"Price-Revenue Correlation: {price_revenue_correlation[0]:.3f} (p-value: {price_revenue_correlation[1]:.3f})")

# Category performance comparison
category_performance = product_data.groupby('category').agg({
    'total_revenue': 'sum',
    'units_sold': 'sum',
    'avg_selling_price': 'mean'
}).sort_values('total_revenue', ascending=False)
```

## Workflow Templates

### Template 1: Weekly Business Review

```python
def weekly_business_review(week_start_date, engine):
    """Generate automated weekly business review"""
    
    # SQL queries for key metrics
    weekly_summary_query = f"""
    WITH current_week AS (
        SELECT 
            COUNT(*) as orders,
            SUM(order_amount) as revenue,
            COUNT(DISTINCT customer_id) as customers,
            AVG(order_amount) as aov
        FROM orders
        WHERE order_date >= '{week_start_date}'
        AND order_date < '{week_start_date}'::date + interval '7 days'
    ),
    previous_week AS (
        SELECT 
            COUNT(*) as orders,
            SUM(order_amount) as revenue,
            COUNT(DISTINCT customer_id) as customers,
            AVG(order_amount) as aov
        FROM orders
        WHERE order_date >= '{week_start_date}'::date - interval '7 days'
        AND order_date < '{week_start_date}'::date
    )
    SELECT 
        'current' as period, * FROM current_week
    UNION ALL
    SELECT 
        'previous' as period, * FROM previous_week
    """
    
    weekly_metrics = pd.read_sql_query(weekly_summary_query, engine)
    
    # Calculate week-over-week changes
    current = weekly_metrics[weekly_metrics['period'] == 'current'].iloc[0]
    previous = weekly_metrics[weekly_metrics['period'] == 'previous'].iloc[0]
    
    wow_changes = {
        'revenue_change': (current['revenue'] - previous['revenue']) / previous['revenue'] * 100,
        'order_change': (current['orders'] - previous['orders']) / previous['orders'] * 100,
        'customer_change': (current['customers'] - previous['customers']) / previous['customers'] * 100,
        'aov_change': (current['aov'] - previous['aov']) / previous['aov'] * 100
    }
    
    # Generate insights
    insights = []
    if wow_changes['revenue_change'] > 5:
        insights.append("Strong revenue growth this week")
    elif wow_changes['revenue_change'] < -5:
        insights.append("Revenue decline needs attention")
        
    return {
        'metrics': weekly_metrics,
        'changes': wow_changes,
        'insights': insights
    }
```

### Template 2: Customer Cohort Analysis

```python
def customer_cohort_analysis(engine):
    """Perform customer cohort analysis"""
    
    # SQL for cohort data preparation
    cohort_query = """
    WITH customer_first_purchase AS (
        SELECT 
            customer_id,
            MIN(order_date) as first_purchase_date,
            DATE_TRUNC('month', MIN(order_date)) as cohort_month
        FROM orders
        GROUP BY customer_id
    ),
    customer_orders AS (
        SELECT 
            o.customer_id,
            o.order_date,
            cfp.cohort_month,
            EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.order_date), cfp.cohort_month)) * 12 +
            EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_date), cfp.cohort_month)) as month_number
        FROM orders o
        JOIN customer_first_purchase cfp ON o.customer_id = cfp.customer_id
    )
    SELECT 
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) as customers
    FROM customer_orders
    GROUP BY cohort_month, month_number
    ORDER BY cohort_month, month_number
    """
    
    cohort_data = pd.read_sql_query(cohort_query, engine)
    
    # Python for cohort table creation
    cohort_table = cohort_data.pivot_table(
        index='cohort_month',
        columns='month_number',
        values='customers',
        fill_value=0
    )
    
    # Calculate retention rates
    cohort_sizes = cohort_table.iloc[:, 0]
    retention_table = cohort_table.divide(cohort_sizes, axis=0)
    
    return {
        'cohort_table': cohort_table,
        'retention_table': retention_table
    }
```

## Best Practices for Workflow Integration

### 1. Performance Optimization
- Use SQL for heavy aggregations and filtering
- Bring only necessary data into Python
- Cache intermediate results for iterative analysis
- Use appropriate data types to reduce memory usage

### 2. Code Organization
- Separate SQL queries into dedicated files for complex analysis
- Create reusable functions for common patterns
- Use configuration files for database connections and parameters
- Implement logging for production workflows

### 3. Error Handling and Validation
```python
def safe_sql_execution(query, engine, params=None):
    """Execute SQL with proper error handling"""
    try:
        result = pd.read_sql_query(query, engine, params=params)
        print(f"✅ Query executed successfully. {len(result):,} rows returned.")
        return result
    except Exception as e:
        print(f"❌ SQL execution failed: {e}")
        return None

def validate_data_quality(df, required_columns):
    """Validate data quality before analysis"""
    issues = []
    
    # Check for required columns
    missing_cols = set(required_columns) - set(df.columns)
    if missing_cols:
        issues.append(f"Missing columns: {missing_cols}")
    
    # Check for empty dataset
    if len(df) == 0:
        issues.append("Empty dataset returned")
    
    # Check for excessive null values
    null_percentages = df.isnull().sum() / len(df) * 100
    high_null_cols = null_percentages[null_percentages > 50].index.tolist()
    if high_null_cols:
        issues.append(f"High null percentage in columns: {high_null_cols}")
    
    return issues
```

### 4. Documentation and Reproducibility
- Document business logic and assumptions
- Use version control for analysis scripts
- Create parameterized notebooks for different time periods
- Export results with metadata and creation timestamps

## Next Steps

1. **Practice** with the provided templates using your own data
2. **Customize** workflows for your specific business needs
3. **Automate** routine analysis with scheduling tools
4. **Share** reproducible analysis with business stakeholders

---

**Continue to**: `03_visualization_and_reporting/` to learn how to create compelling visualizations and automated reports.
