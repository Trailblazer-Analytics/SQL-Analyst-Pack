# SQL Analyst Development Environment

This Docker environment provides a complete setup for SQL analysts, including multiple database systems, Jupyter notebooks, and essential analysis tools.

## Quick Start

1. **Install Docker Desktop** (Windows/Mac) or Docker (Linux)
2. **Clone this repository** and navigate to the docker-environment folder
3. **Start the environment**:

   ```bash
   docker-compose up -d
   ```

4. **Access Jupyter Lab**: [http://localhost:8888](http://localhost:8888) (password: `analyst`)
5. **Access databases** using the connection details below

## What's Included

### 🗄️ Database Systems

- **PostgreSQL 15** - Primary analytical database
- **MySQL 8** - Alternative relational database
- **ClickHouse** - Columnar database for analytics
- **Redis** - In-memory cache and session store

### 📊 Analysis Tools

- **Jupyter Lab** - Interactive notebooks with SQL extensions
- **pgAdmin** - PostgreSQL administration interface
- **Adminer** - Universal database management tool

### 📦 Pre-installed Packages

- pandas, numpy, matplotlib, seaborn, plotly
- SQLAlchemy, psycopg2, pymysql
- jupyter-sql magic commands
- Sample datasets and SQL Analyst Pack modules

## Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Jupyter Lab | [http://localhost:8888](http://localhost:8888) | Password: `analyst` |
| pgAdmin | [http://localhost:5050](http://localhost:5050) | admin@analyst.com / admin |
| Adminer | [http://localhost:8080](http://localhost:8080) | See connection details below |

## Database Connections

### PostgreSQL (Primary)

```text
Host: localhost (or postgres from containers)
Port: 5432
Database: analytics
Username: analyst
Password: analyst123
```

### MySQL

```text
Host: localhost (or mysql from containers)
Port: 3306
Database: analytics
Username: analyst
Password: analyst123
```

### ClickHouse

```text
Host: localhost (or clickhouse from containers)
Port: 8123
Database: analytics
Username: analyst
Password: analyst123
```

## Sample Data

The environment includes several sample datasets:

- **E-commerce transactions** (orders, customers, products)
- **Financial data** (accounts, transactions, balances)
- **HR data** (employees, departments, performance)
- **Marketing data** (campaigns, leads, conversions)

## Getting Started Guide

### 1. First Time Setup

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs if needed
docker-compose logs jupyter
```

### 2. Connect to Jupyter

1. Open [http://localhost:8888](http://localhost:8888)
2. Enter password: `analyst`
3. Navigate to `sql-analyst-pack/` folder
4. Open `getting-started.ipynb`

### 3. Database Connection Test

```python
import pandas as pd
import sqlalchemy as sa

# PostgreSQL connection
pg_engine = sa.create_engine('postgresql://analyst:analyst123@postgres:5432/analytics')

# Test query
test_df = pd.read_sql_query("SELECT version()", pg_engine)
print(test_df)
```

### 4. Load Sample Data

```bash
# Execute from host machine
docker-compose exec postgres psql -U analyst -d analytics -f /data/sample_data.sql
```

## Troubleshooting

### Common Issues

**Port conflicts**:

```bash
# Check what's using the ports
netstat -an | findstr "8888|5432|3306"

# Modify ports in docker-compose.yml if needed
```

**Memory issues**:

```bash
# Increase Docker memory allocation to at least 4GB
# Docker Desktop -> Settings -> Resources -> Memory
```

**Connection problems**:

```bash
# Reset the environment
docker-compose down
docker-compose up -d

# Check container logs
docker-compose logs [service-name]
```

### Container Management

```bash
# Stop all services
docker-compose down

# Restart specific service
docker-compose restart jupyter

# Update images
docker-compose pull
docker-compose up -d

# Clean up (removes data!)
docker-compose down -v
```

## Environment Customization

### Adding New Packages

Edit `jupyter/requirements.txt` and rebuild:

```bash
docker-compose build jupyter
docker-compose up -d jupyter
```

### Custom SQL Scripts

Place `.sql` files in `data/scripts/` and they'll be available in containers at `/scripts/`

### Configuration Changes

- **Jupyter**: Edit `jupyter/jupyter_lab_config.py`
- **PostgreSQL**: Edit `postgres/postgresql.conf`
- **MySQL**: Edit `mysql/my.cnf`

## Production Notes

🚨 **This environment is for development only!**

For production use:

- Change all default passwords
- Enable SSL/TLS connections
- Configure proper backup strategies
- Implement access controls and monitoring
- Use secrets management for credentials

## Analyst Workflow Tips

### 1. Project Organization

```
/work/projects/
├── project-1/
│   ├── notebooks/
│   ├── sql/
│   ├── data/
│   └── reports/
└── project-2/
    └── ...
```

### 2. SQL Magic Commands

```python
# Load SQL magic
%load_ext sql

# Set default connection
%sql postgresql://analyst:analyst123@postgres:5432/analytics

# Execute SQL directly
%%sql
SELECT customer_id, sum(order_amount) as total
FROM orders
GROUP BY customer_id
LIMIT 10
```

### 3. Data Export

```python
# Export to Excel
df.to_excel('/work/exports/analysis_results.xlsx', index=False)

# Export to CSV
df.to_csv('/work/exports/data_export.csv', index=False)
```

---

**Ready to start analyzing? Run `docker-compose up -d` and open Jupyter Lab!** 🚀
