# Contributing to the SQL Analyst Pack

First off, thank you for considering contributing! Your help is essential for keeping this repository a valuable resource for the data analyst community.

## 🎯 **What We're Looking For**

This repository focuses specifically on **SQL for analysts** - not database administration, engineering, or development. We welcome contributions that help analysts:

- 📊 **Analyze business data** more effectively
- 🧹 **Clean and profile datasets** for insights  
- 📈 **Create reports and dashboards** from SQL queries
- 🔍 **Solve real-world business problems** with data
- 📚 **Learn modern SQL practices** for analytics

## 🛠️ **Types of Contributions Welcome**

### 📝 **Content Improvements**

- Fix typos, grammar, or formatting issues
- Enhance explanations or add missing context
- Update outdated information or broken links
- Add real-world examples or use cases

### 🌍 **Translations & Accessibility**

- Translate content to other languages
- Improve accessibility (alt text, clearer headings)
- Add closed captions to any video content

### 💻 **SQL Content**

- Add new business-focused SQL patterns or templates
- Create additional exercises with solutions
- Contribute sample datasets for practice
- Add SQL snippets for common analyst tasks

### 📚 **Educational Materials**

- Write tutorials for specific analyst workflows
- Create cheat sheets or quick reference guides
- Add case studies from real business scenarios
- Improve learning path recommendations

## 🚀 **How to Contribute**

### **Option 1: Quick Fixes (Recommended)**

Perfect for typos, small improvements, or adding examples:

1. **Navigate to the file** you want to edit on GitHub
2. **Click the pencil icon** (✏️) to edit directly  
3. **Make your changes** in the web editor
4. **Scroll down** and describe your changes
5. **Click "Propose changes"** to create a pull request

### **Option 2: Larger Contributions**

For new content, multiple files, or complex changes:

1. **Fork the repository** to your own GitHub account
2. **Clone your fork** locally: `git clone https://github.com/yourusername/SQL-Analyst-Pack.git`
3. **Create a new branch**: `git checkout -b feature/your-feature-name`
4. **Make your changes** and ensure they follow our style guide below
5. **Test your changes** (run any SQL queries, check links work)
6. **Commit and push**: `git add . && git commit -m "Description" && git push origin feature/your-feature-name`
7. **Submit a pull request** with a clear description of your changes

### **Option 3: Discussions & Ideas**

- 💡 **Share ideas** in [GitHub Discussions](../../discussions)
- 🐛 **Report issues** using our [issue templates](../../issues/new/choose)  
- ❓ **Ask questions** about contributing or content

## 📋 **Content Guidelines**

### **📊 Analyst Focus**

All content should be relevant to SQL analysts, not database administrators or engineers:

- ✅ **Include**: Business analysis, reporting, data profiling, cleaning, insights
- ✅ **Include**: Common analyst workflows, dashboard queries, KPI calculations  
- ❌ **Avoid**: Database administration, performance tuning, infrastructure setup
- ❌ **Avoid**: Complex programming concepts not relevant to day-to-day analysis

### **🎯 Real-World Focus**

- Use **business-realistic scenarios** (sales, marketing, finance, operations)
- Include **common data quality issues** analysts actually encounter
- Provide **practical templates** that can be adapted to real work
- Focus on **insights and decision-making** rather than just technical syntax

### **📚 Learning-Oriented**

- Start with **clear learning objectives** for each lesson
- Include **multiple examples** showing the same concept in different contexts
- Provide **both solutions and explanations** for exercises
- Use **progressive difficulty** within each module

## 🎨 **Style Guide**

### **SQL File Headers**

Every `.sql` file must begin with this header:

```sql
/*
    File        : {{PATH_FROM_REPO_ROOT}}
    Topic       : {{FOLDER_NAME_READABLE}}
    Purpose     : {{One-sentence description of what the script demonstrates}}
    Author      : [Your Name] / SQL Analyst Pack Community
    Created     : {{yyyy-mm-dd}}
    Updated     : {{yyyy-mm-dd}}
    SQL Flavors : ✅ PostgreSQL | ✅ MySQL | ⛔ SQL Server | ⚠️ Oracle | ✅ SQLite | ⚠️ BigQuery | ✅ Snowflake
    -- Mark ✅ fully compatible, ⚠️ needs edits (explain below), ⛔ not supported.
    Notes       : • Short bullets on assumptions or prerequisites
                • Links to official docs (1 per flavor max)
*/
```

