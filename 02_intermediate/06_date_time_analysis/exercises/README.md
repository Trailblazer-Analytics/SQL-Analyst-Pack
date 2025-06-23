# 📅 Date/Time Analysis - Practice Exercises

**Module:** 06_date_time_analysis  
**Difficulty Range:** Beginner to Advanced  
**Database:** Chinook Sample Database  
**Estimated Time:** 4-6 hours

## 📋 Exercise Categories

### 🌟 Beginner Exercises (1-8)
Focus on basic date extraction, formatting, and simple temporal calculations.

### 🔥 Intermediate Exercises (9-16)
Emphasize date arithmetic, business logic, and time series analysis.

### 💎 Advanced Exercises (17-20)
Challenge with complex temporal patterns, forecasting, and advanced analytics.

---

## 🌟 Beginner Exercises

### Exercise 1: Basic Date Extraction
**Objective:** Extract date components from timestamps
**Business Context:** Create monthly sales reports

**Task:** From the Invoice table, extract the year, month, quarter, and day of week from each InvoiceDate. Show invoice counts by each time component.

**Expected Columns:** Year, Month, Quarter, DayOfWeek, InvoiceCount

**Hint:** Use EXTRACT() or date functions like YEAR(), MONTH(), etc.

---

### Exercise 2: Date Formatting and Display
**Objective:** Format dates for business reporting
**Business Context:** Create customer-friendly date displays

**Task:** Display customer invoices with formatted dates showing "Month Day, Year" format (e.g., "January 15, 2009") and categorize by time of year.

**Expected Columns:** CustomerId, InvoiceId, FormattedDate, Season

**Hint:** Use date formatting functions and CASE statements for seasons

---

### Exercise 3: Age and Tenure Calculations
**Objective:** Calculate time differences
**Business Context:** Analyze employee tenure and service years

**Task:** Calculate each employee's age at hire date and current tenure in years and months.

**Expected Columns:** EmployeeId, FirstName, LastName, HireDate, AgeAtHire, TenureYears, TenureMonths

**Hint:** Use date arithmetic with DATEDIFF or TIMESTAMPDIFF

---

### Exercise 4: Business Day Analysis
**Objective:** Work with business calendar concepts
**Business Context:** Analyze sales patterns by business vs. weekend days

**Task:** Categorize all invoices as "Weekday" or "Weekend" and calculate average sales for each category.

**Expected Columns:** DayType, InvoiceCount, AverageSale, TotalSales

**Hint:** Use day of week functions and CASE statements

---

### Exercise 5: Monthly Sales Trends
**Objective:** Basic time series grouping
**Business Context:** Identify monthly sales patterns

**Task:** Calculate total sales by month for 2009, showing month name and sales amount. Sort chronologically.

**Expected Columns:** MonthName, YearMonth, TotalSales, InvoiceCount

**Hint:** Group by year and month, use date formatting for month names

---

### Exercise 6: Customer First Purchase Analysis
**Objective:** Identify temporal milestones
**Business Context:** Track customer acquisition timing

**Task:** Find each customer's first purchase date and categorize by quarter of first purchase.

**Expected Columns:** CustomerId, CustomerName, FirstPurchaseDate, FirstPurchaseQuarter, FirstPurchaseYear

**Hint:** Use MIN() with GROUP BY and date extraction

---

### Exercise 7: Simple Date Range Filtering
**Objective:** Filter data using date ranges
**Business Context:** Analyze specific time periods

**Task:** Find all invoices from Q4 2009 (October-December) and show daily sales totals.

**Expected Columns:** InvoiceDate, DailySales, InvoiceCount

**Hint:** Use WHERE clause with date ranges and GROUP BY date

---

### Exercise 8: Days Between Events
**Objective:** Calculate simple date differences
**Business Context:** Measure time between customer purchases

**Task:** For customers with multiple purchases, calculate days between their first and second purchase.

**Expected Columns:** CustomerId, CustomerName, FirstPurchase, SecondPurchase, DaysBetween

**Hint:** Use window functions to get first and second purchase dates

---

## 🔥 Intermediate Exercises

### Exercise 9: Rolling Time Window Analysis
**Objective:** Implement moving time windows
**Business Context:** Calculate 30-day rolling sales averages

**Task:** For each date with sales, calculate the 30-day rolling average of daily sales amounts.

**Expected Columns:** SalesDate, DailySales, Rolling30DayAvg, DaysInWindow

**Hint:** Use window functions with RANGE BETWEEN INTERVAL

---

### Exercise 10: Period-over-Period Growth
**Objective:** Calculate growth rates across time periods
**Business Context:** Measure month-over-month sales growth

**Task:** Calculate monthly sales and month-over-month growth rate for 2009. Express growth as percentage.

**Expected Columns:** YearMonth, MonthlySales, PreviousMonth, GrowthRate, GrowthDirection

**Hint:** Use LAG() window function and percentage calculations

---

### Exercise 11: Seasonal Analysis
**Objective:** Identify seasonal patterns
**Business Context:** Determine peak sales seasons

**Task:** Compare quarterly sales across all years and identify the strongest and weakest quarters.

**Expected Columns:** Quarter, AvgQuarterlySales, TotalSales, SeasonalRank, Performance

**Hint:** Extract quarters, calculate averages, and use ranking functions

