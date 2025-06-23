# 📊 Interactive Dashboards Exercise

## Business Context

**Scenario**: You're a Business Intelligence Analyst at RetailWave Analytics, a leading retail consultancy. Your clients need interactive, self-service dashboards to explore their sales data, identify trends, and make data-driven decisions without constantly requesting custom reports.

**Stakeholder**: Jennifer Park, Director of Client Solutions
**Business Challenge**: Clients are frustrated with static reports and want interactive exploration capabilities that they can use independently.

## 🎯 Learning Objectives

By completing this exercise, you will:

- Build interactive dashboards using Dash/Plotly with SQL data sources
- Create dynamic filtering and drill-down capabilities
- Implement real-time data refresh and caching strategies
- Design responsive dashboards for multiple screen sizes
- Build user authentication and role-based access control
- Deploy dashboards for business stakeholder consumption

## 📊 Dataset Overview

You'll work with RetailWave's comprehensive retail analytics database:

### Key Tables

- `sales_transactions`: Point-of-sale transaction data
- `products`: Product catalog with categories and pricing
- `stores`: Store locations and characteristics
- `customers`: Customer demographics and segments
- `inventory`: Real-time inventory levels
- `marketing_campaigns`: Campaign performance data

## 🛠️ Technical Requirements

### Required Libraries

```python
import dash
from dash import dcc, html, Input, Output, callback, dash_table
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import pandas as pd
import sqlalchemy as sa
from datetime import datetime, timedelta
import numpy as np
from dash.exceptions import PreventUpdate
import dash_auth
import redis
import pickle
import json
```

### Database Connection

```python
# RetailWave analytics database
engine = sa.create_engine("postgresql://localhost:5432/retailwave_db")
```

## 📋 Tasks

### Task 1: Basic Interactive Sales Dashboard (🟡 Intermediate)

**Objective**: Create a foundational interactive dashboard with filtering and basic interactivity.

**Requirements**:

1. Sales performance overview with key metrics
2. Interactive date range selection
3. Store and product category filters
4. Dynamic chart updates based on user selections

**Dashboard Foundation**:

