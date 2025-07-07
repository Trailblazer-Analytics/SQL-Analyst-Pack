# 💼 Business Analytics Examples: SQL + Python in Action

**Level:** Intermediate to Advanced  
**Prerequisites:** SQL fundamentals, Python basics, data visualization  
**Estimated Time:** 6-8 hours  
**Business Impact:** Very High - Complete analytical solutions

## 🎯 Real-World Business Scenarios

This module provides complete analytical solutions that combine SQL and Python to solve actual business challenges. Each example includes the business context, stakeholder requirements, complete code, and presentation-ready outputs.

## 📁 Business Scenario Examples

### 🛒 **01_ecommerce_customer_analytics.py**
**Business Challenge:** E-commerce company needs to optimize customer acquisition and retention  
**Stakeholders:** Marketing Director, Customer Success Manager  
**Deliverables:** Customer segmentation analysis, LTV predictions, retention strategies

### 📈 **02_sales_performance_optimization.py**
**Business Challenge:** B2B company wants to improve sales team performance and forecasting  
**Stakeholders:** Sales VP, Regional Managers, Individual Sales Reps  
**Deliverables:** Territory analysis, quota attainment tracking, pipeline forecasting

### 💰 **03_financial_variance_analysis.py**
**Business Challenge:** CFO needs automated monthly close reporting and variance analysis  
**Stakeholders:** CFO, Finance Team, Department Heads  
**Deliverables:** Budget vs actual analysis, variance explanations, forecast updates

### 📱 **04_marketing_campaign_optimization.py**
**Business Challenge:** Digital marketing team needs to optimize campaign spend and targeting  
**Stakeholders:** Marketing Director, Campaign Managers, Data Team  
**Deliverables:** Campaign ROI analysis, audience insights, spend optimization

### 🏭 **05_operational_efficiency_analysis.py**
**Business Challenge:** Operations team wants to improve process efficiency and reduce costs  
**Stakeholders:** Operations Manager, Plant Managers, Quality Team  
**Deliverables:** Process performance metrics, bottleneck identification, improvement recommendations

## 🛒 Example 1: E-commerce Customer Analytics

### Business Context
You're analyzing customer behavior for an online retailer to improve marketing ROI and customer lifetime value.

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine
from datetime import datetime, timedelta
import plotly.express as px
import plotly.graph_objects as go

# Database connection
engine = create_engine('postgresql://user:pass@host:port/ecommerce_db')

