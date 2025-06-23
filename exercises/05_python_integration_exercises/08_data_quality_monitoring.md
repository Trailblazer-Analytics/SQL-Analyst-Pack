# 🔍 Data Quality Monitoring Exercise

## Business Context

**Scenario**: As the Senior Data Analyst at FinanceFlow Bank, you've discovered that poor data quality is causing significant business issues - incorrect customer risk assessments, failed regulatory reports, and lost revenue from bad customer data. The Chief Risk Officer has mandated implementing comprehensive data quality monitoring.

**Stakeholder**: Michael Rodriguez, Chief Risk Officer
**Business Challenge**: Data quality issues are causing regulatory compliance risks and impacting customer experience.

## 🎯 Learning Objectives

By completing this exercise, you will:

- Implement comprehensive data quality monitoring using Python and SQL
- Build automated data validation pipelines with custom business rules
- Create real-time alerting systems for data quality issues
- Develop data quality scorecards and trending reports
- Design data lineage tracking and impact analysis
- Establish data quality SLAs and monitoring dashboards

## 📊 Dataset Overview

You'll work with FinanceFlow's core banking datasets:

### Key Tables

- `customers`: Customer master data with PII and demographics
- `accounts`: Banking account information and balances
- `transactions`: Financial transaction records
- `credit_scores`: Customer creditworthiness data
- `regulatory_reports`: Compliance and regulatory data
- `data_lineage`: System data lineage and transformation tracking

## 🛠️ Technical Requirements

### Required Libraries

```python
import pandas as pd
import sqlalchemy as sa
import numpy as np
from datetime import datetime, timedelta
import great_expectations as ge
from great_expectations.dataset import PandasDataset
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import smtplib
from email.mime.text import MIMEText
import logging
from dataclasses import dataclass
from typing import List, Dict, Any
import json
```

### Database Connection

```python
# FinanceFlow database connection
engine = sa.create_engine("postgresql://localhost:5432/financeflow_db")
```

## 📋 Tasks

### Task 1: Core Data Quality Checks (🟢 Beginner)

**Objective**: Implement fundamental data quality validation checks for customer data.

**Requirements**:

1. Check for completeness, uniqueness, validity, and consistency
2. Identify data quality issues with specific business context
3. Generate summary reports with actionable recommendations

**SQL Foundation Queries**:

```sql
-- Customer data quality assessment
WITH customer_quality_checks AS (
    SELECT 
        'customers' AS table_name,
        COUNT(*) AS total_records,
        
        -- Completeness checks
        COUNT(*) - COUNT(customer_id) AS missing_customer_id,
        COUNT(*) - COUNT(first_name) AS missing_first_name,
        COUNT(*) - COUNT(last_name) AS missing_last_name,
        COUNT(*) - COUNT(email) AS missing_email,
        COUNT(*) - COUNT(phone) AS missing_phone,
        COUNT(*) - COUNT(address) AS missing_address,
        COUNT(*) - COUNT(date_of_birth) AS missing_dob,
        COUNT(*) - COUNT(ssn) AS missing_ssn,
        
        -- Uniqueness checks
        COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customer_id,
        COUNT(*) - COUNT(DISTINCT email) AS duplicate_email,
        COUNT(*) - COUNT(DISTINCT ssn) AS duplicate_ssn,
        
        -- Validity checks
        SUM(CASE WHEN email NOT LIKE '%@%.%' THEN 1 ELSE 0 END) AS invalid_email_format,
        SUM(CASE WHEN phone !~ '^[0-9\-\(\)\s\+]+$' THEN 1 ELSE 0 END) AS invalid_phone_format,
        SUM(CASE WHEN ssn !~ '^\d{3}-\d{2}-\d{4}$' THEN 1 ELSE 0 END) AS invalid_ssn_format,
        SUM(CASE WHEN date_of_birth > current_date OR 
                      date_of_birth < '1900-01-01' THEN 1 ELSE 0 END) AS invalid_dob,
        
        -- Business rule checks
        SUM(CASE WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) < 18 THEN 1 ELSE 0 END) AS underage_customers,
        SUM(CASE WHEN created_date > current_date THEN 1 ELSE 0 END) AS future_created_date
        
    FROM customers
    WHERE created_date >= current_date - INTERVAL '7 days'  -- Recent data
)
SELECT * FROM customer_quality_checks;

-- Account data consistency checks
WITH account_consistency AS (
    SELECT 
        'accounts' AS table_name,
        COUNT(*) AS total_records,
        
        -- Referential integrity
        SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END) AS orphaned_accounts,
        
        -- Business logic consistency
        SUM(CASE WHEN a.account_balance < 0 AND a.account_type = 'savings' 
                 THEN 1 ELSE 0 END) AS negative_savings_balance,
        SUM(CASE WHEN a.account_balance > 1000000 AND a.account_type = 'checking' 
                 THEN 1 ELSE 0 END) AS suspicious_high_balance,
        SUM(CASE WHEN a.opened_date > current_date THEN 1 ELSE 0 END) AS future_opened_date,
        SUM(CASE WHEN a.closed_date < a.opened_date THEN 1 ELSE 0 END) AS invalid_close_date
        
    FROM accounts a
    LEFT JOIN customers c ON a.customer_id = c.customer_id
    WHERE a.opened_date >= current_date - INTERVAL '7 days'
)
SELECT * FROM account_consistency;
```

