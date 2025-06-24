# Exercise 11: Real-Time Analytics with Streaming Data

**Author:** Alexander Nykolaiszyn  |  **Last Updated:** 2025-06-24

## Business Context

You're a **Principal Data Engineer** at **StreamInsights Corp**, specializing in real-time analytics for digital businesses. Your client, **DigitalCommerce Plus**, needs a comprehensive real-time analytics system to monitor customer behavior, detect fraud, optimize marketing campaigns, and enable instant business decision-making. You'll build a production-grade streaming analytics platform combining real-time data ingestion, SQL stream processing, and Python-based real-time dashboards.

## Learning Objectives

By completing this exercise, you will:

- Build real-time data pipelines using Apache Kafka and Python
- Implement streaming SQL analytics for business metrics
- Create real-time fraud detection and anomaly monitoring
- Design live dashboards with automatic updates
- Deploy scalable real-time analytics infrastructure
- Develop real-time alerting and notification systems

## Business Scenario: Real-Time E-commerce Analytics

**Stakeholder:** Michael Rodriguez, Chief Technology Officer  
**Challenge:** "We need to move from batch analytics to real-time insights. Our business moves too fast for yesterday's reports."

**Key Requirements:**

1. **Real-Time Monitoring**: Track customer behavior and business KPIs as they happen
2. **Fraud Detection**: Identify suspicious transactions within seconds
3. **Campaign Optimization**: Adjust marketing campaigns based on real-time performance
4. **Inventory Alerts**: Notify when products approach stockout thresholds
5. **Customer Experience**: Monitor and respond to user experience issues instantly

## Architecture Overview

### Real-Time Data Flow

```text
Customer Actions → Web/Mobile Apps → Kafka Streams → SQL Processing → Dashboards
                                        → Alerting System
                                        → Machine Learning Models
```

### Technology Stack

- **Streaming Platform**: Apache Kafka
- **Stream Processing**: Kafka Streams, Python
- **Real-Time SQL**: ksqlDB, Materialized Views
- **Dashboards**: Streamlit, Plotly Dash
- **Alerts**: Custom Python service
- **Storage**: PostgreSQL (for persistence), Redis (for caching)

### Streaming Data Sources

```python
# Real-time event schemas
customer_events = {
    "event_id": "uuid",
    "customer_id": "string", 
    "event_type": "string",  # page_view, add_to_cart, purchase, etc.
    "product_id": "string",
    "session_id": "string",
    "timestamp": "datetime",
    "page_url": "string",
    "device_type": "string",
    "location": "geo_point",
    "revenue": "decimal",
    "properties": "json"
}

transaction_events = {
    "transaction_id": "uuid",
    "customer_id": "string",
    "amount": "decimal",
    "currency": "string",
    "payment_method": "string",
    "timestamp": "datetime",
    "merchant_category": "string",
    "location": "geo_point",
    "risk_score": "float",
    "status": "string"
}

inventory_events = {
    "product_id": "string",
    "sku": "string",
    "current_stock": "integer",
    "reserved_stock": "integer",
    "warehouse_location": "string",
    "timestamp": "datetime",
    "reorder_point": "integer",
    "supplier_id": "string"
}
```

## Tasks

### Task 1: Real-Time Data Ingestion Pipeline

**Business Objective**: Build a robust real-time data pipeline that can handle high-volume streaming data with low latency.

#### 1.1 Kafka Producer Setup

