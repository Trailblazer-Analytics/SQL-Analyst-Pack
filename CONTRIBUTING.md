# Contributing to the SQL Analyst Pack

First off, thank you for considering contributing! Your help is essential for keeping this repository a valuable resource for the data analyst community.

## How to Contribute

1.  **Fork the repository** to your own GitHub account.
2.  **Create a new branch** for your changes (`git checkout -b feature/your-feature-name`).
3.  **Make your changes** and ensure they adhere to the style guide below.
4.  **Submit a pull request** with a clear description of your changes.

## Style Guide

To maintain consistency across the repository, please follow these style rules.

### Script Header

Every `.sql` file must begin with this header, fully filled out:

```sql
/*
    File        : {{PATH_FROM_REPO_ROOT}}
    Topic       : {{FOLDER_NAME_READABLE}}
    Purpose     : {{One-sentence description of what the script demonstrates}}
    Author      : Alexander Nykolaiszyn
    Created     : {{yyyy-mm-dd}}
    Updated     : {{yyyy-mm-dd}}
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ⛔ SQL Server | ⚠️ Oracle | ✅ SQLite | ⚠️ BigQuery | ✅ Snowflake
    -- Mark ✅ fully compatible, ⚠️ needs edits (explain below), ⛔ not supported.
    Notes       : • Short bullets on assumptions or prerequisites
                • Links to official docs (1 per flavor max)
*/
```

### Commenting

-   Use ANSI-standard syntax (`--` for single-line, `/* ... */` for multi-line) wherever possible.
-   Place comments **above** the line of code they refer to, not at the end of the line.
-   For complex logic, use C-style `/* ... */` blocks to explain the approach.
-   Include at least one sample query and a comment explaining the expected result.
-   Use flavor-tagged blocks for syntax that differs between database systems:

    ```sql
    -- POSTGRES ONLY
    --   ...explanation of the difference...
    ```

### Formatting

-   **Indentation**: Use tabs, which should be set to 4 spaces.
-   **Line Length**: Keep lines at or below 120 characters.
-   **Keywords**: Use uppercase for SQL keywords (`SELECT`, `FROM`, `WHERE`, etc.).

## Pull Request Process

1.  Ensure your code lints (if a linter is configured).
2.  Update the `README.md` and any relevant folder-level `README.md` files if you have added or removed scripts.
3.  Make sure your PR has a descriptive title and a clear summary of the changes.

Thank you for your contribution!
