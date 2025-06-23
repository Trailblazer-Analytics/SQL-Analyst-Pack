-- ============================================================================
-- SALES PIPELINE PERFORMANCE ANALYSIS
-- Sales Analytics Scenario for SQL Analysts
-- ============================================================================

/*
📊 BUSINESS CONTEXT:
The VP of Sales needs a comprehensive analysis of the sales pipeline to 
understand conversion rates, identify bottlenecks, and optimize the sales 
process. The analysis will inform quarterly planning and territory allocation.

🎯 STAKEHOLDER: VP of Sales & Regional Sales Managers
📅 FREQUENCY: Monthly pipeline review, quarterly strategic planning
🎯 DECISION: Resource allocation, territory optimization, process improvements

🎯 BUSINESS REQUIREMENTS:
1. Pipeline stage conversion rates and velocity analysis
2. Sales rep performance vs targets and peer comparisons
3. Territory and product line performance analysis
4. Lead quality assessment and source effectiveness
5. Sales forecasting and quota attainment projections

📈 SUCCESS METRICS:
- Primary: Pipeline conversion rate, deal velocity, quota attainment
- Secondary: Lead quality scores, average deal size, win rate by source
- Leading Indicators: Pipeline coverage ratio, stage progression rates
*/

-- ============================================================================
-- DATA STRUCTURE OVERVIEW
-- ============================================================================

/*
Available Tables:
- leads: Lead generation and source information
- opportunities: Sales pipeline data with stage progression
- sales_reps: Sales team information, territories, and quotas
- customers: Customer information and history
- products: Product catalog and pricing information
- targets: Quarterly and annual sales targets by rep/territory
*/

-- ============================================================================
-- SECTION 1: PIPELINE HEALTH DASHBOARD
-- ============================================================================