```python
import json
import time
import random
from datetime import datetime, timedelta
from kafka import KafkaProducer
from faker import Faker
import uuid

class RealTimeDataSimulator:
    """Simulate real-time e-commerce events for testing"""
    
    def __init__(self, kafka_config):
        self.producer = KafkaProducer(
            bootstrap_servers=kafka_config['servers'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None
        )
        self.fake = Faker()
        self.customers = [str(uuid.uuid4()) for _ in range(1000)]
        self.products = [f"PROD_{i:05d}" for i in range(500)]
        
    def generate_customer_event(self):
        """Generate realistic customer behavior event"""
        
        event_types = ['page_view', 'product_view', 'add_to_cart', 'remove_from_cart', 'purchase']
        weights = [0.4, 0.25, 0.15, 0.05, 0.15]  # Realistic conversion funnel
        
        event = {
            'event_id': str(uuid.uuid4()),
            'customer_id': random.choice(self.customers),
            'event_type': random.choices(event_types, weights=weights)[0],
            'product_id': random.choice(self.products),
            'session_id': str(uuid.uuid4()),
            'timestamp': datetime.now().isoformat(),
            'page_url': f"/{self.fake.word()}/{random.randint(1, 100)}",
            'device_type': random.choice(['desktop', 'mobile', 'tablet']),
            'location': {
                'lat': float(self.fake.latitude()),
                'lon': float(self.fake.longitude()),
                'country': self.fake.country_code()
            },
            'revenue': round(random.uniform(10, 500), 2) if event['event_type'] == 'purchase' else 0,
            'properties': {
                'referrer': random.choice(['google', 'facebook', 'direct', 'email']),
                'user_agent': self.fake.user_agent(),
                'campaign_id': f"CAMP_{random.randint(100, 999)}"
            }
        }
        
        return event
    
    def generate_transaction_event(self):
        """Generate transaction event with fraud indicators"""
        
        # Simulate some fraudulent patterns
        is_fraud = random.random() < 0.02  # 2% fraud rate
        
        if is_fraud:
            # Fraudulent transactions often have certain patterns
            amount = round(random.uniform(500, 2000), 2)  # Higher amounts
            location = {'lat': 0.0, 'lon': 0.0, 'country': 'XX'}  # Invalid location
            risk_score = random.uniform(0.7, 1.0)  # High risk score
        else:
            amount = round(random.uniform(10, 300), 2)
            location = {
                'lat': float(self.fake.latitude()),
                'lon': float(self.fake.longitude()),
                'country': self.fake.country_code()
            }
            risk_score = random.uniform(0.0, 0.3)
        
        transaction = {
            'transaction_id': str(uuid.uuid4()),
            'customer_id': random.choice(self.customers),
            'amount': amount,
            'currency': 'USD',
            'payment_method': random.choice(['credit_card', 'debit_card', 'paypal', 'apple_pay']),
            'timestamp': datetime.now().isoformat(),
            'merchant_category': random.choice(['retail', 'grocery', 'gas', 'restaurant']),
            'location': location,
            'risk_score': risk_score,
            'status': 'pending'
        }
        
        return transaction
    
    def generate_inventory_event(self):
        """Generate inventory level update"""
        
        product_id = random.choice(self.products)
        current_stock = random.randint(0, 1000)
        reorder_point = random.randint(10, 50)
        
        inventory = {
            'product_id': product_id,
            'sku': f"SKU_{product_id}",
            'current_stock': current_stock,
            'reserved_stock': random.randint(0, min(current_stock, 20)),
            'warehouse_location': random.choice(['NYC', 'LAX', 'CHI', 'DFW']),
            'timestamp': datetime.now().isoformat(),
            'reorder_point': reorder_point,
            'supplier_id': f"SUP_{random.randint(100, 999)}",
            'low_stock_alert': current_stock <= reorder_point
        }
        
        return inventory
    
    def start_streaming(self, events_per_second=10):
        """Start streaming events to Kafka"""
        
        print(f"Starting real-time data simulation at {events_per_second} events/second")
        
        while True:
            try:
                # Generate different types of events
                for _ in range(events_per_second):
                    event_type = random.choices(
                        ['customer', 'transaction', 'inventory'],
                        weights=[0.7, 0.2, 0.1]
                    )[0]
                    
                    if event_type == 'customer':
                        event = self.generate_customer_event()
                        self.producer.send('customer_events', 
                                         key=event['customer_id'], 
                                         value=event)
                    
                    elif event_type == 'transaction':
                        event = self.generate_transaction_event()
                        self.producer.send('transaction_events', 
                                         key=event['customer_id'], 
                                         value=event)
                    
                    elif event_type == 'inventory':
                        event = self.generate_inventory_event()
                        self.producer.send('inventory_events', 
                                         key=event['product_id'], 
                                         value=event)
                
                self.producer.flush()
                time.sleep(1)  # Wait 1 second before next batch
                
            except KeyboardInterrupt:
                print("Stopping data simulation...")
                break
            except Exception as e:
                print(f"Error in data simulation: {e}")
                time.sleep(5)  # Wait before retrying

# Start the simulation
kafka_config = {
    'servers': ['localhost:9092']
}

simulator = RealTimeDataSimulator(kafka_config)
simulator.start_streaming(events_per_second=50)
```

#### 1.2 Stream Processing with Python

