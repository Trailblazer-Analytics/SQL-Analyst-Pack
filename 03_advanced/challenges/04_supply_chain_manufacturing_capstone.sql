-- =====================================================
-- 04. Supply Chain & Manufacturing Analytics Capstone
-- =====================================================
-- 
-- EXPERT-LEVEL CHALLENGE: End-to-end supply chain
-- optimization and manufacturing analytics platform for
-- global operations, predictive maintenance, and demand
-- forecasting.
-- 
-- Business Context:
-- As Lead Analytics Manager at GlobalMFG Corporation,
-- you're developing an integrated supply chain intelligence
-- system that optimizes inventory, predicts equipment
-- failures, forecasts demand, and ensures supply chain
-- resilience across 50+ facilities worldwide.
-- 
-- Success Criteria:
-- • Inventory cost reduction of 20%+ ($5M+ annually)
-- • Equipment downtime reduction of 30%+
-- • Demand forecast accuracy of 90%+
-- • Supply chain risk score improvement to <15%
-- • On-time delivery improvement to 98%+
-- 
-- Technical Requirements:
-- • Advanced time-series analysis
-- • Multivariate forecasting models
-- • Network optimization algorithms
-- • Risk assessment frameworks
-- • Real-time anomaly detection
-- =====================================================

-- =====================================================
-- Challenge 1: Demand Forecasting & Planning
-- =====================================================

-- Build sophisticated demand forecasting models incorporating
-- seasonality, trends, external factors, and market dynamics

