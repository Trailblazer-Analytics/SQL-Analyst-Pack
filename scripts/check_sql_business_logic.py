#!/usr/bin/env python3
"""
SQL Business Logic Checker for SQL Analyst Pack

This script performs additional checks beyond SQLFluff to ensure
SQL queries follow business analysis best practices.
"""

import sys
import re
import sqlparse
from pathlib import Path
from typing import List, Tuple


class SQLBusinessLogicChecker:
    """Check SQL files for business analysis best practices"""
    
    def __init__(self):
        self.errors = []
        
    def check_file(self, filepath: Path) -> List[Tuple[str, str]]:
        """Check a single SQL file and return list of (line_number, error_message)"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Parse SQL
            parsed = sqlparse.parse(content)
            
            # Run all checks
            file_errors = []
            file_errors.extend(self._check_business_context(content, filepath))
            file_errors.extend(self._check_performance_patterns(content, filepath))
            file_errors.extend(self._check_analyst_best_practices(content, filepath))
            
            return file_errors
            
        except Exception as e:
            return [(1, f"Error reading file: {str(e)}")]
    
    def _check_business_context(self, content: str, filepath: Path) -> List[Tuple[str, str]]:
        """Check for business context and documentation"""
        errors = []
        lines = content.split('\n')
        
        # Check for business context comment
        has_business_comment = any(
            re.search(r'--.*(?:business|requirement|stakeholder|objective)', line, re.IGNORECASE)
            for line in lines[:10]  # Check first 10 lines
        )
        
        if not has_business_comment and len(lines) > 20:  # Only for complex queries
            errors.append((1, "Consider adding business context comment for complex queries"))
            
        # Check for hardcoded dates that might need parameterization
        hardcoded_dates = re.findall(r"'(\d{4}-\d{2}-\d{2})'", content)
        if len(hardcoded_dates) > 2:
            for i, line in enumerate(lines):
                if re.search(r"'\d{4}-\d{2}-\d{2}'", line):
                    errors.append((i+1, "Consider parameterizing hardcoded dates for reusability"))
                    break
                    
        return errors
    
    def _check_performance_patterns(self, content: str, filepath: Path) -> List[Tuple[str, str]]:
        """Check for common performance issues"""
        errors = []
        lines = content.split('\n')
        
        # Check for SELECT * in production-like queries
        for i, line in enumerate(lines):
            if re.search(r'\bSELECT\s+\*\b', line, re.IGNORECASE):
                # Allow in exploratory contexts
                if not any(keyword in filepath.name.lower() for keyword in ['explore', 'profile', 'test']):
                    errors.append((i+1, "Avoid SELECT * in production queries - specify needed columns"))
        
        # Check for missing WHERE clauses on large tables
        common_large_tables = ['orders', 'transactions', 'events', 'logs', 'sessions']
        for i, line in enumerate(lines):
            for table in common_large_tables:
                if re.search(rf'\bFROM\s+{table}\b', line, re.IGNORECASE):
                    # Look for WHERE clause in next few lines
                    has_where = any(
                        re.search(r'\bWHERE\b', lines[j], re.IGNORECASE)
                        for j in range(i, min(i+5, len(lines)))
                    )
                    if not has_where:
                        errors.append((i+1, f"Consider adding WHERE clause when querying large table '{table}'"))
                        
        return errors
    
    def _check_analyst_best_practices(self, content: str, filepath: Path) -> List[Tuple[str, str]]:
        """Check for analyst-specific best practices"""
        errors = []
        lines = content.split('\n')
        
        # Check for meaningful column aliases in aggregations
        for i, line in enumerate(lines):
            if re.search(r'\b(COUNT|SUM|AVG|MAX|MIN)\s*\([^)]+\)(?!\s+AS\s+\w+)', line, re.IGNORECASE):
                errors.append((i+1, "Consider adding meaningful aliases to aggregate functions"))
        
        # Check for CASE statements without ELSE
        case_without_else = re.findall(r'\bCASE\b.*?\bEND\b', content, re.IGNORECASE | re.DOTALL)
        for case_stmt in case_without_else:
            if 'ELSE' not in case_stmt.upper():
                # Find line number (approximate)
                case_line = next((i+1 for i, line in enumerate(lines) if 'CASE' in line.upper()), 0)
                errors.append((case_line, "Consider adding ELSE clause to CASE statements for completeness"))
        
        # Check for GROUP BY without ORDER BY in analytical queries
        has_group_by = any(re.search(r'\bGROUP\s+BY\b', line, re.IGNORECASE) for line in lines)
        has_order_by = any(re.search(r'\bORDER\s+BY\b', line, re.IGNORECASE) for line in lines)
        
        if has_group_by and not has_order_by:
            group_by_line = next((i+1 for i, line in enumerate(lines) if re.search(r'\bGROUP\s+BY\b', line, re.IGNORECASE)), 0)
            errors.append((group_by_line, "Consider adding ORDER BY for consistent results in analytical queries"))
            
        return errors


def main():
    """Main function for pre-commit hook"""
    if len(sys.argv) < 2:
        print("Usage: check_sql_business_logic.py <sql_files...>")
        sys.exit(1)
    
    checker = SQLBusinessLogicChecker()
    total_errors = 0
    
    for filepath in sys.argv[1:]:
        path = Path(filepath)
        if path.suffix.lower() == '.sql':
            errors = checker.check_file(path)
            
            if errors:
                print(f"\n📋 Business Logic Issues in {filepath}:")
                for line_num, message in errors:
                    print(f"  Line {line_num}: {message}")
                total_errors += len(errors)
    
    if total_errors > 0:
        print(f"\n❌ Found {total_errors} business logic issues")
        print("💡 These are suggestions to improve your SQL for business analysis")
        # Don't fail the commit - these are suggestions
        sys.exit(0)  
    else:
        print("✅ All SQL files follow business analysis best practices")
        sys.exit(0)


if __name__ == "__main__":
    main()
