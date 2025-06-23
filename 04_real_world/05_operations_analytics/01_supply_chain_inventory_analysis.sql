-- ============================================================================
-- SUPPLY CHAIN INVENTORY OPTIMIZATION ANALYSIS
-- Operations Analytics Scenario for SQL Analysts
-- ============================================================================

/*
📊 BUSINESS CONTEXT:
The Operations Director needs to optimize inventory levels, improve supplier 
performance, and reduce carrying costs while maintaining service levels. 
This analysis will support quarterly operations review and vendor negotiations.

🎯 STAKEHOLDER: Operations Director, Supply Chain Manager, Procurement Team
📅 FREQUENCY: Monthly inventory review, quarterly supplier evaluation
🎯 DECISION: Inventory optimization, supplier negotiations, safety stock levels

🎯 BUSINESS REQUIREMENTS:
1. Inventory turnover analysis and optimization opportunities
2. Supplier performance evaluation and risk assessment
3. Demand forecasting accuracy and safety stock optimization
4. Stockout analysis and service level impact
5. Cost optimization recommendations for carrying and ordering costs

📈 SUCCESS METRICS:
- Improve inventory turnover by 15% while maintaining 95% service level
- Reduce carrying costs by $500K annually through optimization
- Achieve 95% supplier on-time delivery performance
- Minimize stockouts while optimizing safety stock levels
*/

-- ============================================================================
-- DATA STRUCTURE OVERVIEW
-- ============================================================================

/*
Available Tables:
- inventory: Current and historical inventory levels by product and location
- sales_demand: Customer demand and sales transactions
- purchase_orders: Supplier orders, delivery dates, and performance
- suppliers: Supplier information, contracts, and performance ratings
- products: Product catalog, categories, costs, and lead times
- warehouses: Location information and capacity constraints
*/

-- ============================================================================
-- SECTION 1: INVENTORY TURNOVER AND OPTIMIZATION ANALYSIS
-- ============================================================================

-- 1.1 Inventory Turnover Analysis by Product Category
SELECT 
    p.product_category,
    p.product_subcategory,
    COUNT(DISTINCT p.product_id) as product_count,
    
    -- Inventory metrics
    AVG(i.current_stock_level) as avg_stock_level,
    SUM(i.current_stock_value) as total_inventory_value,
    
    -- Sales and demand metrics
    SUM(sd.units_sold) as total_units_sold,
    SUM(sd.sales_revenue) as total_sales_revenue,
    AVG(sd.daily_demand) as avg_daily_demand,
    
    -- Turnover calculations
    ROUND(
        SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0), 2
    ) as inventory_turnover_ratio,
    
    ROUND(
        365 / NULLIF(SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0), 0), 1
    ) as days_inventory_outstanding,
    
    -- Cost metrics
    SUM(i.carrying_cost) as total_carrying_cost,
    ROUND(
        SUM(i.carrying_cost) * 100.0 / NULLIF(SUM(i.current_stock_value), 0), 2
    ) as carrying_cost_percentage,
    
    -- Performance indicators
    CASE 
        WHEN SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) >= 12 
        THEN '🟢 Excellent Turnover'
        WHEN SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) >= 8 
        THEN '✅ Good Turnover'
        WHEN SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) >= 4 
        THEN '🟡 Average Turnover'
        WHEN SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) >= 2 
        THEN '🟠 Poor Turnover'
        ELSE '🔴 Very Poor Turnover'
    END as turnover_performance,
    
    -- Optimization opportunities
    CASE 
        WHEN SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) < 4 
        THEN 'HIGH: Reduce inventory levels'
        WHEN SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) < 6 
        THEN 'MEDIUM: Optimize stock levels'
        WHEN SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) > 15 
        THEN 'CAUTION: Potential stockout risk'
        ELSE 'MAINTAIN: Current levels appropriate'
    END as optimization_recommendation

FROM products p
JOIN inventory i ON p.product_id = i.product_id
JOIN sales_demand sd ON p.product_id = sd.product_id

WHERE i.as_of_date >= CURRENT_DATE - INTERVAL '90 days'
  AND sd.transaction_date >= CURRENT_DATE - INTERVAL '365 days'
GROUP BY p.product_category, p.product_subcategory
ORDER BY SUM(sd.units_sold) / NULLIF(AVG(i.current_stock_level), 0) ASC;

