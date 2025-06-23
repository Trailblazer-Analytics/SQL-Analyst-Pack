-- =====================================================
-- 03. Healthcare Analytics Capstone
-- =====================================================
-- 
-- EXPERT-LEVEL CHALLENGE: Comprehensive healthcare 
-- analytics platform for patient outcomes, operational
-- efficiency, and regulatory compliance.
-- 
-- Business Context:
-- As a Senior Data Analyst at MediCore Health Systems,
-- you're building an integrated analytics platform that
-- combines patient data, operational metrics, and
-- financial performance to drive evidence-based
-- healthcare decisions and ensure regulatory compliance.
-- 
-- Success Criteria:
-- • Patient outcome prediction with 85%+ accuracy
-- • Cost reduction identification of $2M+ annually
-- • HIPAA compliance score of 95%+
-- • Population health insights for 100K+ patients
-- • Operational efficiency improvements of 15%+
-- 
-- Technical Requirements:
-- • Advanced statistical modeling
-- • Time-series forecasting
-- • Survival analysis techniques
-- • Multi-dimensional data integration
-- • Real-time alerting systems
-- =====================================================

-- =====================================================
-- Challenge 1: Patient Outcome Prediction Model
-- =====================================================

-- Build a comprehensive patient risk stratification system
-- that predicts readmission risk, mortality, and complications

