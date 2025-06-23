-- =====================================================
-- Financial Transactions Sample Database
-- =====================================================
-- Purpose: Fraud detection and risk analysis scenarios:
-- - Transaction pattern analysis
-- - Anomaly detection techniques
-- - Risk scoring and assessment
-- - Compliance and regulatory reporting
-- =====================================================

-- Create database schema for financial transactions

-- Customers table: Customer profile and risk information
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    ssn_hash VARCHAR(64), -- Hashed for privacy
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    income_level VARCHAR(20) CHECK (income_level IN ('low', 'medium', 'high', 'very_high')),
    credit_score INTEGER CHECK (credit_score BETWEEN 300 AND 850),
    risk_score DECIMAL(5,2) CHECK (risk_score BETWEEN 0 AND 100),
    kyc_status VARCHAR(20) CHECK (kyc_status IN ('pending', 'verified', 'rejected', 'expired')),
    registration_date DATE NOT NULL,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Accounts table: Bank accounts and financial instruments
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type VARCHAR(20) CHECK (account_type IN ('checking', 'savings', 'credit', 'investment', 'business')),
    balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    credit_limit DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    account_status VARCHAR(20) CHECK (account_status IN ('active', 'frozen', 'closed', 'suspended')),
    opened_date DATE NOT NULL,
    closed_date DATE,
    branch_code VARCHAR(10),
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Merchants table: Businesses and service providers
CREATE TABLE merchants (
    merchant_id SERIAL PRIMARY KEY,
    merchant_name VARCHAR(255) NOT NULL,
    merchant_code VARCHAR(20) UNIQUE NOT NULL,
    category_code VARCHAR(10), -- MCC codes
    category_description VARCHAR(100),
    address_line1 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'very_high')),
    is_high_risk BOOLEAN DEFAULT FALSE,
    registration_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions table: All financial transactions
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(account_id),
    merchant_id INTEGER REFERENCES merchants(merchant_id),
    transaction_date TIMESTAMP NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('debit', 'credit', 'transfer', 'withdrawal', 'deposit', 'payment', 'refund')),
    transaction_method VARCHAR(20) CHECK (transaction_method IN ('card', 'ach', 'wire', 'check', 'cash', 'online', 'mobile')),
    description TEXT,
    reference_number VARCHAR(50),
    authorization_code VARCHAR(20),
    terminal_id VARCHAR(20),
    card_number_masked VARCHAR(20), -- Last 4 digits only
    location_city VARCHAR(100),
    location_state VARCHAR(50),
    location_country VARCHAR(50),
    is_international BOOLEAN DEFAULT FALSE,
    is_suspicious BOOLEAN DEFAULT FALSE,
    fraud_score DECIMAL(5,2) CHECK (fraud_score BETWEEN 0 AND 100),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'cancelled', 'disputed', 'reversed')),
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fraud alerts table: Suspicious activity notifications
CREATE TABLE fraud_alerts (
    alert_id SERIAL PRIMARY KEY,
    transaction_id INTEGER REFERENCES transactions(transaction_id),
    customer_id INTEGER REFERENCES customers(customer_id),
    alert_type VARCHAR(50) NOT NULL,
    alert_description TEXT,
    risk_score DECIMAL(5,2),
    alert_status VARCHAR(20) CHECK (alert_status IN ('open', 'investigating', 'resolved', 'false_positive')),
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_notes TEXT
);

-- Account balances history for trend analysis
CREATE TABLE balance_history (
    balance_id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(account_id),
    balance_date DATE NOT NULL,
    balance_amount DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Insert Sample Data
-- =====================================================

-- Insert sample customers (10,000 customers)
INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, address_line1, city, state, postal_code, 
                      income_level, credit_score, risk_score, kyc_status, registration_date, is_active)
