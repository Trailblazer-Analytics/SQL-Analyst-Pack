"""
Customer Segmentation Analysis using SQL + Python
================================================

This script demonstrates how to perform RFM (Recency, Frequency, Monetary) 
analysis to segment customers for targeted marketing campaigns.

Author: SQL Analyst Pack
Focus: Customer Analytics & Business Intelligence
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import sqlite3

class CustomerSegmentation:
    """RFM Analysis and Customer Segmentation for Business Analysts"""
    
    def __init__(self, db_connection):
        self.conn = db_connection
        self.analysis_date = datetime.now()
        
    def extract_customer_data(self):
        """Extract customer transaction data using SQL"""
        
        query = """
        SELECT 
            customer_id,
            order_date,
            order_total,
            -- Calculate days since analysis date
            julianday('now') - julianday(order_date) as days_since_order
        FROM orders 
        WHERE order_date >= date('now', '-365 days')
        ORDER BY customer_id, order_date
        """
        
        df = pd.read_sql_query(query, self.conn)
        df['order_date'] = pd.to_datetime(df['order_date'])
        
        print(f"📊 Extracted {len(df)} transactions for {df['customer_id'].nunique()} customers")
        return df
    
    def calculate_rfm_metrics(self, df):
        """Calculate RFM (Recency, Frequency, Monetary) metrics"""
        
        print("🔢 Calculating RFM metrics...")
        
        rfm = df.groupby('customer_id').agg({
            'days_since_order': 'min',  # Recency (days since last order)
            'order_date': 'count',      # Frequency (number of orders)
            'order_total': 'sum'        # Monetary (total spent)
        }).round(2)
        
        # Rename columns
        rfm.columns = ['Recency', 'Frequency', 'Monetary']
        
        # Add customer count for validation
        print(f"   ✅ RFM calculated for {len(rfm)} customers")
        print(f"   📈 Average metrics: R={rfm['Recency'].mean():.1f} days, "
              f"F={rfm['Frequency'].mean():.1f} orders, M=${rfm['Monetary'].mean():.0f}")
        
        return rfm
    
    def create_rfm_scores(self, rfm_df):
        """Create RFM scores using quintiles (1-5 scale)"""
        
        print("📊 Creating RFM scores (1-5 scale)...")
        
        # Create a copy to avoid modifying original
        rfm_scores = rfm_df.copy()
        
        # Calculate quintiles for each metric
        # Note: For Recency, lower is better (recent purchases), so we reverse the scoring
        rfm_scores['R_Score'] = pd.qcut(rfm_scores['Recency'], 5, labels=[5,4,3,2,1])
        rfm_scores['F_Score'] = pd.qcut(rfm_scores['Frequency'].rank(method='first'), 5, labels=[1,2,3,4,5])
        rfm_scores['M_Score'] = pd.qcut(rfm_scores['Monetary'], 5, labels=[1,2,3,4,5])
        
        # Convert to numeric
        rfm_scores['R_Score'] = rfm_scores['R_Score'].astype(int)
        rfm_scores['F_Score'] = rfm_scores['F_Score'].astype(int)
        rfm_scores['M_Score'] = rfm_scores['M_Score'].astype(int)
        
        # Create combined RFM score
        rfm_scores['RFM_Score'] = (rfm_scores['R_Score'].astype(str) + 
                                  rfm_scores['F_Score'].astype(str) + 
                                  rfm_scores['M_Score'].astype(str))
        
        print(f"   ✅ RFM scores created")
        return rfm_scores
    
    def create_customer_segments(self, rfm_scores):
        """Create customer segments based on RFM scores"""
        
        print("🎯 Creating customer segments...")
        
        segments = rfm_scores.copy()
        
        # Define segment rules based on RFM scores
        def assign_segment(row):
            r, f, m = row['R_Score'], row['F_Score'], row['M_Score']
            
            # Champions: High RFM scores
            if r >= 4 and f >= 4 and m >= 4:
                return 'Champions'
            
            # Loyal Customers: High R and F, varying M
            elif r >= 3 and f >= 4:
                return 'Loyal Customers'
            
            # Potential Loyalists: Recent customers with good frequency
            elif r >= 4 and f >= 2 and f <= 3:
                return 'Potential Loyalists'
            
            # New Customers: High recency, low frequency
            elif r >= 4 and f <= 2:
                return 'New Customers'
            
            # Promising: Recent customers with medium frequency
            elif r >= 3 and f >= 2 and f <= 3:
                return 'Promising'
            
            # Need Attention: Average recency and frequency
            elif r >= 2 and r <= 3:
                return 'Need Attention'
            
            # About to Sleep: Low recency, varying frequency
            elif r >= 2 and f >= 2:
                return 'About to Sleep'
            
            # At Risk: Low recency, high frequency/monetary in the past
            elif f >= 4 and m >= 4:
                return 'At Risk'
            
            # Cannot Lose Them: Low recency but high monetary value
            elif m >= 4:
                return 'Cannot Lose Them'
            
            # Hibernating: Low scores across the board
            else:
                return 'Hibernating'
        
        segments['Segment'] = segments.apply(assign_segment, axis=1)
        
        # Print segment summary
        segment_summary = segments['Segment'].value_counts()
        print("   ✅ Customer segments created:")
        for segment, count in segment_summary.items():
            percentage = (count / len(segments)) * 100
            print(f"      {segment}: {count} customers ({percentage:.1f}%)")
        
        return segments
    
    def analyze_segment_characteristics(self, segments):
        """Analyze characteristics of each customer segment"""
        
        print("\n📈 Analyzing segment characteristics...")
        
        # Calculate segment metrics
        segment_analysis = segments.groupby('Segment').agg({
            'Recency': ['mean', 'median'],
            'Frequency': ['mean', 'median'], 
            'Monetary': ['mean', 'median', 'sum']
        }).round(2)
        
        # Flatten column names
        segment_analysis.columns = ['_'.join(col).strip() for col in segment_analysis.columns]
        
        # Add customer counts
        segment_analysis['Customer_Count'] = segments.groupby('Segment').size()
        
        # Calculate percentage of total revenue
        total_revenue = segments['Monetary'].sum()
        segment_analysis['Revenue_Percentage'] = (
            segment_analysis['Monetary_sum'] / total_revenue * 100
        ).round(1)
        
        print("   ✅ Segment analysis complete")
        return segment_analysis
    
    def create_visualization_dashboard(self, segments, segment_analysis):
        """Create comprehensive visualization dashboard"""
        
        print("🎨 Creating visualization dashboard...")
        
        # Set up the plot style
        plt.style.use('seaborn-v0_8')
        fig = plt.figure(figsize=(20, 15))
        
        # 1. Segment Distribution (Pie Chart)
        ax1 = plt.subplot(3, 3, 1)
        segment_counts = segments['Segment'].value_counts()
        colors = plt.cm.Set3(np.linspace(0, 1, len(segment_counts)))
        ax1.pie(segment_counts.values, labels=segment_counts.index, autopct='%1.1f%%', 
                colors=colors, startangle=90)
        ax1.set_title('Customer Segment Distribution', fontsize=14, fontweight='bold')
        
        # 2. Revenue by Segment (Bar Chart)
        ax2 = plt.subplot(3, 3, 2)
        segment_revenue = segments.groupby('Segment')['Monetary'].sum().sort_values(ascending=False)
        bars = ax2.bar(range(len(segment_revenue)), segment_revenue.values, color=colors[:len(segment_revenue)])
        ax2.set_xticks(range(len(segment_revenue)))
        ax2.set_xticklabels(segment_revenue.index, rotation=45, ha='right')
        ax2.set_title('Total Revenue by Segment', fontsize=14, fontweight='bold')
        ax2.set_ylabel('Revenue ($)')
        
        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            ax2.text(bar.get_x() + bar.get_width()/2., height,
                    f'${height:,.0f}', ha='center', va='bottom', fontsize=8)
        
        # 3. RFM Score Distribution (Heatmap)
        ax3 = plt.subplot(3, 3, 3)
        rfm_matrix = segments.pivot_table(values='customer_id', 
                                         index='R_Score', 
                                         columns=['F_Score'], 
                                         aggfunc='count', 
                                         fill_value=0)
        sns.heatmap(rfm_matrix, annot=True, fmt='d', cmap='YlOrRd', ax=ax3)
        ax3.set_title('RFM Score Distribution (R vs F)', fontsize=14, fontweight='bold')
        
        # 4. Recency Distribution by Segment
        ax4 = plt.subplot(3, 3, 4)
        segments.boxplot(column='Recency', by='Segment', ax=ax4)
        ax4.set_title('Recency Distribution by Segment', fontsize=14, fontweight='bold')
        ax4.set_xlabel('Customer Segment')
        ax4.set_ylabel('Days Since Last Order')
        plt.setp(ax4.xaxis.get_majorticklabels(), rotation=45, ha='right')
        
        # 5. Frequency vs Monetary Scatter
        ax5 = plt.subplot(3, 3, 5)
        segment_colors = {segment: colors[i] for i, segment in enumerate(segments['Segment'].unique())}
        for segment in segments['Segment'].unique():
            segment_data = segments[segments['Segment'] == segment]
            ax5.scatter(segment_data['Frequency'], segment_data['Monetary'], 
                       label=segment, alpha=0.6, c=[segment_colors[segment]])
        ax5.set_xlabel('Frequency (Number of Orders)')
        ax5.set_ylabel('Monetary Value ($)')
        ax5.set_title('Frequency vs Monetary Value by Segment', fontsize=14, fontweight='bold')
        ax5.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=8)
        
        # 6. Average Order Value by Segment
        ax6 = plt.subplot(3, 3, 6)
        avg_order_value = segments.groupby('Segment')['Monetary'].sum() / segments.groupby('Segment')['Frequency'].sum()
        avg_order_value = avg_order_value.sort_values(ascending=False)
        ax6.bar(range(len(avg_order_value)), avg_order_value.values, color=colors[:len(avg_order_value)])
        ax6.set_xticks(range(len(avg_order_value)))
        ax6.set_xticklabels(avg_order_value.index, rotation=45, ha='right')
        ax6.set_title('Average Order Value by Segment', fontsize=14, fontweight='bold')
        ax6.set_ylabel('Average Order Value ($)')
        
        # 7. Customer Lifecycle (Recency vs Frequency)
        ax7 = plt.subplot(3, 3, 7)
        scatter = ax7.scatter(segments['Recency'], segments['Frequency'], 
                             c=segments['Monetary'], cmap='viridis', alpha=0.6)
        ax7.set_xlabel('Recency (Days Since Last Order)')
        ax7.set_ylabel('Frequency (Number of Orders)')
        ax7.set_title('Customer Lifecycle Analysis', fontsize=14, fontweight='bold')
        plt.colorbar(scatter, ax=ax7, label='Monetary Value ($)')
        
        # 8. Segment Performance Metrics Table
        ax8 = plt.subplot(3, 3, 8)
        ax8.axis('tight')
        ax8.axis('off')
        
        # Create table data
        table_data = []
        for segment in segment_analysis.index:
            row = [
                segment,
                f"{segment_analysis.loc[segment, 'Customer_Count']}",
                f"${segment_analysis.loc[segment, 'Monetary_mean']:,.0f}",
                f"{segment_analysis.loc[segment, 'Frequency_mean']:.1f}",
                f"{segment_analysis.loc[segment, 'Recency_mean']:.0f}",
                f"{segment_analysis.loc[segment, 'Revenue_Percentage']}%"
            ]
            table_data.append(row)
        
        table = ax8.table(cellText=table_data,
                         colLabels=['Segment', 'Count', 'Avg CLV', 'Avg Freq', 'Avg Recency', 'Revenue %'],
                         cellLoc='center',
                         loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(8)
        table.scale(1, 1.5)
        ax8.set_title('Segment Performance Summary', fontsize=14, fontweight='bold')
        
        # 9. RFM Score Correlation
        ax9 = plt.subplot(3, 3, 9)
        rfm_corr = segments[['R_Score', 'F_Score', 'M_Score', 'Recency', 'Frequency', 'Monetary']].corr()
        sns.heatmap(rfm_corr, annot=True, cmap='coolwarm', center=0, ax=ax9)
        ax9.set_title('RFM Metrics Correlation', fontsize=14, fontweight='bold')
        
        plt.suptitle('Customer Segmentation Analysis Dashboard', fontsize=20, fontweight='bold', y=0.98)
        plt.tight_layout()
        
        return fig
    
    def generate_business_recommendations(self, segments, segment_analysis):
        """Generate actionable business recommendations for each segment"""
        
        print("\n💡 Generating business recommendations...")
        
        recommendations = {
            'Champions': {
                'strategy': 'Reward and Retain',
                'actions': [
                    'Offer exclusive VIP programs and early access to new products',
                    'Ask for referrals and reviews',
                    'Upsell premium products and services',
                    'Create a Champions loyalty tier with special perks'
                ],
                'priority': 'High'
            },
            'Loyal Customers': {
                'strategy': 'Maintain Satisfaction',
                'actions': [
                    'Regular engagement through personalized offers',
                    'Birthday and anniversary rewards',
                    'Cross-sell complementary products',
                    'Maintain high service quality'
                ],
                'priority': 'High'
            },
            'Potential Loyalists': {
                'strategy': 'Increase Frequency',
                'actions': [
                    'Create membership programs to increase visit frequency',
                    'Send targeted offers for faster follow-up purchases',
                    'Recommend products based on purchase history',
                    'Implement retention campaigns'
                ],
                'priority': 'Medium'
            },
            'New Customers': {
                'strategy': 'Nurture and Convert',
                'actions': [
                    'Welcome series with product education',
                    'First-time buyer incentives for repeat purchases',
                    'Onboarding campaigns to increase engagement',
                    'Product recommendations and tutorials'
                ],
                'priority': 'Medium'
            },
            'At Risk': {
                'strategy': 'Win Back',
                'actions': [
                    'Send personalized win-back campaigns',
                    'Offer significant discounts or incentives',
                    'Survey to understand pain points',
                    'Re-engagement email series with value propositions'
                ],
                'priority': 'High'
            },
            'Cannot Lose Them': {
                'strategy': 'Urgent Recovery',
                'actions': [
                    'Immediate personal outreach from account managers',
                    'Exclusive recovery offers and apologies',
                    'VIP customer service and problem resolution',
                    'Long-term retention programs'
                ],
                'priority': 'Critical'
            },
            'Hibernating': {
                'strategy': 'Cost-Effective Reactivation',
                'actions': [
                    'Low-cost reactivation campaigns',
                    'Survey to understand dormancy reasons',
                    'Seasonal or event-based re-engagement',
                    'Consider removing from active marketing to reduce costs'
                ],
                'priority': 'Low'
            }
        }
        
        # Print recommendations
        for segment in segment_analysis.index:
            if segment in recommendations:
                rec = recommendations[segment]
                customer_count = segment_analysis.loc[segment, 'Customer_Count']
                revenue_pct = segment_analysis.loc[segment, 'Revenue_Percentage']
                
                print(f"\n🎯 {segment} ({customer_count} customers, {revenue_pct}% revenue)")
                print(f"   Strategy: {rec['strategy']} (Priority: {rec['priority']})")
                print("   Actions:")
                for action in rec['actions']:
                    print(f"   • {action}")
        
        return recommendations
    
    def run_complete_analysis(self):
        """Run the complete customer segmentation analysis"""
        
        print("🚀 Starting Complete Customer Segmentation Analysis")
        print("=" * 60)
        
        # Step 1: Extract data
        customer_data = self.extract_customer_data()
        
        # Step 2: Calculate RFM metrics
        rfm_metrics = self.calculate_rfm_metrics(customer_data)
        
        # Step 3: Create RFM scores
        rfm_scores = self.create_rfm_scores(rfm_metrics)
        
        # Step 4: Create customer segments
        segments = self.create_customer_segments(rfm_scores)
        
        # Step 5: Analyze segment characteristics
        segment_analysis = self.analyze_segment_characteristics(segments)
        
        # Step 6: Create visualizations
        dashboard_fig = self.create_visualization_dashboard(segments, segment_analysis)
        
        # Step 7: Generate recommendations
        recommendations = self.generate_business_recommendations(segments, segment_analysis)
        
        print("\n✅ Analysis Complete!")
        print(f"📊 Dashboard created with {len(segments)} customers in {segments['Segment'].nunique()} segments")
        
        return {
            'segments': segments,
            'analysis': segment_analysis,
            'recommendations': recommendations,
            'dashboard': dashboard_fig
        }

# Example usage
if __name__ == "__main__":
    print("🎯 Customer Segmentation Analysis with RFM")
    print("=" * 50)
    
    print("📝 This analysis includes:")
    print("   - RFM (Recency, Frequency, Monetary) calculation")
    print("   - Customer segmentation (10 business-focused segments)")
    print("   - Comprehensive visualization dashboard")
    print("   - Actionable business recommendations")
    print("   - Marketing strategy for each segment")
    print("")
    print("🔧 To use this analysis:")
    print("1. Connect to your database with customer order data")
    print("2. Update SQL query for your schema")
    print("3. Run: analyzer = CustomerSegmentation(connection)")
    print("4. Execute: results = analyzer.run_complete_analysis()")
    print("5. Save: results['dashboard'].savefig('customer_segments.png', dpi=300)")
    print("")
    print("💡 Expected tables: orders (customer_id, order_date, order_total)")