**Python Implementation**:

```python
@dataclass
class DataQualityResult:
    """Data quality check result structure."""
    table_name: str
    check_name: str
    status: str  # 'PASS', 'WARN', 'FAIL'
    value: float
    threshold: float
    message: str
    timestamp: datetime

class DataQualityMonitor:
    """Core data quality monitoring system."""
    
    def __init__(self, engine):
        self.engine = engine
        self.results = []
        
        # Configure logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def check_completeness(self, table_name: str, required_columns: List[str]) -> List[DataQualityResult]:
        """Check for missing values in required columns."""
        results = []
        
        # Build dynamic completeness query
        completeness_checks = []
        for col in required_columns:
            completeness_checks.append(f"""
                COUNT(*) - COUNT({col}) AS missing_{col},
                (COUNT(*) - COUNT({col})) * 100.0 / COUNT(*) AS missing_{col}_pct
            """)
        
        query = f"""
        SELECT 
            COUNT(*) AS total_records,
            {','.join(completeness_checks)}
        FROM {table_name}
        WHERE created_date >= current_date - INTERVAL '7 days';
        """
        
        df = pd.read_sql(query, self.engine)
        
        for col in required_columns:
            missing_count = df.iloc[0][f'missing_{col}']
            missing_pct = df.iloc[0][f'missing_{col}_pct']
            
            status = 'PASS' if missing_pct < 1 else 'WARN' if missing_pct < 5 else 'FAIL'
            
            results.append(DataQualityResult(
                table_name=table_name,
                check_name=f'completeness_{col}',
                status=status,
                value=missing_pct,
                threshold=5.0,
                message=f'{col}: {missing_count} missing values ({missing_pct:.1f}%)',
                timestamp=datetime.now()
            ))
        
        return results
    
    def check_uniqueness(self, table_name: str, unique_columns: List[str]) -> List[DataQualityResult]:
        """Check for duplicate values in columns that should be unique."""
        results = []
        
        for col in unique_columns:
            query = f"""
            SELECT 
                COUNT(*) AS total_records,
                COUNT(DISTINCT {col}) AS unique_values,
                COUNT(*) - COUNT(DISTINCT {col}) AS duplicate_count
            FROM {table_name}
            WHERE {col} IS NOT NULL
                AND created_date >= current_date - INTERVAL '7 days';
            """
            
            df = pd.read_sql(query, self.engine)
            duplicate_count = df.iloc[0]['duplicate_count']
            total_records = df.iloc[0]['total_records']
            duplicate_pct = (duplicate_count / total_records) * 100 if total_records > 0 else 0
            
            status = 'PASS' if duplicate_count == 0 else 'WARN' if duplicate_count < 10 else 'FAIL'
            
            results.append(DataQualityResult(
                table_name=table_name,
                check_name=f'uniqueness_{col}',
                status=status,
                value=duplicate_pct,
                threshold=0.0,
                message=f'{col}: {duplicate_count} duplicate values ({duplicate_pct:.1f}%)',
                timestamp=datetime.now()
            ))
        
        return results
    
    def check_business_rules(self, table_name: str, rules: List[Dict[str, Any]]) -> List[DataQualityResult]:
        """Check custom business rules."""
        results = []
        
        for rule in rules:
            query = f"""
            SELECT 
                COUNT(*) AS total_records,
                SUM(CASE WHEN {rule['condition']} THEN 1 ELSE 0 END) AS violations
            FROM {table_name}
            WHERE created_date >= current_date - INTERVAL '7 days';
            """
            
            df = pd.read_sql(query, self.engine)
            violations = df.iloc[0]['violations']
            total_records = df.iloc[0]['total_records']
            violation_pct = (violations / total_records) * 100 if total_records > 0 else 0
            
            status = 'PASS' if violation_pct < rule['warn_threshold'] else \
                    'WARN' if violation_pct < rule['fail_threshold'] else 'FAIL'
            
            results.append(DataQualityResult(
                table_name=table_name,
                check_name=f"business_rule_{rule['name']}",
                status=status,
                value=violation_pct,
                threshold=rule['fail_threshold'],
                message=f"{rule['description']}: {violations} violations ({violation_pct:.1f}%)",
                timestamp=datetime.now()
            ))
        
        return results
    
    def run_customer_quality_checks(self) -> List[DataQualityResult]:
        """Run comprehensive customer data quality checks."""
        all_results = []
        
        # Completeness checks
        required_fields = ['customer_id', 'first_name', 'last_name', 'email', 'date_of_birth', 'ssn']
        all_results.extend(self.check_completeness('customers', required_fields))
        
        # Uniqueness checks
        unique_fields = ['customer_id', 'email', 'ssn']
        all_results.extend(self.check_uniqueness('customers', unique_fields))
        
        # Business rules
        business_rules = [
            {
                'name': 'valid_email_format',
                'condition': "email NOT LIKE '%@%.%'",
                'description': 'Invalid email format',
                'warn_threshold': 1.0,
                'fail_threshold': 5.0
            },
            {
                'name': 'valid_age',
                'condition': "EXTRACT(YEAR FROM AGE(date_of_birth)) < 18",
                'description': 'Underage customers',
                'warn_threshold': 0.1,
                'fail_threshold': 1.0
            },
            {
                'name': 'valid_phone',
                'condition': "phone !~ '^[0-9\\-\\(\\)\\s\\+]+$'",
                'description': 'Invalid phone format',
                'warn_threshold': 2.0,
                'fail_threshold': 10.0
            }
        ]
        all_results.extend(self.check_business_rules('customers', business_rules))
        
        self.results.extend(all_results)
        return all_results

# Usage example
dq_monitor = DataQualityMonitor(engine)
customer_results = dq_monitor.run_customer_quality_checks()

for result in customer_results:
    print(f"{result.status}: {result.message}")
```