SELECT 
    'Customer' || i,
    'LastName' || i,
    'customer' || i || '@example.com',
    '+1555' || LPAD(i::text, 7, '0'),
    DATE '1950-01-01' + (i % 25000), -- Ages 20-90
    i || ' Main Street',
    CASE (i % 10)
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Los Angeles'
        WHEN 2 THEN 'Chicago'
        WHEN 3 THEN 'Houston'
        WHEN 4 THEN 'Phoenix'
        WHEN 5 THEN 'Philadelphia'
        WHEN 6 THEN 'San Antonio'
        WHEN 7 THEN 'San Diego'
        WHEN 8 THEN 'Dallas'
        ELSE 'Austin'
    END,
    CASE (i % 5)
        WHEN 0 THEN 'NY'
        WHEN 1 THEN 'CA'
        WHEN 2 THEN 'IL'
        WHEN 3 THEN 'TX'
        ELSE 'AZ'
    END,
    LPAD((10000 + (i % 90000))::text, 5, '0'),
    CASE 
        WHEN i % 4 = 0 THEN 'low'
        WHEN i % 4 = 1 THEN 'medium'
        WHEN i % 4 = 2 THEN 'high'
        ELSE 'very_high'
    END,
    300 + (i % 551), -- Credit scores 300-850
    ROUND((RANDOM() * 100)::numeric, 2),
    CASE (i % 4)
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'verified'
        WHEN 2 THEN 'verified'
        ELSE 'verified'
    END,
    CURRENT_DATE - (i % 3650), -- Registration over 10 years
    CASE WHEN i % 20 = 0 THEN FALSE ELSE TRUE END
FROM generate_series(1, 10000) AS i;

-- Insert sample accounts (15,000 accounts - some customers have multiple)
INSERT INTO accounts (customer_id, account_number, account_type, balance, credit_limit, account_status, opened_date, branch_code)
SELECT 
    (i % 10000) + 1,
    'ACC' || LPAD(i::text, 12, '0'),
    CASE (i % 5)
        WHEN 0 THEN 'checking'
        WHEN 1 THEN 'savings'
        WHEN 2 THEN 'credit'
        WHEN 3 THEN 'investment'
        ELSE 'business'
    END,
    ROUND((RANDOM() * 50000 + 100)::numeric, 2),
    CASE 
        WHEN (i % 5) = 2 THEN ROUND((RANDOM() * 20000 + 1000)::numeric, 2) -- Credit accounts
        ELSE NULL
    END,
    CASE WHEN i % 50 = 0 THEN 'frozen' ELSE 'active' END,
    CURRENT_DATE - (i % 3650),
    'BR' || LPAD(((i % 100) + 1)::text, 3, '0')
FROM generate_series(1, 15000) AS i;