```python
import dash
from dash import dcc, html, Input, Output, callback
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
import sqlalchemy as sa
from datetime import datetime, timedelta

# Initialize Dash app
app = dash.Dash(__name__)
app.title = "RetailWave Analytics Dashboard"

# Database connection
engine = sa.create_engine("postgresql://localhost:5432/retailwave_db")

def get_sales_data(start_date, end_date, store_ids=None, categories=None):
    """Fetch sales data with optional filters."""
    
    # Build dynamic WHERE clause
    filters = [f"st.transaction_date BETWEEN '{start_date}' AND '{end_date}'"]
    
    if store_ids:
        store_list = ', '.join([str(id) for id in store_ids])
        filters.append(f"st.store_id IN ({store_list})")
    
    if categories:
        category_list = ', '.join([f"'{cat}'" for cat in categories])
        filters.append(f"p.category IN ({category_list})")
    
    where_clause = " AND ".join(filters)
    
    query = f"""
    SELECT 
        st.transaction_date,
        st.store_id,
        s.store_name,
        s.region,
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        st.quantity,
        st.unit_price,
        st.total_amount,
        st.discount_amount,
        c.customer_segment,
        EXTRACT(hour FROM st.transaction_time) as hour_of_day,
        EXTRACT(dow FROM st.transaction_date) as day_of_week
    FROM sales_transactions st
    JOIN stores s ON st.store_id = s.store_id
    JOIN products p ON st.product_id = p.product_id
    LEFT JOIN customers c ON st.customer_id = c.customer_id
    WHERE {where_clause}
    ORDER BY st.transaction_date, st.transaction_time;
    """
    
    return pd.read_sql(query, engine)

def get_filter_options():
    """Get available filter options for dropdowns."""
    
    # Get store options
    stores_query = "SELECT store_id, store_name, region FROM stores ORDER BY store_name"
    stores_df = pd.read_sql(stores_query, engine)
    store_options = [{'label': f"{row['store_name']} ({row['region']})", 
                     'value': row['store_id']} for _, row in stores_df.iterrows()]
    
    # Get category options
    categories_query = "SELECT DISTINCT category FROM products ORDER BY category"
    categories_df = pd.read_sql(categories_query, engine)
    category_options = [{'label': cat, 'value': cat} for cat in categories_df['category']]
    
    return store_options, category_options

# Get filter options
store_options, category_options = get_filter_options()

# Define app layout
app.layout = html.Div([
    # Header
    html.Div([
        html.H1("RetailWave Analytics Dashboard", className="header-title"),
        html.P("Interactive Sales Performance Analytics", className="header-subtitle")
    ], className="header"),
    
    # Filters section
    html.Div([
        html.Div([
            html.Label("Date Range:"),
            dcc.DatePickerRange(
                id='date-picker-range',
                start_date=datetime.now() - timedelta(days=30),
                end_date=datetime.now(),
                display_format='YYYY-MM-DD'
            )
        ], className="filter-item"),
        
        html.Div([
            html.Label("Stores:"),
            dcc.Dropdown(
                id='store-dropdown',
                options=store_options,
                value=[],
                multi=True,
                placeholder="Select stores (all if none selected)"
            )
        ], className="filter-item"),
        
        html.Div([
            html.Label("Product Categories:"),
            dcc.Dropdown(
                id='category-dropdown',
                options=category_options,
                value=[],
                multi=True,
                placeholder="Select categories (all if none selected)"
            )
        ], className="filter-item"),
        
        html.Button("Refresh Data", id="refresh-button", n_clicks=0)
    ], className="filters-section"),
    
    # KPI Cards
    html.Div(id="kpi-cards", className="kpi-section"),
    
    # Charts section
    html.Div([
        html.Div([
            dcc.Graph(id="sales-trend-chart")
        ], className="chart-container"),
        
        html.Div([
            dcc.Graph(id="category-performance-chart")
        ], className="chart-container"),
        
        html.Div([
            dcc.Graph(id="store-comparison-chart")
        ], className="chart-container"),
        
        html.Div([
            dcc.Graph(id="hourly-sales-pattern")
        ], className="chart-container")
    ], className="charts-grid"),
    
    # Data table
    html.Div([
        html.H3("Detailed Sales Data"),
        html.Div(id="sales-data-table")
    ], className="data-table-section")
])

# Callback for updating all dashboard components
@callback(
    [Output('kpi-cards', 'children'),
     Output('sales-trend-chart', 'figure'),
     Output('category-performance-chart', 'figure'),
     Output('store-comparison-chart', 'figure'),
     Output('hourly-sales-pattern', 'figure'),
     Output('sales-data-table', 'children')],
    [Input('refresh-button', 'n_clicks')],
    [dash.dependencies.State('date-picker-range', 'start_date'),
     dash.dependencies.State('date-picker-range', 'end_date'),
     dash.dependencies.State('store-dropdown', 'value'),
     dash.dependencies.State('category-dropdown', 'value')]
)
def update_dashboard(n_clicks, start_date, end_date, selected_stores, selected_categories):
    """Update all dashboard components based on filter selections."""
    
    # Get filtered data
    data = get_sales_data(
        start_date=start_date,
        end_date=end_date,
        store_ids=selected_stores if selected_stores else None,
        categories=selected_categories if selected_categories else None
    )
    
    if data.empty:
        return "No data available", {}, {}, {}, {}, "No data to display"
    
    # Calculate KPIs
    total_revenue = data['total_amount'].sum()
    total_transactions = len(data)
    avg_transaction_value = data['total_amount'].mean()
    total_discount = data['discount_amount'].sum()
    
    # KPI Cards
    kpi_cards = html.Div([
        html.Div([
            html.H3(f"${total_revenue:,.0f}"),
            html.P("Total Revenue")
        ], className="kpi-card"),
        
        html.Div([
            html.H3(f"{total_transactions:,}"),
            html.P("Transactions")
        ], className="kpi-card"),
        
        html.Div([
            html.H3(f"${avg_transaction_value:.2f}"),
            html.P("Avg Transaction")
        ], className="kpi-card"),
        
        html.Div([
            html.H3(f"${total_discount:,.0f}"),
            html.P("Total Discounts")
        ], className="kpi-card")
    ], className="kpi-cards-container")
    
    # Sales Trend Chart
    daily_sales = data.groupby('transaction_date').agg({
        'total_amount': 'sum',
        'transaction_date': 'count'
    }).rename(columns={'transaction_date': 'transaction_count'}).reset_index()
    
    sales_trend_fig = go.Figure()
    sales_trend_fig.add_trace(go.Scatter(
        x=daily_sales['transaction_date'],
        y=daily_sales['total_amount'],
        mode='lines+markers',
        name='Daily Revenue',
        line=dict(color='#1f77b4', width=3)
    ))
    sales_trend_fig.update_layout(
        title="Daily Sales Trend",
        xaxis_title="Date",
        yaxis_title="Revenue ($)",
        hovermode='x unified'
    )
    
    # Category Performance Chart
    category_sales = data.groupby('category').agg({
        'total_amount': 'sum',
        'quantity': 'sum'
    }).reset_index().sort_values('total_amount', ascending=True)
    
    category_fig = px.bar(
        category_sales,
        x='total_amount',
        y='category',
        orientation='h',
        title="Sales by Product Category",
        labels={'total_amount': 'Revenue ($)', 'category': 'Product Category'}
    )
    category_fig.update_layout(height=400)
    
    # Store Comparison Chart
    store_sales = data.groupby(['store_name', 'region']).agg({
        'total_amount': 'sum'
    }).reset_index().sort_values('total_amount', ascending=False).head(10)
    
    store_fig = px.bar(
        store_sales,
        x='store_name',
        y='total_amount',
        color='region',
        title="Top 10 Stores by Revenue",
        labels={'total_amount': 'Revenue ($)', 'store_name': 'Store'}
    )
    store_fig.update_xaxis(tickangle=45)
    
    # Hourly Sales Pattern
    hourly_sales = data.groupby('hour_of_day')['total_amount'].sum().reset_index()
    
    hourly_fig = px.line(
        hourly_sales,
        x='hour_of_day',
        y='total_amount',
        title="Sales Pattern by Hour of Day",
        labels={'hour_of_day': 'Hour of Day', 'total_amount': 'Revenue ($)'},
        markers=True
    )
    hourly_fig.update_xaxis(tickmode='linear', tick0=0, dtick=2)
    
    # Data Table
    summary_data = data.groupby(['transaction_date', 'store_name', 'category']).agg({
        'total_amount': 'sum',
        'quantity': 'sum',
        'transaction_date': 'count'
    }).rename(columns={'transaction_date': 'transaction_count'}).reset_index()
    
    data_table = dash_table.DataTable(
        data=summary_data.head(100).to_dict('records'),
        columns=[
            {'name': 'Date', 'id': 'transaction_date', 'type': 'datetime'},
            {'name': 'Store', 'id': 'store_name'},
            {'name': 'Category', 'id': 'category'},
            {'name': 'Revenue', 'id': 'total_amount', 'type': 'numeric', 'format': {'specifier': '$,.0f'}},
            {'name': 'Quantity', 'id': 'quantity', 'type': 'numeric'},
            {'name': 'Transactions', 'id': 'transaction_count', 'type': 'numeric'}
        ],
        sort_action="native",
        filter_action="native",
        page_action="native",
        page_current=0,
        page_size=20,
        style_cell={'textAlign': 'left'},
        style_data_conditional=[
            {
                'if': {'row_index': 'odd'},
                'backgroundColor': 'rgb(248, 248, 248)'
            }
        ]
    )
    
    return kpi_cards, sales_trend_fig, category_fig, store_fig, hourly_fig, data_table

# CSS styling
app.index_string = '''
<!DOCTYPE html>
<html>
    <head>
        {%metas%}
        <title>{%title%}</title>
        {%favicon%}
        {%css%}
        <style>
            body { 
                font-family: Arial, sans-serif; 
                margin: 0; 
                background-color: #f5f5f5; 
            }
            .header { 
                background: linear-gradient(90deg, #1f77b4, #2ca02c); 
                color: white; 
                padding: 20px; 
                text-align: center; 
            }
            .header-title { margin: 0; font-size: 2.5em; }
            .header-subtitle { margin: 10px 0 0 0; font-size: 1.2em; opacity: 0.9; }
            .filters-section { 
                background: white; 
                padding: 20px; 
                margin: 20px; 
                border-radius: 8px; 
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                display: flex;
                gap: 20px;
                align-items: end;
                flex-wrap: wrap;
            }
            .filter-item { min-width: 200px; }
            .filter-item label { font-weight: bold; margin-bottom: 5px; display: block; }
            .kpi-section { margin: 20px; }
            .kpi-cards-container { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
                gap: 20px; 
            }
            .kpi-card { 
                background: white; 
                padding: 20px; 
                border-radius: 8px; 
                box-shadow: 0 2px 4px rgba(0,0,0,0.1); 
                text-align: center; 
            }
            .kpi-card h3 { margin: 0; color: #1f77b4; font-size: 2em; }
            .kpi-card p { margin: 10px 0 0 0; color: #666; }
            .charts-grid { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); 
                gap: 20px; 
                margin: 20px; 
            }
            .chart-container { 
                background: white; 
                border-radius: 8px; 
                box-shadow: 0 2px 4px rgba(0,0,0,0.1); 
                padding: 20px; 
            }
            .data-table-section { 
                background: white; 
                margin: 20px; 
                padding: 20px; 
                border-radius: 8px; 
                box-shadow: 0 2px 4px rgba(0,0,0,0.1); 
            }
            #refresh-button {
                background: #1f77b4;
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 4px;
                cursor: pointer;
                font-size: 1em;
            }
            #refresh-button:hover { background: #0d5aa7; }
        </style>
    </head>
    <body>
        {%app_entry%}
        <footer>
            {%config%}
            {%scripts%}
            {%renderer%}
        </footer>
    </body>
</html>
'''

if __name__ == '__main__':
    app.run_server(debug=True)
```

