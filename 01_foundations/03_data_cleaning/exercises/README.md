# 🧹 Data Cleaning Exercises

Practice systematic data cleaning techniques to build professional-level data quality skills.

---

## 🎯 Exercise Categories

### 🟢 Beginner Exercises (1-5)
**Focus**: Basic cleaning techniques  
**Database**: Chinook sample database  
**Skills**: Simple duplicates, basic missing values, format standardization

### 🟡 Intermediate Exercises (6-10)  
**Focus**: Advanced cleaning strategies  
**Database**: Multiple sample datasets  
**Skills**: Complex duplicates, business rule validation, automation

### 🔴 Advanced Exercises (11-15)
**Focus**: Enterprise-grade solutions  
**Database**: Real-world scenarios  
**Skills**: Quality frameworks, monitoring systems, performance optimization

---

## 🟢 Beginner Exercises

### Exercise 1: Basic Duplicate Detection
**Scenario**: The marketing team suspects duplicate customer records are inflating customer counts.

**Sample Data Issue**: Some customers may have been entered multiple times with slight variations.

**Tasks**:
1. Find exact duplicate customers (same email address)
2. Identify potential duplicates with same name but different email
3. Count how many "true" unique customers exist
4. Create a query to show the duplicate records for manual review

**Expected Skills**: GROUP BY, HAVING, COUNT, basic duplicate detection

**Success Criteria**: Identify at least 3 different types of potential duplicates

---

### Exercise 2: Email Address Standardization
**Scenario**: Customer service reports that email communications are failing due to format issues.

**Common Issues**:
- Mixed case emails (John.Doe@GMAIL.com)
- Extra whitespace (" john@example.com ")
- Invalid characters in email addresses

**Tasks**:
1. Standardize all email addresses to lowercase
2. Remove leading and trailing whitespace
3. Identify obviously invalid email formats (missing @, etc.)
4. Create a "cleaned" email field alongside the original

**Expected Skills**: LOWER, TRIM, string functions, pattern validation

---

### Exercise 3: Phone Number Cleanup
**Scenario**: The sales team needs consistent phone number formatting for their CRM integration.

**Format Issues**:
- Different formats: (555) 123-4567, 555-123-4567, 5551234567
- International vs domestic numbers
- Missing or incomplete numbers

**Tasks**:
1. Standardize all phone numbers to (XXX) XXX-XXXX format
2. Identify international numbers (starting with +)
3. Flag incomplete phone numbers (less than 10 digits)
4. Create separate fields for area code and number

**Expected Skills**: String manipulation, SUBSTRING, pattern replacement

---

### Exercise 4: Missing Contact Information
**Scenario**: Customer outreach campaigns are failing due to missing contact information.

**Tasks**:
1. Identify customers with missing email addresses
2. Find customers with missing phone numbers
3. Calculate the percentage of incomplete contact records
4. Prioritize customers for contact information collection based on purchase history

**Expected Skills**: NULL handling, CASE statements, percentage calculations

---

### Exercise 5: Address Standardization
**Scenario**: Shipping problems due to inconsistent address formatting.

**Address Issues**:
- Inconsistent state abbreviations (CA vs California vs Calif)
- Mixed case addresses (123 main street vs 123 Main Street)
- Missing postal codes

**Tasks**:
1. Standardize state names to official abbreviations
2. Implement proper case formatting for addresses
3. Identify addresses missing postal codes
4. Validate postal code formats for different countries

**Expected Skills**: String functions, CASE statements, reference data validation

---

## 🟡 Intermediate Exercises

### Exercise 6: Advanced Duplicate Resolution
**Scenario**: Merge duplicate customer accounts while preserving all purchase history.

**Complex Challenge**: Some customers have multiple accounts with different information that all needs to be preserved.

**Tasks**:
1. Develop a scoring system to identify the "best" record among duplicates
2. Create a merge strategy that preserves all purchase history
3. Handle conflicting information (different addresses, phone numbers)
4. Generate a report showing what was merged and why

**Expected Skills**: Window functions, complex joins, data lineage tracking

