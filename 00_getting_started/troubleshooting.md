# 🆘 Troubleshooting Guide

Common issues and solutions for the SQL Analyst Pack setup and learning environment.

## 🔧 Database Setup Issues

### PostgreSQL Connection Problems

**Problem:** Cannot connect to PostgreSQL database
```
FATAL: database "sql_analyst_pack" does not exist
```

**Solutions:**
1. **Create the database first:**
   ```bash
   createdb sql_analyst_pack
   ```

2. **Check if PostgreSQL is running:**
   ```bash
   # On Windows
   pg_ctl status
   
   # On macOS/Linux
   brew services list | grep postgresql
   systemctl status postgresql
   ```

3. **Verify connection parameters:**
   ```bash
   psql -h localhost -U postgres -l
   ```

### Docker Setup Issues

**Problem:** Docker containers won't start
```
ERROR: Cannot start service postgres
```

**Solutions:**
1. **Check Docker is running:**
   ```bash
   docker --version
   docker-compose --version
   ```

2. **Free up port 5432:**
   ```bash
   # Find what's using port 5432
   netstat -tulpn | grep 5432
   
   # Stop local PostgreSQL if running
   sudo systemctl stop postgresql
   ```

3. **Clean up previous containers:**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### Data Loading Errors

**Problem:** Setup script fails with syntax errors
```
ERROR: syntax error at or near "..."
```

**Solutions:**
1. **Check file encoding:** Ensure files are UTF-8 encoded
2. **Verify PostgreSQL version:** Some features require PostgreSQL 12+
3. **Run setup in correct order:**
   ```bash
   # First load Chinook
   psql sql_analyst_pack -f chinook.sql
   
   # Then load additional tables
   psql sql_analyst_pack -f setup_postgresql.sql
   ```

## 📊 Data Quality Issues

### Missing or Empty Tables

**Problem:** Tables exist but have no data
```sql
SELECT COUNT(*) FROM ecommerce_users; -- Returns 0
```

**Solutions:**
1. **Check if data generation completed:**
   ```sql
   SELECT tablename, n_live_tup as row_count 
   FROM pg_stat_user_tables 
   WHERE schemaname = 'public';
   ```

2. **Manually run data generation:**
   ```sql
   -- Re-run the INSERT statements from setup script
   INSERT INTO ecommerce_users (...) SELECT ...;
   ```

### Performance Issues

**Problem:** Queries are running very slowly

**Solutions:**
1. **Check if indexes exist:**
   ```sql
   SELECT indexname, tablename 
   FROM pg_indexes 
   WHERE schemaname = 'public';
   ```

2. **Analyze table statistics:**
   ```sql
   ANALYZE;
   ```

3. **Create missing indexes:**
   ```sql
   CREATE INDEX idx_orders_date ON ecommerce_orders(order_date);
   ```

## 🖥️ Environment Setup Issues

### VS Code SQL Extensions

**Problem:** SQL syntax highlighting not working

**Solutions:**
1. **Install recommended extensions:**
   - SQLTools
   - PostgreSQL (by Chris Kolkman)
   - SQL Formatter

2. **Configure workspace settings:**
   ```json
   {
     "sqltools.connections": [{
       "name": "SQL Analyst Pack",
       "driver": "PostgreSQL",
       "server": "localhost",
       "port": 5432,
       "database": "sql_analyst_pack",
       "username": "postgres"
     }]
   }
   ```

### Python-SQL Integration Issues

**Problem:** Cannot connect from Python to database
```python
ImportError: No module named 'psycopg2'
```

**Solutions:**
1. **Install required packages:**
   ```bash
   pip install psycopg2-binary sqlalchemy pandas
   ```

2. **Use correct connection string:**
   ```python
   import sqlalchemy
   engine = sqlalchemy.create_engine(
       'postgresql://analyst:learning123@localhost:5432/sql_analyst_pack'
   )
   ```

## 📚 Learning Path Issues

### Difficulty Understanding Concepts

**Problem:** SQL concepts seem overwhelming

**Solutions:**
1. **Start slower:** Take more time with foundations
2. **Use visual tools:** Draw out table relationships
3. **Practice more:** Repeat exercises until comfortable
4. **Ask for help:** Use GitHub Issues for questions

### Exercise Solutions Not Working

**Problem:** Exercise queries return errors or wrong results

**Solutions:**
1. **Check table names:** Ensure correct spelling and case
2. **Verify data exists:** Run COUNT(*) on tables first
3. **Review syntax:** Check for missing commas, parentheses
4. **Compare with examples:** Look at working queries first

## 🔍 Advanced Troubleshooting

### Log Analysis

**View PostgreSQL logs:**
```bash
# Find log location
SHOW log_directory;
SHOW log_filename;

# On typical installations
tail -f /var/log/postgresql/postgresql-15-main.log
```

### Performance Debugging

**Check query execution plans:**
```sql
EXPLAIN ANALYZE 
SELECT * FROM ecommerce_orders 
WHERE order_date >= '2024-01-01';
```

**Monitor active queries:**
```sql
SELECT 
    pid,
    state,
    query_start,
    LEFT(query, 50) as query_preview
FROM pg_stat_activity 
WHERE state = 'active';
```

## 🆘 Getting Additional Help

### Community Support
- **GitHub Issues:** Report bugs or ask questions
- **Discussions:** Share learning experiences
- **Wiki:** Community-contributed solutions

### Documentation Resources
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [SQL Tutorial Resources](../reference/learning_resources.md)
- [VS Code SQL Setup Guide](../tools_and_resources/vscode_setup.md)

### Expert Help
- **Office Hours:** Check schedule in main README
- **Mentorship Program:** Apply through GitHub Issues
- **Professional Support:** Contact information in CONTRIBUTING.md

## 🎯 Prevention Tips

### Before Starting
1. ✅ Verify system requirements
2. ✅ Test database connection
3. ✅ Run verification script
4. ✅ Backup important data

### Best Practices
1. **Work incrementally:** Test each section before moving on
2. **Keep notes:** Document what works and what doesn't
3. **Version control:** Use Git to track your progress
4. **Regular backups:** Export your work periodically

### Success Metrics
- All setup verification queries pass
- Can run basic SELECT statements without errors
- Sample data is accessible and makes sense
- Development environment is comfortable to use

---

**Still having issues?** Don't hesitate to open a GitHub Issue with:
1. Your operating system and version
2. PostgreSQL version (`SELECT version();`)
3. Exact error message
4. Steps you've already tried

We're here to help you succeed! 🚀
