# 📝 SQL Analyst Pack - Naming Conventions

## File Naming Standards

### SQL Files
All SQL files should follow this pattern:
```
##_descriptive_name.sql
```

- **Numbers**: Two-digit prefix (01, 02, 03, etc.)
- **Separator**: Underscore (`_`)
- **Description**: Clear, concise description using snake_case
- **Extension**: `.sql` (lowercase)

**Examples:**
- ✅ `01_basic_select_statements.sql`
- ✅ `02_filtering_with_where.sql`
- ✅ `03_joining_multiple_tables.sql`
- ❌ `basicSelectStatements.sql`
- ❌ `1_select.sql`
- ❌ `Advanced-Joins.SQL`

### Directory Naming
Directories should follow this pattern:
```
##_descriptive_name/
```

- **Numbers**: Two-digit prefix for ordering
- **Separator**: Underscore (`_`)
- **Description**: Clear, descriptive name using snake_case
- **No file extension**

**Examples:**
- ✅ `01_basic_queries/`
- ✅ `02_data_profiling/`
- ✅ `03_advanced_analytics/`
- ❌ `basicQueries/`
- ❌ `1_queries/`
- ❌ `Advanced-Analytics/`

### Documentation Files
- **README files**: `README.md` (all caps)
- **Documentation**: `descriptive_name.md` (snake_case)
- **Guides**: `descriptive_name.md`

**Examples:**
- ✅ `README.md`
- ✅ `troubleshooting.md`
- ✅ `installation_guide.md`
- ❌ `ReadMe.md`
- ❌ `troubleshooting-guide.md`

## Content Organization

### Module Structure
Each learning module should contain:
```
##_module_name/
├── README.md                    # Module overview and learning objectives
├── 01_first_concept.sql         # Progressive learning files
├── 02_second_concept.sql
├── ...
├── exercises/                   # Practice exercises
│   ├── README.md
│   ├── 01_exercise_name.sql
│   └── solutions/
│       └── 01_exercise_name_solution.sql
└── reference/                   # Quick reference materials
    ├── cheat_sheet.md
    └── common_patterns.sql
```

### Progressive Numbering
- **Foundations (01-03)**: 01-99 file numbering
- **Intermediate (04-07)**: Continue sequential numbering
- **Advanced (08-10)**: Continue sequential numbering
- **Real World (11+)**: Project-based numbering

## Special Files

### Configuration and Setup
- `setup_*.sql` - Database setup scripts
- `verify_*.sql` - Verification scripts
- `config_*.yml` - Configuration files
- `docker-compose.yml` - Docker configuration

### Sample Data
- `sample_*.sql` - Sample data scripts
- `*_dataset.csv` - CSV data files
- `chinook.sql` - Specific database samples

### Tools and Utilities
- `snippet_*.sql` - Reusable code snippets
- `utility_*.sql` - Utility functions
- `template_*.sql` - Template files

## Best Practices

### File Naming
1. **Be Descriptive**: File names should clearly indicate content
2. **Use Numbers**: Always use two-digit prefixes for ordering
3. **Consistent Case**: Always use lowercase with underscores
4. **Avoid Spaces**: Never use spaces in file or directory names
5. **Be Concise**: Keep names under 50 characters when possible

### Content Organization
1. **Progressive Learning**: Number files in learning order
2. **Logical Grouping**: Group related concepts in the same directory
3. **Clear Hierarchy**: Use subdirectories for sub-topics
4. **Consistent Structure**: Each module should follow the same pattern

## Validation

To check naming convention compliance, run:
```sql
-- Check for naming inconsistencies
SELECT 
    file_name,
    CASE 
        WHEN file_name ~ '^[0-9]{2}_[a-z0-9_]+\.sql$' THEN 'Valid'
        ELSE 'Invalid'
    END as naming_status
FROM files_list;
```

## Migration Notes

When renaming existing files:
1. Update any references in README files
2. Update file paths in documentation
3. Check for hardcoded paths in SQL comments
4. Update learning path documentation
5. Verify all links still work

---

**Last Updated:** June 22, 2025  
**Next Review:** Monthly