---

### Exercise 7: Business Rule Validation
**Scenario**: Implement automated validation rules for financial data integrity.

**Business Rules**:
- Invoice totals must equal sum of line items
- Dates must be logical (invoice date before ship date)
- Quantities and prices must be positive
- Customer must exist before invoice creation

**Tasks**:
1. Create validation queries for each business rule
2. Identify violations and quantify impact
3. Develop correction strategies for each violation type
4. Build an automated validation framework

**Expected Skills**: Complex validation logic, aggregation validation, referential integrity

---

### Exercise 8: Time Series Data Cleaning
**Scenario**: Clean sales data for accurate trend analysis.

**Data Issues**:
- Missing sales days (gaps in time series)
- Duplicate entries for same day
- Backdated transactions entered incorrectly
- Seasonal outliers that may be data errors

**Tasks**:
1. Identify gaps in daily sales data
2. Detect and resolve duplicate daily entries
3. Flag suspicious date anomalies
4. Create a clean, continuous time series dataset

**Expected Skills**: Date/time functions, gap detection, outlier identification

---

### Exercise 9: Product Catalog Cleanup
**Scenario**: Standardize product information for better searchability and reporting.

**Catalog Issues**:
- Inconsistent product names and descriptions
- Missing genre classifications
- Duplicate tracks with slight title variations
- Inconsistent artist name spellings

**Tasks**:
1. Standardize product naming conventions
2. Fill in missing genre information using pattern matching
3. Identify and merge near-duplicate products
4. Standardize artist names across the catalog

**Expected Skills**: Text processing, pattern matching, categorical data cleaning

---

### Exercise 10: Multi-Table Data Consistency
**Scenario**: Ensure referential integrity across related tables.

**Consistency Issues**:
- Orphaned records (invoices without customers)
- Missing lookup values (genres not in genre table)
- Inconsistent foreign key relationships
- Data type mismatches between related tables

**Tasks**:
1. Identify all referential integrity violations
2. Develop cleanup strategies for each type of violation
3. Create constraints to prevent future violations
4. Build monitoring queries for ongoing data quality

**Expected Skills**: Multi-table analysis, referential integrity, constraint design

---

## 🔴 Advanced Exercises

### Exercise 11: Automated Data Quality Framework
**Scenario**: Build an enterprise-grade data quality monitoring system.

**Requirements**:
- Automated detection of quality issues
- Configurable quality rules and thresholds
- Quality score calculation and tracking
- Alerting for quality degradation

**Tasks**:
1. Design a flexible rule engine for quality checks
2. Implement quality scoring algorithms
3. Create automated quality reports and dashboards
4. Build alerting mechanisms for quality thresholds

**Expected Skills**: Advanced SQL patterns, procedure development, monitoring systems

---

### Exercise 12: Real-Time Data Cleaning Pipeline
**Scenario**: Clean data as it arrives in the system rather than batch processing.

**Challenge**: Implement incremental cleaning that processes only new/changed records.

**Tasks**:
1. Design change detection mechanisms
2. Implement incremental cleaning logic
3. Handle dependencies between cleaning steps
4. Ensure consistency during partial updates

**Expected Skills**: Incremental processing, change detection, pipeline design

---

### Exercise 13: Machine Learning Data Preparation
**Scenario**: Prepare datasets for machine learning model training.

**ML-Specific Requirements**:
- Handle categorical encoding consistently
- Normalize numeric ranges appropriately  
- Handle missing values with ML-appropriate strategies
- Create feature engineering pipelines

**Tasks**:
1. Implement one-hot encoding for categorical variables
2. Create standardized numeric feature scaling
3. Develop ML-appropriate missing value strategies
4. Build reproducible feature engineering pipelines

**Expected Skills**: Statistical methods, feature engineering, ML data preparation

---

### Exercise 14: Regulatory Compliance Cleaning
**Scenario**: Ensure data meets regulatory requirements (GDPR, CCPA, SOX).