---

### Exercise 12: Customer Purchase Intervals
**Objective:** Analyze customer behavior timing
**Business Context:** Understand customer purchase frequency patterns

**Task:** Calculate average days between purchases for each customer who has made multiple purchases.

**Expected Columns:** CustomerId, CustomerName, TotalPurchases, AvgDaysBetweenPurchases, CustomerCategory

**Hint:** Use LAG() to get previous purchase dates, then calculate averages

---

### Exercise 13: Working Days Calculation
**Objective:** Implement business calendar logic
**Business Context:** Calculate SLA compliance excluding weekends

**Task:** Calculate working days between invoice date and payment (assume payment date = invoice date + 5 business days).

**Expected Columns:** InvoiceId, InvoiceDate, PaymentDueDate, WorkingDaysToPayment

**Hint:** Create a function to add business days excluding weekends

---

### Exercise 14: Cohort Analysis Basics
**Objective:** Group customers by time periods
**Business Context:** Analyze customer retention by acquisition month

**Task:** Group customers by their first purchase month and track how many made repeat purchases within 90 days.

**Expected Columns:** AcquisitionMonth, CustomersAcquired, CustomersRetained, RetentionRate

**Hint:** Use first purchase dates and count subsequent purchases within time window

---

### Exercise 15: Time Zone Handling
**Objective:** Work with different time zones
**Business Context:** Normalize global sales data

**Task:** Convert all invoice timestamps to UTC and analyze sales by UTC hour of day.

**Expected Columns:** UTCHour, SalesCount, TotalSales, AvgSaleSize

**Hint:** Use timezone conversion functions and EXTRACT(HOUR)

---

### Exercise 16: Fiscal vs Calendar Year Analysis
**Objective:** Work with different year definitions
**Business Context:** Compare calendar year vs fiscal year performance

**Task:** Calculate sales for both calendar year 2009 and fiscal year 2009 (assume fiscal year starts April 1).

**Expected Columns:** PeriodType, Year, TotalSales, GrowthFromPrevious

**Hint:** Use CASE statements to categorize dates into different year types

---

## 💎 Advanced Exercises

### Exercise 17: Time Series Gap Detection
**Objective:** Identify missing data points in time series
**Business Context:** Find periods with no sales activity

**Task:** Identify all date gaps larger than 7 days between consecutive sales dates. Show the gap duration and potential impact.

**Expected Columns:** GapStartDate, GapEndDate, GapDays, SalesBeforeGap, SalesAfterGap, PotentialLostRevenue

**Hint:** Use LAG() to find date differences and identify significant gaps

---

### Exercise 18: Dynamic Date Range Filtering
**Objective:** Create flexible date filtering logic
**Business Context:** Build parameterized reports for different time periods

**Task:** Create a query that can analyze sales for "Last N days", "Last N months", or "Year to Date" based on parameters.

**Expected Logic:** Show how the query would work for different scenarios
**Expected Output:** Flexible reporting structure

**Hint:** Use CASE statements and date arithmetic with variables

---

### Exercise 19: Anomaly Detection in Time Series
**Objective:** Identify unusual patterns in temporal data
**Business Context:** Detect abnormal sales days for investigation

**Task:** Identify days where sales are more than 2 standard deviations away from the rolling 30-day average.

**Expected Columns:** SalesDate, DailySales, Rolling30DayAvg, StandardDeviation, DeviationScore, AnomalyType

**Hint:** Use window functions to calculate rolling statistics and identify outliers

---

### Exercise 20: Advanced Forecasting Model
**Objective:** Build predictive temporal models
**Business Context:** Forecast next month's sales based on trends

**Task:** Create a simple linear trend forecast for the next month's sales based on the last 6 months of data.

**Expected Columns:** ForecastMonth, PredictedSales, ConfidenceLevel, TrendDirection, SeasonalAdjustment

**Hint:** Use regression concepts with SQL window functions and trend calculations

---

## 🔧 Solution Guidelines

### For Instructors
- Provide multiple solution approaches (different SQL dialects)
- Include performance optimization tips
- Highlight common date/time pitfalls and edge cases
- Demonstrate real-world business applications

### For Students
- Pay attention to timezone and locale considerations
- Test edge cases (leap years, month boundaries, etc.)
- Consider performance implications of date functions
- Practice with different date formats and inputs

## 📊 Validation Queries

Each exercise should include validation steps:
1. Date range verification (no impossible dates)
2. Calculation accuracy checking
3. Timezone consistency validation
4. Performance benchmarking for large datasets

## 🚀 Extension Challenges

After completing all exercises:
1. Build a comprehensive temporal analytics dashboard
2. Implement advanced statistical models for forecasting
3. Create reusable date dimension tables
4. Develop time-based data quality monitoring

## 💡 Common Pitfalls and Best Practices

### Date/Time Pitfalls to Avoid
- Inconsistent timezone handling
- Ignoring leap years and month-end boundaries
- Performance issues with date functions in WHERE clauses
- Incorrect business day calculations

### Best Practices
- Always be explicit about timezone assumptions
- Use appropriate indexes on date columns
- Consider using date dimension tables for complex calendars
- Test thoroughly with edge case dates

---

*Master temporal analytics to unlock the power of time-based business intelligence!*
