/*
================================================================================
File: 03_advanced/09_business_reporting/03_financial_reporting_automation.sql
Topic: Automated Financial Reporting Systems
Purpose: Build automated monthly financial reports with variance analysis
Author: SQL Analyst Pack Community
Created: 2025-07-06
Database: Multi-platform compatible
================================================================================

FINANCIAL REPORTING AUTOMATION:
This script automates the monthly financial close process, providing
automated variance analysis, budget comparisons, and financial KPI tracking
that finance teams need for monthly board reports and management reviews.

TARGET USERS:
- CFO and Finance Directors
- Finance Analysts and Controllers
- Department Heads with budget responsibility
- Board members and executives

KEY FINANCIAL REPORTS:
- P&L variance analysis (Budget vs Actual)
- Cash flow summary and projections
- Department budget performance
- Financial KPI dashboard
- Automated alerts for significant variances
================================================================================
*/

-- ============================================================================
-- SECTION 1: MONTHLY P&L VARIANCE ANALYSIS
-- ============================================================================

-- Comprehensive Budget vs Actual Analysis
WITH monthly_actuals AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) as month,
        department,
        account_category,
        SUM(CASE WHEN transaction_type = 'Revenue' THEN amount ELSE 0 END) as actual_revenue,
        SUM(CASE WHEN transaction_type = 'Expense' THEN amount ELSE 0 END) as actual_expenses,
        SUM(CASE WHEN transaction_type = 'Revenue' THEN amount 
                 WHEN transaction_type = 'Expense' THEN -amount 
                 ELSE 0 END) as net_income
    FROM financial_transactions 
    WHERE EXTRACT(YEAR FROM transaction_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY DATE_TRUNC('month', transaction_date), department, account_category
),

budget_comparison AS (
    SELECT 
        b.month,
        b.department,
        b.account_category,
        b.budgeted_revenue,
        b.budgeted_expenses,
        COALESCE(a.actual_revenue, 0) as actual_revenue,
        COALESCE(a.actual_expenses, 0) as actual_expenses,
        COALESCE(a.net_income, 0) as actual_net_income,
        (b.budgeted_revenue - b.budgeted_expenses) as budgeted_net_income
    FROM budget_data b
    LEFT JOIN monthly_actuals a ON b.month = a.month 
                               AND b.department = a.department
                               AND b.account_category = a.account_category
    WHERE EXTRACT(YEAR FROM b.month) = EXTRACT(YEAR FROM CURRENT_DATE)
)

-- Executive Financial Dashboard
SELECT 
    '💰 MONTHLY FINANCIAL PERFORMANCE - ' || TO_CHAR(month, 'YYYY-MM') as report_title,
    department,
    account_category,
    
    -- Budget vs Actual
    budgeted_revenue,
    actual_revenue,
    budgeted_expenses,
    actual_expenses,
    budgeted_net_income,
    actual_net_income,
    
    -- Variance Analysis
    (actual_revenue - budgeted_revenue) as revenue_variance,
    (actual_expenses - budgeted_expenses) as expense_variance,
    (actual_net_income - budgeted_net_income) as net_income_variance,
    
    -- Percentage Variances
    CASE 
        WHEN budgeted_revenue > 0 THEN 
            ROUND((actual_revenue - budgeted_revenue) / budgeted_revenue * 100, 2)
        ELSE NULL 
    END as revenue_variance_pct,
    
    CASE 
        WHEN budgeted_expenses > 0 THEN 
            ROUND((actual_expenses - budgeted_expenses) / budgeted_expenses * 100, 2)
        ELSE NULL 
    END as expense_variance_pct,
    
    -- Performance Indicators
    CASE 
        WHEN actual_revenue >= budgeted_revenue * 1.05 THEN '🟢 REVENUE EXCEEDING'
        WHEN actual_revenue >= budgeted_revenue * 0.95 THEN '🟡 REVENUE ON TARGET'
        WHEN actual_revenue >= budgeted_revenue * 0.90 THEN '🟠 REVENUE BELOW TARGET'
        ELSE '🔴 REVENUE SIGNIFICANTLY LOW'
    END as revenue_performance,
    
    CASE 
        WHEN actual_expenses <= budgeted_expenses * 1.05 THEN '🟢 EXPENSES CONTROLLED'
        WHEN actual_expenses <= budgeted_expenses * 1.10 THEN '🟡 EXPENSES NEAR BUDGET'
        WHEN actual_expenses <= budgeted_expenses * 1.15 THEN '🟠 EXPENSES OVER BUDGET'
        ELSE '🔴 EXPENSES SIGNIFICANTLY OVER'
    END as expense_performance,
    
    -- Executive Actions Required
    CASE 
        WHEN ABS((actual_revenue - budgeted_revenue) / budgeted_revenue * 100) > 10 
             OR ABS((actual_expenses - budgeted_expenses) / budgeted_expenses * 100) > 10
        THEN '⚠️ REQUIRES EXECUTIVE REVIEW'
        WHEN ABS((actual_net_income - budgeted_net_income) / budgeted_net_income * 100) > 15
        THEN '🚨 CRITICAL VARIANCE - IMMEDIATE ACTION'
        ELSE '✅ WITHIN ACCEPTABLE RANGE'
    END as executive_action_flag

