/*
Title: A/B Testing and Experimentation with SQL
Author: Alexander Nykolaiszyn
Created: 2023-08-12
Description: Techniques for designing, analyzing, and drawing conclusions from A/B tests using SQL
*/

-- ==========================================
-- INTRODUCTION TO A/B TESTING WITH SQL
-- ==========================================
-- A/B testing (split testing) is a method to compare two versions of something
-- to determine which performs better. This script demonstrates how to design
-- and analyze A/B tests using SQL.

-- ==========================================
-- 1. SETTING UP TEST DATA STRUCTURE
-- ==========================================

-- Create a table to track experiments
CREATE TABLE experiments (
    experiment_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    owner VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('planned', 'running', 'completed', 'aborted'))
);

-- Create a table to track experiment variants
CREATE TABLE experiment_variants (
    variant_id VARCHAR(50) PRIMARY KEY,
    experiment_id VARCHAR(50) NOT NULL REFERENCES experiments(experiment_id),
    name VARCHAR(50) NOT NULL, -- typically 'control', 'variant_a', 'variant_b', etc.
    description TEXT,
    allocation_percentage DECIMAL(5,2) NOT NULL, -- e.g., 50.00 for 50%
    CONSTRAINT valid_percentage CHECK (allocation_percentage > 0 AND allocation_percentage <= 100)
);

-- Create a table to track user assignments to variants
CREATE TABLE user_variant_assignments (
    user_id VARCHAR(50) NOT NULL,
    experiment_id VARCHAR(50) NOT NULL REFERENCES experiments(experiment_id),
    variant_id VARCHAR(50) NOT NULL REFERENCES experiment_variants(variant_id),
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, experiment_id)
);

-- Create a table to track user interactions and conversions
CREATE TABLE experiment_events (
    event_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    experiment_id VARCHAR(50) NOT NULL REFERENCES experiments(experiment_id),
    event_type VARCHAR(50) NOT NULL, -- e.g., 'page_view', 'click', 'purchase'
    event_timestamp TIMESTAMP NOT NULL,
    event_value DECIMAL(10,2), -- optional value (e.g., purchase amount)
    metadata JSONB -- additional event data
);

-- ==========================================
-- 2. SAMPLE DATA POPULATION
-- ==========================================

-- Insert a sample experiment
INSERT INTO experiments (experiment_id, name, description, start_date, end_date, owner, status)
VALUES (
    'exp-homepage-2023-q3',
    'Homepage Redesign Q3 2023',
    'Testing a new homepage layout to improve conversion rate',
    '2023-07-01 00:00:00',
    '2023-07-31 23:59:59',
    'Alexander Nykolaiszyn',
    'completed'
);

-- Insert experiment variants
INSERT INTO experiment_variants (variant_id, experiment_id, name, description, allocation_percentage)
VALUES
    ('exp-homepage-2023-q3-control', 'exp-homepage-2023-q3', 'control', 'Current homepage design', 50.00),
    ('exp-homepage-2023-q3-variant', 'exp-homepage-2023-q3', 'variant', 'New homepage with larger CTA buttons', 50.00);

-- Insert user assignments (in practice, this would be thousands of users)
INSERT INTO user_variant_assignments (user_id, experiment_id, variant_id, assigned_at)
VALUES
    ('user-001', 'exp-homepage-2023-q3', 'exp-homepage-2023-q3-control', '2023-07-01 10:15:23'),
    ('user-002', 'exp-homepage-2023-q3', 'exp-homepage-2023-q3-variant', '2023-07-01 10:18:45'),
    ('user-003', 'exp-homepage-2023-q3', 'exp-homepage-2023-q3-control', '2023-07-01 10:23:12'),
    ('user-004', 'exp-homepage-2023-q3', 'exp-homepage-2023-q3-variant', '2023-07-01 10:28:39'),
    ('user-005', 'exp-homepage-2023-q3', 'exp-homepage-2023-q3-control', '2023-07-01 10:31:56');

