# 📊 Sample Database Setup Guide

This directory contains sample databases designed to support the SQL Analyst Pack learning journey. Each dataset represents real-world scenarios you'll encounter as a data analyst.

## 🗃️ Available Datasets

### 1. Chinook Database (Music Store)
**File:** `chinook.sql`  
**Description:** A digital music store with customers, invoices, tracks, artists, and albums.  
**Use Cases:** Basic queries, joins, aggregations, customer analysis  
**Tables:** 11 tables with realistic relationships  
**Data Volume:** ~1000 customers, ~400 invoices, ~3500 tracks

### 2. E-commerce Analytics (Extended)
**File:** `ecommerce_analytics.sql`  
**Description:** Enhanced e-commerce dataset with user behavior, A/B tests, and cohort data.  
**Use Cases:** Advanced analytics, cohort analysis, A/B testing, funnel analysis  
**Tables:** 8 tables with time-series data  
**Data Volume:** ~5000 users, ~15000 orders, ~50000 events

### 3. Financial Transactions (Fraud Detection)
**File:** `financial_transactions.sql`  
**Description:** Banking transactions with normal and suspicious activity patterns.  
**Use Cases:** Fraud detection, anomaly analysis, risk scoring  
**Tables:** 4 tables with transaction patterns  
**Data Volume:** ~10000 accounts, ~100000 transactions

### 4. Time Series Data (IoT Sensors)
**File:** `iot_timeseries.sql`  
**Description:** IoT sensor data with timestamps, metrics, and device information.  
**Use Cases:** Time series analysis, trend detection, forecasting  
**Tables:** 3 tables with hourly data  
**Data Volume:** ~100 devices, ~500000 readings

## 🚀 Quick Setup

### Option 1: PostgreSQL (Recommended)
```bash
# Create database
createdb sql_analyst_pack

# Load all datasets
psql sql_analyst_pack -f setup_postgresql.sql
```

### Option 2: SQLite (Portable)
```bash
# Load into SQLite
sqlite3 sql_analyst_pack.db < setup_sqlite.sql
```

### Option 3: Docker (Easiest)
```bash
# Use our pre-configured container
docker-compose up -d
```

## 📋 Database Schema Overview

### Chinook Schema (Foundation Learning)
```
Artist (ArtistId, Name)
Album (AlbumId, Title, ArtistId)
Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice)
Customer (CustomerId, FirstName, LastName, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email, SupportRepId)
Invoice (InvoiceId, CustomerId, InvoiceDate, BillingAddress, BillingCity, BillingState, BillingCountry, BillingPostalCode, Total)
InvoiceLine (InvoiceLineId, InvoiceId, TrackId, UnitPrice, Quantity)
Employee (EmployeeId, LastName, FirstName, Title, ReportsTo, BirthDate, HireDate, Address, City, State, Country, PostalCode, Phone, Fax, Email)
```

### E-commerce Schema (Intermediate Analytics)
```
users (user_id, signup_date, country, device_type, traffic_source)
orders (order_id, user_id, order_date, order_value, status)
order_items (order_item_id, order_id, product_id, quantity, unit_price)
products (product_id, product_name, category, supplier_id, unit_cost)
user_events (event_id, user_id, event_type, event_timestamp, page_url)
ab_tests (test_id, user_id, variant, start_date, end_date)
cohorts (cohort_month, users_count, retention_month_1, retention_month_3, retention_month_6)
```

### Financial Schema (Advanced Analysis)
```
accounts (account_id, customer_id, account_type, balance, created_date, status)
transactions (transaction_id, account_id, transaction_date, amount, transaction_type, merchant_id, description)
customers (customer_id, age, income_level, risk_score, country, registration_date)
merchants (merchant_id, merchant_name, category, risk_level)
```

## 🎯 Learning Objectives by Dataset

### Chinook Database
- **Foundations:** Basic SELECT, WHERE, JOIN operations
- **Intermediate:** Aggregations, subqueries, window functions
- **Advanced:** Performance optimization, complex analytics

### E-commerce Analytics
- **Customer Segmentation:** RFM analysis, cohort studies
- **A/B Testing:** Statistical significance, conversion analysis
- **Funnel Analysis:** User journey mapping, drop-off analysis

### Financial Transactions
- **Fraud Detection:** Anomaly detection, pattern matching
- **Risk Analysis:** Scoring models, threshold optimization
- **Compliance:** Audit trails, regulatory reporting

### IoT Time Series
- **Trend Analysis:** Moving averages, seasonal patterns
- **Forecasting:** Linear regression, time series decomposition
- **Alerting:** Threshold monitoring, outlier detection

## 🔧 Advanced Features

### Data Quality Scenarios
Each dataset includes intentional data quality issues for cleaning exercises:
- Missing values and NULLs
- Duplicate records
- Inconsistent formatting
- Outliers and anomalies

### Performance Testing
Large enough datasets to practice:
- Index creation and optimization
- Query performance tuning
- Execution plan analysis

### Real-world Complexity
- Multiple table relationships
- Business logic constraints
- Time-based data challenges
- Cross-system integration patterns

## 📝 Usage Examples

### Getting Started (Chinook)
```sql
-- Your first query: Find all customers
SELECT FirstName, LastName, Country 
FROM Customer 
LIMIT 10;

-- Basic aggregation: Sales by country
SELECT BillingCountry, SUM(Total) as TotalSales
FROM Invoice 
GROUP BY BillingCountry
ORDER BY TotalSales DESC;
```

### Intermediate Analysis (E-commerce)
```sql
-- Cohort analysis: Monthly retention
SELECT 
    cohort_month,
    users_count,
    retention_month_1 / users_count::float * 100 as month_1_retention,
    retention_month_3 / users_count::float * 100 as month_3_retention
FROM cohorts
ORDER BY cohort_month;
```

### Advanced Analytics (Financial)
```sql
-- Fraud detection: Unusual transaction patterns
WITH transaction_stats AS (
    SELECT 
        account_id,
        AVG(amount) as avg_amount,
        STDDEV(amount) as stddev_amount,
        COUNT(*) as transaction_count
    FROM transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY account_id
)
SELECT 
    t.transaction_id,
    t.account_id,
    t.amount,
    CASE 
        WHEN t.amount > ts.avg_amount + 3 * ts.stddev_amount THEN 'High Risk'
        WHEN t.amount > ts.avg_amount + 2 * ts.stddev_amount THEN 'Medium Risk'
        ELSE 'Normal'
    END as risk_level
FROM transactions t
JOIN transaction_stats ts ON t.account_id = ts.account_id
WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '7 days';
```

## 🆘 Troubleshooting

**Database Connection Issues:**
- Verify PostgreSQL is running: `pg_ctl status`
- Check connection string and credentials
- Ensure database exists: `\l` in psql

**Data Loading Problems:**
- Check file permissions and paths
- Verify SQL syntax compatibility
- Review error logs for specific issues

**Performance Issues:**
- Monitor query execution time
- Check if indexes are created
- Review connection pool settings

## 🔗 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Chinook Database GitHub](https://github.com/lerocha/chinook-database)
- [SQL Performance Tuning Guide](../reference/performance_guide.md)
- [Data Quality Best Practices](../reference/data_quality.md)

---

**Next:** Load your preferred dataset and start with [01_foundations](../01_foundations/) to begin your SQL learning journey!