def customer_segmentation_analysis():
    '''
    Complete customer segmentation analysis for marketing team
    Business Question: Which customers should we target for different campaigns?
    '''
    
    # SQL Query: Customer RFM Analysis
    rfm_query = '''
    WITH customer_metrics AS (
        SELECT 
            customer_id,
            MAX(order_date) as last_order_date,
            COUNT(DISTINCT order_id) as order_frequency,
            SUM(order_total) as monetary_value,
            CURRENT_DATE - MAX(order_date) as days_since_last_order,
            DATE_PART('days', CURRENT_DATE - MIN(order_date)) as customer_age_days
        FROM orders 
        WHERE order_date >= CURRENT_DATE - INTERVAL '24 months'
        GROUP BY customer_id
    ),
    rfm_scores AS (
        SELECT *,
            NTILE(5) OVER (ORDER BY days_since_last_order ASC) as recency_score,
            NTILE(5) OVER (ORDER BY order_frequency DESC) as frequency_score,
            NTILE(5) OVER (ORDER BY monetary_value DESC) as monetary_score
        FROM customer_metrics
    )
    SELECT 
        customer_id,
        days_since_last_order,
        order_frequency,
        monetary_value,
        customer_age_days,
        recency_score,
        frequency_score,
        monetary_score,
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost Customers'
            WHEN monetary_score <= 2 THEN 'Price Sensitive'
            ELSE 'Developing'
        END as customer_segment
    FROM rfm_scores
    '''
    
    # Execute analysis
    df_customers = pd.read_sql(rfm_query, engine)
    
    # Segment Analysis
    segment_summary = df_customers.groupby('customer_segment').agg({
        'customer_id': 'count',
        'monetary_value': ['mean', 'sum'],
        'order_frequency': 'mean',
        'days_since_last_order': 'mean'
    }).round(2)
    
    segment_summary.columns = ['Customer_Count', 'Avg_LTV', 'Total_Revenue', 'Avg_Frequency', 'Avg_Recency']
    segment_summary['Revenue_Percentage'] = (segment_summary['Total_Revenue'] / segment_summary['Total_Revenue'].sum() * 100).round(2)
    
    # Create visualizations
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
    
    # 1. Customer Count by Segment
    segment_summary['Customer_Count'].plot(kind='bar', ax=ax1, color='skyblue')
    ax1.set_title('Customer Count by Segment', fontweight='bold')
    ax1.set_ylabel('Number of Customers')
    ax1.tick_params(axis='x', rotation=45)
    
    # 2. Revenue Distribution
    colors = ['gold', 'lightgreen', 'lightcoral', 'lightskyblue', 'plum', 'orange', 'lightgray']
    ax2.pie(segment_summary['Total_Revenue'], labels=segment_summary.index, autopct='%1.1f%%', colors=colors)
    ax2.set_title('Revenue Distribution by Segment', fontweight='bold')
    
    # 3. Average LTV by Segment
    segment_summary['Avg_LTV'].plot(kind='bar', ax=ax3, color='lightgreen')
    ax3.set_title('Average Customer Lifetime Value by Segment', fontweight='bold')
    ax3.set_ylabel('Average LTV ($)')
    ax3.tick_params(axis='x', rotation=45)
    
    # 4. Recency vs Frequency Scatter
    scatter = ax4.scatter(df_customers['order_frequency'], df_customers['days_since_last_order'], 
                         c=df_customers['monetary_value'], cmap='viridis', alpha=0.6)
    ax4.set_xlabel('Order Frequency')
    ax4.set_ylabel('Days Since Last Order')
    ax4.set_title('Customer RFM Analysis', fontweight='bold')
    plt.colorbar(scatter, ax=ax4, label='Monetary Value ($)')
    
    plt.tight_layout()
    plt.show()
    
    # Business Insights
    insights = f'''
    📊 CUSTOMER SEGMENTATION INSIGHTS
    ================================
    
    🏆 Champions: {segment_summary.loc['Champions', 'Customer_Count']} customers (${segment_summary.loc['Champions', 'Avg_LTV']:.0f} avg LTV)
    💙 Loyal Customers: {segment_summary.loc['Loyal Customers', 'Customer_Count']} customers 
    🆕 New Customers: {segment_summary.loc['New Customers', 'Customer_Count']} customers (Growth opportunity)
    ⚠️ At Risk: {segment_summary.loc['At Risk', 'Customer_Count']} customers (Retention needed)
    😞 Lost Customers: {segment_summary.loc['Lost Customers', 'Customer_Count']} customers (Win-back campaigns)
    
    💰 Revenue Concentration: Top 2 segments generate {(segment_summary.loc[['Champions', 'Loyal Customers'], 'Revenue_Percentage'].sum()):.1f}% of revenue
    
    🎯 RECOMMENDED ACTIONS:
    =====================
    1. VIP Program: Target Champions with exclusive offers
    2. Retention Campaign: Re-engage At Risk customers
    3. Win-back Campaign: Special offers for Lost Customers
    4. Growth Strategy: Convert New Customers to Loyal
    '''
    
    print(insights)
    return df_customers, segment_summary