WITH patient_demographics AS (
    SELECT 
        patient_id,
        age,
        gender,
        race_ethnicity,
        insurance_type,
        zip_code,
        socioeconomic_score
    FROM patients.demographics
),
clinical_history AS (
    SELECT 
        patient_id,
        diagnosis_code,
        diagnosis_description,
        chronic_condition_count,
        comorbidity_score,
        medication_count,
        allergy_count,
        previous_admissions_12m,
        last_admission_date
    FROM patients.clinical_data
),
admission_details AS (
    SELECT 
        admission_id,
        patient_id,
        admission_date,
        discharge_date,
        length_of_stay_days,
        admission_type, -- Emergency, Elective, Urgent
        primary_diagnosis,
        secondary_diagnoses,
        procedures_performed,
        icu_stay_hours,
        complications_occurred,
        discharge_disposition
    FROM admissions.episodes
    WHERE admission_date >= '2023-01-01'
),
vital_signs AS (
    SELECT 
        patient_id,
        admission_id,
        measurement_datetime,
        systolic_bp,
        diastolic_bp,
        heart_rate,
        temperature,
        oxygen_saturation,
        respiratory_rate,
        blood_glucose,
        -- Calculate stability scores
        CASE 
            WHEN systolic_bp BETWEEN 90 AND 140 
             AND diastolic_bp BETWEEN 60 AND 90 
             AND heart_rate BETWEEN 60 AND 100
            THEN 1 ELSE 0 
        END as vitals_stable
    FROM clinical.vital_signs
    WHERE measurement_datetime >= '2023-01-01'
),
lab_results AS (
    SELECT 
        patient_id,
        admission_id,
        test_date,
        white_blood_cell_count,
        hemoglobin,
        platelet_count,
        creatinine,
        blood_urea_nitrogen,
        sodium,
        potassium,
        glucose,
        -- Calculate abnormal lab flags
        CASE 
            WHEN creatinine > 1.2 OR blood_urea_nitrogen > 20 THEN 1 ELSE 0 
        END as kidney_function_abnormal,
        CASE 
            WHEN white_blood_cell_count > 11000 OR white_blood_cell_count < 4000 THEN 1 ELSE 0 
        END as infection_indicator
    FROM clinical.laboratory_results
    WHERE test_date >= '2023-01-01'
),
-- Create comprehensive patient risk features
risk_features AS (
    SELECT 
        a.patient_id,
        a.admission_id,
        pd.age,
        pd.gender,
        pd.insurance_type,
        pd.socioeconomic_score,
        ch.chronic_condition_count,
        ch.comorbidity_score,
        ch.previous_admissions_12m,
        a.admission_type,
        a.length_of_stay_days,
        a.icu_stay_hours,
        -- Vital signs stability
        AVG(vs.vitals_stable) as vitals_stability_score,
        -- Lab abnormalities
        MAX(lr.kidney_function_abnormal) as has_kidney_dysfunction,
        MAX(lr.infection_indicator) as has_infection_signs,
        -- Calculate risk scores
        CASE 
            WHEN pd.age >= 75 THEN 25
            WHEN pd.age >= 65 THEN 15
            WHEN pd.age >= 55 THEN 10
            ELSE 0
        END as age_risk_score,
        CASE 
            WHEN ch.chronic_condition_count >= 5 THEN 30
            WHEN ch.chronic_condition_count >= 3 THEN 20
            WHEN ch.chronic_condition_count >= 1 THEN 10
            ELSE 0
        END as comorbidity_risk_score,
        CASE 
            WHEN a.admission_type = 'Emergency' THEN 20
            WHEN a.admission_type = 'Urgent' THEN 10
            ELSE 0
        END as admission_urgency_score,
        CASE 
            WHEN a.icu_stay_hours > 0 THEN 25
            ELSE 0
        END as icu_risk_score
    FROM admission_details a
    JOIN patient_demographics pd ON a.patient_id = pd.patient_id
    JOIN clinical_history ch ON a.patient_id = ch.patient_id
    LEFT JOIN vital_signs vs ON a.admission_id = vs.admission_id
    LEFT JOIN lab_results lr ON a.admission_id = lr.admission_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
),
-- Calculate final risk predictions
patient_risk_model AS (
    SELECT 
        patient_id,
        admission_id,
        age,
        gender,
        insurance_type,
        chronic_condition_count,
        previous_admissions_12m,
        length_of_stay_days,
        icu_stay_hours,
        vitals_stability_score,
        has_kidney_dysfunction,
        has_infection_signs,
        -- Calculate composite risk score
        age_risk_score + 
        comorbidity_risk_score + 
        admission_urgency_score + 
        icu_risk_score +
        CASE WHEN has_kidney_dysfunction = 1 THEN 15 ELSE 0 END +
        CASE WHEN has_infection_signs = 1 THEN 10 ELSE 0 END +
        CASE WHEN vitals_stability_score < 0.8 THEN 15 ELSE 0 END as total_risk_score,
        -- Predict outcomes
        CASE 
            WHEN age_risk_score + comorbidity_risk_score + admission_urgency_score + icu_risk_score >= 70 
            THEN 'HIGH_RISK'
            WHEN age_risk_score + comorbidity_risk_score + admission_urgency_score + icu_risk_score >= 40 
            THEN 'MEDIUM_RISK'
            ELSE 'LOW_RISK'
        END as readmission_risk_category,
        -- Calculate specific risk probabilities (simplified model)
        CASE 
            WHEN age >= 75 AND chronic_condition_count >= 3 AND icu_stay_hours > 0 THEN 0.35
            WHEN age >= 65 AND chronic_condition_count >= 2 THEN 0.25
            WHEN previous_admissions_12m >= 2 THEN 0.30
            WHEN has_kidney_dysfunction = 1 AND has_infection_signs = 1 THEN 0.40
            ELSE 0.10
        END as readmission_probability,
        CASE 
            WHEN age >= 80 AND icu_stay_hours > 72 THEN 0.15
            WHEN age >= 75 AND has_infection_signs = 1 THEN 0.10
            WHEN chronic_condition_count >= 5 THEN 0.08
            ELSE 0.02
        END as mortality_risk_probability
    FROM risk_features
)
SELECT 
    patient_id,
    admission_id,
    age,
    gender,
    chronic_condition_count,
    total_risk_score,
    readmission_risk_category,
    ROUND(readmission_probability * 100, 1) as readmission_risk_pct,
    ROUND(mortality_risk_probability * 100, 1) as mortality_risk_pct,
    -- Clinical recommendations
    CASE 
        WHEN readmission_probability >= 0.3 THEN 'INTENSIVE_DISCHARGE_PLANNING'
        WHEN readmission_probability >= 0.2 THEN 'ENHANCED_FOLLOW_UP'
        WHEN readmission_probability >= 0.15 THEN 'STANDARD_PLUS_MONITORING'
        ELSE 'STANDARD_CARE'
    END as care_recommendation,
    -- Resource allocation
    CASE 
        WHEN mortality_risk_probability >= 0.1 THEN 'PALLIATIVE_CARE_CONSULT'
        WHEN readmission_probability >= 0.25 THEN 'CASE_MANAGEMENT'
        WHEN total_risk_score >= 60 THEN 'CARE_COORDINATION'
        ELSE 'ROUTINE_FOLLOW_UP'
    END as resource_allocation