-- Insert sample events
INSERT INTO experiment_events (event_id, user_id, experiment_id, event_type, event_timestamp, event_value, metadata)
VALUES
    ('event-001', 'user-001', 'exp-homepage-2023-q3', 'page_view', '2023-07-01 10:15:30', NULL, '{"page": "homepage", "device": "desktop", "browser": "chrome"}'),
    ('event-002', 'user-001', 'exp-homepage-2023-q3', 'click', '2023-07-01 10:16:15', NULL, '{"element": "cta_button", "position": "hero"}'),
    ('event-003', 'user-001', 'exp-homepage-2023-q3', 'purchase', '2023-07-01 10:23:45', 49.99, '{"product_id": "prod-123", "quantity": 1}'),
    ('event-004', 'user-002', 'exp-homepage-2023-q3', 'page_view', '2023-07-01 10:18:50', NULL, '{"page": "homepage", "device": "mobile", "browser": "safari"}'),
    ('event-005', 'user-002', 'exp-homepage-2023-q3', 'click', '2023-07-01 10:19:20', NULL, '{"element": "cta_button", "position": "hero"}'),
    ('event-006', 'user-002', 'exp-homepage-2023-q3', 'purchase', '2023-07-01 10:25:10', 79.99, '{"product_id": "prod-456", "quantity": 2}'),
    ('event-007', 'user-003', 'exp-homepage-2023-q3', 'page_view', '2023-07-01 10:23:20', NULL, '{"page": "homepage", "device": "desktop", "browser": "firefox"}'),
    ('event-008', 'user-004', 'exp-homepage-2023-q3', 'page_view', '2023-07-01 10:28:45', NULL, '{"page": "homepage", "device": "tablet", "browser": "chrome"}'),
    ('event-009', 'user-004', 'exp-homepage-2023-q3', 'click', '2023-07-01 10:29:30', NULL, '{"element": "cta_button", "position": "hero"}'),
    ('event-010', 'user-005', 'exp-homepage-2023-q3', 'page_view', '2023-07-01 10:32:00', NULL, '{"page": "homepage", "device": "desktop", "browser": "edge"}');

-- ==========================================
-- 3. RANDOM ASSIGNMENT OF USERS TO VARIANTS
-- ==========================================

-- Function to assign users to variants with specified probabilities
-- PostgreSQL Example
CREATE OR REPLACE FUNCTION assign_user_to_experiment(
    p_user_id VARCHAR(50),
    p_experiment_id VARCHAR(50)
)
RETURNS VARCHAR(50)
AS $$
DECLARE
    v_random DECIMAL;
    v_cumulative DECIMAL := 0;
    v_variant_id VARCHAR(50);
    v_variant_record RECORD;
BEGIN
    -- Generate a random number between 0 and 1
    v_random := RANDOM();
    
    -- Loop through variants and assign based on allocation percentage
    FOR v_variant_record IN (
        SELECT 
            variant_id, 
            allocation_percentage / 100 AS probability
        FROM 
            experiment_variants
        WHERE 
            experiment_id = p_experiment_id
        ORDER BY 
            variant_id
    ) LOOP
        v_cumulative := v_cumulative + v_variant_record.probability;
        
        IF v_random <= v_cumulative THEN
            v_variant_id := v_variant_record.variant_id;
            EXIT;
        END IF;
    END LOOP;
    
    -- Insert the assignment
    INSERT INTO user_variant_assignments (user_id, experiment_id, variant_id)
    VALUES (p_user_id, p_experiment_id, v_variant_id);
    
    RETURN v_variant_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 4. BASIC A/B TEST ANALYSIS
-- ==========================================

-- Counting users in each variant
SELECT
    ev.name AS variant_name,
    COUNT(DISTINCT uva.user_id) AS user_count
FROM
    user_variant_assignments uva
