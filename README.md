# 📊 SQL Analyst Pack: Git-Based Learning Course

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![SQL](https://img.shields.io/badge/SQL-Multi--Dialect-blue.svg)](https://en.wikipedia.org/wiki/SQL)
[![GitHub Classroom](https://img.shields.io/badge/GitHub-Classroom%20Ready-blue.svg)](https://classroom.github.com/)

> **A comprehensive Git-based learning course designed specifically for SQL analysts to master data analysis through hands-on, version-controlled practice.**

This course uses Git workflows to teach SQL analysis skills progressively. Each module builds your expertise while teaching you professional version control practices used in data teams worldwide.

## 🚀 **START HERE: Choose Your Path**

### ⚡ **Too Busy? 2-Minute Quick Start**
1. **Fork this repository** (click Fork button above)
2. **Go to:** [Day 1 Survival Guide](./00_getting_started/DAY_1_SURVIVAL_GUIDE.md)
3. **Copy-paste** the first SQL query and start analyzing data

---

### 👶 **New to SQL?** ("I've never written a query")
**→ [Complete Beginner's Guide](./00_getting_started/NEW_TO_SQL_GUIDE.md)**  
*8-week structured learning plan from zero to analyst*

### 💼 **New SQL Analyst?** ("I know some SQL but new to the role")  
**→ [Day 1 Survival Guide](./00_getting_started/DAY_1_SURVIVAL_GUIDE.md)**  
*Get productive in your first week on the job*

### 🔄 **Experienced Analyst?** ("I need to refresh/advance my skills")
**→ [Analytics Pro Refresher](./00_getting_started/ANALYTICS_PRO_REFRESHER.md)**  
*Quick assessment and custom learning paths*

### 🎓 **Instructor/Team Lead?**
**→ [Getting Started Guide](./00_getting_started/README.md)**  
*Setup guide and curriculum overview*

---

## 📋 **Before You Begin: Get Your Copy**

**⚠️ IMPORTANT: You need your own copy to complete exercises and track progress!**

### For Learning (Recommended)
1. **[Create a GitHub account](https://github.com/join)** if you don't have one
2. **Fork this repository** - Click the "Fork" button at the top of this page
3. **Clone YOUR fork** to your computer
4. **Follow your chosen path above**

### For Instructors  
- Use **[GitHub Classroom](https://classroom.github.com/)** to distribute assignments
- Students get their own repositories automatically
- Track progress through commit history

## 🎯 Course Audience

**Primary Focus: SQL Analysts** (Not Data Engineers)

- **Beginner Analysts** - Learn SQL fundamentals with Git best practices
- **Business Analysts** - Master analytical SQL with professional workflows  
- **Reporting Specialists** - Advanced techniques for business intelligence
- **Self-Learners** - Structured, self-paced learning with clear progression
- **Students** - Perfect for GitHub Classroom assignments and projects
- **Instructors** - Ready-to-use curriculum with Git-based assessments

## 🗺️ Learning Path

### 📚 [00_getting_started](./00_getting_started/) - Environment & Git Setup

**Time:** 2-3 hours | **Level:** Anyone  

- Set up your SQL development environment
- Learn Git workflows for data analysis projects
- **[Day 1 Survival Guide](./00_getting_started/DAY_1_SURVIVAL_GUIDE.md)** - What to do your first week as an analyst
- **[Business SQL Patterns](./00_getting_started/BUSINESS_SQL_PATTERNS.md)** - 8 essential templates for immediate productivity

### 📖 [01_foundations](./01_foundations/) - SQL Analysis Fundamentals

**Time:** 3-4 weeks | **Level:** Beginner  

- **Basic Queries**: SELECT, WHERE, filtering for business insights
- **Data Profiling**: Explore and understand business datasets
- **Data Cleaning**: Handle real-world data quality issues analysts face daily

### 📊 [02_intermediate](./02_intermediate/) - Business Analysis Techniques

**Time:** 4-6 weeks | **Level:** Intermediate  

- **Aggregation**: Create summaries and business metrics
- **Window Functions**: Rankings, running totals, period-over-period analysis
- **Date/Time Analysis**: Time series, seasonal trends, business calendar analysis
- **Text Analysis**: Parse and analyze text data for insights

### 🚀 [03_advanced](./03_advanced/) - Advanced Analytics for Analysts

**Time:** 6-8 weeks | **Level:** Advanced  

- **Performance Tuning**: Optimize queries for large business datasets
- **Advanced Analytics**: Statistical functions, cohort analysis, forecasting
- **Cloud Platforms**: Modern analytics platforms (BigQuery, Snowflake, etc.)

### 🔧 [04_real_world](./04_real_world/) - Business Intelligence Scenarios

**Time:** Ongoing | **Level:** Professional  

- **Business Intelligence**: Dashboards, KPIs, automated reporting
- **Marketing Analytics**: Customer segmentation, campaign analysis
- **Sales Analytics**: Pipeline analysis, performance metrics
- **Financial Reporting**: P&L analysis, budget vs. actual reporting
- **Operations Analytics**: Process optimization and monitoring

### 🐍 [05_python_integration](./05_python_integration/) - Modern Analyst Toolkit

**Time:** 4-6 weeks | **Level:** Intermediate to Advanced  

- **Data Workflows**: Combine SQL with Python for complete analysis
- **Automation**: Schedule reports and data pipelines
- **Visualization**: Create charts and dashboards programmatically

## 🚀 Quick Start

### 🔥 **Immediate Value (5 minutes)**
New to SQL or need results today? Start here:
- **[Day 1 Survival Guide](./00_getting_started/DAY_1_SURVIVAL_GUIDE.md)** - Your first week as a SQL analyst
- **[Business SQL Patterns](./00_getting_started/BUSINESS_SQL_PATTERNS.md)** - 8 copy-paste templates for instant productivity

### For Self-Paced Learners

```bash
# 1. Fork this repository to your GitHub account
# 2. Clone your fork locally
git clone https://github.com/YOUR-USERNAME/SQL-Analyst-Pack.git
cd SQL-Analyst-Pack

# 3. Set up your environment (see SETUP.md for details)
# 4. Create your first learning branch
git checkout -b learning-foundations
```

### For GitHub Classroom

- Accept your instructor's assignment invitation
- Your repository will be automatically created
- Clone and follow the same workflow above

## 🔄 Git-Based Learning Workflow

### Basic Workflow

1. **📖 Read the lesson** in the module folder
2. **🌿 Create a branch** for your exercises: `git checkout -b module-topic`
3. **💻 Work through exercises** at your own pace
4. **📝 Commit your progress** regularly with descriptive messages
5. **🔀 Push and merge** when ready to move to the next lesson

### Example: Complete First Module

```bash
# Start the foundations module
git checkout -b foundations-basic-queries

# Navigate to the lesson
cd 01_foundations/01_basic_queries/

# Create your first SQL file
echo "-- My first business query
SELECT customer_name, total_spent 
FROM customers 
WHERE registration_date >= '2024-01-01';" > my_first_query.sql

# Commit your work
git add .
git commit -m "First SQL query: Customer analysis since 2024"

# Push to showcase your work
git push origin foundations-basic-queries
```

## 📚 Course Resources

### Core Learning Materials

- **[Getting Started Guide](./00_getting_started/README.md)** – Setup and Git workflow for analysts
- **[Foundations](./01_foundations/README.md)** – Essential SQL for business analysis  
- **[Intermediate](./02_intermediate/README.md)** – Advanced querying for insights
- **[Advanced](./03_advanced/README.md)** – Performance and complex analytics
- **[Real World](./04_real_world/README.md)** – Business scenarios and case studies
- **[Python Integration](./05_python_integration/README.md)** – Modern analyst workflows

### Practice & Reference

- **[Module Exercises](./01_foundations/README.md)** – Hands-on challenges with Git workflows
- **[Sample Database](./sample_database/README.md)** – Complete business datasets
- **[SQL Snippets Reference](./00_getting_started/SQL_SNIPPETS_REFERENCE.md)** – Common patterns and templates
- **[SQL Style Guide](./SQL_STYLE_GUIDE.md)** – Best practices for readable analytical SQL
- **[FAQ](./FAQ.md)** – Common questions and troubleshooting
- **[Glossary](./GLOSSARY.md)** – SQL terminology reference

## 🔧 Setup

Before you begin, please follow the instructions in the [**Setup Guide**](./SETUP.md) to set up the sample database.

## 💬 Community & Support

### 🙏 **Say Thank You**
- ⭐ **Star this repository** to show your support and help others discover it
- 🐦 **Share on social media** using #SQLAnalystPack  
- 💼 **Add to your LinkedIn** as a skill or project
- 📝 **Write a review** or testimonial in our [discussions](../../discussions)

### 🆘 **Get Help**
- 🐛 **Found a bug?** [Open an issue](../../issues/new)
- 💡 **Have an idea?** [Request a feature](../../issues/new)
- ❓ **Need help?** Check our [FAQ](./FAQ.md) or start a [discussion](../../discussions)
- 💬 **Join the community** in [GitHub Discussions](../../discussions)

### 🤝 **Contribute Back**
- 📚 **Improve content** - Fix typos, add examples, enhance explanations
- 🌍 **Translate materials** - Help make this accessible globally  
- 📖 **Share your analysis projects** - Inspire others with your work
- 🎓 **Become a mentor** - Help other learners in discussions
- 💻 **Add new SQL patterns** - Contribute business-focused templates

*See our [Contributing Guide](./CONTRIBUTING.md) for details on how to help.*

### 🏢 **For Organizations**
- 📊 **Training teams?** This course is perfect for onboarding new analysts
- 🎓 **Teaching SQL?** Use GitHub Classroom for seamless assignment distribution
- 💼 **Hiring analysts?** Use exercises as practical interview assessments
- 🤝 **Want to sponsor?** Contact us about supporting SQL education

---

**Happy Querying!** 📊✨

*This repository is maintained by the SQL Analyst Pack community. All contributors welcome!*