FROM patient_risk_model
ORDER BY total_risk_score DESC, readmission_probability DESC;

-- =====================================================
-- Challenge 2: Population Health Analytics
-- =====================================================

-- Analyze population health trends and identify intervention opportunities
-- for chronic disease management and preventive care

WITH population_demographics AS (
    SELECT 
        zip_code,
        age_group,
        gender,
        race_ethnicity,
        insurance_type,
        COUNT(*) as patient_count,
        AVG(socioeconomic_score) as avg_socioeconomic_score
    FROM patients.demographics
    GROUP BY 1, 2, 3, 4, 5
),
chronic_disease_prevalence AS (
    SELECT 
        pd.zip_code,
        pd.age_group,
        COUNT(DISTINCT pd.patient_id) as total_patients,
        COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'E11%' THEN pd.patient_id END) as diabetes_patients,
        COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'I10%' THEN pd.patient_id END) as hypertension_patients,
        COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'E78%' THEN pd.patient_id END) as dyslipidemia_patients,
        COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'J44%' THEN pd.patient_id END) as copd_patients,
        COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'F32%' OR cd.diagnosis_code LIKE 'F33%' THEN pd.patient_id END) as depression_patients,
        -- Calculate prevalence rates
        ROUND(COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'E11%' THEN pd.patient_id END) * 100.0 / COUNT(DISTINCT pd.patient_id), 2) as diabetes_prevalence_pct,
        ROUND(COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'I10%' THEN pd.patient_id END) * 100.0 / COUNT(DISTINCT pd.patient_id), 2) as hypertension_prevalence_pct,
        ROUND(COUNT(DISTINCT CASE WHEN cd.diagnosis_code LIKE 'E78%' THEN pd.patient_id END) * 100.0 / COUNT(DISTINCT pd.patient_id), 2) as dyslipidemia_prevalence_pct
    FROM patients.demographics pd
    LEFT JOIN patients.clinical_data cd ON pd.patient_id = cd.patient_id
    GROUP BY 1, 2
),
preventive_care_gaps AS (
    SELECT 
        pd.patient_id,
        pd.age,
        pd.gender,
        pd.zip_code,
        -- Check for preventive screenings
        MAX(CASE WHEN ps.screening_type = 'MAMMOGRAPHY' AND ps.screening_date >= DATE_SUB(CURRENT_DATE, INTERVAL 2 YEAR) THEN 1 ELSE 0 END) as mammography_current,
        MAX(CASE WHEN ps.screening_type = 'COLONOSCOPY' AND ps.screening_date >= DATE_SUB(CURRENT_DATE, INTERVAL 10 YEAR) THEN 1 ELSE 0 END) as colonoscopy_current,
        MAX(CASE WHEN ps.screening_type = 'CERVICAL_CANCER' AND ps.screening_date >= DATE_SUB(CURRENT_DATE, INTERVAL 3 YEAR) THEN 1 ELSE 0 END) as cervical_screening_current,
        MAX(CASE WHEN ps.screening_type = 'BONE_DENSITY' AND ps.screening_date >= DATE_SUB(CURRENT_DATE, INTERVAL 2 YEAR) THEN 1 ELSE 0 END) as bone_density_current,
        -- Check for chronic disease monitoring
        MAX(CASE WHEN cd.diagnosis_code LIKE 'E11%' THEN 1 ELSE 0 END) as has_diabetes,
        MAX(CASE WHEN ps.screening_type = 'HBA1C' AND ps.screening_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH) THEN 1 ELSE 0 END) as diabetes_monitoring_current
    FROM patients.demographics pd
    LEFT JOIN patients.preventive_screenings ps ON pd.patient_id = ps.patient_id
    LEFT JOIN patients.clinical_data cd ON pd.patient_id = cd.patient_id
    GROUP BY 1, 2, 3, 4
),
care_gap_analysis AS (
    SELECT 
        zip_code,
        COUNT(*) as total_eligible_patients,
        -- Preventive care gaps
        COUNT(CASE WHEN gender = 'F' AND age BETWEEN 50 AND 74 AND mammography_current = 0 THEN 1 END) as mammography_gaps,
        COUNT(CASE WHEN age BETWEEN 50 AND 75 AND colonoscopy_current = 0 THEN 1 END) as colonoscopy_gaps,
        COUNT(CASE WHEN gender = 'F' AND age BETWEEN 21 AND 65 AND cervical_screening_current = 0 THEN 1 END) as cervical_screening_gaps,
        COUNT(CASE WHEN gender = 'F' AND age >= 65 AND bone_density_current = 0 THEN 1 END) as bone_density_gaps,
        -- Chronic disease monitoring gaps
        COUNT(CASE WHEN has_diabetes = 1 AND diabetes_monitoring_current = 0 THEN 1 END) as diabetes_monitoring_gaps,
        -- Calculate gap percentages
        ROUND(COUNT(CASE WHEN gender = 'F' AND age BETWEEN 50 AND 74 AND mammography_current = 0 THEN 1 END) * 100.0 / 
              NULLIF(COUNT(CASE WHEN gender = 'F' AND age BETWEEN 50 AND 74 THEN 1 END), 0), 2) as mammography_gap_pct,
        ROUND(COUNT(CASE WHEN age BETWEEN 50 AND 75 AND colonoscopy_current = 0 THEN 1 END) * 100.0 / 
              NULLIF(COUNT(CASE WHEN age BETWEEN 50 AND 75 THEN 1 END), 0), 2) as colonoscopy_gap_pct
    FROM preventive_care_gaps
    GROUP BY 1
),
population_health_priorities AS (
    SELECT 
        cdp.zip_code,
        cdp.total_patients,
        cdp.diabetes_prevalence_pct,
        cdp.hypertension_prevalence_pct,
        cdp.dyslipidemia_prevalence_pct,
        cga.mammography_gap_pct,
        cga.colonoscopy_gap_pct,
        cga.diabetes_monitoring_gaps,
        -- Calculate intervention priority scores
        CASE 
            WHEN cdp.diabetes_prevalence_pct > 15 THEN 30
            WHEN cdp.diabetes_prevalence_pct > 10 THEN 20
            WHEN cdp.diabetes_prevalence_pct > 8 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN cga.mammography_gap_pct > 40 THEN 25
            WHEN cga.mammography_gap_pct > 25 THEN 15
            WHEN cga.mammography_gap_pct > 15 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN cga.colonoscopy_gap_pct > 50 THEN 20
            WHEN cga.colonoscopy_gap_pct > 35 THEN 15
            WHEN cga.colonoscopy_gap_pct > 20 THEN 10
            ELSE 0
        END as intervention_priority_score
    FROM chronic_disease_prevalence cdp
    LEFT JOIN care_gap_analysis cga ON cdp.zip_code = cga.zip_code
    WHERE cdp.age_group = 'ADULT' -- Focus on adult population
)
SELECT 
    zip_code,
    total_patients,
    diabetes_prevalence_pct,
    hypertension_prevalence_pct,
    mammography_gap_pct,
    colonoscopy_gap_pct,
    diabetes_monitoring_gaps,
    intervention_priority_score,
    -- Specific intervention recommendations
    CASE 
        WHEN diabetes_prevalence_pct > 15 AND diabetes_monitoring_gaps > 100 THEN 'DIABETES_MANAGEMENT_PROGRAM'
        WHEN mammography_gap_pct > 40 THEN 'BREAST_CANCER_SCREENING_OUTREACH'
        WHEN colonoscopy_gap_pct > 50 THEN 'COLORECTAL_SCREENING_CAMPAIGN'
        WHEN hypertension_prevalence_pct > 30 THEN 'HYPERTENSION_MONITORING_PROGRAM'
        ELSE 'ROUTINE_HEALTH_PROMOTION'
    END as recommended_intervention,
    -- Resource allocation
    CASE 
        WHEN intervention_priority_score >= 60 THEN 'HIGH_PRIORITY_FUNDING'
        WHEN intervention_priority_score >= 40 THEN 'MODERATE_FUNDING'
        WHEN intervention_priority_score >= 20 THEN 'STANDARD_FUNDING'
        ELSE 'BASIC_HEALTH_PROMOTION'
    END as funding_recommendation