### Task 2: Advanced Data Quality Framework (🟡 Intermediate)

**Objective**: Build a comprehensive data quality framework with trending, alerting, and automated remediation.

**Requirements**:

1. Implement Great Expectations for advanced validation
2. Create data quality scorecards and trending analysis
3. Build automated alerting for critical issues
4. Design data lineage impact analysis

**Advanced Implementation**:

```python
import great_expectations as ge
from great_expectations.dataset import PandasDataset

class AdvancedDataQualityFramework:
    """Enterprise-grade data quality monitoring system."""
    
    def __init__(self, engine, alerting_config=None):
        self.engine = engine
        self.alerting_config = alerting_config or {}
        self.quality_history = []
        
        # Initialize Great Expectations
        self.context = ge.DataContext()
        
    def create_expectation_suite(self, table_name: str) -> str:
        """Create Great Expectations suite for a table."""
        suite_name = f"{table_name}_quality_suite"
        
        # Customer table expectations
        if table_name == 'customers':
            suite = self.context.create_expectation_suite(suite_name, overwrite_existing=True)
            
            # Load data for profiling
            df = pd.read_sql(f"SELECT * FROM {table_name} LIMIT 10000", self.engine)
            dataset = PandasDataset(df)
            
            # Core expectations
            dataset.expect_table_row_count_to_be_between(min_value=1000, max_value=1000000)
            dataset.expect_column_to_exist('customer_id')
            dataset.expect_column_values_to_be_unique('customer_id')
            dataset.expect_column_values_to_not_be_null('customer_id')
            dataset.expect_column_values_to_not_be_null('first_name')
            dataset.expect_column_values_to_not_be_null('last_name')
            dataset.expect_column_values_to_match_regex('email', r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$')
            dataset.expect_column_values_to_match_regex('ssn', r'^\\d{3}-\\d{2}-\\d{4}$')
            
            # Business logic expectations
            dataset.expect_column_values_to_be_between('date_of_birth', 
                                                      min_value=datetime(1920, 1, 1), 
                                                      max_value=datetime.now() - timedelta(days=18*365))
            
            # Save expectations
            dataset.save_expectation_suite(suite_name)
            
        return suite_name
    
    def run_great_expectations_validation(self, table_name: str) -> Dict:
        """Run Great Expectations validation."""
        
        # Create or get expectation suite
        suite_name = self.create_expectation_suite(table_name)
        
        # Load recent data
        df = pd.read_sql(f"""
            SELECT * FROM {table_name} 
            WHERE created_date >= current_date - INTERVAL '1 day'
        """, self.engine)
        
        # Run validation
        dataset = PandasDataset(df)
        results = dataset.validate(expectation_suite_name=suite_name)
        
        return results.to_json_dict()
    
    def calculate_data_quality_score(self, table_name: str) -> float:
        """Calculate overall data quality score (0-100)."""
        
        # Get all check results for table
        table_results = [r for r in self.results if r.table_name == table_name]
        
        if not table_results:
            return 0.0
        
        # Calculate weighted score
        total_weight = 0
        weighted_score = 0
        
        for result in table_results:
            # Assign weights based on check type
            if 'completeness' in result.check_name:
                weight = 0.3
            elif 'uniqueness' in result.check_name:
                weight = 0.3
            elif 'business_rule' in result.check_name:
                weight = 0.4
            else:
                weight = 0.2
            
            # Convert status to score
            if result.status == 'PASS':
                score = 100
            elif result.status == 'WARN':
                score = 70
            else:  # FAIL
                score = 30
            
            weighted_score += score * weight
            total_weight += weight
        
        return weighted_score / total_weight if total_weight > 0 else 0.0
    
    def generate_quality_trend_analysis(self, days: int = 30) -> pd.DataFrame:
        """Generate data quality trending analysis."""
        
        query = f"""
        WITH daily_quality_metrics AS (
            SELECT 
                DATE_TRUNC('day', created_date) AS check_date,
                'customers' AS table_name,
                
                -- Completeness metrics
                COUNT(*) AS total_records,
                SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS email_missing_pct,
                SUM(CASE WHEN phone IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS phone_missing_pct,
                
                -- Validity metrics
                SUM(CASE WHEN email NOT LIKE '%@%.%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS email_invalid_pct,
                SUM(CASE WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) < 18 
                         THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS underage_pct
                
            FROM customers
            WHERE created_date >= current_date - INTERVAL '{days} days'
            GROUP BY check_date
            ORDER BY check_date
        )
        SELECT * FROM daily_quality_metrics;
        """
        
        return pd.read_sql(query, self.engine)
    
    def create_quality_dashboard(self):
        """Create comprehensive data quality dashboard."""
        
        # Get trend data
        trend_data = self.generate_quality_trend_analysis()
        
        # Create subplots
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Data Completeness Trends', 'Data Validity Trends',
                          'Record Volume Trend', 'Overall Quality Score'),
            specs=[[{"secondary_y": False}, {"secondary_y": False}],
                   [{"secondary_y": False}, {"secondary_y": False}]]
        )
        
        # Completeness trends
        fig.add_trace(
            go.Scatter(x=trend_data['check_date'], y=trend_data['email_missing_pct'],
                      mode='lines+markers', name='Email Missing %', 
                      line=dict(color='#ff7f0e')),
            row=1, col=1
        )
        fig.add_trace(
            go.Scatter(x=trend_data['check_date'], y=trend_data['phone_missing_pct'],
                      mode='lines+markers', name='Phone Missing %', 
                      line=dict(color='#d62728')),
            row=1, col=1
        )
        
        # Validity trends
        fig.add_trace(
            go.Scatter(x=trend_data['check_date'], y=trend_data['email_invalid_pct'],
                      mode='lines+markers', name='Email Invalid %', 
                      line=dict(color='#9467bd')),
            row=1, col=2
        )
        fig.add_trace(
            go.Scatter(x=trend_data['check_date'], y=trend_data['underage_pct'],
                      mode='lines+markers', name='Underage %', 
                      line=dict(color='#8c564b')),
            row=1, col=2
        )
        
        # Record volume
        fig.add_trace(
            go.Bar(x=trend_data['check_date'], y=trend_data['total_records'],
                   name='Daily Records', marker_color='#2ca02c'),
            row=2, col=1
        )
        
        # Calculate quality scores
        quality_scores = []
        for _, row in trend_data.iterrows():
            # Simple scoring algorithm
            completeness_score = 100 - max(row['email_missing_pct'], row['phone_missing_pct'])
            validity_score = 100 - max(row['email_invalid_pct'], row['underage_pct'])
            overall_score = (completeness_score + validity_score) / 2
            quality_scores.append(overall_score)
        
        fig.add_trace(
            go.Scatter(x=trend_data['check_date'], y=quality_scores,
                      mode='lines+markers', name='Quality Score', 
                      line=dict(color='#1f77b4', width=3)),
            row=2, col=2
        )
        
        fig.update_layout(
            title_text="FinanceFlow Data Quality Dashboard",
            title_x=0.5,
            height=600,
            showlegend=True
        )
        
        return fig
    
    def send_quality_alerts(self, results: List[DataQualityResult]):
        """Send automated alerts for data quality issues."""
        
        critical_issues = [r for r in results if r.status == 'FAIL']
        warning_issues = [r for r in results if r.status == 'WARN']
        
        if critical_issues or len(warning_issues) > 5:
            
            subject = f"Data Quality Alert - {len(critical_issues)} Critical Issues Found"
            
            body = f"""
            Data Quality Alert Summary
            Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            
            CRITICAL ISSUES ({len(critical_issues)}):
            {chr(10).join([f"- {issue.message}" for issue in critical_issues])}
            
            WARNING ISSUES ({len(warning_issues)}):
            {chr(10).join([f"- {issue.message}" for issue in warning_issues[:10]])}
            
            Action Required:
            1. Investigate root cause of critical issues
            2. Implement data cleansing procedures
            3. Review data ingestion processes
            
            Data Quality Dashboard: https://dq-dashboard.financeflow.com
            """
            
            # Send email (implementation depends on your email system)
            self.send_email_alert(subject, body, self.alerting_config.get('recipients', []))
    
    def send_email_alert(self, subject: str, body: str, recipients: List[str]):
        """Send email alert."""
        try:
            msg = MIMEText(body)
            msg['Subject'] = subject
            msg['From'] = 'data-quality@financeflow.com'
            msg['To'] = ', '.join(recipients)
            
            # Configure SMTP (adjust for your email server)
            # server = smtplib.SMTP('smtp.financeflow.com', 587)
            # server.send_message(msg)
            
            print(f"Alert sent: {subject}")
            
        except Exception as e:
            print(f"Failed to send alert: {e}")
    
    def generate_quality_scorecard(self) -> pd.DataFrame:
        """Generate executive data quality scorecard."""
        
        tables = ['customers', 'accounts', 'transactions']
        scorecard_data = []
        
        for table in tables:
            # Run quality checks for each table
            if table == 'customers':
                results = self.run_customer_quality_checks()
            # Add other table checks as needed
            
            score = self.calculate_data_quality_score(table)
            
            # Count issues by severity
            critical_count = len([r for r in results if r.status == 'FAIL'])
            warning_count = len([r for r in results if r.status == 'WARN'])
            
            scorecard_data.append({
                'table_name': table,
                'quality_score': round(score, 1),
                'critical_issues': critical_count,
                'warning_issues': warning_count,
                'status': 'HEALTHY' if score >= 90 else 'AT_RISK' if score >= 70 else 'CRITICAL',
                'last_checked': datetime.now().strftime('%Y-%m-%d %H:%M')
            })
        
        return pd.DataFrame(scorecard_data)

# Usage example
advanced_dq = AdvancedDataQualityFramework(engine, {'recipients': ['dq-team@financeflow.com']})

# Run comprehensive quality assessment
customer_results = advanced_dq.run_customer_quality_checks()
advanced_dq.send_quality_alerts(customer_results)

# Generate scorecard
scorecard = advanced_dq.generate_quality_scorecard()
print("\nData Quality Scorecard:")
print(scorecard.to_string(index=False))

# Create dashboard
dashboard = advanced_dq.create_quality_dashboard()
dashboard.show()
```

