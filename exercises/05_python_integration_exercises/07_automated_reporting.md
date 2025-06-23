# 🤖 Automated Reporting Exercise

## Business Context

**Scenario**: You're a senior analyst at TechFlow Solutions, a growing SaaS company. The executive team currently receives manual weekly reports that take 6 hours to compile each week. Your mission is to automate these reports using Python and SQL, reducing manual effort and enabling real-time insights.

**Stakeholder**: Sarah Chen, VP of Operations
**Business Challenge**: Manual reporting is time-consuming, error-prone, and always outdated by the time it reaches stakeholders.

## 🎯 Learning Objectives

By completing this exercise, you will:

- Build automated SQL data extraction pipelines in Python
- Create reusable reporting templates with parameterized queries
- Generate professional PDF reports programmatically
- Implement automated email distribution
- Design error handling and data validation workflows
- Schedule automated report generation

## 📊 Dataset Overview

You'll work with the TechFlow customer and usage database:

### Key Tables

- `customers`: Customer information and subscription details
- `usage_metrics`: Daily product usage statistics
- `revenue_transactions`: Monthly recurring revenue tracking
- `support_tickets`: Customer support interactions
- `feature_usage`: Individual feature adoption tracking

## 🛠️ Technical Requirements

### Required Libraries

```python
import pandas as pd
import sqlalchemy as sa
import plotly.graph_objects as go
import plotly.express as px
from datetime import datetime, timedelta
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
```

### Database Connection

```python
# Connection to TechFlow database
engine = sa.create_engine("postgresql://localhost:5432/techflow_db")
```

## 📋 Tasks

### Task 1: Executive KPI Dashboard Data (🟢 Beginner)

**Objective**: Extract and format core business metrics for executive review.

**Requirements**:

1. Create a Python function that extracts key metrics for the last 30 days:
   - Total Active Customers
   - Monthly Recurring Revenue (MRR)
   - Customer Churn Rate
   - Average Support Response Time
   - Feature Adoption Rate

2. Format the data for executive consumption

**SQL Query Template**:

```sql
-- Executive KPI extraction
WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', current_date) AS report_month,
        COUNT(DISTINCT c.customer_id) AS active_customers,
        SUM(rt.amount) AS mrr,
        COUNT(DISTINCT st.ticket_id) AS support_tickets,
        AVG(st.response_time_hours) AS avg_response_time
    FROM customers c
    LEFT JOIN revenue_transactions rt ON c.customer_id = rt.customer_id
    LEFT JOIN support_tickets st ON c.customer_id = st.customer_id
    WHERE c.status = 'active'
        AND rt.transaction_date >= DATE_TRUNC('month', current_date)
        AND st.created_date >= DATE_TRUNC('month', current_date)
    GROUP BY 1
)
SELECT * FROM monthly_metrics;
```

**Python Implementation**:

```python
def extract_executive_kpis(engine, report_date=None):
    """Extract executive KPIs for specified date."""
    if report_date is None:
        report_date = datetime.now().strftime('%Y-%m-%d')
    
    query = """
    WITH executive_kpis AS (
        SELECT 
            '{report_date}'::date AS report_date,
            COUNT(DISTINCT c.customer_id) AS total_customers,
            SUM(CASE WHEN c.status = 'active' THEN 1 ELSE 0 END) AS active_customers,
            SUM(rt.amount) AS current_mrr,
            AVG(st.response_time_hours) AS avg_response_time,
            COUNT(DISTINCT fu.feature_id) AS features_in_use
        FROM customers c
        LEFT JOIN revenue_transactions rt ON c.customer_id = rt.customer_id
            AND DATE_TRUNC('month', rt.transaction_date) = DATE_TRUNC('month', '{report_date}'::date)
        LEFT JOIN support_tickets st ON c.customer_id = st.customer_id
            AND st.created_date >= '{report_date}'::date - INTERVAL '30 days'
        LEFT JOIN feature_usage fu ON c.customer_id = fu.customer_id
            AND fu.usage_date >= '{report_date}'::date - INTERVAL '30 days'
    )
    SELECT * FROM executive_kpis;
    """.format(report_date=report_date)
    
    return pd.read_sql(query, engine)

# Usage
kpi_data = extract_executive_kpis(engine)
print(kpi_data)
```

