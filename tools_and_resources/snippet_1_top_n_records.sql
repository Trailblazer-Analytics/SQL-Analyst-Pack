/*
================================================================================
File: tools_and_resources/snippet_1_top_n_records.sql
Topic: Top N Records Per Group Pattern
Purpose: Find highest/lowest performers within categories for rankings and leaderboards
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Updated: 2025-06-23
================================================================================

BUSINESS USE CASE:
Essential pattern for business analysis - finding top performers, best sellers,
highest value customers, or worst performing items within specific categories.
Common in sales analysis, product performance, and competitive rankings.

TECHNIQUE:
Uses ROW_NUMBER() window function with PARTITION BY to rank items within groups,
then filters to show only the top N results per group.

SQL COMPATIBILITY:
✅ PostgreSQL, SQL Server, Oracle, MySQL 8.0+, SQLite 3.25+
⚠️ Older MySQL versions need subquery approach
================================================================================
*/

-- Snippet 1: Find the Top N Records Per Group

-- Use Case: Find the top 3 best-selling tracks in each genre.
-- Technique: Use the `ROW_NUMBER()` window function partitioned by the group.

WITH RankedTracks AS (
    SELECT
        g.Name AS Genre,
        t.Name AS TrackName,
        SUM(ii.Quantity) AS UnitsSold,
        ROW_NUMBER() OVER(PARTITION BY g.Name ORDER BY SUM(ii.Quantity) DESC) as Rank
    FROM
        genres g
    JOIN
        tracks t ON g.GenreId = t.GenreId
    JOIN
        invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY
        g.Name, t.Name
)
SELECT
    Genre,
    TrackName,
    UnitsSold
FROM
    RankedTracks
WHERE
    Rank <= 3
ORDER BY
    Genre, UnitsSold DESC;
