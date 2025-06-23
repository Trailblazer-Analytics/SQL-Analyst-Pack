# 📖 Basic SQL Queries - Foundation Module

Welcome to your SQL journey! This module covers the fundamental building blocks that every SQL analyst needs to master. You'll learn to retrieve, filter, and combine data using real-world examples.

## 🎯 Learning Objectives

By completing this module, you will be able to:

- **Retrieve data** using SELECT statements
- **Filter records** with WHERE clauses and conditions
- **Work with text** using pattern matching and string functions
- **Combine tables** using different types of JOINs
- **Structure complex queries** with Common Table Expressions (CTEs)

## 📚 Module Contents

### 1. Data Retrieval and Filtering
- **01_basic_where_filtering.sql** - Master the WHERE clause with practical examples
- **02_filtering_and_selection.sql** - Column selection techniques and advanced filtering

### 2. Text and Pattern Matching  
- **03_pattern_matching_and_text_filtering.sql** - Search and filter text data effectively

### 3. Combining Data from Multiple Tables
- **04_basic_joins.sql** - Inner and Left joins with real business scenarios
- **05_advanced_joins.sql** - Full outer joins, self-joins, and complex combinations

### 4. Advanced Query Structure
- **06_common_table_expressions.sql** - Organize complex queries with CTEs

## 🗃️ Sample Data

This module uses the **Chinook Music Store** database, which contains:
- **Artists** and **Albums** - Music catalog data
- **Customers** - Customer information from different countries
- **Invoices** - Sales transactions and line items
- **Employees** - Staff hierarchy and territories

## 🚀 Getting Started

### Prerequisites
- Sample database loaded (see [Setup Guide](../../00_getting_started/README.md))
- Basic understanding of what a database table contains (rows and columns)

### Study Approach
1. **Read each SQL file from top to bottom** - Comments explain every concept
2. **Run the queries yourself** - Practice makes perfect
3. **Modify the examples** - Try different filters and conditions
4. **Complete the exercises** - Apply what you've learned

### Recommended Order
```
01_basic_where_filtering.sql     ← Start here!
02_filtering_and_selection.sql   ← Column selection
03_pattern_matching_and_text_filtering.sql
04_basic_joins.sql               ← Combining tables
05_advanced_joins.sql            ← More join types
06_common_table_expressions.sql  ← Query organization
```

## 💡 Key Concepts Covered

### WHERE Clause Mastery
- Single condition filtering
- Multiple conditions (AND, OR, NOT)
- Value ranges (BETWEEN, IN)
- NULL value handling

### Text Processing
- Pattern matching with LIKE and wildcards
- Case-insensitive searching
- String functions (UPPER, LOWER, LENGTH)

### JOIN Operations
- Inner joins - matching records only
- Left joins - include all records from left table
- Right joins - include all records from right table  
- Full outer joins - include all records from both tables
- Self joins - join a table to itself

### Query Organization
- Common Table Expressions (CTEs)
- Subqueries vs CTEs
- Making complex queries readable

## 🏋️ Practice Exercises

After completing each script, try these challenges:

### Beginner Exercises
1. Find all customers from Canada
2. List all albums by 'AC/DC'
3. Show invoices with total greater than $10
4. Find employees with 'Manager' in their title

### Intermediate Exercises  
1. Find customers who have spent more than $40 total
2. List all tracks longer than 5 minutes with their albums
3. Show artists who have more than 10 albums
4. Find employees and their direct reports

### Advanced Exercises
1. Calculate total sales by country and month
2. Find customers who bought tracks from multiple genres
3. Identify top-selling artists by revenue
4. Create a customer loyalty classification

## 🔗 Next Steps

Once you've mastered basic queries:

1. **Move to [02_data_profiling](../02_data_profiling/)** - Learn to explore and understand new datasets
2. **Practice regularly** - Try the queries with different sample databases
3. **Join the community** - Share your solutions and learn from others

## 📋 Self-Assessment Checklist

Before moving to the next module, ensure you can:

- [ ] Write SELECT statements to retrieve specific columns
- [ ] Use WHERE clauses with multiple conditions
- [ ] Apply text pattern matching with LIKE
- [ ] Perform INNER and LEFT JOINs confidently  
- [ ] Understand when to use different join types
- [ ] Structure complex queries using CTEs
- [ ] Debug common SQL errors independently

## 🆘 Need Help?

- **Stuck on a concept?** Check our [FAQ](../../FAQ.md)
- **Technical issues?** See the [Troubleshooting Guide](../../00_getting_started/troubleshooting.md)
- **Want to contribute?** Read our [Contributing Guidelines](../../CONTRIBUTING.md)

---

**Remember:** SQL is learned by doing. Run every query, experiment with modifications, and don't hesitate to make mistakes – they're part of the learning process! 🚀
