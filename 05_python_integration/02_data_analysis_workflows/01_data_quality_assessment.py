"""
Automated SQL Data Quality Assessment
===================================

This script automates data quality checks across database tables,
perfect for analysts who need to quickly assess data reliability.

Author: SQL Analyst Pack
Focus: Data Quality & Validation Automation
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import sqlite3
from typing import Dict, List, Any
import warnings
warnings.filterwarnings('ignore')

class DataQualityAssessment:
    """Automated data quality assessment for business analysts"""
    
    def __init__(self, db_connection):
        self.conn = db_connection
        self.assessment_date = datetime.now()
        self.quality_report = {}
        
    def get_table_list(self):
        """Get list of all tables in the database"""
        
        query = """
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name NOT LIKE 'sqlite_%'
        ORDER BY name
        """
        
        try:
            tables = pd.read_sql_query(query, self.conn)
            table_list = tables['name'].tolist()
            print(f"📊 Found {len(table_list)} tables: {', '.join(table_list)}")
            return table_list
        except Exception as e:
            print(f"❌ Error getting table list: {e}")
            return []
    
    def get_table_schema(self, table_name):
        """Get schema information for a table"""
        
        query = f"PRAGMA table_info({table_name})"
        
        try:
            schema = pd.read_sql_query(query, self.conn)
            return schema
        except Exception as e:
            print(f"❌ Error getting schema for {table_name}: {e}")
            return pd.DataFrame()
    
    def assess_table_completeness(self, table_name):
        """Assess data completeness for a table"""
        
        print(f"🔍 Assessing completeness for {table_name}...")
        
        # Get total row count
        count_query = f"SELECT COUNT(*) as total_rows FROM {table_name}"
        total_rows = pd.read_sql_query(count_query, self.conn).iloc[0, 0]
        
        if total_rows == 0:
            return {
                'total_rows': 0,
                'null_analysis': {},
                'completeness_score': 0,
                'issues': ['Table is empty']
            }
        
        # Get schema
        schema = self.get_table_schema(table_name)
        
        # Analyze null values for each column
        null_analysis = {}
        for _, column in schema.iterrows():
            col_name = column['name']
            
            # Count nulls and empty strings
            null_query = f"""
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN {col_name} IS NULL OR {col_name} = '' THEN 1 END) as nulls
            FROM {table_name}
            """
            
            result = pd.read_sql_query(null_query, self.conn)
            null_count = result.iloc[0, 1]
            null_percentage = (null_count / total_rows) * 100
            
            null_analysis[col_name] = {
                'null_count': null_count,
                'null_percentage': null_percentage,
                'data_type': column['type']
            }
        
        # Calculate overall completeness score
        avg_completeness = np.mean([100 - info['null_percentage'] for info in null_analysis.values()])
        
        # Identify issues
        issues = []
        for col, info in null_analysis.items():
            if info['null_percentage'] > 50:
                issues.append(f"{col}: {info['null_percentage']:.1f}% missing data")
            elif info['null_percentage'] > 20:
                issues.append(f"{col}: {info['null_percentage']:.1f}% missing (moderate)")
        
        return {
            'total_rows': total_rows,
            'null_analysis': null_analysis,
            'completeness_score': avg_completeness,
            'issues': issues
        }
    
    def assess_data_consistency(self, table_name):
        """Assess data consistency patterns"""
        
        print(f"🔍 Assessing consistency for {table_name}...")
        
        schema = self.get_table_schema(table_name)
        consistency_analysis = {}
        
        for _, column in schema.iterrows():
            col_name = column['name']
            col_type = column['type'].upper()
            
            analysis = {
                'data_type': col_type,
                'issues': []
            }
            
            # Check for data type consistency
            if 'TEXT' in col_type or 'VARCHAR' in col_type:
                # Text analysis
                text_query = f"""
                SELECT 
                    COUNT(DISTINCT {col_name}) as unique_values,
                    COUNT(*) as total_values,
                    MIN(LENGTH({col_name})) as min_length,
                    MAX(LENGTH({col_name})) as max_length,
                    AVG(LENGTH({col_name})) as avg_length
                FROM {table_name}
                WHERE {col_name} IS NOT NULL AND {col_name} != ''
                """
                
                result = pd.read_sql_query(text_query, self.conn)
                if not result.empty:
                    stats = result.iloc[0]
                    analysis.update({
                        'unique_values': stats['unique_values'],
                        'total_values': stats['total_values'],
                        'min_length': stats['min_length'],
                        'max_length': stats['max_length'],
                        'avg_length': stats['avg_length'],
                        'uniqueness_ratio': stats['unique_values'] / stats['total_values'] if stats['total_values'] > 0 else 0
                    })
                    
                    # Check for potential issues
                    if stats['max_length'] - stats['min_length'] > 100:
                        analysis['issues'].append("High length variation")
                    
                    if stats['unique_values'] / stats['total_values'] < 0.1 and stats['unique_values'] > 1:
                        analysis['issues'].append("Low uniqueness - possible data quality issue")
            
            elif 'INT' in col_type or 'REAL' in col_type or 'NUMERIC' in col_type:
                # Numeric analysis
                numeric_query = f"""
                SELECT 
                    MIN({col_name}) as min_value,
                    MAX({col_name}) as max_value,
                    AVG({col_name}) as avg_value,
                    COUNT(DISTINCT {col_name}) as unique_values,
                    COUNT(*) as total_values
                FROM {table_name}
                WHERE {col_name} IS NOT NULL
                """
                
                result = pd.read_sql_query(numeric_query, self.conn)
                if not result.empty:
                    stats = result.iloc[0]
                    analysis.update({
                        'min_value': stats['min_value'],
                        'max_value': stats['max_value'],
                        'avg_value': stats['avg_value'],
                        'unique_values': stats['unique_values'],
                        'total_values': stats['total_values']
                    })
                    
                    # Check for outliers (simple rule)
                    if stats['min_value'] < 0 and 'id' in col_name.lower():
                        analysis['issues'].append("Negative values in ID field")
                    
                    # Check for suspicious patterns
                    if stats['unique_values'] == 1:
                        analysis['issues'].append("All values are identical")
            
            consistency_analysis[col_name] = analysis
        
        return consistency_analysis
    
    def assess_business_rules(self, table_name):
        """Assess common business rule violations"""
        
        print(f"🔍 Assessing business rules for {table_name}...")
        
        business_issues = []
        
        try:
            # Check for common business rule violations
            schema = self.get_table_schema(table_name)
            columns = [col['name'] for _, col in schema.iterrows()]
            
            # Date-related checks
            date_columns = [col for col in columns if 'date' in col.lower() or 'time' in col.lower()]
            for date_col in date_columns:
                # Check for future dates
                future_query = f"""
                SELECT COUNT(*) as future_count
                FROM {table_name}
                WHERE {date_col} > date('now')
                """
                
                result = pd.read_sql_query(future_query, self.conn)
                future_count = result.iloc[0, 0]
                if future_count > 0:
                    business_issues.append(f"{date_col}: {future_count} future dates found")
            
            # Email format checks (if email column exists)
            email_columns = [col for col in columns if 'email' in col.lower()]
            for email_col in email_columns:
                email_query = f"""
                SELECT COUNT(*) as invalid_emails
                FROM {table_name}
                WHERE {email_col} NOT LIKE '%@%' 
                AND {email_col} IS NOT NULL 
                AND {email_col} != ''
                """
                
                result = pd.read_sql_query(email_query, self.conn)
                invalid_count = result.iloc[0, 0]
                if invalid_count > 0:
                    business_issues.append(f"{email_col}: {invalid_count} invalid email formats")
            
            # Price/Amount checks
            amount_columns = [col for col in columns if any(word in col.lower() for word in ['price', 'amount', 'total', 'cost'])]
            for amount_col in amount_columns:
                negative_query = f"""
                SELECT COUNT(*) as negative_amounts
                FROM {table_name}
                WHERE {amount_col} < 0
                """
                
                result = pd.read_sql_query(negative_query, self.conn)
                negative_count = result.iloc[0, 0]
                if negative_count > 0:
                    business_issues.append(f"{amount_col}: {negative_count} negative amounts")
            
        except Exception as e:
            business_issues.append(f"Error checking business rules: {str(e)}")
        
        return business_issues
    
    def check_referential_integrity(self, table_name):
        """Check for potential referential integrity issues"""
        
        print(f"🔍 Checking referential integrity for {table_name}...")
        
        integrity_issues = []
        
        try:
            schema = self.get_table_schema(table_name)
            columns = [col['name'] for _, col in schema.iterrows()]
            
            # Look for potential foreign key columns (columns ending with _id)
            fk_columns = [col for col in columns if col.lower().endswith('_id') and col.lower() != 'id']
            
            for fk_col in fk_columns:
                # Check for orphaned records (simplified check)
                # This would need to be customized based on actual foreign key relationships
                orphan_query = f"""
                SELECT COUNT(*) as total_records,
                       COUNT(DISTINCT {fk_col}) as unique_foreign_keys,
                       COUNT(CASE WHEN {fk_col} IS NULL THEN 1 END) as null_foreign_keys
                FROM {table_name}
                """
                
                result = pd.read_sql_query(orphan_query, self.conn)
                stats = result.iloc[0]
                
                if stats['null_foreign_keys'] > 0:
                    null_pct = (stats['null_foreign_keys'] / stats['total_records']) * 100
                    integrity_issues.append(f"{fk_col}: {null_pct:.1f}% null foreign keys")
                
        except Exception as e:
            integrity_issues.append(f"Error checking referential integrity: {str(e)}")
        
        return integrity_issues
    
    def generate_data_profile(self, table_name):
        """Generate comprehensive data profile for a table"""
        
        print(f"📊 Generating data profile for {table_name}...")
        
        # Get basic table info
        row_count_query = f"SELECT COUNT(*) as row_count FROM {table_name}"
        row_count = pd.read_sql_query(row_count_query, self.conn).iloc[0, 0]
        
        schema = self.get_table_schema(table_name)
        
        profile = {
            'table_name': table_name,
            'row_count': row_count,
            'column_count': len(schema),
            'assessment_date': self.assessment_date.isoformat(),
            'columns': {}
        }
        
        # Profile each column
        for _, column in schema.iterrows():
            col_name = column['name']
            col_type = column['type']
            
            # Basic statistics
            stats_query = f"""
            SELECT 
                COUNT(*) as total_count,
                COUNT({col_name}) as non_null_count,
                COUNT(DISTINCT {col_name}) as unique_count
            FROM {table_name}
            """
            
            stats = pd.read_sql_query(stats_query, self.conn).iloc[0]
            
            col_profile = {
                'data_type': col_type,
                'total_count': stats['total_count'],
                'non_null_count': stats['non_null_count'],
                'null_count': stats['total_count'] - stats['non_null_count'],
                'null_percentage': ((stats['total_count'] - stats['non_null_count']) / stats['total_count'] * 100) if stats['total_count'] > 0 else 0,
                'unique_count': stats['unique_count'],
                'uniqueness_ratio': stats['unique_count'] / stats['non_null_count'] if stats['non_null_count'] > 0 else 0
            }
            
            profile['columns'][col_name] = col_profile
        
        return profile
    
    def create_quality_dashboard(self, assessment_results):
        """Create data quality visualization dashboard"""
        
        print("🎨 Creating data quality dashboard...")
        
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        fig.suptitle('Data Quality Assessment Dashboard', fontsize=16, fontweight='bold')
        
        # 1. Completeness scores by table
        ax1 = axes[0, 0]
        table_names = list(assessment_results.keys())
        completeness_scores = [results['completeness']['completeness_score'] for results in assessment_results.values()]
        
        bars = ax1.bar(range(len(table_names)), completeness_scores, color='lightblue')
        ax1.set_xticks(range(len(table_names)))
        ax1.set_xticklabels(table_names, rotation=45, ha='right')
        ax1.set_ylabel('Completeness Score (%)')
        ax1.set_title('Data Completeness by Table')
        ax1.set_ylim(0, 100)
        
        # Add score labels on bars
        for bar, score in zip(bars, completeness_scores):
            ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                    f'{score:.1f}%', ha='center', va='bottom')
        
        # 2. Issue count by table
        ax2 = axes[0, 1]
        issue_counts = []
        for results in assessment_results.values():
            total_issues = (len(results['completeness']['issues']) + 
                          len(results['business_rules']) + 
                          len(results['referential_integrity']))
            issue_counts.append(total_issues)
        
        ax2.bar(range(len(table_names)), issue_counts, color='lightcoral')
        ax2.set_xticks(range(len(table_names)))
        ax2.set_xticklabels(table_names, rotation=45, ha='right')
        ax2.set_ylabel('Number of Issues')
        ax2.set_title('Data Quality Issues by Table')
        
        # 3. Row count by table
        ax3 = axes[0, 2]
        row_counts = [results['profile']['row_count'] for results in assessment_results.values()]
        ax3.bar(range(len(table_names)), row_counts, color='lightgreen')
        ax3.set_xticks(range(len(table_names)))
        ax3.set_xticklabels(table_names, rotation=45, ha='right')
        ax3.set_ylabel('Row Count')
        ax3.set_title('Table Row Counts')
        
        # 4. Overall quality score distribution
        ax4 = axes[1, 0]
        ax4.hist(completeness_scores, bins=10, edgecolor='black', alpha=0.7, color='skyblue')
        ax4.set_xlabel('Completeness Score (%)')
        ax4.set_ylabel('Number of Tables')
        ax4.set_title('Quality Score Distribution')
        
        # 5. Issue type breakdown
        ax5 = axes[1, 1]
        issue_types = ['Completeness', 'Business Rules', 'Referential Integrity']
        issue_type_counts = []
        
        for issue_type in issue_types:
            count = 0
            for results in assessment_results.values():
                if issue_type == 'Completeness':
                    count += len(results['completeness']['issues'])
                elif issue_type == 'Business Rules':
                    count += len(results['business_rules'])
                elif issue_type == 'Referential Integrity':
                    count += len(results['referential_integrity'])
            issue_type_counts.append(count)
        
        ax5.pie(issue_type_counts, labels=issue_types, autopct='%1.1f%%', startangle=90)
        ax5.set_title('Issue Types Distribution')
        
        # 6. Quality summary table
        ax6 = axes[1, 2]
        ax6.axis('off')
        
        # Create summary statistics
        total_tables = len(assessment_results)
        avg_completeness = np.mean(completeness_scores)
        total_issues = sum(issue_counts)
        total_rows = sum(row_counts)
        
        summary_data = [
            ['Total Tables', f'{total_tables}'],
            ['Average Completeness', f'{avg_completeness:.1f}%'],
            ['Total Issues Found', f'{total_issues}'],
            ['Total Rows Assessed', f'{total_rows:,}'],
            ['Assessment Date', self.assessment_date.strftime('%Y-%m-%d %H:%M')]
        ]
        
        table = ax6.table(cellText=summary_data,
                         colLabels=['Metric', 'Value'],
                         cellLoc='left',
                         loc='center',
                         bbox=[0, 0, 1, 1])
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        ax6.set_title('Assessment Summary', fontsize=12, fontweight='bold', pad=20)
        
        plt.tight_layout()
        return fig
    
    def run_complete_assessment(self, tables=None):
        """Run complete data quality assessment"""
        
        print("🚀 Starting Complete Data Quality Assessment")
        print("=" * 60)
        
        if tables is None:
            tables = self.get_table_list()
        
        if not tables:
            print("❌ No tables found or specified")
            return {}
        
        assessment_results = {}
        
        for table in tables:
            print(f"\n📋 Assessing table: {table}")
            
            try:
                # Run all assessments
                completeness = self.assess_table_completeness(table)
                consistency = self.assess_data_consistency(table)
                business_rules = self.assess_business_rules(table)
                referential_integrity = self.check_referential_integrity(table)
                profile = self.generate_data_profile(table)
                
                assessment_results[table] = {
                    'completeness': completeness,
                    'consistency': consistency,
                    'business_rules': business_rules,
                    'referential_integrity': referential_integrity,
                    'profile': profile
                }
                
                print(f"   ✅ Assessment complete - Score: {completeness['completeness_score']:.1f}%")
                
            except Exception as e:
                print(f"   ❌ Error assessing {table}: {str(e)}")
                assessment_results[table] = {
                    'error': str(e)
                }
        
        # Create visualization
        dashboard_fig = self.create_quality_dashboard(assessment_results)
        
        print(f"\n✅ Data Quality Assessment Complete!")
        print(f"📊 Assessed {len(assessment_results)} tables")
        
        # Store results
        self.quality_report = assessment_results
        
        return {
            'results': assessment_results,
            'dashboard': dashboard_fig,
            'summary': self._generate_executive_summary(assessment_results)
        }
    
    def _generate_executive_summary(self, assessment_results):
        """Generate executive summary of data quality"""
        
        completeness_scores = []
        total_issues = 0
        total_rows = 0
        
        for table, results in assessment_results.items():
            if 'error' not in results:
                completeness_scores.append(results['completeness']['completeness_score'])
                total_issues += (len(results['completeness']['issues']) + 
                               len(results['business_rules']) + 
                               len(results['referential_integrity']))
                total_rows += results['profile']['row_count']
        
        summary = {
            'total_tables': len(assessment_results),
            'average_completeness': np.mean(completeness_scores) if completeness_scores else 0,
            'total_issues': total_issues,
            'total_rows': total_rows,
            'assessment_date': self.assessment_date,
            'recommendations': []
        }
        
        # Generate recommendations
        if summary['average_completeness'] < 80:
            summary['recommendations'].append("Data completeness is below 80% - investigate missing data patterns")
        
        if total_issues > len(assessment_results) * 5:
            summary['recommendations'].append("High number of data quality issues detected - prioritize data cleansing")
        
        if not summary['recommendations']:
            summary['recommendations'].append("Data quality appears good - maintain current data governance practices")
        
        return summary

# Example usage
if __name__ == "__main__":
    print("🎯 Automated Data Quality Assessment")
    print("=" * 50)
    
    print("📝 This assessment includes:")
    print("   - Data completeness analysis (null values, missing data)")
    print("   - Data consistency checks (formats, patterns)")
    print("   - Business rule validation (dates, emails, amounts)")
    print("   - Referential integrity checks")
    print("   - Comprehensive data profiling")
    print("   - Visual quality dashboard")
    print("")
    print("🔧 To use this assessment:")
    print("1. Connect to your database")
    print("2. Run: assessor = DataQualityAssessment(connection)")
    print("3. Execute: results = assessor.run_complete_assessment()")
    print("4. Save: results['dashboard'].savefig('data_quality_report.png', dpi=300)")
    print("")
    print("💡 Pro tip: Run regularly to monitor data quality trends!")
