"""
Automated Business Dashboard Generator
=====================================

This script creates a multi-page business dashboard from SQL queries.
Perfect for weekly/monthly reporting automation for analysts.

Author: SQL Analyst Pack
Focus: Business Reporting & Dashboard Automation
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.ticker import FuncFormatter
import sqlite3
from datetime import datetime, timedelta
import numpy as np

class BusinessDashboard:
    """Automated dashboard generator for business analysts"""
    
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
    
    def create_kpi_summary(self):
        """Create KPI summary section"""
        # Sample KPI queries (modify for your business)
        kpi_queries = {
            'Total Revenue': """
                SELECT SUM(order_total) as value 
                FROM orders 
                WHERE order_date >= date('now', '-30 days')
            """,
            'New Customers': """
                SELECT COUNT(DISTINCT customer_id) as value
                FROM orders 
                WHERE customer_id NOT IN (
                    SELECT DISTINCT customer_id 
                    FROM orders 
                    WHERE order_date < date('now', '-30 days')
                )
                AND order_date >= date('now', '-30 days')
            """,
            'Average Order Value': """
                SELECT AVG(order_total) as value
                FROM orders 
                WHERE order_date >= date('now', '-30 days')
            """,
            'Order Conversion Rate': """
                SELECT 
                    (COUNT(DISTINCT CASE WHEN order_total > 0 THEN session_id END) * 100.0 / 
                     COUNT(DISTINCT session_id)) as value
                FROM website_sessions ws
                LEFT JOIN orders o ON ws.session_id = o.session_id
                WHERE ws.session_date >= date('now', '-30 days')
            """
        }
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        fig.suptitle('Key Performance Indicators - Last 30 Days', fontsize=20, fontweight='bold')
        
        kpi_values = {}
        for i, (kpi_name, query) in enumerate(kpi_queries.items()):
            ax = axes[i//2, i%2]
            
            # Execute query
            result = self.execute_query(query)
            if not result.empty:
                value = result.iloc[0, 0]
                kpi_values[kpi_name] = value
                
                # Format value based on KPI type
                if 'Revenue' in kpi_name or 'Value' in kpi_name:
                    display_value = f"${value:,.0f}"
                elif 'Rate' in kpi_name:
                    display_value = f"{value:.1f}%"
                else:
                    display_value = f"{value:,.0f}"
                
                # Create KPI box
                ax.text(0.5, 0.6, display_value, 
                       horizontalalignment='center', verticalalignment='center',
                       fontsize=24, fontweight='bold', color='darkblue')
                ax.text(0.5, 0.3, kpi_name,
                       horizontalalignment='center', verticalalignment='center',
                       fontsize=14, color='gray')
                
                # Add trend indicator (simplified)
                try:
                    trend = "↗" if float(value) > 0 else "↘"
                    color = 'green' if float(value) > 0 else 'red'
                except (ValueError, TypeError):
                    trend = "→"
                    color = 'gray'
                ax.text(0.8, 0.8, trend, fontsize=20, color=color)
            
            ax.set_xlim(0, 1)
            ax.set_ylim(0, 1)
            ax.axis('off')
            
            # Add border
            for spine in ax.spines.values():
                spine.set_visible(True)
                spine.set_linewidth(2)
                spine.set_edgecolor('lightgray')
        
        plt.tight_layout()
        return fig
    
    def create_sales_trends(self):
        """Create sales trend analysis"""
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
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle('Sales Performance Trends - Last 90 Days', fontsize=18, fontweight='bold')
        
        # Daily sales trend
        axes[0,0].plot(df['date'], df['daily_sales'], marker='o', linewidth=2)
        axes[0,0].set_title('Daily Sales Revenue')
        axes[0,0].set_ylabel('Revenue ($)')
        axes[0,0].tick_params(axis='x', rotation=45)
        axes[0,0].yaxis.set_major_formatter(FuncFormatter(lambda x, p: f'${x:,.0f}'))
        
        # Order count trend
        axes[0,1].plot(df['date'], df['order_count'], marker='s', linewidth=2, color='orange')
        axes[0,1].set_title('Daily Order Count')
        axes[0,1].set_ylabel('Number of Orders')
        axes[0,1].tick_params(axis='x', rotation=45)
        
        # Average order value trend
        axes[1,0].plot(df['date'], df['avg_order_value'], marker='^', linewidth=2, color='green')
        axes[1,0].set_title('Average Order Value')
        axes[1,0].set_ylabel('AOV ($)')
        axes[1,0].tick_params(axis='x', rotation=45)
        axes[1,0].yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:.0f}'))
        
        # 7-day moving average
        df['sales_7day_ma'] = df['daily_sales'].rolling(window=7).mean()
        axes[1,1].plot(df['date'], df['daily_sales'], alpha=0.3, label='Daily Sales')
        axes[1,1].plot(df['date'], df['sales_7day_ma'], linewidth=3, label='7-Day Moving Average')
        axes[1,1].set_title('Sales with Moving Average')
        axes[1,1].set_ylabel('Revenue ($)')
        axes[1,1].tick_params(axis='x', rotation=45)
        axes[1,1].legend()
        axes[1,1].yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:,.0f}'))
        
        for ax in axes.flat:
            ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        return fig
    
    def create_product_analysis(self):
        """Create product performance analysis"""
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
        """
        
        df = self.execute_query(query)
        if df.empty:
            return None
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle('Product Performance Analysis - Last 30 Days', fontsize=18, fontweight='bold')
        
        # Top products by revenue
        top_products = df.head(10)
        axes[0,0].barh(range(len(top_products)), top_products['revenue'])
        axes[0,0].set_yticks(range(len(top_products)))
        axes[0,0].set_yticklabels(top_products['product_name'], fontsize=8)
        axes[0,0].set_xlabel('Revenue ($)')
        axes[0,0].set_title('Top 10 Products by Revenue')
        axes[0,0].xaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:,.0f}'))
        
        # Category performance
        category_perf = df.groupby('category')['revenue'].sum().sort_values(ascending=False)
        axes[0,1].pie(category_perf.values, labels=category_perf.index, autopct='%1.1f%%')
        axes[0,1].set_title('Revenue Distribution by Category')
        
        # Units sold vs revenue scatter
        axes[1,0].scatter(df['units_sold'], df['revenue'], alpha=0.6)
        axes[1,0].set_xlabel('Units Sold')
        axes[1,0].set_ylabel('Revenue ($)')
        axes[1,0].set_title('Units Sold vs Revenue')
        axes[1,0].yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:,.0f}'))
        
        # Price distribution
        axes[1,1].hist(df['avg_price'], bins=20, edgecolor='black', alpha=0.7)
        axes[1,1].set_xlabel('Average Price ($)')
        axes[1,1].set_ylabel('Number of Products')
        axes[1,1].set_title('Product Price Distribution')
        axes[1,1].xaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:.0f}'))
        
        plt.tight_layout()
        return fig
    
    def create_customer_insights(self):
        """Create customer analysis dashboard"""
        query = """
        SELECT 
            customer_id,
            COUNT(*) as order_count,
            SUM(order_total) as total_spent,
            AVG(order_total) as avg_order_value,
            MIN(order_date) as first_order,
            MAX(order_date) as last_order,
            julianday('now') - julianday(MAX(order_date)) as days_since_last_order
        FROM orders
        GROUP BY customer_id
        HAVING COUNT(*) > 0
        """
        
        df = self.execute_query(query)
        if df.empty:
            return None
        
        # Create customer segments
        df['customer_segment'] = pd.cut(df['total_spent'], 
                                      bins=[0, 100, 500, 1000, float('inf')],
                                      labels=['Low Value', 'Medium Value', 'High Value', 'VIP'])
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle('Customer Insights Dashboard', fontsize=18, fontweight='bold')
        
        # Customer segments
        segment_counts = df['customer_segment'].value_counts()
        axes[0,0].pie(segment_counts.values, labels=segment_counts.index, autopct='%1.1f%%')
        axes[0,0].set_title('Customer Distribution by Value Segment')
        
        # Total spent distribution
        axes[0,1].hist(df['total_spent'], bins=30, edgecolor='black', alpha=0.7)
        axes[0,1].set_xlabel('Total Spent ($)')
        axes[0,1].set_ylabel('Number of Customers')
        axes[0,1].set_title('Customer Spending Distribution')
        axes[0,1].xaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:.0f}'))
        
        # Order frequency
        axes[1,0].hist(df['order_count'], bins=20, edgecolor='black', alpha=0.7, color='orange')
        axes[1,0].set_xlabel('Number of Orders')
        axes[1,0].set_ylabel('Number of Customers')
        axes[1,0].set_title('Order Frequency Distribution')
        
        # Days since last order
        axes[1,1].hist(df['days_since_last_order'], bins=30, edgecolor='black', alpha=0.7, color='red')
        axes[1,1].set_xlabel('Days Since Last Order')
        axes[1,1].set_ylabel('Number of Customers')
        axes[1,1].set_title('Customer Recency Distribution')
        
        plt.tight_layout()
        return fig
    
    def generate_dashboard(self, output_file=None):
        """Generate complete dashboard PDF"""
        if output_file is None:
            output_file = f"business_dashboard_{self.report_date}.pdf"
        
        print(f"🎯 Generating Business Dashboard: {output_file}")
        
        with PdfPages(output_file) as pdf:
            # Page 1: KPI Summary
            print("📊 Creating KPI Summary...")
            fig1 = self.create_kpi_summary()
            if fig1:
                pdf.savefig(fig1, bbox_inches='tight')
                plt.close(fig1)
            
            # Page 2: Sales Trends
            print("📈 Creating Sales Trends...")
            fig2 = self.create_sales_trends()
            if fig2:
                pdf.savefig(fig2, bbox_inches='tight')
                plt.close(fig2)
            
            # Page 3: Product Analysis
            print("🛍️ Creating Product Analysis...")
            fig3 = self.create_product_analysis()
            if fig3:
                pdf.savefig(fig3, bbox_inches='tight')
                plt.close(fig3)
            
            # Page 4: Customer Insights
            print("👥 Creating Customer Insights...")
            fig4 = self.create_customer_insights()
            if fig4:
                pdf.savefig(fig4, bbox_inches='tight')
                plt.close(fig4)
        
        print(f"✅ Dashboard saved: {output_file}")
        return output_file

# Example usage
if __name__ == "__main__":
    print("🎯 Automated Business Dashboard Generator")
    print("=" * 50)
    
    # Note: This is a demo - you'll need actual database connection
    print("📝 Dashboard includes:")
    print("   - KPI Summary (Revenue, Customers, AOV, Conversion)")
    print("   - Sales Trends (90-day analysis)")
    print("   - Product Performance (Top products, categories)")
    print("   - Customer Insights (Segmentation, spending patterns)")
    print("")
    print("🔧 To use this script:")
    print("1. Connect to your database")
    print("2. Update SQL queries for your schema")
    print("3. Run: dashboard = BusinessDashboard(connection)")
    print("4. Generate: dashboard.generate_dashboard()")
    print("")
    print("💡 Pro tip: Schedule this script to run weekly/monthly for automated reporting!")
