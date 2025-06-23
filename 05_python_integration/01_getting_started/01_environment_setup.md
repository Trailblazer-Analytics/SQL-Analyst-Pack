# Getting Started with Python-SQL Integration

## Introduction

This section covers the fundamentals of connecting Python to SQL databases for business analysis. You'll learn to set up your environment, establish database connections, and execute basic queries from Python.

## Setup Requirements

### Python Environment Setup

1. **Install Python** (3.8+ recommended)
2. **Create virtual environment** (recommended)
3. **Install core packages**

```bash
# Create virtual environment
python -m venv sql-analyst-env

# Activate (Windows)
sql-analyst-env\Scripts\activate

# Activate (Mac/Linux)
source sql-analyst-env/bin/activate

# Install core packages
pip install pandas sqlalchemy jupyter matplotlib seaborn
```

### Database Drivers

Install the appropriate driver for your database:

```bash
# PostgreSQL
pip install psycopg2-binary

# MySQL/MariaDB
pip install pymysql

# SQL Server
pip install pyodbc

# SQLite (included with Python)
# No additional installation needed
```

## Basic Database Connection

### Using pandas (Recommended for Analysts)

```python
import pandas as pd
import sqlalchemy as sa

# Create connection string
# PostgreSQL example
connection_string = "postgresql://username:password@host:port/database"

# SQL Server example
connection_string = "mssql+pyodbc://username:password@server/database?driver=ODBC+Driver+17+for+SQL+Server"

# Create engine
engine = sa.create_engine(connection_string)

# Test connection
with engine.connect() as conn:
    result = conn.execute(sa.text("SELECT 1 as test"))
    print("Connection successful!")
```

### Simple Query Execution

```python
# Execute SQL and get DataFrame
query = """
SELECT 
    customer_id,
    customer_name,
    total_orders,
    total_revenue
FROM customer_summary
LIMIT 10
"""

df = pd.read_sql_query(query, engine)
print(df.head())
```

## Working with Query Results

### Basic DataFrame Operations

```python
# View data info
print(df.info())
print(df.describe())

# Basic filtering (complement to SQL WHERE)
high_value_customers = df[df['total_revenue'] > 1000]

# Quick aggregations
revenue_stats = df.groupby('customer_type')['total_revenue'].agg(['sum', 'mean', 'count'])
```

### Combining SQL and pandas

```python
# Use SQL for heavy lifting, pandas for analysis
base_query = """
SELECT 
    o.order_date,
    o.customer_id,
    o.order_amount,
    c.customer_segment,
    c.region
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2024-01-01'
"""

# Get data with SQL
orders_df = pd.read_sql_query(base_query, engine)

# Analyze with pandas
monthly_trends = orders_df.groupby([
    orders_df['order_date'].dt.to_period('M'), 
    'customer_segment'
])['order_amount'].sum().reset_index()

print(monthly_trends)
```

## Quick Visualization

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Simple trend analysis
plt.figure(figsize=(12, 6))
sns.lineplot(data=monthly_trends, x='order_date', y='order_amount', hue='customer_segment')
plt.title('Monthly Revenue Trends by Customer Segment')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

## Best Practices for Analysts

### 1. Keep SQL Skills Sharp
```python
# Good: Use SQL for what it does best
query = """
SELECT 
    region,
    customer_segment,
    COUNT(*) as customers,
    AVG(annual_revenue) as avg_revenue,
    SUM(annual_revenue) as total_revenue
FROM customers 
WHERE status = 'active'
GROUP BY region, customer_segment
ORDER BY total_revenue DESC
"""

# Then use pandas for additional analysis
customer_analysis = pd.read_sql_query(query, engine)
```

### 2. Handle Large Datasets Efficiently
```python
# For large datasets, use chunking
chunk_size = 10000
chunks = []

for chunk in pd.read_sql_query(query, engine, chunksize=chunk_size):
    # Process each chunk if needed
    processed_chunk = chunk.copy()
    chunks.append(processed_chunk)

# Combine all chunks
final_df = pd.concat(chunks, ignore_index=True)
```

### 3. Parameterized Queries
```python
# Safe way to handle parameters
def get_customer_analysis(start_date, region=None):
    query = """
    SELECT customer_id, order_date, order_amount
    FROM orders 
    WHERE order_date >= %(start_date)s
    """
    
    params = {'start_date': start_date}
    
    if region:
        query += " AND region = %(region)s"
        params['region'] = region
    
    return pd.read_sql_query(query, engine, params=params)

# Usage
jan_data = get_customer_analysis('2024-01-01', 'North America')
```

## Common Analyst Workflows

### 1. Daily Data Refresh
```python
def daily_sales_report(report_date):
    """Generate daily sales summary"""
    query = """
    SELECT 
        DATE(order_timestamp) as order_date,
        COUNT(*) as total_orders,
        SUM(order_amount) as total_revenue,
        AVG(order_amount) as avg_order_value
    FROM orders
    WHERE DATE(order_timestamp) = %(report_date)s
    """
    
    results = pd.read_sql_query(query, engine, params={'report_date': report_date})
    return results

# Usage
today_sales = daily_sales_report('2024-06-22')
print(f"Today's Revenue: ${today_sales['total_revenue'].iloc[0]:,.2f}")
```

### 2. Automated Data Quality Checks
```python
def data_quality_check(table_name):
    """Basic data quality assessment"""
    query = f"""
    SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT customer_id) as unique_customers,
        SUM(CASE WHEN order_amount IS NULL THEN 1 ELSE 0 END) as null_amounts,
        MIN(order_date) as earliest_date,
        MAX(order_date) as latest_date
    FROM {table_name}
    """
    
    quality_stats = pd.read_sql_query(query, engine)
    
    # Additional pandas checks
    data = pd.read_sql_query(f"SELECT * FROM {table_name} LIMIT 1000", engine)
    
    print("Data Quality Report:")
    print(f"Total Records: {quality_stats['total_records'].iloc[0]:,}")
    print(f"Date Range: {quality_stats['earliest_date'].iloc[0]} to {quality_stats['latest_date'].iloc[0]}")
    print(f"Null Values: {quality_stats['null_amounts'].iloc[0]}")
    
    return quality_stats

# Usage
quality_report = data_quality_check('orders')
```

## Troubleshooting Connection Issues

### Common Problems and Solutions

1. **Connection Timeout**
```python
# Add timeout parameters
engine = sa.create_engine(connection_string, pool_timeout=20, pool_recycle=30)
```

2. **Large Query Results**
```python
# Use server-side cursors for large datasets
engine = sa.create_engine(connection_string, server_side_cursors=True)
```

3. **Memory Issues**
```python
# Process in chunks
for chunk in pd.read_sql_query(query, engine, chunksize=5000):
    # Process each chunk
    process_chunk(chunk)
```

## Next Steps

After mastering these basics:

1. **Practice** with your own database
2. **Explore** the data analysis workflows (next module)
3. **Build** your first automated analysis
4. **Share** results with your team

---

**Continue to**: `02_data_analysis_workflows/` to learn comprehensive analysis patterns.
