# 🏋️ Basic Queries - Practice Exercises

Put your SQL skills to the test! These exercises are designed to reinforce the concepts from the basic queries module using the Chinook music store database.

## 📋 Exercise Instructions

1. **Try each exercise yourself first** - Don't peek at the solutions immediately
2. **Run your queries** - Test them against the Chinook database
3. **Compare with solutions** - Learn from different approaches
4. **Experiment** - Modify the queries to explore the data further

## 🎯 Difficulty Levels

- 🟢 **Beginner** - Basic WHERE clauses and single-table queries
- 🟡 **Intermediate** - Multiple conditions, JOINs, and functions
- 🔴 **Advanced** - Complex logic, subqueries, and business scenarios

---

## 🟢 Beginner Exercises

### Exercise 1: Customer Geography
**Task:** Find all customers from Brazil.
**Expected columns:** CustomerId, FirstName, LastName, Country
**Hint:** Use a simple WHERE clause

### Exercise 2: High-Value Invoices  
**Task:** Find all invoices with a total greater than $10.
**Expected columns:** InvoiceId, CustomerId, InvoiceDate, Total
**Hint:** Use comparison operators

### Exercise 3: Rock Music
**Task:** Find all tracks in the "Rock" genre.
**Expected columns:** TrackId, Name, GenreId
**Hint:** You'll need to find the GenreId for Rock first, or use a JOIN

### Exercise 4: Long Tracks
**Task:** Find tracks longer than 5 minutes (300,000 milliseconds).
**Expected columns:** TrackId, Name, Milliseconds, Minutes (calculated)
**Hint:** Convert milliseconds to minutes using division

### Exercise 5: Multiple Countries
**Task:** Find customers from USA, Canada, or Brazil.
**Expected columns:** CustomerId, FirstName, LastName, Country
**Hint:** Use the IN operator

---

## 🟡 Intermediate Exercises

### Exercise 6: Employee Hierarchy
**Task:** Find all employees who report to Nancy Edwards (EmployeeId = 2).
**Expected columns:** EmployeeId, FirstName, LastName, Title, ReportsTo
**Hint:** Use the ReportsTo column

### Exercise 7: Date Range Analysis
**Task:** Find all invoices from the first quarter of 2012 (Jan-Mar).
**Expected columns:** InvoiceId, InvoiceDate, Total, CustomerName
**Hint:** Use BETWEEN for dates and JOIN for customer names

### Exercise 8: Price Range Products
**Task:** Find tracks priced between $0.99 and $1.29.
**Expected columns:** TrackId, Name, UnitPrice, Album, Artist
**Hint:** Use BETWEEN and multiple JOINs

### Exercise 9: Customer Without Company
**Task:** Find individual customers (those without a company name).
**Expected columns:** CustomerId, FirstName, LastName, Email, Country
**Hint:** Check for NULL values properly

### Exercise 10: Genre Exclusion
**Task:** Find all tracks that are NOT in Rock, Pop, or Jazz genres.
**Expected columns:** TrackId, Name, Genre, Artist, Album
**Hint:** Use NOT IN and multiple JOINs

---

## 🔴 Advanced Exercises

### Exercise 11: Customer Purchase Analysis
**Task:** Find customers who have made purchases totaling more than $40.
**Expected columns:** CustomerId, CustomerName, Country, TotalSpent
**Hint:** Use GROUP BY and HAVING with aggregation

### Exercise 12: Multi-Genre Artists
**Task:** Find artists who have albums in multiple genres.
**Expected columns:** ArtistId, ArtistName, GenreCount, GenreList
**Hint:** Use GROUP BY, COUNT, and STRING_AGG (or similar function)

### Exercise 13: Seasonal Sales Analysis
**Task:** Find the highest-selling month in 2012.
**Expected columns:** Month, Year, TotalSales, InvoiceCount
**Hint:** Use date functions, GROUP BY, and ORDER BY

### Exercise 14: Customer Loyalty Segmentation
**Task:** Classify customers as 'High', 'Medium', or 'Low' value based on total purchases.
**Rules:** High (>$40), Medium ($15-$40), Low (<$15)
**Expected columns:** CustomerId, CustomerName, TotalSpent, Segment
**Hint:** Use CASE WHEN for segmentation

### Exercise 15: Complex Business Query
**Task:** Find the top 3 selling tracks in each genre (by quantity sold).
**Expected columns:** Genre, TrackName, Artist, QuantitySold, Rank
**Hint:** Use window functions (ROW_NUMBER) or subqueries

---

## 💡 Bonus Challenges

### Bonus 1: Data Quality Check
Find any inconsistencies in the data (e.g., customers without invoices, tracks without albums).

### Bonus 2: Time-Based Analysis
Analyze customer purchasing patterns by day of week and hour of day.

### Bonus 3: Geographic Revenue Analysis
Calculate revenue per capita by country (you'll need to research population data).

---

## 🎓 Learning Outcomes

After completing these exercises, you should be comfortable with:

- ✅ Basic WHERE clause filtering
- ✅ Comparison and logical operators
- ✅ IN, BETWEEN, and NULL handling
- ✅ Simple JOINs between related tables
- ✅ Basic aggregate functions and grouping
- ✅ Date and time filtering
- ✅ String pattern matching
- ✅ Business logic implementation in SQL

## 🔗 Next Steps

Once you've completed these exercises:

1. **Check your solutions** against the provided answer key
2. **Move to the next module:** [02_data_profiling](../../02_data_profiling/)
3. **Practice more** with the [intermediate exercises](../../02_intermediate/)
4. **Share your solutions** and learn from the community

---

**Remember:** There's often more than one correct way to write a SQL query. Focus on getting the right results first, then optimize for readability and performance! 🚀
