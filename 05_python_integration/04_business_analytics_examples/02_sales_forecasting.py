"""
Sales Forecasting using SQL + Python
===================================

This script demonstrates time series analysis and sales forecasting
for business analysts using historical sales data.

Author: SQL Analyst Pack
Focus: Predictive Analytics for Business Planning
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import sqlite3
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

class SalesForecasting:
    """Sales forecasting and trend analysis for business analysts"""
    
    def __init__(self, db_connection):
        self.conn = db_connection
        self.forecast_date = datetime.now()
        
    def extract_sales_data(self, months_back=24):
        """Extract historical sales data from database"""
        
        query = f"""
        SELECT 
            DATE(order_date) as date,
            SUM(order_total) as daily_sales,
            COUNT(*) as order_count,
            AVG(order_total) as avg_order_value
        FROM orders 
        WHERE order_date >= date('now', '-{months_back} months')
        GROUP BY DATE(order_date)
        ORDER BY date
        """
        
        df = pd.read_sql_query(query, self.conn)
        df['date'] = pd.to_datetime(df['date'])
        
        print(f"📊 Extracted {len(df)} days of sales data ({months_back} months)")
        print(f"   Date range: {df['date'].min().date()} to {df['date'].max().date()}")
        print(f"   Total sales: ${df['daily_sales'].sum():,.0f}")
        
        return df
    
    def prepare_time_series(self, df):
        """Prepare time series data with additional features"""
        
        print("🔧 Preparing time series features...")
        
        # Set date as index
        ts_df = df.set_index('date').copy()
        
        # Fill missing dates
        full_date_range = pd.date_range(start=ts_df.index.min(), 
                                       end=ts_df.index.max(), 
                                       freq='D')
        ts_df = ts_df.reindex(full_date_range, fill_value=0)
        
        # Add time-based features
        ts_df['year'] = ts_df.index.year
        ts_df['month'] = ts_df.index.month
        ts_df['day_of_week'] = ts_df.index.dayofweek  # 0 = Monday
        ts_df['day_of_year'] = ts_df.index.dayofyear
        ts_df['week_of_year'] = ts_df.index.isocalendar().week
        ts_df['is_weekend'] = ts_df['day_of_week'].isin([5, 6]).astype(int)
        ts_df['is_month_start'] = ts_df.index.is_month_start.astype(int)
        ts_df['is_month_end'] = ts_df.index.is_month_end.astype(int)
        
        # Add lag features
        ts_df['sales_lag_1'] = ts_df['daily_sales'].shift(1)
        ts_df['sales_lag_7'] = ts_df['daily_sales'].shift(7)
        ts_df['sales_lag_30'] = ts_df['daily_sales'].shift(30)
        
        # Moving averages
        ts_df['sales_ma_7'] = ts_df['daily_sales'].rolling(window=7).mean()
        ts_df['sales_ma_30'] = ts_df['daily_sales'].rolling(window=30).mean()
        ts_df['sales_ma_90'] = ts_df['daily_sales'].rolling(window=90).mean()
        
        # Growth rates
        ts_df['sales_growth_7d'] = ts_df['daily_sales'].pct_change(7) * 100
        ts_df['sales_growth_30d'] = ts_df['daily_sales'].pct_change(30) * 100
        
        print(f"   ✅ Added {len(ts_df.columns)} features")
        return ts_df
    
    def analyze_trends(self, ts_df):
        """Analyze sales trends and patterns"""
        
        print("📈 Analyzing sales trends...")
        
        trends = {}
        
        # Overall trend (linear regression)
        x = np.arange(len(ts_df))
        y = ts_df['daily_sales'].values
        slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
        
        trends['overall_trend'] = {
            'slope': slope,
            'r_squared': r_value**2,
            'p_value': p_value,
            'direction': 'Increasing' if slope > 0 else 'Decreasing',
            'strength': 'Strong' if abs(r_value) > 0.7 else 'Moderate' if abs(r_value) > 0.3 else 'Weak'
        }
        
        # Seasonal patterns
        monthly_avg = ts_df.groupby('month')['daily_sales'].mean()
        dow_avg = ts_df.groupby('day_of_week')['daily_sales'].mean()
        
        trends['seasonal'] = {
            'best_month': monthly_avg.idxmax(),
            'worst_month': monthly_avg.idxmin(),
            'monthly_variation': (monthly_avg.max() - monthly_avg.min()) / monthly_avg.mean() * 100,
            'best_day': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dow_avg.idxmax()],
            'worst_day': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dow_avg.idxmin()],
            'weekend_vs_weekday': ts_df[ts_df['is_weekend'] == 1]['daily_sales'].mean() / ts_df[ts_df['is_weekend'] == 0]['daily_sales'].mean()
        }
        
        # Growth analysis
        recent_30d = ts_df['daily_sales'].tail(30).mean()
        previous_30d = ts_df['daily_sales'].iloc[-60:-30].mean()
        growth_30d = (recent_30d - previous_30d) / previous_30d * 100 if previous_30d > 0 else 0
        
        trends['growth'] = {
            'last_30d_growth': growth_30d,
            'current_avg': recent_30d,
            'previous_avg': previous_30d
        }
        
        print("   ✅ Trend analysis complete")
        return trends
    
    def simple_moving_average_forecast(self, ts_df, forecast_days=30, window=30):
        """Simple moving average forecast"""
        
        last_ma = ts_df['daily_sales'].rolling(window=window).mean().iloc[-1]
        forecast = [last_ma] * forecast_days
        
        return forecast
    
    def linear_trend_forecast(self, ts_df, forecast_days=30):
        """Linear trend forecast using regression"""
        
        # Use last 90 days for trend calculation
        recent_data = ts_df['daily_sales'].tail(90)
        x = np.arange(len(recent_data))
        y = recent_data.values
        
        slope, intercept, _, _, _ = stats.linregress(x, y)
        
        # Project forward
        future_x = np.arange(len(recent_data), len(recent_data) + forecast_days)
        forecast = slope * future_x + intercept
        
        # Ensure non-negative values
        forecast = np.maximum(forecast, 0)
        
        return forecast
    
    def seasonal_forecast(self, ts_df, forecast_days=30):
        """Seasonal forecast using historical patterns"""
        
        # Calculate seasonal factors
        ts_df_copy = ts_df.copy()
        ts_df_copy['month'] = ts_df_copy.index.month
        ts_df_copy['day_of_week'] = ts_df_copy.index.dayofweek
        
        # Monthly seasonality
        monthly_factors = ts_df_copy.groupby('month')['daily_sales'].mean()
        overall_mean = ts_df_copy['daily_sales'].mean()
        monthly_factors = monthly_factors / overall_mean
        
        # Day of week seasonality
        dow_factors = ts_df_copy.groupby('day_of_week')['daily_sales'].mean()
        dow_factors = dow_factors / overall_mean
        
        # Base forecast (trend)
        base_forecast = self.linear_trend_forecast(ts_df, forecast_days)
        
        # Apply seasonal adjustments
        forecast_dates = pd.date_range(start=ts_df.index[-1] + timedelta(days=1), 
                                      periods=forecast_days, freq='D')
        
        seasonal_forecast = []
        for i, date in enumerate(forecast_dates):
            month_factor = monthly_factors.get(date.month, 1.0)
            dow_factor = dow_factors.get(date.weekday(), 1.0)
            
            # Combine factors
            seasonal_factor = (month_factor + dow_factor) / 2
            seasonal_value = base_forecast[i] * seasonal_factor
            seasonal_forecast.append(seasonal_value)
        
        return seasonal_forecast
    
    def create_forecast_visualization(self, ts_df, forecasts, forecast_days=30):
        """Create comprehensive forecast visualization"""
        
        print("🎨 Creating forecast visualization...")
        
        # Prepare forecast dates
        forecast_dates = pd.date_range(start=ts_df.index[-1] + timedelta(days=1), 
                                      periods=forecast_days, freq='D')
        
        # Create subplots
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle('Sales Forecasting Analysis', fontsize=16, fontweight='bold')
        
        # 1. Historical sales with forecasts
        ax1 = axes[0, 0]
        
        # Plot historical data (last 90 days for clarity)
        recent_ts = ts_df.tail(90)
        ax1.plot(recent_ts.index, recent_ts['daily_sales'], 
                label='Historical Sales', color='blue', linewidth=2)
        
        # Plot forecasts
        for method, forecast in forecasts.items():
            ax1.plot(forecast_dates, forecast, 
                    label=f'{method} Forecast', linewidth=2, linestyle='--')
        
        ax1.set_title('Sales Forecast Comparison')
        ax1.set_xlabel('Date')
        ax1.set_ylabel('Daily Sales ($)')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        ax1.tick_params(axis='x', rotation=45)
        
        # 2. Monthly trend analysis
        ax2 = axes[0, 1]
        monthly_sales = ts_df.groupby(ts_df.index.month)['daily_sales'].mean()
        month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        ax2.bar(range(1, 13), [monthly_sales.get(i, 0) for i in range(1, 13)])
        ax2.set_xticks(range(1, 13))
        ax2.set_xticklabels(month_names)
        ax2.set_title('Average Daily Sales by Month')
        ax2.set_ylabel('Average Daily Sales ($)')
        
        # 3. Day of week analysis
        ax3 = axes[1, 0]
        dow_sales = ts_df.groupby(ts_df.index.dayofweek)['daily_sales'].mean()
        dow_names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        ax3.bar(range(7), [dow_sales.get(i, 0) for i in range(7)])
        ax3.set_xticks(range(7))
        ax3.set_xticklabels(dow_names)
        ax3.set_title('Average Daily Sales by Day of Week')
        ax3.set_ylabel('Average Daily Sales ($)')
        
        # 4. Forecast summary statistics
        ax4 = axes[1, 1]
        ax4.axis('off')
        
        # Create forecast summary table
        forecast_summary = []
        for method, forecast in forecasts.items():
            summary = [
                method,
                f"${np.mean(forecast):,.0f}",
                f"${np.sum(forecast):,.0f}",
                f"${np.min(forecast):,.0f}",
                f"${np.max(forecast):,.0f}"
            ]
            forecast_summary.append(summary)
        
        table = ax4.table(cellText=forecast_summary,
                         colLabels=['Method', 'Avg Daily', f'{forecast_days}d Total', 'Min', 'Max'],
                         cellLoc='center',
                         loc='center',
                         bbox=[0, 0, 1, 1])
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        ax4.set_title('Forecast Summary', fontsize=12, fontweight='bold', pad=20)
        
        plt.tight_layout()
        return fig
    
    def generate_business_insights(self, ts_df, trends, forecasts):
        """Generate actionable business insights from analysis"""
        
        print("💡 Generating business insights...")
        
        insights = {
            'trend_insights': [],
            'seasonal_insights': [],
            'forecast_insights': [],
            'recommendations': []
        }
        
        # Trend insights
        trend = trends['overall_trend']
        if trend['direction'] == 'Increasing':
            insights['trend_insights'].append(
                f"Sales are trending {trend['direction'].lower()} with {trend['strength'].lower()} correlation (R² = {trend['r_squared']:.3f})"
            )
        else:
            insights['trend_insights'].append(
                f"⚠️ Sales are trending {trend['direction'].lower()} - intervention may be needed"
            )
        
        # Seasonal insights
        seasonal = trends['seasonal']
        insights['seasonal_insights'].extend([
            f"Best performing month: {seasonal['best_month']} (Month {seasonal['best_month']})",
            f"Worst performing month: {seasonal['worst_month']} (Month {seasonal['worst_month']})",
            f"Monthly variation: {seasonal['monthly_variation']:.1f}%",
            f"Best day: {seasonal['best_day']}, Worst day: {seasonal['worst_day']}",
            f"Weekend vs Weekday ratio: {seasonal['weekend_vs_weekday']:.2f}"
        ])
        
        # Growth insights
        growth = trends['growth']
        if growth['last_30d_growth'] > 5:
            insights['trend_insights'].append(f"✅ Strong growth: {growth['last_30d_growth']:.1f}% in last 30 days")
        elif growth['last_30d_growth'] < -5:
            insights['trend_insights'].append(f"⚠️ Declining sales: {growth['last_30d_growth']:.1f}% in last 30 days")
        else:
            insights['trend_insights'].append(f"Stable sales: {growth['last_30d_growth']:.1f}% change in last 30 days")
        
        # Forecast insights
        forecast_avg = np.mean(list(forecasts.values()), axis=0)
        current_avg = ts_df['daily_sales'].tail(30).mean()
        forecast_change = (np.mean(forecast_avg) - current_avg) / current_avg * 100
        
        insights['forecast_insights'].extend([
            f"Expected daily sales (next 30 days): ${np.mean(forecast_avg):,.0f}",
            f"Projected change from current: {forecast_change:+.1f}%",
            f"Total forecasted revenue (30 days): ${np.sum(forecast_avg):,.0f}"
        ])
        
        # Business recommendations
        if growth['last_30d_growth'] < 0:
            insights['recommendations'].extend([
                "Investigate factors causing sales decline",
                "Consider promotional campaigns to boost sales",
                "Analyze customer feedback and market conditions"
            ])
        
        if seasonal['monthly_variation'] > 30:
            insights['recommendations'].extend([
                "High seasonal variation detected - prepare inventory management",
                "Consider seasonal marketing campaigns",
                "Plan cash flow around seasonal patterns"
            ])
        
        if seasonal['weekend_vs_weekday'] > 1.2:
            insights['recommendations'].append("Weekend sales are strong - consider weekend-specific promotions")
        elif seasonal['weekend_vs_weekday'] < 0.8:
            insights['recommendations'].append("Weekday sales outperform weekends - focus weekday marketing")
        
        return insights
    
    def run_complete_forecast(self, forecast_days=30):
        """Run complete sales forecasting analysis"""
        
        print("🚀 Starting Complete Sales Forecasting Analysis")
        print("=" * 60)
        
        # Step 1: Extract sales data
        sales_data = self.extract_sales_data()
        
        # Step 2: Prepare time series
        ts_data = self.prepare_time_series(sales_data)
        
        # Step 3: Analyze trends
        trends = self.analyze_trends(ts_data)
        
        # Step 4: Generate forecasts
        print(f"🔮 Generating {forecast_days}-day forecasts...")
        forecasts = {
            'Moving Average': self.simple_moving_average_forecast(ts_data, forecast_days),
            'Linear Trend': self.linear_trend_forecast(ts_data, forecast_days),
            'Seasonal': self.seasonal_forecast(ts_data, forecast_days)
        }
        
        # Step 5: Create visualizations
        forecast_fig = self.create_forecast_visualization(ts_data, forecasts, forecast_days)
        
        # Step 6: Generate insights
        insights = self.generate_business_insights(ts_data, trends, forecasts)
        
        print("\n✅ Forecasting Analysis Complete!")
        print(f"📊 Generated forecasts using {len(forecasts)} methods")
        
        return {
            'data': ts_data,
            'trends': trends,
            'forecasts': forecasts,
            'insights': insights,
            'visualization': forecast_fig
        }

# Example usage
if __name__ == "__main__":
    print("🎯 Sales Forecasting with Time Series Analysis")
    print("=" * 50)
    
    print("📝 This analysis includes:")
    print("   - Historical sales trend analysis")
    print("   - Seasonal pattern detection")
    print("   - Multiple forecasting methods (MA, Linear, Seasonal)")
    print("   - Business insights and recommendations")
    print("   - Comprehensive visualization dashboard")
    print("")
    print("🔧 To use this analysis:")
    print("1. Connect to your database with sales order data")
    print("2. Update SQL query for your schema")
    print("3. Run: forecaster = SalesForecasting(connection)")
    print("4. Execute: results = forecaster.run_complete_forecast(30)")
    print("5. Save: results['visualization'].savefig('sales_forecast.png', dpi=300)")
    print("")
    print("💡 Expected tables: orders (order_date, order_total)")
