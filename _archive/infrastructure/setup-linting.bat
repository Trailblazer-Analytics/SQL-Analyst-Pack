@echo off
REM Setup script for SQL code quality tools (Windows)
REM This script installs and configures SQLFluff and pre-commit hooks

echo 🔧 Setting up SQL Code Quality Tools
echo ====================================

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is required but not installed. Please install Python 3.8+.
    echo    Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python is available

REM Check if pip is available
python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ pip is required but not available.
    pause
    exit /b 1
)

echo ✅ pip is available

REM Install SQLFluff and related packages
echo 📦 Installing SQLFluff and dependencies...
python -m pip install --user sqlfluff[postgres] pre-commit sqlparse

REM Verify SQLFluff installation
python -m sqlfluff --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ SQLFluff installation failed
    pause
    exit /b 1
)

echo ✅ SQLFluff installed successfully

REM Install pre-commit hooks
echo 🪝 Installing pre-commit hooks...
python -m pre_commit install >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Pre-commit hooks installed
) else (
    echo ⚠️  Pre-commit hook installation had issues, but continuing...
)

REM Test SQLFluff configuration
echo 🧪 Testing SQLFluff configuration...
if exist ".sqlfluff\config" (
    echo ✅ SQLFluff configuration found
) else (
    echo ❌ SQLFluff configuration not found at .sqlfluff\config
    pause
    exit /b 1
)

REM Create Windows batch scripts for quick access
echo 📝 Creating convenience scripts...

REM Create lint script
(
echo @echo off
echo echo 🔍 Running SQL quality checks...
echo if "%%1"=="" ^(
echo     echo Checking all SQL files...
echo     python -m sqlfluff lint **/*.sql
echo ^) else ^(
echo     echo Checking specified files: %%*
echo     python -m sqlfluff lint %%*
echo ^)
) > lint-sql.bat

REM Create fix script
(
echo @echo off
echo echo 🔧 Auto-fixing SQL formatting...
echo if "%%1"=="" ^(
echo     echo Fixing all SQL files...
echo     python -m sqlfluff fix **/*.sql
echo ^) else ^(
echo     echo Fixing specified files: %%*
echo     python -m sqlfluff fix %%*
echo ^)
) > fix-sql.bat

REM Provide usage information
echo.
echo 🎉 SQL Code Quality Tools Setup Complete!
echo ========================================
echo.
echo 📋 Available Tools:
echo    SQLFluff:     Code linting and formatting
echo    Pre-commit:   Automatic checks before commits
echo    Custom hooks: Business logic validation
echo.
echo 🚀 Quick Usage:
echo    Lint all SQL:    lint-sql.bat
echo    Fix formatting:  fix-sql.bat
echo    Lint specific:   lint-sql.bat path\to\file.sql
echo    Manual SQLFluff: python -m sqlfluff lint file.sql
echo    Run pre-commit:  python -m pre_commit run --all-files
echo.
echo ⚙️  Configuration:
echo    SQLFluff config: .sqlfluff\config
echo    Pre-commit:      .pre-commit-config.yaml
echo    Style guide:     SQL_STYLE_GUIDE.md
echo.
echo 💡 Tips:
echo    • Pre-commit hooks will run automatically on git commits
echo    • SQLFluff will help maintain consistent code style
echo    • Check SQL_STYLE_GUIDE.md for detailed style rules
echo    • Use VS Code with SQLFluff extension for real-time linting
echo.

pause