-- 1.2 ABC Analysis for Inventory Classification
WITH product_revenue_analysis AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        SUM(sd.sales_revenue) as annual_revenue,
        AVG(i.current_stock_value) as avg_inventory_value,
        SUM(i.carrying_cost) as annual_carrying_cost,
        
        -- Revenue ranking
        ROW_NUMBER() OVER (ORDER BY SUM(sd.sales_revenue) DESC) as revenue_rank,
        
        -- Calculate cumulative revenue percentage
        SUM(SUM(sd.sales_revenue)) OVER (ORDER BY SUM(sd.sales_revenue) DESC) as cumulative_revenue,
        SUM(SUM(sd.sales_revenue)) OVER () as total_revenue

    FROM products p
    JOIN sales_demand sd ON p.product_id = sd.product_id
    JOIN inventory i ON p.product_id = i.product_id
    WHERE sd.transaction_date >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY p.product_id, p.product_name, p.product_category
),
abc_classification AS (
    SELECT 
        *,
        ROUND(cumulative_revenue * 100.0 / total_revenue, 2) as cumulative_revenue_pct,
        
        -- ABC Classification
        CASE 
            WHEN cumulative_revenue * 100.0 / total_revenue <= 80 THEN 'A'
            WHEN cumulative_revenue * 100.0 / total_revenue <= 95 THEN 'B'
            ELSE 'C'
        END as abc_class

    FROM product_revenue_analysis
)
SELECT 
    abc_class,
    COUNT(*) as product_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as product_percentage,
    
    SUM(annual_revenue) as total_revenue,
    ROUND(SUM(annual_revenue) * 100.0 / SUM(SUM(annual_revenue)) OVER (), 1) as revenue_percentage,
    
    SUM(avg_inventory_value) as total_inventory_value,
    ROUND(SUM(avg_inventory_value) * 100.0 / SUM(SUM(avg_inventory_value)) OVER (), 1) as inventory_percentage,
    
    SUM(annual_carrying_cost) as total_carrying_cost,
    ROUND(AVG(annual_carrying_cost), 0) as avg_carrying_cost_per_product,
    
    -- Strategic recommendations by class
    CASE 
        WHEN abc_class = 'A' THEN 'HIGH PRIORITY: Tight inventory control, frequent reviews'
        WHEN abc_class = 'B' THEN 'MEDIUM PRIORITY: Regular monitoring, standard controls'
        ELSE 'LOW PRIORITY: Basic controls, less frequent reviews'
    END as management_strategy,
    
    -- Recommended service levels
    CASE 
        WHEN abc_class = 'A' THEN '98-99%'
        WHEN abc_class = 'B' THEN '95-98%'
        ELSE '90-95%'
    END as recommended_service_level

FROM abc_classification
GROUP BY abc_class
ORDER BY abc_class;

-- ============================================================================
-- SECTION 2: SUPPLIER PERFORMANCE ANALYSIS
-- ============================================================================

