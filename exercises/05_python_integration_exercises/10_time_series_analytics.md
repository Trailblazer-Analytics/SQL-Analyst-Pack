# Exercise 10: Advanced Time Series Analytics with Python and SQL

## Business Context

You're a **Senior Data Analyst** at **TrendCast Analytics**, a consulting firm specializing in forecasting and trend analysis for retail clients. Your client, **GlobalRetail Corp**, needs sophisticated time series analysis to optimize inventory planning, predict seasonal demand, and identify emerging market trends. You'll build production-ready time series analytics combining SQL data extraction with Python's advanced statistical modeling capabilities.

## Learning Objectives

By completing this exercise, you will:

- Master time series data preparation and feature engineering with SQL
- Implement advanced forecasting models using Python (ARIMA, Prophet, seasonal decomposition)
- Build automated anomaly detection systems for business metrics
- Create real-time trend analysis and early warning systems
- Design production deployment for time series models
- Develop comprehensive time series reporting and visualization

## Business Scenario: Retail Demand Forecasting

**Stakeholder:** Sarah Chen, VP of Supply Chain Operations  
**Challenge:** "We need accurate demand forecasting to optimize inventory levels and reduce stockouts while minimizing carrying costs."

**Key Requirements:**
1. **Seasonal Forecasting**: Predict demand 12 weeks ahead with seasonal adjustments
2. **Anomaly Detection**: Identify unusual patterns that require immediate attention
3. **Multi-Product Analysis**: Scale forecasting across 500+ product categories
4. **Real-Time Updates**: Daily model updates with new sales data
5. **Business Insights**: Actionable recommendations for inventory management

## Dataset Overview

### Time Series Tables
```sql
-- Daily sales data with multiple dimensions
sales_daily (
    date_id DATE,
    product_category VARCHAR(100),
    region VARCHAR(50),
    sales_units INTEGER,
    sales_revenue DECIMAL(10,2),
    promotion_flag BOOLEAN,
    weather_condition VARCHAR(20)
);

-- External factors affecting demand
market_factors (
    date_id DATE,
    economic_index DECIMAL(8,4),
    competitor_promotion_intensity DECIMAL(5,2),
    seasonal_events VARCHAR(100),
    social_media_mentions INTEGER
);

-- Inventory and supply chain data
inventory_daily (
    date_id DATE,
    product_category VARCHAR(100),
    stock_level INTEGER,
    reorder_point INTEGER,
    lead_time_days INTEGER,
    stockout_flag BOOLEAN
);
```

## Tasks

### Task 1: Advanced Time Series Data Preparation

**Business Objective**: Create comprehensive time series datasets with engineered features for forecasting models.

#### 1.1 SQL Data Foundation
```sql
-- Create comprehensive time series dataset with lag features
WITH daily_metrics AS (
    SELECT 
        date_id,
        product_category,
        region,
        sales_units,
        sales_revenue,
        promotion_flag,
        
        -- Lag features for model input
        LAG(sales_units, 1) OVER (PARTITION BY product_category, region ORDER BY date_id) as sales_lag_1,
        LAG(sales_units, 7) OVER (PARTITION BY product_category, region ORDER BY date_id) as sales_lag_7,
        LAG(sales_units, 14) OVER (PARTITION BY product_category, region ORDER BY date_id) as sales_lag_14,
        
        -- Rolling averages
        AVG(sales_units) OVER (
            PARTITION BY product_category, region 
            ORDER BY date_id 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as rolling_avg_7d,
        
        AVG(sales_units) OVER (
            PARTITION BY product_category, region 
            ORDER BY date_id 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) as rolling_avg_30d,
        
        -- Volatility measures
        STDDEV(sales_units) OVER (
            PARTITION BY product_category, region 
            ORDER BY date_id 
            ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
        ) as rolling_std_14d,
        
        -- Trend indicators
        sales_units - LAG(sales_units, 7) OVER (
            PARTITION BY product_category, region ORDER BY date_id
        ) as week_over_week_change,
        
        CASE 
            WHEN EXTRACT(DOW FROM date_id) IN (6, 0) THEN 1 
            ELSE 0 
        END as is_weekend,
        
        EXTRACT(MONTH FROM date_id) as month_num,
        EXTRACT(QUARTER FROM date_id) as quarter_num
        
    FROM sales_daily
),

enriched_dataset AS (
    SELECT 
        dm.*,
        mf.economic_index,
        mf.competitor_promotion_intensity,
        mf.seasonal_events,
        mf.social_media_mentions,
        
        id.stock_level,
        id.stockout_flag,
        
        -- Create seasonality features
        SIN(2 * PI() * EXTRACT(DOY FROM date_id) / 365.25) as seasonal_sin,
        COS(2 * PI() * EXTRACT(DOY FROM date_id) / 365.25) as seasonal_cos,
        
        -- Holiday proximity features
        CASE 
            WHEN mf.seasonal_events LIKE '%Christmas%' THEN 1
            WHEN mf.seasonal_events LIKE '%Black Friday%' THEN 1
            ELSE 0
        END as major_holiday_flag
        
    FROM daily_metrics dm
    LEFT JOIN market_factors mf ON dm.date_id = mf.date_id
    LEFT JOIN inventory_daily id ON dm.date_id = id.date_id 
        AND dm.product_category = id.product_category
)

SELECT * FROM enriched_dataset
WHERE date_id >= CURRENT_DATE - INTERVAL '2 years'
ORDER BY product_category, region, date_id;
```