-- Insert sample merchants (2,000 merchants)
INSERT INTO merchants (merchant_name, merchant_code, category_code, category_description, city, state, country, risk_level, is_high_risk, registration_date)
SELECT 
    CASE (i % 15)
        WHEN 0 THEN 'SuperMarket ' || i
        WHEN 1 THEN 'Gas Station ' || i
        WHEN 2 THEN 'Restaurant ' || i
        WHEN 3 THEN 'Online Store ' || i
        WHEN 4 THEN 'ATM Location ' || i
        WHEN 5 THEN 'Department Store ' || i
        WHEN 6 THEN 'Pharmacy ' || i
        WHEN 7 THEN 'Hotel ' || i
        WHEN 8 THEN 'Car Rental ' || i
        WHEN 9 THEN 'Airlines ' || i
        WHEN 10 THEN 'Electronics Store ' || i
        WHEN 11 THEN 'Coffee Shop ' || i
        WHEN 12 THEN 'Casino ' || i
        WHEN 13 THEN 'Jewelry Store ' || i
        ELSE 'Unknown Merchant ' || i
    END,
    'MERCH' || LPAD(i::text, 8, '0'),
    CASE (i % 15)
        WHEN 0 THEN '5411' -- Grocery stores
        WHEN 1 THEN '5542' -- Gas stations
        WHEN 2 THEN '5812' -- Restaurants
        WHEN 3 THEN '5999' -- Miscellaneous retail
        WHEN 4 THEN '6011' -- ATM
        WHEN 5 THEN '5311' -- Department stores
        WHEN 6 THEN '5912' -- Drug stores
        WHEN 7 THEN '7011' -- Hotels
        WHEN 8 THEN '7512' -- Car rental
        WHEN 9 THEN '4511' -- Airlines
        WHEN 10 THEN '5732' -- Electronics
        WHEN 11 THEN '5814' -- Fast food
        WHEN 12 THEN '7995' -- Gambling
        WHEN 13 THEN '5944' -- Jewelry
        ELSE '5999'
    END,
    CASE (i % 15)
        WHEN 0 THEN 'Grocery Stores and Supermarkets'
        WHEN 1 THEN 'Automated Fuel Dispensers'
        WHEN 2 THEN 'Eating Places, Restaurants'
        WHEN 3 THEN 'Miscellaneous and Specialty Retail Stores'
        WHEN 4 THEN 'Automated Cash Disbursements'
        WHEN 5 THEN 'Department Stores'
        WHEN 6 THEN 'Drug Stores and Pharmacies'
        WHEN 7 THEN 'Hotels, Motels, and Resorts'
        WHEN 8 THEN 'Automobile Rental Agency'
        WHEN 9 THEN 'Airlines, Air Carriers'
        WHEN 10 THEN 'Electronics Stores'
        WHEN 11 THEN 'Fast Food Restaurants'
        WHEN 12 THEN 'Betting/Casino Gambling'
        WHEN 13 THEN 'Jewelry Stores, Watches, Clocks'
        ELSE 'Miscellaneous'
    END,
    CASE (i % 10)
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Los Angeles'
        WHEN 2 THEN 'Chicago'
        WHEN 3 THEN 'Houston'
        WHEN 4 THEN 'Phoenix'
        WHEN 5 THEN 'Philadelphia'
        WHEN 6 THEN 'San Antonio'
        WHEN 7 THEN 'San Diego'
        WHEN 8 THEN 'Dallas'
        ELSE 'Austin'
    END,
    CASE (i % 5)
        WHEN 0 THEN 'NY'
        WHEN 1 THEN 'CA'
        WHEN 2 THEN 'IL'
        WHEN 3 THEN 'TX'
        ELSE 'AZ'
    END,
    'USA',
    CASE 
        WHEN i % 20 = 0 THEN 'high'
        WHEN i % 10 = 0 THEN 'medium'
        ELSE 'low'
    END,
    CASE WHEN i % 20 = 0 OR (i % 15) = 12 THEN TRUE ELSE FALSE END, -- Casinos and some others
    CURRENT_DATE - (i % 2000)
FROM generate_series(1, 2000) AS i;

-- Insert sample transactions (200,000 transactions with patterns)
INSERT INTO transactions (account_id, merchant_id, transaction_date, amount, transaction_type, transaction_method, 
                         description, card_number_masked, location_city, location_state, is_international, 
                         is_suspicious, fraud_score, status)
SELECT 
    (RANDOM() * 14999 + 1)::integer,
    (RANDOM() * 1999 + 1)::integer,
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '365 days'),
    CASE 
        WHEN RANDOM() < 0.7 THEN ROUND((RANDOM() * 200 + 5)::numeric, 2)   -- Normal transactions
        WHEN RANDOM() < 0.95 THEN ROUND((RANDOM() * 1000 + 200)::numeric, 2) -- Larger transactions
        ELSE ROUND((RANDOM() * 10000 + 1000)::numeric, 2) -- Very large transactions
    END,
    CASE (FLOOR(RANDOM() * 7)::integer)
        WHEN 0 THEN 'debit'
        WHEN 1 THEN 'credit'
        WHEN 2 THEN 'payment'
        WHEN 3 THEN 'withdrawal'
        WHEN 4 THEN 'deposit'
        WHEN 5 THEN 'transfer'
        ELSE 'refund'
    END,
    CASE (FLOOR(RANDOM() * 6)::integer)
        WHEN 0 THEN 'card'
        WHEN 1 THEN 'online'
        WHEN 2 THEN 'mobile'
        WHEN 3 THEN 'ach'
        WHEN 4 THEN 'wire'
        ELSE 'check'
    END,
    CASE (FLOOR(RANDOM() * 10)::integer)
        WHEN 0 THEN 'Grocery purchase'
        WHEN 1 THEN 'Gas station payment'
        WHEN 2 THEN 'Restaurant bill'
        WHEN 3 THEN 'Online shopping'
        WHEN 4 THEN 'ATM withdrawal'
        WHEN 5 THEN 'Bill payment'
        WHEN 6 THEN 'Hotel charges'
        WHEN 7 THEN 'Car rental'
        WHEN 8 THEN 'Airline ticket'
        ELSE 'Miscellaneous purchase'
    END,
    '****' || LPAD((FLOOR(RANDOM() * 10000)::integer)::text, 4, '0'),
    CASE (FLOOR(RANDOM() * 10)::integer)
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Los Angeles'
        WHEN 2 THEN 'Chicago'
        WHEN 3 THEN 'Houston'
        WHEN 4 THEN 'Phoenix'
        WHEN 5 THEN 'Philadelphia'
        WHEN 6 THEN 'San Antonio'
        WHEN 7 THEN 'San Diego'
        WHEN 8 THEN 'Dallas'
        ELSE 'Austin'
    END,
    CASE (FLOOR(RANDOM() * 5)::integer)
        WHEN 0 THEN 'NY'
        WHEN 1 THEN 'CA'
        WHEN 2 THEN 'IL'
        WHEN 3 THEN 'TX'
        ELSE 'AZ'
    END,
    RANDOM() < 0.05, -- 5% international transactions
    RANDOM() < 0.02, -- 2% suspicious transactions
    ROUND((RANDOM() * 100)::numeric, 2),
    CASE 
        WHEN RANDOM() < 0.9 THEN 'completed'
        WHEN RANDOM() < 0.95 THEN 'pending'
        WHEN RANDOM() < 0.98 THEN 'failed'
        ELSE 'disputed'
    END
