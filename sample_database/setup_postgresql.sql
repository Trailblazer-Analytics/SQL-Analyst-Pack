-- =====================================================
-- SQL Analyst Pack - Complete Database Setup
-- =====================================================
-- This script sets up all sample databases for the SQL Analyst Pack
-- Includes: Chinook, E-commerce Analytics, Financial Transactions, IoT Time Series
-- Database: PostgreSQL (can be adapted for other SQL databases)
-- Version: 1.0
-- Date: June 22, 2025

-- =====================================================
-- SETUP INSTRUCTIONS
-- =====================================================
-- 1. Create database: createdb sql_analyst_pack
-- 2. Run this script: psql sql_analyst_pack -f setup_postgresql.sql
-- 3. Verify setup: Run verification queries at the end

\echo '🚀 Starting SQL Analyst Pack Database Setup...'
\echo ''

-- =====================================================
-- SECTION 1: CHINOOK DATABASE (Music Store)
-- =====================================================
\echo '📀 Setting up Chinook Database (Music Store)...'

-- Load the existing Chinook database
\i chinook.sql

\echo '✅ Chinook Database loaded successfully!'
\echo ''

-- =====================================================
-- SECTION 2: E-COMMERCE ANALYTICS DATABASE
-- =====================================================
\echo '🛒 Setting up E-commerce Analytics Database...'

-- Users table with signup information
CREATE TABLE ecommerce_users (
    user_id SERIAL PRIMARY KEY,
    signup_date DATE NOT NULL,
    country VARCHAR(50) NOT NULL,
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('desktop', 'mobile', 'tablet')),
    traffic_source VARCHAR(30) NOT NULL,
    age_group VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products catalog