# Customer Lifetime Value Prediction
def predict_customer_ltv():
    '''
    Predict customer lifetime value for marketing budget allocation
    '''
    
    ltv_query = '''
    WITH customer_cohorts AS (
        SELECT 
            customer_id,
            DATE_TRUNC('month', MIN(order_date)) as cohort_month,
            DATE_TRUNC('month', order_date) as order_month,
            SUM(order_total) as monthly_revenue
        FROM orders 
        GROUP BY customer_id, DATE_TRUNC('month', MIN(order_date)), DATE_TRUNC('month', order_date)
    ),
    ltv_calculation AS (
        SELECT 
            customer_id,
            cohort_month,
            SUM(monthly_revenue) as total_revenue,
            COUNT(DISTINCT order_month) as active_months,
            MAX(order_month) as last_active_month,
            EXTRACT(EPOCH FROM (MAX(order_month) - cohort_month)) / (30 * 24 * 3600) as customer_age_months
        FROM customer_cohorts
        GROUP BY customer_id, cohort_month
    )
    SELECT 
        customer_id,
        cohort_month,
        total_revenue,
        active_months,
        customer_age_months,
        CASE 
            WHEN customer_age_months > 0 THEN total_revenue / customer_age_months
            ELSE total_revenue
        END as monthly_revenue_rate,
        -- Predicted LTV based on current trajectory
        CASE 
            WHEN customer_age_months > 0 THEN (total_revenue / customer_age_months) * 24  -- 24 month projection
            ELSE total_revenue * 24
        END as predicted_24m_ltv
    FROM ltv_calculation
    WHERE customer_age_months >= 1  -- At least 1 month of data
    '''
    
    df_ltv = pd.read_sql(ltv_query, engine)
    
    # LTV Distribution Analysis
    ltv_stats = df_ltv['predicted_24m_ltv'].describe()
    
    # Create LTV distribution chart
    plt.figure(figsize=(12, 8))
    
    plt.subplot(2, 2, 1)
    plt.hist(df_ltv['predicted_24m_ltv'], bins=50, alpha=0.7, color='skyblue', edgecolor='black')
    plt.title('Customer LTV Distribution', fontweight='bold')
    plt.xlabel('Predicted 24-Month LTV ($)')
    plt.ylabel('Number of Customers')
    plt.axvline(ltv_stats['mean'], color='red', linestyle='--', label=f'Mean: ${ltv_stats["mean"]:.0f}')
    plt.legend()
    
    # LTV by Cohort Month
    plt.subplot(2, 2, 2)
    cohort_ltv = df_ltv.groupby('cohort_month')['predicted_24m_ltv'].mean()
    cohort_ltv.plot(kind='line', marker='o', color='green')
    plt.title('Average LTV by Customer Cohort', fontweight='bold')
    plt.xlabel('Cohort Month')
    plt.ylabel('Average Predicted LTV ($)')
    plt.xticks(rotation=45)
    
    # High Value Customer Identification
    high_value_threshold = df_ltv['predicted_24m_ltv'].quantile(0.8)  # Top 20%
    high_value_customers = df_ltv[df_ltv['predicted_24m_ltv'] >= high_value_threshold]
    
    plt.subplot(2, 2, 3)
    plt.scatter(df_ltv['customer_age_months'], df_ltv['predicted_24m_ltv'], alpha=0.5, color='lightblue')
    plt.scatter(high_value_customers['customer_age_months'], high_value_customers['predicted_24m_ltv'], 
               alpha=0.8, color='red', label='High Value (Top 20%)')
    plt.title('LTV vs Customer Age', fontweight='bold')
    plt.xlabel('Customer Age (Months)')
    plt.ylabel('Predicted LTV ($)')
    plt.legend()
    
    plt.tight_layout()
    plt.show()
    
    # Marketing Recommendations
    recommendations = f'''
    💰 CUSTOMER LIFETIME VALUE ANALYSIS
    ==================================
    
    📈 Average Predicted LTV: ${ltv_stats["mean"]:.0f}
    🔝 Top 20% Customer LTV: ${high_value_threshold:.0f}+
    🏆 High Value Customers: {len(high_value_customers)} ({len(high_value_customers)/len(df_ltv)*100:.1f}% of total)
    
    🎯 MARKETING BUDGET ALLOCATION:
    ==============================
    1. Acquisition: Target similar profiles to high-LTV customers
    2. Retention: Invest heavily in customers approaching high-value threshold
    3. Growth: Focus expansion efforts on active, high-potential customers
    
    💡 TACTICAL RECOMMENDATIONS:
    ===========================
    • Acquisition CAC Limit: ${high_value_threshold * 0.3:.0f} (30% of high-value LTV)
    • Retention Investment: Up to ${high_value_threshold * 0.15:.0f} per high-value customer
    • Expansion Budget: Focus on customers with ${ltv_stats["75%"]:.0f}+ current LTV
    '''
    
    print(recommendations)
    return df_ltv

