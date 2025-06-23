# 🚀 Window Functions - Practice Exercises

**Module:** 05_window_functions  
**Difficulty Range:** Beginner to Advanced  
**Database:** Chinook Sample Database  
**Estimated Time:** 4-6 hours

## 📋 Exercise Categories

### 🌟 Beginner Exercises (1-8)
Focus on basic window function concepts and simple ranking scenarios.

### 🔥 Intermediate Exercises (9-16)
Emphasize running calculations, complex partitioning, and business analytics.

### 💎 Advanced Exercises (17-20)
Challenge with complex scenarios, multiple window functions, and performance optimization.

---

## 🌟 Beginner Exercises

### Exercise 1: Basic Row Numbering
**Objective:** Understand ROW_NUMBER() basics
**Business Context:** Assign unique identifiers to customer records

**Task:** Write a query to assign row numbers to all customers, ordered by their last name, then first name.

**Expected Columns:** CustomerId, FirstName, LastName, RowNum

**Hint:** Use ROW_NUMBER() OVER(ORDER BY ...)

---

### Exercise 2: Department Ranking
**Objective:** Learn RANK() vs DENSE_RANK()
**Business Context:** Rank employees within their departments

**Task:** Create a query that ranks employees by hire date within each department (use title as department). Show both RANK() and DENSE_RANK() to understand the difference.

**Expected Columns:** EmployeeId, FirstName, LastName, Title, HireDate, Rank, DenseRank

**Hint:** Use PARTITION BY Title in your OVER clause

---

### Exercise 3: Customer Purchase Count Ranking
**Objective:** Apply ranking to business metrics
**Business Context:** Identify top customers by purchase frequency

**Task:** Rank customers by their total number of invoices (purchase frequency). Include ties appropriately.

**Expected Columns:** CustomerId, FirstName, LastName, TotalInvoices, CustomerRank

**Hint:** First calculate total invoices per customer, then apply ranking

---

### Exercise 4: Top N Analysis
**Objective:** Filter ranked results
**Business Context:** Find top 5 customers by total spending

**Task:** Use window functions to identify the top 5 customers by total invoice amount. Show their rank and total spending.

**Expected Columns:** CustomerId, FirstName, LastName, TotalSpent, SpendingRank

**Hint:** Use a CTE with ranking, then filter WHERE rank <= 5

---

### Exercise 5: Basic Percentile Analysis
**Objective:** Understand NTILE() function
**Business Context:** Categorize customers into spending quartiles

**Task:** Divide customers into 4 equal groups (quartiles) based on their total spending. Label them as Q1, Q2, Q3, Q4.

**Expected Columns:** CustomerId, FirstName, LastName, TotalSpent, Quartile

**Hint:** Use NTILE(4) and CASE statement for labeling

---

### Exercise 6: Simple Running Total
**Objective:** Introduction to cumulative calculations
**Business Context:** Track cumulative sales by date

**Task:** Calculate a running total of daily sales amounts, ordered by invoice date.

**Expected Columns:** InvoiceDate, DailySales, RunningTotal

**Hint:** Use SUM() OVER(ORDER BY date ROWS UNBOUNDED PRECEDING)

---

### Exercise 7: Previous Value Comparison
**Objective:** Basic LAG() usage
**Business Context:** Compare current month sales to previous month

**Task:** For each month in 2009, show the monthly sales total and the previous month's sales total.

**Expected Columns:** YearMonth, MonthlySales, PreviousMonthSales

**Hint:** Extract year-month, group by it, then use LAG()

---

### Exercise 8: First and Last Values
**Objective:** Use FIRST_VALUE() and LAST_VALUE()
**Business Context:** Compare individual sales to period boundaries

**Task:** For each customer's invoices, show the first invoice amount and last invoice amount in their purchase history.

**Expected Columns:** CustomerId, InvoiceId, InvoiceDate, Total, FirstInvoice, LastInvoice

**Hint:** Partition by CustomerId, order by InvoiceDate

---

## 🔥 Intermediate Exercises

### Exercise 9: Moving Average Analysis
**Objective:** Calculate rolling averages
**Business Context:** Smooth out daily sales fluctuations

**Task:** Calculate a 7-day moving average of daily sales. Only include days where you have at least 3 days of prior data.

**Expected Columns:** InvoiceDate, DailySales, MovingAvg7Day

**Hint:** Use ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

---

### Exercise 10: Growth Rate Analysis
**Objective:** Calculate period-over-period growth
**Business Context:** Measure monthly revenue growth rates

**Task:** Calculate month-over-month growth rate for total sales. Express as a percentage.

**Expected Columns:** YearMonth, MonthlySales, PreviousMonth, GrowthRate

**Hint:** Use LAG() and percentage calculation formula

---

### Exercise 11: Customer Segmentation
**Objective:** Multi-criteria ranking and segmentation
**Business Context:** Create customer value segments

**Task:** Segment customers into "High", "Medium", "Low" value categories based on both total spending and purchase frequency. Use NTILE for each metric.

**Expected Columns:** CustomerId, FirstName, LastName, TotalSpent, InvoiceCount, SpendingTier, FrequencyTier, OverallSegment