**Compliance Requirements**:
- Data anonymization and pseudonymization
- Audit trail maintenance
- Data retention policy enforcement
- Privacy-compliant data handling

**Tasks**:
1. Implement data anonymization techniques
2. Create complete audit trails for all data changes
3. Build data retention and deletion workflows
4. Ensure privacy-compliant data processing

**Expected Skills**: Privacy techniques, audit systems, compliance frameworks

---

### Exercise 15: Performance-Optimized Cleaning
**Scenario**: Clean massive datasets efficiently without impacting system performance.

**Performance Challenges**:
- Large table cleaning without table locks
- Memory-efficient processing of huge datasets
- Parallel processing of cleaning operations
- Minimal downtime during cleaning operations

**Tasks**:
1. Design chunked processing for large tables
2. Implement parallel cleaning strategies
3. Optimize cleaning queries for performance
4. Monitor and minimize system impact

**Expected Skills**: Performance optimization, parallel processing, system impact analysis

---

## 🎯 Exercise Templates

### Basic Duplicate Detection Template
```sql
-- Find exact duplicates
SELECT email, COUNT(*) as duplicate_count
FROM Customer 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Identify which records to keep/remove
WITH ranked_duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY CustomerId) as rn
    FROM Customer
)
SELECT * FROM ranked_duplicates WHERE rn > 1; -- Records to remove
```

### Missing Value Analysis Template
```sql
-- Calculate completeness percentages
SELECT 
    'Email' as field_name,
    COUNT(Email) as non_null_count,
    COUNT(*) as total_count,
    ROUND(COUNT(Email) * 100.0 / COUNT(*), 2) as completeness_pct
FROM Customer

UNION ALL

SELECT 
    'Phone',
    COUNT(Phone),
    COUNT(*),
    ROUND(COUNT(Phone) * 100.0 / COUNT(*), 2)
FROM Customer;
```

### Standardization Template
```sql
-- Email standardization
UPDATE Customer 
SET Email = LOWER(TRIM(Email))
WHERE Email IS NOT NULL 
  AND Email != LOWER(TRIM(Email));
```

---

## 💡 Success Tips

### Getting Started
- Always backup data before cleaning operations
- Start with small samples to test cleaning logic
- Document all cleaning decisions and rationale
- Measure data quality before and after cleaning

### Best Practices
- Clean data incrementally rather than all at once
- Preserve original data during cleaning processes
- Test cleaning logic thoroughly before full execution
- Create reversible cleaning operations when possible

### Quality Validation
- Always validate cleaning results
- Measure improvement in data quality metrics
- Get business stakeholder approval for cleaning rules
- Monitor data quality continuously after cleaning

---

## 📊 Progress Tracking

### Beginner Level Completion
- [ ] Exercise 1: Basic Duplicate Detection
- [ ] Exercise 2: Email Address Standardization  
- [ ] Exercise 3: Phone Number Cleanup
- [ ] Exercise 4: Missing Contact Information
- [ ] Exercise 5: Address Standardization

### Intermediate Level Completion
- [ ] Exercise 6: Advanced Duplicate Resolution
- [ ] Exercise 7: Business Rule Validation
- [ ] Exercise 8: Time Series Data Cleaning
- [ ] Exercise 9: Product Catalog Cleanup
- [ ] Exercise 10: Multi-Table Data Consistency

### Advanced Level Completion
- [ ] Exercise 11: Automated Data Quality Framework
- [ ] Exercise 12: Real-Time Data Cleaning Pipeline
- [ ] Exercise 13: Machine Learning Data Preparation
- [ ] Exercise 14: Regulatory Compliance Cleaning
- [ ] Exercise 15: Performance-Optimized Cleaning

---

## 🔗 Additional Resources

- [Data Cleaning Best Practices Guide](../reference/cleaning_best_practices.md)
- [SQL Functions Reference](../reference/sql_functions_reference.md)
- [Quality Metrics Framework](../reference/quality_metrics.md)

---

*Master these exercises and you'll be cleaning data like a pro! Start with Exercise 1 and work your way up.* 🎯