WITH historical_demand AS (
    SELECT 
        product_id,
        facility_id,
        region,
        DATE_TRUNC('week', order_date) as week_start,
        SUM(quantity_ordered) as weekly_demand,
        SUM(revenue) as weekly_revenue,
        AVG(unit_price) as avg_unit_price,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM sales.orders
    WHERE order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 104 WEEK) -- 2 years
    GROUP BY 1, 2, 3, 4
),
external_factors AS (
    SELECT 
        week_start,
        economic_indicator,
        weather_index,
        competitor_price_index,
        marketing_spend,
        promotional_activity,
        holiday_flag,
        -- Seasonal components
        EXTRACT(WEEK FROM week_start) as week_of_year,
        EXTRACT(MONTH FROM week_start) as month_of_year,
        EXTRACT(QUARTER FROM week_start) as quarter_of_year
    FROM market.external_data
    WHERE week_start >= DATE_SUB(CURRENT_DATE, INTERVAL 104 WEEK)
),
demand_with_features AS (
    SELECT 
        hd.product_id,
        hd.facility_id,
        hd.region,
        hd.week_start,
        hd.weekly_demand,
        hd.weekly_revenue,
        hd.avg_unit_price,
        ef.economic_indicator,
        ef.weather_index,
        ef.marketing_spend,
        ef.promotional_activity,
        ef.holiday_flag,
        ef.week_of_year,
        ef.month_of_year,
        ef.quarter_of_year,
        -- Lag features for time series
        LAG(hd.weekly_demand, 1) OVER (PARTITION BY hd.product_id, hd.facility_id ORDER BY hd.week_start) as demand_lag_1,
        LAG(hd.weekly_demand, 2) OVER (PARTITION BY hd.product_id, hd.facility_id ORDER BY hd.week_start) as demand_lag_2,
        LAG(hd.weekly_demand, 4) OVER (PARTITION BY hd.product_id, hd.facility_id ORDER BY hd.week_start) as demand_lag_4,
        LAG(hd.weekly_demand, 52) OVER (PARTITION BY hd.product_id, hd.facility_id ORDER BY hd.week_start) as demand_lag_52,
        -- Moving averages
        AVG(hd.weekly_demand) OVER (
            PARTITION BY hd.product_id, hd.facility_id 
            ORDER BY hd.week_start 
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ) as ma_4_week,
        AVG(hd.weekly_demand) OVER (
            PARTITION BY hd.product_id, hd.facility_id 
            ORDER BY hd.week_start 
            ROWS BETWEEN 11 PRECEDING AND 1 PRECEDING
        ) as ma_12_week,
        -- Trend calculation
        (hd.weekly_demand - LAG(hd.weekly_demand, 4) OVER (PARTITION BY hd.product_id, hd.facility_id ORDER BY hd.week_start)) / 
        NULLIF(LAG(hd.weekly_demand, 4) OVER (PARTITION BY hd.product_id, hd.facility_id ORDER BY hd.week_start), 0) * 100 as trend_4_week
    FROM historical_demand hd
    LEFT JOIN external_factors ef ON hd.week_start = ef.week_start
),
seasonal_patterns AS (
    SELECT 
        product_id,
        week_of_year,
        month_of_year,
        quarter_of_year,
        AVG(weekly_demand) as avg_seasonal_demand,
        STDDEV(weekly_demand) as seasonal_volatility,
        -- Calculate seasonality index
        AVG(weekly_demand) / AVG(AVG(weekly_demand)) OVER (PARTITION BY product_id) as seasonality_index
    FROM demand_with_features
    WHERE weekly_demand IS NOT NULL
    GROUP BY 1, 2, 3, 4
),
forecast_model AS (
    SELECT 
        dwf.product_id,
        dwf.facility_id,
        dwf.region,
        dwf.week_start,
        dwf.weekly_demand as actual_demand,
        -- Simple linear forecast (in practice, use more sophisticated models)
        CASE 
            WHEN dwf.ma_12_week IS NOT NULL AND sp.seasonality_index IS NOT NULL
            THEN dwf.ma_12_week * sp.seasonality_index * 
                 (1 + COALESCE(dwf.trend_4_week, 0) / 100) *
                 (1 + dwf.promotional_activity * 0.15) *
                 (1 + dwf.marketing_spend / 10000 * 0.05)
            ELSE dwf.ma_4_week
        END as forecasted_demand,
        -- Confidence intervals
        CASE 
            WHEN sp.seasonal_volatility IS NOT NULL
            THEN sp.seasonal_volatility * 1.96 -- 95% confidence
            ELSE STDDEV(dwf.weekly_demand) OVER (PARTITION BY dwf.product_id) * 1.96
        END as forecast_confidence_interval,
        dwf.promotional_activity,
        dwf.holiday_flag,
        sp.seasonality_index
    FROM demand_with_features dwf
    LEFT JOIN seasonal_patterns sp ON dwf.product_id = sp.product_id 
                                   AND dwf.week_of_year = sp.week_of_year
),
forecast_accuracy AS (
    SELECT 
        product_id,
        facility_id,
        region,
        week_start,
        actual_demand,
        forecasted_demand,
        forecast_confidence_interval,
        -- Calculate forecast errors
        ABS(actual_demand - forecasted_demand) as absolute_error,
        ABS(actual_demand - forecasted_demand) / NULLIF(actual_demand, 0) * 100 as percentage_error,
        CASE 
            WHEN actual_demand BETWEEN (forecasted_demand - forecast_confidence_interval) 
                                   AND (forecasted_demand + forecast_confidence_interval)
            THEN 1 ELSE 0
        END as within_confidence_interval,
        -- Business impact metrics
        CASE 
            WHEN forecasted_demand > actual_demand 
            THEN (forecasted_demand - actual_demand) * 10 -- Overstock cost per unit
            ELSE (actual_demand - forecasted_demand) * 25 -- Stockout cost per unit
        END as forecast_error_cost
    FROM forecast_model
    WHERE actual_demand IS NOT NULL
      AND forecasted_demand IS NOT NULL
      AND week_start >= DATE_SUB(CURRENT_DATE, INTERVAL 26 WEEK) -- Test on last 6 months
)
SELECT 
    product_id,
    facility_id,
    region,
    COUNT(*) as forecast_periods,
    ROUND(AVG(percentage_error), 2) as avg_percentage_error,
    ROUND(AVG(within_confidence_interval) * 100, 1) as confidence_interval_accuracy_pct,
    SUM(forecast_error_cost) as total_forecast_cost,
    -- Forecast quality assessment
    CASE 
        WHEN AVG(percentage_error) <= 10 THEN 'EXCELLENT'
        WHEN AVG(percentage_error) <= 20 THEN 'GOOD'
        WHEN AVG(percentage_error) <= 30 THEN 'ACCEPTABLE'
        ELSE 'NEEDS_IMPROVEMENT'
    END as forecast_quality,
    -- Recommendations
    CASE 
        WHEN AVG(percentage_error) > 30 THEN 'REVISE_FORECASTING_MODEL'
        WHEN AVG(within_confidence_interval) < 0.8 THEN 'ADJUST_CONFIDENCE_INTERVALS'
        WHEN SUM(forecast_error_cost) > 10000 THEN 'FOCUS_ON_COST_REDUCTION'
        ELSE 'MAINTAIN_CURRENT_MODEL'
    END as recommendation
FROM forecast_accuracy
GROUP BY 1, 2, 3
ORDER BY total_forecast_cost DESC;

-- =====================================================
-- Challenge 2: Inventory Optimization
-- =====================================================

-- Optimize inventory levels using dynamic safety stock calculations,
-- ABC analysis, and demand variability assessment

