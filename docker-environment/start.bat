@echo off
REM SQL Analyst Pack Docker Environment Setup Script for Windows
REM This script helps you get started with the development environment

echo 🚀 SQL Analyst Pack Docker Environment Setup
echo ==============================================

REM Check if Docker is installed and running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not running. Please start Docker Desktop.
    echo    Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo ✅ Docker is ready

REM Check if Docker Compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose is not available. Please install Docker Desktop with Compose.
    pause
    exit /b 1
)

echo ✅ Docker Compose is ready

REM Create necessary directories
echo 📁 Creating necessary directories...
if not exist work\projects mkdir work\projects
if not exist work\exports mkdir work\exports
if not exist work\templates mkdir work\templates
if not exist data\scripts mkdir data\scripts
if not exist config\mysql mkdir config\mysql
if not exist config\pgadmin mkdir config\pgadmin
if not exist jupyter\notebooks mkdir jupyter\notebooks

REM Create MySQL configuration if it doesn't exist
if not exist config\mysql\my.cnf (
    echo Creating MySQL configuration...
    (
        echo [mysqld]
        echo innodb_buffer_pool_size = 256M
        echo max_connections = 200
        echo query_cache_size = 64M
        echo query_cache_limit = 2M
        echo slow_query_log = 1
        echo long_query_time = 2
        echo.
        echo [mysql]
        echo default-character-set = utf8mb4
        echo.
        echo [client]
        echo default-character-set = utf8mb4
    ) > config\mysql\my.cnf
)

REM Create pgAdmin servers configuration
if not exist config\pgadmin\servers.json (
    echo Creating pgAdmin configuration...
    (
        echo {
        echo     "Servers": {
        echo         "1": {
        echo             "Name": "SQL Analyst PostgreSQL",
        echo             "Group": "Servers",
        echo             "Host": "postgres",
        echo             "Port": 5432,
        echo             "MaintenanceDB": "analytics",
        echo             "Username": "analyst",
        echo             "PassFile": "/tmp/pgpassfile"
        echo         }
        echo     }
        echo }
    ) > config\pgadmin\servers.json
)

REM Start the environment
echo 🔧 Starting the SQL Analyst Pack environment...
echo This may take a few minutes the first time while images are downloaded...

docker-compose up -d

REM Wait for services to be ready
echo ⏳ Waiting for services to start...
timeout /t 30 /nobreak >nul

REM Check service status
echo 📊 Checking service status...
docker-compose ps

REM Provide access information
echo.
echo 🎉 Environment is ready!
echo =======================
echo.
echo 📊 Access URLs:
echo    Jupyter Lab: http://localhost:8888 (password: analyst)
echo    pgAdmin:     http://localhost:5050 (admin@analyst.com / admin)
echo    Adminer:     http://localhost:8080
echo.
echo 🗄️  Database Connections:
echo    PostgreSQL:  localhost:5432 (analyst / analyst123)
echo    MySQL:       localhost:3306 (analyst / analyst123)
echo    ClickHouse:  localhost:8123 (analyst / analyst123)
echo    Redis:       localhost:6379 (password: analyst123)
echo.
echo 📚 Next Steps:
echo    1. Open Jupyter Lab in your browser
echo    2. Navigate to sql-analyst-pack/ folder
echo    3. Start with the getting-started notebook
echo    4. Explore the sample datasets in the analytics database
echo.
echo 🛠️  Management Commands:
echo    Stop:    docker-compose down
echo    Restart: docker-compose restart
echo    Logs:    docker-compose logs [service-name]
echo    Status:  docker-compose ps
echo.

REM Optional: Open Jupyter in browser
echo Opening Jupyter Lab in your default browser...
start http://localhost:8888

pause
