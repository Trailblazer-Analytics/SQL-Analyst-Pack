"""
Automated Business Report Generator
=================================

This script creates comprehensive business reports by combining multiple
SQL queries and analysis into a single automated workflow.

Author: SQL Analyst Pack
Focus: Business Intelligence Automation
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import sqlite3
from pathlib import Path
import json

class BusinessReportGenerator:
    """Automated business report generator for analysts"""
    
    def __init__(self, db_connection, report_config=None):
        self.conn = db_connection
        self.report_date = datetime.now()
        self.config = report_config or self._default_config()
        self.results = {}
        
    def _default_config(self):
        """Default report configuration"""
        return {
            'report_title': 'Business Performance Report',
            'date_range_days': 30,
            'include_sections': [
                'executive_summary',
                'sales_performance', 
                'customer_analysis',
                'product_performance',
                'operational_metrics'
            ],
            'output_formats': ['html', 'pdf'],
            'charts_style': 'seaborn-v0_8'
        }
    
    def execute_sql(self, query, description="Query"):
        """Execute SQL query with error handling"""
        try:
            df = pd.read_sql_query(query, self.conn)
            print(f"✅ {description}: {len(df)} rows returned")
            return df
        except Exception as e:
            print(f"❌ {description} failed: {e}")
            return pd.DataFrame()
    
    def generate_executive_summary(self):
        """Generate executive summary metrics"""
        
        print("📊 Generating Executive Summary...")
        
        days_back = self.config['date_range_days']
        
        # Key metrics queries
        queries = {
            'total_revenue': f"""
                SELECT SUM(order_total) as value
                FROM orders 
                WHERE order_date >= date('now', '-{days_back} days')
            """,
            'total_orders': f"""
                SELECT COUNT(*) as value
                FROM orders 
                WHERE order_date >= date('now', '-{days_back} days')
            """,
            'avg_order_value': f"""
                SELECT AVG(order_total) as value
                FROM orders 
                WHERE order_date >= date('now', '-{days_back} days')
            """,
            'new_customers': f"""
                SELECT COUNT(DISTINCT customer_id) as value
                FROM orders o1
                WHERE order_date >= date('now', '-{days_back} days')
                AND NOT EXISTS (
                    SELECT 1 FROM orders o2 
                    WHERE o2.customer_id = o1.customer_id 
                    AND o2.order_date < date('now', '-{days_back} days')
                )
            """,
            'repeat_customer_rate': f"""
                SELECT 
                    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END) * 100.0 / 
                    COUNT(DISTINCT customer_id) as value
                FROM (
                    SELECT customer_id, COUNT(*) as order_count
                    FROM orders 
                    WHERE order_date >= date('now', '-{days_back} days')
                    GROUP BY customer_id
                )
            """
        }
        
        summary = {}
        for metric, query in queries.items():
            result = self.execute_sql(query, f"Executive metric: {metric}")
            summary[metric] = result.iloc[0, 0] if not result.empty else 0
        
        # Calculate period-over-period changes
        prev_period_queries = {
            'prev_revenue': f"""
                SELECT SUM(order_total) as value
                FROM orders 
                WHERE order_date >= date('now', '-{days_back * 2} days')
                AND order_date < date('now', '-{days_back} days')
            """,
            'prev_orders': f"""
                SELECT COUNT(*) as value
                FROM orders 
                WHERE order_date >= date('now', '-{days_back * 2} days')
                AND order_date < date('now', '-{days_back} days')
            """
        }
        
        for metric, query in prev_period_queries.items():
            result = self.execute_sql(query, f"Previous period: {metric}")
            summary[metric] = result.iloc[0, 0] if not result.empty else 0
        
        # Calculate growth rates
        summary['revenue_growth'] = (
            (summary['total_revenue'] - summary['prev_revenue']) / summary['prev_revenue'] * 100
            if summary['prev_revenue'] > 0 else 0
        )
        
        summary['order_growth'] = (
            (summary['total_orders'] - summary['prev_orders']) / summary['prev_orders'] * 100
            if summary['prev_orders'] > 0 else 0
        )
        
        self.results['executive_summary'] = summary
        return summary
    
    def generate_sales_performance(self):
        """Generate sales performance analysis"""
        
        print("📈 Generating Sales Performance Analysis...")
        
        days_back = self.config['date_range_days']
        
        # Daily sales trend
        daily_sales_query = f"""
        SELECT 
            DATE(order_date) as date,
            SUM(order_total) as daily_sales,
            COUNT(*) as daily_orders,
            AVG(order_total) as daily_aov
        FROM orders 
        WHERE order_date >= date('now', '-{days_back} days')
        GROUP BY DATE(order_date)
        ORDER BY date
        """
        
        daily_sales = self.execute_sql(daily_sales_query, "Daily sales trend")
        daily_sales['date'] = pd.to_datetime(daily_sales['date'])
        
        # Weekly performance
        weekly_sales_query = f"""
        SELECT 
            strftime('%Y-%W', order_date) as week,
            SUM(order_total) as weekly_sales,
            COUNT(*) as weekly_orders
        FROM orders 
        WHERE order_date >= date('now', '-{days_back} days')
        GROUP BY strftime('%Y-%W', order_date)
        ORDER BY week
        """
        
        weekly_sales = self.execute_sql(weekly_sales_query, "Weekly sales performance")
        
        # Top performing days
        dow_performance_query = f"""
        SELECT 
            CASE strftime('%w', order_date)
                WHEN '0' THEN 'Sunday'
                WHEN '1' THEN 'Monday'
                WHEN '2' THEN 'Tuesday'
                WHEN '3' THEN 'Wednesday'
                WHEN '4' THEN 'Thursday'
                WHEN '5' THEN 'Friday'
                WHEN '6' THEN 'Saturday'
            END as day_of_week,
            AVG(order_total) as avg_daily_sales,
            COUNT(*) as total_orders
        FROM orders 
        WHERE order_date >= date('now', '-{days_back} days')
        GROUP BY strftime('%w', order_date)
        ORDER BY avg_daily_sales DESC
        """
        
        dow_performance = self.execute_sql(dow_performance_query, "Day of week performance")
        
        sales_analysis = {
            'daily_sales': daily_sales,
            'weekly_sales': weekly_sales,
            'dow_performance': dow_performance,
            'key_insights': []
        }
        
        # Generate insights
        if not daily_sales.empty:
            best_day = daily_sales.loc[daily_sales['daily_sales'].idxmax()]
            worst_day = daily_sales.loc[daily_sales['daily_sales'].idxmin()]
            
            sales_analysis['key_insights'].extend([
                f"Best sales day: {best_day['date'].strftime('%Y-%m-%d')} (${best_day['daily_sales']:,.0f})",
                f"Worst sales day: {worst_day['date'].strftime('%Y-%m-%d')} (${worst_day['daily_sales']:,.0f})",
                f"Average daily sales: ${daily_sales['daily_sales'].mean():,.0f}"
            ])
        
        self.results['sales_performance'] = sales_analysis
        return sales_analysis
    
    def generate_customer_analysis(self):
        """Generate customer analysis"""
        
        print("👥 Generating Customer Analysis...")
        
        days_back = self.config['date_range_days']
        
        # Customer segmentation
        customer_segments_query = f"""
        SELECT 
            customer_id,
            COUNT(*) as order_count,
            SUM(order_total) as total_spent,
            AVG(order_total) as avg_order_value,
            MAX(order_date) as last_order_date,
            CASE 
                WHEN SUM(order_total) >= 1000 THEN 'High Value'
                WHEN SUM(order_total) >= 500 THEN 'Medium Value'
                ELSE 'Low Value'
            END as value_segment
        FROM orders 
        WHERE order_date >= date('now', '-{days_back} days')
        GROUP BY customer_id
        """
        
        customer_segments = self.execute_sql(customer_segments_query, "Customer segmentation")
        
        # Customer acquisition
        acquisition_query = f"""
        SELECT 
            DATE(first_order) as acquisition_date,
            COUNT(*) as new_customers
        FROM (
            SELECT 
                customer_id,
                MIN(order_date) as first_order
            FROM orders
            GROUP BY customer_id
            HAVING MIN(order_date) >= date('now', '-{days_back} days')
        )
        GROUP BY DATE(first_order)
        ORDER BY acquisition_date
        """
        
        acquisition_data = self.execute_sql(acquisition_query, "Customer acquisition")
        
        # Customer retention
        retention_query = f"""
        SELECT 
            value_segment,
            COUNT(*) as customer_count,
            AVG(total_spent) as avg_clv,
            AVG(order_count) as avg_frequency
        FROM (
            SELECT 
                customer_id,
                COUNT(*) as order_count,
                SUM(order_total) as total_spent,
                CASE 
                    WHEN SUM(order_total) >= 1000 THEN 'High Value'
                    WHEN SUM(order_total) >= 500 THEN 'Medium Value'
                    ELSE 'Low Value'
                END as value_segment
            FROM orders 
            WHERE order_date >= date('now', '-{days_back} days')
            GROUP BY customer_id
        )
        GROUP BY value_segment
        """
        
        retention_data = self.execute_sql(retention_query, "Customer retention analysis")
        
        customer_analysis = {
            'segments': customer_segments,
            'acquisition': acquisition_data,
            'retention': retention_data,
            'insights': []
        }
        
        # Generate insights
        if not customer_segments.empty:
            total_customers = len(customer_segments)
            high_value_customers = len(customer_segments[customer_segments['value_segment'] == 'High Value'])
            high_value_pct = (high_value_customers / total_customers) * 100
            
            customer_analysis['insights'].extend([
                f"Total active customers: {total_customers:,}",
                f"High-value customers: {high_value_customers:,} ({high_value_pct:.1f}%)",
                f"Average customer value: ${customer_segments['total_spent'].mean():,.0f}"
            ])
        
        self.results['customer_analysis'] = customer_analysis
        return customer_analysis
    
    def generate_product_performance(self):
        """Generate product performance analysis"""
        
        print("🛍️ Generating Product Performance Analysis...")
        
        days_back = self.config['date_range_days']
        
        # Top products by revenue
        top_products_query = f"""
        SELECT 
            p.product_name,
            p.category,
            SUM(oi.quantity) as units_sold,
            SUM(oi.quantity * oi.unit_price) as total_revenue,
            AVG(oi.unit_price) as avg_price
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_date >= date('now', '-{days_back} days')
        GROUP BY p.product_id, p.product_name, p.category
        ORDER BY total_revenue DESC
        LIMIT 20
        """
        
        top_products = self.execute_sql(top_products_query, "Top products analysis")
        
        # Category performance
        category_performance_query = f"""
        SELECT 
            p.category,
            COUNT(DISTINCT p.product_id) as product_count,
            SUM(oi.quantity) as units_sold,
            SUM(oi.quantity * oi.unit_price) as total_revenue,
            AVG(oi.unit_price) as avg_price
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_date >= date('now', '-{days_back} days')
        GROUP BY p.category
        ORDER BY total_revenue DESC
        """
        
        category_performance = self.execute_sql(category_performance_query, "Category performance")
        
        product_analysis = {
            'top_products': top_products,
            'category_performance': category_performance,
            'insights': []
        }
        
        # Generate insights
        if not top_products.empty:
            best_product = top_products.iloc[0]
            total_revenue = top_products['total_revenue'].sum()
            top_product_contribution = (best_product['total_revenue'] / total_revenue) * 100
            
            product_analysis['insights'].extend([
                f"Top product: {best_product['product_name']} (${best_product['total_revenue']:,.0f})",
                f"Top product contributes {top_product_contribution:.1f}% of revenue",
                f"Total products sold: {top_products['units_sold'].sum():,} units"
            ])
        
        self.results['product_performance'] = product_analysis
        return product_analysis
    
    def generate_operational_metrics(self):
        """Generate operational metrics"""
        
        print("⚙️ Generating Operational Metrics...")
        
        days_back = self.config['date_range_days']
        
        # Order processing metrics
        order_metrics_query = f"""
        SELECT 
            COUNT(*) as total_orders,
            AVG(order_total) as avg_order_value,
            MIN(order_total) as min_order,
            MAX(order_total) as max_order,
            COUNT(DISTINCT customer_id) as unique_customers,
            COUNT(*) * 1.0 / COUNT(DISTINCT customer_id) as orders_per_customer
        FROM orders 
        WHERE order_date >= date('now', '-{days_back} days')
        """
        
        order_metrics = self.execute_sql(order_metrics_query, "Order processing metrics")
        
        # Daily order volume
        daily_volume_query = f"""
        SELECT 
            DATE(order_date) as date,
            COUNT(*) as order_count
        FROM orders 
        WHERE order_date >= date('now', '-{days_back} days')
        GROUP BY DATE(order_date)
        ORDER BY date
        """
        
        daily_volume = self.execute_sql(daily_volume_query, "Daily order volume")
        daily_volume['date'] = pd.to_datetime(daily_volume['date'])
        
        operational_analysis = {
            'order_metrics': order_metrics,
            'daily_volume': daily_volume,
            'insights': []
        }
        
        # Generate insights
        if not order_metrics.empty:
            metrics = order_metrics.iloc[0]
            operational_analysis['insights'].extend([
                f"Total orders processed: {int(metrics['total_orders']):,}",
                f"Average order value: ${metrics['avg_order_value']:,.2f}",
                f"Orders per customer: {metrics['orders_per_customer']:.1f}"
            ])
        
        self.results['operational_metrics'] = operational_analysis
        return operational_analysis
    
    def create_report_visualizations(self):
        """Create comprehensive report visualizations"""
        
        print("🎨 Creating report visualizations...")
        
        plt.style.use(self.config['charts_style'])
        fig = plt.figure(figsize=(20, 24))
        
        # Executive Summary Dashboard (Top section)
        gs = fig.add_gridspec(6, 4, hspace=0.3, wspace=0.3)
        
        # KPI Cards
        if 'executive_summary' in self.results:
            summary = self.results['executive_summary']
            
            # Revenue KPI
            ax1 = fig.add_subplot(gs[0, 0])
            ax1.text(0.5, 0.6, f"${summary['total_revenue']:,.0f}", 
                    ha='center', va='center', fontsize=20, fontweight='bold')
            ax1.text(0.5, 0.3, 'Total Revenue', ha='center', va='center', fontsize=12)
            ax1.text(0.5, 0.1, f"{summary['revenue_growth']:+.1f}%", 
                    ha='center', va='center', fontsize=10, 
                    color='green' if summary['revenue_growth'] > 0 else 'red')
            ax1.set_xlim(0, 1)
            ax1.set_ylim(0, 1)
            ax1.axis('off')
            
            # Orders KPI
            ax2 = fig.add_subplot(gs[0, 1])
            ax2.text(0.5, 0.6, f"{summary['total_orders']:,.0f}", 
                    ha='center', va='center', fontsize=20, fontweight='bold')
            ax2.text(0.5, 0.3, 'Total Orders', ha='center', va='center', fontsize=12)
            ax2.text(0.5, 0.1, f"{summary['order_growth']:+.1f}%", 
                    ha='center', va='center', fontsize=10,
                    color='green' if summary['order_growth'] > 0 else 'red')
            ax2.set_xlim(0, 1)
            ax2.set_ylim(0, 1)
            ax2.axis('off')
            
            # AOV KPI
            ax3 = fig.add_subplot(gs[0, 2])
            ax3.text(0.5, 0.6, f"${summary['avg_order_value']:,.0f}", 
                    ha='center', va='center', fontsize=20, fontweight='bold')
            ax3.text(0.5, 0.3, 'Avg Order Value', ha='center', va='center', fontsize=12)
            ax3.set_xlim(0, 1)
            ax3.set_ylim(0, 1)
            ax3.axis('off')
            
            # New Customers KPI
            ax4 = fig.add_subplot(gs[0, 3])
            ax4.text(0.5, 0.6, f"{summary['new_customers']:,.0f}", 
                    ha='center', va='center', fontsize=20, fontweight='bold')
            ax4.text(0.5, 0.3, 'New Customers', ha='center', va='center', fontsize=12)
            ax4.set_xlim(0, 1)
            ax4.set_ylim(0, 1)
            ax4.axis('off')
        
        # Sales Performance Charts
        if 'sales_performance' in self.results:
            sales = self.results['sales_performance']
            
            # Daily sales trend
            if not sales['daily_sales'].empty:
                ax5 = fig.add_subplot(gs[1, :2])
                ax5.plot(sales['daily_sales']['date'], sales['daily_sales']['daily_sales'], 
                        marker='o', linewidth=2)
                ax5.set_title('Daily Sales Trend', fontsize=14, fontweight='bold')
                ax5.set_ylabel('Sales ($)')
                ax5.tick_params(axis='x', rotation=45)
                ax5.grid(True, alpha=0.3)
            
            # Day of week performance
            if not sales['dow_performance'].empty:
                ax6 = fig.add_subplot(gs[1, 2:])
                ax6.bar(sales['dow_performance']['day_of_week'], 
                       sales['dow_performance']['avg_daily_sales'])
                ax6.set_title('Average Sales by Day of Week', fontsize=14, fontweight='bold')
                ax6.set_ylabel('Average Sales ($)')
                ax6.tick_params(axis='x', rotation=45)
        
        # Customer Analysis
        if 'customer_analysis' in self.results:
            customers = self.results['customer_analysis']
            
            # Customer segments pie chart
            if not customers['retention'].empty:
                ax7 = fig.add_subplot(gs[2, :2])
                ax7.pie(customers['retention']['customer_count'], 
                       labels=customers['retention']['value_segment'],
                       autopct='%1.1f%%', startangle=90)
                ax7.set_title('Customer Value Segments', fontsize=14, fontweight='bold')
            
            # Customer acquisition
            if not customers['acquisition'].empty:
                ax8 = fig.add_subplot(gs[2, 2:])
                customers['acquisition']['acquisition_date'] = pd.to_datetime(customers['acquisition']['acquisition_date'])
                ax8.plot(customers['acquisition']['acquisition_date'], 
                        customers['acquisition']['new_customers'], marker='o')
                ax8.set_title('Customer Acquisition Trend', fontsize=14, fontweight='bold')
                ax8.set_ylabel('New Customers')
                ax8.tick_params(axis='x', rotation=45)
                ax8.grid(True, alpha=0.3)
        
        # Product Performance
        if 'product_performance' in self.results:
            products = self.results['product_performance']
            
            # Top products
            if not products['top_products'].empty:
                ax9 = fig.add_subplot(gs[3, :2])
                top_10 = products['top_products'].head(10)
                ax9.barh(range(len(top_10)), top_10['total_revenue'])
                ax9.set_yticks(range(len(top_10)))
                ax9.set_yticklabels(top_10['product_name'], fontsize=8)
                ax9.set_xlabel('Revenue ($)')
                ax9.set_title('Top 10 Products by Revenue', fontsize=14, fontweight='bold')
            
            # Category performance
            if not products['category_performance'].empty:
                ax10 = fig.add_subplot(gs[3, 2:])
                ax10.bar(products['category_performance']['category'], 
                        products['category_performance']['total_revenue'])
                ax10.set_title('Revenue by Category', fontsize=14, fontweight='bold')
                ax10.set_ylabel('Revenue ($)')
                ax10.tick_params(axis='x', rotation=45)
        
        # Operational Metrics
        if 'operational_metrics' in self.results:
            ops = self.results['operational_metrics']
            
            # Daily order volume
            if not ops['daily_volume'].empty:
                ax11 = fig.add_subplot(gs[4, :])
                ax11.plot(ops['daily_volume']['date'], ops['daily_volume']['order_count'], 
                         marker='s', linewidth=2, color='orange')
                ax11.set_title('Daily Order Volume', fontsize=14, fontweight='bold')
                ax11.set_ylabel('Number of Orders')
                ax11.tick_params(axis='x', rotation=45)
                ax11.grid(True, alpha=0.3)
        
        # Insights Summary Table
        ax12 = fig.add_subplot(gs[5, :])
        ax12.axis('off')
        
        # Compile all insights
        all_insights = []
        for section, data in self.results.items():
            if 'insights' in data:
                all_insights.extend(data['insights'])
        
        # Create insights table
        if all_insights:
            insights_text = '\n'.join([f"• {insight}" for insight in all_insights[:10]])  # Top 10 insights
            ax12.text(0.05, 0.95, "Key Business Insights:", fontsize=14, fontweight='bold', 
                     transform=ax12.transAxes, va='top')
            ax12.text(0.05, 0.85, insights_text, fontsize=10, 
                     transform=ax12.transAxes, va='top', wrap=True)
        
        plt.suptitle(f"{self.config['report_title']} - {self.report_date.strftime('%Y-%m-%d')}", 
                    fontsize=18, fontweight='bold', y=0.98)
        
        return fig
    
    def save_report(self, output_dir="reports"):
        """Save the complete business report"""
        
        print(f"💾 Saving business report to {output_dir}/...")
        
        Path(output_dir).mkdir(exist_ok=True)
        
        # Create visualization
        dashboard_fig = self.create_report_visualizations()
        
        # Save visualization
        timestamp = self.report_date.strftime('%Y%m%d_%H%M%S')
        chart_filename = f"{output_dir}/business_report_{timestamp}.png"
        dashboard_fig.savefig(chart_filename, dpi=300, bbox_inches='tight')
        print(f"   ✅ Charts saved: {chart_filename}")
        
        # Save data as JSON
        data_filename = f"{output_dir}/business_report_data_{timestamp}.json"
        with open(data_filename, 'w') as f:
            # Convert DataFrames to dict for JSON serialization
            json_data = {}
            for section, data in self.results.items():
                json_data[section] = {}
                for key, value in data.items():
                    if isinstance(value, pd.DataFrame):
                        json_data[section][key] = value.to_dict('records')
                    else:
                        json_data[section][key] = value
            
            json.dump(json_data, f, indent=2, default=str)
        print(f"   ✅ Data saved: {data_filename}")
        
        return {
            'chart_file': chart_filename,
            'data_file': data_filename,
            'report_date': self.report_date,
            'sections_included': list(self.results.keys())
        }
    
    def run_complete_report(self):
        """Run complete business report generation"""
        
        print("🚀 Starting Complete Business Report Generation")
        print("=" * 60)
        
        # Generate all sections based on config
        if 'executive_summary' in self.config['include_sections']:
            self.generate_executive_summary()
        
        if 'sales_performance' in self.config['include_sections']:
            self.generate_sales_performance()
        
        if 'customer_analysis' in self.config['include_sections']:
            self.generate_customer_analysis()
        
        if 'product_performance' in self.config['include_sections']:
            self.generate_product_performance()
        
        if 'operational_metrics' in self.config['include_sections']:
            self.generate_operational_metrics()
        
        # Save the report
        report_files = self.save_report()
        
        print(f"\n✅ Business Report Complete!")
        print(f"📊 Generated {len(self.results)} sections")
        print(f"📁 Files saved: {report_files['chart_file']}, {report_files['data_file']}")
        
        return {
            'results': self.results,
            'files': report_files,
            'config': self.config
        }

# Example usage
if __name__ == "__main__":
    print("🎯 Automated Business Report Generator")
    print("=" * 50)
    
    print("📝 This generator creates:")
    print("   - Executive summary with KPIs and growth metrics")
    print("   - Sales performance analysis and trends")
    print("   - Customer segmentation and acquisition analysis")
    print("   - Product performance and category insights")
    print("   - Operational metrics and efficiency measures")
    print("   - Comprehensive visualization dashboard")
    print("   - Exportable data in JSON format")
    print("")
    print("🔧 To use this generator:")
    print("1. Connect to your database")
    print("2. Configure: config = {'report_title': 'My Report', 'date_range_days': 30}")
    print("3. Run: generator = BusinessReportGenerator(connection, config)")
    print("4. Execute: report = generator.run_complete_report()")
    print("")
    print("💡 Expected tables: orders, order_items, products, customers")