WITH inventory_metrics AS (
    SELECT 
        product_id,
        facility_id,
        warehouse_location,
        DATE_TRUNC('week', inventory_date) as week_start,
        AVG(on_hand_quantity) as avg_on_hand,
        AVG(safety_stock_level) as avg_safety_stock,
        AVG(reorder_point) as avg_reorder_point,
        SUM(units_received) as weekly_receipts,
        SUM(units_shipped) as weekly_shipments,
        COUNT(CASE WHEN stockout_flag = 1 THEN 1 END) as stockout_days,
        AVG(carrying_cost_per_unit) as avg_carrying_cost,
        AVG(ordering_cost_per_order) as avg_ordering_cost
    FROM inventory.daily_positions
    WHERE inventory_date >= DATE_SUB(CURRENT_DATE, INTERVAL 52 WEEK)
    GROUP BY 1, 2, 3, 4
),
demand_variability AS (
    SELECT 
        product_id,
        facility_id,
        AVG(weekly_demand) as avg_weekly_demand,
        STDDEV(weekly_demand) as demand_std_dev,
        STDDEV(weekly_demand) / NULLIF(AVG(weekly_demand), 0) as coefficient_of_variation,
        -- Lead time analysis
        AVG(supplier_lead_time_days) as avg_lead_time,
        STDDEV(supplier_lead_time_days) as lead_time_std_dev
    FROM demand_with_features dwf
    JOIN suppliers.lead_times lt ON dwf.product_id = lt.product_id
    GROUP BY 1, 2
),
abc_analysis AS (
    SELECT 
        product_id,
        facility_id,
        SUM(weekly_revenue) as total_annual_revenue,
        SUM(weekly_demand * avg_unit_price) as total_annual_value,
        -- Calculate cumulative percentage of total value
        SUM(SUM(weekly_revenue)) OVER (
            PARTITION BY facility_id 
            ORDER BY SUM(weekly_revenue) DESC
        ) / SUM(SUM(weekly_revenue)) OVER (PARTITION BY facility_id) * 100 as cumulative_value_pct,
        -- ABC classification
        CASE 
            WHEN SUM(SUM(weekly_revenue)) OVER (
                PARTITION BY facility_id 
                ORDER BY SUM(weekly_revenue) DESC
            ) / SUM(SUM(weekly_revenue)) OVER (PARTITION BY facility_id) <= 0.80 THEN 'A'
            WHEN SUM(SUM(weekly_revenue)) OVER (
                PARTITION BY facility_id 
                ORDER BY SUM(weekly_revenue) DESC
            ) / SUM(SUM(weekly_revenue)) OVER (PARTITION BY facility_id) <= 0.95 THEN 'B'
            ELSE 'C'
        END as abc_category
    FROM historical_demand
    GROUP BY 1, 2
),
optimal_inventory AS (
    SELECT 
        im.product_id,
        im.facility_id,
        im.warehouse_location,
        dv.avg_weekly_demand,
        dv.demand_std_dev,
        dv.coefficient_of_variation,
        dv.avg_lead_time,
        dv.lead_time_std_dev,
        abc.abc_category,
        abc.total_annual_value,
        im.avg_carrying_cost,
        im.avg_ordering_cost,
        im.stockout_days,
        -- Calculate optimal safety stock using service level approach
        CASE abc.abc_category
            WHEN 'A' THEN 2.33 -- 99% service level
            WHEN 'B' THEN 1.65 -- 95% service level
            ELSE 1.28 -- 90% service level
        END * SQRT(dv.avg_lead_time) * dv.demand_std_dev as optimal_safety_stock,
        -- Economic Order Quantity (EOQ)
        SQRT(2 * dv.avg_weekly_demand * 52 * im.avg_ordering_cost / NULLIF(im.avg_carrying_cost, 0)) as economic_order_quantity,
        -- Reorder point calculation
        (dv.avg_weekly_demand * dv.avg_lead_time / 7) + 
        (CASE abc.abc_category
            WHEN 'A' THEN 2.33
            WHEN 'B' THEN 1.65
            ELSE 1.28
        END * SQRT(dv.avg_lead_time) * dv.demand_std_dev) as optimal_reorder_point,
        -- Current vs optimal comparison
        im.avg_safety_stock as current_safety_stock,
        im.avg_reorder_point as current_reorder_point
    FROM inventory_metrics im
    JOIN demand_variability dv ON im.product_id = dv.product_id AND im.facility_id = dv.facility_id
    JOIN abc_analysis abc ON im.product_id = abc.product_id AND im.facility_id = abc.facility_id
),
inventory_optimization_impact AS (
    SELECT 
        product_id,
        facility_id,
        warehouse_location,
        abc_category,
        avg_weekly_demand,
        coefficient_of_variation,
        current_safety_stock,
        optimal_safety_stock,
        current_reorder_point,
        optimal_reorder_point,
        economic_order_quantity,
        total_annual_value,
        avg_carrying_cost,
        stockout_days,
        -- Calculate inventory reduction/increase
        optimal_safety_stock - current_safety_stock as safety_stock_change,
        optimal_reorder_point - current_reorder_point as reorder_point_change,
        -- Financial impact
        (optimal_safety_stock - current_safety_stock) * avg_carrying_cost as carrying_cost_impact,
        -- Risk assessment
        CASE 
            WHEN coefficient_of_variation > 0.5 AND abc_category = 'A' THEN 'HIGH_RISK'
            WHEN coefficient_of_variation > 0.3 AND abc_category IN ('A', 'B') THEN 'MEDIUM_RISK'
            WHEN stockout_days > 5 THEN 'HIGH_STOCKOUT_RISK'
            ELSE 'LOW_RISK'
        END as inventory_risk_level
    FROM optimal_inventory
)
SELECT 
    product_id,
    facility_id,
    abc_category,
    ROUND(avg_weekly_demand, 0) as avg_weekly_demand,
    ROUND(coefficient_of_variation, 3) as demand_variability,
    ROUND(current_safety_stock, 0) as current_safety_stock,
    ROUND(optimal_safety_stock, 0) as optimal_safety_stock,
    ROUND(safety_stock_change, 0) as safety_stock_change,
    ROUND(carrying_cost_impact, 0) as annual_cost_impact,
    stockout_days,
    inventory_risk_level,
    -- Optimization recommendations
    CASE 
        WHEN ABS(safety_stock_change) / NULLIF(current_safety_stock, 0) > 0.2 
        THEN 'SIGNIFICANT_ADJUSTMENT_NEEDED'
        WHEN carrying_cost_impact < -1000 
        THEN 'REDUCE_INVENTORY_LEVELS'
        WHEN stockout_days > 5 
        THEN 'INCREASE_SAFETY_STOCK'
        WHEN inventory_risk_level = 'HIGH_RISK' 
        THEN 'IMPLEMENT_ENHANCED_MONITORING'
        ELSE 'MAINTAIN_CURRENT_LEVELS'
    END as optimization_action,
    -- Priority level
    CASE 
        WHEN abc_category = 'A' AND ABS(carrying_cost_impact) > 5000 THEN 'HIGH_PRIORITY'
        WHEN abc_category IN ('A', 'B') AND ABS(carrying_cost_impact) > 2000 THEN 'MEDIUM_PRIORITY'
        WHEN carrying_cost_impact < -500 THEN 'COST_SAVINGS_OPPORTUNITY'
        ELSE 'LOW_PRIORITY'
    END as implementation_priority