### Task 2: Advanced Interactive Features (🔴 Advanced)

**Objective**: Add advanced interactivity including drill-down, cross-filtering, and real-time updates.

**Requirements**:

1. Implement click-through drill-down functionality
2. Add cross-chart filtering capabilities
3. Create real-time data refresh with caching
4. Build customer cohort analysis with interactive parameters

**Advanced Dashboard Features**:

```python
import redis
import pickle
from datetime import datetime, timedelta
import threading
import time

class AdvancedRetailDashboard:
    """Advanced interactive dashboard with real-time features."""
    
    def __init__(self, engine):
        self.engine = engine
        self.cache = redis.Redis(host='localhost', port=6379, db=0)
        self.app = dash.Dash(__name__)
        self.setup_layout()
        self.setup_callbacks()
        
        # Start background data refresh thread
        self.start_background_refresh()
    
    def cache_data(self, key: str, data: pd.DataFrame, ttl: int = 300):
        """Cache data with time-to-live."""
        try:
            serialized_data = pickle.dumps(data)
            self.cache.setex(key, ttl, serialized_data)
        except Exception as e:
            print(f"Cache error: {e}")
    
    def get_cached_data(self, key: str) -> pd.DataFrame:
        """Retrieve cached data."""
        try:
            cached_data = self.cache.get(key)
            if cached_data:
                return pickle.loads(cached_data)
        except Exception as e:
            print(f"Cache retrieval error: {e}")
        return None
    
    def get_customer_cohort_data(self, cohort_type='monthly'):
        """Get customer cohort analysis data."""
        
        cache_key = f"cohort_data_{cohort_type}"
        cached_data = self.get_cached_data(cache_key)
        if cached_data is not None:
            return cached_data
        
        if cohort_type == 'monthly':
            period_format = 'YYYY-MM'
            period_sql = "DATE_TRUNC('month', first_purchase_date)"
        else:
            period_format = 'YYYY-"W"WW'
            period_sql = "DATE_TRUNC('week', first_purchase_date)"
        
        query = f"""
        WITH customer_cohorts AS (
            SELECT 
                c.customer_id,
                MIN(st.transaction_date) as first_purchase_date,
                {period_sql} as cohort_period
            FROM customers c
            JOIN sales_transactions st ON c.customer_id = st.customer_id
            GROUP BY c.customer_id
        ),
        cohort_sizes AS (
            SELECT 
                cohort_period,
                COUNT(DISTINCT customer_id) as cohort_size
            FROM customer_cohorts
            GROUP BY cohort_period
        ),
        retention_data AS (
            SELECT 
                cc.cohort_period,
                DATE_TRUNC('{cohort_type[:-2]}', st.transaction_date) as period,
                EXTRACT(epoch FROM (DATE_TRUNC('{cohort_type[:-2]}', st.transaction_date) - cc.cohort_period)) / 
                (60 * 60 * 24 * {'30' if cohort_type == 'monthly' else '7'}) as period_number,
                COUNT(DISTINCT st.customer_id) as customers
            FROM customer_cohorts cc
            JOIN sales_transactions st ON cc.customer_id = st.customer_id
            WHERE st.transaction_date >= cc.cohort_period
            GROUP BY cc.cohort_period, period, period_number
        )
        SELECT 
            rd.cohort_period,
            rd.period_number,
            rd.customers,
            cs.cohort_size,
            (rd.customers * 100.0 / cs.cohort_size) as retention_rate
        FROM retention_data rd
        JOIN cohort_sizes cs ON rd.cohort_period = cs.cohort_period
        ORDER BY rd.cohort_period, rd.period_number;
        """
        
        cohort_data = pd.read_sql(query, self.engine)
        self.cache_data(cache_key, cohort_data, ttl=600)  # Cache for 10 minutes
        
        return cohort_data
    
    def create_cohort_heatmap(self, cohort_data):
        """Create interactive cohort retention heatmap."""
        
        # Pivot data for heatmap
        cohort_table = cohort_data.pivot(
            index='cohort_period', 
            columns='period_number', 
            values='retention_rate'
        )
        
        fig = go.Figure(data=go.Heatmap(
            z=cohort_table.values,
            x=[f"Period {int(col)}" for col in cohort_table.columns],
            y=[str(idx)[:10] for idx in cohort_table.index],
            colorscale='RdYlGn',
            text=np.around(cohort_table.values, 1),
            texttemplate="%{text}%",
            textfont={"size": 10},
            hoverongaps=False,
            hovertemplate='Cohort: %{y}<br>Period: %{x}<br>Retention: %{z:.1f}%<extra></extra>'
        ))
        
        fig.update_layout(
            title="Customer Retention Cohort Analysis",
            xaxis_title="Periods Since First Purchase",
            yaxis_title="Cohort (First Purchase Date)",
            height=500
        )
        
        return fig
    
    def create_drill_down_chart(self, data, level='category'):
        """Create drill-down capable chart."""
        
        if level == 'category':
            grouped_data = data.groupby('category').agg({
                'total_amount': 'sum',
                'quantity': 'sum'
            }).reset_index()
            
            fig = px.treemap(
                grouped_data,
                path=['category'],
                values='total_amount',
                title="Sales by Category (Click to drill down)",
                color='total_amount',
                color_continuous_scale='Viridis'
            )
            
        elif level == 'subcategory':
            grouped_data = data.groupby(['category', 'subcategory']).agg({
                'total_amount': 'sum',
                'quantity': 'sum'
            }).reset_index()
            
            fig = px.treemap(
                grouped_data,
                path=['category', 'subcategory'],
                values='total_amount',
                title="Sales by Category and Subcategory",
                color='total_amount',
                color_continuous_scale='Viridis'
            )
            
        else:  # product level
            grouped_data = data.groupby(['category', 'subcategory', 'product_name']).agg({
                'total_amount': 'sum',
                'quantity': 'sum'
            }).reset_index().head(50)  # Limit for performance
            
            fig = px.treemap(
                grouped_data,
                path=['category', 'subcategory', 'product_name'],
                values='total_amount',
                title="Sales by Product (Top 50)",
                color='total_amount',
                color_continuous_scale='Viridis'
            )
        
        return fig
    
    def create_real_time_metrics(self):
        """Create real-time metrics component."""
        
        query = """
        SELECT 
            COUNT(*) as transactions_today,
            SUM(total_amount) as revenue_today,
            AVG(total_amount) as avg_transaction_today,
            COUNT(DISTINCT customer_id) as unique_customers_today
        FROM sales_transactions
        WHERE transaction_date = current_date;
        """
        
        metrics = pd.read_sql(query, self.engine)
        
        if not metrics.empty:
            return html.Div([
                html.H3("Today's Performance", style={'textAlign': 'center'}),
                html.Div([
                    html.Div([
                        html.H2(f"{int(metrics.iloc[0]['transactions_today']):,}"),
                        html.P("Transactions Today")
                    ], className="realtime-metric"),
                    
                    html.Div([
                        html.H2(f"${int(metrics.iloc[0]['revenue_today']):,}"),
                        html.P("Revenue Today")
                    ], className="realtime-metric"),
                    
                    html.Div([
                        html.H2(f"${metrics.iloc[0]['avg_transaction_today']:.2f}"),
                        html.P("Avg Transaction")
                    ], className="realtime-metric"),
                    
                    html.Div([
                        html.H2(f"{int(metrics.iloc[0]['unique_customers_today']):,}"),
                        html.P("Unique Customers")
                    ], className="realtime-metric")
                ], style={'display': 'flex', 'justifyContent': 'space-around'})
            ])
        
        return html.Div("No data available for today")
    
    def setup_layout(self):
        """Setup advanced dashboard layout."""
        
        self.app.layout = html.Div([
            # Header with real-time clock
            html.Div([
                html.H1("RetailWave Advanced Analytics"),
                html.Div(id="live-clock", style={'fontSize': '1.2em'})
            ], className="header"),
            
            # Real-time metrics
            html.Div(id="realtime-metrics", className="realtime-section"),
            
            # Tabbed interface
            dcc.Tabs(id="main-tabs", value='sales-analysis', children=[
                dcc.Tab(label='Sales Analysis', value='sales-analysis'),
                dcc.Tab(label='Customer Cohorts', value='customer-cohorts'),
                dcc.Tab(label='Product Deep Dive', value='product-analysis'),
                dcc.Tab(label='Real-time Monitor', value='realtime-monitor')
            ]),
            
            # Tab content
            html.Div(id="tab-content"),
            
            # Hidden divs to store data
            html.Div(id="selected-data", style={'display': 'none'}),
            
            # Auto-refresh interval
            dcc.Interval(
                id='interval-component',
                interval=30*1000,  # Update every 30 seconds
                n_intervals=0
            )
        ])
    
    def setup_callbacks(self):
        """Setup all dashboard callbacks."""
        
        @self.app.callback(
            Output('live-clock', 'children'),
            Input('interval-component', 'n_intervals')
        )
        def update_clock(n):
            return f"Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        
        @self.app.callback(
            Output('realtime-metrics', 'children'),
            Input('interval-component', 'n_intervals')
        )
        def update_realtime_metrics(n):
            return self.create_real_time_metrics()
        
        @self.app.callback(
            Output('tab-content', 'children'),
            Input('main-tabs', 'value')
        )
        def render_tab_content(active_tab):
            if active_tab == 'sales-analysis':
                return self.create_sales_analysis_tab()
            elif active_tab == 'customer-cohorts':
                return self.create_cohort_analysis_tab()
            elif active_tab == 'product-analysis':
                return self.create_product_analysis_tab()
            elif active_tab == 'realtime-monitor':
                return self.create_realtime_monitor_tab()
        
        # Cross-filtering callback
        @self.app.callback(
            Output('selected-data', 'children'),
            Input('category-chart', 'clickData')
        )
        def store_selected_category(clickData):
            if clickData:
                selected_category = clickData['points'][0]['label']
                return json.dumps({'selected_category': selected_category})
            return json.dumps({})
    
    def create_cohort_analysis_tab(self):
        """Create customer cohort analysis tab."""
        
        return html.Div([
            html.H2("Customer Cohort Analysis"),
            
            html.Div([
                html.Label("Cohort Period:"),
                dcc.RadioItems(
                    id='cohort-period-radio',
                    options=[
                        {'label': 'Monthly', 'value': 'monthly'},
                        {'label': 'Weekly', 'value': 'weekly'}
                    ],
                    value='monthly',
                    inline=True
                )
            ], style={'margin': '20px 0'}),
            
            dcc.Graph(id="cohort-heatmap"),
            
            html.Div([
                html.H3("Cohort Insights"),
                html.Div(id="cohort-insights")
            ])
        ])
    
    def start_background_refresh(self):
        """Start background thread for data refresh."""
        
        def refresh_cache():
            while True:
                try:
                    # Refresh key cached data every 5 minutes
                    self.get_customer_cohort_data('monthly')
                    self.get_customer_cohort_data('weekly')
                    print(f"Cache refreshed at {datetime.now()}")
                    time.sleep(300)  # 5 minutes
                except Exception as e:
                    print(f"Background refresh error: {e}")
                    time.sleep(60)  # Retry in 1 minute
        
        refresh_thread = threading.Thread(target=refresh_cache, daemon=True)
        refresh_thread.start()
    
    def run(self, debug=True, port=8050):
        """Run the dashboard."""
        self.app.run_server(debug=debug, port=port)

# Usage
if __name__ == '__main__':
    engine = sa.create_engine("postgresql://localhost:5432/retailwave_db")
    dashboard = AdvancedRetailDashboard(engine)
    dashboard.run()
```

