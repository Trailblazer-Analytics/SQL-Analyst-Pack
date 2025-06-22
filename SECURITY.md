# Security Policy

## Supported Versions

This repository contains educational SQL scripts and documentation. As this is primarily an educational resource, we maintain the following support:

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |

## Reporting a Vulnerability

While this repository primarily contains educational SQL scripts, we take security seriously. If you discover a security vulnerability, please follow these steps:

### For SQL Security Issues:
- **SQL Injection vulnerabilities** in example scripts
- **Unsafe SQL patterns** that could mislead learners
- **Database security misconfigurations** in setup guides

### How to Report:
1. **DO NOT** open a public issue for security vulnerabilities
2. Email the maintainers directly (if public email available) or
3. Use GitHub's private vulnerability reporting feature
4. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Expect:
- **Acknowledgment** within 48 hours
- **Assessment** within 1 week
- **Fix timeline** depends on severity:
  - Critical: 24-48 hours
  - High: 1 week
  - Medium: 2 weeks
  - Low: 1 month

### Security Best Practices for Contributors:
- Never include real credentials or connection strings in scripts
- Use placeholder values (e.g., `your_password_here`)
- Avoid SQL patterns that could encourage bad security practices
- Include warnings about production database safety
- Test scripts in isolated environments only

## Scope

This security policy covers:
- SQL scripts and their educational content
- Documentation and setup guides
- Repository infrastructure and workflows

This policy does not cover:
- Third-party databases or tools referenced in documentation
- Issues with users' local database installations
- General SQL education questions (use discussions instead)

## Security Contact

For security-related questions or reports:
- Create a private vulnerability report on GitHub
- Tag issues with `security` label when appropriate

Thank you for helping keep the SQL learning community safe! 🔒