#### 1.2 Python Time Series Pipeline
```python
import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import matplotlib.pyplot as plt
import seaborn as sns
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.arima.model import ARIMA
from prophet import Prophet
from sklearn.metrics import mean_absolute_error, mean_squared_error
import warnings
warnings.filterwarnings('ignore')

class TimeSeriesAnalyzer:
    """Advanced time series analysis for retail demand forecasting"""
    
    def __init__(self, connection_string):
        self.engine = create_engine(connection_string)
        self.models = {}
        self.forecasts = {}
        
    def extract_time_series_data(self, product_category=None, region=None):
        """Extract and prepare time series data from SQL"""
        
        query = """
        WITH daily_metrics AS (
            -- Your SQL query from above
        )
        SELECT * FROM enriched_dataset
        WHERE 1=1
        """
        
        if product_category:
            query += f" AND product_category = '{product_category}'"
        if region:
            query += f" AND region = '{region}'"
            
        query += " ORDER BY date_id"
        
        df = pd.read_sql(query, self.engine)
        df['date_id'] = pd.to_datetime(df['date_id'])
        df.set_index('date_id', inplace=True)
        
        return df
    
    def decompose_time_series(self, df, target_column='sales_units'):
        """Perform seasonal decomposition analysis"""
        
        decomposition = seasonal_decompose(
            df[target_column].dropna(), 
            model='additive', 
            period=7  # Weekly seasonality
        )
        
        # Create comprehensive decomposition plot
        fig, axes = plt.subplots(4, 1, figsize=(15, 12))
        
        decomposition.observed.plot(ax=axes[0], title='Original Time Series')
        decomposition.trend.plot(ax=axes[1], title='Trend Component')
        decomposition.seasonal.plot(ax=axes[2], title='Seasonal Component')
        decomposition.resid.plot(ax=axes[3], title='Residual Component')
        
        plt.tight_layout()
        plt.savefig('time_series_decomposition.png', dpi=300, bbox_inches='tight')
        
        return decomposition
    
    def build_prophet_model(self, df, target_column='sales_units'):
        """Build Facebook Prophet forecasting model"""
        
        # Prepare data for Prophet
        prophet_df = df.reset_index()[['date_id', target_column]].copy()
        prophet_df.columns = ['ds', 'y']
        prophet_df = prophet_df.dropna()
        
        # Initialize Prophet with business-relevant parameters
        model = Prophet(
            yearly_seasonality=True,
            weekly_seasonality=True,
            daily_seasonality=False,
            holidays_prior_scale=10.0,
            seasonality_prior_scale=10.0,
            changepoint_prior_scale=0.05
        )
        
        # Add custom regressors for external factors
        if 'promotion_flag' in df.columns:
            model.add_regressor('promotion_flag')
            prophet_df['promotion_flag'] = df['promotion_flag'].values
        
        if 'economic_index' in df.columns:
            model.add_regressor('economic_index')
            prophet_df['economic_index'] = df['economic_index'].fillna(method='ffill').values
        
        # Fit model
        model.fit(prophet_df)
        
        # Generate future dataframe for forecasting
        future = model.make_future_dataframe(periods=84)  # 12 weeks ahead
        
        # Add regressor values for future periods
        if 'promotion_flag' in df.columns:
            future['promotion_flag'] = 0  # Assume no promotions in forecast
        if 'economic_index' in df.columns:
            future['economic_index'] = df['economic_index'].fillna(method='ffill').iloc[-1]
        
        # Generate forecast
        forecast = model.predict(future)
        
        return model, forecast
    
    def detect_anomalies(self, df, target_column='sales_units', threshold=2.5):
        """Detect anomalies in time series data"""
        
        # Calculate rolling statistics
        rolling_mean = df[target_column].rolling(window=14).mean()
        rolling_std = df[target_column].rolling(window=14).std()
        
        # Identify anomalies using statistical threshold
        anomalies = df[
            (df[target_column] > rolling_mean + threshold * rolling_std) |
            (df[target_column] < rolling_mean - threshold * rolling_std)
        ].copy()
        
        # Enhanced anomaly analysis
        anomalies['anomaly_score'] = np.abs(
            (anomalies[target_column] - rolling_mean) / rolling_std
        )
        
        # Business context for anomalies
        anomalies['business_impact'] = anomalies['anomaly_score'].apply(
            lambda x: 'HIGH' if x > 4 else 'MEDIUM' if x > 3 else 'LOW'
        )
        
        return anomalies
    
    def generate_forecast_report(self, model, forecast, actual_data, product_category):
        """Generate comprehensive forecasting report"""
        
        # Calculate accuracy metrics
        forecast_subset = forecast[forecast['ds'].isin(actual_data.index)]
        if len(forecast_subset) > 0:
            mae = mean_absolute_error(
                actual_data['sales_units'].iloc[-len(forecast_subset):], 
                forecast_subset['yhat']
            )
            mape = np.mean(np.abs(
                (actual_data['sales_units'].iloc[-len(forecast_subset):] - forecast_subset['yhat']) 
                / actual_data['sales_units'].iloc[-len(forecast_subset):]
            )) * 100
        else:
            mae = np.nan
            mape = np.nan
        
        # Create forecast visualization
        fig, ax = plt.subplots(figsize=(15, 8))
        
        # Plot historical data
        actual_data['sales_units'].plot(ax=ax, label='Actual Sales', color='blue')
        
        # Plot forecast
        forecast_future = forecast[forecast['ds'] > actual_data.index.max()]
        ax.plot(forecast_future['ds'], forecast_future['yhat'], 
                label='Forecast', color='red', linestyle='--')
        
        # Plot confidence intervals
        ax.fill_between(forecast_future['ds'], 
                       forecast_future['yhat_lower'], 
                       forecast_future['yhat_upper'], 
                       alpha=0.3, color='red', label='Confidence Interval')
        
        ax.set_title(f'Sales Forecast - {product_category}')
        ax.set_xlabel('Date')
        ax.set_ylabel('Sales Units')
        ax.legend()
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(f'forecast_{product_category.replace(" ", "_")}.png', 
                   dpi=300, bbox_inches='tight')
        
        # Business insights
        insights = {
            'product_category': product_category,
            'forecast_horizon': '12 weeks',
            'mae': mae,
            'mape': f"{mape:.2f}%",
            'avg_weekly_forecast': forecast_future['yhat'].mean(),
            'seasonal_peak': forecast_future.loc[forecast_future['yhat'].idxmax(), 'ds'],
            'seasonal_trough': forecast_future.loc[forecast_future['yhat'].idxmin(), 'ds'],
            'business_recommendations': self._generate_business_recommendations(forecast_future)
        }
        
        return insights
    
    def _generate_business_recommendations(self, forecast_data):
        """Generate actionable business recommendations"""
        
        recommendations = []
        
        # Trend analysis
        trend_change = (forecast_data['yhat'].iloc[-1] - forecast_data['yhat'].iloc[0]) / forecast_data['yhat'].iloc[0]
        
        if trend_change > 0.1:
            recommendations.append("GROWTH: Increase inventory levels by 15% to meet rising demand")
        elif trend_change < -0.1:
            recommendations.append("DECLINE: Reduce inventory and consider promotional activities")
        
        # Seasonality insights
        volatility = forecast_data['yhat'].std() / forecast_data['yhat'].mean()
        if volatility > 0.3:
            recommendations.append("HIGH VOLATILITY: Implement flexible ordering system")
        
        # Risk assessment
        confidence_width = (forecast_data['yhat_upper'] - forecast_data['yhat_lower']).mean()
        relative_uncertainty = confidence_width / forecast_data['yhat'].mean()
        
        if relative_uncertainty > 0.5:
            recommendations.append("HIGH UNCERTAINTY: Monitor weekly and adjust forecasts")
        
        return recommendations

# Initialize analyzer
analyzer = TimeSeriesAnalyzer('postgresql://user:pass@localhost/retaildb')

# Run comprehensive analysis
categories = ['Electronics', 'Clothing', 'Home & Garden']
results = {}

for category in categories:
    print(f"\n=== Analyzing {category} ===")
    
    # Extract data
    df = analyzer.extract_time_series_data(product_category=category)
    
    # Decompose time series
    decomposition = analyzer.decompose_time_series(df)
    
    # Build forecast model
    model, forecast = analyzer.build_prophet_model(df)
    
    # Detect anomalies
    anomalies = analyzer.detect_anomalies(df)
    print(f"Detected {len(anomalies)} anomalies")
    
    # Generate report
    insights = analyzer.generate_forecast_report(model, forecast, df, category)
    results[category] = insights
    
    print(f"Forecast accuracy (MAPE): {insights['mape']}")
    print(f"Recommendations: {insights['business_recommendations']}")

print("\n=== EXECUTIVE SUMMARY ===")
for category, result in results.items():
    print(f"{category}: {result['mape']} MAPE, {len(result['business_recommendations'])} recommendations")
```