FROM population_health_priorities
ORDER BY intervention_priority_score DESC;

-- =====================================================
-- Challenge 3: Operational Efficiency Analysis
-- =====================================================

-- Optimize hospital operations, resource utilization, and cost management
-- while maintaining quality of care standards

WITH bed_utilization AS (
    SELECT 
        DATE(admission_date) as service_date,
        ward_type,
        bed_type,
        COUNT(*) as daily_admissions,
        AVG(length_of_stay_days) as avg_los,
        SUM(length_of_stay_days) as total_bed_days,
        -- Calculate occupancy rates
        total_bed_days / available_beds as occupancy_rate
    FROM admissions.episodes e
    JOIN facility.bed_inventory b ON e.ward_id = b.ward_id
    WHERE admission_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY 1, 2, 3
),
staffing_efficiency AS (
    SELECT 
        service_date,
        department,
        shift_type,
        COUNT(DISTINCT staff_id) as staff_count,
        SUM(hours_worked) as total_hours_worked,
        SUM(patient_encounters) as total_encounters,
        SUM(overtime_hours) as total_overtime,
        -- Calculate efficiency metrics
        SUM(patient_encounters) / SUM(hours_worked) as encounters_per_hour,
        SUM(overtime_hours) / SUM(hours_worked) as overtime_rate
    FROM operations.staffing_log
    WHERE service_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY 1, 2, 3
),
equipment_utilization AS (
    SELECT 
        equipment_type,
        department,
        COUNT(*) as total_bookings,
        SUM(usage_hours) as total_usage_hours,
        SUM(maintenance_hours) as total_maintenance_hours,
        AVG(utilization_rate) as avg_utilization_rate,
        SUM(revenue_generated) as total_revenue,
        SUM(operating_costs) as total_costs
    FROM operations.equipment_usage
    WHERE usage_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY 1, 2
),
cost_center_analysis AS (
    SELECT 
        department,
        cost_category,
        SUM(actual_cost) as total_actual_cost,
        SUM(budgeted_cost) as total_budgeted_cost,
        SUM(actual_cost) - SUM(budgeted_cost) as cost_variance,
        (SUM(actual_cost) - SUM(budgeted_cost)) / NULLIF(SUM(budgeted_cost), 0) * 100 as variance_percentage
    FROM finance.cost_centers
    WHERE fiscal_period >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY 1, 2
),
quality_metrics AS (
    SELECT 
        department,
        COUNT(*) as total_cases,
        COUNT(CASE WHEN patient_satisfaction_score >= 4 THEN 1 END) as satisfied_patients,
        COUNT(CASE WHEN readmission_30_days = 1 THEN 1 END) as readmissions,
        COUNT(CASE WHEN hospital_acquired_infection = 1 THEN 1 END) as infections,
        COUNT(CASE WHEN medication_error = 1 THEN 1 END) as medication_errors,
        -- Calculate quality scores
        COUNT(CASE WHEN patient_satisfaction_score >= 4 THEN 1 END) * 100.0 / COUNT(*) as satisfaction_rate,
        COUNT(CASE WHEN readmission_30_days = 1 THEN 1 END) * 100.0 / COUNT(*) as readmission_rate,
        COUNT(CASE WHEN hospital_acquired_infection = 1 THEN 1 END) * 100.0 / COUNT(*) as infection_rate
    FROM quality.patient_outcomes
    WHERE discharge_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY 1
),
operational_dashboard AS (
    SELECT 
        bu.ward_type,
        bu.avg_los,
        bu.occupancy_rate,
        se.encounters_per_hour,
        se.overtime_rate,
        eu.avg_utilization_rate,
        eu.total_revenue - eu.total_costs as equipment_net_revenue,
        cca.variance_percentage as cost_variance_pct,
        qm.satisfaction_rate,
        qm.readmission_rate,
        qm.infection_rate,
        -- Calculate operational efficiency score
        CASE 
            WHEN bu.occupancy_rate BETWEEN 0.85 AND 0.95 THEN 20 ELSE 10
        END +
        CASE 
            WHEN se.overtime_rate < 0.05 THEN 15 ELSE 5
        END +
        CASE 
            WHEN eu.avg_utilization_rate > 0.80 THEN 15 ELSE 10
        END +
        CASE 
            WHEN ABS(cca.variance_percentage) < 5 THEN 20 ELSE 10
        END +
        CASE 
            WHEN qm.satisfaction_rate > 90 THEN 15 ELSE 10
        END +
        CASE 
            WHEN qm.readmission_rate < 10 THEN 15 ELSE 5
        END as efficiency_score
    FROM bed_utilization bu
    LEFT JOIN staffing_efficiency se ON bu.service_date = se.service_date
    LEFT JOIN equipment_utilization eu ON bu.ward_type = eu.department
    LEFT JOIN cost_center_analysis cca ON bu.ward_type = cca.department
    LEFT JOIN quality_metrics qm ON bu.ward_type = qm.department
)
SELECT 
    ward_type,
    ROUND(avg_los, 1) as avg_length_of_stay,
    ROUND(occupancy_rate * 100, 1) as occupancy_rate_pct,
    ROUND(encounters_per_hour, 2) as encounters_per_hour,
    ROUND(overtime_rate * 100, 1) as overtime_rate_pct,
    ROUND(avg_utilization_rate * 100, 1) as equipment_utilization_pct,
    equipment_net_revenue,
    ROUND(cost_variance_pct, 1) as budget_variance_pct,
    ROUND(satisfaction_rate, 1) as patient_satisfaction_pct,
    ROUND(readmission_rate, 1) as readmission_rate_pct,
    efficiency_score,
    -- Improvement recommendations
    CASE 
        WHEN occupancy_rate > 0.95 THEN 'INCREASE_BED_CAPACITY'
        WHEN occupancy_rate < 0.75 THEN 'OPTIMIZE_DISCHARGE_PLANNING'
        WHEN overtime_rate > 0.10 THEN 'REVIEW_STAFFING_LEVELS'
        WHEN avg_utilization_rate < 0.70 THEN 'IMPROVE_EQUIPMENT_SCHEDULING'
        WHEN ABS(cost_variance_pct) > 10 THEN 'BUDGET_CONTROL_MEASURES'
        WHEN readmission_rate > 15 THEN 'ENHANCE_DISCHARGE_PROCESS'
        ELSE 'MAINTAIN_CURRENT_OPERATIONS'
    END as primary_recommendation,
    -- Financial impact estimate
    CASE 
        WHEN occupancy_rate < 0.75 THEN (0.85 - occupancy_rate) * equipment_net_revenue
        WHEN overtime_rate > 0.10 THEN overtime_rate * 50000 -- Estimated overtime cost reduction
        WHEN avg_utilization_rate < 0.70 THEN (0.80 - avg_utilization_rate) * equipment_net_revenue
        ELSE 0
    END as estimated_annual_savings
