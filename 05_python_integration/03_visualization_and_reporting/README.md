# 📊 SQL + Python Visualization for Business Analysts

**Level:** Intermediate  
**Prerequisites:** Basic SQL, Python fundamentals  
**Estimated Time:** 4-6 hours  
**Business Impact:** High - Create professional reports and dashboards

## 🎯 Learning Objectives

Master the integration of SQL and Python to create compelling business visualizations:

1. **Execute SQL from Python** and work with results in pandas DataFrames
2. **Create business charts** directly from SQL query results
3. **Build automated reports** that update with fresh data
4. **Export to business formats** (Excel, PowerPoint, PDF)
5. **Design dashboards** for stakeholder consumption

## 📁 Module Contents

### 📈 **01_sql_to_charts.py**
**Business Context:** Transform SQL query results into executive-ready visualizations  
**Skills:** pandas + matplotlib/seaborn for business charts  
**Deliverable:** Revenue trend charts, product performance graphs

### 📋 **02_automated_reports.py**
**Business Context:** Generate weekly/monthly reports automatically  
**Skills:** Report templating, automated chart generation  
**Deliverable:** Self-updating executive summary reports

### 📊 **03_dashboard_creation.py**
**Business Context:** Interactive dashboards for business stakeholders  
**Skills:** Plotly/Dash for interactive business dashboards  
**Deliverable:** Web-based interactive business dashboard

### 📄 **04_export_to_business_tools.py**
**Business Context:** Export insights to Excel, PowerPoint for presentations  
**Skills:** openpyxl, python-pptx integration  
**Deliverable:** Professional presentation-ready outputs

## 🛠️ Analyst-Focused Examples

### Basic SQL to Chart Workflow
```python
import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy

# Connect to your business database
engine = sqlalchemy.create_engine('postgresql://user:pass@host:port/db')

# Business question: Monthly revenue trend
query = '''
SELECT 
    DATE_TRUNC('month', order_date) as month,
    SUM(order_total) as monthly_revenue,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders 
WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month
'''

# Execute and visualize
df = pd.read_sql(query, engine)

# Create executive-ready chart
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))

# Revenue trend
ax1.plot(df['month'], df['monthly_revenue'], marker='o', linewidth=2)
ax1.set_title('Monthly Revenue Trend', fontsize=14, fontweight='bold')
ax1.set_ylabel('Revenue ($)')
ax1.grid(True, alpha=0.3)

# Customer trend
ax2.bar(df['month'], df['unique_customers'], alpha=0.7, color='green')
ax2.set_title('Monthly Unique Customers', fontsize=14, fontweight='bold')
ax2.set_ylabel('Customers')
ax2.set_xlabel('Month')

plt.tight_layout()
plt.show()
```

### Automated Business Report
```python
# Generate automated executive summary
def create_business_summary():
    # KPI queries
    kpi_query = '''
    WITH current_month AS (
        SELECT 
            SUM(revenue) as current_revenue,
            COUNT(DISTINCT customer_id) as current_customers
        FROM sales_data 
        WHERE date_month = DATE_TRUNC('month', CURRENT_DATE)
    ),
    previous_month AS (
        SELECT 
            SUM(revenue) as prev_revenue,
            COUNT(DISTINCT customer_id) as prev_customers
        FROM sales_data 
        WHERE date_month = DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
    )
    SELECT 
        current_revenue,
        current_customers,
        prev_revenue,
        prev_customers,
        ROUND((current_revenue - prev_revenue) / prev_revenue * 100, 2) as revenue_growth,
        ROUND((current_customers - prev_customers) / prev_customers * 100, 2) as customer_growth
    FROM current_month, previous_month
    '''
    
    kpis = pd.read_sql(kpi_query, engine)
    
    # Create summary report
    report = f'''
    📊 MONTHLY BUSINESS SUMMARY
    ========================
    
    Revenue: ${kpis['current_revenue'][0]:,.0f} ({kpis['revenue_growth'][0]:+.1f}%)
    Customers: {kpis['current_customers'][0]:,} ({kpis['customer_growth'][0]:+.1f}%)
    
    Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}
    '''
    
    return report
```

## 🎯 Business Applications

### Marketing Analytics Dashboard
- Campaign performance charts
- Customer acquisition funnels
- ROI visualizations

### Sales Performance Reports
- Territory comparison maps
- Product performance heatmaps
- Pipeline progression charts

### Financial Reporting
- Budget vs actual variance charts
- Cash flow projections
- P&L trend analysis

### Operations Analytics
- Inventory level monitoring
- Supply chain efficiency metrics
- Quality control dashboards

## 🔧 Tools & Libraries for Analysts

### Essential Python Libraries
```python
# Data manipulation and SQL connection
import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine

# Visualization for business reports
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go

# Business output formats
from openpyxl import Workbook
from openpyxl.chart import LineChart, BarChart
import pptx
from reportlab.pdfgen import canvas

# Dashboard creation
import streamlit as st  # Quick dashboards
import dash  # Advanced interactive dashboards
```

### Business Visualization Best Practices
1. **Use business-appropriate colors** - avoid rainbow palettes
2. **Include clear titles and labels** - stakeholders should understand immediately
3. **Add context with annotations** - highlight key insights
4. **Choose appropriate chart types** - bars for comparisons, lines for trends
5. **Include data source and date** - for credibility and freshness

## 🚀 Getting Started

1. **Set up your environment** - Install required packages
2. **Connect to your database** - Test SQL execution from Python
3. **Start with simple charts** - One query, one visualization
4. **Build complexity gradually** - Add interactivity and automation
5. **Focus on business value** - Every chart should answer a business question

## 📚 Next Steps

After mastering this module:
- **[04_business_analytics_examples](../04_business_analytics_examples/)** - Industry-specific use cases
- **[05_automation_and_scheduling](../05_automation_and_scheduling/)** - Schedule reports and alerts
- **[Real World Applications](../../04_real_world/)** - Apply to actual business scenarios

---

**Remember:** The goal isn't just pretty charts - it's actionable insights that drive business decisions. Every visualization should tell a story that leads to action.