### Task 2: Real-Time Anomaly Detection System

#### 2.1 Automated Anomaly Detection Pipeline
```python
import schedule
import time
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class RealTimeAnomalyDetector:
    """Real-time anomaly detection for business metrics"""
    
    def __init__(self, connection_string, alert_config):
        self.analyzer = TimeSeriesAnalyzer(connection_string)
        self.alert_config = alert_config
        self.anomaly_history = []
        
    def run_daily_anomaly_check(self):
        """Daily automated anomaly detection"""
        
        print(f"Running anomaly detection at {datetime.now()}")
        
        # Get yesterday's data
        yesterday = datetime.now() - timedelta(days=1)
        
        query = f"""
        SELECT 
            product_category,
            region,
            sales_units,
            sales_revenue,
            date_id
        FROM sales_daily 
        WHERE date_id = '{yesterday.strftime('%Y-%m-%d')}'
        """
        
        daily_data = pd.read_sql(query, self.analyzer.engine)
        
        # Check each product-region combination
        anomalies_detected = []
        
        for _, row in daily_data.iterrows():
            # Get historical data for comparison
            historical_query = f"""
            SELECT sales_units 
            FROM sales_daily 
            WHERE product_category = '{row['product_category']}'
                AND region = '{row['region']}'
                AND date_id BETWEEN '{(yesterday - timedelta(days=30)).strftime('%Y-%m-%d')}'
                AND '{(yesterday - timedelta(days=1)).strftime('%Y-%m-%d')}'
            ORDER BY date_id
            """
            
            historical_data = pd.read_sql(historical_query, self.analyzer.engine)
            
            if len(historical_data) > 7:  # Need minimum data for analysis
                # Calculate anomaly score
                mean_sales = historical_data['sales_units'].mean()
                std_sales = historical_data['sales_units'].std()
                
                z_score = abs((row['sales_units'] - mean_sales) / std_sales)
                
                if z_score > 2.5:  # Anomaly threshold
                    anomaly = {
                        'date': row['date_id'],
                        'product_category': row['product_category'],
                        'region': row['region'],
                        'actual_sales': row['sales_units'],
                        'expected_sales': mean_sales,
                        'anomaly_score': z_score,
                        'impact': 'HIGH' if z_score > 4 else 'MEDIUM'
                    }
                    anomalies_detected.append(anomaly)
        
        # Process anomalies
        if anomalies_detected:
            self._process_anomalies(anomalies_detected)
            
        return anomalies_detected
    
    def _process_anomalies(self, anomalies):
        """Process detected anomalies and send alerts"""
        
        high_impact_anomalies = [a for a in anomalies if a['impact'] == 'HIGH']
        
        if high_impact_anomalies:
            # Send immediate alert for high-impact anomalies
            self._send_alert_email(high_impact_anomalies)
            
        # Log all anomalies
        for anomaly in anomalies:
            self.anomaly_history.append({
                **anomaly,
                'detected_at': datetime.now(),
                'status': 'NEW'
            })
            
        # Store anomalies in database
        self._store_anomalies(anomalies)
    
    def _send_alert_email(self, anomalies):
        """Send email alert for critical anomalies"""
        
        msg = MIMEMultipart()
        msg['From'] = self.alert_config['from_email']
        msg['To'] = ', '.join(self.alert_config['alert_recipients'])
        msg['Subject'] = f"🚨 CRITICAL: {len(anomalies)} Sales Anomalies Detected"
        
        body = "Critical sales anomalies detected:\n\n"
        
        for anomaly in anomalies:
            body += f"""
Product: {anomaly['product_category']}
Region: {anomaly['region']}
Date: {anomaly['date']}
Actual Sales: {anomaly['actual_sales']:,}
Expected Sales: {anomaly['expected_sales']:,.0f}
Anomaly Score: {anomaly['anomaly_score']:.2f}
---
"""
        
        body += "\nPlease investigate immediately and update stakeholders."
        
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        try:
            server = smtplib.SMTP(self.alert_config['smtp_server'], 587)
            server.starttls()
            server.login(self.alert_config['email_user'], self.alert_config['email_password'])
            server.sendmail(msg['From'], self.alert_config['alert_recipients'], msg.as_string())
            server.quit()
            print("Alert email sent successfully")
        except Exception as e:
            print(f"Failed to send alert email: {e}")
    
    def _store_anomalies(self, anomalies):
        """Store anomalies in database for tracking"""
        
        for anomaly in anomalies:
            insert_query = """
            INSERT INTO anomaly_log (
                detected_date, product_category, region,
                actual_value, expected_value, anomaly_score,
                impact_level, status, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            # Execute insert (implement based on your database)
            print(f"Logged anomaly: {anomaly['product_category']} - {anomaly['region']}")

# Configure real-time monitoring
alert_config = {
    'from_email': 'alerts@trendcast.com',
    'alert_recipients': ['sarah.chen@globalretail.com', 'data-team@trendcast.com'],
    'smtp_server': 'smtp.gmail.com',
    'email_user': 'alerts@trendcast.com',
    'email_password': 'your_app_password'
}

detector = RealTimeAnomalyDetector('postgresql://user:pass@localhost/retaildb', alert_config)

# Schedule daily checks
schedule.every().day.at("08:00").do(detector.run_daily_anomaly_check)
schedule.every().day.at("14:00").do(detector.run_daily_anomaly_check)

print("Real-time anomaly detection system started...")
print("Monitoring sales data for anomalies...")

# Keep the system running
while True:
    schedule.run_pending()
    time.sleep(60)  # Check every minute
```