### Task 3: Production Deployment with Authentication (🔴 Advanced)

**Objective**: Deploy a production-ready dashboard with user authentication, role-based access, and monitoring.

**Requirements**:

1. Implement user authentication and authorization
2. Add role-based data access controls  
3. Deploy with Docker and load balancing
4. Add monitoring and logging

**Production Deployment Setup**:

```python
import dash_auth
from functools import wraps
import jwt
import hashlib
import os
from flask import session

class ProductionDashboard(AdvancedRetailDashboard):
    """Production-ready dashboard with authentication and monitoring."""
    
    def __init__(self, engine, config):
        self.config = config
        super().__init__(engine)
        self.setup_authentication()
        self.setup_monitoring()
    
    def setup_authentication(self):
        """Setup user authentication."""
        
        # User database (in production, use proper database)
        self.users = {
            'admin': {
                'password': hashlib.sha256('admin123'.encode()).hexdigest(),
                'role': 'admin',
                'regions': ['all'],
                'stores': ['all']
            },
            'manager_east': {
                'password': hashlib.sha256('manager123'.encode()).hexdigest(),
                'role': 'manager',
                'regions': ['east'],
                'stores': ['all']
            },
            'analyst': {
                'password': hashlib.sha256('analyst123'.encode()).hexdigest(),
                'role': 'analyst',
                'regions': ['east', 'west'],
                'stores': ['all']
            }
        }
        
        # Setup Dash auth
        auth = dash_auth.BasicAuth(
            self.app,
            self.get_valid_username_password_pairs()
        )
    
    def get_valid_username_password_pairs(self):
        """Get username/password pairs for authentication."""
        return {user: data['password'][:8] for user, data in self.users.items()}
    
    def get_user_permissions(self, username):
        """Get user permissions based on role."""
        user_data = self.users.get(username, {})
        return {
            'role': user_data.get('role', 'guest'),
            'regions': user_data.get('regions', []),
            'stores': user_data.get('stores', [])
        }
    
    def filter_data_by_permissions(self, data, username):
        """Filter data based on user permissions."""
        permissions = self.get_user_permissions(username)
        
        if permissions['regions'] != ['all']:
            data = data[data['region'].isin(permissions['regions'])]
        
        if permissions['stores'] != ['all']:
            data = data[data['store_id'].isin(permissions['stores'])]
        
        return data
    
    def setup_monitoring(self):
        """Setup application monitoring and logging."""
        
        import logging
        from logging.handlers import RotatingFileHandler
        
        # Setup detailed logging
        log_formatter = logging.Formatter(
            '%(asctime)s %(levelname)s [%(filename)s:%(lineno)d] %(message)s'
        )
        
        file_handler = RotatingFileHandler(
            'dashboard.log', maxBytes=10240000, backupCount=10
        )
        file_handler.setFormatter(log_formatter)
        file_handler.setLevel(logging.INFO)
        
        self.app.logger.addHandler(file_handler)
        self.app.logger.setLevel(logging.INFO)
        
        # Add performance monitoring
        @self.app.server.before_request
        def before_request():
            session['request_start_time'] = time.time()
        
        @self.app.server.after_request
        def after_request(response):
            if 'request_start_time' in session:
                duration = time.time() - session['request_start_time']
                self.app.logger.info(f"Request duration: {duration:.3f}s")
            return response

# Docker deployment configuration
# Dockerfile
docker_config = """
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8050

CMD ["gunicorn", "--bind", "0.0.0.0:8050", "--workers", "4", "app:server"]
"""

# docker-compose.yml
docker_compose = """
version: '3.8'

services:
  dashboard:
    build: .
    ports:
      - "8050:8050"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/retailwave_db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: retailwave_db
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    depends_on:
      - dashboard

volumes:
  postgres_data:
"""

# Nginx configuration for load balancing
nginx_config = """
events {
    worker_connections 1024;
}

http {
    upstream dashboard {
        server dashboard:8050;
    }

    server {
        listen 80;
        server_name your-domain.com;
        
        location / {
            proxy_pass http://dashboard;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
"""

# Deployment script
deployment_script = """
#!/bin/bash

# Build and deploy RetailWave Dashboard

echo "Building Docker images..."
docker-compose build

echo "Starting services..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 30

echo "Running database migrations..."
docker-compose exec dashboard python migrate.py

echo "Dashboard deployed successfully!"
echo "Access at: http://localhost:8050"
echo "Logs: docker-compose logs -f dashboard"
"""

if __name__ == '__main__':
    config = {
        'database_url': os.environ.get('DATABASE_URL', 'postgresql://localhost:5432/retailwave_db'),
        'redis_url': os.environ.get('REDIS_URL', 'redis://localhost:6379/0'),
        'secret_key': os.environ.get('SECRET_KEY', 'your-secret-key'),
        'debug': os.environ.get('DEBUG', 'False').lower() == 'true'
    }
    
    engine = sa.create_engine(config['database_url'])
    dashboard = ProductionDashboard(engine, config)
    
    # In production, use gunicorn instead of development server
    if config['debug']:
        dashboard.run(debug=True)
    else:
        # Production WSGI server
        server = dashboard.app.server
```