### **SQL Commenting Standards**

- Use ANSI-standard syntax (`--` for single-line, `/* ... */` for multi-line)
- Place comments **above** the line of code they refer to, not at the end
- For complex logic, use C-style `/* ... */` blocks to explain the approach
- Include at least one sample query and a comment explaining the expected result
- Use flavor-tagged blocks for database-specific syntax:

```sql
-- POSTGRES ONLY: Using ILIKE for case-insensitive matching
--   Other databases might use UPPER() or LOWER() functions
SELECT * FROM customers WHERE name ILIKE '%smith%';
```

### **SQL Formatting Standards**

- **Keywords**: Use UPPERCASE for SQL keywords (`SELECT`, `FROM`, `WHERE`, etc.)
- **Indentation**: Use 4 spaces (or tabs set to 4 spaces)
- **Line Length**: Keep lines at or below 120 characters
- **Alignment**: Align SELECT columns and JOIN conditions for readability

**Example of good formatting:**

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) as total_orders,
    SUM(o.order_amount) as total_spent
FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.registration_date >= '2023-01-01'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 5
ORDER BY total_spent DESC;
```

### **Markdown Standards**

- Use consistent heading hierarchy (H1 for title, H2 for main sections, etc.)
- Include blank lines around headings and lists for proper rendering
- Use code blocks with language specification (\`\`\`sql)
- Include emoji sparingly and consistently (📊 for data, 🎯 for goals, etc.)

## ⚖️ **What We DON'T Accept**

To maintain quality and focus, we don't accept:

- 🚫 **Database administration content** (server setup, user management, backups)
- 🚫 **Advanced programming concepts** (stored procedures, triggers, complex ETL)
- 🚫 **Promotional content** for specific tools, courses, or services
- 🚫 **Homework assignments** without educational context
- 🚫 **Incomplete contributions** without documentation or examples
- 🚫 **Content that duplicates existing materials** without adding value

## 🔄 **Pull Request Process**

### **Before Submitting**

1. **Test your SQL queries** against sample data to ensure they work
2. **Check all links** to make sure they're not broken
3. **Review spelling and grammar** (we recommend Grammarly or similar tools)
4. **Ensure proper formatting** follows our style guide above
5. **Update any relevant README files** if you've added or changed content

### **PR Requirements**

Your pull request should include:

- ✅ **Descriptive title** summarizing the changes
- ✅ **Clear description** explaining what you changed and why
- ✅ **Reference any related issues** (e.g., "Fixes #123")
- ✅ **Screenshots or examples** for visual changes
- ✅ **Updated documentation** if you've added new content

### **Review Process**

1. **Automated checks** will run to validate formatting and links
2. **Community review** from maintainers and other contributors
3. **Testing period** to ensure changes work across different environments
4. **Merge** once approved by maintainers

*We aim to review pull requests within 48-72 hours.*

## 🎓 **For Educators & Trainers**

### **Classroom Integration**

If you're adapting content for educational use:

- ✅ **Maintain attribution** to the SQL Analyst Pack community
- ✅ **Share improvements back** via pull requests when possible
- ✅ **Use GitHub Classroom** for seamless student distribution
- ✅ **Reference our setup guides** for consistent environments

### **Corporate Training**

For enterprise training programs:

- 📧 **Contact us** about bulk usage and customization needs
- 🤝 **Consider sponsoring** development of specific content areas
- 📚 **Share success stories** to help us improve the curriculum
- 🔄 **Contribute real-world scenarios** from your organization

## 🆘 **Getting Help**

### **Questions About Contributing**

- 💬 **Ask in discussions**: [GitHub Discussions](../../discussions)
- 📧 **Email maintainers**: For sensitive or complex questions
- 📖 **Check existing issues**: Someone might have asked already
- 🔍 **Search the documentation**: FAQ and troubleshooting guides

### **Technical Issues**

- 🐛 **Report bugs**: Use our [bug report template](../../issues/new?template=bug_report.md)
- 💡 **Request features**: Use our [feature request template](../../issues/new?template=feature_request.md)
- 🚀 **Suggest improvements**: Start a discussion first for major changes

---

## 🙏 **Thank You!**

Your contributions make this repository a valuable resource for the entire SQL analyst community. Whether you're fixing a typo, adding a new exercise, or translating content, every contribution matters.

**Happy contributing!** 📊✨

*This contributing guide is itself open to improvement - feel free to suggest changes!*