-- 2.1 Supplier Performance Scorecard
SELECT 
    s.supplier_name,
    s.supplier_type,
    s.supplier_region,
    
    -- Order performance metrics
    COUNT(po.order_id) as total_orders,
    SUM(po.order_value) as total_order_value,
    AVG(po.order_value) as avg_order_value,
    
    -- Delivery performance
    SUM(CASE WHEN po.actual_delivery_date <= po.promised_delivery_date THEN 1 ELSE 0 END) as on_time_deliveries,
    ROUND(
        SUM(CASE WHEN po.actual_delivery_date <= po.promised_delivery_date THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(po.order_id), 2
    ) as on_time_delivery_rate,
    
    AVG(po.actual_delivery_date - po.promised_delivery_date) as avg_delivery_delay_days,
    
    -- Quality metrics
    SUM(po.quantity_received) as total_quantity_received,
    SUM(po.quantity_accepted) as total_quantity_accepted,
    ROUND(
        SUM(po.quantity_accepted) * 100.0 / NULLIF(SUM(po.quantity_received), 0), 2
    ) as quality_acceptance_rate,
    
    -- Cost performance
    AVG(po.unit_cost) as avg_unit_cost,
    SUM(po.total_cost_variance) as total_cost_variance,
    ROUND(
        SUM(po.total_cost_variance) * 100.0 / NULLIF(SUM(po.order_value), 0), 2
    ) as cost_variance_percentage,
    
    -- Lead time analysis
    AVG(po.actual_lead_time_days) as avg_lead_time,
    STDDEV(po.actual_lead_time_days) as lead_time_variability,
    
    -- Overall supplier score (weighted)
    ROUND(
        (SUM(CASE WHEN po.actual_delivery_date <= po.promised_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(po.order_id)) * 0.4 +
        (SUM(po.quantity_accepted) * 100.0 / NULLIF(SUM(po.quantity_received), 0)) * 0.3 +
        (100 - ABS(SUM(po.total_cost_variance) * 100.0 / NULLIF(SUM(po.order_value), 0))) * 0.3, 2
    ) as overall_supplier_score,
    
    -- Performance rating
    CASE 
        WHEN (SUM(CASE WHEN po.actual_delivery_date <= po.promised_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(po.order_id)) >= 95 
             AND (SUM(po.quantity_accepted) * 100.0 / NULLIF(SUM(po.quantity_received), 0)) >= 98
        THEN '🌟 Preferred Supplier'
        WHEN (SUM(CASE WHEN po.actual_delivery_date <= po.promised_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(po.order_id)) >= 90 
             AND (SUM(po.quantity_accepted) * 100.0 / NULLIF(SUM(po.quantity_received), 0)) >= 95
        THEN '✅ Good Supplier'
        WHEN (SUM(CASE WHEN po.actual_delivery_date <= po.promised_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(po.order_id)) >= 80 
             AND (SUM(po.quantity_accepted) * 100.0 / NULLIF(SUM(po.quantity_received), 0)) >= 90
        THEN '🟡 Average Supplier'
        ELSE '🔴 Underperforming Supplier'
    END as supplier_rating

FROM suppliers s
JOIN purchase_orders po ON s.supplier_id = po.supplier_id

WHERE po.order_date >= CURRENT_DATE - INTERVAL '12 months'
  AND po.order_status = 'Completed'
GROUP BY s.supplier_name, s.supplier_type, s.supplier_region
ORDER BY overall_supplier_score DESC;

-- ============================================================================
-- SECTION 3: DEMAND FORECASTING AND SAFETY STOCK OPTIMIZATION
-- ============================================================================

-- 3.1 Demand Pattern Analysis and Forecast Accuracy
WITH demand_analysis AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.lead_time_days,
        
        -- Historical demand statistics
        AVG(sd.daily_demand) as avg_daily_demand,
        STDDEV(sd.daily_demand) as demand_std_dev,
        MIN(sd.daily_demand) as min_daily_demand,
        MAX(sd.daily_demand) as max_daily_demand,
        
        -- Demand variability
        ROUND(STDDEV(sd.daily_demand) / NULLIF(AVG(sd.daily_demand), 0), 3) as coefficient_of_variation,
        
        -- Seasonal analysis
        AVG(CASE WHEN EXTRACT(QUARTER FROM sd.transaction_date) = 1 THEN sd.daily_demand END) as q1_avg_demand,
        AVG(CASE WHEN EXTRACT(QUARTER FROM sd.transaction_date) = 2 THEN sd.daily_demand END) as q2_avg_demand,
        AVG(CASE WHEN EXTRACT(QUARTER FROM sd.transaction_date) = 3 THEN sd.daily_demand END) as q3_avg_demand,
        AVG(CASE WHEN EXTRACT(QUARTER FROM sd.transaction_date) = 4 THEN sd.daily_demand END) as q4_avg_demand,
        
        -- Current inventory levels
        i.current_stock_level,
        i.safety_stock_level,
        i.reorder_point

    FROM products p
    JOIN sales_demand sd ON p.product_id = sd.product_id
    JOIN inventory i ON p.product_id = i.product_id
    WHERE sd.transaction_date >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY p.product_id, p.product_name, p.lead_time_days, 
             i.current_stock_level, i.safety_stock_level, i.reorder_point
),
safety_stock_recommendations AS (
    SELECT 
        *,
        -- Calculate optimal safety stock (assumes 95% service level, Z = 1.65)
        ROUND(1.65 * demand_std_dev * SQRT(lead_time_days), 0) as recommended_safety_stock,
        
        -- Calculate optimal reorder point
        ROUND((avg_daily_demand * lead_time_days) + (1.65 * demand_std_dev * SQRT(lead_time_days)), 0) as recommended_reorder_point,
        
        -- Seasonality indicator
        CASE 
            WHEN GREATEST(q1_avg_demand, q2_avg_demand, q3_avg_demand, q4_avg_demand) / 
                 NULLIF(LEAST(q1_avg_demand, q2_avg_demand, q3_avg_demand, q4_avg_demand), 0) > 2 
            THEN 'High Seasonality'
            WHEN GREATEST(q1_avg_demand, q2_avg_demand, q3_avg_demand, q4_avg_demand) / 
                 NULLIF(LEAST(q1_avg_demand, q2_avg_demand, q3_avg_demand, q4_avg_demand), 0) > 1.5 
            THEN 'Moderate Seasonality'
            ELSE 'Low Seasonality'
        END as seasonality_pattern,
        
        -- Demand predictability
        CASE 
            WHEN coefficient_of_variation <= 0.3 THEN 'Predictable'
            WHEN coefficient_of_variation <= 0.7 THEN 'Moderately Variable'
            ELSE 'Highly Variable'
        END as demand_predictability

    FROM demand_analysis
)
SELECT 
    product_name,
    avg_daily_demand,
    coefficient_of_variation,
    seasonality_pattern,
    demand_predictability,
    
    -- Current vs recommended levels
    current_stock_level,
    safety_stock_level as current_safety_stock,
    recommended_safety_stock,
    recommended_safety_stock - safety_stock_level as safety_stock_adjustment,
    
    reorder_point as current_reorder_point,
    recommended_reorder_point,
    recommended_reorder_point - reorder_point as reorder_point_adjustment,
    
    -- Optimization potential
    CASE 
        WHEN ABS(recommended_safety_stock - safety_stock_level) > safety_stock_level * 0.2 
        THEN 'HIGH: Significant optimization opportunity'
        WHEN ABS(recommended_safety_stock - safety_stock_level) > safety_stock_level * 0.1 
        THEN 'MEDIUM: Moderate optimization potential'
        ELSE 'LOW: Current levels appropriate'
    END as optimization_priority,
    
    -- Strategic recommendations
    CASE 
        WHEN demand_predictability = 'Highly Variable' AND seasonality_pattern = 'High Seasonality'
        THEN 'Complex: Requires dynamic safety stock and seasonal planning'
        WHEN demand_predictability = 'Predictable' AND seasonality_pattern = 'Low Seasonality'
        THEN 'Simple: Standard reorder point model appropriate'
        WHEN coefficient_of_variation > 1.0
        THEN 'Consider alternative supply strategy or demand management'
        ELSE 'Standard inventory management practices'
    END as management_recommendation

FROM safety_stock_recommendations
ORDER BY ABS(recommended_safety_stock - safety_stock_level) DESC;

/*
🎯 KEY BUSINESS INSIGHTS:

1. INVENTORY OPTIMIZATION:
   - ABC analysis identifies high-value products requiring focused management
   - Turnover analysis reveals slow-moving inventory and optimization opportunities
   - Carrying cost analysis quantifies the financial impact of excess inventory

2. SUPPLIER PERFORMANCE:
   - Comprehensive scorecard enables data-driven supplier selection and negotiation
   - On-time delivery and quality metrics support supplier relationship management
   - Cost variance tracking identifies opportunities for cost reduction

3. DEMAND FORECASTING:
   - Statistical analysis of demand patterns improves forecasting accuracy
   - Safety stock optimization balances service levels with carrying costs
   - Seasonality and variability analysis enables dynamic inventory strategies

4. OPERATIONAL EFFICIENCY:
   - Inventory turnover improvements directly impact cash flow and profitability
   - Supplier optimization reduces procurement costs and operational risks
   - Demand-driven inventory management minimizes stockouts and excess inventory

💼 BUSINESS ACTIONS:
- Implement ABC-based inventory management strategies
- Negotiate supplier performance improvements and cost reductions
- Optimize safety stock levels based on statistical analysis
- Develop seasonal inventory planning processes

📊 SUCCESS METRICS TO MONITOR:
- Inventory turnover ratio improvement
- Supplier on-time delivery performance
- Safety stock optimization and service level achievement
- Total inventory carrying cost reduction
*/
