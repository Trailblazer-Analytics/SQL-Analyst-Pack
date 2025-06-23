-- File: 07_text-analysis/04_tokenization_and_word_counts.sql
-- Topic: Tokenization and Word Counts
-- Author: Alexander Nykolaiszyn
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates how to perform tokenization (splitting text into words) and
-- calculate word frequencies. This is a fundamental task in text analysis, often used
-- to understand which terms are most common in a body of text.

-- Prerequisites:
-- This is an advanced topic. It requires knowledge of Common Table Expressions (CTEs),
-- particularly recursive CTEs. The syntax can be complex and varies across databases.

-- Dialect Compatibility:
-- Standard SQL lacks a built-in function for splitting strings into rows, making this task
-- challenging. The primary example uses a recursive CTE, which is supported by:
-- - PostgreSQL
-- - SQL Server
-- - Oracle
-- - SQLite (version 3.8.3+)
-- - MySQL (version 8.0+)
-- Other systems like BigQuery and Snowflake have dedicated, simpler functions.

---------------------------------------------------------------------------------------------------

-- Section 1: The Concept of Tokenization

-- Tokenization is the process of breaking down a piece of text into smaller units, called tokens.
-- Usually, tokens are words, but they can also be characters, sentences, or other units.
-- Once we have tokens, we can count them to find the most frequent words.

-- For example, the sentence "The quick brown fox" would be tokenized into:
-- "The"
-- "quick"
-- "brown"
-- "fox"

---------------------------------------------------------------------------------------------------

-- Section 2: Tokenization using a Recursive CTE

-- Since most databases don't have a `SPLIT` function that returns a table, we can build one
-- using a recursive CTE. This is a powerful but complex approach.

-- Let's tokenize the titles of all tracks in the `tracks` table.

-- Step 1: We need a CTE that recursively splits the track names.
WITH RECURSIVE WordSplit AS (
    -- Anchor Member: This is the starting point of the recursion.
    -- It selects the initial track name and finds the first space.
    SELECT
        TrackId,
        Name,
        -- Find the first word. If no space, the whole name is the word.
        CASE
            WHEN INSTR(Name, ' ') > 0 THEN SUBSTR(Name, 1, INSTR(Name, ' ') - 1)
            ELSE Name
        END AS Word,
        -- Keep the rest of the string for the next iteration.
        CASE
            WHEN INSTR(Name, ' ') > 0 THEN SUBSTR(Name, INSTR(Name, ' ') + 1)
            ELSE ''
        END AS RemainingName
    FROM
        tracks

    UNION ALL

    -- Recursive Member: This part refers to the CTE itself.
    -- It takes the `RemainingName` from the previous step and repeats the process.
    SELECT
        TrackId,
        Name,
        CASE
            WHEN INSTR(RemainingName, ' ') > 0 THEN SUBSTR(RemainingName, 1, INSTR(RemainingName, ' ') - 1)
            ELSE RemainingName
        END AS Word,
        CASE
            WHEN INSTR(RemainingName, ' ') > 0 THEN SUBSTR(RemainingName, INSTR(RemainingName, ' ') + 1)
            ELSE ''
        END AS RemainingName
    FROM
        WordSplit
    WHERE
        RemainingName != '' -- The recursion stops when there's nothing left to split.
)

-- Step 2: Now, we can query the CTE to get the word counts.
-- We will clean the words by making them lowercase and removing common punctuation.
SELECT
    LOWER(TRIM(REPLACE(REPLACE(Word, '(', ''), ')', ''))) AS CleanedWord,
    COUNT(*) AS WordFrequency
FROM
    WordSplit
WHERE
    CleanedWord != '' -- Exclude any empty strings that might result from splitting.
GROUP BY
    CleanedWord
ORDER BY
    WordFrequency DESC
LIMIT 20; -- Show the top 20 most frequent words.

-- Note on Function Compatibility:
-- `INSTR(string, substring)` finds the position of a substring. In SQL Server, use `CHARINDEX(substring, string)`.
-- `SUBSTR(string, start, length)` extracts a substring. In SQL Server, use `SUBSTRING(string, start, length)`.
-- `RECURSIVE` keyword is not needed in SQL Server (`WITH WordSplit AS (...)`).

---------------------------------------------------------------------------------------------------

-- Section 3: Simpler Methods in Other SQL Dialects

-- Some database systems make this much easier with built-in functions.

-- PostgreSQL Example:
-- SELECT
--     LOWER(Word) AS CleanedWord,
--     COUNT(*) AS WordFrequency
-- FROM
--     tracks,
--     unnest(string_to_array(Name, ' ')) AS Word
-- GROUP BY
--     CleanedWord
-- ORDER BY
--     WordFrequency DESC
-- LIMIT 20;

-- Google BigQuery Example:
-- SELECT
--     LOWER(Word) AS CleanedWord,
--     COUNT(*) AS WordFrequency
-- FROM
--     `project.dataset.tracks`,
--     UNNEST(SPLIT(Name, ' ')) AS Word
-- GROUP BY
--     CleanedWord
-- ORDER BY
--     WordFrequency DESC
-- LIMIT 20;

-- Snowflake Example:
-- SELECT
--     LOWER(value) AS CleanedWord,
--     COUNT(*) AS WordFrequency
-- FROM
--     tracks,
--     TABLE(SPLIT_TO_TABLE(Name, ' '))
-- GROUP BY
--     CleanedWord
-- ORDER BY
--     WordFrequency DESC
-- LIMIT 20;

-- This script illustrates that while complex text processing is possible in standard SQL,
-- it often requires advanced techniques. Modern data platforms typically provide more
-- convenient functions for these tasks.
