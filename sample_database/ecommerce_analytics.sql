-- =====================================================
-- E-commerce Analytics Sample Database
-- =====================================================
-- Purpose: Advanced analytics scenarios including:
-- - Customer behavior analysis
-- - A/B testing and experimentation
-- - Cohort analysis and retention
-- - Funnel analysis and conversion optimization
-- =====================================================

-- Create database schema for e-commerce analytics

-- Users table: Customer registration and profile data
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    signup_date DATE NOT NULL,
    country VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(100),
    device_type VARCHAR(20) CHECK (device_type IN ('mobile', 'desktop', 'tablet')),
    traffic_source VARCHAR(50),
    age_group VARCHAR(20) CHECK (age_group IN ('18-24', '25-34', '35-44', '45-54', '55+')),
    gender VARCHAR(10) CHECK (gender IN ('M', 'F', 'Other')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table: Product catalog with categories
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    supplier_id INTEGER,
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table: Purchase transactions
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    order_date TIMESTAMP NOT NULL,
    order_value DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    shipping_cost DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'returned')),
    payment_method VARCHAR(50),
    shipping_country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order items table: Individual items within orders
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- User events table: Website behavior tracking
CREATE TABLE user_events (
    event_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    session_id VARCHAR(255),
    event_type VARCHAR(50) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    page_url VARCHAR(500),
    referrer_url VARCHAR(500),
    product_id INTEGER REFERENCES products(product_id),
    event_properties JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- A/B tests table: Experimentation tracking
CREATE TABLE ab_tests (
    test_id SERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    user_id INTEGER REFERENCES users(user_id),
    variant VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    conversion_event VARCHAR(100),
    converted BOOLEAN DEFAULT FALSE,
    conversion_value DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cohorts table: Pre-calculated cohort analysis
CREATE TABLE cohorts (
    cohort_id SERIAL PRIMARY KEY,
    cohort_month DATE NOT NULL,
    users_count INTEGER NOT NULL,
    retention_month_1 INTEGER,
    retention_month_3 INTEGER,
    retention_month_6 INTEGER,
    retention_month_12 INTEGER,
    avg_order_value_month_1 DECIMAL(10,2),
    total_revenue_month_1 DECIMAL(10,2)
);

-- Customer segments table: Marketing segments
CREATE TABLE customer_segments (
    segment_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    segment_name VARCHAR(100) NOT NULL,
    rfm_score VARCHAR(10),
    recency_score INTEGER CHECK (recency_score BETWEEN 1 AND 5),
    frequency_score INTEGER CHECK (frequency_score BETWEEN 1 AND 5),
    monetary_score INTEGER CHECK (monetary_score BETWEEN 1 AND 5),
    segment_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Insert Sample Data
-- =====================================================

-- Insert sample users (5000 users over 2 years)
INSERT INTO users (email, signup_date, country, state, city, device_type, traffic_source, age_group, gender)
SELECT 
    'user' || i || '@example.com',
    CURRENT_DATE - INTERVAL '730 days' + (i * INTERVAL '8 hours'),
    CASE (i % 5)
        WHEN 0 THEN 'USA'
        WHEN 1 THEN 'Canada'
        WHEN 2 THEN 'UK'
        WHEN 3 THEN 'Germany'
        ELSE 'France'
    END,
    CASE (i % 10)
        WHEN 0 THEN 'California'
        WHEN 1 THEN 'New York'
        WHEN 2 THEN 'Texas'
        WHEN 3 THEN 'Ontario'
        WHEN 4 THEN 'London'
        ELSE NULL
    END,
    CASE (i % 8)
        WHEN 0 THEN 'San Francisco'
        WHEN 1 THEN 'New York City'
        WHEN 2 THEN 'Austin'
        WHEN 3 THEN 'Toronto'
        WHEN 4 THEN 'London'
        WHEN 5 THEN 'Berlin'
        WHEN 6 THEN 'Paris'
        ELSE 'Vancouver'
    END,
    CASE (i % 3)
        WHEN 0 THEN 'mobile'
        WHEN 1 THEN 'desktop'
        ELSE 'tablet'
    END,
    CASE (i % 6)
        WHEN 0 THEN 'google'
        WHEN 1 THEN 'facebook'
        WHEN 2 THEN 'direct'
        WHEN 3 THEN 'email'
        WHEN 4 THEN 'referral'
        ELSE 'organic'
    END,
    CASE (i % 5)
        WHEN 0 THEN '18-24'
        WHEN 1 THEN '25-34'
        WHEN 2 THEN '35-44'
        WHEN 3 THEN '45-54'
        ELSE '55+'
    END,
    CASE (i % 3)
        WHEN 0 THEN 'M'
        WHEN 1 THEN 'F'
        ELSE 'Other'
    END
FROM generate_series(1, 5000) AS i;

-- Insert sample products (500 products across categories)
INSERT INTO products (product_name, category, subcategory, supplier_id, unit_cost, unit_price, description)
SELECT 
    'Product ' || i,
    CASE (i % 8)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Home & Garden'
        WHEN 3 THEN 'Sports'
        WHEN 4 THEN 'Books'
        WHEN 5 THEN 'Beauty'
        WHEN 6 THEN 'Automotive'
        ELSE 'Health'
    END,
    CASE (i % 15)
        WHEN 0 THEN 'Smartphones'
        WHEN 1 THEN 'Laptops'
        WHEN 2 THEN 'Men''s Clothing'
        WHEN 3 THEN 'Women''s Clothing'
        WHEN 4 THEN 'Furniture'
        WHEN 5 THEN 'Kitchen'
        WHEN 6 THEN 'Fitness'
        WHEN 7 THEN 'Outdoor'
        WHEN 8 THEN 'Fiction'
        WHEN 9 THEN 'Non-Fiction'
        WHEN 10 THEN 'Skincare'
        WHEN 11 THEN 'Makeup'
        WHEN 12 THEN 'Car Parts'
        WHEN 13 THEN 'Vitamins'
        ELSE 'Supplements'
    END,
    (i % 50) + 1,
    ROUND((RANDOM() * 100 + 10)::numeric, 2),
    ROUND((RANDOM() * 200 + 25)::numeric, 2),
    'High-quality product with excellent features and customer satisfaction.'
FROM generate_series(1, 500) AS i;

-- Insert sample orders (15000 orders with seasonal patterns)
INSERT INTO orders (user_id, order_date, order_value, discount_amount, shipping_cost, tax_amount, status, payment_method, shipping_country)
SELECT 
    (RANDOM() * 4999 + 1)::integer,
    CURRENT_DATE - INTERVAL '365 days' + (RANDOM() * INTERVAL '365 days'),
    ROUND((RANDOM() * 500 + 25)::numeric, 2),
    ROUND((RANDOM() * 50)::numeric, 2),
    CASE 
        WHEN RANDOM() < 0.7 THEN 0  -- Free shipping
        ELSE ROUND((RANDOM() * 15 + 5)::numeric, 2)
    END,
    0, -- Tax calculated separately
    CASE 
        WHEN RANDOM() < 0.85 THEN 'delivered'
        WHEN RANDOM() < 0.92 THEN 'shipped'
        WHEN RANDOM() < 0.96 THEN 'confirmed'
        WHEN RANDOM() < 0.98 THEN 'pending'
        ELSE 'cancelled'
    END,
    CASE (FLOOR(RANDOM() * 4)::integer)
        WHEN 0 THEN 'credit_card'
        WHEN 1 THEN 'paypal'
        WHEN 2 THEN 'debit_card'
        ELSE 'bank_transfer'
    END,
    CASE (FLOOR(RANDOM() * 5)::integer)
        WHEN 0 THEN 'USA'
        WHEN 1 THEN 'Canada'
        WHEN 2 THEN 'UK'
        WHEN 3 THEN 'Germany'
        ELSE 'France'
    END
FROM generate_series(1, 15000) AS i;

-- Update tax amounts based on order value
UPDATE orders SET tax_amount = ROUND((order_value * 0.08)::numeric, 2);

-- Insert order items (2-5 items per order on average)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 
    o.order_id,
    (RANDOM() * 499 + 1)::integer,
    (RANDOM() * 3 + 1)::integer,
    p.unit_price * (0.8 + RANDOM() * 0.4) -- Some price variation
FROM orders o
CROSS JOIN LATERAL (
    SELECT * FROM generate_series(1, (RANDOM() * 4 + 1)::integer)
) AS items
JOIN products p ON p.product_id = (RANDOM() * 499 + 1)::integer
WHERE o.order_id <= 15000;

-- Insert user events (website behavior - 100,000 events)
INSERT INTO user_events (user_id, session_id, event_type, event_timestamp, page_url, product_id, event_properties)
SELECT 
    (RANDOM() * 4999 + 1)::integer,
    'sess_' || FLOOR(RANDOM() * 50000),
    CASE (FLOOR(RANDOM() * 8)::integer)
        WHEN 0 THEN 'page_view'
        WHEN 1 THEN 'product_view'
        WHEN 2 THEN 'add_to_cart'
        WHEN 3 THEN 'purchase'
        WHEN 4 THEN 'search'
        WHEN 5 THEN 'signup'
        WHEN 6 THEN 'login'
        ELSE 'logout'
    END,
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '365 days'),
    '/page/' || FLOOR(RANDOM() * 100),
    CASE WHEN RANDOM() < 0.3 THEN (RANDOM() * 499 + 1)::integer ELSE NULL END,
    '{"browser": "Chrome", "os": "Windows"}'::jsonb
FROM generate_series(1, 100000) AS i;

-- Insert A/B test data
INSERT INTO ab_tests (test_name, user_id, variant, start_date, end_date, conversion_event, converted, conversion_value)
SELECT 
    CASE (i % 3)
        WHEN 0 THEN 'checkout_button_color'
        WHEN 1 THEN 'product_page_layout'
        ELSE 'email_subject_line'
    END,
    (RANDOM() * 4999 + 1)::integer,
    CASE (i % 2)
        WHEN 0 THEN 'control'
        ELSE 'treatment'
    END,
    CURRENT_DATE - INTERVAL '90 days',
    CURRENT_DATE - INTERVAL '30 days',
    'purchase',
    RANDOM() < 0.15, -- 15% conversion rate
    CASE WHEN RANDOM() < 0.15 THEN ROUND((RANDOM() * 200 + 50)::numeric, 2) ELSE NULL END
FROM generate_series(1, 2000) AS i;

-- Insert cohort analysis data (monthly cohorts)
INSERT INTO cohorts (cohort_month, users_count, retention_month_1, retention_month_3, retention_month_6, retention_month_12)
SELECT 
    date_trunc('month', CURRENT_DATE - (i * INTERVAL '1 month')),
    FLOOR(RANDOM() * 500 + 100)::integer,
    FLOOR(RANDOM() * 40 + 20)::integer,
    FLOOR(RANDOM() * 25 + 10)::integer,
    FLOOR(RANDOM() * 15 + 5)::integer,
    FLOOR(RANDOM() * 10 + 2)::integer
FROM generate_series(0, 23) AS i; -- 24 months of data

-- Insert customer segments (RFM analysis)
INSERT INTO customer_segments (user_id, segment_name, rfm_score, recency_score, frequency_score, monetary_score, segment_date)
SELECT 
    user_id,
    CASE 
        WHEN RANDOM() < 0.1 THEN 'Champions'
        WHEN RANDOM() < 0.25 THEN 'Loyal Customers'
        WHEN RANDOM() < 0.4 THEN 'Potential Loyalists'
        WHEN RANDOM() < 0.55 THEN 'Recent Customers'
        WHEN RANDOM() < 0.7 THEN 'Promising'
        WHEN RANDOM() < 0.8 THEN 'Customers Needing Attention'
        WHEN RANDOM() < 0.9 THEN 'At Risk'
        ELSE 'Lost Customers'
    END,
    LPAD((FLOOR(RANDOM() * 5) + 1)::text, 1, '0') || 
    LPAD((FLOOR(RANDOM() * 5) + 1)::text, 1, '0') || 
    LPAD((FLOOR(RANDOM() * 5) + 1)::text, 1, '0'),
    (FLOOR(RANDOM() * 5) + 1)::integer,
    (FLOOR(RANDOM() * 5) + 1)::integer,
    (FLOOR(RANDOM() * 5) + 1)::integer,
    CURRENT_DATE
FROM users
WHERE RANDOM() < 0.8; -- 80% of users have been segmented

-- =====================================================
-- Create useful indexes for performance
-- =====================================================

CREATE INDEX idx_users_signup_date ON users(signup_date);
CREATE INDEX idx_users_country ON users(country);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_user_events_user_id ON user_events(user_id);
CREATE INDEX idx_user_events_timestamp ON user_events(event_timestamp);
CREATE INDEX idx_user_events_type ON user_events(event_type);
CREATE INDEX idx_ab_tests_user_id ON ab_tests(user_id);
CREATE INDEX idx_ab_tests_test_name ON ab_tests(test_name);

-- =====================================================
-- Create helpful views for common analytics
-- =====================================================

-- Customer lifetime value view
CREATE VIEW customer_ltv AS
SELECT 
    u.user_id,
    u.email,
    u.signup_date,
    COUNT(o.order_id) as total_orders,
    SUM(o.order_value) as total_spent,
    AVG(o.order_value) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    MIN(o.order_date) as first_order_date,
    EXTRACT(DAYS FROM (MAX(o.order_date) - MIN(o.order_date))) as customer_lifespan_days
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.email, u.signup_date;

-- Monthly revenue view
CREATE VIEW monthly_revenue AS
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as orders_count,
    SUM(order_value) as total_revenue,
    AVG(order_value) as avg_order_value,
    COUNT(DISTINCT user_id) as unique_customers
FROM orders
WHERE status IN ('delivered', 'shipped')
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- Product performance view
CREATE VIEW product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(oi.order_item_id) as times_ordered,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.total_price) as total_revenue,
    AVG(oi.unit_price) as avg_selling_price,
    p.unit_cost,
    SUM(oi.total_price) - (SUM(oi.quantity) * p.unit_cost) as profit
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.unit_cost;

-- =====================================================
-- Analytics Examples and Common Queries
-- =====================================================

-- Example 1: Cohort retention analysis
/*
SELECT 
    cohort_month,
    users_count,
    retention_month_1,
    ROUND(retention_month_1::numeric / users_count * 100, 2) as retention_rate_month_1,
    retention_month_3,
    ROUND(retention_month_3::numeric / users_count * 100, 2) as retention_rate_month_3,
    retention_month_6,
    ROUND(retention_month_6::numeric / users_count * 100, 2) as retention_rate_month_6
FROM cohorts
ORDER BY cohort_month DESC;
*/

-- Example 2: A/B test performance comparison
/*
SELECT 
    test_name,
    variant,
    COUNT(*) as participants,
    SUM(CASE WHEN converted THEN 1 ELSE 0 END) as conversions,
    ROUND(AVG(CASE WHEN converted THEN 1.0 ELSE 0.0 END) * 100, 2) as conversion_rate,
    AVG(conversion_value) as avg_conversion_value
FROM ab_tests
GROUP BY test_name, variant
ORDER BY test_name, variant;
*/

-- Example 3: Customer segmentation analysis
/*
SELECT 
    segment_name,
    COUNT(*) as customers_count,
    AVG(frequency_score) as avg_frequency,
    AVG(monetary_score) as avg_monetary,
    AVG(recency_score) as avg_recency
FROM customer_segments
GROUP BY segment_name
ORDER BY customers_count DESC;
*/
