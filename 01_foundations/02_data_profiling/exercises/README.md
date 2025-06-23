# 📊 Data Profiling Exercises

These exercises will help you practice data profiling techniques and build confidence in exploring new datasets.

---

## 🎯 Exercise Categories

### 🟢 Beginner Exercises (1-5)
**Goal**: Learn basic profiling techniques  
**Database**: Chinook sample database  
**Focus**: Table counts, basic statistics, simple quality checks

### 🟡 Intermediate Exercises (6-10)  
**Goal**: Develop systematic profiling approaches  
**Database**: E-commerce and Financial datasets  
**Focus**: Automated profiling, pattern detection, cross-table analysis

### 🔴 Advanced Exercises (11-15)
**Goal**: Build professional-grade profiling solutions  
**Database**: Multiple databases, real-world scenarios  
**Focus**: Custom profiling frameworks, anomaly detection, reporting

---

## 🟢 Beginner Exercises

### Exercise 1: Database Reconnaissance
**Scenario**: You're a new analyst at Chinook Digital Music. Your manager wants a quick overview of the database.

**Tasks**:
1. List all tables in the database with their row counts
2. Identify the 3 largest tables by number of rows
3. Calculate total rows across all tables
4. Find any empty tables

**Expected Output**: A summary report showing table sizes

**Hint**: Use `INFORMATION_SCHEMA.TABLES` and `COUNT(*)` queries

---

### Exercise 2: Customer Data Profile
**Scenario**: The marketing team needs to understand customer demographics for a new campaign.

**Tasks**:
1. Profile the `Customer` table - count total customers
2. Find countries with the most customers
3. Identify customers with missing information (nulls)
4. Calculate average, min, and max customer ID values

**Expected Skills**: Basic aggregation, GROUP BY, NULL handling

---

### Exercise 3: Invoice Analysis Overview
**Scenario**: Finance team requests a high-level overview of sales data quality.

**Tasks**:
1. Count total invoices and invoice lines
2. Find date range of invoices (earliest and latest)
3. Calculate total revenue across all invoices
4. Identify any invoices with zero or negative amounts

**Expected Learning**: Date analysis, financial data validation

---

### Exercise 4: Product Catalog Health Check
**Scenario**: The inventory team suspects there are data quality issues in the product catalog.

**Tasks**:
1. Profile the `Track` table - count total tracks
2. Find tracks with missing album information
3. Identify the most common track duration patterns
4. List tracks with unusual durations (very short or very long)

**Expected Skills**: Pattern recognition, outlier detection

---

### Exercise 5: Employee Data Audit
**Scenario**: HR needs to audit employee data for completeness and accuracy.

**Tasks**:
1. Count total employees and identify reporting hierarchy
2. Find employees with missing manager information
3. Calculate tenure for each employee (hire date to now)
4. Identify any data inconsistencies in employee records

**Expected Learning**: Hierarchical data analysis, date calculations

---

## 🟡 Intermediate Exercises

### Exercise 6: Automated Table Profiling
**Scenario**: Create a reusable script to profile any table in the database.

**Tasks**:
1. Write a query that profiles multiple tables at once
2. Include row counts, column counts, and null percentages
3. Identify tables with the most/least data quality issues
4. Create a scoring system for table "health"

**Expected Skills**: Dynamic SQL concepts, systematic analysis

---

### Exercise 7: Cross-Table Relationship Analysis  
**Scenario**: Understand data relationships and referential integrity.

**Tasks**:
1. Analyze foreign key relationships in the database
2. Find "orphaned" records (referencing non-existent parents)
3. Calculate relationship cardinalities (1:1, 1:many, many:many)
4. Identify potential missing foreign key constraints

**Expected Learning**: Relational integrity, join analysis

---

### Exercise 8: Time Series Data Profiling
**Scenario**: Analyze sales trends and identify data collection issues.

**Tasks**:
1. Profile invoice dates - find gaps in data collection
2. Calculate sales velocity (orders per day/week/month)
3. Identify seasonal patterns in the data
4. Find anomalous time periods (unusual high/low activity)

**Expected Skills**: Time series analysis, trend detection