FROM inventory_optimization_impact
ORDER BY ABS(carrying_cost_impact) DESC;

-- =====================================================
-- Challenge 3: Predictive Maintenance
-- =====================================================

-- Develop predictive maintenance models to prevent equipment failures
-- and optimize maintenance schedules

WITH equipment_sensors AS (
    SELECT 
        equipment_id,
        facility_id,
        equipment_type,
        sensor_timestamp,
        temperature,
        vibration_level,
        pressure,
        rotation_speed,
        oil_quality_index,
        power_consumption,
        operating_hours_total,
        -- Calculate derived metrics
        temperature - LAG(temperature) OVER (PARTITION BY equipment_id ORDER BY sensor_timestamp) as temp_change_rate,
        vibration_level - LAG(vibration_level) OVER (PARTITION BY equipment_id ORDER BY sensor_timestamp) as vibration_change,
        power_consumption / NULLIF(rotation_speed, 0) as power_efficiency
    FROM maintenance.sensor_data
    WHERE sensor_timestamp >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 90 DAY)
),
maintenance_history AS (
    SELECT 
        equipment_id,
        maintenance_date,
        maintenance_type,
        failure_type,
        repair_cost,
        downtime_hours,
        parts_replaced,
        -- Calculate time between failures
        DATEDIFF(hour, 
            LAG(maintenance_date) OVER (PARTITION BY equipment_id ORDER BY maintenance_date),
            maintenance_date
        ) as hours_since_last_maintenance
    FROM maintenance.work_orders
    WHERE maintenance_date >= DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY)
      AND maintenance_type IN ('CORRECTIVE', 'EMERGENCY')
),
equipment_health_metrics AS (
    SELECT 
        es.equipment_id,
        es.facility_id,
        es.equipment_type,
        DATE_TRUNC('day', es.sensor_timestamp) as monitoring_date,
        -- Aggregate daily sensor readings
        AVG(es.temperature) as avg_temperature,
        MAX(es.temperature) as max_temperature,
        AVG(es.vibration_level) as avg_vibration,
        MAX(es.vibration_level) as max_vibration,
        AVG(es.pressure) as avg_pressure,
        AVG(es.rotation_speed) as avg_rotation_speed,
        AVG(es.oil_quality_index) as avg_oil_quality,
        AVG(es.power_consumption) as avg_power_consumption,
        MAX(es.operating_hours_total) as daily_operating_hours,
        -- Calculate anomaly indicators
        STDDEV(es.temperature) as temp_volatility,
        STDDEV(es.vibration_level) as vibration_volatility,
        COUNT(CASE WHEN ABS(es.temp_change_rate) > 5 THEN 1 END) as rapid_temp_changes,
        COUNT(CASE WHEN es.vibration_change > 2 THEN 1 END) as vibration_spikes
    FROM equipment_sensors es
    GROUP BY 1, 2, 3, 4
),
failure_risk_indicators AS (
    SELECT 
        ehm.equipment_id,
        ehm.facility_id,
        ehm.equipment_type,
        ehm.monitoring_date,
        ehm.avg_temperature,
        ehm.max_temperature,
        ehm.avg_vibration,
        ehm.max_vibration,
        ehm.avg_oil_quality,
        ehm.daily_operating_hours,
        ehm.temp_volatility,
        ehm.vibration_volatility,
        ehm.rapid_temp_changes,
        ehm.vibration_spikes,
        mh.hours_since_last_maintenance,
        mh.repair_cost as last_repair_cost,
        -- Calculate risk scores based on thresholds
        CASE 
            WHEN ehm.max_temperature > 80 THEN 25
            WHEN ehm.avg_temperature > 70 THEN 15
            WHEN ehm.avg_temperature > 60 THEN 10
            ELSE 0
        END as temperature_risk_score,
        CASE 
            WHEN ehm.max_vibration > 5.0 THEN 30
            WHEN ehm.avg_vibration > 3.0 THEN 20
            WHEN ehm.avg_vibration > 2.0 THEN 10
            ELSE 0
        END as vibration_risk_score,
        CASE 
            WHEN ehm.avg_oil_quality < 0.3 THEN 20
            WHEN ehm.avg_oil_quality < 0.5 THEN 15
            WHEN ehm.avg_oil_quality < 0.7 THEN 10
            ELSE 0
        END as oil_quality_risk_score,
        CASE 
            WHEN mh.hours_since_last_maintenance > 2000 THEN 25
            WHEN mh.hours_since_last_maintenance > 1500 THEN 15
            WHEN mh.hours_since_last_maintenance > 1000 THEN 10
            ELSE 0
        END as maintenance_overdue_score,
        CASE 
            WHEN ehm.rapid_temp_changes > 10 THEN 15
            WHEN ehm.vibration_spikes > 5 THEN 15
            WHEN ehm.temp_volatility > 10 THEN 10
            ELSE 0
        END as anomaly_score
    FROM equipment_health_metrics ehm
    LEFT JOIN maintenance_history mh ON ehm.equipment_id = mh.equipment_id
),
predictive_maintenance_model AS (
    SELECT 
        equipment_id,
        facility_id,
        equipment_type,
        monitoring_date,
        temperature_risk_score,
        vibration_risk_score,
        oil_quality_risk_score,
        maintenance_overdue_score,
        anomaly_score,
        hours_since_last_maintenance,
        last_repair_cost,
        -- Calculate total risk score
        temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
        maintenance_overdue_score + anomaly_score as total_risk_score,
        -- Predict failure probability (simplified model)
        CASE 
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 80 THEN 0.85
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 60 THEN 0.65
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 40 THEN 0.35
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 20 THEN 0.15
            ELSE 0.05
        END as failure_probability,
        -- Estimate time to failure (days)
        CASE 
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 80 THEN 7
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 60 THEN 14
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 40 THEN 30
            WHEN (temperature_risk_score + vibration_risk_score + oil_quality_risk_score + 
                  maintenance_overdue_score + anomaly_score) >= 20 THEN 60
            ELSE 90
        END as estimated_days_to_failure
    FROM failure_risk_indicators
),
maintenance_recommendations AS (
    SELECT 
        equipment_id,
        facility_id,
        equipment_type,
        monitoring_date,
        total_risk_score,
        failure_probability,
        estimated_days_to_failure,
        hours_since_last_maintenance,
        COALESCE(last_repair_cost, 1000) as estimated_repair_cost,
        -- Risk categorization
        CASE 
            WHEN failure_probability >= 0.8 THEN 'CRITICAL'
            WHEN failure_probability >= 0.6 THEN 'HIGH'
            WHEN failure_probability >= 0.3 THEN 'MEDIUM'
            WHEN failure_probability >= 0.1 THEN 'LOW'
            ELSE 'MINIMAL'
        END as risk_level,
        -- Maintenance recommendations
        CASE 
            WHEN failure_probability >= 0.8 THEN 'IMMEDIATE_SHUTDOWN_AND_REPAIR'
            WHEN failure_probability >= 0.6 THEN 'SCHEDULE_EMERGENCY_MAINTENANCE'
            WHEN failure_probability >= 0.3 THEN 'SCHEDULE_PREVENTIVE_MAINTENANCE'
            WHEN hours_since_last_maintenance > 1500 THEN 'ROUTINE_MAINTENANCE_DUE'
            ELSE 'CONTINUE_MONITORING'
        END as maintenance_action,
        -- Cost-benefit analysis
        failure_probability * estimated_repair_cost * 3 as expected_failure_cost, -- 3x for downtime costs
        CASE 
            WHEN failure_probability >= 0.3 THEN 500 -- Preventive maintenance cost
            ELSE 0
        END as preventive_maintenance_cost
    FROM predictive_maintenance_model
)
SELECT 
    equipment_id,
    facility_id,
    equipment_type,
    risk_level,
    ROUND(failure_probability * 100, 1) as failure_probability_pct,
    estimated_days_to_failure,
    hours_since_last_maintenance,
    maintenance_action,
    ROUND(expected_failure_cost, 0) as expected_failure_cost,
    ROUND(preventive_maintenance_cost, 0) as preventive_maintenance_cost,
    ROUND(expected_failure_cost - preventive_maintenance_cost, 0) as potential_savings,
    -- Implementation priority
    CASE 
        WHEN risk_level = 'CRITICAL' THEN 'IMMEDIATE'
        WHEN risk_level = 'HIGH' AND (expected_failure_cost - preventive_maintenance_cost) > 5000 THEN 'URGENT'
        WHEN risk_level = 'MEDIUM' AND (expected_failure_cost - preventive_maintenance_cost) > 2000 THEN 'SCHEDULED'
        ELSE 'ROUTINE'
    END as maintenance_priority
