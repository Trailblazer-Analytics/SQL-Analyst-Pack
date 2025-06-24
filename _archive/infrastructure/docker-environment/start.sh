#!/bin/bash

# SQL Analyst Pack Docker Environment Setup Script
# This script helps you get started with the development environment

echo "🚀 SQL Analyst Pack Docker Environment Setup"
echo "=============================================="

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop first."
    echo "   Download from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is ready"

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose."
    exit 1
fi

echo "✅ Docker Compose is ready"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p work/projects work/exports work/templates
mkdir -p data/scripts config/mysql config/pgadmin
mkdir -p jupyter/notebooks

# Create MySQL configuration if it doesn't exist
if [ ! -f "config/mysql/my.cnf" ]; then
    echo "Creating MySQL configuration..."
    cat > config/mysql/my.cnf << EOF
[mysqld]
innodb_buffer_pool_size = 256M
max_connections = 200
query_cache_size = 64M
query_cache_limit = 2M
slow_query_log = 1
long_query_time = 2

[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4
EOF
fi

# Create pgAdmin servers configuration
if [ ! -f "config/pgadmin/servers.json" ]; then
    echo "Creating pgAdmin configuration..."
    cat > config/pgadmin/servers.json << EOF
{
    "Servers": {
        "1": {
            "Name": "SQL Analyst PostgreSQL",
            "Group": "Servers",
            "Host": "postgres",
            "Port": 5432,
            "MaintenanceDB": "analytics",
            "Username": "analyst",
            "PassFile": "/tmp/pgpassfile"
        }
    }
}
EOF
fi

# Start the environment
echo "🔧 Starting the SQL Analyst Pack environment..."
echo "This may take a few minutes the first time while images are downloaded..."

docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "📊 Checking service status..."
docker-compose ps

# Provide access information
echo ""
echo "🎉 Environment is ready!"
echo "======================="
echo ""
echo "📊 Access URLs:"
echo "   Jupyter Lab: http://localhost:8888 (password: analyst)"
echo "   pgAdmin:     http://localhost:5050 (admin@analyst.com / admin)"
echo "   Adminer:     http://localhost:8080"
echo ""
echo "🗄️  Database Connections:"
echo "   PostgreSQL:  localhost:5432 (analyst / analyst123)"
echo "   MySQL:       localhost:3306 (analyst / analyst123)"
echo "   ClickHouse:  localhost:8123 (analyst / analyst123)"
echo "   Redis:       localhost:6379 (password: analyst123)"
echo ""
echo "📚 Next Steps:"
echo "   1. Open Jupyter Lab in your browser"
echo "   2. Navigate to sql-analyst-pack/ folder"
echo "   3. Start with the getting-started notebook"
echo "   4. Explore the sample datasets in the analytics database"
echo ""
echo "🛠️  Management Commands:"
echo "   Stop:    docker-compose down"
echo "   Restart: docker-compose restart"
echo "   Logs:    docker-compose logs [service-name]"
echo "   Status:  docker-compose ps"

# Optional: Open Jupyter in browser (uncomment if desired)
# sleep 5
# if command -v xdg-open &> /dev/null; then
#     xdg-open http://localhost:8888
# elif command -v open &> /dev/null; then
#     open http://localhost:8888
# fi