```python
import json
from kafka import KafkaConsumer, KafkaProducer
import pandas as pd
from datetime import datetime, timedelta
import redis
import psycopg2
from sqlalchemy import create_engine
import threading
import logging

class RealTimeAnalyticsProcessor:
    """Process streaming data and generate real-time analytics"""
    
    def __init__(self, kafka_config, db_config, redis_config):
        self.kafka_config = kafka_config
        self.db_engine = create_engine(db_config['connection_string'])
        self.redis_client = redis.Redis(**redis_config)
        
        # Initialize producers for processed events
        self.producer = KafkaProducer(
            bootstrap_servers=kafka_config['servers'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        
        # Real-time metrics storage
        self.metrics_cache = {}
        
        # Setup logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def process_customer_events(self):
        """Process customer behavior events in real-time"""
        
        consumer = KafkaConsumer(
            'customer_events',
            bootstrap_servers=self.kafka_config['servers'],
            auto_offset_reset='latest',
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            group_id='customer_analytics_group'
        )
        
        # Sliding window for real-time metrics
        window_events = []
        window_duration = timedelta(minutes=5)
        
        for message in consumer:
            event = message.value
            current_time = datetime.fromisoformat(event['timestamp'])
            
            # Add to sliding window
            window_events.append(event)
            
            # Remove old events from window
            cutoff_time = current_time - window_duration
            window_events = [e for e in window_events 
                           if datetime.fromisoformat(e['timestamp']) > cutoff_time]
            
            # Calculate real-time metrics
            self._update_realtime_metrics(window_events, current_time)
            
            # Check for business alerts
            self._check_customer_alerts(event, window_events)
            
            # Store processed event for persistence
            self._store_processed_event(event, 'customer_events_processed')
    
    def process_transaction_events(self):
        """Process transaction events with fraud detection"""
        
        consumer = KafkaConsumer(
            'transaction_events',
            bootstrap_servers=self.kafka_config['servers'],
            auto_offset_reset='latest',
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            group_id='transaction_analytics_group'
        )
        
        for message in consumer:
            transaction = message.value
            
            # Real-time fraud detection
            fraud_score = self._calculate_fraud_score(transaction)
            transaction['enhanced_fraud_score'] = fraud_score
            
            # Update real-time transaction metrics
            self._update_transaction_metrics(transaction)
            
            # Check for fraud alerts
            if fraud_score > 0.8:
                self._send_fraud_alert(transaction)
            
            # Update transaction status based on fraud score
            if fraud_score > 0.9:
                transaction['status'] = 'blocked'
            elif fraud_score > 0.7:
                transaction['status'] = 'review'
            else:
                transaction['status'] = 'approved'
            
            # Send updated transaction
            self.producer.send('transactions_processed', value=transaction)
    
    def process_inventory_events(self):
        """Process inventory events with low stock alerts"""
        
        consumer = KafkaConsumer(
            'inventory_events',
            bootstrap_servers=self.kafka_config['servers'],
            auto_offset_reset='latest',
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            group_id='inventory_analytics_group'
        )
        
        for message in consumer:
            inventory = message.value
            
            # Cache current stock levels
            self.redis_client.hset(
                'current_inventory',
                inventory['product_id'],
                inventory['current_stock']
            )
            
            # Check for low stock alerts
            if inventory['low_stock_alert']:
                self._send_inventory_alert(inventory)
            
            # Update inventory metrics
            self._update_inventory_metrics(inventory)
    
    def _update_realtime_metrics(self, window_events, current_time):
        """Update real-time customer metrics"""
        
        if not window_events:
            return
        
        # Calculate key metrics for 5-minute window
        total_events = len(window_events)
        unique_customers = len(set(e['customer_id'] for e in window_events))
        page_views = len([e for e in window_events if e['event_type'] == 'page_view'])
        purchases = len([e for e in window_events if e['event_type'] == 'purchase'])
        total_revenue = sum(e['revenue'] for e in window_events)
        
        conversion_rate = (purchases / page_views * 100) if page_views > 0 else 0
        
        metrics = {
            'timestamp': current_time.isoformat(),
            'window_minutes': 5,
            'total_events': total_events,
            'unique_customers': unique_customers,
            'page_views': page_views,
            'purchases': purchases,
            'total_revenue': total_revenue,
            'conversion_rate': conversion_rate,
            'events_per_minute': total_events / 5
        }
        
        # Cache metrics in Redis for dashboard
        self.redis_client.hset('realtime_metrics', 'customer_metrics', json.dumps(metrics))
        
        # Log key metrics
        self.logger.info(f"Real-time metrics: {purchases} purchases, ${total_revenue:.2f} revenue, {conversion_rate:.2f}% conversion")
    
    def _calculate_fraud_score(self, transaction):
        """Calculate enhanced fraud score using real-time data"""
        
        score = transaction['risk_score']  # Base score
        
        # Check customer transaction history (last hour)
        customer_id = transaction['customer_id']
        hour_ago = (datetime.now() - timedelta(hours=1)).isoformat()
        
        # Get recent transactions from cache
        recent_key = f"recent_transactions:{customer_id}"
        recent_transactions = self.redis_client.lrange(recent_key, 0, -1)
        recent_transactions = [json.loads(t) for t in recent_transactions]
        
        # Velocity check: too many transactions
        if len(recent_transactions) > 5:
            score += 0.3
        
        # Amount check: significantly higher than recent average
        if recent_transactions:
            avg_amount = sum(float(t['amount']) for t in recent_transactions) / len(recent_transactions)
            if transaction['amount'] > avg_amount * 3:
                score += 0.2
        
        # Location check: different from recent transactions
        if recent_transactions:
            recent_countries = set(t.get('location', {}).get('country', '') for t in recent_transactions)
            if transaction['location']['country'] not in recent_countries:
                score += 0.15
        
        # Cache this transaction
        self.redis_client.lpush(recent_key, json.dumps(transaction))
        self.redis_client.ltrim(recent_key, 0, 9)  # Keep last 10 transactions
        self.redis_client.expire(recent_key, 3600)  # Expire after 1 hour
        
        return min(score, 1.0)  # Cap at 1.0
    
    def _update_transaction_metrics(self, transaction):
        """Update real-time transaction metrics"""
        
        # Update transaction counts and amounts
        current_minute = datetime.now().strftime('%Y-%m-%d %H:%M')
        
        # Increment transaction count
        self.redis_client.hincrby('transaction_metrics', f'{current_minute}:count', 1)
        
        # Add to transaction amount
        self.redis_client.hincrbyfloat('transaction_metrics', f'{current_minute}:amount', float(transaction['amount']))
        
        # Update fraud detection metrics
        if transaction['enhanced_fraud_score'] > 0.7:
            self.redis_client.hincrby('fraud_metrics', f'{current_minute}:flagged', 1)
    
    def _send_fraud_alert(self, transaction):
        """Send fraud alert for high-risk transaction"""
        
        alert = {
            'alert_type': 'fraud_detection',
            'severity': 'HIGH',
            'transaction_id': transaction['transaction_id'],
            'customer_id': transaction['customer_id'],
            'amount': transaction['amount'],
            'fraud_score': transaction['enhanced_fraud_score'],
            'timestamp': datetime.now().isoformat(),
            'details': transaction
        }
        
        # Send to alerts topic
        self.producer.send('fraud_alerts', value=alert)
        
        self.logger.warning(f"FRAUD ALERT: Transaction {transaction['transaction_id']} flagged with score {transaction['enhanced_fraud_score']:.2f}")
    
    def _send_inventory_alert(self, inventory):
        """Send low stock inventory alert"""
        
        alert = {
            'alert_type': 'low_inventory',
            'severity': 'MEDIUM',
            'product_id': inventory['product_id'],
            'current_stock': inventory['current_stock'],
            'reorder_point': inventory['reorder_point'],
            'warehouse': inventory['warehouse_location'],
            'timestamp': datetime.now().isoformat()
        }
        
        # Send to alerts topic
        self.producer.send('inventory_alerts', value=alert)
        
        self.logger.info(f"INVENTORY ALERT: Product {inventory['product_id']} low stock ({inventory['current_stock']} units)")
    
    def start_processing(self):
        """Start all processing threads"""
        
        threads = [
            threading.Thread(target=self.process_customer_events),
            threading.Thread(target=self.process_transaction_events),
            threading.Thread(target=self.process_inventory_events)
        ]
        
        for thread in threads:
            thread.daemon = True
            thread.start()
        
        self.logger.info("Real-time analytics processor started")
        
        # Keep main thread alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            self.logger.info("Shutting down processor...")

# Configuration
kafka_config = {'servers': ['localhost:9092']}
db_config = {'connection_string': 'postgresql://user:pass@localhost/ecommerce'}
redis_config = {'host': 'localhost', 'port': 6379, 'db': 0}

# Start processing
processor = RealTimeAnalyticsProcessor(kafka_config, db_config, redis_config)
processor.start_processing()
```