FROM maintenance_recommendations
WHERE risk_level != 'MINIMAL'
ORDER BY failure_probability DESC, potential_savings DESC;

-- =====================================================
-- Challenge 4: Supply Chain Risk Assessment
-- =====================================================

-- Comprehensive supply chain risk analysis including supplier
-- reliability, geopolitical risks, and network resilience

WITH supplier_performance AS (
    SELECT 
        supplier_id,
        supplier_name,
        supplier_country,
        supplier_region,
        product_category,
        COUNT(*) as total_orders,
        COUNT(CASE WHEN delivery_status = 'ON_TIME' THEN 1 END) as on_time_deliveries,
        COUNT(CASE WHEN quality_status = 'PASSED' THEN 1 END) as quality_passed,
        AVG(delivery_lead_time_days) as avg_lead_time,
        STDDEV(delivery_lead_time_days) as lead_time_variability,
        SUM(order_value) as total_order_value,
        AVG(unit_cost) as avg_unit_cost,
        -- Performance metrics
        COUNT(CASE WHEN delivery_status = 'ON_TIME' THEN 1 END) * 100.0 / COUNT(*) as on_time_delivery_rate,
        COUNT(CASE WHEN quality_status = 'PASSED' THEN 1 END) * 100.0 / COUNT(*) as quality_pass_rate,
        STDDEV(delivery_lead_time_days) / NULLIF(AVG(delivery_lead_time_days), 0) as lead_time_cv
    FROM procurement.purchase_orders
    WHERE order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY)
    GROUP BY 1, 2, 3, 4, 5
),
geopolitical_risk_factors AS (
    SELECT 
        country_code,
        country_name,
        political_stability_index, -- Scale 1-10
        economic_stability_index,  -- Scale 1-10
        trade_freedom_index,       -- Scale 1-10
        infrastructure_quality,    -- Scale 1-10
        currency_volatility,       -- Coefficient of variation
        trade_dispute_flag,
        sanctions_flag,
        natural_disaster_risk,     -- Scale 1-10
        -- Calculate composite risk score
        (10 - political_stability_index) * 0.25 +
        (10 - economic_stability_index) * 0.20 +
        (10 - trade_freedom_index) * 0.15 +
        (10 - infrastructure_quality) * 0.15 +
        currency_volatility * 10 * 0.10 +
        CASE WHEN trade_dispute_flag = 1 THEN 2 ELSE 0 END +
        CASE WHEN sanctions_flag = 1 THEN 3 ELSE 0 END +
        natural_disaster_risk * 0.15 as country_risk_score
    FROM reference.country_risk_data
),
supply_network_analysis AS (
    SELECT 
        product_id,
        product_category,
        COUNT(DISTINCT sp.supplier_id) as supplier_count,
        COUNT(DISTINCT sp.supplier_country) as country_count,
        SUM(sp.total_order_value) as total_category_spend,
        -- Concentration risk
        MAX(sp.total_order_value) / SUM(sp.total_order_value) as supplier_concentration,
        MAX(country_spend.country_total) / SUM(sp.total_order_value) as country_concentration,
        -- Performance aggregation
        AVG(sp.on_time_delivery_rate) as avg_otd_rate,
        AVG(sp.quality_pass_rate) as avg_quality_rate,
        AVG(sp.lead_time_cv) as avg_lead_time_variability
    FROM products.master_data p
    JOIN supplier_performance sp ON p.product_category = sp.product_category
    JOIN (
        SELECT 
            supplier_country,
            product_category,
            SUM(total_order_value) as country_total
        FROM supplier_performance
        GROUP BY 1, 2
    ) country_spend ON sp.supplier_country = country_spend.supplier_country 
                   AND sp.product_category = country_spend.product_category
    GROUP BY 1, 2
),
risk_assessment AS (
    SELECT 
        sp.supplier_id,
        sp.supplier_name,
        sp.supplier_country,
        sp.product_category,
        sp.total_order_value,
        sp.on_time_delivery_rate,
        sp.quality_pass_rate,
        sp.lead_time_cv,
        grf.country_risk_score,
        sna.supplier_concentration,
        sna.country_concentration,
        -- Calculate supplier risk scores
        CASE 
            WHEN sp.on_time_delivery_rate < 85 THEN 20
            WHEN sp.on_time_delivery_rate < 90 THEN 15
            WHEN sp.on_time_delivery_rate < 95 THEN 10
            ELSE 0
        END as delivery_risk_score,
        CASE 
            WHEN sp.quality_pass_rate < 95 THEN 25
            WHEN sp.quality_pass_rate < 98 THEN 15
            WHEN sp.quality_pass_rate < 99 THEN 10
            ELSE 0
        END as quality_risk_score,
        CASE 
            WHEN sp.lead_time_cv > 0.5 THEN 15
            WHEN sp.lead_time_cv > 0.3 THEN 10
            WHEN sp.lead_time_cv > 0.2 THEN 5
            ELSE 0
        END as variability_risk_score,
        CASE 
            WHEN sna.supplier_concentration > 0.7 THEN 20
            WHEN sna.supplier_concentration > 0.5 THEN 15
            WHEN sna.supplier_concentration > 0.3 THEN 10
            ELSE 0
        END as concentration_risk_score,
        -- Financial risk
        sp.total_order_value / SUM(sp.total_order_value) OVER () * 100 as spend_percentage
    FROM supplier_performance sp
    LEFT JOIN geopolitical_risk_factors grf ON sp.supplier_country = grf.country_code
    LEFT JOIN supply_network_analysis sna ON sp.product_category = sna.product_category
),
comprehensive_risk_scoring AS (
    SELECT 
        supplier_id,
        supplier_name,
        supplier_country,
        product_category,
        total_order_value,
        spend_percentage,
        on_time_delivery_rate,
        quality_pass_rate,
        delivery_risk_score,
        quality_risk_score,
        variability_risk_score,
        concentration_risk_score,
        COALESCE(country_risk_score, 5) as country_risk_score,
        -- Calculate total risk score
        delivery_risk_score + quality_risk_score + variability_risk_score + 
        concentration_risk_score + COALESCE(country_risk_score, 5) as total_risk_score,
        -- Risk impact calculation
        (delivery_risk_score + quality_risk_score + variability_risk_score + 
         concentration_risk_score + COALESCE(country_risk_score, 5)) * 
        (spend_percentage / 100) as risk_weighted_impact
    FROM risk_assessment
)
SELECT 
    supplier_name,
    supplier_country,
    product_category,
    ROUND(total_order_value, 0) as annual_spend,
    ROUND(spend_percentage, 2) as spend_percentage,
    ROUND(on_time_delivery_rate, 1) as otd_rate_pct,
    ROUND(quality_pass_rate, 1) as quality_rate_pct,
    ROUND(total_risk_score, 0) as risk_score,
    ROUND(risk_weighted_impact, 2) as risk_impact,
    -- Risk categorization
    CASE 
        WHEN total_risk_score >= 60 THEN 'HIGH_RISK'
        WHEN total_risk_score >= 40 THEN 'MEDIUM_RISK'
        WHEN total_risk_score >= 20 THEN 'LOW_RISK'
        ELSE 'MINIMAL_RISK'
    END as risk_category,
    -- Mitigation recommendations
    CASE 
        WHEN total_risk_score >= 60 AND spend_percentage > 10 THEN 'DIVERSIFY_SUPPLIER_BASE'
        WHEN delivery_risk_score >= 15 THEN 'IMPROVE_DELIVERY_PERFORMANCE'
        WHEN quality_risk_score >= 20 THEN 'IMPLEMENT_QUALITY_IMPROVEMENT'
        WHEN concentration_risk_score >= 15 THEN 'REDUCE_SUPPLIER_DEPENDENCY'
        WHEN country_risk_score >= 7 THEN 'CONSIDER_ALTERNATIVE_REGIONS'
        ELSE 'MAINTAIN_CURRENT_RELATIONSHIP'
    END as mitigation_strategy,
    -- Business priority
    CASE 
        WHEN risk_category = 'HIGH_RISK' AND spend_percentage > 5 THEN 'CRITICAL_PRIORITY'
        WHEN risk_category = 'MEDIUM_RISK' AND spend_percentage > 10 THEN 'HIGH_PRIORITY'
        WHEN risk_weighted_impact > 5 THEN 'MEDIUM_PRIORITY'
        ELSE 'LOW_PRIORITY'
    END as business_priority
