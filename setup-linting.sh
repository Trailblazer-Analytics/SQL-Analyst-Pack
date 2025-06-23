#!/bin/bash

# Setup script for SQL code quality tools
# This script installs and configures SQLFluff and pre-commit hooks

echo "🔧 Setting up SQL Code Quality Tools"
echo "===================================="

# Check if Python is available
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "❌ Python is required but not installed. Please install Python 3.8+."
    exit 1
fi

# Use python3 if available, otherwise python
PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
fi

echo "✅ Using Python: $(which $PYTHON_CMD)"

# Check if pip is available
if ! $PYTHON_CMD -m pip --version &> /dev/null; then
    echo "❌ pip is required but not available."
    exit 1
fi

echo "✅ pip is available"

# Install SQLFluff and related packages
echo "📦 Installing SQLFluff and dependencies..."
$PYTHON_CMD -m pip install --user sqlfluff[postgres] pre-commit sqlparse

# Verify SQLFluff installation
if command -v sqlfluff &> /dev/null || $PYTHON_CMD -m sqlfluff --version &> /dev/null; then
    echo "✅ SQLFluff installed successfully"
else
    echo "❌ SQLFluff installation failed"
    exit 1
fi

# Install pre-commit hooks
echo "🪝 Installing pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install
    echo "✅ Pre-commit hooks installed"
else
    echo "⚠️  pre-commit not found in PATH, trying with Python..."
    $PYTHON_CMD -m pre_commit install
fi

# Test SQLFluff configuration
echo "🧪 Testing SQLFluff configuration..."
if [ -f ".sqlfluff/config" ]; then
    echo "✅ SQLFluff configuration found"
    
    # Test with a sample SQL file if available
    if find . -name "*.sql" -type f | head -1 | read -r sample_file; then
        echo "🔍 Testing with sample file: $sample_file"
        if command -v sqlfluff &> /dev/null; then
            sqlfluff lint "$sample_file" --verbose || echo "⚠️  Found some style issues (this is normal)"
        else
            $PYTHON_CMD -m sqlfluff lint "$sample_file" --verbose || echo "⚠️  Found some style issues (this is normal)"
        fi
    fi
else
    echo "❌ SQLFluff configuration not found at .sqlfluff/config"
    exit 1
fi

# Create a simple script for running checks
cat > lint-sql.sh << 'EOF'
#!/bin/bash
# Quick script to lint SQL files

echo "🔍 Running SQL quality checks..."

if [ $# -eq 0 ]; then
    echo "Checking all SQL files..."
    if command -v sqlfluff &> /dev/null; then
        sqlfluff lint **/*.sql
    else
        python -m sqlfluff lint **/*.sql
    fi
else
    echo "Checking specified files: $@"
    if command -v sqlfluff &> /dev/null; then
        sqlfluff lint "$@"
    else
        python -m sqlfluff lint "$@"
    fi
fi
EOF

chmod +x lint-sql.sh

# Create a fix script
cat > fix-sql.sh << 'EOF'
#!/bin/bash
# Quick script to auto-fix SQL formatting

echo "🔧 Auto-fixing SQL formatting..."

if [ $# -eq 0 ]; then
    echo "Fixing all SQL files..."
    if command -v sqlfluff &> /dev/null; then
        sqlfluff fix **/*.sql
    else
        python -m sqlfluff fix **/*.sql
    fi
else
    echo "Fixing specified files: $@"
    if command -v sqlfluff &> /dev/null; then
        sqlfluff fix "$@"
    else
        python -m sqlfluff fix "$@"
    fi
fi
EOF

chmod +x fix-sql.sh

# Provide usage information
echo ""
echo "🎉 SQL Code Quality Tools Setup Complete!"
echo "========================================"
echo ""
echo "📋 Available Tools:"
echo "   SQLFluff:     Code linting and formatting"
echo "   Pre-commit:   Automatic checks before commits"
echo "   Custom hooks: Business logic validation"
echo ""
echo "🚀 Quick Usage:"
echo "   Lint all SQL:    ./lint-sql.sh"
echo "   Fix formatting:  ./fix-sql.sh"
echo "   Lint specific:   ./lint-sql.sh path/to/file.sql"
echo "   Manual SQLFluff: sqlfluff lint file.sql"
echo "   Run pre-commit: pre-commit run --all-files"
echo ""
echo "⚙️  Configuration:"
echo "   SQLFluff config: .sqlfluff/config"
echo "   Pre-commit:      .pre-commit-config.yaml"
echo "   Style guide:     SQL_STYLE_GUIDE.md"
echo ""
echo "💡 Tips:"
echo "   • Pre-commit hooks will run automatically on git commits"
echo "   • SQLFluff will help maintain consistent code style"
echo "   • Check SQL_STYLE_GUIDE.md for detailed style rules"
echo "   • Use VS Code with SQLFluff extension for real-time linting"
