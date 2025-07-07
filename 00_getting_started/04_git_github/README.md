# 🐙 Git & GitHub for SQL Analysts

Learn version control and collaboration essentials for modern data analysis workflows.

## 🎯 Why Git for Analysts?

As a SQL analyst, you'll be:
- **Saving query versions** and tracking changes
- **Collaborating** with team members on analysis projects
- **Backing up work** and preventing data loss
- **Documenting analysis** with clear commit messages
- **Managing different versions** of reports and dashboards

---

## 🚀 Getting Started

### Install Git

**Windows:**
1. Download from [git-scm.com](https://git-scm.com/download/win)
2. Run installer with default settings
3. Verify: Open PowerShell and type `git --version`

**Mac:**
```bash
# Install using Homebrew
brew install git

# Or download from git-scm.com
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt install git

# CentOS/RHEL
sudo yum install git
```

### First-Time Setup

```bash
# Set your identity (use your real name and email)
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"

# Set default branch name
git config --global init.defaultBranch main

# Verify setup
git config --list
```

---

## 📁 Project Organization for Analysts

### Recommended Folder Structure

```
your-analysis-project/
├── README.md                 # Project overview
├── queries/                  # SQL files organized by topic
│   ├── data_exploration/
│   ├── weekly_reports/
│   └── ad_hoc_analysis/
├── results/                  # Query outputs, charts
├── documentation/            # Analysis documentation
└── .gitignore               # Files to exclude from Git
```

### Create Your First Repository

```bash
# Create a new project folder
mkdir my-sql-analysis
cd my-sql-analysis

# Initialize Git repository
git init

# Create your first file
echo "# My SQL Analysis Project" > README.md

# Add file to Git
git add README.md

# Make your first commit
git commit -m "Initial commit: Add README"
```

---

## 🔄 Basic Git Workflow for Analysts

### Daily Workflow

```bash
# 1. Check status of your files
git status

# 2. Add new or modified SQL files
git add queries/sales_analysis.sql
# Or add all files at once
git add .

# 3. Commit with descriptive message
git commit -m "Add weekly sales trend analysis query"

# 4. View your commit history
git log --oneline
```

### Working with SQL Files

```bash
# Add a new analysis query
git add queries/customer_segmentation.sql
git commit -m "Add customer RFM segmentation analysis"

# Modify an existing query
git add queries/sales_analysis.sql
git commit -m "Update sales query to include returns data"

# See what changed in a file
git diff queries/sales_analysis.sql
```

---

## 🌐 GitHub for Collaboration

### Create a GitHub Account

1. Go to [github.com](https://github.com)
2. Sign up with your work email
3. Choose a professional username
4. Verify your email address

### Connect Local Repository to GitHub

```bash
# Create repository on GitHub first, then:

# Add GitHub as remote origin
git remote add origin https://github.com/yourusername/your-analysis-project.git

# Push your code to GitHub
git push -u origin main
```

### Clone an Existing Repository

```bash
# Clone the SQL Analyst Pack (example)
git clone https://github.com/your-company/sql-analyst-pack.git

# Navigate to the project
cd sql-analyst-pack

# Start working with the files
```

---

## 🔀 Branching for Analysis Projects

### Why Use Branches?

- **Experiment safely** without affecting main analysis
- **Work on different projects** simultaneously
- **Collaborate** without conflicts
- **Test new approaches** before finalizing

### Basic Branching

```bash
# Create and switch to new branch
git checkout -b feature/customer-analysis

# Work on your analysis...
git add queries/customer_analysis.sql
git commit -m "Add customer behavior analysis"

# Switch back to main branch
git checkout main

# Merge your completed analysis
git merge feature/customer-analysis

# Delete the feature branch
git branch -d feature/customer-analysis
```

---

## 📝 Best Practices for SQL Analysts

### Commit Message Guidelines

**Good Examples:**
```bash
git commit -m "Add quarterly revenue analysis for finance team"
git commit -m "Fix date filter in customer retention query"
git commit -m "Update dashboard query to include new product categories"
```

**Bad Examples:**
```bash
git commit -m "update"
git commit -m "fixes"
git commit -m "stuff"
```

### What to Track in Git

**✅ DO track:**
- SQL query files (.sql)
- Documentation files (.md, .txt)
- Configuration files
- Analysis scripts (.py, .r)
- README files

**❌ DON'T track:**
- Large data files (.csv, .xlsx with data)
- Database connection files with passwords
- Temporary files (.tmp, .log)
- Personal notes with sensitive information

### .gitignore for Analysts

Create a `.gitignore` file:

```gitignore
# Data files (too large or sensitive)
*.csv
*.xlsx
*.xls
data/
exports/

# Database connections
*.env
config.ini
connections.json

# Temporary files
*.tmp
*.log
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/

# Results that change frequently
results/temp/
```

---

## 👥 Collaboration Workflows

### Pull Requests (PRs)

1. **Create a branch** for your analysis
2. **Complete your work** and commit changes
3. **Push branch** to GitHub
4. **Create Pull Request** for review
5. **Address feedback** from team members
6. **Merge** once approved

```bash
# Example workflow
git checkout -b analysis/monthly-kpis
# ... do your work ...
git add .
git commit -m "Add monthly KPI dashboard queries"
git push origin analysis/monthly-kpis
# Create PR on GitHub website
```

### Code Review for SQL

**What to Review:**
- Query logic and correctness
- Performance considerations
- Code readability and comments
- Business logic accuracy
- Data security and privacy

---

## 🛠️ Tools Integration

### VS Code + Git

1. Install VS Code
2. Install Git extension
3. Open your project folder
4. Use built-in Git panel for commits

### GitHub Desktop

- Visual interface for Git operations
- Great for beginners
- Download from [desktop.github.com](https://desktop.github.com)

---

## 📚 Practical Exercises

### Exercise 1: Your First Analysis Repository

1. Create a new folder for analysis project
2. Initialize Git repository
3. Create README.md describing your project
4. Add a simple SQL query file
5. Make your first commit

### Exercise 2: Track Query Evolution

1. Create a sales analysis query
2. Commit the initial version
3. Modify the query to add new metrics
4. Commit the changes with descriptive message
5. Use `git log` to see your history

### Exercise 3: Collaborative Analysis

1. Fork a shared analysis repository
2. Create a branch for new analysis
3. Add your SQL queries
4. Create a pull request
5. Respond to feedback and merge

---

## 🔗 Additional Resources

- [Git Handbook](https://guides.github.com/introduction/git-handbook/)
- [GitHub Learning Lab](https://lab.github.com/)
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)
- [Pro Git Book](https://git-scm.com/book) (Free online)

---

## 🎯 Key Takeaways

- **Start simple**: Begin with basic add, commit, push workflow
- **Commit often**: Small, frequent commits are better than large ones
- **Write clear messages**: Your future self will thank you
- **Use branches**: Experiment safely without breaking main work
- **Collaborate**: Leverage team knowledge through code review

---

*Version control isn't just for developers - it's essential for professional data analysis!* 🚀
