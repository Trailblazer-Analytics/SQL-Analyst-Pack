# Author Update Instructions

## 🔧 How to Update Author Information

To update all SQL and Python files in the SQL Analyst Pack with your name as the author, follow these simple steps:

### Option 1: PowerShell Script (Recommended)

1. **Open PowerShell** in the SQL-Analyst-Pack directory
2. **Run the update script** with your name:

```powershell
# Replace "Your Name" with your actual name
.\scripts\update_author.ps1 -AuthorName "Your Name"
```

**Examples:**
```powershell
# Single name
.\scripts\update_author.ps1 -AuthorName "John Smith"

# With title/company
.\scripts\update_author.ps1 -AuthorName "Jane Doe, Senior Data Analyst"

# With GitHub username
.\scripts\update_author.ps1 -AuthorName "@yourusername"
```

### Option 2: Manual Find & Replace

If you prefer manual control, you can use your editor's find & replace feature:

**Find these patterns and replace with your name:**
- `Author      : SQL Analyst Pack Contributors`
- `Author      : GitHub Copilot`
- `Author      : {{Your Name}}`
- `Author      : [Your Name]`

### What Gets Updated

The script will update:
- ✅ All SQL files (*.sql) - Author field in headers
- ✅ All Python files (*.py) - Author field in docstrings  
- ✅ Updated date to today's date
- ✅ Maintains all other header information

### Files Excluded

- ❌ Files in `_archive/` directory (historical content)
- ❌ Third-party sample data files (preserves original attribution)

### Verification

After running the script, you can verify the changes by checking a few files:
```bash
# Check a sample file
head -10 01_foundations/01_basic_queries/01_basic_where_filtering.sql
```

You should see your name in the `Author` field!

## 📝 Template for New Files

When creating new SQL files, use this header template:

```sql
/*
    File        : path/to/your/file.sql
    Topic       : Your Topic Here
    Purpose     : What this script demonstrates or solves
    Author      : Your Name
    Created     : 2025-06-23
    Updated     : 2025-06-23
    Database    : Target database (e.g., Chinook, ecommerce)
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ SQLite | ✅ BigQuery
    
    Prerequisites:
    - List any requirements here
    
    What You'll Learn:
    - Key concepts covered
    - Skills developed
*/
```

---

**Ready to claim ownership of your SQL Analyst Pack! 🚀**