CREATE TABLE ecommerce_products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    unit_cost DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    supplier_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE ecommerce_orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES ecommerce_users(user_id),
    order_date TIMESTAMP NOT NULL,
    order_value DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded')),
    shipping_cost DECIMAL(8,2) DEFAULT 0,
    discount_amount DECIMAL(8,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order items (line items)
CREATE TABLE ecommerce_order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES ecommerce_orders(order_id),
    product_id INTEGER REFERENCES ecommerce_products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User events for funnel analysis
CREATE TABLE ecommerce_user_events (
    event_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES ecommerce_users(user_id),
    event_type VARCHAR(30) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    page_url VARCHAR(500),
    product_id INTEGER REFERENCES ecommerce_products(product_id),
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- A/B testing data
CREATE TABLE ecommerce_ab_tests (
    test_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES ecommerce_users(user_id),
    test_name VARCHAR(100) NOT NULL,
    variant VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    conversion_event VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cohort analysis pre-calculated table
CREATE TABLE ecommerce_cohorts (
    cohort_id SERIAL PRIMARY KEY,
    cohort_month DATE NOT NULL,
    users_count INTEGER NOT NULL,
    retention_month_1 INTEGER,
    retention_month_3 INTEGER,
    retention_month_6 INTEGER,
    retention_month_12 INTEGER,
    total_revenue DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

\echo '✅ E-commerce Analytics tables created!'

-- =====================================================
-- SECTION 3: FINANCIAL TRANSACTIONS DATABASE
-- =====================================================
\echo '💰 Setting up Financial Transactions Database...'

-- Customer profiles
CREATE TABLE financial_customers (
    customer_id SERIAL PRIMARY KEY,
    age INTEGER CHECK (age >= 18 AND age <= 100),
    income_level VARCHAR(20) CHECK (income_level IN ('low', 'medium', 'high', 'very_high')),
    risk_score DECIMAL(3,2) CHECK (risk_score >= 0 AND risk_score <= 1),
    country VARCHAR(50) NOT NULL,
    registration_date DATE NOT NULL,
    kyc_status VARCHAR(20) DEFAULT 'verified',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Account information
CREATE TABLE financial_accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES financial_customers(customer_id),
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('checking', 'savings', 'credit', 'business')),
    balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    credit_limit DECIMAL(15,2),
    created_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'frozen', 'closed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Merchant information
CREATE TABLE financial_merchants (
    merchant_id SERIAL PRIMARY KEY,
    merchant_name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    risk_level VARCHAR(10) CHECK (risk_level IN ('low', 'medium', 'high')),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction records
CREATE TABLE financial_transactions (
    transaction_id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES financial_accounts(account_id),
    transaction_date TIMESTAMP NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer', 'payment', 'refund')),
    merchant_id INTEGER REFERENCES financial_merchants(merchant_id),
    description TEXT,
    location VARCHAR(100),
    is_suspicious BOOLEAN DEFAULT FALSE,
    fraud_score DECIMAL(3,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

\echo '✅ Financial Transactions tables created!'

-- =====================================================
-- SECTION 4: IOT TIME SERIES DATABASE
-- =====================================================
\echo '🌡️ Setting up IoT Time Series Database...'

-- Device registry
CREATE TABLE iot_devices (
    device_id SERIAL PRIMARY KEY,
    device_name VARCHAR(100) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    installation_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'offline')),
    firmware_version VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sensor readings
CREATE TABLE iot_sensor_readings (
    reading_id SERIAL PRIMARY KEY,
    device_id INTEGER REFERENCES iot_devices(device_id),
    timestamp TIMESTAMP NOT NULL,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    pressure DECIMAL(8,2),
    battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
    signal_strength INTEGER CHECK (signal_strength >= 0 AND signal_strength <= 100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Device alerts and anomalies
CREATE TABLE iot_alerts (
    alert_id SERIAL PRIMARY KEY,
    device_id INTEGER REFERENCES iot_devices(device_id),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(10) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    alert_timestamp TIMESTAMP NOT NULL,
    message TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_timestamp TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

\echo '✅ IoT Time Series tables created!'

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================
\echo '⚡ Creating performance indexes...'

-- E-commerce indexes
CREATE INDEX idx_ecommerce_orders_user_date ON ecommerce_orders(user_id, order_date);
CREATE INDEX idx_ecommerce_orders_date ON ecommerce_orders(order_date);
CREATE INDEX idx_ecommerce_events_user_timestamp ON ecommerce_user_events(user_id, event_timestamp);
CREATE INDEX idx_ecommerce_events_type_timestamp ON ecommerce_user_events(event_type, event_timestamp);

-- Financial indexes
CREATE INDEX idx_financial_transactions_account_date ON financial_transactions(account_id, transaction_date);
CREATE INDEX idx_financial_transactions_date ON financial_transactions(transaction_date);
CREATE INDEX idx_financial_transactions_amount ON financial_transactions(amount);
CREATE INDEX idx_financial_transactions_suspicious ON financial_transactions(is_suspicious);

-- IoT indexes
CREATE INDEX idx_iot_readings_device_timestamp ON iot_sensor_readings(device_id, timestamp);
CREATE INDEX idx_iot_readings_timestamp ON iot_sensor_readings(timestamp);
CREATE INDEX idx_iot_alerts_device_timestamp ON iot_alerts(device_id, alert_timestamp);

\echo '✅ Performance indexes created!'

-- =====================================================
-- VIEWS FOR COMMON ANALYSIS PATTERNS
-- =====================================================
\echo '👁️ Creating analysis views...'

-- Customer lifetime value view
CREATE VIEW ecommerce_customer_ltv AS
SELECT 
    u.user_id,
    u.signup_date,
    u.country,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.order_value) as lifetime_value,
    AVG(o.order_value) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    EXTRACT(DAYS FROM (MAX(o.order_date) - MIN(o.order_date))) as customer_lifespan_days
FROM ecommerce_users u
LEFT JOIN ecommerce_orders o ON u.user_id = o.user_id
WHERE o.status = 'completed'
GROUP BY u.user_id, u.signup_date, u.country;

-- Daily transaction summary view
CREATE VIEW financial_daily_summary AS
SELECT 
    DATE(transaction_date) as transaction_date,
    COUNT(*) as total_transactions,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount,
    COUNT(CASE WHEN is_suspicious THEN 1 END) as suspicious_transactions,
    COUNT(CASE WHEN amount > 10000 THEN 1 END) as large_transactions
FROM financial_transactions
GROUP BY DATE(transaction_date);

-- IoT device health summary
CREATE VIEW iot_device_health AS
SELECT 
    d.device_id,
    d.device_name,
    d.device_type,
    d.location,
    COUNT(r.reading_id) as total_readings_today,
    AVG(r.temperature) as avg_temperature,
    AVG(r.humidity) as avg_humidity,
    AVG(r.battery_level) as avg_battery_level,
    COUNT(a.alert_id) as alerts_today
FROM iot_devices d
LEFT JOIN iot_sensor_readings r ON d.device_id = r.device_id AND DATE(r.timestamp) = CURRENT_DATE
LEFT JOIN iot_alerts a ON d.device_id = a.device_id AND DATE(a.alert_timestamp) = CURRENT_DATE
GROUP BY d.device_id, d.device_name, d.device_type, d.location;

\echo '✅ Analysis views created!'

-- =====================================================
-- SAMPLE DATA GENERATION (Small Sample)
-- =====================================================
\echo '📊 Generating sample data...'

-- Note: This is a minimal sample. Full dataset generation would be much larger
-- and is better done with a separate data generation script.

-- Sample e-commerce users
INSERT INTO ecommerce_users (signup_date, country, device_type, traffic_source, age_group)
SELECT 
    CURRENT_DATE - (random() * 365)::integer,
    CASE (random() * 5)::integer
        WHEN 0 THEN 'USA'
        WHEN 1 THEN 'Canada'
        WHEN 2 THEN 'UK'
        WHEN 3 THEN 'Germany'
        ELSE 'France'
    END,
    CASE (random() * 3)::integer
        WHEN 0 THEN 'desktop'
        WHEN 1 THEN 'mobile'
        ELSE 'tablet'
    END,
    CASE (random() * 4)::integer
        WHEN 0 THEN 'organic'
        WHEN 1 THEN 'paid_search'
        WHEN 2 THEN 'social'
        ELSE 'email'
    END,
    CASE (random() * 4)::integer
        WHEN 0 THEN '18-25'
        WHEN 1 THEN '26-35'
        WHEN 2 THEN '36-50'
        ELSE '50+'
    END
FROM generate_series(1, 100);

\echo '✅ Sample data generated!'

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
\echo '🔍 Running verification queries...'
\echo ''

-- Check table counts
\echo 'Table Record Counts:'
SELECT 'Chinook - Customer' as table_name, COUNT(*) as record_count FROM Customer
UNION ALL
SELECT 'Chinook - Invoice', COUNT(*) FROM Invoice
UNION ALL
SELECT 'E-commerce - Users', COUNT(*) FROM ecommerce_users
UNION ALL
SELECT 'Financial - Customers', COUNT(*) FROM financial_customers
UNION ALL
SELECT 'IoT - Devices', COUNT(*) FROM iot_devices;

\echo ''
\echo '🎉 SQL Analyst Pack Database Setup Complete!'
\echo ''
\echo 'Next Steps:'
\echo '1. Explore the sample data in each schema'
\echo '2. Run the verification queries below'
\echo '3. Start with the foundations course: 01_foundations/'
\echo '4. Check out the sample queries in the README.md'
\echo ''
\echo 'Happy Learning! 🚀'