JOIN
    experiment_variants ev ON uva.variant_id = ev.variant_id
WHERE
    uva.experiment_id = 'exp-homepage-2023-q3'
GROUP BY
    ev.name;

-- Conversion rate analysis
WITH user_actions AS (
    SELECT
        uva.user_id,
        ev.name AS variant,
        MAX(CASE WHEN ee.event_type = 'page_view' THEN 1 ELSE 0 END) AS viewed_page,
        MAX(CASE WHEN ee.event_type = 'click' THEN 1 ELSE 0 END) AS clicked,
        MAX(CASE WHEN ee.event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased,
        SUM(CASE WHEN ee.event_type = 'purchase' THEN ee.event_value ELSE 0 END) AS total_purchase_value
    FROM
        user_variant_assignments uva
    JOIN
        experiment_variants ev ON uva.variant_id = ev.variant_id
    LEFT JOIN
        experiment_events ee ON uva.user_id = ee.user_id AND uva.experiment_id = ee.experiment_id
    WHERE
        uva.experiment_id = 'exp-homepage-2023-q3'
    GROUP BY
        uva.user_id, ev.name
)
SELECT
    variant,
    COUNT(*) AS total_users,
    SUM(viewed_page) AS users_viewed_page,
    SUM(clicked) AS users_clicked,
    SUM(purchased) AS users_purchased,
    SUM(clicked)::FLOAT / NULLIF(SUM(viewed_page), 0) AS click_rate,
    SUM(purchased)::FLOAT / NULLIF(SUM(viewed_page), 0) AS conversion_rate,
    SUM(total_purchase_value) AS total_revenue,
    SUM(total_purchase_value) / NULLIF(SUM(purchased), 0) AS average_order_value
FROM
    user_actions
GROUP BY
    variant;

-- ==========================================
-- 5. STATISTICAL SIGNIFICANCE TESTING
-- ==========================================

-- Chi-Square Test for Conversion Rate (PostgreSQL)
WITH variant_counts AS (
    SELECT
        ev.name AS variant,
        COUNT(DISTINCT uva.user_id) AS total_users,
        COUNT(DISTINCT CASE WHEN ee.event_type = 'purchase' THEN uva.user_id END) AS converted_users
    FROM
        user_variant_assignments uva
    JOIN
        experiment_variants ev ON uva.variant_id = ev.variant_id
    LEFT JOIN
        experiment_events ee ON uva.user_id = ee.user_id 
                            AND uva.experiment_id = ee.experiment_id
                            AND ee.event_type = 'purchase'
    WHERE
        uva.experiment_id = 'exp-homepage-2023-q3'
    GROUP BY
        ev.name
),
conversion_data AS (
    SELECT
        variant,
        converted_users,
        total_users - converted_users AS non_converted_users,
        total_users
    FROM
        variant_counts
)
SELECT
    c1.variant AS control_variant,
    c2.variant AS test_variant,
    c1.converted_users AS control_conversions,
    c1.total_users AS control_total,
    c1.converted_users::FLOAT / c1.total_users AS control_conversion_rate,
    c2.converted_users AS test_conversions,
    c2.total_users AS test_total,
    c2.converted_users::FLOAT / c2.total_users AS test_conversion_rate,
    (c2.converted_users::FLOAT / c2.total_users) - (c1.converted_users::FLOAT / c1.total_users) AS absolute_difference,
    ((c2.converted_users::FLOAT / c2.total_users) / (c1.converted_users::FLOAT / c1.total_users) - 1) * 100 AS relative_difference_pct,
    -- Chi-square statistic calculation
    (POWER(c1.converted_users * c2.total_users - c2.converted_users * c1.total_users, 2) * (c1.total_users + c2.total_users)) / 
    (c1.total_users * c2.total_users * (c1.converted_users + c2.converted_users) * (c1.non_converted_users + c2.non_converted_users)) AS chi_square_statistic,
    -- P-value would be calculated from chi-square distribution with 1 degree of freedom
    -- For PostgreSQL, you might need an extension or custom function for this
    -- Alternatively, compare chi_square_statistic to critical values:
    -- 3.84 for p=0.05, 6.63 for p=0.01, 10.83 for p=0.001
    CASE 
        WHEN (POWER(c1.converted_users * c2.total_users - c2.converted_users * c1.total_users, 2) * (c1.total_users + c2.total_users)) / 
             (c1.total_users * c2.total_users * (c1.converted_users + c2.converted_users) * (c1.non_converted_users + c2.non_converted_users)) > 3.84 
        THEN 'Statistically Significant (p < 0.05)'
        ELSE 'Not Statistically Significant (p >= 0.05)'
    END AS significance_result
FROM
    conversion_data c1
CROSS JOIN
    conversion_data c2
WHERE
    c1.variant = 'control'
    AND c2.variant = 'variant';

-- ==========================================
-- 6. SEGMENTATION ANALYSIS
-- ==========================================

-- Analyzing results by device type
WITH user_segments AS (
    SELECT
        uva.user_id,
        ev.name AS variant,
        ee.metadata->>'device' AS device_type,
        MAX(CASE WHEN ee.event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM
        user_variant_assignments uva
    JOIN
        experiment_variants ev ON uva.variant_id = ev.variant_id
    JOIN
        experiment_events ee ON uva.user_id = ee.user_id AND uva.experiment_id = ee.experiment_id
    WHERE
        uva.experiment_id = 'exp-homepage-2023-q3'
        AND ee.metadata->>'device' IS NOT NULL
    GROUP BY
        uva.user_id, ev.name, ee.metadata->>'device'
)
SELECT
    variant,
    device_type,
    COUNT(*) AS total_users,
    SUM(purchased) AS converted_users,
    SUM(purchased)::FLOAT / COUNT(*) AS conversion_rate
FROM
    user_segments
GROUP BY
    variant, device_type
ORDER BY
    device_type, variant;

-- ==========================================
-- 7. TIME-BASED ANALYSIS
-- ==========================================

-- Checking for novelty or primacy effects
WITH daily_metrics AS (
    SELECT
        DATE_TRUNC('day', ee.event_timestamp) AS day,
        ev.name AS variant,
        COUNT(DISTINCT uva.user_id) AS users,
        COUNT(DISTINCT CASE WHEN ee.event_type = 'purchase' THEN uva.user_id END) AS purchasers
    FROM
        user_variant_assignments uva
    JOIN
        experiment_variants ev ON uva.variant_id = ev.variant_id
    JOIN
        experiment_events ee ON uva.user_id = ee.user_id AND uva.experiment_id = ee.experiment_id
    WHERE
        uva.experiment_id = 'exp-homepage-2023-q3'
    GROUP BY
        DATE_TRUNC('day', ee.event_timestamp), ev.name
)
SELECT
    day,
    variant,
    users,
    purchasers,
    purchasers::FLOAT / NULLIF(users, 0) AS conversion_rate
FROM
    daily_metrics
ORDER BY
    day, variant;

-- ==========================================
-- 8. SAMPLE SIZE AND POWER CALCULATION
-- ==========================================

-- Function to calculate required sample size
-- PostgreSQL Example
CREATE OR REPLACE FUNCTION calculate_sample_size(
    baseline_conversion_rate DECIMAL,
    minimum_detectable_effect DECIMAL,
    significance_level DECIMAL DEFAULT 0.05,
    statistical_power DECIMAL DEFAULT 0.8
)
RETURNS INTEGER
AS $$
DECLARE
    z_alpha DECIMAL := 1.96; -- Z-score for 95% confidence (alpha = 0.05)
    z_beta DECIMAL := 0.84;  -- Z-score for 80% power (beta = 0.2)
    p1 DECIMAL := baseline_conversion_rate;
    p2 DECIMAL := baseline_conversion_rate * (1 + minimum_detectable_effect);
    p_pooled DECIMAL := (p1 + p2) / 2;
    sample_size DECIMAL;
BEGIN
    -- If significance_level != 0.05, recalculate z_alpha
    IF significance_level != 0.05 THEN
        -- This is an approximation; in a real implementation, you'd use a proper quantile function
        IF significance_level = 0.01 THEN
            z_alpha := 2.58;
        ELSIF significance_level = 0.1 THEN
            z_alpha := 1.64;
        END IF;
    END IF;
    
    -- If statistical_power != 0.8, recalculate z_beta
    IF statistical_power != 0.8 THEN
        -- This is an approximation; in a real implementation, you'd use a proper quantile function
        IF statistical_power = 0.9 THEN
            z_beta := 1.28;
        ELSIF statistical_power = 0.7 THEN
            z_beta := 0.52;
        END IF;
    END IF;
    
    -- Calculate sample size per variant
    sample_size := (POWER(z_alpha + z_beta, 2) * p_pooled * (1 - p_pooled)) / POWER(p2 - p1, 2);
    
    -- Return the ceiling (round up) of the sample size
    RETURN CEILING(sample_size);
END;
$$ LANGUAGE plpgsql;

-- Example usage
SELECT calculate_sample_size(0.10, 0.05) AS required_sample_size_per_variant;

-- ==========================================
-- 9. A/B TEST DOCUMENTATION AND REPORTING
-- ==========================================

-- Create a summary view for experiments
CREATE OR REPLACE VIEW experiment_summary AS
WITH variant_metrics AS (
    SELECT
        e.experiment_id,
        e.name AS experiment_name,
        e.description AS experiment_description,
        e.start_date,
        e.end_date,
        e.status,
        ev.name AS variant_name,
        COUNT(DISTINCT uva.user_id) AS total_users,
        COUNT(DISTINCT CASE WHEN ee.event_type = 'page_view' THEN uva.user_id END) AS users_viewed,
        COUNT(DISTINCT CASE WHEN ee.event_type = 'click' THEN uva.user_id END) AS users_clicked,
        COUNT(DISTINCT CASE WHEN ee.event_type = 'purchase' THEN uva.user_id END) AS users_purchased,
        SUM(CASE WHEN ee.event_type = 'purchase' THEN ee.event_value ELSE 0 END) AS total_revenue
    FROM
        experiments e
    JOIN
        experiment_variants ev ON e.experiment_id = ev.experiment_id
    LEFT JOIN
        user_variant_assignments uva ON ev.variant_id = uva.variant_id
    LEFT JOIN
        experiment_events ee ON uva.user_id = ee.user_id AND uva.experiment_id = ee.experiment_id
    GROUP BY
        e.experiment_id, e.name, e.description, e.start_date, e.end_date, e.status, ev.name
)
SELECT
    experiment_id,
    experiment_name,
    experiment_description,
    start_date,
    end_date,
    status,
    variant_name,
    total_users,
    users_viewed,
    users_clicked,
    users_purchased,
    total_revenue,
    users_clicked::FLOAT / NULLIF(users_viewed, 0) AS click_through_rate,
    users_purchased::FLOAT / NULLIF(users_viewed, 0) AS conversion_rate,
    total_revenue::FLOAT / NULLIF(users_purchased, 0) AS average_order_value
FROM
    variant_metrics;

-- ==========================================
-- 10. BEST PRACTICES FOR A/B TESTING
-- ==========================================

/*
A/B Testing Best Practices:

1. Define Clear Metrics
   - Primary metric (e.g., conversion rate)
   - Secondary metrics (e.g., average order value, user engagement)
   - Guard metrics to ensure you're not sacrificing long-term value

2. Experimental Design
   - Calculate required sample size in advance
   - Run test long enough to account for cyclical patterns (e.g., day of week)
   - Consider segmentation needs in advance
   - Control for external factors and seasonality

3. Execution
   - Ensure proper randomization
   - Validate that variant distribution matches expected allocation
   - Monitor for any technical issues
   - Avoid making changes mid-experiment

4. Analysis
   - Use appropriate statistical tests
   - Check for novelty effects
   - Segment results by user characteristics
   - Look for interactions with other variables

5. Decision Making
   - Document methodology and results
   - Consider practical significance, not just statistical significance
   - Plan for how to roll out winning variants
   - Share learnings across the organization
*/

-- ==========================================
-- 11. COMMON A/B TESTING PITFALLS
-- ==========================================

/*
Common A/B Testing Pitfalls:

1. Sample Ratio Mismatch
   - Check that your variant assignment is working correctly
*/
SELECT
    ev.name AS variant_name,
    COUNT(DISTINCT uva.user_id) AS assigned_users,
    ev.allocation_percentage AS expected_percentage,
    (COUNT(DISTINCT uva.user_id) * 100.0 / SUM(COUNT(DISTINCT uva.user_id)) OVER ()) AS actual_percentage,
    ABS((COUNT(DISTINCT uva.user_id) * 100.0 / SUM(COUNT(DISTINCT uva.user_id)) OVER ()) - ev.allocation_percentage) AS percentage_difference
FROM
    user_variant_assignments uva
JOIN
    experiment_variants ev ON uva.variant_id = ev.variant_id
WHERE
    uva.experiment_id = 'exp-homepage-2023-q3'
GROUP BY
    ev.name, ev.allocation_percentage;

/*
2. Peeking at Results Too Early
   - Avoid checking results before reaching planned sample size
   - Consider using sequential testing if early stopping is desired

3. Multiple Testing Problem
   - Be cautious when looking at many metrics or segments
   - Apply corrections like Bonferroni or False Discovery Rate

4. Simpson's Paradox
   - Overall results can be misleading when segments behave differently
   - Always check key segments separately
*/

-- Example of Simpson's Paradox detection
WITH segment_analysis AS (
    SELECT
        ev.name AS variant,
        ee.metadata->>'device' AS device_type,
        COUNT(DISTINCT uva.user_id) AS users,
        COUNT(DISTINCT CASE WHEN ee2.event_type = 'purchase' THEN uva.user_id END) AS conversions,
        COUNT(DISTINCT CASE WHEN ee2.event_type = 'purchase' THEN uva.user_id END)::FLOAT / 
            NULLIF(COUNT(DISTINCT uva.user_id), 0) AS conversion_rate
    FROM
        user_variant_assignments uva
    JOIN
        experiment_variants ev ON uva.variant_id = ev.variant_id
    JOIN
        experiment_events ee ON uva.user_id = ee.user_id AND uva.experiment_id = ee.experiment_id
    LEFT JOIN
        experiment_events ee2 ON uva.user_id = ee2.user_id AND uva.experiment_id = ee2.experiment_id AND ee2.event_type = 'purchase'
    WHERE
        uva.experiment_id = 'exp-homepage-2023-q3'
        AND ee.metadata->>'device' IS NOT NULL
    GROUP BY
        ev.name, ee.metadata->>'device'
)
SELECT
    s1.device_type,
    s1.variant AS variant_a,
    s1.conversion_rate AS rate_a,
    s2.variant AS variant_b,
    s2.conversion_rate AS rate_b,
    s2.conversion_rate - s1.conversion_rate AS rate_diff,
    CASE 
        WHEN s1.conversion_rate < s2.conversion_rate THEN 'B wins in segment'
        WHEN s1.conversion_rate > s2.conversion_rate THEN 'A wins in segment'
        ELSE 'Tie'
    END AS segment_winner
FROM
    segment_analysis s1
JOIN
    segment_analysis s2 ON s1.device_type = s2.device_type AND s1.variant < s2.variant
ORDER BY
    s1.device_type;