# Execute the complete analysis
if __name__ == "__main__":
    print("🛒 ECOMMERCE CUSTOMER ANALYTICS")
    print("=" * 50)
    
    # Run customer segmentation
    customers_df, segments_summary = customer_segmentation_analysis()
    
    print("\n" + "=" * 50)
    
    # Run LTV prediction
    ltv_df = predict_customer_ltv()
    
    # Export results for stakeholders
    with pd.ExcelWriter('customer_analytics_report.xlsx') as writer:
        segments_summary.to_excel(writer, sheet_name='Segment_Summary')
        customers_df.to_excel(writer, sheet_name='Customer_Details', index=False)
        ltv_df.to_excel(writer, sheet_name='LTV_Analysis', index=False)
    
    print("\n📄 Report exported to 'customer_analytics_report.xlsx'")
    print("🎯 Ready for stakeholder presentation!")
```

## 🎯 Business Impact Measurement

### ROI Calculation Framework
```python
def calculate_analysis_roi():
    '''
    Measure the business impact of your analytics work
    '''
    
    # Example: Customer segmentation campaign results
    campaign_results = {
        'champions_campaign': {
            'investment': 50000,  # Campaign cost
            'revenue_lift': 250000,  # Additional revenue
            'customers_targeted': 1500
        },
        'retention_campaign': {
            'investment': 30000,
            'revenue_saved': 180000,  # Prevented churn revenue
            'customers_retained': 800
        }
    }
    
    total_investment = sum(c['investment'] for c in campaign_results.values())
    total_return = sum(c.get('revenue_lift', 0) + c.get('revenue_saved', 0) for c in campaign_results.values())
    
    roi = ((total_return - total_investment) / total_investment) * 100
    
    print(f"📊 ANALYTICS ROI SUMMARY")
    print(f"========================")
    print(f"Total Investment: ${total_investment:,}")
    print(f"Total Return: ${total_return:,}")
    print(f"Net ROI: {roi:.1f}%")
    print(f"💰 Every $1 spent on analytics generated ${total_return/total_investment:.2f} in return")
```

## 🔧 Production-Ready Templates

Each example includes:
- ✅ **Complete business context** and stakeholder requirements
- ✅ **Production-ready SQL** with proper error handling
- ✅ **Professional visualizations** suitable for executive presentations
- ✅ **Actionable insights** with specific recommendations
- ✅ **Export capabilities** to Excel, PowerPoint, and PDF
- ✅ **ROI measurement** framework

## 🚀 Getting Started

1. **Choose your business scenario** - Pick the example closest to your industry
2. **Adapt the database schema** - Update table and column names
3. **Customize the business rules** - Adjust thresholds and calculations
4. **Test with your data** - Start with a small dataset
5. **Present to stakeholders** - Use the insights and visualizations provided

## 📈 Success Metrics

Track these KPIs for your analytics projects:
- **Time to Insight**: How quickly can you answer business questions?
- **Decision Impact**: How many business decisions were influenced by your analysis?
- **Revenue Impact**: What financial impact did your insights generate?
- **Stakeholder Satisfaction**: Are business users getting value from your work?

---

**🎯 Remember**: These examples are templates. The real value comes from understanding your business context and adapting the analysis to solve your specific challenges. Focus on actionable insights that drive real business outcomes.