FROM comprehensive_risk_scoring
ORDER BY risk_weighted_impact DESC;

-- =====================================================
-- Executive Dashboard Integration
-- =====================================================

-- Comprehensive supply chain performance dashboard
-- combining all analytical components

WITH supply_chain_kpis AS (
    SELECT 
        'Demand Forecasting' as kpi_category,
        AVG(avg_percentage_error) as performance_metric,
        COUNT(CASE WHEN forecast_quality = 'EXCELLENT' THEN 1 END) as excellent_count,
        COUNT(*) as total_count,
        SUM(total_forecast_cost) as total_cost_impact
    FROM forecast_accuracy
    WHERE forecast_quality IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'Inventory Optimization' as kpi_category,
        AVG(carrying_cost_impact) as performance_metric,
        COUNT(CASE WHEN optimization_action = 'REDUCE_INVENTORY_LEVELS' THEN 1 END) as optimization_opportunities,
        COUNT(*) as total_count,
        SUM(carrying_cost_impact) as total_cost_impact
    FROM inventory_optimization_impact
    
    UNION ALL
    
    SELECT 
        'Predictive Maintenance' as kpi_category,
        AVG(failure_probability * 100) as performance_metric,
        COUNT(CASE WHEN risk_level IN ('HIGH', 'CRITICAL') THEN 1 END) as high_risk_equipment,
        COUNT(*) as total_count,
        SUM(potential_savings) as total_cost_impact
    FROM maintenance_recommendations
    
    UNION ALL
    
    SELECT 
        'Supply Chain Risk' as kpi_category,
        AVG(risk_score) as performance_metric,
        COUNT(CASE WHEN risk_category = 'HIGH_RISK' THEN 1 END) as high_risk_suppliers,
        COUNT(*) as total_count,
        NULL as total_cost_impact
    FROM comprehensive_risk_scoring
)
SELECT 
    kpi_category,
    ROUND(performance_metric, 2) as key_performance_metric,
    excellent_count as positive_indicators,
    total_count as total_entities_analyzed,
    ROUND(total_cost_impact, 0) as financial_impact_usd,
    -- Strategic recommendations
    CASE kpi_category
        WHEN 'Demand Forecasting' THEN 
            CASE WHEN performance_metric > 20 THEN 'Improve forecasting models'
                 ELSE 'Maintain forecasting accuracy' END
        WHEN 'Inventory Optimization' THEN 
            CASE WHEN total_cost_impact < -100000 THEN 'Implement inventory reductions'
                 ELSE 'Fine-tune inventory levels' END
        WHEN 'Predictive Maintenance' THEN 
            CASE WHEN excellent_count > 10 THEN 'Prioritize high-risk equipment'
                 ELSE 'Expand predictive maintenance program' END
        WHEN 'Supply Chain Risk' THEN 
            CASE WHEN excellent_count > 5 THEN 'Diversify high-risk suppliers'
                 ELSE 'Continue risk monitoring' END
    END as strategic_recommendation
FROM supply_chain_kpis
ORDER BY ABS(total_cost_impact) DESC NULLS LAST;

-- =====================================================
-- SUCCESS METRICS VALIDATION
-- =====================================================

/*
Validate your solution against these success criteria:

1. Inventory Cost Reduction (Target: 20%+ reduction, $5M+ annually)
   - Optimize safety stock levels
   - Implement ABC analysis
   - Reduce carrying costs

2. Equipment Downtime Reduction (Target: 30%+ reduction)
   - Predictive maintenance implementation
   - Failure probability accuracy
   - Maintenance cost optimization

3. Demand Forecast Accuracy (Target: 90%+)
   - Forecast error minimization
   - Seasonal pattern recognition
   - External factor integration

4. Supply Chain Risk Score (Target: <15% high-risk suppliers)
   - Supplier diversification
   - Geopolitical risk mitigation
   - Performance monitoring

5. On-time Delivery (Target: 98%+)
   - Supplier performance improvement
   - Lead time optimization
   - Risk-based sourcing
*/