FROM budget_comparison
WHERE month >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '3 months'
ORDER BY month DESC, department, account_category;

-- ============================================================================
-- SECTION 2: CASH FLOW ANALYSIS AND PROJECTIONS
-- ============================================================================

-- Monthly Cash Flow Summary
WITH cash_flow_analysis AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) as month,
        
        -- Operating Cash Flow
        SUM(CASE WHEN cash_flow_category = 'Operating' AND amount > 0 THEN amount ELSE 0 END) as operating_inflows,
        SUM(CASE WHEN cash_flow_category = 'Operating' AND amount < 0 THEN ABS(amount) ELSE 0 END) as operating_outflows,
        
        -- Investment Cash Flow  
        SUM(CASE WHEN cash_flow_category = 'Investment' AND amount > 0 THEN amount ELSE 0 END) as investment_inflows,
        SUM(CASE WHEN cash_flow_category = 'Investment' AND amount < 0 THEN ABS(amount) ELSE 0 END) as investment_outflows,
        
        -- Financing Cash Flow
        SUM(CASE WHEN cash_flow_category = 'Financing' AND amount > 0 THEN amount ELSE 0 END) as financing_inflows,
        SUM(CASE WHEN cash_flow_category = 'Financing' AND amount < 0 THEN ABS(amount) ELSE 0 END) as financing_outflows
        
    FROM cash_flow_transactions 
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', transaction_date)
),

cash_flow_summary AS (
    SELECT *,
        (operating_inflows - operating_outflows) as net_operating_cash_flow,
        (investment_inflows - investment_outflows) as net_investment_cash_flow,
        (financing_inflows - financing_outflows) as net_financing_cash_flow,
        
        -- Running cash balance
        SUM((operating_inflows - operating_outflows) + 
            (investment_inflows - investment_outflows) + 
            (financing_inflows - financing_outflows)) 
        OVER (ORDER BY month) as cumulative_cash_flow
    FROM cash_flow_analysis
)

SELECT 
    '💸 CASH FLOW DASHBOARD - ' || TO_CHAR(month, 'YYYY-MM') as cash_flow_report,
    month,
    
    -- Operating Activities
    operating_inflows,
    operating_outflows,
    net_operating_cash_flow,
    
    -- Investment Activities
    investment_inflows,
    investment_outflows,
    net_investment_cash_flow,
    
    -- Financing Activities
    financing_inflows,
    financing_outflows,
    net_financing_cash_flow,
    
    -- Overall Cash Position
    (net_operating_cash_flow + net_investment_cash_flow + net_financing_cash_flow) as net_cash_flow,
    cumulative_cash_flow,
    
    -- Cash Flow Health Indicators
    CASE 
        WHEN net_operating_cash_flow > 0 AND cumulative_cash_flow > 0 THEN '🟢 STRONG CASH POSITION'
        WHEN net_operating_cash_flow > 0 AND cumulative_cash_flow <= 0 THEN '🟡 POSITIVE OPERATIONS, LOW RESERVES'
        WHEN net_operating_cash_flow <= 0 AND cumulative_cash_flow > 0 THEN '🟠 BURNING CASH, ADEQUATE RESERVES'
        ELSE '🔴 CRITICAL CASH SITUATION'
    END as cash_flow_health,
    
    -- Liquidity Warnings
    CASE 
        WHEN cumulative_cash_flow < 50000 THEN '🚨 LOW CASH RESERVES'
        WHEN net_operating_cash_flow < 0 AND month >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 months'
        THEN '⚠️ NEGATIVE OPERATING CASH FLOW'
        ELSE '✅ ADEQUATE LIQUIDITY'
    END as liquidity_alert