-- 1.1 Current Pipeline Overview by Stage
SELECT 
    stage_name,
    COUNT(*) as opportunities_count,
    SUM(opportunity_value) as total_pipeline_value,
    ROUND(AVG(opportunity_value), 0) as avg_deal_size,
    ROUND(AVG(days_in_stage), 1) as avg_days_in_stage,
    
    -- Stage conversion rates (based on historical data)
    ROUND(
        COUNT(CASE WHEN stage_outcome = 'Won' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN stage_outcome IN ('Won', 'Lost') THEN 1 END), 0), 2
    ) as historical_conversion_rate,
    
    -- Pipeline progression analysis
    COUNT(CASE WHEN created_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_this_month,
    COUNT(CASE WHEN stage_entry_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as entered_this_week,
    
    -- Risk indicators
    COUNT(CASE WHEN days_in_stage > 45 THEN 1 END) as stalled_opportunities,
    COUNT(CASE WHEN close_date < CURRENT_DATE AND stage_name != 'Closed Won' THEN 1 END) as overdue_opportunities,
    
    -- Revenue potential
    SUM(opportunity_value * probability_to_close / 100) as weighted_pipeline_value

FROM opportunities o
WHERE stage_name != 'Closed Lost' 
  AND stage_name != 'Closed Won'
  AND created_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY stage_name
ORDER BY 
    CASE stage_name
        WHEN 'Lead' THEN 1
        WHEN 'Qualified' THEN 2
        WHEN 'Proposal' THEN 3
        WHEN 'Negotiation' THEN 4
        WHEN 'Verbal Commit' THEN 5
        ELSE 6
    END;

-- 1.2 Pipeline Conversion Funnel Analysis
WITH stage_progression AS (
    SELECT 
        'Lead' as stage_name, 1 as stage_order,
        COUNT(*) as opportunities_entering,
        COUNT(CASE WHEN final_outcome = 'Won' THEN 1 END) as eventually_won
    FROM opportunities 
    WHERE created_date >= CURRENT_DATE - INTERVAL '6 months'
    
    UNION ALL
    
    SELECT 
        'Qualified' as stage_name, 2 as stage_order,
        COUNT(*) as opportunities_entering,
        COUNT(CASE WHEN final_outcome = 'Won' THEN 1 END) as eventually_won
    FROM opportunities 
    WHERE stage_reached_qualified = 1
      AND created_date >= CURRENT_DATE - INTERVAL '6 months'
    
    UNION ALL
    
    SELECT 
        'Proposal' as stage_name, 3 as stage_order,
        COUNT(*) as opportunities_entering,
        COUNT(CASE WHEN final_outcome = 'Won' THEN 1 END) as eventually_won
    FROM opportunities 
    WHERE stage_reached_proposal = 1
      AND created_date >= CURRENT_DATE - INTERVAL '6 months'
    
    UNION ALL
    
    SELECT 
        'Negotiation' as stage_name, 4 as stage_order,
        COUNT(*) as opportunities_entering,
        COUNT(CASE WHEN final_outcome = 'Won' THEN 1 END) as eventually_won
    FROM opportunities 
    WHERE stage_reached_negotiation = 1
      AND created_date >= CURRENT_DATE - INTERVAL '6 months'
),
funnel_metrics AS (
    SELECT 
        stage_name,
        stage_order,
        opportunities_entering,
        eventually_won,
        LAG(opportunities_entering) OVER (ORDER BY stage_order) as prev_stage_count,
        
        -- Stage-to-stage conversion rate
        ROUND(
            opportunities_entering * 100.0 / 
            NULLIF(LAG(opportunities_entering) OVER (ORDER BY stage_order), 0), 2
        ) as stage_conversion_rate,
        
        -- Overall conversion rate from this stage
        ROUND(eventually_won * 100.0 / opportunities_entering, 2) as win_rate_from_stage,
        
        -- Drop-off analysis
        LAG(opportunities_entering) OVER (ORDER BY stage_order) - opportunities_entering as dropped_off
        
    FROM stage_progression
)
SELECT 
    stage_name,
    opportunities_entering,
    prev_stage_count,
    dropped_off,
    stage_conversion_rate,
    win_rate_from_stage,
    
    -- Funnel health indicators
    CASE 
        WHEN stage_conversion_rate >= 70 THEN '🟢 Healthy'
        WHEN stage_conversion_rate >= 50 THEN '🟡 Moderate'
        WHEN stage_conversion_rate >= 30 THEN '🟠 Concerning'
        ELSE '🔴 Critical'
    END as conversion_health,
    
    -- Optimization opportunities
    CASE 
        WHEN dropped_off > prev_stage_count * 0.5 THEN 'HIGH: Focus on conversion improvement'
        WHEN dropped_off > prev_stage_count * 0.3 THEN 'MEDIUM: Review process and training'
        ELSE 'LOW: Monitor for trends'
    END as optimization_priority

FROM funnel_metrics
WHERE stage_order > 1
ORDER BY stage_order;

-- ============================================================================
-- SECTION 2: SALES REP PERFORMANCE ANALYSIS
-- ============================================================================

-- 2.1 Rep Performance vs Quota and Peer Comparison
WITH rep_performance AS (
    SELECT 
        sr.sales_rep_id,
        sr.sales_rep_name,
        sr.territory,
        sr.hire_date,
        t.quarterly_quota,
        
        -- Current quarter performance (Q4 2024)
        SUM(CASE WHEN o.close_date BETWEEN '2024-10-01' AND '2024-12-31' 
                  AND o.stage_name = 'Closed Won' THEN o.opportunity_value ELSE 0 END) as q4_revenue,
        
        COUNT(CASE WHEN o.close_date BETWEEN '2024-10-01' AND '2024-12-31' 
                    AND o.stage_name = 'Closed Won' THEN 1 END) as q4_deals_won,
        
        -- Pipeline metrics
        COUNT(CASE WHEN o.stage_name NOT IN ('Closed Won', 'Closed Lost') THEN 1 END) as active_pipeline_count,
        SUM(CASE WHEN o.stage_name NOT IN ('Closed Won', 'Closed Lost') 
                 THEN o.opportunity_value * o.probability_to_close / 100 ELSE 0 END) as weighted_pipeline,
        
        -- Activity metrics
        AVG(o.opportunity_value) as avg_deal_size,
        ROUND(AVG(CASE WHEN o.stage_name = 'Closed Won' THEN o.days_to_close END), 1) as avg_sales_cycle,
        
        -- Win rate calculation
        ROUND(
            COUNT(CASE WHEN o.final_outcome = 'Won' THEN 1 END) * 100.0 / 
            NULLIF(COUNT(CASE WHEN o.final_outcome IN ('Won', 'Lost') THEN 1 END), 0), 2
        ) as overall_win_rate

    FROM sales_reps sr
    LEFT JOIN opportunities o ON sr.sales_rep_id = o.sales_rep_id
    LEFT JOIN targets t ON sr.sales_rep_id = t.sales_rep_id AND t.period = 'Q4-2024'
    WHERE sr.active = 1
      AND (o.created_date >= CURRENT_DATE - INTERVAL '12 months' OR o.opportunity_id IS NULL)
    GROUP BY sr.sales_rep_id, sr.sales_rep_name, sr.territory, sr.hire_date, t.quarterly_quota
),
performance_rankings AS (
    SELECT 
        *,
        -- Quota attainment
        ROUND(q4_revenue * 100.0 / NULLIF(quarterly_quota, 0), 1) as quota_attainment_pct,
        
        -- Peer rankings
        ROW_NUMBER() OVER (ORDER BY q4_revenue DESC) as revenue_rank,
        ROW_NUMBER() OVER (ORDER BY q4_revenue * 100.0 / NULLIF(quarterly_quota, 0) DESC) as quota_attainment_rank,
        ROW_NUMBER() OVER (ORDER BY overall_win_rate DESC) as win_rate_rank,
        
        -- Territory comparisons
        AVG(q4_revenue) OVER (PARTITION BY territory) as territory_avg_revenue,
        AVG(overall_win_rate) OVER (PARTITION BY territory) as territory_avg_win_rate,
        
        -- Experience factor
        CASE 
            WHEN hire_date >= CURRENT_DATE - INTERVAL '6 months' THEN 'New Rep (0-6 months)'
            WHEN hire_date >= CURRENT_DATE - INTERVAL '18 months' THEN 'Developing (6-18 months)'
            WHEN hire_date >= CURRENT_DATE - INTERVAL '36 months' THEN 'Experienced (1.5-3 years)'
            ELSE 'Veteran (3+ years)'
        END as experience_level
        
    FROM rep_performance
)
SELECT 
    sales_rep_name,
    territory,
    experience_level,
    quarterly_quota,
    q4_revenue,
    quota_attainment_pct,
    q4_deals_won,
    avg_deal_size,
    overall_win_rate,
    avg_sales_cycle,
    weighted_pipeline,
    
    -- Performance indicators
    CASE 
        WHEN quota_attainment_pct >= 100 THEN '🎯 Quota Achieved'
        WHEN quota_attainment_pct >= 90 THEN '🟢 On Track'
        WHEN quota_attainment_pct >= 70 THEN '🟡 Needs Support'
        ELSE '🔴 At Risk'
    END as performance_status,
    
    -- Ranking context
    CONCAT(revenue_rank, ' of ', COUNT(*) OVER(), ' (Revenue)') as revenue_ranking,
    CONCAT(win_rate_rank, ' of ', COUNT(*) OVER(), ' (Win Rate)') as win_rate_ranking,
    
    -- vs Territory average
    ROUND(q4_revenue - territory_avg_revenue, 0) as vs_territory_avg_revenue,
    ROUND(overall_win_rate - territory_avg_win_rate, 2) as vs_territory_avg_win_rate,
    
    -- Development recommendations
    CASE 
        WHEN quota_attainment_pct < 70 AND overall_win_rate < 20 THEN 'Focus: Lead qualification and closing skills'
        WHEN quota_attainment_pct < 70 AND avg_deal_size < territory_avg_revenue/4 THEN 'Focus: Upselling and deal value'
        WHEN quota_attainment_pct < 70 AND avg_sales_cycle > 90 THEN 'Focus: Sales process efficiency'
        WHEN quota_attainment_pct >= 90 THEN 'High performer - consider mentoring role'
        ELSE 'Monitor and provide standard support'
    END as development_recommendation

FROM performance_rankings
ORDER BY quota_attainment_pct DESC;

-- ============================================================================
-- SECTION 3: TERRITORY AND PRODUCT ANALYSIS
-- ============================================================================

-- 3.1 Territory Performance Analysis
SELECT 
    territory,
    COUNT(DISTINCT sales_rep_id) as rep_count,
    SUM(quarterly_quota) as territory_quota,
    
    -- Performance metrics
    SUM(q4_revenue) as territory_revenue,
    ROUND(SUM(q4_revenue) * 100.0 / SUM(quarterly_quota), 1) as territory_quota_attainment,
    SUM(q4_deals_won) as total_deals_won,
    ROUND(AVG(avg_deal_size), 0) as territory_avg_deal_size,
    ROUND(AVG(overall_win_rate), 2) as territory_avg_win_rate,
    
    -- Pipeline health
    SUM(weighted_pipeline) as territory_weighted_pipeline,
    ROUND(SUM(weighted_pipeline) / SUM(quarterly_quota), 2) as pipeline_coverage_ratio,
    
    -- Territory rankings
    ROW_NUMBER() OVER (ORDER BY SUM(q4_revenue) DESC) as revenue_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(q4_revenue) * 100.0 / SUM(quarterly_quota) DESC) as quota_attainment_rank,
    
    -- Performance indicators
    CASE 
        WHEN SUM(q4_revenue) * 100.0 / SUM(quarterly_quota) >= 100 THEN '🏆 Exceeding Quota'
        WHEN SUM(q4_revenue) * 100.0 / SUM(quarterly_quota) >= 90 THEN '🎯 On Target'
        WHEN SUM(q4_revenue) * 100.0 / SUM(quarterly_quota) >= 70 THEN '⚠️ Below Target'
        ELSE '🚨 Requires Intervention'
    END as territory_status,
    
    -- Resource allocation insights
    CASE 
        WHEN SUM(weighted_pipeline) / SUM(quarterly_quota) < 2 THEN 'URGENT: Insufficient pipeline'
        WHEN SUM(weighted_pipeline) / SUM(quarterly_quota) < 3 THEN 'CAUTION: Low pipeline coverage'
        WHEN SUM(weighted_pipeline) / SUM(quarterly_quota) > 5 THEN 'OPPORTUNITY: Strong pipeline'
        ELSE 'HEALTHY: Adequate pipeline coverage'
    END as pipeline_health_status

FROM (
    SELECT 
        sr.territory,
        sr.sales_rep_id,
        t.quarterly_quota,
        SUM(CASE WHEN o.close_date BETWEEN '2024-10-01' AND '2024-12-31' 
                  AND o.stage_name = 'Closed Won' THEN o.opportunity_value ELSE 0 END) as q4_revenue,
        COUNT(CASE WHEN o.close_date BETWEEN '2024-10-01' AND '2024-12-31' 
                    AND o.stage_name = 'Closed Won' THEN 1 END) as q4_deals_won,
        AVG(o.opportunity_value) as avg_deal_size,
        ROUND(
            COUNT(CASE WHEN o.final_outcome = 'Won' THEN 1 END) * 100.0 / 
            NULLIF(COUNT(CASE WHEN o.final_outcome IN ('Won', 'Lost') THEN 1 END), 0), 2
        ) as overall_win_rate,
        SUM(CASE WHEN o.stage_name NOT IN ('Closed Won', 'Closed Lost') 
                 THEN o.opportunity_value * o.probability_to_close / 100 ELSE 0 END) as weighted_pipeline
    FROM sales_reps sr
    LEFT JOIN opportunities o ON sr.sales_rep_id = o.sales_rep_id
    LEFT JOIN targets t ON sr.sales_rep_id = t.sales_rep_id AND t.period = 'Q4-2024'
    WHERE sr.active = 1
    GROUP BY sr.territory, sr.sales_rep_id, t.quarterly_quota
) territory_rollup
GROUP BY territory
ORDER BY territory_quota_attainment DESC;

-- ============================================================================
-- SECTION 4: SALES FORECASTING AND PROJECTIONS
-- ============================================================================

-- 4.1 Quarterly Sales Forecast
WITH pipeline_forecast AS (
    SELECT 
        stage_name,
        SUM(opportunity_value) as total_pipeline_value,
        SUM(opportunity_value * probability_to_close / 100) as weighted_value,
        COUNT(*) as opportunity_count,
        
        -- Expected close timing
        COUNT(CASE WHEN expected_close_date <= CURRENT_DATE + INTERVAL '30 days' THEN 1 END) as closing_next_30_days,
        COUNT(CASE WHEN expected_close_date <= CURRENT_DATE + INTERVAL '60 days' THEN 1 END) as closing_next_60_days,
        COUNT(CASE WHEN expected_close_date <= CURRENT_DATE + INTERVAL '90 days' THEN 1 END) as closing_next_90_days,
        
        -- Revenue projections
        SUM(CASE WHEN expected_close_date <= CURRENT_DATE + INTERVAL '30 days' 
                 THEN opportunity_value * probability_to_close / 100 ELSE 0 END) as revenue_next_30_days,
        SUM(CASE WHEN expected_close_date <= CURRENT_DATE + INTERVAL '60 days' 
                 THEN opportunity_value * probability_to_close / 100 ELSE 0 END) as revenue_next_60_days,
        SUM(CASE WHEN expected_close_date <= CURRENT_DATE + INTERVAL '90 days' 
                 THEN opportunity_value * probability_to_close / 100 ELSE 0 END) as revenue_next_90_days

    FROM opportunities 
    WHERE stage_name NOT IN ('Closed Won', 'Closed Lost')
      AND expected_close_date <= CURRENT_DATE + INTERVAL '90 days'
    GROUP BY stage_name
),
quota_tracking AS (
    SELECT 
        SUM(t.quarterly_quota) as total_quarterly_quota,
        SUM(CASE WHEN o.close_date BETWEEN '2024-10-01' AND CURRENT_DATE 
                  AND o.stage_name = 'Closed Won' THEN o.opportunity_value ELSE 0 END) as revenue_to_date,
        
        -- Days remaining in quarter
        CASE 
            WHEN CURRENT_DATE <= '2024-12-31' THEN ('2024-12-31'::DATE - CURRENT_DATE)
            ELSE 0
        END as days_remaining_in_quarter
        
    FROM targets t
    LEFT JOIN opportunities o ON t.sales_rep_id = o.sales_rep_id
    WHERE t.period = 'Q4-2024'
)
SELECT 
    'Q4 2024 Forecast Summary' as forecast_period,
    
    -- Current performance
    qt.total_quarterly_quota,
    qt.revenue_to_date,
    ROUND(qt.revenue_to_date * 100.0 / qt.total_quarterly_quota, 1) as quota_achievement_to_date,
    qt.days_remaining_in_quarter,
    
    -- Pipeline projections
    SUM(pf.revenue_next_30_days) as projected_revenue_30_days,
    SUM(pf.revenue_next_60_days) as projected_revenue_60_days,
    SUM(pf.revenue_next_90_days) as projected_revenue_90_days,
    
    -- Quota attainment projections
    ROUND((qt.revenue_to_date + SUM(pf.revenue_next_90_days)) * 100.0 / qt.total_quarterly_quota, 1) as projected_quota_attainment,
    
    -- Gap analysis
    qt.total_quarterly_quota - qt.revenue_to_date - SUM(pf.revenue_next_90_days) as revenue_gap,
    
    -- Forecast confidence
    CASE 
        WHEN (qt.revenue_to_date + SUM(pf.revenue_next_90_days)) >= qt.total_quarterly_quota * 1.1 THEN '🟢 High Confidence - Exceeding'
        WHEN (qt.revenue_to_date + SUM(pf.revenue_next_90_days)) >= qt.total_quarterly_quota THEN '🟢 High Confidence - Achieving'
        WHEN (qt.revenue_to_date + SUM(pf.revenue_next_90_days)) >= qt.total_quarterly_quota * 0.9 THEN '🟡 Moderate Confidence'
        ELSE '🔴 Low Confidence - At Risk'
    END as forecast_confidence,
    
    -- Recommended actions
    CASE 
        WHEN qt.total_quarterly_quota - qt.revenue_to_date - SUM(pf.revenue_next_90_days) > qt.total_quarterly_quota * 0.2 
        THEN 'URGENT: Accelerate pipeline conversion and add new opportunities'
        WHEN qt.total_quarterly_quota - qt.revenue_to_date - SUM(pf.revenue_next_90_days) > 0 
        THEN 'FOCUS: Push key deals in negotiation and proposal stages'
        ELSE 'MAINTAIN: Continue current activities and monitor execution'
    END as recommended_action

FROM pipeline_forecast pf
CROSS JOIN quota_tracking qt
GROUP BY 
    qt.total_quarterly_quota, 
    qt.revenue_to_date, 
    qt.days_remaining_in_quarter;

/*
🎯 KEY BUSINESS INSIGHTS:

1. PIPELINE HEALTH:
   - Overall conversion rates by stage identify process bottlenecks
   - Stage velocity analysis reveals sales cycle optimization opportunities
   - Pipeline coverage ratio indicates future quarter health

2. SALES REP PERFORMANCE:
   - Individual quota attainment and peer ranking for performance management
   - Win rate and deal size metrics for coaching and development
   - Territory performance comparison for resource allocation

3. TERRITORY OPTIMIZATION:
   - Geographic performance analysis for expansion planning
   - Resource allocation optimization based on pipeline health
   - Market opportunity assessment by region

4. FORECASTING ACCURACY:
   - Weighted pipeline projections for quarterly planning
   - Risk assessment and mitigation strategies
   - Revenue gap analysis for tactical adjustments

💼 BUSINESS ACTIONS:
- Identify top performers for best practice sharing
- Focus coaching on reps with conversion rate challenges
- Reallocate resources to high-opportunity territories
- Accelerate deals in late-stage pipeline for quarter close

📊 SUCCESS METRICS TO MONITOR:
- Pipeline velocity (stage progression speed)
- Conversion rates by stage and rep
- Quota attainment trends and forecasting accuracy
- Territory and product line performance indicators
*/