### Task 3: Production Deployment and Monitoring

#### 3.1 Docker Deployment Configuration
```dockerfile
# Dockerfile for time series analytics service
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create directories for outputs
RUN mkdir -p /app/outputs /app/logs

# Set environment variables
ENV PYTHONPATH=/app
ENV TZ=UTC

# Expose port for health checks
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')"

# Run the application
CMD ["python", "time_series_service.py"]
```

#### 3.2 Production Service Implementation
```python
from flask import Flask, jsonify, request
import logging
from datetime import datetime
import os

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/time_series_service.log'),
        logging.StreamHandler()
    ]
)

class TimeSeriesService:
    """Production time series analytics service"""
    
    def __init__(self):
        self.analyzer = TimeSeriesAnalyzer(os.getenv('DATABASE_URL'))
        self.detector = RealTimeAnomalyDetector(
            os.getenv('DATABASE_URL'),
            {
                'from_email': os.getenv('ALERT_FROM_EMAIL'),
                'alert_recipients': os.getenv('ALERT_RECIPIENTS').split(','),
                'smtp_server': os.getenv('SMTP_SERVER'),
                'email_user': os.getenv('EMAIL_USER'),
                'email_password': os.getenv('EMAIL_PASSWORD')
            }
        )
        
service = TimeSeriesService()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'time_series_analytics'
    })

@app.route('/forecast', methods=['POST'])
def generate_forecast():
    """Generate forecast for specific product-region combination"""
    
    try:
        data = request.json
        product_category = data.get('product_category')
        region = data.get('region')
        forecast_days = data.get('forecast_days', 84)
        
        logging.info(f"Generating forecast for {product_category} in {region}")
        
        # Extract data and generate forecast
        df = service.analyzer.extract_time_series_data(product_category, region)
        model, forecast = service.analyzer.build_prophet_model(df)
        insights = service.analyzer.generate_forecast_report(
            model, forecast, df, product_category
        )
        
        return jsonify({
            'success': True,
            'forecast': insights,
            'generated_at': datetime.now().isoformat()
        })
        
    except Exception as e:
        logging.error(f"Forecast generation failed: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/anomalies/detect', methods=['POST'])
def detect_anomalies():
    """Run anomaly detection"""
    
    try:
        anomalies = service.detector.run_daily_anomaly_check()
        
        return jsonify({
            'success': True,
            'anomalies_detected': len(anomalies),
            'anomalies': anomalies,
            'checked_at': datetime.now().isoformat()
        })
        
    except Exception as e:
        logging.error(f"Anomaly detection failed: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/metrics/dashboard', methods=['GET'])
def dashboard_metrics():
    """Get metrics for monitoring dashboard"""
    
    try:
        # Get recent forecasting accuracy
        accuracy_query = """
        SELECT 
            product_category,
            AVG(forecast_accuracy) as avg_accuracy,
            COUNT(*) as forecast_count
        FROM forecast_log 
        WHERE created_at >= NOW() - INTERVAL '7 days'
        GROUP BY product_category
        ORDER BY avg_accuracy DESC
        """
        
        accuracy_data = pd.read_sql(accuracy_query, service.analyzer.engine)
        
        # Get recent anomalies
        anomaly_query = """
        SELECT 
            COUNT(*) as total_anomalies,
            SUM(CASE WHEN impact_level = 'HIGH' THEN 1 ELSE 0 END) as high_impact,
            SUM(CASE WHEN status = 'RESOLVED' THEN 1 ELSE 0 END) as resolved
        FROM anomaly_log 
        WHERE detected_date >= NOW() - INTERVAL '7 days'
        """
        
        anomaly_data = pd.read_sql(anomaly_query, service.analyzer.engine)
        
        return jsonify({
            'success': True,
            'metrics': {
                'forecast_accuracy': accuracy_data.to_dict('records'),
                'anomaly_summary': anomaly_data.to_dict('records')[0],
                'system_status': 'operational',
                'last_updated': datetime.now().isoformat()
            }
        })
        
    except Exception as e:
        logging.error(f"Dashboard metrics failed: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
```

