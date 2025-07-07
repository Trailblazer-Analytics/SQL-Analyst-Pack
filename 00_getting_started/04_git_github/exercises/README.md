# 🐙 Git & GitHub Exercises

Practice version control workflows specifically designed for SQL analysts.

---

## 🎯 Learning Objectives

After completing these exercises, you will:
- **Set up Git** for your analysis projects
- **Track SQL query versions** effectively
- **Collaborate** with team members using GitHub
- **Organize analysis projects** with proper structure
- **Use branching** for experimental analysis

---

## 🗃️ Module-Specific Exercises

These exercises focus on **Git and GitHub workflows** for SQL analysts.

---

## 🟢 Beginner: Git Fundamentals

### Exercise 1: First Analysis Repository
**Scenario**: Start tracking your SQL analysis work with version control.

**Tasks**:
1. Create a new folder called `customer-analysis`
2. Initialize a Git repository
3. Create a README.md with project description
4. Add your first SQL query file
5. Make your first commit with a clear message

**Skills**: `git init`, `git add`, `git commit`

---

### Exercise 2: Query Version Control
**Scenario**: Track changes to your sales analysis query as requirements evolve.

**Tasks**:
1. Create `sales_monthly_report.sql` with basic SELECT
2. Commit the initial version
3. Add GROUP BY and aggregation functions
4. Commit the updated version
5. Use `git log` to view your commit history

**Skills**: Iterative development, commit messages, `git log`

---

### Exercise 3: Project Organization
**Scenario**: Structure your analysis project for team collaboration.

**Tasks**:
1. Create folder structure: `queries/`, `results/`, `documentation/`
2. Add appropriate SQL files to each folder
3. Create a `.gitignore` file for analyst workflows
4. Commit the organized structure
5. Verify files are properly tracked/ignored

**Skills**: Project structure, `.gitignore`, file organization

---

## 🟡 Intermediate: GitHub Collaboration

### Exercise 4: GitHub Repository Setup
**Scenario**: Share your analysis project with team members.

**Tasks**:
1. Create a GitHub account (if you don't have one)
2. Create a new repository on GitHub
3. Connect your local repository to GitHub
4. Push your existing commits to GitHub
5. Add a descriptive README on GitHub

**Skills**: `git remote`, `git push`, GitHub interface

---

### Exercise 5: Branching for Analysis
**Scenario**: Experiment with different analysis approaches without affecting main work.

**Tasks**:
1. Create a branch called `feature/cohort-analysis`
2. Develop customer cohort analysis queries
3. Commit your work on the branch
4. Switch back to main and create another branch
5. Merge your completed analysis back to main

**Skills**: `git branch`, `git checkout`, `git merge`

---

### Exercise 6: Pull Request Workflow
**Scenario**: Collaborate with team members on quarterly reporting.

**Tasks**:
1. Fork a shared analysis repository (or use a test repo)
2. Create a branch for your contribution
3. Add quarterly KPI analysis queries
4. Push your branch to GitHub
5. Create a Pull Request with clear description

**Skills**: Forking, Pull Requests, collaborative review

---

## 🔴 Advanced: Professional Workflows

### Exercise 7: Code Review Process
**Scenario**: Implement professional code review for SQL analysis.

**Tasks**:
1. Review a teammate's SQL query Pull Request
2. Provide constructive feedback on query logic
3. Suggest performance improvements
4. Approve and merge after addressing feedback
5. Document the review process

**Skills**: Code review, constructive feedback, quality assurance

---

### Exercise 8: Analysis Documentation
**Scenario**: Create comprehensive documentation for your analysis project.

**Tasks**:
1. Write detailed README with project overview
2. Document each SQL query's purpose and logic
3. Create a CHANGELOG for version tracking
4. Add data dictionary and business context
5. Use GitHub Pages to publish documentation

**Skills**: Technical writing, documentation, knowledge sharing

---

## 💡 Git Templates for Analysts

### Repository Structure
```
analysis-project/
├── README.md
├── .gitignore
├── queries/
│   ├── exploratory/
│   ├── reporting/
│   └── ad_hoc/
├── documentation/
└── results/ (gitignored)
```

### Commit Message Templates
```bash
# Feature: Add new analysis
git commit -m "Add customer churn analysis for marketing team"

# Fix: Correct existing query
git commit -m "Fix date filter in monthly revenue query"

# Update: Modify existing analysis
git commit -m "Update KPI dashboard to include Q4 metrics"

# Docs: Documentation changes
git commit -m "Add documentation for sales analysis workflow"
```

### .gitignore for SQL Analysts
```gitignore
# Data files
*.csv
*.xlsx
data/
exports/

# Sensitive files
*.env
connections.ini

# Results
results/
temp/

# System files
.DS_Store
Thumbs.db
```

---

## 🎯 Success Metrics

- **Beginner (1-3)**: Complete in 30-45 minutes each
- **Intermediate (4-6)**: Complete in 45-60 minutes each  
- **Advanced (7-8)**: Complete in 60-90 minutes each

---

## 🔗 Next Steps

After mastering Git & GitHub:
- Apply version control to all your analysis projects
- Practice collaborative workflows with team members
- Explore advanced Git features (rebasing, cherry-picking)
- Set up automated workflows with GitHub Actions

---

*Version control is a superpower for professional analysts!* 🚀
