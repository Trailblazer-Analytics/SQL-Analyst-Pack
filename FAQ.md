# 🙋 Frequently Asked Questions (FAQ)

## 🚀 **Getting Started**

### Q: I'm completely new to SQL. Where should I start?

**A:** Perfect! Start with our [Getting Started Guide](./00_getting_started/README.md) to set up your environment, then begin with [01_foundations](./01_foundations/). The learning path is designed to take you from complete beginner to advanced analyst.

### Q: Do I need to install a database to use this project?

**A:** Yes, but we make it easy! We provide multiple options:

- **Docker setup** (recommended): `docker-compose up -d`
- **Local PostgreSQL** installation
- **Cloud database** options (Supabase, AWS RDS)
- **SQLite** for lightweight local development

Follow our [Setup Guide](./SETUP.md) for step-by-step instructions.

### Q: Which SQL dialect should I learn first?

**A:** We recommend **PostgreSQL** as it's feature-rich, open-source, and widely used. However, start with the dialect your workplace uses. Our materials cover:

- PostgreSQL (primary focus)
- MySQL
- SQL Server
- SQLite
- BigQuery

## 🛠️ **Technical Issues**

### Q: I'm getting syntax errors when running the scripts. What's wrong?

**A:** Common causes:

- **Wrong SQL dialect**: Check the compatibility notes in each script header
- **Missing sample data**: Ensure you've loaded the sample databases correctly
- **Outdated database version**: Some features require recent versions
- **Copy-paste issues**: Make sure to copy complete statements

### Q: The script works in one database but not another. Why?

**A:** SQL dialects have differences in:

- **Date functions** (`EXTRACT` vs `DATEPART` vs `strftime`)
- **String concatenation** (`||` vs `CONCAT` vs `+`)
- **Window function syntax** and availability
- **JSON support** and functions
- **Recursive CTE** support

Look for dialect-specific notes in the script comments and our [Compatibility Guide](./reference/compatibility_guide.md).

### Q: How do I fix "table doesn't exist" errors?

**A:** Ensure you:

1. Loaded the sample databases using `setup_postgresql.sql`
2. Are connected to the correct database
3. Use the correct table names (case-sensitive in some databases)
4. Have the necessary permissions to access tables

### Q: The Docker setup isn't working. What should I do?

**A:** Try these troubleshooting steps:

1. Ensure Docker is running: `docker --version`
2. Check port availability: Make sure ports 5432 and 8080 are free
3. Review logs: `docker-compose logs`
4. Reset containers: `docker-compose down` then `docker-compose up -d`
5. Check our [Troubleshooting Guide](./00_getting_started/troubleshooting.md)

## 📚 **Learning Path**

### Q: Can I skip sections or jump around?

**A:** While the sections build on each other, you can focus on specific areas. However, we recommend completing 01-04 before jumping to advanced topics.

### Q: How long does it take to complete the entire learning path?

**A:** Depends on your background:

- **Complete beginner**: 2-3 months with regular practice
- **Some SQL experience**: 3-4 weeks
- **Experienced analyst**: 1-2 weeks for review and advanced topics

### Q: Are there practice exercises?

**A:** Currently, the scripts contain examples you can modify. Practice exercises are planned for v2.1 (see [Roadmap](./ROADMAP.md)).

## 🔍 **Understanding the Scripts**

### Q: What does the script header mean?

**A:** Each script header includes:

- **Purpose**: What the script demonstrates
- **SQL Flavors**: Compatibility with different databases (✅ = works, ⚠️ = needs edits, ⛔ = not supported)
- **Notes**: Important assumptions or prerequisites

### Q: What's the difference between snippets and full scripts?

**A:**

- **Full scripts** (in sql-training folders): Complete tutorials with explanations
- **Snippets** (in templates folder): Copy-paste ready code for common tasks

### Q: How do I adapt scripts for my own data?

**A:**

1. Replace table and column names with your own
2. Modify the `WHERE` clauses for your filters
3. Adjust data types as needed
4. Test thoroughly before using in production

## 🏢 **Real-World Application**

### Q: Are these scripts production-ready?

**A:** The techniques are production-ready, but scripts should be adapted for your environment:

- Add proper error handling
- Include performance optimizations for large datasets
- Add security considerations (avoid hardcoded values)
- Test thoroughly with your data

### Q: How do I handle large datasets?

**A:** See the [Performance Tuning](./sql-training/08_performance-tuning/) section for:

- Index optimization
- Query plan analysis
- Efficient JOIN strategies
- LIMIT and pagination techniques

### Q: Can I use these with cloud databases (AWS, Azure, GCP)?

**A:** Yes! Most scripts work with cloud databases:

- **AWS Redshift**: PostgreSQL-compatible
- **Azure SQL Database**: SQL Server-compatible
- **Google BigQuery**: Has some unique syntax (noted in scripts)
- **Snowflake**: Most features supported

## 🤝 **Contributing**

### Q: I found an error in a script. How do I report it?

**A:** Please [open an issue](https://github.com/your-username/SQL-Analyst-Pack/issues) with:

- Which script has the problem
- Your database platform
- Error message
- Expected vs actual behavior

### Q: Can I contribute my own scripts?

**A:** Absolutely! See our [Contributing Guide](./CONTRIBUTING.md) for:

- Style guidelines
- How to structure your contribution
- Pull request process

### Q: I have an idea for a new section. Where do I suggest it?

**A:** [Open a feature request](https://github.com/your-username/SQL-Analyst-Pack/issues) or start a [discussion](https://github.com/your-username/SQL-Analyst-Pack/discussions). We love new ideas!

## 🎯 **Career Development**

### Q: Will this help me get a data analyst job?

**A:** Yes! This project covers:

- **Core SQL skills** required for most analyst roles
- **Real-world patterns** you'll use daily
- **Best practices** that show professional competence
- **Portfolio projects** you can discuss in interviews

### Q: What should I learn after completing this project?

**A:** Consider expanding into:

- **Python/R** for advanced analytics
- **Data visualization** tools (Tableau, Power BI)
- **Statistical analysis** and machine learning
- **Cloud platforms** and big data tools
- **Domain expertise** in your industry of interest

### Q: Can I use this project in my portfolio?

**A:** Yes! You can:

- Fork the repository and add your own scripts
- Create case studies using the techniques
- Write blog posts about your learning journey
- Share your solutions to real problems

## 🆘 **Still Need Help?**

- 💬 **General questions**: Start a [discussion](https://github.com/your-username/SQL-Analyst-Pack/discussions)
- 🐛 **Bug reports**: [Open an issue](https://github.com/your-username/SQL-Analyst-Pack/issues)
- 📧 **Direct contact**: See the [README](./README.md) for maintainer information

---

*Don't see your question here? We'd love to add it! Open an issue or discussion with your question.*