FROM cash_flow_summary
ORDER BY month DESC;

-- ============================================================================
-- SECTION 3: DEPARTMENTAL BUDGET PERFORMANCE TRACKING
-- ============================================================================

-- Department Budget Performance Dashboard
WITH dept_performance AS (
    SELECT 
        department,
        SUM(CASE WHEN EXTRACT(MONTH FROM month) <= EXTRACT(MONTH FROM CURRENT_DATE)
                 THEN budgeted_expenses ELSE 0 END) as ytd_budget,
        SUM(CASE WHEN EXTRACT(MONTH FROM month) <= EXTRACT(MONTH FROM CURRENT_DATE)
                 THEN actual_expenses ELSE 0 END) as ytd_actual,
        SUM(budgeted_expenses) as annual_budget,
        
        -- Current month performance
        SUM(CASE WHEN month = DATE_TRUNC('month', CURRENT_DATE)
                 THEN budgeted_expenses ELSE 0 END) as current_month_budget,
        SUM(CASE WHEN month = DATE_TRUNC('month', CURRENT_DATE)
                 THEN actual_expenses ELSE 0 END) as current_month_actual
    FROM budget_comparison
    WHERE EXTRACT(YEAR FROM month) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY department
)

SELECT 
    '🏢 DEPARTMENTAL BUDGET PERFORMANCE' as performance_dashboard,
    department,
    
    -- Budget vs Actual YTD
    ytd_budget,
    ytd_actual,
    (ytd_actual - ytd_budget) as ytd_variance,
    ROUND((ytd_actual - ytd_budget) / ytd_budget * 100, 2) as ytd_variance_pct,
    
    -- Current Month
    current_month_budget,
    current_month_actual,
    (current_month_actual - current_month_budget) as current_month_variance,
    
    -- Projected Annual Performance
    annual_budget,
    ROUND(ytd_actual / (EXTRACT(MONTH FROM CURRENT_DATE) / 12.0), 0) as projected_annual_actual,
    
    -- Performance Ratings
    CASE 
        WHEN ABS((ytd_actual - ytd_budget) / ytd_budget * 100) <= 5 THEN '🟢 ON BUDGET'
        WHEN (ytd_actual - ytd_budget) / ytd_budget * 100 BETWEEN 5 AND 10 THEN '🟡 SLIGHTLY OVER'
        WHEN (ytd_actual - ytd_budget) / ytd_budget * 100 > 10 THEN '🔴 SIGNIFICANTLY OVER'
        WHEN (ytd_actual - ytd_budget) / ytd_budget * 100 BETWEEN -10 AND -5 THEN '🟡 UNDER BUDGET'
        ELSE '🟢 WELL UNDER BUDGET'
    END as budget_performance_rating,
    
    -- Management Actions
    CASE 
        WHEN (ytd_actual - ytd_budget) / ytd_budget * 100 > 15 
        THEN '🚨 BUDGET REVIEW REQUIRED'
        WHEN (ytd_actual - ytd_budget) / ytd_budget * 100 > 10 
        THEN '⚠️ MONITORING NEEDED'
        WHEN (ytd_actual - ytd_budget) / ytd_budget * 100 < -20 
        THEN '💡 REALLOCATION OPPORTUNITY'
        ELSE '✅ CONTINUE CURRENT APPROACH'
    END as recommended_action

FROM dept_performance
ORDER BY ABS((ytd_actual - ytd_budget) / ytd_budget * 100) DESC;

-- ============================================================================
-- SECTION 4: FINANCIAL KPI AUTOMATION
-- ============================================================================

