# 📊 Data Profiling Exercises

Practice the four core data profiling skills from this module - the foundation of reliable analysis.

---

## 🎯 Learning Objectives

After completing these exercises, you will master:
- **Table inventory and sizing** - Quick database reconnaissance
- **Column structure analysis** - Schema validation and data types  
- **Data quality assessment** - NULL patterns and completeness
- **Value distribution profiling** - Frequency analysis and outliers

---

## 🛠️ Module Exercise Structure

Each exercise corresponds directly to the SQL files in this module:

| Exercise | SQL File | Focus Area | Time |
|----------|----------|------------|------|
| Exercise 1 | `01_table_overview_and_counts.sql` | Database structure & sizing | 20 min |
| Exercise 2 | `02_column_profiling_and_types.sql` | Schema and data types | 25 min |
| Exercise 3 | `03_data_quality_and_nulls.sql` | Missing values & duplicates | 30 min |
| Exercise 4 | `04_value_distribution_and_frequency.sql` | Statistical distribution | 25 min |Exercises

Master the essential skill of data profiling - understanding your data before you analyze it.

---

## 🎯 Learning Objectives

After completing these exercises, you will:
- **Systematically explore** new datasets with confidence
- **Identify data quality issues** before they impact analysis
- **Create data profiles** that inform business decisions
- **Build reusable profiling queries** for efficiency
- **Communicate data insights** to stakeholders

---

## �️ Module-Specific Exercises

These exercises focus specifically on **data profiling techniques** using the concepts from this module.

---

## 🟢 Exercise 1: Table Overview & Row Counts
*Based on: `01_table_overview_and_counts.sql`*

**Business Scenario**: You're the new data analyst at Chinook Music Store. Before diving into sales analysis, you need to understand the database structure and data volumes.

**Your Tasks**:

1. **Database Inventory**: Create a complete list of all tables with their row counts
2. **Size Assessment**: Identify the 3 largest tables and calculate total records
3. **Empty Table Check**: Find any tables with zero records
4. **Growth Tracking**: Write a query template for monthly size monitoring

**Key Skills**: System catalogs, COUNT(*), metadata queries, database reconnaissance

**Success Criteria**: 
- Generate a table showing: Table Name | Row Count | Percentage of Total
- Identify which tables contain the core business data
- Create reusable monitoring queries

---

## 🟡 Exercise 2: Column Profiling & Data Types  
*Based on: `02_column_profiling_and_types.sql`*

**Business Scenario**: The IT team is planning a data migration. You need to analyze the column structures and validate data types across key tables.

**Your Tasks**:

1. **Schema Analysis**: Profile all columns in Customer, Invoice, and Track tables
2. **Data Type Mapping**: Document column types, lengths, and constraints
3. **Storage Optimization**: Identify oversized text fields and unused precision
4. **Type Validation**: Check for data that doesn't match its declared type

**Key Skills**: INFORMATION_SCHEMA, column metadata, data type analysis, schema validation

**Success Criteria**:
- Create a data dictionary with column specs
- Flag potential storage optimizations  
- Identify data type inconsistencies

---

## 🟢 Exercise 3: Data Quality & NULL Analysis
*Based on: `03_data_quality_and_nulls.sql`*

**Business Scenario**: Before launching a customer email campaign, you need to assess data completeness and quality in the customer database.

**Your Tasks**:

1. **Missing Data Assessment**: Calculate NULL percentages for all Customer columns
2. **Completeness Scoring**: Create overall data quality scores per record
3. **Duplicate Detection**: Find duplicate customers using multiple criteria
4. **Quality Report**: Generate a summary for the marketing team

**Key Skills**: NULL analysis, completeness metrics, duplicate detection, data quality scoring

**Success Criteria**:
- Report showing: Column | NULL Count | NULL % | Data Quality Impact
- Identify customers with insufficient data for campaigns
- Create data quality rules and thresholds

---

## 🟡 Exercise 4: Value Distribution & Frequency Analysis
*Based on: `04_value_distribution_and_frequency.sql`*

**Business Scenario**: The sales team wants to understand customer distribution and purchasing patterns to focus their efforts on the most profitable segments.

**Your Tasks**:

1. **Geographic Distribution**: Analyze customer distribution by country and city
2. **Purchase Patterns**: Profile invoice amounts and frequency distributions  
3. **Product Popularity**: Analyze track and album purchase frequencies
4. **Outlier Detection**: Identify unusual values and potential data errors

**Key Skills**: GROUP BY analysis, frequency distributions, statistical profiling, outlier detection

**Success Criteria**:
- Generate market segment analysis for sales planning
- Identify top customers and products for targeted campaigns
- Flag data anomalies requiring investigation

---

## 💡 Quick Profiling Templates

### Basic Table Profile
```sql
SELECT 
    'table_name' as table_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT primary_key) as unique_records,
    COUNT(column1) as non_null_column1,
    COUNT(*) - COUNT(column1) as null_column1,
    MIN(date_column) as earliest_date,
    MAX(date_column) as latest_date
FROM table_name;
```

### Column Completeness Check
```sql
SELECT 
    SUM(CASE WHEN column1 IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as null_pct_col1,
    SUM(CASE WHEN column2 IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as null_pct_col2
FROM table_name;
```

---

## ⏱️ Time Guidelines

- **Exercise 1**: 20 minutes - Focus on understanding database structure
- **Exercise 2**: 25 minutes - Dive deep into column analysis  
- **Exercise 3**: 30 minutes - Comprehensive data quality assessment
- **Exercise 4**: 25 minutes - Statistical distribution patterns

**Total Module Time**: ~100 minutes of focused practice

---

## 🔗 Next Steps

After mastering data profiling:

- Move to [Data Cleaning](../../03_data_cleaning/) module
- Practice with [Aggregation](../../../02_intermediate/04_aggregation/) techniques
- Apply skills in [Real-World Scenarios](../../../04_real_world/)

---

*Data profiling is the foundation of reliable analysis!* 📊