FROM operational_dashboard
ORDER BY efficiency_score ASC;

-- =====================================================
-- Challenge 4: Revenue Cycle Optimization
-- =====================================================

-- Analyze billing, collections, and reimbursement patterns
-- to optimize revenue and reduce denials

WITH claim_performance AS (
    SELECT 
        service_date,
        department,
        insurance_type,
        procedure_code,
        COUNT(*) as total_claims,
        SUM(charged_amount) as total_charges,
        SUM(allowed_amount) as total_allowed,
        SUM(paid_amount) as total_paid,
        COUNT(CASE WHEN claim_status = 'DENIED' THEN 1 END) as denied_claims,
        COUNT(CASE WHEN claim_status = 'PAID' THEN 1 END) as paid_claims,
        AVG(days_to_payment) as avg_days_to_payment,
        -- Calculate performance metrics
        COUNT(CASE WHEN claim_status = 'DENIED' THEN 1 END) * 100.0 / COUNT(*) as denial_rate,
        SUM(paid_amount) / NULLIF(SUM(charged_amount), 0) * 100 as collection_rate,
        SUM(allowed_amount) / NULLIF(SUM(charged_amount), 0) * 100 as contractual_adjustment_rate
    FROM revenue.claims_data
    WHERE service_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
    GROUP BY 1, 2, 3, 4
),
denial_analysis AS (
    SELECT 
        denial_reason,
        insurance_type,
        department,
        COUNT(*) as denial_count,
        SUM(charged_amount) as denied_charges,
        AVG(appeal_success_rate) as avg_appeal_success_rate,
        -- Categorize denial reasons
        CASE 
            WHEN denial_reason LIKE '%AUTHORIZATION%' THEN 'PRIOR_AUTH_REQUIRED'
            WHEN denial_reason LIKE '%CODING%' OR denial_reason LIKE '%PROCEDURE%' THEN 'CODING_ERROR'
            WHEN denial_reason LIKE '%ELIGIBILITY%' OR denial_reason LIKE '%COVERAGE%' THEN 'ELIGIBILITY_ISSUE'
            WHEN denial_reason LIKE '%DOCUMENTATION%' THEN 'INSUFFICIENT_DOCUMENTATION'
            ELSE 'OTHER'
        END as denial_category
    FROM revenue.claim_denials
    WHERE denial_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
    GROUP BY 1, 2, 3
),
accounts_receivable AS (
    SELECT 
        aging_bucket,
        department,
        insurance_type,
        COUNT(DISTINCT account_id) as account_count,
        SUM(outstanding_balance) as total_ar_balance,
        AVG(days_outstanding) as avg_days_outstanding,
        -- Calculate AR aging distribution
        SUM(outstanding_balance) / SUM(SUM(outstanding_balance)) OVER (PARTITION BY department) * 100 as ar_percentage
    FROM revenue.ar_aging
    WHERE as_of_date = CURRENT_DATE
    GROUP BY 1, 2, 3
),
revenue_optimization_opportunities AS (
    SELECT 
        cp.department,
        cp.insurance_type,
        cp.total_charges,
        cp.total_paid,
        cp.denial_rate,
        cp.collection_rate,
        cp.avg_days_to_payment,
        da.denial_count,
        da.denied_charges,
        da.denial_category,
        ar.total_ar_balance,
        ar.avg_days_outstanding,
        -- Calculate potential revenue recovery
        da.denied_charges * da.avg_appeal_success_rate / 100 as recoverable_denials,
        ar.total_ar_balance * CASE 
            WHEN ar.aging_bucket = '0-30' THEN 0.95
            WHEN ar.aging_bucket = '31-60' THEN 0.85
            WHEN ar.aging_bucket = '61-90' THEN 0.70
            WHEN ar.aging_bucket = '91-120' THEN 0.50
            ELSE 0.25
        END as expected_ar_collection,
        -- Identify improvement opportunities
        CASE 
            WHEN cp.denial_rate > 15 THEN 'HIGH_DENIAL_RATE'
            WHEN cp.collection_rate < 85 THEN 'LOW_COLLECTION_RATE'
            WHEN cp.avg_days_to_payment > 45 THEN 'SLOW_PAYMENT'
            WHEN ar.avg_days_outstanding > 60 THEN 'AR_AGING_ISSUE'
            ELSE 'PERFORMING_WELL'
        END as primary_issue
    FROM claim_performance cp
    LEFT JOIN denial_analysis da ON cp.department = da.department AND cp.insurance_type = da.insurance_type
    LEFT JOIN accounts_receivable ar ON cp.department = ar.department AND cp.insurance_type = ar.insurance_type
)
SELECT 
    department,
    insurance_type,
    ROUND(total_charges, 0) as total_charges,
    ROUND(total_paid, 0) as total_paid,
    ROUND(denial_rate, 2) as denial_rate_pct,
    ROUND(collection_rate, 2) as collection_rate_pct,
    ROUND(avg_days_to_payment, 0) as avg_days_to_payment,
    denial_category,
    ROUND(recoverable_denials, 0) as potential_denial_recovery,
    ROUND(expected_ar_collection, 0) as expected_ar_collection,
    primary_issue,
    -- Specific recommendations
    CASE 
        WHEN primary_issue = 'HIGH_DENIAL_RATE' AND denial_category = 'CODING_ERROR' THEN 'IMPROVE_CODING_ACCURACY'
        WHEN primary_issue = 'HIGH_DENIAL_RATE' AND denial_category = 'PRIOR_AUTH_REQUIRED' THEN 'ENHANCE_AUTHORIZATION_PROCESS'
        WHEN primary_issue = 'LOW_COLLECTION_RATE' THEN 'REVIEW_CONTRACTING_RATES'
        WHEN primary_issue = 'SLOW_PAYMENT' THEN 'ACCELERATE_CLAIM_SUBMISSION'
        WHEN primary_issue = 'AR_AGING_ISSUE' THEN 'INTENSIFY_COLLECTION_EFFORTS'
        ELSE 'MAINTAIN_CURRENT_PROCESSES'
    END as recommended_action,
    -- Financial impact
    ROUND(recoverable_denials + expected_ar_collection - total_ar_balance, 0) as net_revenue_opportunity
