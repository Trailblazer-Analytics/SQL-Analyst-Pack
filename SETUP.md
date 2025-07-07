# 🛠️ Setup Guide: Git-Based SQL Learning Environment

**Time Required:** 15-20 minutes  
**Goal:** Set up everything you need for Git-based SQL analysis learning

## 🎯 Quick Setup Checklist

Before starting your SQL learning journey, you'll need:

- [ ] **Git installed** (for version control workflow)
- [ ] **Code editor** (VS Code recommended for SQL + Git integration)
- [ ] **Database system** (SQLite recommended for simplicity)
- [ ] **Sample data loaded** (business datasets for practice)
- [ ] **First Git repository** (your forked learning repository)

## 🚀 Fast Track Setup (15 minutes)

### Step 1: Install Git (2 minutes)
```bash
# Windows: Download from https://git-scm.com/
# macOS: git --version (will prompt install if needed)
# Linux: sudo apt install git

# Verify installation
git --version
```

### Step 2: Install VS Code + SQL Extensions (5 minutes)

1. **Download VS Code:** [code.visualstudio.com](https://code.visualstudio.com/)
2. **Install SQL Extensions:**
   - SQLite (by alexcvzz) - For database management
   - Git Graph - For visualizing your learning progress
   - SQL Formatter - For clean, readable queries

### Step 3: Fork & Clone This Repository (3 minutes)
```bash
# 1. Fork this repository on GitHub (click Fork button)
# 2. Clone YOUR fork
git clone https://github.com/YOUR-USERNAME/SQL-Analyst-Pack.git
cd SQL-Analyst-Pack

# 3. Verify you're ready for Git-based learning
git status
```

### Step 4: Set Up Sample Database (5 minutes)

**Option A: SQLite (Recommended for beginners)**

1. **Install the Extension**: Go to the Extensions view in VS Code (`Ctrl+Shift+X`) and search for `alexcvzz.vscode-sqlite`.
2. **Open the Command Palette**: (`Ctrl+Shift+P`).
3. **Select "SQLite: New Database"**: Type `SQLite: New Database` and press Enter.
4. **Save the Database**: Save the new database file as `chinook.db` in the root of this project.
5. **Open the Database**: The extension will automatically open the new database.
6. **Run the SQL Script**: Right-click on the `chinook.db` file in the explorer, select "Run Query", and then paste the entire contents of `sample_database/chinook.sql` into the editor and run it.
7. **Verify**: You should now see all the Chinook database tables in the SQLite Explorer view.

## 📝 **Alternative Database Setups**

### PostgreSQL Setup

1. Install PostgreSQL and create a new database called `chinook`
2. Use the [PostgreSQL version of Chinook](https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_PostgreSql.sql)
3. Install the [PostgreSQL extension](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-postgresql) for VS Code

### MySQL Setup

1. Install MySQL and create a new database called `chinook`
2. Use the [MySQL version of Chinook](https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_MySql.sql)
3. Install the [MySQL extension](https://marketplace.visualstudio.com/items?itemName=formulahendry.vscode-mysql) for VS Code

### SQL Server Setup

1. Install SQL Server (Express edition is free) and create a new database called `chinook`
2. Use the [SQL Server version of Chinook](https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_SqlServer.sql)
3. Install the [SQL Server extension](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql) for VS Code

## 🎯 **Next Steps**

Once your database is set up:

1. **Start with [01_foundations](./01_foundations/)** to test your setup
2. **Follow the learning path** in order for the best experience
3. **Practice regularly** - consistency is key to mastering SQL
4. **Join our community** by starring this repository and sharing your progress!

---

*Ready to become an SQL expert? Let's get started!* 🚀