-- Executive Financial KPI Dashboard
WITH financial_kpis AS (
    SELECT 
        -- Profitability Metrics
        SUM(CASE WHEN transaction_type = 'Revenue' THEN amount ELSE 0 END) as total_revenue,
        SUM(CASE WHEN transaction_type = 'Expense' THEN amount ELSE 0 END) as total_expenses,
        SUM(CASE WHEN transaction_type = 'Revenue' THEN amount 
                 WHEN transaction_type = 'Expense' THEN -amount ELSE 0 END) as net_income,
        
        -- Growth Metrics (vs same period last year)
        SUM(CASE WHEN transaction_type = 'Revenue' 
                 AND EXTRACT(YEAR FROM transaction_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
                 THEN amount ELSE 0 END) as last_year_revenue,
        
        -- Efficiency Metrics
        COUNT(DISTINCT EXTRACT(MONTH FROM transaction_date)) as months_of_data,
        COUNT(DISTINCT department) as active_departments
        
    FROM financial_transactions 
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '24 months'
)

SELECT 
    '📊 EXECUTIVE FINANCIAL KPI DASHBOARD' as kpi_dashboard,
    
    -- Core Financial Metrics
    total_revenue,
    total_expenses,
    net_income,
    ROUND(net_income / total_revenue * 100, 2) as net_margin_pct,
    
    -- Growth Analysis
    last_year_revenue,
    ROUND((total_revenue - last_year_revenue) / last_year_revenue * 100, 2) as revenue_growth_yoy_pct,
    
    -- Operational Efficiency
    ROUND(total_revenue / months_of_data, 0) as avg_monthly_revenue,
    ROUND(total_expenses / months_of_data, 0) as avg_monthly_expenses,
    ROUND(total_revenue / active_departments, 0) as revenue_per_department,
    
    -- Financial Health Indicators
    CASE 
        WHEN net_income / total_revenue > 0.15 THEN '🟢 EXCELLENT PROFITABILITY'
        WHEN net_income / total_revenue > 0.10 THEN '🟡 GOOD PROFITABILITY'
        WHEN net_income / total_revenue > 0.05 THEN '🟠 MODERATE PROFITABILITY'
        WHEN net_income > 0 THEN '🟡 BREAK-EVEN PLUS'
        ELSE '🔴 LOSS MAKING'
    END as profitability_status,
    
    CASE 
        WHEN (total_revenue - last_year_revenue) / last_year_revenue > 0.20 THEN '🟢 STRONG GROWTH'
        WHEN (total_revenue - last_year_revenue) / last_year_revenue > 0.10 THEN '🟡 MODERATE GROWTH'
        WHEN (total_revenue - last_year_revenue) / last_year_revenue > 0 THEN '🟠 SLOW GROWTH'
        ELSE '🔴 DECLINING REVENUE'
    END as growth_status,
    
    -- Strategic Recommendations
    CASE 
        WHEN net_income / total_revenue < 0.05 AND 
             (total_revenue - last_year_revenue) / last_year_revenue < 0.05
        THEN '🚨 URGENT: REVIEW COST STRUCTURE AND GROWTH STRATEGY'
        WHEN net_income / total_revenue > 0.15 AND 
             (total_revenue - last_year_revenue) / last_year_revenue > 0.15
        THEN '💡 OPPORTUNITY: CONSIDER STRATEGIC INVESTMENTS'
        WHEN net_income / total_revenue < 0.10
        THEN '⚠️ FOCUS: IMPROVE OPERATIONAL EFFICIENCY'
        ELSE '✅ MAINTAIN: CURRENT PERFORMANCE IS SOLID'
    END as strategic_recommendation

FROM financial_kpis;

/*
================================================================================
AUTOMATION SETUP INSTRUCTIONS:
================================================================================

RECOMMENDED SCHEDULE:
- Daily: Cash flow monitoring queries
- Weekly: Department budget performance
- Monthly: Full P&L variance analysis and KPI dashboard
- Quarterly: Strategic recommendations review

ALERT THRESHOLDS (Customize for your business):
- Revenue variance > ±10%: Executive notification
- Expense variance > +15%: Department head review
- Cash flow negative for 2+ months: CFO alert
- Net margin < 5%: Board attention required

INTEGRATION NOTES:
- Export results to Excel for board presentations
- Set up email alerts for critical variances
- Create dashboard views for real-time monitoring
- Archive monthly reports for audit trails

CUSTOMIZATION CHECKLIST:
□ Update table names for your schema
□ Adjust variance thresholds for your business
□ Add industry-specific KPIs
□ Configure automated email delivery
□ Set up dashboard refresh schedules
================================================================================
*/
