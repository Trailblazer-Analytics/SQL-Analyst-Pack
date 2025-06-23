-- SQL Analyst Pack Sample Data Setup for PostgreSQL
-- This script creates sample datasets for learning and practice

-- Create sample e-commerce schema
CREATE SCHEMA IF NOT EXISTS ecommerce;
SET search_path TO ecommerce;

-- Customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50) DEFAULT 'USA',
    postal_code VARCHAR(20),
    registration_date DATE DEFAULT CURRENT_DATE,
    customer_segment VARCHAR(20) DEFAULT 'Standard',
    acquisition_channel VARCHAR(30),
    birth_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    brand VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2),
    weight_kg DECIMAL(8,2),
    dimensions_cm VARCHAR(20),
    color VARCHAR(30),
    size VARCHAR(10),
    stock_quantity INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,
    supplier_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date DATE DEFAULT CURRENT_DATE,
    order_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_status VARCHAR(20) DEFAULT 'pending',
    shipping_method VARCHAR(30),
    shipping_cost DECIMAL(8,2) DEFAULT 0,
    tax_amount DECIMAL(8,2) DEFAULT 0,
    discount_amount DECIMAL(8,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(30),
    shipping_address TEXT,
    billing_address TEXT,
    order_source VARCHAR(20) DEFAULT 'website',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Items table
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    line_total DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount_percent/100)) STORED
);

-- Marketing campaigns table
CREATE TABLE campaigns (
    campaign_id SERIAL PRIMARY KEY,
    campaign_name VARCHAR(100) NOT NULL,
    campaign_type VARCHAR(30),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10,2),
    target_audience VARCHAR(50),
    channel VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customer campaign interactions