**Hint:** Create separate NTILE rankings, then combine with business logic

---

### Exercise 12: Sales Performance Dashboard
**Objective:** Combine multiple window functions
**Business Context:** Create a comprehensive sales rep performance view

**Task:** For each employee, calculate their total sales, rank among all employees, percentage of total company sales, and running contribution to company total.

**Expected Columns:** EmployeeId, FirstName, LastName, TotalSales, SalesRank, PercentOfTotal, RunningContribution

**Hint:** Combine SUM(), RANK(), and window aggregates

---

### Exercise 13: Seasonal Trend Analysis
**Objective:** Advanced date-based windowing
**Business Context:** Identify seasonal sales patterns

**Task:** For each month, calculate the sales total, the same month last year's sales, and the year-over-year change.

**Expected Columns:** Year, Month, MonthlySales, SameMonthLastYear, YoYChange

**Hint:** Use LAG() with appropriate PARTITION BY and ORDER BY

---

### Exercise 14: Customer Retention Analysis
**Objective:** Gap analysis with LAG/LEAD
**Business Context:** Measure time between customer purchases

**Task:** For each customer's invoices, calculate the days between consecutive purchases. Identify customers with gaps > 90 days.

**Expected Columns:** CustomerId, InvoiceId, InvoiceDate, DaysSinceLast, IsLongGap

**Hint:** Use LAG() to get previous invoice date, then calculate differences

---

### Exercise 15: Product Performance Comparison
**Objective:** Complex partitioning and ranking
**Business Context:** Compare track performance within albums

**Task:** For each track, show its sales rank within its album and its sales rank overall. Also show what percentage of the album's sales this track represents.

**Expected Columns:** TrackId, Name, AlbumTitle, AlbumRank, OverallRank, PercentOfAlbum

**Hint:** Use multiple PARTITION BY clauses and percentage calculations

---

### Exercise 16: ABC Analysis Implementation
**Objective:** Cumulative percentage analysis
**Business Context:** Implement ABC analysis for inventory management

**Task:** Classify customers into A (top 80% of sales), B (next 15%), and C (remaining 5%) categories using cumulative percentage analysis.

**Expected Columns:** CustomerId, FirstName, LastName, TotalSales, CumulativePercent, ABCCategory

**Hint:** Calculate running total percentage, then categorize

---

## 💎 Advanced Exercises

### Exercise 17: Complex Cohort Analysis
**Objective:** Multi-dimensional window functions
**Business Context:** Customer behavior cohort analysis

**Task:** Create a cohort analysis showing customer retention by month. For customers who made their first purchase in each month, track how many are still active in subsequent months.

**Expected Columns:** CohortMonth, Period, CustomersActive, RetentionRate

**Hint:** Complex combination of window functions and date arithmetic

---

### Exercise 18: Dynamic Ranking with Ties
**Objective:** Handle ranking edge cases
**Business Context:** Award system with tie-breaking rules

**Task:** Create a sales leaderboard where ties in total sales are broken by the number of transactions (fewer transactions ranks higher), and then by customer ID as final tiebreaker.

**Expected Columns:** CustomerId, FirstName, LastName, TotalSales, TransactionCount, FinalRank

**Hint:** Use ORDER BY with multiple criteria in RANK()

---

### Exercise 19: Performance Optimization Challenge
**Objective:** Optimize window function performance
**Business Context:** Large dataset processing

**Task:** Rewrite a slow query that calculates running totals for all invoices. Compare different windowing approaches and explain which is most efficient.

**Original Query Provided:** See solution notes
**Your Optimized Query:** [Your solution]
**Performance Improvement:** [Explain your optimization]

**Hint:** Consider different frame specifications and ordering strategies

---

### Exercise 20: Business Intelligence Dashboard
**Objective:** Comprehensive analytics integration
**Business Context:** Executive dashboard creation

**Task:** Create a comprehensive query that answers: "For each genre, show total sales, rank among genres, percent of total sales, top-selling artist in that genre, and 3-month moving average of sales."

**Expected Columns:** GenreId, GenreName, TotalSales, GenreRank, PercentOfTotal, TopArtist, MovingAvg3Month

**Hint:** Combine multiple CTEs with various window functions

---

## 🔧 Solution Guidelines

### For Instructors
- Solutions should demonstrate multiple approaches where applicable
- Include performance considerations and best practices
- Highlight common pitfalls and how to avoid them
- Provide business context explanations

### For Students
- Start with simpler exercises and build complexity
- Test your solutions with different data ranges
- Pay attention to NULL handling
- Consider performance implications of your window functions

## 📊 Validation Queries

Each exercise should include validation steps:
1. Row count verification
2. Data type checking
3. Business logic validation
4. Performance benchmarking (for advanced exercises)

## 🚀 Extension Challenges

After completing all exercises:
1. Combine window functions with other advanced SQL features
2. Create your own business scenarios
3. Optimize queries for production environments
4. Build reusable analytical functions

---

*Master these exercises to become proficient in window functions for real-world business analytics!*
