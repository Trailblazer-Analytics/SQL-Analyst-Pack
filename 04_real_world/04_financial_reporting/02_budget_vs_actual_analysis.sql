-- ============================================================================
-- BUDGET VS ACTUAL VARIANCE ANALYSIS
-- Financial Reporting Scenario for SQL Analysts
-- ============================================================================

/*
📊 BUSINESS CONTEXT:
The Finance team needs to prepare the monthly budget vs actual report for the 
executive team. This analysis will identify significant variances, explain 
performance drivers, and support quarterly reforecasting efforts.

🎯 STAKEHOLDER: CFO, Finance Director, Business Unit Leaders
📅 FREQUENCY: Monthly (due 5 business days after month end)
🎯 DECISION: Resource allocation, forecast adjustments, corrective actions

🎯 BUSINESS REQUIREMENTS:
1. Revenue and expense variance analysis by business unit and GL account
2. Identification of variances >10% or >$50K for investigation
3. Year-to-date performance tracking vs annual budget
4. Forecast accuracy assessment and reforecast recommendations
5. Key variance explanations and business impact analysis

📈 SUCCESS METRICS:
- Accurate variance calculations and trend identification
- Timely identification of significant variances requiring action
- Support for executive decision-making and budget management
- Improved forecast accuracy through variance pattern analysis
*/

-- ============================================================================
-- DATA STRUCTURE OVERVIEW
-- ============================================================================

/*
Available Tables:
- actual_results: Monthly actual revenue and expenses by GL account
- budget_plan: Annual budget by month, business unit, and GL account  
- forecast_updates: Quarterly reforecasts and adjustments
- gl_accounts: Chart of accounts with account types and categories
- business_units: Organizational structure and reporting hierarchy
- variance_explanations: Management explanations for significant variances
*/

-- ============================================================================
-- SECTION 1: REVENUE VARIANCE ANALYSIS
-- ============================================================================

-- 1.1 Monthly Revenue Performance by Business Unit
SELECT 
    bu.business_unit_name,
    bu.business_unit_type,
    gl.account_name,
    
    -- Current month performance
    SUM(ar.actual_amount) as actual_revenue,
    SUM(bp.budget_amount) as budget_revenue,
    SUM(ar.actual_amount) - SUM(bp.budget_amount) as revenue_variance,
    
    -- Variance percentages
    ROUND(
        (SUM(ar.actual_amount) - SUM(bp.budget_amount)) * 100.0 / 
        NULLIF(SUM(bp.budget_amount), 0), 2
    ) as variance_percent,
    
    -- Year-to-date performance
    SUM(CASE WHEN ar.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
             THEN ar.actual_amount ELSE 0 END) as ytd_actual,
    SUM(CASE WHEN bp.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
             THEN bp.budget_amount ELSE 0 END) as ytd_budget,
    
    -- YTD variance
    SUM(CASE WHEN ar.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
             THEN ar.actual_amount ELSE 0 END) - 
    SUM(CASE WHEN bp.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
             THEN bp.budget_amount ELSE 0 END) as ytd_variance,
    
    -- Forecast accuracy (previous month)
    SUM(CASE WHEN ar.period_month = EXTRACT(MONTH FROM CURRENT_DATE) - 1 
             THEN ar.actual_amount ELSE 0 END) as prev_month_actual,
    SUM(CASE WHEN fu.forecast_month = EXTRACT(MONTH FROM CURRENT_DATE) - 1 
             THEN fu.forecast_amount ELSE 0 END) as prev_month_forecast,
    
    -- Performance indicators
    CASE 
        WHEN ABS((SUM(ar.actual_amount) - SUM(bp.budget_amount)) * 100.0 / 
                 NULLIF(SUM(bp.budget_amount), 0)) >= 15 
        THEN '🔴 Significant Variance'
        WHEN ABS((SUM(ar.actual_amount) - SUM(bp.budget_amount)) * 100.0 / 
                 NULLIF(SUM(bp.budget_amount), 0)) >= 10 
        THEN '🟡 Moderate Variance'
        WHEN SUM(ar.actual_amount) > SUM(bp.budget_amount) 
        THEN '🟢 Favorable'
        ELSE '➡️ On Track'
    END as variance_status