### Task 2: Customer Health Scoring (🟡 Intermediate)

**Objective**: Build a comprehensive customer health scoring system.

**Requirements**:

1. Create a composite health score based on:
   - Usage frequency (weight: 40%)
   - Support ticket volume (weight: 20%)
   - Feature adoption (weight: 25%)
   - Payment history (weight: 15%)

2. Categorize customers as: Healthy, At Risk, Critical

**Business Logic**:

```python
def calculate_customer_health(engine):
    """Calculate comprehensive customer health scores."""
    
    query = """
    WITH customer_metrics AS (
        SELECT 
            c.customer_id,
            c.customer_name,
            c.subscription_tier,
            
            -- Usage Score (0-100)
            CASE 
                WHEN AVG(um.daily_usage_minutes) >= 120 THEN 100
                WHEN AVG(um.daily_usage_minutes) >= 60 THEN 75
                WHEN AVG(um.daily_usage_minutes) >= 30 THEN 50
                WHEN AVG(um.daily_usage_minutes) >= 10 THEN 25
                ELSE 0
            END AS usage_score,
            
            -- Support Score (0-100, fewer tickets = higher score)
            CASE 
                WHEN COUNT(st.ticket_id) = 0 THEN 100
                WHEN COUNT(st.ticket_id) <= 1 THEN 80
                WHEN COUNT(st.ticket_id) <= 3 THEN 60
                WHEN COUNT(st.ticket_id) <= 5 THEN 40
                ELSE 20
            END AS support_score,
            
            -- Feature Adoption Score (0-100)
            (COUNT(DISTINCT fu.feature_id) * 100.0 / 
             (SELECT COUNT(*) FROM features WHERE is_core = true)) AS adoption_score,
            
            -- Payment Score (0-100)
            CASE 
                WHEN COUNT(rt.transaction_id) = 
                     EXTRACT(day FROM age(current_date, c.signup_date))/30 THEN 100
                WHEN COUNT(rt.transaction_id) >= 
                     EXTRACT(day FROM age(current_date, c.signup_date))/30 * 0.9 THEN 80
                ELSE 50
            END AS payment_score
            
        FROM customers c
        LEFT JOIN usage_metrics um ON c.customer_id = um.customer_id
            AND um.usage_date >= current_date - INTERVAL '30 days'
        LEFT JOIN support_tickets st ON c.customer_id = st.customer_id
            AND st.created_date >= current_date - INTERVAL '30 days'
        LEFT JOIN feature_usage fu ON c.customer_id = fu.customer_id
            AND fu.usage_date >= current_date - INTERVAL '30 days'
        LEFT JOIN revenue_transactions rt ON c.customer_id = rt.customer_id
            AND rt.transaction_date >= current_date - INTERVAL '90 days'
        WHERE c.status = 'active'
        GROUP BY c.customer_id, c.customer_name, c.subscription_tier, c.signup_date
    ),
    health_scores AS (
        SELECT 
            *,
            -- Weighted health score
            (usage_score * 0.40 + 
             support_score * 0.20 + 
             adoption_score * 0.25 + 
             payment_score * 0.15) AS health_score
        FROM customer_metrics
    )
    SELECT 
        *,
        CASE 
            WHEN health_score >= 80 THEN 'Healthy'
            WHEN health_score >= 60 THEN 'At Risk'
            ELSE 'Critical'
        END AS health_category
    FROM health_scores
    ORDER BY health_score DESC;
    """
    
    return pd.read_sql(query, engine)

# Generate health report
health_data = calculate_customer_health(engine)
print(f"Customer Health Distribution:")
print(health_data['health_category'].value_counts())
```