FROM revenue_optimization_opportunities
ORDER BY net_revenue_opportunity DESC;

-- =====================================================
-- Final Integration Dashboard
-- =====================================================

-- Executive summary combining all healthcare analytics components
-- for strategic decision-making and performance monitoring

WITH executive_summary AS (
    SELECT 
        'Patient Outcomes' as metric_category,
        COUNT(DISTINCT patient_id) as total_patients,
        AVG(readmission_probability) as avg_readmission_risk,
        COUNT(CASE WHEN readmission_risk_category = 'HIGH_RISK' THEN 1 END) as high_risk_patients,
        NULL as financial_impact,
        'Implement targeted interventions for high-risk patients' as key_recommendation
    FROM patient_risk_model
    
    UNION ALL
    
    SELECT 
        'Population Health' as metric_category,
        SUM(total_patients) as total_patients,
        AVG(intervention_priority_score) as avg_priority_score,
        COUNT(CASE WHEN intervention_priority_score >= 60 THEN 1 END) as high_priority_areas,
        NULL as financial_impact,
        'Focus on diabetes management and cancer screening programs' as key_recommendation
    FROM population_health_priorities
    
    UNION ALL
    
    SELECT 
        'Operational Efficiency' as metric_category,
        COUNT(DISTINCT ward_type) as departments_analyzed,
        AVG(efficiency_score) as avg_efficiency_score,
        COUNT(CASE WHEN efficiency_score < 70 THEN 1 END) as underperforming_areas,
        SUM(estimated_annual_savings) as financial_impact,
        'Optimize bed utilization and reduce overtime costs' as key_recommendation
    FROM operational_dashboard
    
    UNION ALL
    
    SELECT 
        'Revenue Cycle' as metric_category,
        COUNT(DISTINCT department) as departments_analyzed,
        AVG(collection_rate) as avg_collection_rate,
        COUNT(CASE WHEN denial_rate > 15 THEN 1 END) as high_denial_departments,
        SUM(net_revenue_opportunity) as financial_impact,
        'Reduce claim denials and accelerate collections' as key_recommendation
    FROM revenue_optimization_opportunities
)
SELECT 
    metric_category,
    total_patients,
    ROUND(avg_readmission_risk * 100, 1) as avg_risk_metric_pct,
    high_risk_patients as areas_needing_attention,
    ROUND(financial_impact, 0) as financial_impact_usd,
    key_recommendation
FROM executive_summary
ORDER BY financial_impact DESC NULLS LAST;

-- =====================================================
-- SUCCESS METRICS VALIDATION
-- =====================================================

/*
Validate your solution against these success criteria:

1. Patient Outcome Prediction (Target: 85%+ accuracy)
   - Risk stratification model identifies high-risk patients
   - Incorporates multiple clinical variables
   - Provides actionable care recommendations

2. Cost Reduction (Target: $2M+ annually)
   - Operational efficiency improvements
   - Revenue cycle optimization
   - Preventive care gap closure

3. HIPAA Compliance (Target: 95%+ score)
   - Data de-identification protocols
   - Access controls and audit trails
   - Privacy-preserving analytics

4. Population Health (Target: 100K+ patients)
   - Comprehensive demographic analysis
   - Chronic disease prevalence tracking
   - Preventive care gap identification

5. Operational Efficiency (Target: 15%+ improvement)
   - Bed utilization optimization
   - Staffing efficiency analysis
   - Equipment utilization enhancement
*/