### Task 2: Real-Time Dashboard and Visualization

#### 2.1 Live Dashboard with Streamlit

```python
import streamlit as st
import plotly.graph_objects as go
import plotly.express as px
import pandas as pd
import json
import redis
from datetime import datetime, timedelta
import time

class RealTimeDashboard:
    """Real-time analytics dashboard using Streamlit"""
    
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        
        # Configure Streamlit page
        st.set_page_config(
            page_title="Real-Time E-commerce Analytics",
            page_icon="📊",
            layout="wide",
            initial_sidebar_state="expanded"
        )
    
    def get_realtime_metrics(self):
        """Fetch real-time metrics from Redis"""
        
        try:
            # Get customer metrics
            customer_metrics_raw = self.redis_client.hget('realtime_metrics', 'customer_metrics')
            customer_metrics = json.loads(customer_metrics_raw) if customer_metrics_raw else {}
            
            # Get transaction metrics (last hour)
            transaction_data = []
            now = datetime.now()
            
            for i in range(60):  # Last 60 minutes
                minute = (now - timedelta(minutes=i)).strftime('%Y-%m-%d %H:%M')
                count = self.redis_client.hget('transaction_metrics', f'{minute}:count')
                amount = self.redis_client.hget('transaction_metrics', f'{minute}:amount')
                
                transaction_data.append({
                    'minute': minute,
                    'count': int(count) if count else 0,
                    'amount': float(amount) if amount else 0.0
                })
            
            # Get fraud metrics
            fraud_data = []
            for i in range(60):
                minute = (now - timedelta(minutes=i)).strftime('%Y-%m-%d %H:%M')
                flagged = self.redis_client.hget('fraud_metrics', f'{minute}:flagged')
                fraud_data.append({
                    'minute': minute,
                    'flagged': int(flagged) if flagged else 0
                })
            
            return customer_metrics, transaction_data, fraud_data
            
        except Exception as e:
            st.error(f"Error fetching metrics: {e}")
            return {}, [], []
    
    def render_kpi_cards(self, customer_metrics):
        """Render KPI cards at the top of dashboard"""
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric(
                label="Active Customers (5min)",
                value=customer_metrics.get('unique_customers', 0),
                delta=None
            )
        
        with col2:
            st.metric(
                label="Revenue (5min)",
                value=f"${customer_metrics.get('total_revenue', 0):,.2f}",
                delta=None
            )
        
        with col3:
            st.metric(
                label="Conversion Rate",
                value=f"{customer_metrics.get('conversion_rate', 0):.2f}%",
                delta=None
            )
        
        with col4:
            st.metric(
                label="Events/Min",
                value=f"{customer_metrics.get('events_per_minute', 0):.1f}",
                delta=None
            )
    
    def render_transaction_charts(self, transaction_data):
        """Render real-time transaction charts"""
        
        if not transaction_data:
            st.warning("No transaction data available")
            return
        
        df = pd.DataFrame(transaction_data)
        df['minute'] = pd.to_datetime(df['minute'])
        df = df.sort_values('minute')
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Transaction count over time
            fig_count = go.Figure()
            fig_count.add_trace(go.Scatter(
                x=df['minute'],
                y=df['count'],
                mode='lines+markers',
                name='Transactions',
                line=dict(color='#1f77b4', width=2),
                marker=dict(size=4)
            ))
            
            fig_count.update_layout(
                title="Transactions per Minute",
                xaxis_title="Time",
                yaxis_title="Count",
                height=400,
                showlegend=False
            )
            
            st.plotly_chart(fig_count, use_container_width=True)
        
        with col2:
            # Revenue over time
            fig_revenue = go.Figure()
            fig_revenue.add_trace(go.Scatter(
                x=df['minute'],
                y=df['amount'],
                mode='lines+markers',
                name='Revenue',
                line=dict(color='#2ca02c', width=2),
                marker=dict(size=4),
                fill='tonexty'
            ))
            
            fig_revenue.update_layout(
                title="Revenue per Minute",
                xaxis_title="Time",
                yaxis_title="Amount ($)",
                height=400,
                showlegend=False
            )
            
            st.plotly_chart(fig_revenue, use_container_width=True)
    
    def render_fraud_monitoring(self, fraud_data):
        """Render fraud detection monitoring"""
        
        st.subheader("🚨 Fraud Detection Monitoring")
        
        if not fraud_data:
            st.info("No fraud data available")
            return
        
        df = pd.DataFrame(fraud_data)
        df['minute'] = pd.to_datetime(df['minute'])
        df = df.sort_values('minute')
        
        # Calculate fraud rate
        total_flagged = df['flagged'].sum()
        
        col1, col2 = st.columns([2, 1])
        
        with col1:
            # Fraud alerts over time
            fig_fraud = go.Figure()
            fig_fraud.add_trace(go.Bar(
                x=df['minute'],
                y=df['flagged'],
                name='Flagged Transactions',
                marker_color='red',
                opacity=0.7
            ))
            
            fig_fraud.update_layout(
                title="Fraud Alerts per Minute",
                xaxis_title="Time",
                yaxis_title="Flagged Count",
                height=400,
                showlegend=False
            )
            
            st.plotly_chart(fig_fraud, use_container_width=True)
        
        with col2:
            st.metric(
                label="Total Flagged (1hr)",
                value=total_flagged,
                delta=None
            )
            
            # Recent fraud alerts
            st.write("**Recent Alerts:**")
            recent_alerts = df[df['flagged'] > 0].tail(5)
            for _, alert in recent_alerts.iterrows():
                st.write(f"🚨 {alert['minute'].strftime('%H:%M')} - {alert['flagged']} flagged")
    
    def render_inventory_status(self):
        """Render inventory status monitoring"""
        
        st.subheader("📦 Inventory Status")
        
        # Get low stock products from Redis
        try:
            inventory_keys = self.redis_client.hkeys('current_inventory')
            low_stock_products = []
            
            for key in inventory_keys[:10]:  # Show top 10
                stock_level = int(self.redis_client.hget('current_inventory', key))
                if stock_level < 20:  # Assume 20 is low stock threshold
                    low_stock_products.append({
                        'product_id': key.decode('utf-8'),
                        'stock_level': stock_level
                    })
            
            if low_stock_products:
                df_inventory = pd.DataFrame(low_stock_products)
                
                fig_inventory = px.bar(
                    df_inventory,
                    x='product_id',
                    y='stock_level',
                    title="Low Stock Products",
                    color='stock_level',
                    color_continuous_scale='reds'
                )
                
                st.plotly_chart(fig_inventory, use_container_width=True)
            else:
                st.info("All products have adequate stock levels")
                
        except Exception as e:
            st.error(f"Error fetching inventory data: {e}")
    
    def run(self):
        """Main dashboard rendering loop"""
        
        st.title("🚀 Real-Time E-commerce Analytics")
        st.markdown("Live monitoring of customer behavior, transactions, and business metrics")
        
        # Sidebar controls
        st.sidebar.header("Dashboard Controls")
        auto_refresh = st.sidebar.checkbox("Auto Refresh", value=True)
        refresh_rate = st.sidebar.slider("Refresh Rate (seconds)", 5, 60, 10)
        
        # Main dashboard loop
        placeholder = st.empty()
        
        while True:
            with placeholder.container():
                # Fetch real-time data
                customer_metrics, transaction_data, fraud_data = self.get_realtime_metrics()
                
                # Render dashboard sections
                self.render_kpi_cards(customer_metrics)
                
                st.divider()
                
                st.subheader("💰 Transaction Analytics")
                self.render_transaction_charts(transaction_data)
                
                st.divider()
                
                self.render_fraud_monitoring(fraud_data)
                
                st.divider()
                
                self.render_inventory_status()
                
                # Last updated timestamp
                st.caption(f"Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            
            if not auto_refresh:
                break
                
            time.sleep(refresh_rate)

# Run the dashboard
if __name__ == "__main__":
    dashboard = RealTimeDashboard()
    dashboard.run()
```