### Task 3: Automated Report Generation (🔴 Advanced)

**Objective**: Create a complete automated reporting pipeline with PDF generation and email distribution.

**Requirements**:

1. Generate a professional executive report
2. Include visualizations and trend analysis
3. Create automated email distribution
4. Implement error handling and logging

**Complete Solution**:

```python
import logging
from datetime import datetime
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import base64
from io import BytesIO

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ExecutiveReportGenerator:
    """Automated executive report generation system."""
    
    def __init__(self, engine, smtp_config=None):
        self.engine = engine
        self.smtp_config = smtp_config or {
            'server': 'smtp.gmail.com',
            'port': 587,
            'username': 'reports@techflow.com',
            'password': 'app_password'
        }
    
    def extract_trend_data(self, days=90):
        """Extract trending metrics for visualization."""
        query = """
        SELECT 
            DATE_TRUNC('week', um.usage_date) AS week_start,
            COUNT(DISTINCT um.customer_id) AS active_users,
            AVG(um.daily_usage_minutes) AS avg_usage_minutes,
            SUM(rt.amount) AS weekly_revenue,
            COUNT(st.ticket_id) AS support_tickets
        FROM usage_metrics um
        LEFT JOIN revenue_transactions rt ON DATE_TRUNC('week', um.usage_date) = 
                                            DATE_TRUNC('week', rt.transaction_date)
        LEFT JOIN support_tickets st ON DATE_TRUNC('week', um.usage_date) = 
                                       DATE_TRUNC('week', st.created_date)
        WHERE um.usage_date >= current_date - INTERVAL '{days} days'
        GROUP BY week_start
        ORDER BY week_start;
        """.format(days=days)
        
        return pd.read_sql(query, self.engine)
    
    def create_executive_dashboard(self):
        """Create comprehensive executive dashboard visualization."""
        
        # Get trend data
        trend_data = self.extract_trend_data()
        
        # Create subplots
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Weekly Active Users', 'Average Usage per User', 
                          'Weekly Revenue Trend', 'Support Ticket Volume'),
            specs=[[{"secondary_y": False}, {"secondary_y": False}],
                   [{"secondary_y": False}, {"secondary_y": False}]]
        )
        
        # Active Users
        fig.add_trace(
            go.Scatter(x=trend_data['week_start'], y=trend_data['active_users'],
                      mode='lines+markers', name='Active Users', 
                      line=dict(color='#1f77b4', width=3)),
            row=1, col=1
        )
        
        # Usage per User
        fig.add_trace(
            go.Scatter(x=trend_data['week_start'], y=trend_data['avg_usage_minutes'],
                      mode='lines+markers', name='Avg Usage (min)', 
                      line=dict(color='#ff7f0e', width=3)),
            row=1, col=2
        )
        
        # Revenue
        fig.add_trace(
            go.Scatter(x=trend_data['week_start'], y=trend_data['weekly_revenue'],
                      mode='lines+markers', name='Revenue', 
                      line=dict(color='#2ca02c', width=3)),
            row=2, col=1
        )
        
        # Support Tickets
        fig.add_trace(
            go.Bar(x=trend_data['week_start'], y=trend_data['support_tickets'],
                   name='Support Tickets', marker_color='#d62728'),
            row=2, col=2
        )
        
        fig.update_layout(
            title_text="TechFlow Executive Dashboard - Weekly Trends",
            title_x=0.5,
            height=600,
            showlegend=False
        )
        
        return fig
    
    def generate_insights(self):
        """Generate automated business insights."""
        
        # Get current and previous period data
        current_kpis = extract_executive_kpis(self.engine)
        
        insights = []
        
        # Revenue growth insight
        query = """
        SELECT 
            DATE_TRUNC('month', rt.transaction_date) AS month,
            SUM(rt.amount) AS monthly_revenue
        FROM revenue_transactions rt
        WHERE rt.transaction_date >= current_date - INTERVAL '2 months'
        GROUP BY month
        ORDER BY month;
        """
        
        revenue_trend = pd.read_sql(query, self.engine)
        if len(revenue_trend) >= 2:
            current_revenue = revenue_trend.iloc[-1]['monthly_revenue']
            previous_revenue = revenue_trend.iloc[-2]['monthly_revenue']
            growth_rate = ((current_revenue - previous_revenue) / previous_revenue) * 100
            
            if growth_rate > 10:
                insights.append(f"🚀 Strong revenue growth: {growth_rate:.1f}% month-over-month")
            elif growth_rate > 0:
                insights.append(f"📈 Positive revenue growth: {growth_rate:.1f}% month-over-month")
            else:
                insights.append(f"⚠️ Revenue decline: {growth_rate:.1f}% month-over-month requires attention")
        
        # Customer health insights
        health_data = calculate_customer_health(self.engine)
        critical_customers = len(health_data[health_data['health_category'] == 'Critical'])
        at_risk_customers = len(health_data[health_data['health_category'] == 'At Risk'])
        
        if critical_customers > 0:
            insights.append(f"🔥 {critical_customers} customers in critical health status - immediate action required")
        
        if at_risk_customers > 5:
            insights.append(f"⚠️ {at_risk_customers} customers at risk - consider proactive outreach")
        
        return insights
    
    def generate_html_report(self):
        """Generate complete HTML report."""
        
        # Get data
        kpi_data = extract_executive_kpis(self.engine)
        health_data = calculate_customer_health(self.engine)
        dashboard_fig = self.create_executive_dashboard()
        insights = self.generate_insights()
        
        # Convert plot to HTML
        dashboard_html = dashboard_fig.to_html(include_plotlyjs='cdn', div_id="dashboard")
        
        # Generate health summary
        health_summary = health_data.groupby('health_category').agg({
            'customer_id': 'count',
            'health_score': 'mean'
        }).round(1)
        
        html_template = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>TechFlow Executive Report - {datetime.now().strftime('%B %d, %Y')}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; }}
                .header {{ text-align: center; color: #2c3e50; }}
                .kpi-grid {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin: 30px 0; }}
                .kpi-card {{ background: #f8f9fa; border-left: 4px solid #3498db; padding: 20px; }}
                .kpi-value {{ font-size: 2em; font-weight: bold; color: #2c3e50; }}
                .kpi-label {{ color: #7f8c8d; font-size: 0.9em; }}
                .insights {{ background: #e8f4fd; border-radius: 8px; padding: 20px; margin: 20px 0; }}
                .health-table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
                .health-table th, .health-table td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
                .health-table th {{ background-color: #f2f2f2; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>TechFlow Executive Report</h1>
                <h2>{datetime.now().strftime('%B %d, %Y')}</h2>
            </div>
            
            <div class="kpi-grid">
                <div class="kpi-card">
                    <div class="kpi-value">{int(kpi_data.iloc[0]['active_customers']):,}</div>
                    <div class="kpi-label">Active Customers</div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-value">${int(kpi_data.iloc[0]['current_mrr']):,}</div>
                    <div class="kpi-label">Monthly Recurring Revenue</div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-value">{kpi_data.iloc[0]['avg_response_time']:.1f}h</div>
                    <div class="kpi-label">Avg Support Response Time</div>
                </div>
            </div>
            
            <div class="insights">
                <h3>📊 Key Insights</h3>
                <ul>
                    {''.join([f'<li>{insight}</li>' for insight in insights])}
                </ul>
            </div>
            
            {dashboard_html}
            
            <h3>Customer Health Summary</h3>
            <table class="health-table">
                <tr>
                    <th>Health Category</th>
                    <th>Customer Count</th>
                    <th>Average Score</th>
                </tr>
                {health_summary.to_html(table_id=None, escape=False, classes='health-table')}
            </table>
            
            <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #7f8c8d;">
                <p>Report generated automatically by TechFlow Analytics System</p>
                <p>For questions, contact: analytics@techflow.com</p>
            </div>
        </body>
        </html>
        """
        
        return html_template
    
    def send_email_report(self, recipients, html_content):
        """Send HTML report via email."""
        
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = f"TechFlow Executive Report - {datetime.now().strftime('%B %d, %Y')}"
            msg['From'] = self.smtp_config['username']
            msg['To'] = ', '.join(recipients)
            
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            server = smtplib.SMTP(self.smtp_config['server'], self.smtp_config['port'])
            server.starttls()
            server.login(self.smtp_config['username'], self.smtp_config['password'])
            server.send_message(msg)
            server.quit()
            
            logger.info(f"Report sent successfully to {len(recipients)} recipients")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email report: {str(e)}")
            return False
    
    def run_full_report(self, recipients=None):
        """Execute complete automated reporting pipeline."""
        
        try:
            logger.info("Starting automated report generation...")
            
            # Generate report
            html_report = self.generate_html_report()
            
            # Save local copy
            report_filename = f"executive_report_{datetime.now().strftime('%Y%m%d_%H%M')}.html"
            with open(report_filename, 'w', encoding='utf-8') as f:
                f.write(html_report)
            
            logger.info(f"Report saved locally as {report_filename}")
            
            # Send email if recipients specified
            if recipients:
                success = self.send_email_report(recipients, html_report)
                if success:
                    logger.info("Email distribution completed successfully")
                else:
                    logger.error("Email distribution failed")
            
            return report_filename
            
        except Exception as e:
            logger.error(f"Report generation failed: {str(e)}")
            raise

# Usage example
if __name__ == "__main__":
    # Initialize report generator
    engine = sa.create_engine("postgresql://localhost:5432/techflow_db")
    
    report_gen = ExecutiveReportGenerator(engine)
    
    # Generate and distribute report
    recipients = ['sarah.chen@techflow.com', 'executive-team@techflow.com']
    report_file = report_gen.run_full_report(recipients)
    
    print(f"Executive report generated: {report_file}")
```