## 🎯 Business Impact

### Success Metrics

- **User Adoption**: 90%+ of stakeholders using self-service dashboards
- **Query Reduction**: 70% reduction in ad-hoc data requests
- **Decision Speed**: 50% faster decision-making with real-time insights
- **User Satisfaction**: 95%+ satisfaction with dashboard usability

### Expected Outcomes

1. **Self-Service Analytics**:
   - Stakeholders can explore data independently
   - Reduced dependency on analyst team for basic reporting
   - Faster access to insights and trends

2. **Improved Decision Making**:
   - Real-time visibility into business performance
   - Interactive exploration reveals hidden insights
   - Data-driven decision making across all levels

3. **Operational Efficiency**:
   - Automated reporting reduces manual effort
   - Consistent data presentation across organization
   - Scalable solution for growing business needs

## 🚀 Extensions & Next Steps

### Challenge Extensions

1. **Mobile Optimization**: Responsive design for tablet and mobile access
2. **Predictive Analytics**: Add forecasting and trend prediction
3. **Natural Language Queries**: Voice/text-based data exploration
4. **Collaboration Features**: Share insights, annotate charts, create alerts

### Advanced Features

1. **Machine Learning Integration**: Automated insight generation and anomaly detection
2. **Real-time Streaming**: Live data feeds with WebSocket connections
3. **Multi-tenancy**: Support for multiple organizations with data isolation
4. **API Integration**: Connect to external data sources and third-party tools

---

**💡 Pro Tip**: Focus on user experience and performance optimization. Start with core functionality and progressively add advanced features based on user feedback and business requirements.
