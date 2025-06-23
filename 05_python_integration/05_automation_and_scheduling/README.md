# Automation and Scheduling for Analysts

## Overview

This section shows how to automate routine SQL analysis tasks using Python. These automation patterns help analysts save time on repetitive work and ensure consistent, timely delivery of insights.

## Automation Patterns for Analysts

### 1. Scheduled Data Reports

**Use Case**: Daily/weekly/monthly reports that stakeholders expect
**Benefits**: Consistency, time savings, reduced manual errors

```python
import schedule
import time
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import pandas as pd

def daily_sales_report():
    """Generate and send daily sales report"""
    
    # SQL query for daily metrics
    daily_query = """
    SELECT 
        CURRENT_DATE as report_date,
        COUNT(*) as total_orders,
        SUM(order_amount) as total_revenue,
        AVG(order_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as unique_customers,
        
        -- Compare to previous day
        LAG(COUNT(*)) OVER (ORDER BY DATE(order_date)) as prev_orders,
        LAG(SUM(order_amount)) OVER (ORDER BY DATE(order_date)) as prev_revenue
        
    FROM orders
    WHERE DATE(order_date) = CURRENT_DATE
    OR DATE(order_date) = CURRENT_DATE - 1
    GROUP BY DATE(order_date)
    ORDER BY DATE(order_date) DESC
    LIMIT 1
    """
    
    # Execute query and create report
    daily_data = pd.read_sql_query(daily_query, engine)
    
    # Calculate day-over-day changes
    if not daily_data.empty:
        current = daily_data.iloc[0]
        
        report_html = f"""
        <h2>Daily Sales Report - {current['report_date']}</h2>
        <table border="1">
        <tr><td><strong>Metric</strong></td><td><strong>Today</strong></td><td><strong>Change</strong></td></tr>
        <tr><td>Total Orders</td><td>{current['total_orders']:,}</td><td>{((current['total_orders']/current['prev_orders']-1)*100):+.1f}%</td></tr>
        <tr><td>Total Revenue</td><td>${current['total_revenue']:,.2f}</td><td>{((current['total_revenue']/current['prev_revenue']-1)*100):+.1f}%</td></tr>
        <tr><td>Average Order Value</td><td>${current['avg_order_value']:.2f}</td><td>-</td></tr>
        <tr><td>Unique Customers</td><td>{current['unique_customers']:,}</td><td>-</td></tr>
        </table>
        """
        
        # Send email report
        send_email_report("Daily Sales Report", report_html, ["stakeholder@company.com"])

def send_email_report(subject, html_content, recipients):
    """Send HTML email report"""
    
    msg = MIMEMultipart('alternative')
    msg['Subject'] = subject
    msg['From'] = "analytics@company.com"
    msg['To'] = ", ".join(recipients)
    
    # Attach HTML content
    html_part = MIMEText(html_content, 'html')
    msg.attach(html_part)
    
    # Send email (configure SMTP settings)
    try:
        server = smtplib.SMTP('smtp.company.com', 587)
        server.starttls()
        server.login("analytics@company.com", "password")
        server.sendmail(msg['From'], recipients, msg.as_string())
        server.quit()
        print("✅ Email report sent successfully")
    except Exception as e:
        print(f"❌ Email sending failed: {e}")

# Schedule the report
schedule.every().day.at("09:00").do(daily_sales_report)
```

### 2. Data Quality Monitoring

**Use Case**: Automatic alerts when data quality issues are detected
**Benefits**: Early problem detection, data integrity assurance