FROM generate_series(1, 200000) AS i;

-- Update some transactions to have higher fraud scores and mark as suspicious
UPDATE transactions 
SET fraud_score = 80 + (RANDOM() * 20), is_suspicious = TRUE
WHERE amount > 5000 AND is_international = TRUE;

UPDATE transactions 
SET fraud_score = 70 + (RANDOM() * 25), is_suspicious = TRUE
WHERE transaction_date > CURRENT_TIMESTAMP - INTERVAL '1 hour' 
  AND account_id IN (
      SELECT account_id 
      FROM transactions 
      WHERE transaction_date > CURRENT_TIMESTAMP - INTERVAL '1 hour'
      GROUP BY account_id 
      HAVING COUNT(*) > 5
  );

-- Insert fraud alerts for suspicious transactions
INSERT INTO fraud_alerts (transaction_id, customer_id, alert_type, alert_description, risk_score, alert_status, created_by)
SELECT 
    t.transaction_id,
    a.customer_id,
    CASE 
        WHEN t.amount > 5000 AND t.is_international THEN 'large_international_transaction'
        WHEN t.fraud_score > 80 THEN 'high_fraud_score'
        WHEN t.is_international THEN 'international_transaction'
        ELSE 'suspicious_pattern'
    END,
    CASE 
        WHEN t.amount > 5000 AND t.is_international THEN 'Large international transaction detected'
        WHEN t.fraud_score > 80 THEN 'Transaction flagged by fraud detection model'
        WHEN t.is_international THEN 'International transaction from domestic account'
        ELSE 'Suspicious transaction pattern detected'
    END,
    t.fraud_score,
    CASE 
        WHEN RANDOM() < 0.6 THEN 'resolved'
        WHEN RANDOM() < 0.8 THEN 'false_positive'
        WHEN RANDOM() < 0.9 THEN 'investigating'
        ELSE 'open'
    END,
    'fraud_detection_system'
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
WHERE t.is_suspicious = TRUE;

-- Generate daily balance history for active accounts
INSERT INTO balance_history (account_id, balance_date, balance_amount)
SELECT 
    a.account_id,
    date_series.balance_date,
    a.balance + (RANDOM() * 1000 - 500) -- Add some variation
FROM accounts a
CROSS JOIN (
    SELECT CURRENT_DATE - i AS balance_date
    FROM generate_series(0, 30) AS i -- Last 30 days
) AS date_series
WHERE a.account_status = 'active'
  AND RANDOM() < 0.1; -- Sample only 10% to keep data manageable

-- =====================================================
-- Create useful indexes for performance
-- =====================================================

CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_risk_score ON customers(risk_score);
CREATE INDEX idx_customers_kyc_status ON customers(kyc_status);
CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX idx_accounts_account_number ON accounts(account_number);
CREATE INDEX idx_accounts_status ON accounts(account_status);
CREATE INDEX idx_merchants_category_code ON merchants(category_code);
CREATE INDEX idx_merchants_risk_level ON merchants(risk_level);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_merchant_id ON transactions(merchant_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_transactions_suspicious ON transactions(is_suspicious);
CREATE INDEX idx_transactions_fraud_score ON transactions(fraud_score);
CREATE INDEX idx_fraud_alerts_customer_id ON fraud_alerts(customer_id);
CREATE INDEX idx_fraud_alerts_status ON fraud_alerts(alert_status);
CREATE INDEX idx_balance_history_account_date ON balance_history(account_id, balance_date);

-- =====================================================
-- Create helpful views for fraud analysis
-- =====================================================

-- High-risk customers view
CREATE VIEW high_risk_customers AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.risk_score,
    c.credit_score,
    COUNT(DISTINCT a.account_id) as account_count,
    COUNT(DISTINCT t.transaction_id) as transaction_count,
    SUM(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) as suspicious_transactions,
    AVG(t.fraud_score) as avg_fraud_score,
    MAX(t.transaction_date) as last_transaction_date
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE c.risk_score > 70 OR c.credit_score < 500
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.risk_score, c.credit_score;

-- Transaction patterns view
CREATE VIEW transaction_patterns AS
SELECT 
    t.account_id,
    DATE_TRUNC('day', t.transaction_date) as transaction_day,
    COUNT(*) as daily_transaction_count,
    SUM(t.amount) as daily_transaction_amount,
    AVG(t.amount) as avg_transaction_amount,
    MAX(t.amount) as max_transaction_amount,
    COUNT(DISTINCT t.merchant_id) as unique_merchants,
    SUM(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) as suspicious_count
FROM transactions t
WHERE t.status = 'completed'
GROUP BY t.account_id, DATE_TRUNC('day', t.transaction_date);

-- Merchant risk analysis view
CREATE VIEW merchant_risk_analysis AS
SELECT 
    m.merchant_id,
    m.merchant_name,
    m.category_description,
    m.risk_level,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_transaction_amount,
    AVG(t.amount) as avg_transaction_amount,
    SUM(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) as suspicious_transactions,
    ROUND(AVG(t.fraud_score), 2) as avg_fraud_score,
    COUNT(DISTINCT fa.alert_id) as fraud_alerts_count
FROM merchants m
LEFT JOIN transactions t ON m.merchant_id = t.merchant_id
LEFT JOIN fraud_alerts fa ON t.transaction_id = fa.transaction_id
GROUP BY m.merchant_id, m.merchant_name, m.category_description, m.risk_level;

-- =====================================================
-- Example Analytics Queries
-- =====================================================

-- Example 1: Daily fraud detection metrics
/*
SELECT 
    DATE_TRUNC('day', transaction_date) as date,
    COUNT(*) as total_transactions,
    SUM(CASE WHEN is_suspicious THEN 1 ELSE 0 END) as suspicious_transactions,
    ROUND(AVG(fraud_score), 2) as avg_fraud_score,
    SUM(amount) as total_amount,
    SUM(CASE WHEN is_suspicious THEN amount ELSE 0 END) as suspicious_amount
FROM transactions
WHERE transaction_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', transaction_date)
ORDER BY date DESC;
*/

-- Example 2: Account velocity analysis (multiple transactions in short time)
/*
SELECT 
    account_id,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    MIN(transaction_date) as first_transaction,
    MAX(transaction_date) as last_transaction,
    EXTRACT(EPOCH FROM (MAX(transaction_date) - MIN(transaction_date)))/3600 as time_span_hours
FROM transactions
WHERE transaction_date >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
  AND status = 'completed'
GROUP BY account_id
HAVING COUNT(*) >= 5
ORDER BY transaction_count DESC, time_span_hours ASC;
*/

-- Example 3: Cross-border transaction analysis
/*
SELECT 
    c.country as customer_country,
    t.location_country as transaction_country,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.fraud_score) as avg_fraud_score,
    SUM(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) as suspicious_count
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.is_international = TRUE
GROUP BY c.country, t.location_country
ORDER BY transaction_count DESC;
*/
