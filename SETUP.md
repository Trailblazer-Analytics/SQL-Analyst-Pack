# Setup Guide

This guide provides instructions on how to set up the sample database for this project.

## Using the Chinook Sample Database

This project uses the Chinook sample database. The SQL script to create and populate this database is located in the `sample_database` directory.

### Steps to Set Up the Database

1. **Create a new database.** The name of the database can be `chinook`.
2. **Run the script.** Execute the `sample_database/chinook.sql` script in the new database to create the tables and insert the data.

## Recommended Editor: Visual Studio Code

For an integrated and user-friendly experience, we strongly recommend using **Visual Studio Code (VS Code)**, a free and powerful code editor from Microsoft. It offers excellent SQL support and can be extended to manage databases directly within the editor, which is how this guide is structured.

If you do not have it installed, you can [**download it for free here**](https://code.visualstudio.com/).

### Database Setup in VS Code

The following steps will guide you through setting up the database using a popular VS Code extension.

For the best experience, we recommend using the [**SQLite**](https://marketplace.visualstudio.com/items?itemName=alexcvzz.vscode-sqlite) extension for VS Code.

```vscode-extensions
alexcvzz.vscode-sqlite
```

**Instructions:**

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