## 🎯 Business Impact

### Success Metrics

- **Time Savings**: Reduce weekly reporting from 6 hours to 15 minutes
- **Accuracy**: Eliminate manual data entry errors
- **Timeliness**: Real-time insights vs. weekly delayed reports
- **Stakeholder Satisfaction**: Consistent, professional formatting

### Expected Outcomes

1. **Executive Team Benefits**:
   - Real-time access to key metrics
   - Consistent report format and timing
   - Automated insights and recommendations

2. **Analyst Team Benefits**:
   - More time for strategic analysis
   - Reduced manual, repetitive work
   - Focus on insight generation vs. data compilation

3. **Business Benefits**:
   - Faster decision-making with timely data
   - Improved customer retention through health monitoring
   - Proactive issue identification and resolution

## 🚀 Extensions & Next Steps

### Challenge Extensions

1. **Real-Time Alerts**: Implement threshold-based alerting for critical metrics
2. **Interactive Dashboards**: Convert to Streamlit or Dash for interactive exploration
3. **Mobile Optimization**: Format reports for mobile consumption
4. **Predictive Analytics**: Add forecasting models for revenue and churn
5. **Multi-Department Reports**: Extend to marketing, sales, and support teams

### Advanced Implementations

1. **Airflow Integration**: Schedule reports using Apache Airflow
2. **Cloud Deployment**: Deploy to AWS/Azure for scalable execution  
3. **Data Lineage**: Implement data quality monitoring and lineage tracking
4. **A/B Testing**: Add statistical significance testing for business experiments

---

**💡 Pro Tip**: Start with manual report generation and validation before implementing full automation. This ensures data accuracy and stakeholder buy-in before scaling the solution.
