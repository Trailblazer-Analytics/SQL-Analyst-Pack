# SQL Glossary

## A

**Aggregate Function**: Functions that perform calculations on a set of values and return a single value (e.g., SUM, COUNT, AVG, MIN, MAX).

**Alias**: A temporary name assigned to a table or column for easier reference in queries.

**ANSI SQL**: American National Standards Institute SQL standard that defines the syntax and semantics of SQL.

## B

**BigQuery**: Google Cloud's enterprise data warehouse solution.

**Boolean Logic**: Operations using TRUE/FALSE values, often with AND, OR, NOT operators.

## C

**CTE (Common Table Expression)**: A named temporary result set that exists within a single SQL statement.

**Cardinality**: The number of unique values in a column or the number of rows returned by a query.

**Chinook Database**: Sample database representing a digital media store, used throughout this project.

**Column**: A vertical structure in a table that stores a specific type of data.

**Constraint**: Rules applied to columns to ensure data integrity (PRIMARY KEY, FOREIGN KEY, NOT NULL, etc.).

## D

**Data Type**: Classification of data (INTEGER, VARCHAR, DATE, etc.) that determines storage and operations.

**DDL (Data Definition Language)**: SQL commands that define database structure (CREATE, ALTER, DROP).

**DML (Data Manipulation Language)**: SQL commands that manipulate data (INSERT, UPDATE, DELETE, SELECT).

**Duplicate**: Records that have identical values across specified columns.

## E

**ETL (Extract, Transform, Load)**: Process of extracting data from sources, transforming it, and loading into a destination.

**Execution Plan**: Database's strategy for executing a query, showing steps and resource usage.

## F

**Foreign Key**: Column(s) that reference the primary key of another table, enforcing referential integrity.

**Function**: Predefined operations that return values (scalar functions) or tables (table functions).

## G

**GROUP BY**: SQL clause that groups rows with same values in specified columns for aggregate calculations.

## H

**HAVING**: Clause that filters groups created by GROUP BY (similar to WHERE but for groups).

## I

**Index**: Database structure that improves query performance by providing fast data access paths.

**INNER JOIN**: Returns only rows that have matching values in both tables.

## J

**JOIN**: Operation that combines rows from two or more tables based on related columns.

**JSON**: JavaScript Object Notation, a data format increasingly supported in modern SQL databases.

## K

**Key**: Column(s) that uniquely identify rows (Primary Key) or reference other tables (Foreign Key).

## L

**LAG/LEAD**: Window functions that access data from previous/next rows without self-joins.

**LEFT JOIN**: Returns all rows from left table and matching rows from right table.

## M

**MySQL**: Open-source relational database management system.

**MERGE**: SQL statement that conditionally inserts, updates, or deletes based on match conditions.

## N

**Normalization**: Process of organizing database to reduce redundancy and improve integrity.

**NULL**: Special value representing missing or unknown data.

## O

**Oracle**: Enterprise relational database management system.

**OUTER JOIN**: Returns rows even when there's no match in one of the tables (LEFT, RIGHT, FULL).

## P

**PostgreSQL**: Advanced open-source relational database system.

**Primary Key**: Column(s) that uniquely identify each row in a table.

**Partition**: Window function clause that divides result set into groups for calculations.

## Q

**Query**: SQL statement that retrieves data from database tables.

**Query Optimization**: Process of improving query performance through better syntax, indexing, or execution plans.

## R

**Recursive CTE**: Common Table Expression that references itself to handle hierarchical data.

**Referential Integrity**: Constraint ensuring foreign key values match primary key values in referenced table.

**ROW_NUMBER()**: Window function that assigns unique sequential numbers to rows.

## S

**Schema**: Logical structure that defines how database is organized (tables, views, procedures).

**Snowflake**: Cloud-based data warehouse platform.

**SQL Server**: Microsoft's relational database management system.

**SQLite**: Lightweight, file-based relational database engine.

**Subquery**: Query nested inside another query.

## T

**Table**: Collection of related data organized in rows and columns.

**Transaction**: Unit of work that consists of one or more SQL statements, executed as a single operation.

**Trigger**: Special stored procedure that automatically executes in response to database events.

## U

**UNION**: Combines result sets of multiple SELECT statements, removing duplicates.

**UPDATE**: SQL statement that modifies existing data in tables.

**Upsert**: Operation that inserts new records or updates existing ones based on key matches.

## V

**View**: Virtual table based on the result of a SELECT statement.

**VARCHAR**: Variable-length character data type.

## W

**WHERE**: Clause that filters rows based on specified conditions.

**Window Function**: Function that performs calculations across related rows without collapsing them.

**WITH**: Keyword used to define Common Table Expressions (CTEs).

---

*This glossary covers key terms used throughout the SQL Analyst Pack. For deeper explanations, refer to the relevant scripts in each section.*