```python
def automated_data_quality_check():
    """Monitor data quality and send alerts"""
    
    quality_checks = {
        'orders_today': """
            SELECT COUNT(*) as count 
            FROM orders 
            WHERE DATE(order_date) = CURRENT_DATE
        """,
        'null_customer_ids': """
            SELECT COUNT(*) as count 
            FROM orders 
            WHERE customer_id IS NULL 
            AND DATE(order_date) = CURRENT_DATE
        """,
        'duplicate_orders': """
            SELECT COUNT(*) - COUNT(DISTINCT order_id) as count
            FROM orders 
            WHERE DATE(order_date) = CURRENT_DATE
        """
    }
    
    alerts = []
    
    for check_name, query in quality_checks.items():
        result = pd.read_sql_query(query, engine)
        count = result.iloc[0]['count']
        
        # Define alert conditions
        if check_name == 'orders_today' and count < 10:
            alerts.append(f"Low order volume today: {count} orders")
        elif check_name == 'null_customer_ids' and count > 0:
            alerts.append(f"Found {count} orders with null customer_id")
        elif check_name == 'duplicate_orders' and count > 0:
            alerts.append(f"Found {count} duplicate orders")
    
    # Send alerts if any issues found
    if alerts:
        alert_message = "\\n".join(alerts)
        send_alert_email("Data Quality Alert", alert_message)
        print(f"⚠️  Data quality issues detected: {len(alerts)} alerts")
    else:
        print("✅ All data quality checks passed")

def send_alert_email(subject, message):
    """Send simple alert email"""
    # Implementation similar to send_email_report
    pass

# Schedule quality checks
schedule.every().hour.do(automated_data_quality_check)
```

### 3. Performance Monitoring Dashboard

**Use Case**: Real-time business metrics monitoring
**Benefits**: Quick access to key metrics, trend identification

```python
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import dash
from dash import dcc, html
from dash.dependencies import Input, Output

def create_realtime_dashboard():
    """Create a real-time business dashboard"""
    
    app = dash.Dash(__name__)
    
    app.layout = html.Div([
        html.H1("Business Performance Dashboard"),
        
        dcc.Interval(
            id='interval-component',
            interval=300*1000,  # Update every 5 minutes
            n_intervals=0
        ),
        
        html.Div([
            html.Div([
                dcc.Graph(id='revenue-trend')
            ], className="six columns"),
            
            html.Div([
                dcc.Graph(id='order-volume')
            ], className="six columns"),
        ], className="row"),
        
        html.Div([
            dcc.Graph(id='customer-metrics')
        ])
    ])
    
    @app.callback(
        [Output('revenue-trend', 'figure'),
         Output('order-volume', 'figure'),
         Output('customer-metrics', 'figure')],
        [Input('interval-component', 'n_intervals')]
    )
    def update_dashboard(n):
        # Revenue trend
        revenue_query = """
        SELECT 
            DATE(order_date) as date,
            SUM(order_amount) as revenue
        FROM orders
        WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY DATE(order_date)
        ORDER BY date
        """
        
        revenue_data = pd.read_sql_query(revenue_query, engine)
        
        revenue_fig = px.line(
            revenue_data, 
            x='date', 
            y='revenue',
            title='30-Day Revenue Trend'
        )
        
        # Order volume
        order_query = """
        SELECT 
            EXTRACT(HOUR FROM order_timestamp) as hour,
            COUNT(*) as orders
        FROM orders
        WHERE DATE(order_date) = CURRENT_DATE
        GROUP BY EXTRACT(HOUR FROM order_timestamp)
        ORDER BY hour
        """
        
        order_data = pd.read_sql_query(order_query, engine)
        
        order_fig = px.bar(
            order_data,
            x='hour',
            y='orders',
            title='Today\'s Hourly Order Volume'
        )
        
        # Customer metrics
        customer_query = """
        SELECT 
            'New Customers' as metric,
            COUNT(*) as value
        FROM customers
        WHERE DATE(registration_date) = CURRENT_DATE
        
        UNION ALL
        
        SELECT 
            'Returning Customers' as metric,
            COUNT(DISTINCT customer_id) as value
        FROM orders
        WHERE DATE(order_date) = CURRENT_DATE
        AND customer_id IN (
            SELECT customer_id 
            FROM orders 
            WHERE DATE(order_date) < CURRENT_DATE
        )
        """
        
        customer_data = pd.read_sql_query(customer_query, engine)
        
        customer_fig = px.pie(
            customer_data,
            values='value',
            names='metric',
            title='Customer Composition Today'
        )
        
        return revenue_fig, order_fig, customer_fig
    
    return app

# Run dashboard
dashboard_app = create_realtime_dashboard()
# dashboard_app.run_server(debug=True, port=8050)
```