## Business Impact Assessment

### Key Metrics and KPIs
- **Forecast Accuracy**: Achieve <15% MAPE for 12-week forecasts
- **Anomaly Detection**: <30 minutes from occurrence to alert
- **Inventory Optimization**: 20% reduction in stockouts, 15% reduction in carrying costs
- **Processing Speed**: Real-time analysis of 500+ product categories
- **System Reliability**: 99.5% uptime for production service

### ROI Calculation
- **Cost Savings**: $2.3M annually from optimized inventory management
- **Revenue Protection**: $1.8M annually from faster anomaly response
- **Implementation Cost**: $450K (development + infrastructure)
- **ROI**: 811% over 2 years

## Extension Challenges

### Challenge 1: Multi-Store Forecasting
Extend the system to handle 200+ individual store locations with location-specific factors.

### Challenge 2: External Data Integration
Incorporate weather data, economic indicators, and social media sentiment into forecasting models.

### Challenge 3: Hierarchical Forecasting
Implement hierarchical forecasting that ensures store-level forecasts roll up to regional and national totals.

### Challenge 4: Model Ensemble
Build ensemble models combining ARIMA, Prophet, and machine learning approaches for improved accuracy.

---

*This exercise demonstrates production-ready time series analytics that directly supports critical business decisions in retail demand planning and inventory optimization.*
