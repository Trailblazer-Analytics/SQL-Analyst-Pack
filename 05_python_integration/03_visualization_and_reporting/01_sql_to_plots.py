"""
SQL to Visualization Pipeline - Basic Charts for Analysts
=========================================================

This script demonstrates how to connect to a database, run SQL queries,
and create basic business charts using Python. Perfect for analysts who 
need to quickly visualize SQL results.

Author: SQL Analyst Pack
Focus: Business Analytics & Data Visualization
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import sqlite3
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# Set up plotting style
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")

def connect_to_database(db_path="sample_data.db"):
    """Connect to SQLite database (modify for your database type)"""
    try:
        conn = sqlite3.connect(db_path)
        print(f"✅ Connected to database: {db_path}")
        return conn
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return None

def execute_sql_to_dataframe(conn, query, query_name="Query"):
    """Execute SQL query and return results as pandas DataFrame"""
    try:
        df = pd.read_sql_query(query, conn)
        print(f"✅ {query_name} executed successfully - {len(df)} rows returned")
        return df
    except Exception as e:
        print(f"❌ {query_name} failed: {e}")
        return None

def create_sales_trend_chart(df, date_col='order_date', value_col='total_sales'):
    """Create a sales trend line chart"""
    plt.figure(figsize=(12, 6))
    
    # Convert date column to datetime
    df[date_col] = pd.to_datetime(df[date_col])
    df = df.sort_values(date_col)
    
    plt.plot(df[date_col], df[value_col], marker='o', linewidth=2, markersize=4)
    plt.title('Sales Trend Over Time', fontsize=16, fontweight='bold')
    plt.xlabel('Date', fontsize=12)
    plt.ylabel('Total Sales ($)', fontsize=12)
    plt.xticks(rotation=45)
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    # Format y-axis as currency
    ax = plt.gca()
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:,.0f}'))
    
    return plt.gcf()

def create_top_products_chart(df, product_col='product_name', value_col='total_revenue', top_n=10):
    """Create horizontal bar chart for top products"""
    plt.figure(figsize=(12, 8))
    
    # Get top N products
    top_products = df.nlargest(top_n, value_col)
    
    # Create horizontal bar chart
    bars = plt.barh(range(len(top_products)), top_products[value_col])
    plt.yticks(range(len(top_products)), top_products[product_col])
    plt.xlabel('Revenue ($)', fontsize=12)
    plt.ylabel('Product', fontsize=12)
    plt.title(f'Top {top_n} Products by Revenue', fontsize=16, fontweight='bold')
    
    # Add value labels on bars
    for i, bar in enumerate(bars):
        width = bar.get_width()
        plt.text(width, bar.get_y() + bar.get_height()/2, 
                f'${width:,.0f}', ha='left', va='center', fontweight='bold')
    
    plt.tight_layout()
    return plt.gcf()

def create_customer_segment_pie(df, segment_col='customer_segment', value_col='revenue'):
    """Create pie chart for customer segments"""
    plt.figure(figsize=(10, 8))
    
    # Group by segment and sum revenue
    segment_data = df.groupby(segment_col)[value_col].sum().sort_values(ascending=False)
    
    # Create pie chart
    colors = sns.color_palette("husl", len(segment_data))
    plt.pie(segment_data.values, labels=segment_data.index, autopct='%1.1f%%', 
            startangle=90, colors=colors)
    plt.title('Revenue Distribution by Customer Segment', fontsize=16, fontweight='bold')
    plt.axis('equal')
    
    return plt.gcf()

def create_monthly_comparison_chart(df, month_col='month', value_col='sales', year_col='year'):
    """Create grouped bar chart comparing months across years"""
    plt.figure(figsize=(14, 8))
    
    # Pivot data for grouped bar chart
    pivot_df = df.pivot(index=month_col, columns=year_col, values=value_col)
    
    # Create grouped bar chart
    ax = pivot_df.plot(kind='bar', figsize=(14, 8), width=0.8)
    plt.title('Monthly Sales Comparison by Year', fontsize=16, fontweight='bold')
    plt.xlabel('Month', fontsize=12)
    plt.ylabel('Sales ($)', fontsize=12)
    plt.xticks(rotation=45)
    plt.legend(title='Year', title_fontsize=12)
    plt.grid(True, alpha=0.3, axis='y')
    
    # Format y-axis as currency
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x:,.0f}'))
    
    plt.tight_layout()
    return plt.gcf()

# Example usage with sample SQL queries
if __name__ == "__main__":
    print("🎯 SQL to Visualization Pipeline Demo")
    print("=" * 50)
    
    # Sample SQL queries (modify for your database)
    SALES_TREND_QUERY = """
    SELECT 
        DATE(order_date) as order_date,
        SUM(order_total) as total_sales
    FROM orders 
    WHERE order_date >= date('now', '-12 months')
    GROUP BY DATE(order_date)
    ORDER BY order_date
    """
    
    TOP_PRODUCTS_QUERY = """
    SELECT 
        p.product_name,
        SUM(oi.quantity * oi.unit_price) as total_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_name
    ORDER BY total_revenue DESC
    LIMIT 15
    """
    
    CUSTOMER_SEGMENTS_QUERY = """
    SELECT 
        CASE 
            WHEN total_spent >= 1000 THEN 'High Value'
            WHEN total_spent >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END as customer_segment,
        total_spent as revenue
    FROM (
        SELECT 
            customer_id,
            SUM(order_total) as total_spent
        FROM orders
        GROUP BY customer_id
    ) customer_totals
    """
    
    # Note: This is a demo script - you'll need actual database connection
    print("📝 Sample queries defined:")
    print("   - Sales trend analysis")
    print("   - Top products ranking") 
    print("   - Customer segmentation")
    print("")
    print("🔧 To use this script:")
    print("1. Update connection details for your database")
    print("2. Modify SQL queries for your schema")
    print("3. Run the visualization functions")
    print("")
    print("💡 Pro tip: Save charts with plt.savefig('chart_name.png', dpi=300, bbox_inches='tight')")