### 4. Automated Alerting System

**Use Case**: Proactive notifications for business events
**Benefits**: Immediate response to important changes

```python
class BusinessAlertSystem:
    """Comprehensive business alerting system"""
    
    def __init__(self, engine, alert_config):
        self.engine = engine
        self.config = alert_config
        
    def check_revenue_anomalies(self):
        """Detect unusual revenue patterns"""
        
        query = """
        WITH daily_revenue AS (
            SELECT 
                DATE(order_date) as date,
                SUM(order_amount) as revenue
            FROM orders
            WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY DATE(order_date)
        ),
        revenue_stats AS (
            SELECT 
                AVG(revenue) as avg_revenue,
                STDDEV(revenue) as stddev_revenue
            FROM daily_revenue
            WHERE date < CURRENT_DATE
        )
        SELECT 
            dr.date,
            dr.revenue,
            rs.avg_revenue,
            rs.stddev_revenue,
            ABS(dr.revenue - rs.avg_revenue) / rs.stddev_revenue as z_score
        FROM daily_revenue dr
        CROSS JOIN revenue_stats rs
        WHERE dr.date = CURRENT_DATE
        """
        
        result = pd.read_sql_query(query, self.engine)
        
        if not result.empty:
            z_score = result.iloc[0]['z_score']
            current_revenue = result.iloc[0]['revenue']
            avg_revenue = result.iloc[0]['avg_revenue']
            
            if z_score > 2:  # More than 2 standard deviations
                if current_revenue > avg_revenue:
                    self.send_alert(
                        "Exceptional Revenue Day",
                        f"Today's revenue (${current_revenue:,.2f}) is significantly higher than normal (avg: ${avg_revenue:,.2f})"
                    )
                else:
                    self.send_alert(
                        "Revenue Alert",
                        f"Today's revenue (${current_revenue:,.2f}) is significantly lower than normal (avg: ${avg_revenue:,.2f})"
                    )
    
    def check_conversion_rates(self):
        """Monitor conversion rate changes"""
        
        query = """
        WITH daily_metrics AS (
            SELECT 
                DATE(session_date) as date,
                COUNT(*) as sessions,
                COUNT(CASE WHEN converted = true THEN 1 END) as conversions,
                COUNT(CASE WHEN converted = true THEN 1 END)::float / COUNT(*) as conversion_rate
            FROM website_sessions
            WHERE session_date >= CURRENT_DATE - INTERVAL '7 days'
            GROUP BY DATE(session_date)
        )
        SELECT 
            date,
            conversion_rate,
            LAG(conversion_rate) OVER (ORDER BY date) as prev_conversion_rate
        FROM daily_metrics
        ORDER BY date DESC
        LIMIT 1
        """
        
        result = pd.read_sql_query(query, self.engine)
        
        if not result.empty:
            current_rate = result.iloc[0]['conversion_rate']
            prev_rate = result.iloc[0]['prev_conversion_rate']
            
            if prev_rate and abs(current_rate - prev_rate) / prev_rate > 0.2:  # 20% change
                change_direction = "increased" if current_rate > prev_rate else "decreased"
                self.send_alert(
                    "Conversion Rate Alert",
                    f"Conversion rate {change_direction} significantly: {current_rate:.2%} vs {prev_rate:.2%}"
                )
    
    def send_alert(self, title, message):
        """Send alert notification"""
        print(f"🚨 ALERT: {title}")
        print(f"   {message}")
        # Implement email, Slack, or other notification methods
        
    def run_all_checks(self):
        """Run all monitoring checks"""
        self.check_revenue_anomalies()
        self.check_conversion_rates()
        # Add more checks as needed

# Configure and schedule alerts
alert_config = {
    'revenue_threshold': 2,  # Z-score threshold
    'conversion_threshold': 0.2,  # 20% change threshold
}

alert_system = BusinessAlertSystem(engine, alert_config)
schedule.every(30).minutes.do(alert_system.run_all_checks)
```

## Deployment and Scheduling Options

### 1. Local Scheduling with Windows Task Scheduler

