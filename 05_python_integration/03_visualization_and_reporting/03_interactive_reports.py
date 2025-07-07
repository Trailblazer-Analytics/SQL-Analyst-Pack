"""
Interactive Business Reports Generator
=====================================

This script creates interactive business reports using plotly for analysts.
Perfect for sharing insights with stakeholders.

Author: SQL Analyst Pack
Focus: Interactive Business Analytics
"""

import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import sqlite3
from datetime import datetime, timedelta

class InteractiveReports:
    """Generate interactive business reports with Plotly"""
    
    def __init__(self, db_connection):
        self.conn = db_connection
        self.report_date = datetime.now().strftime("%Y-%m-%d")
        
    def execute_query(self, query, params=None):
        """Execute SQL query and return DataFrame"""
        try:
            return pd.read_sql_query(query, self.conn, params=params)
        except Exception as e:
            print(f"Query error: {e}")
            return pd.DataFrame()
    
    def create_sales_dashboard(self):
        """Create interactive sales dashboard"""
        # Sample sales data query
        query = """
        SELECT 
            DATE(order_date) as date,
            SUM(order_total) as daily_sales,
            COUNT(*) as order_count,
            AVG(order_total) as avg_order_value
        FROM orders 
        WHERE order_date >= date('now', '-90 days')
        GROUP BY DATE(order_date)
        ORDER BY date
        """
        
        df = self.execute_query(query)
        if df.empty:
            return None
            
        df['date'] = pd.to_datetime(df['date'])
        
        # Create subplots
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Daily Sales Revenue', 'Order Count', 
                          'Average Order Value', 'Sales Trend with Moving Average'),
            specs=[[{"secondary_y": False}, {"secondary_y": False}],
                   [{"secondary_y": False}, {"secondary_y": True}]]
        )
        
        # Daily sales
        fig.add_trace(
            go.Scatter(x=df['date'], y=df['daily_sales'], 
                      mode='lines+markers', name='Daily Sales',
                      line=dict(color='blue', width=2)),
            row=1, col=1
        )
        
        # Order count
        fig.add_trace(
            go.Scatter(x=df['date'], y=df['order_count'],
                      mode='lines+markers', name='Order Count',
                      line=dict(color='orange', width=2)),
            row=1, col=2
        )
        
        # Average order value
        fig.add_trace(
            go.Scatter(x=df['date'], y=df['avg_order_value'],
                      mode='lines+markers', name='AOV',
                      line=dict(color='green', width=2)),
            row=2, col=1
        )
        
        # Sales with moving average
        df['sales_7day_ma'] = df['daily_sales'].rolling(window=7).mean()
        fig.add_trace(
            go.Scatter(x=df['date'], y=df['daily_sales'],
                      mode='lines', name='Daily Sales', opacity=0.3,
                      line=dict(color='lightblue')),
            row=2, col=2
        )
        fig.add_trace(
            go.Scatter(x=df['date'], y=df['sales_7day_ma'],
                      mode='lines', name='7-Day MA',
                      line=dict(color='red', width=3)),
            row=2, col=2
        )
        
        fig.update_layout(height=800, title_text="Sales Performance Dashboard",
                         showlegend=False)
        
        return fig
    
    def create_product_performance(self):
        """Create interactive product performance charts"""
        query = """
        SELECT 
            p.category,
            p.product_name,
            SUM(oi.quantity) as units_sold,
            SUM(oi.quantity * oi.unit_price) as revenue,
            AVG(oi.unit_price) as avg_price
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_date >= date('now', '-30 days')
        GROUP BY p.category, p.product_name
        ORDER BY revenue DESC
        LIMIT 20
        """
        
        df = self.execute_query(query)
        if df.empty:
            return None
        
        # Create subplots
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Top Products by Revenue', 'Category Performance',
                          'Units vs Revenue', 'Price Distribution'),
            specs=[[{"type": "bar"}, {"type": "pie"}],
                   [{"type": "scatter"}, {"type": "histogram"}]]
        )
        
        # Top products bar chart
        top_products = df.head(10)
        fig.add_trace(
            go.Bar(x=top_products['revenue'], y=top_products['product_name'],
                  orientation='h', name='Revenue',
                  marker_color='lightblue'),
            row=1, col=1
        )
        
        # Category pie chart
        category_revenue = df.groupby('category')['revenue'].sum().reset_index()
        fig.add_trace(
            go.Pie(labels=category_revenue['category'], 
                  values=category_revenue['revenue'],
                  name="Category Revenue"),
            row=1, col=2
        )
        
        # Scatter plot: Units vs Revenue
        fig.add_trace(
            go.Scatter(x=df['units_sold'], y=df['revenue'],
                      mode='markers', name='Products',
                      marker=dict(size=8, color='green', opacity=0.6),
                      text=df['product_name']),
            row=2, col=1
        )
        
        # Price histogram
        fig.add_trace(
            go.Histogram(x=df['avg_price'], name='Price Distribution',
                        marker_color='orange', opacity=0.7),
            row=2, col=2
        )
        
        fig.update_layout(height=800, title_text="Product Performance Analysis",
                         showlegend=False)
        
        return fig
    
    def create_customer_analysis(self):
        """Create customer analysis dashboard"""
        query = """
        SELECT 
            customer_id,
            COUNT(*) as order_count,
            SUM(order_total) as total_spent,
            AVG(order_total) as avg_order_value,
            MIN(order_date) as first_order,
            MAX(order_date) as last_order
        FROM orders
        GROUP BY customer_id
        """
        
        df = self.execute_query(query)
        if df.empty:
            return None
        
        # Create customer segments
        df['customer_segment'] = pd.cut(df['total_spent'], 
                                      bins=[0, 100, 500, 1000, float('inf')],
                                      labels=['Low Value', 'Medium Value', 'High Value', 'VIP'])
        
        # Create dashboard
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Customer Segments', 'Spending Distribution',
                          'Order Frequency', 'Customer Lifetime Value'),
            specs=[[{"type": "pie"}, {"type": "histogram"}],
                   [{"type": "histogram"}, {"type": "box"}]]
        )
        
        # Customer segments pie
        segment_counts = df['customer_segment'].value_counts()
        fig.add_trace(
            go.Pie(labels=segment_counts.index, values=segment_counts.values,
                  name="Customer Segments"),
            row=1, col=1
        )
        
        # Spending distribution
        fig.add_trace(
            go.Histogram(x=df['total_spent'], name='Total Spent',
                        marker_color='blue', opacity=0.7),
            row=1, col=2
        )
        
        # Order frequency
        fig.add_trace(
            go.Histogram(x=df['order_count'], name='Order Count',
                        marker_color='green', opacity=0.7),
            row=2, col=1
        )
        
        # Box plot of CLV by segment
        for segment in df['customer_segment'].unique():
            segment_data = df[df['customer_segment'] == segment]
            fig.add_trace(
                go.Box(y=segment_data['total_spent'], name=str(segment)),
                row=2, col=2
            )
        
        fig.update_layout(height=800, title_text="Customer Analysis Dashboard",
                         showlegend=False)
        
        return fig
    
    def save_reports(self, output_dir="reports"):
        """Generate and save all interactive reports"""
        import os
        os.makedirs(output_dir, exist_ok=True)
        
        print(f"🎯 Generating Interactive Reports in {output_dir}/")
        
        # Sales Dashboard
        print("📊 Creating Sales Dashboard...")
        sales_fig = self.create_sales_dashboard()
        if sales_fig:
            sales_fig.write_html(f"{output_dir}/sales_dashboard_{self.report_date}.html")
            print(f"   ✅ Saved: sales_dashboard_{self.report_date}.html")
        
        # Product Performance
        print("🛍️ Creating Product Performance...")
        product_fig = self.create_product_performance()
        if product_fig:
            product_fig.write_html(f"{output_dir}/product_performance_{self.report_date}.html")
            print(f"   ✅ Saved: product_performance_{self.report_date}.html")
        
        # Customer Analysis
        print("👥 Creating Customer Analysis...")
        customer_fig = self.create_customer_analysis()
        if customer_fig:
            customer_fig.write_html(f"{output_dir}/customer_analysis_{self.report_date}.html")
            print(f"   ✅ Saved: customer_analysis_{self.report_date}.html")
        
        print("✅ All reports generated successfully!")

# Example usage
if __name__ == "__main__":
    print("🎯 Interactive Business Reports Generator")
    print("=" * 50)
    
    print("📝 Features:")
    print("   - Interactive sales dashboards")
    print("   - Product performance analysis")
    print("   - Customer segmentation insights")
    print("   - Hover tooltips and zoom functionality")
    print("   - HTML output for easy sharing")
    print("")
    print("🔧 To use this script:")
    print("1. pip install plotly pandas")
    print("2. Connect to your database")
    print("3. Update SQL queries for your schema")
    print("4. Run: reports = InteractiveReports(connection)")
    print("5. Generate: reports.save_reports()")
    print("")
    print("💡 Pro tip: Open HTML files in browser to explore interactive features!")