CREATE TABLE campaign_interactions (
    interaction_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    campaign_id INTEGER REFERENCES campaigns(campaign_id),
    interaction_date DATE DEFAULT CURRENT_DATE,
    interaction_type VARCHAR(30), -- email_open, click, conversion, etc.
    conversion_value DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Website sessions table
CREATE TABLE website_sessions (
    session_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    session_date DATE DEFAULT CURRENT_DATE,
    session_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP,
    page_views INTEGER DEFAULT 1,
    session_duration_minutes INTEGER,
    traffic_source VARCHAR(50),
    device_type VARCHAR(20),
    browser VARCHAR(30),
    converted BOOLEAN DEFAULT FALSE,
    conversion_value DECIMAL(10,2) DEFAULT 0
);

-- Create indexes for better query performance
CREATE INDEX idx_customers_segment ON customers(customer_segment);
CREATE INDEX idx_customers_registration ON customers(registration_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_sessions_customer ON website_sessions(customer_id);
CREATE INDEX idx_sessions_date ON website_sessions(session_date);

-- Insert sample data
\echo 'Inserting sample customers...'

INSERT INTO customers (customer_name, email, phone, city, state, customer_segment, acquisition_channel, birth_date) VALUES
('John Smith', 'john.smith@email.com', '555-0101', 'New York', 'NY', 'Premium', 'Google Ads', '1985-03-15'),
('Sarah Johnson', 'sarah.j@email.com', '555-0102', 'Los Angeles', 'CA', 'Standard', 'Organic Search', '1990-07-22'),
('Michael Brown', 'm.brown@email.com', '555-0103', 'Chicago', 'IL', 'VIP', 'Referral', '1982-11-08'),
('Emily Davis', 'emily.davis@email.com', '555-0104', 'Houston', 'TX', 'Standard', 'Social Media', '1988-05-12'),
('David Wilson', 'david.w@email.com', '555-0105', 'Phoenix', 'AZ', 'Premium', 'Email Campaign', '1975-09-30'),
('Lisa Anderson', 'lisa.a@email.com', '555-0106', 'Philadelphia', 'PA', 'Standard', 'Organic Search', '1992-02-18'),
('Robert Taylor', 'robert.t@email.com', '555-0107', 'San Antonio', 'TX', 'VIP', 'Referral', '1980-12-05'),
('Jennifer Martinez', 'jennifer.m@email.com', '555-0108', 'San Diego', 'CA', 'Premium', 'Google Ads', '1987-04-25'),
('William Garcia', 'william.g@email.com', '555-0109', 'Dallas', 'TX', 'Standard', 'Social Media', '1983-08-14'),
('Jessica Rodriguez', 'jessica.r@email.com', '555-0110', 'San Jose', 'CA', 'Premium', 'Email Campaign', '1991-01-03');

\echo 'Inserting sample products...'

INSERT INTO products (product_name, category, subcategory, brand, price, cost, stock_quantity) VALUES
('Wireless Bluetooth Headphones', 'Electronics', 'Audio', 'TechBrand', 79.99, 35.00, 150),
('Organic Cotton T-Shirt', 'Clothing', 'Shirts', 'EcoWear', 24.99, 12.00, 200),
('Stainless Steel Water Bottle', 'Home & Garden', 'Kitchen', 'HydroPlus', 19.99, 8.50, 300),
('Laptop Stand Adjustable', 'Electronics', 'Accessories', 'DeskMaster', 45.99, 20.00, 75),
('Natural Face Moisturizer', 'Beauty', 'Skincare', 'PureGlow', 34.99, 15.00, 120),
('Running Shoes Men', 'Sports', 'Footwear', 'RunFast', 89.99, 40.00, 80),
('Coffee Maker 12-Cup', 'Home & Garden', 'Kitchen', 'BrewMaster', 129.99, 60.00, 45),
('Yoga Mat Premium', 'Sports', 'Fitness', 'ZenFit', 39.99, 18.00, 100),
('Phone Case iPhone', 'Electronics', 'Accessories', 'ProtectMax', 14.99, 6.00, 250),
('Ceramic Dinner Plates Set', 'Home & Garden', 'Dining', 'HomeStyle', 59.99, 25.00, 60);

\echo 'Inserting sample orders and order items...'

-- Generate sample orders
DO $$
DECLARE
    order_counter INTEGER := 1;
    customer_count INTEGER;
    product_count INTEGER;
    random_customer INTEGER;
    random_product INTEGER;
    random_quantity INTEGER;
    random_date DATE;
    current_order_id INTEGER;
BEGIN
    SELECT COUNT(*) INTO customer_count FROM customers;
    SELECT COUNT(*) INTO product_count FROM products;
    
    -- Generate 100 sample orders
    WHILE order_counter <= 100 LOOP
        -- Random customer
        random_customer := floor(random() * customer_count) + 1;
        
        -- Random date in last 365 days
        random_date := CURRENT_DATE - floor(random() * 365)::INTEGER;
        
        -- Insert order
        INSERT INTO orders (customer_id, order_date, order_status, total_amount, payment_method, order_source)
        VALUES (
            random_customer,
            random_date,
            CASE floor(random() * 4)
                WHEN 0 THEN 'completed'
                WHEN 1 THEN 'shipped'
                WHEN 2 THEN 'processing'
                ELSE 'completed'
            END,
            0, -- Will be updated after items
            CASE floor(random() * 3)
                WHEN 0 THEN 'credit_card'
                WHEN 1 THEN 'paypal'
                ELSE 'debit_card'
            END,
            CASE floor(random() * 3)
                WHEN 0 THEN 'website'
                WHEN 1 THEN 'mobile_app'
                ELSE 'phone'
            END
        ) RETURNING order_id INTO current_order_id;
        
        -- Add 1-4 random items to each order
        FOR i IN 1..floor(random() * 4) + 1 LOOP
            random_product := floor(random() * product_count) + 1;
            random_quantity := floor(random() * 3) + 1;
            
            INSERT INTO order_items (order_id, product_id, quantity, unit_price)
            SELECT current_order_id, random_product, random_quantity, price
            FROM products WHERE product_id = random_product;
        END LOOP;
        
        -- Update order total
        UPDATE orders 
        SET total_amount = (
            SELECT COALESCE(SUM(line_total), 0) 
            FROM order_items 
            WHERE order_id = current_order_id
        )
        WHERE order_id = current_order_id;
        
        order_counter := order_counter + 1;
    END LOOP;
END $$;

\echo 'Inserting sample campaigns...'

INSERT INTO campaigns (campaign_name, campaign_type, start_date, end_date, budget, target_audience, channel) VALUES
('Spring Sale 2024', 'Promotion', '2024-03-01', '2024-04-30', 15000.00, 'All Customers', 'Email'),
('New Customer Welcome', 'Acquisition', '2024-01-01', '2024-12-31', 25000.00, 'New Customers', 'Google Ads'),
('VIP Customer Exclusive', 'Retention', '2024-02-15', '2024-03-15', 8000.00, 'VIP Customers', 'Direct Mail'),
('Summer Fashion Launch', 'Product Launch', '2024-05-01', '2024-07-31', 20000.00, 'Fashion Interested', 'Social Media'),
('Back to School', 'Seasonal', '2024-08-01', '2024-09-15', 12000.00, 'Students & Parents', 'Multiple');

\echo 'Creating sample analytics views...'

-- Create useful views for analysis
CREATE VIEW customer_summary AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    c.customer_segment,
    c.acquisition_channel,
    c.registration_date,
    COUNT(o.order_id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as total_spent,
    COALESCE(AVG(o.total_amount), 0) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    CURRENT_DATE - MAX(o.order_date) as days_since_last_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email, c.customer_segment, 
         c.acquisition_channel, c.registration_date;

CREATE VIEW monthly_sales AS
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE order_status = 'completed'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

CREATE VIEW product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    COUNT(oi.order_item_id) as units_sold,
    SUM(oi.line_total) as total_revenue,
    COUNT(DISTINCT oi.order_id) as orders_containing_product
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status = 'completed'
GROUP BY p.product_id, p.product_name, p.category, p.price
ORDER BY total_revenue DESC;

\echo 'Sample data setup complete!'
\echo 'Available tables: customers, products, orders, order_items, campaigns, campaign_interactions, website_sessions'
\echo 'Available views: customer_summary, monthly_sales, product_performance'