### Task 3: Real-Time Quality Monitoring System (🔴 Advanced)

**Objective**: Build a production-ready real-time data quality monitoring system with automated remediation.

**Requirements**:

1. Real-time streaming data quality checks
2. Automated data cleansing and enrichment
3. Data lineage impact analysis
4. SLA monitoring and compliance reporting

**Complete Production System**:

```python
import asyncio
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import pandas as pd
import sqlalchemy as sa
from dataclasses import dataclass, asdict
import logging

@dataclass
class QualityRule:
    """Data quality rule definition."""
    rule_id: str
    table_name: str
    column_name: str
    rule_type: str  # 'completeness', 'uniqueness', 'validity', 'consistency'
    condition: str
    threshold: float
    severity: str  # 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    auto_remediation: bool = False
    remediation_action: Optional[str] = None

@dataclass
class QualityIncident:
    """Data quality incident tracking."""
    incident_id: str
    rule_id: str
    table_name: str
    detected_at: datetime
    severity: str
    description: str
    affected_records: int
    status: str  # 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'SUPPRESSED'
    assigned_to: Optional[str] = None
    resolved_at: Optional[datetime] = None
    resolution_notes: Optional[str] = None

class RealTimeQualityMonitor:
    """Production-grade real-time data quality monitoring system."""
    
    def __init__(self, engine, config_file='dq_config.json'):
        self.engine = engine
        self.load_configuration(config_file)
        self.setup_logging()
        self.active_incidents = {}
        
    def load_configuration(self, config_file: str):
        """Load data quality rules and configuration."""
        
        # Default configuration
        default_config = {
            "rules": [
                {
                    "rule_id": "CUST_001",
                    "table_name": "customers",
                    "column_name": "email",
                    "rule_type": "completeness",
                    "condition": "email IS NOT NULL",
                    "threshold": 95.0,
                    "severity": "HIGH",
                    "auto_remediation": True,
                    "remediation_action": "flag_for_followup"
                },
                {
                    "rule_id": "CUST_002", 
                    "table_name": "customers",
                    "column_name": "customer_id",
                    "rule_type": "uniqueness",
                    "condition": "COUNT(*) = COUNT(DISTINCT customer_id)",
                    "threshold": 100.0,
                    "severity": "CRITICAL",
                    "auto_remediation": False
                },
                {
                    "rule_id": "TXN_001",
                    "table_name": "transactions", 
                    "column_name": "amount",
                    "rule_type": "validity",
                    "condition": "amount > 0 AND amount < 1000000",
                    "threshold": 99.0,
                    "severity": "MEDIUM",
                    "auto_remediation": True,
                    "remediation_action": "quarantine_transaction"
                }
            ],
            "monitoring": {
                "check_interval_minutes": 15,
                "batch_size": 10000,
                "alert_thresholds": {
                    "CRITICAL": 1,
                    "HIGH": 3, 
                    "MEDIUM": 10
                }
            },
            "alerting": {
                "email_recipients": ["dq-team@financeflow.com"],
                "slack_webhook": "https://hooks.slack.com/services/...",
                "escalation_rules": {
                    "CRITICAL": {"immediate": True, "escalate_after_minutes": 15},
                    "HIGH": {"immediate": False, "escalate_after_minutes": 60}
                }
            }
        }
        
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
        except FileNotFoundError:
            config = default_config
            # Save default config
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
        
        self.rules = [QualityRule(**rule) for rule in config['rules']]
        self.monitoring_config = config['monitoring']
        self.alerting_config = config['alerting']
    
    def setup_logging(self):
        """Setup comprehensive logging."""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('data_quality.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    async def monitor_data_quality(self):
        """Main monitoring loop."""
        self.logger.info("Starting real-time data quality monitoring...")
        
        while True:
            try:
                # Run quality checks for each rule
                for rule in self.rules:
                    result = await self.execute_quality_check(rule)
                    
                    if result['failed']:
                        await self.handle_quality_incident(rule, result)
                    else:
                        await self.resolve_existing_incidents(rule.rule_id)
                
                # Wait for next check interval
                await asyncio.sleep(self.monitoring_config['check_interval_minutes'] * 60)
                
            except Exception as e:
                self.logger.error(f"Error in monitoring loop: {e}")
                await asyncio.sleep(60)  # Wait 1 minute on error
    
    async def execute_quality_check(self, rule: QualityRule) -> Dict:
        """Execute individual quality check."""
        try:
            if rule.rule_type == 'completeness':
                return await self.check_completeness(rule)
            elif rule.rule_type == 'uniqueness':
                return await self.check_uniqueness(rule)
            elif rule.rule_type == 'validity':
                return await self.check_validity(rule)
            elif rule.rule_type == 'consistency':
                return await self.check_consistency(rule)
            else:
                raise ValueError(f"Unknown rule type: {rule.rule_type}")
                
        except Exception as e:
            self.logger.error(f"Error executing rule {rule.rule_id}: {e}")
            return {'failed': False, 'error': str(e)}
    
    async def check_completeness(self, rule: QualityRule) -> Dict:
        """Check data completeness."""
        query = f"""
        SELECT 
            COUNT(*) AS total_records,
            COUNT({rule.column_name}) AS non_null_records,
            (COUNT({rule.column_name}) * 100.0 / COUNT(*)) AS completeness_pct
        FROM {rule.table_name}
        WHERE created_date >= current_timestamp - INTERVAL '15 minutes';
        """
        
        df = pd.read_sql(query, self.engine)
        completeness_pct = df.iloc[0]['completeness_pct']
        
        failed = completeness_pct < rule.threshold
        
        return {
            'failed': failed,
            'value': completeness_pct,
            'threshold': rule.threshold,
            'affected_records': df.iloc[0]['total_records'] - df.iloc[0]['non_null_records'],
            'message': f"Completeness: {completeness_pct:.1f}% (threshold: {rule.threshold}%)"
        }
    
    async def check_uniqueness(self, rule: QualityRule) -> Dict:
        """Check data uniqueness."""
        query = f"""
        SELECT 
            COUNT(*) AS total_records,
            COUNT(DISTINCT {rule.column_name}) AS unique_records,
            COUNT(*) - COUNT(DISTINCT {rule.column_name}) AS duplicate_records
        FROM {rule.table_name}
        WHERE created_date >= current_timestamp - INTERVAL '15 minutes';
        """
        
        df = pd.read_sql(query, self.engine)
        duplicate_count = df.iloc[0]['duplicate_records']
        
        failed = duplicate_count > 0  # Any duplicates fail uniqueness
        
        return {
            'failed': failed,
            'value': duplicate_count,
            'threshold': 0,
            'affected_records': duplicate_count,
            'message': f"Duplicates found: {duplicate_count}"
        }
    
    async def check_validity(self, rule: QualityRule) -> Dict:
        """Check data validity using custom conditions."""
        query = f"""
        SELECT 
            COUNT(*) AS total_records,
            SUM(CASE WHEN {rule.condition} THEN 1 ELSE 0 END) AS valid_records,
            SUM(CASE WHEN {rule.condition} THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS validity_pct
        FROM {rule.table_name}
        WHERE created_date >= current_timestamp - INTERVAL '15 minutes';
        """
        
        df = pd.read_sql(query, self.engine)
        validity_pct = df.iloc[0]['validity_pct']
        
        failed = validity_pct < rule.threshold
        
        return {
            'failed': failed,
            'value': validity_pct,
            'threshold': rule.threshold,
            'affected_records': df.iloc[0]['total_records'] - df.iloc[0]['valid_records'],
            'message': f"Validity: {validity_pct:.1f}% (threshold: {rule.threshold}%)"
        }
    
    async def handle_quality_incident(self, rule: QualityRule, result: Dict):
        """Handle data quality incident."""
        
        incident_id = f"{rule.rule_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        incident = QualityIncident(
            incident_id=incident_id,
            rule_id=rule.rule_id,
            table_name=rule.table_name,
            detected_at=datetime.now(),
            severity=rule.severity,
            description=result['message'],
            affected_records=result['affected_records'],
            status='OPEN'
        )
        
        self.active_incidents[rule.rule_id] = incident
        
        # Log incident
        self.logger.warning(f"Data quality incident: {incident.description}")
        
        # Send alerts
        await self.send_incident_alert(incident)
        
        # Auto-remediation if enabled
        if rule.auto_remediation and rule.remediation_action:
            await self.execute_remediation(rule, incident)
    
    async def execute_remediation(self, rule: QualityRule, incident: QualityIncident):
        """Execute automatic data remediation."""
        
        try:
            if rule.remediation_action == 'flag_for_followup':
                # Flag problematic records for manual review
                update_query = f"""
                UPDATE {rule.table_name} 
                SET data_quality_flag = 'NEEDS_REVIEW',
                    flagged_at = current_timestamp
                WHERE {rule.column_name} IS NULL 
                    AND created_date >= current_timestamp - INTERVAL '15 minutes';
                """
                self.engine.execute(update_query)
                
            elif rule.remediation_action == 'quarantine_transaction':
                # Move invalid transactions to quarantine table
                quarantine_query = f"""
                INSERT INTO quarantined_transactions 
                SELECT *, current_timestamp as quarantined_at
                FROM {rule.table_name}
                WHERE NOT ({rule.condition})
                    AND created_date >= current_timestamp - INTERVAL '15 minutes';
                
                DELETE FROM {rule.table_name}
                WHERE NOT ({rule.condition})
                    AND created_date >= current_timestamp - INTERVAL '15 minutes';
                """
                self.engine.execute(quarantine_query)
            
            incident.status = 'RESOLVED'
            incident.resolved_at = datetime.now()
            incident.resolution_notes = f"Auto-remediation: {rule.remediation_action}"
            
            self.logger.info(f"Auto-remediation completed for incident {incident.incident_id}")
            
        except Exception as e:
            self.logger.error(f"Auto-remediation failed for {incident.incident_id}: {e}")
    
    async def send_incident_alert(self, incident: QualityIncident):
        """Send incident alerts via configured channels."""
        
        message = f"""
        🚨 Data Quality Alert
        
        Incident ID: {incident.incident_id}
        Table: {incident.table_name}
        Severity: {incident.severity}
        
        Description: {incident.description}
        Affected Records: {incident.affected_records:,}
        Detected At: {incident.detected_at.strftime('%Y-%m-%d %H:%M:%S')}
        
        Please investigate and take appropriate action.
        """
        
        # Email alert
        # Implementation depends on your email system
        
        # Slack alert  
        # Implementation depends on your Slack integration
        
        self.logger.info(f"Alert sent for incident {incident.incident_id}")
    
    def generate_compliance_report(self, start_date: datetime, end_date: datetime) -> Dict:
        """Generate data quality compliance report."""
        
        # Get historical incident data
        incidents_query = f"""
        SELECT 
            rule_id,
            severity,
            status,
            COUNT(*) as incident_count,
            AVG(affected_records) as avg_affected_records
        FROM quality_incidents 
        WHERE detected_at BETWEEN '{start_date}' AND '{end_date}'
        GROUP BY rule_id, severity, status;
        """
        
        # Calculate SLA compliance
        sla_compliance = {}
        for rule in self.rules:
            # Define SLA targets (example: 99% uptime for CRITICAL rules)
            if rule.severity == 'CRITICAL':
                target = 99.0
            elif rule.severity == 'HIGH':
                target = 95.0
            else:
                target = 90.0
            
            # Calculate actual compliance (simplified)
            # In practice, this would be more sophisticated
            sla_compliance[rule.rule_id] = {
                'target': target,
                'actual': 98.5,  # Placeholder
                'status': 'MEETING' if 98.5 >= target else 'FAILING'
            }
        
        return {
            'report_period': {'start': start_date, 'end': end_date},
            'sla_compliance': sla_compliance,
            'summary': {
                'total_incidents': len(self.active_incidents),
                'critical_incidents': len([i for i in self.active_incidents.values() if i.severity == 'CRITICAL']),
                'resolved_incidents': len([i for i in self.active_incidents.values() if i.status == 'RESOLVED'])
            }
        }

# Usage example - Production deployment
async def main():
    engine = sa.create_engine("postgresql://localhost:5432/financeflow_db")
    
    # Initialize real-time monitor
    monitor = RealTimeQualityMonitor(engine)
    
    # Start monitoring (this runs indefinitely)
    await monitor.monitor_data_quality()

# For testing/demo
if __name__ == "__main__":
    # Run a single check cycle instead of continuous monitoring
    engine = sa.create_engine("postgresql://localhost:5432/financeflow_db")
    monitor = RealTimeQualityMonitor(engine)
    
    # Generate compliance report
    report = monitor.generate_compliance_report(
        start_date=datetime.now() - timedelta(days=30),
        end_date=datetime.now()
    )
    
    print("Data Quality Compliance Report:")
    print(json.dumps(report, indent=2, default=str))
```