```python
# Create a main script: automated_analytics.py
import schedule
import time
import logging

# Set up logging
logging.basicConfig(
    filename='analytics_automation.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def run_automation():
    """Main automation runner"""
    try:
        # Schedule all your automated tasks
        schedule.every().day.at("09:00").do(daily_sales_report)
        schedule.every().hour.do(automated_data_quality_check)
        schedule.every(30).minutes.do(lambda: alert_system.run_all_checks())
        
        while True:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
            
    except KeyboardInterrupt:
        logging.info("Automation stopped by user")
    except Exception as e:
        logging.error(f"Automation error: {e}")

if __name__ == "__main__":
    run_automation()
```

### 2. Cloud Deployment Options

**AWS Lambda** (for serverless automation):
```python
import json
import boto3

def lambda_handler(event, context):
    """AWS Lambda function for automated reports"""
    
    # Your automated analysis code here
    result = daily_sales_report()
    
    return {
        'statusCode': 200,
        'body': json.dumps('Report generated successfully')
    }
```

**Google Cloud Functions**:
```python
def automated_report(request):
    """Google Cloud Function for automation"""
    
    try:
        # Run your automated analysis
        daily_sales_report()
        return 'Success', 200
    except Exception as e:
        return f'Error: {str(e)}', 500
```

## Best Practices for Automation

### 1. Error Handling and Monitoring
- Implement comprehensive logging
- Set up error notifications
- Include retry logic for failed operations
- Monitor resource usage and performance

### 2. Configuration Management
```python
import configparser
import os

class AutomationConfig:
    """Centralized configuration management"""
    
    def __init__(self, config_file='automation_config.ini'):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
    
    @property
    def database_url(self):
        return os.getenv('DATABASE_URL', self.config.get('database', 'url'))
    
    @property
    def email_recipients(self):
        return self.config.get('notifications', 'email_recipients').split(',')
    
    @property
    def alert_thresholds(self):
        return {
            'revenue_z_score': self.config.getfloat('alerts', 'revenue_z_score'),
            'conversion_change': self.config.getfloat('alerts', 'conversion_change')
        }

# Usage
config = AutomationConfig()
engine = create_engine(config.database_url)
```

### 3. Testing and Validation
```python
def test_automation_functions():
    """Test all automation functions before deployment"""
    
    tests = []
    
    try:
        # Test database connection
        test_query = "SELECT 1"
        result = pd.read_sql_query(test_query, engine)
        tests.append(("Database Connection", "PASS"))
    except Exception as e:
        tests.append(("Database Connection", f"FAIL: {e}"))
    
    try:
        # Test email configuration
        send_test_email()
        tests.append(("Email Configuration", "PASS"))
    except Exception as e:
        tests.append(("Email Configuration", f"FAIL: {e}"))
    
    # Print test results
    for test_name, result in tests:
        status_symbol = "✅" if result == "PASS" else "❌"
        print(f"{status_symbol} {test_name}: {result}")
    
    return all(result == "PASS" for _, result in tests)

def send_test_email():
    """Send test email to verify configuration"""
    send_email_report(
        "Test Email - Automation System",
        "<p>This is a test email from the automated analytics system.</p>",
        ["test@company.com"]
    )
```

## Maintenance and Monitoring

### 1. Health Checks
```python
def system_health_check():
    """Monitor automation system health"""
    
    health_status = {
        'database_connection': False,
        'last_report_time': None,
        'error_count_24h': 0,
        'memory_usage': 0
    }
    
    # Check database connection
    try:
        pd.read_sql_query("SELECT 1", engine)
        health_status['database_connection'] = True
    except:
        health_status['database_connection'] = False
    
    # Check memory usage
    import psutil
    health_status['memory_usage'] = psutil.virtual_memory().percent
    
    # Check error logs
    # Implementation depends on your logging setup
    
    return health_status
```

### 2. Performance Optimization
- Cache frequently used query results
- Use connection pooling for database connections
- Implement query timeouts
- Monitor and optimize slow queries

---

**This completes the automation section. Your automated analytics system will help you deliver consistent, timely insights while freeing up time for more strategic analysis work.**