---

### Exercise 9: Text Data Quality Assessment
**Scenario**: Assess the quality of text fields across the database.

**Tasks**:
1. Analyze length patterns in text fields (names, addresses)
2. Find duplicate entries with slight variations
3. Identify potential data entry errors (inconsistent formatting)
4. Calculate text field completeness and standardization

**Expected Learning**: String analysis, pattern matching

---

### Exercise 10: Multi-Database Comparison
**Scenario**: Compare data profiles between development and production environments.

**Tasks**:
1. Profile the same tables in different database environments
2. Identify discrepancies in row counts and data distributions
3. Find schema differences between environments
4. Create a comparison report highlighting differences

**Expected Skills**: Environment comparison, change detection

---

## 🔴 Advanced Exercises

### Exercise 11: Statistical Profiling Framework
**Scenario**: Build a comprehensive statistical profiling system.

**Tasks**:
1. Create functions to calculate percentiles, skewness, and kurtosis
2. Build automated outlier detection using statistical methods
3. Generate data distribution histograms for numeric columns
4. Create statistical baselines for monitoring data drift

**Expected Skills**: Advanced statistics, procedure creation

---

### Exercise 12: Data Quality Scoring System
**Scenario**: Develop a enterprise-grade data quality measurement system.

**Tasks**:
1. Define data quality dimensions (completeness, accuracy, consistency)
2. Create scoring algorithms for each dimension
3. Build an overall data quality score for tables/databases
4. Create alerting for quality score degradation

**Expected Learning**: Quality metrics, algorithmic thinking

---

### Exercise 13: Real-Time Data Profiling
**Scenario**: Monitor data quality in a production environment.

**Tasks**:
1. Create incremental profiling for only new/changed data
2. Build alerting for unusual data patterns
3. Create dashboards showing data quality trends over time
4. Implement automated data quality reporting

**Expected Skills**: Incremental processing, monitoring systems

---

### Exercise 14: Industry-Specific Profiling
**Scenario**: Apply profiling techniques to specialized domains.

**Tasks**:
1. Profile financial transaction data for fraud indicators
2. Analyze e-commerce data for customer behavior patterns
3. Profile IoT sensor data for anomaly detection
4. Create domain-specific quality rules and validations

**Expected Learning**: Domain expertise, specialized analysis

---

### Exercise 15: Machine Learning Data Preparation
**Scenario**: Prepare data profiles for machine learning model development.

**Tasks**:
1. Profile features for ML readiness (distribution, missing values)
2. Identify feature engineering opportunities from profiling
3. Create data quality reports for ML model validation
4. Build automated feature profiling pipelines

**Expected Skills**: ML data preparation, feature analysis

---

## 💡 Exercise Tips

### Getting Started
- Start with the Chinook database for exercises 1-5
- Use the provided sample databases for intermediate exercises
- Create your own test data for advanced exercises

### Best Practices
- Document your findings and insights
- Save your queries for reuse
- Time yourself to build proficiency
- Share solutions with peers for learning

### Common Patterns
```sql
-- Basic table profiling template
SELECT 
    'TableName' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT column1) as unique_values,
    COUNT(column1) * 100.0 / COUNT(*) as completeness_pct
FROM table_name;
```

### Success Metrics
- **Beginner**: Complete exercises in 30-45 minutes each
- **Intermediate**: Complete exercises in 60-90 minutes each  
- **Advanced**: Complete exercises in 2-4 hours each

---

## 🎓 Learning Path

**Week 1**: Beginner exercises (1-5) - Focus on basic concepts  
**Week 2**: Intermediate exercises (6-10) - Build systematic approaches  
**Week 3**: Advanced exercises (11-15) - Develop professional skills  
**Week 4**: Create your own profiling challenges using real data

---

## 🔗 Additional Resources

- [SQL Profiling Cheat Sheet](../reference/profiling_cheat_sheet.md)
- [Data Quality Frameworks](../reference/quality_frameworks.md)
- [Sample Database Documentation](../../../sample_database/README.md)

---

*Master these exercises and you'll be profiling data like a pro!* 🎯