FROM actual_results ar
JOIN budget_plan bp ON ar.gl_account_id = bp.gl_account_id 
                    AND ar.business_unit_id = bp.business_unit_id
                    AND ar.period_month = bp.period_month
                    AND ar.period_year = bp.period_year
JOIN business_units bu ON ar.business_unit_id = bu.business_unit_id
JOIN gl_accounts gl ON ar.gl_account_id = gl.gl_account_id
LEFT JOIN forecast_updates fu ON ar.gl_account_id = fu.gl_account_id 
                              AND ar.business_unit_id = fu.business_unit_id

WHERE gl.account_type = 'Revenue'
  AND ar.period_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND ar.period_month = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY bu.business_unit_name, bu.business_unit_type, gl.account_name
ORDER BY ABS(SUM(ar.actual_amount) - SUM(bp.budget_amount)) DESC;

-- 1.2 Revenue Trend Analysis and Seasonality
WITH monthly_revenue_trends AS (
    SELECT 
        ar.period_month,
        SUM(ar.actual_amount) as actual_revenue,
        SUM(bp.budget_amount) as budget_revenue,
        SUM(ar.actual_amount) - SUM(bp.budget_amount) as variance,
        
        -- Prior year comparison
        LAG(SUM(ar.actual_amount), 12) OVER (ORDER BY ar.period_month) as prior_year_actual,
        
        -- Month-over-month growth
        LAG(SUM(ar.actual_amount), 1) OVER (ORDER BY ar.period_month) as prior_month_actual,
        
        -- 3-month moving average
        AVG(SUM(ar.actual_amount)) OVER (
            ORDER BY ar.period_month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as three_month_avg

    FROM actual_results ar
    JOIN budget_plan bp ON ar.gl_account_id = bp.gl_account_id 
                        AND ar.business_unit_id = bp.business_unit_id
                        AND ar.period_month = bp.period_month
                        AND ar.period_year = bp.period_year
    JOIN gl_accounts gl ON ar.gl_account_id = gl.gl_account_id
    WHERE gl.account_type = 'Revenue'
      AND ar.period_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
    GROUP BY ar.period_month
)
SELECT 
    period_month,
    TO_CHAR(DATE_MAKE(EXTRACT(YEAR FROM CURRENT_DATE), period_month, 1), 'Month') as month_name,
    actual_revenue,
    budget_revenue,
    variance,
    ROUND(variance * 100.0 / NULLIF(budget_revenue, 0), 2) as variance_percent,
    
    -- Growth metrics
    ROUND((actual_revenue - prior_year_actual) * 100.0 / NULLIF(prior_year_actual, 0), 2) as yoy_growth,
    ROUND((actual_revenue - prior_month_actual) * 100.0 / NULLIF(prior_month_actual, 0), 2) as mom_growth,
    
    -- Trend indicators
    ROUND(three_month_avg, 0) as three_month_trend,
    CASE 
        WHEN actual_revenue > three_month_avg * 1.05 THEN 'Above Trend'
        WHEN actual_revenue < three_month_avg * 0.95 THEN 'Below Trend'
        ELSE 'In Line'
    END as trend_status,
    
    -- Seasonality indicators
    CASE 
        WHEN period_month IN (11, 12, 1) THEN 'Peak Season'
        WHEN period_month IN (6, 7, 8) THEN 'Summer Season'  
        ELSE 'Regular Season'
    END as seasonal_period

FROM monthly_revenue_trends
WHERE period_month <= EXTRACT(MONTH FROM CURRENT_DATE)
ORDER BY period_month;

-- ============================================================================
-- SECTION 2: EXPENSE VARIANCE ANALYSIS
-- ============================================================================

-- 2.1 Operating Expense Analysis by Category
SELECT 
    gl.account_category,
    gl.account_name,
    
    -- Current month performance
    SUM(ar.actual_amount) as actual_expense,
    SUM(bp.budget_amount) as budget_expense,
    SUM(ar.actual_amount) - SUM(bp.budget_amount) as expense_variance,
    
    -- Variance analysis (negative variance = overspend)
    ROUND(
        (SUM(ar.actual_amount) - SUM(bp.budget_amount)) * 100.0 / 
        NULLIF(SUM(bp.budget_amount), 0), 2
    ) as variance_percent,
    
    -- Year-to-date tracking
    SUM(CASE WHEN ar.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
             THEN ar.actual_amount ELSE 0 END) as ytd_actual,
    SUM(CASE WHEN bp.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
             THEN bp.budget_amount ELSE 0 END) as ytd_budget,
    
    -- Remaining budget for the year
    SUM(CASE WHEN bp.period_month > EXTRACT(MONTH FROM CURRENT_DATE) 
             THEN bp.budget_amount ELSE 0 END) as remaining_budget,
    
    -- Run rate analysis (monthly average spend)
    ROUND(
        SUM(CASE WHEN ar.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
                 THEN ar.actual_amount ELSE 0 END) / 
        NULLIF(EXTRACT(MONTH FROM CURRENT_DATE), 0), 0
    ) as monthly_run_rate,
    
    -- Projected year-end spend based on run rate
    ROUND(
        SUM(CASE WHEN ar.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
                 THEN ar.actual_amount ELSE 0 END) / 
        NULLIF(EXTRACT(MONTH FROM CURRENT_DATE), 0) * 12, 0
    ) as projected_annual_spend,
    
    -- Budget management indicators
    CASE 
        WHEN SUM(ar.actual_amount) > SUM(bp.budget_amount) * 1.1 THEN '🔴 Over Budget'
        WHEN SUM(ar.actual_amount) > SUM(bp.budget_amount) THEN '🟡 Slightly Over'
        WHEN SUM(ar.actual_amount) < SUM(bp.budget_amount) * 0.9 THEN '🟢 Under Budget'
        ELSE '✅ On Budget'
    END as budget_status

FROM actual_results ar
JOIN budget_plan bp ON ar.gl_account_id = bp.gl_account_id 
                    AND ar.business_unit_id = bp.business_unit_id
                    AND ar.period_month = bp.period_month
                    AND ar.period_year = bp.period_year
JOIN gl_accounts gl ON ar.gl_account_id = gl.gl_account_id

WHERE gl.account_type = 'Expense'
  AND ar.period_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND ar.period_month = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY gl.account_category, gl.account_name
ORDER BY ABS(SUM(ar.actual_amount) - SUM(bp.budget_amount)) DESC;

-- ============================================================================
-- SECTION 3: VARIANCE INVESTIGATION AND EXPLANATION
-- ============================================================================

-- 3.1 Significant Variances Requiring Management Attention
WITH significant_variances AS (
    SELECT 
        bu.business_unit_name,
        gl.account_name,
        gl.account_type,
        SUM(ar.actual_amount) as actual_amount,
        SUM(bp.budget_amount) as budget_amount,
        SUM(ar.actual_amount) - SUM(bp.budget_amount) as variance_amount,
        
        -- Variance percentage
        ROUND(
            (SUM(ar.actual_amount) - SUM(bp.budget_amount)) * 100.0 / 
            NULLIF(SUM(bp.budget_amount), 0), 2
        ) as variance_percent,
        
        -- Materiality flags
        CASE 
            WHEN ABS(SUM(ar.actual_amount) - SUM(bp.budget_amount)) >= 50000 THEN 'Material Amount'
            ELSE 'Immaterial Amount'
        END as materiality_flag,
        
        CASE 
            WHEN ABS((SUM(ar.actual_amount) - SUM(bp.budget_amount)) * 100.0 / 
                     NULLIF(SUM(bp.budget_amount), 0)) >= 15 THEN 'Material Percent'
            ELSE 'Immaterial Percent'
        END as percentage_flag

    FROM actual_results ar
    JOIN budget_plan bp ON ar.gl_account_id = bp.gl_account_id 
                        AND ar.business_unit_id = bp.business_unit_id
                        AND ar.period_month = bp.period_month
                        AND ar.period_year = bp.period_year
    JOIN business_units bu ON ar.business_unit_id = bu.business_unit_id
    JOIN gl_accounts gl ON ar.gl_account_id = gl.gl_account_id

    WHERE ar.period_year = EXTRACT(YEAR FROM CURRENT_DATE)
      AND ar.period_month = EXTRACT(MONTH FROM CURRENT_DATE)
    GROUP BY bu.business_unit_name, gl.account_name, gl.account_type
)
SELECT 
    business_unit_name,
    account_name,
    account_type,
    actual_amount,
    budget_amount,
    variance_amount,
    variance_percent,
    
    -- Investigation priority
    CASE 
        WHEN materiality_flag = 'Material Amount' AND percentage_flag = 'Material Percent' 
        THEN '🔴 HIGH PRIORITY'
        WHEN materiality_flag = 'Material Amount' OR percentage_flag = 'Material Percent' 
        THEN '🟡 MEDIUM PRIORITY'
        ELSE '🟢 LOW PRIORITY'
    END as investigation_priority,
    
    -- Variance type
    CASE 
        WHEN account_type = 'Revenue' AND variance_amount > 0 THEN 'Favorable Revenue'
        WHEN account_type = 'Revenue' AND variance_amount < 0 THEN 'Unfavorable Revenue'
        WHEN account_type = 'Expense' AND variance_amount < 0 THEN 'Favorable Expense'
        WHEN account_type = 'Expense' AND variance_amount > 0 THEN 'Unfavorable Expense'
        ELSE 'Neutral'
    END as variance_type,
    
    -- Standard variance explanation prompts
    CASE 
        WHEN account_type = 'Revenue' AND variance_amount < 0 
        THEN 'Investigate: Lower sales volume, pricing pressure, or timing differences'
        WHEN account_type = 'Revenue' AND variance_amount > 0 
        THEN 'Analyze: Higher volume, price increases, or one-time items'
        WHEN account_type = 'Expense' AND variance_amount > 0 
        THEN 'Review: Higher costs, volume increases, or unplanned expenses'
        WHEN account_type = 'Expense' AND variance_amount < 0 
        THEN 'Confirm: Cost savings, timing differences, or volume decreases'
        ELSE 'Monitor: Regular variance analysis'
    END as investigation_guidance

FROM significant_variances
WHERE (materiality_flag = 'Material Amount' OR percentage_flag = 'Material Percent')
ORDER BY ABS(variance_amount) DESC;

-- ============================================================================
-- SECTION 4: FORECAST ACCURACY AND REFORECAST RECOMMENDATIONS
-- ============================================================================

-- 4.1 Forecast Accuracy Assessment and Year-End Projections
WITH forecast_accuracy AS (
    SELECT 
        gl.account_category,
        
        -- Q1 Forecast Accuracy
        SUM(CASE WHEN ar.period_month BETWEEN 1 AND 3 THEN ar.actual_amount ELSE 0 END) as q1_actual,
        SUM(CASE WHEN fu.forecast_quarter = 1 THEN fu.forecast_amount ELSE 0 END) as q1_forecast,
        
        -- Q2 Forecast Accuracy  
        SUM(CASE WHEN ar.period_month BETWEEN 4 AND 6 THEN ar.actual_amount ELSE 0 END) as q2_actual,
        SUM(CASE WHEN fu.forecast_quarter = 2 THEN fu.forecast_amount ELSE 0 END) as q2_forecast,
        
        -- Q3 Forecast Accuracy
        SUM(CASE WHEN ar.period_month BETWEEN 7 AND 9 THEN ar.actual_amount ELSE 0 END) as q3_actual,
        SUM(CASE WHEN fu.forecast_quarter = 3 THEN fu.forecast_amount ELSE 0 END) as q3_forecast,
        
        -- Year-to-date performance
        SUM(CASE WHEN ar.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
                 THEN ar.actual_amount ELSE 0 END) as ytd_actual,
        SUM(bp.budget_amount) as annual_budget,
        
        -- Current run rate for projections
        ROUND(
            SUM(CASE WHEN ar.period_month <= EXTRACT(MONTH FROM CURRENT_DATE) 
                     THEN ar.actual_amount ELSE 0 END) / 
            NULLIF(EXTRACT(MONTH FROM CURRENT_DATE), 0), 0
        ) as monthly_run_rate

    FROM actual_results ar
    JOIN budget_plan bp ON ar.gl_account_id = bp.gl_account_id 
                        AND ar.business_unit_id = bp.business_unit_id
                        AND ar.period_year = bp.period_year
    JOIN gl_accounts gl ON ar.gl_account_id = gl.gl_account_id
    LEFT JOIN forecast_updates fu ON ar.gl_account_id = fu.gl_account_id 
                                  AND ar.business_unit_id = fu.business_unit_id
                                  AND ar.period_year = fu.forecast_year

    WHERE ar.period_year = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY gl.account_category
)
SELECT 
    account_category,
    ytd_actual,
    annual_budget,
    monthly_run_rate,
    
    -- Year-end projections
    monthly_run_rate * 12 as run_rate_projection,
    annual_budget - (monthly_run_rate * 12) as projected_variance,
    
    -- Forecast accuracy metrics
    ROUND(ABS(q1_actual - q1_forecast) * 100.0 / NULLIF(q1_forecast, 0), 2) as q1_forecast_error,
    ROUND(ABS(q2_actual - q2_forecast) * 100.0 / NULLIF(q2_forecast, 0), 2) as q2_forecast_error,
    ROUND(ABS(q3_actual - q3_forecast) * 100.0 / NULLIF(q3_forecast, 0), 2) as q3_forecast_error,
    
    -- Reforecast recommendations
    CASE 
        WHEN ABS(annual_budget - (monthly_run_rate * 12)) > annual_budget * 0.1 
        THEN 'RECOMMEND REFORECAST'
        WHEN ABS(annual_budget - (monthly_run_rate * 12)) > annual_budget * 0.05 
        THEN 'MONITOR CLOSELY'
        ELSE 'ON TRACK'
    END as reforecast_recommendation,
    
    -- Budget achievement probability
    CASE 
        WHEN monthly_run_rate * 12 > annual_budget * 1.05 THEN 'High - Exceeding Budget'
        WHEN monthly_run_rate * 12 > annual_budget * 0.95 THEN 'High - Meeting Budget'
        WHEN monthly_run_rate * 12 > annual_budget * 0.85 THEN 'Medium - Below Budget'
        ELSE 'Low - Significantly Below'
    END as budget_achievement_probability

FROM forecast_accuracy
ORDER BY ABS(annual_budget - (monthly_run_rate * 12)) DESC;

/*
🎯 KEY BUSINESS INSIGHTS:

1. REVENUE VARIANCE DRIVERS:
   - Identify business units and product lines with significant performance gaps
   - Analyze seasonal patterns and trend deviations
   - Support sales forecasting and resource allocation decisions

2. EXPENSE MANAGEMENT:
   - Track budget adherence and identify overspend risks
   - Calculate run rates and project year-end spend
   - Enable proactive cost management and corrective actions

3. FORECAST ACCURACY:
   - Assess historical forecasting performance by category
   - Recommend reforecast timing and magnitude
   - Improve future planning and budgeting processes

4. VARIANCE INVESTIGATION:
   - Prioritize significant variances requiring management attention
   - Provide investigation guidance and explanation prompts
   - Support variance explanation and documentation processes

💼 BUSINESS ACTIONS:
- Investigate high-priority variances and document explanations
- Adjust quarterly forecasts based on performance trends
- Implement corrective actions for budget overruns
- Improve forecasting accuracy through trend analysis

📊 SUCCESS METRICS TO MONITOR:
- Variance explanation completeness and timeliness
- Forecast accuracy improvement over time
- Budget adherence by business unit and category
- Financial planning and decision-making effectiveness
*/