### Task 3: Production Deployment and Monitoring

#### 3.1 Docker Compose Setup

```yaml
# docker-compose.yml for complete real-time analytics stack
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    volumes:
      - kafka_data:/var/lib/kafka/data

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: ecommerce
      POSTGRES_USER: analytics_user
      POSTGRES_PASSWORD: analytics_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  stream_processor:
    build:
      context: .
      dockerfile: Dockerfile.processor
    depends_on:
      - kafka
      - redis
      - postgres
    environment:
      KAFKA_SERVERS: kafka:9092
      REDIS_HOST: redis
      DATABASE_URL: postgresql://analytics_user:analytics_pass@postgres:5432/ecommerce
    volumes:
      - ./logs:/app/logs

  dashboard:
    build:
      context: .
      dockerfile: Dockerfile.dashboard
    depends_on:
      - redis
    ports:
      - "8501:8501"
    environment:
      REDIS_HOST: redis

  data_simulator:
    build:
      context: .
      dockerfile: Dockerfile.simulator
    depends_on:
      - kafka
    environment:
      KAFKA_SERVERS: kafka:9092

volumes:
  kafka_data:
  redis_data:
  postgres_data:
```

#### 3.2 Production Monitoring and Alerting

```python
import asyncio
import aiohttp
import json
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class ProductionMonitor:
    """Monitor real-time analytics system health and performance"""
    
    def __init__(self, config):
        self.config = config
        self.alert_thresholds = {
            'max_processing_delay': 30,  # seconds
            'min_events_per_minute': 10,
            'max_fraud_rate': 0.05,  # 5%
            'min_system_uptime': 0.99  # 99%
        }
        
    async def check_system_health(self):
        """Comprehensive system health check"""
        
        health_status = {
            'timestamp': datetime.now().isoformat(),
            'kafka_health': await self._check_kafka_health(),
            'redis_health': await self._check_redis_health(),
            'processor_health': await self._check_processor_health(),
            'dashboard_health': await self._check_dashboard_health()
        }
        
        # Calculate overall health score
        health_checks = [v for k, v in health_status.items() if k.endswith('_health')]
        overall_health = sum(health_checks) / len(health_checks)
        health_status['overall_health'] = overall_health
        
        # Check if alerts need to be sent
        if overall_health < self.alert_thresholds['min_system_uptime']:
            await self._send_system_alert(health_status)
        
        return health_status
    
    async def _check_kafka_health(self):
        """Check Kafka cluster health"""
        try:
            # Use Kafka admin client to check cluster health
            from kafka.admin import KafkaAdminClient, ConfigResource, ConfigResourceType
            
            admin_client = KafkaAdminClient(
                bootstrap_servers=self.config['kafka_servers'],
                client_id='health_monitor'
            )
            
            # Check if we can connect and list topics
            topics = admin_client.list_consumer_groups()
            return 1.0 if topics else 0.5
            
        except Exception as e:
            print(f"Kafka health check failed: {e}")
            return 0.0
    
    async def _check_redis_health(self):
        """Check Redis health and performance"""
        try:
            import redis
            
            redis_client = redis.Redis(
                host=self.config['redis_host'],
                port=self.config['redis_port'],
                db=0
            )
            
            # Test basic operations
            redis_client.ping()
            
            # Check memory usage
            info = redis_client.info('memory')
            memory_usage = info['used_memory'] / info['maxmemory'] if info['maxmemory'] > 0 else 0
            
            # Return health score based on memory usage
            if memory_usage < 0.8:
                return 1.0
            elif memory_usage < 0.9:
                return 0.7
            else:
                return 0.3
                
        except Exception as e:
            print(f"Redis health check failed: {e}")
            return 0.0
    
    async def _check_processor_health(self):
        """Check stream processor health"""
        try:
            # Check if processor is processing events (last minute)
            redis_client = redis.Redis(
                host=self.config['redis_host'],
                port=self.config['redis_port']
            )
            
            current_minute = datetime.now().strftime('%Y-%m-%d %H:%M')
            last_minute = (datetime.now() - timedelta(minutes=1)).strftime('%Y-%m-%d %H:%M')
            
            current_events = redis_client.hget('transaction_metrics', f'{current_minute}:count')
            last_events = redis_client.hget('transaction_metrics', f'{last_minute}:count')
            
            current_count = int(current_events) if current_events else 0
            last_count = int(last_events) if last_events else 0
            
            # Check if we're processing events
            if current_count > 0 or last_count > 0:
                return 1.0
            else:
                return 0.0
                
        except Exception as e:
            print(f"Processor health check failed: {e}")
            return 0.0
    
    async def _check_dashboard_health(self):
        """Check dashboard accessibility"""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"http://{self.config['dashboard_host']}:{self.config['dashboard_port']}/health",
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as response:
                    if response.status == 200:
                        return 1.0
                    else:
                        return 0.5
                        
        except Exception as e:
            print(f"Dashboard health check failed: {e}")
            return 0.0
    
    async def monitor_business_metrics(self):
        """Monitor key business metrics for anomalies"""
        
        try:
            redis_client = redis.Redis(
                host=self.config['redis_host'],
                port=self.config['redis_port']
            )
            
            # Get current metrics
            customer_metrics_raw = redis_client.hget('realtime_metrics', 'customer_metrics')
            customer_metrics = json.loads(customer_metrics_raw) if customer_metrics_raw else {}
            
            alerts = []
            
            # Check conversion rate
            conversion_rate = customer_metrics.get('conversion_rate', 0)
            if conversion_rate < 1.0:  # Below 1% conversion
                alerts.append({
                    'type': 'business_metric',
                    'metric': 'conversion_rate',
                    'value': conversion_rate,
                    'threshold': 1.0,
                    'severity': 'MEDIUM'
                })
            
            # Check events per minute
            events_per_minute = customer_metrics.get('events_per_minute', 0)
            if events_per_minute < self.alert_thresholds['min_events_per_minute']:
                alerts.append({
                    'type': 'business_metric',
                    'metric': 'events_per_minute',
                    'value': events_per_minute,
                    'threshold': self.alert_thresholds['min_events_per_minute'],
                    'severity': 'HIGH'
                })
            
            # Send alerts if any
            for alert in alerts:
                await self._send_business_alert(alert)
            
            return alerts
            
        except Exception as e:
            print(f"Business metrics monitoring failed: {e}")
            return []
    
    async def _send_system_alert(self, health_status):
        """Send system health alert"""
        
        subject = f"🚨 System Health Alert - {health_status['overall_health']:.1%} Health"
        
        body = f"""
Real-Time Analytics System Health Alert

Overall Health: {health_status['overall_health']:.1%}
Timestamp: {health_status['timestamp']}

Component Status:
- Kafka: {'✅' if health_status['kafka_health'] > 0.8 else '❌'} {health_status['kafka_health']:.1%}
- Redis: {'✅' if health_status['redis_health'] > 0.8 else '❌'} {health_status['redis_health']:.1%}
- Processor: {'✅' if health_status['processor_health'] > 0.8 else '❌'} {health_status['processor_health']:.1%}
- Dashboard: {'✅' if health_status['dashboard_health'] > 0.8 else '❌'} {health_status['dashboard_health']:.1%}

Please investigate immediately.
"""
        
        await self._send_email(subject, body)
    
    async def _send_business_alert(self, alert):
        """Send business metric alert"""
        
        subject = f"📊 Business Metric Alert - {alert['metric']}"
        
        body = f"""
Business Metric Alert

Metric: {alert['metric']}
Current Value: {alert['value']}
Threshold: {alert['threshold']}
Severity: {alert['severity']}
Timestamp: {datetime.now().isoformat()}

Please review business operations.
"""
        
        await self._send_email(subject, body)
    
    async def _send_email(self, subject, body):
        """Send email notification"""
        
        try:
            msg = MIMEMultipart()
            msg['From'] = self.config['email_from']
            msg['To'] = ', '.join(self.config['email_recipients'])
            msg['Subject'] = subject
            
            msg.attach(MIMEText(body, 'plain'))
            
            server = smtplib.SMTP(self.config['smtp_server'], 587)
            server.starttls()
            server.login(self.config['email_user'], self.config['email_password'])
            server.sendmail(msg['From'], self.config['email_recipients'], msg.as_string())
            server.quit()
            
            print(f"Alert email sent: {subject}")
            
        except Exception as e:
            print(f"Failed to send email alert: {e}")
    
    async def start_monitoring(self):
        """Start continuous monitoring"""
        
        print("Starting production monitoring...")
        
        while True:
            try:
                # System health check every 5 minutes
                health_status = await self.check_system_health()
                print(f"System health: {health_status['overall_health']:.1%}")
                
                # Business metrics check every minute
                business_alerts = await self.monitor_business_metrics()
                if business_alerts:
                    print(f"Business alerts: {len(business_alerts)}")
                
                await asyncio.sleep(60)  # Check every minute
                
            except Exception as e:
                print(f"Monitoring error: {e}")
                await asyncio.sleep(60)

# Production monitoring configuration
monitor_config = {
    'kafka_servers': ['localhost:9092'],
    'redis_host': 'localhost',
    'redis_port': 6379,
    'dashboard_host': 'localhost',
    'dashboard_port': 8501,
    'email_from': 'monitoring@company.com',
    'email_recipients': ['ops-team@company.com'],
    'smtp_server': 'smtp.gmail.com',
    'email_user': 'monitoring@company.com',
    'email_password': 'app_password'
}

# Start monitoring
if __name__ == "__main__":
    monitor = ProductionMonitor(monitor_config)
    asyncio.run(monitor.start_monitoring())
```

## Business Impact Assessment

### Key Performance Indicators

- **Processing Latency**: <100ms from event to dashboard update
- **System Uptime**: 99.9% availability for real-time analytics
- **Fraud Detection**: <5 seconds from transaction to fraud alert
- **Dashboard Response**: <2 seconds for metric updates
- **Alert Delivery**: <30 seconds for critical business alerts

### ROI Analysis

- **Fraud Prevention**: $3.2M annually saved through real-time detection
- **Inventory Optimization**: $1.8M annually from reduced stockouts
- **Customer Experience**: $2.1M revenue protection from instant issue detection
- **Implementation Cost**: $680K (infrastructure + development)
- **ROI**: 942% over 2 years

## Extension Challenges

### Challenge 1: Multi-Region Deployment

Scale the system across multiple geographic regions with data locality requirements.

### Challenge 2: ML Model Integration

Integrate real-time machine learning models for dynamic pricing and personalization.

### Challenge 3: Advanced Analytics

Add complex event processing for customer journey analysis and attribution modeling.

### Challenge 4: Edge Computing

Implement edge analytics for reduced latency in global deployments.

---

*This exercise demonstrates enterprise-grade real-time analytics that enables instant business decision-making and competitive advantage in fast-moving digital markets.*