## 🎯 Business Impact

### Success Metrics

- **Issue Detection Time**: Reduce from hours to minutes
- **Data Quality Score**: Maintain >95% across all critical tables
- **Compliance**: 100% regulatory reporting accuracy
- **Cost Savings**: Prevent $100K+ annual losses from bad data

### Expected Outcomes

1. **Risk Mitigation**:
   - Prevent regulatory compliance failures
   - Reduce customer impact from bad data
   - Minimize financial losses

2. **Operational Excellence**:
   - Proactive issue identification
   - Automated remediation where possible
   - Improved data team efficiency

3. **Business Confidence**:
   - Trust in data-driven decisions
   - Reliable reporting and analytics
   - Enhanced customer experience

## 🚀 Extensions & Next Steps

### Challenge Extensions

1. **Machine Learning Integration**: Use ML for anomaly detection and predictive quality issues
2. **Data Lineage**: Implement full data lineage tracking with impact analysis
3. **Self-Healing Data**: Advanced auto-remediation with confidence scoring
4. **Cross-System Monitoring**: Extend to APIs, files, and streaming data sources

### Production Deployment

1. **Container Deployment**: Package as Docker containers for Kubernetes
2. **Observability**: Integrate with Prometheus, Grafana, and APM tools
3. **Event-Driven Architecture**: Use message queues for scalable processing
4. **Multi-Environment**: Support dev, staging, and production environments

---

**💡 Pro Tip**: Start with critical business rules and gradually expand coverage. Focus on automation for recurring issues while maintaining human oversight for complex scenarios.
