#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Checking Prerequisites for Surveyor Tracking Application..."
echo "-------------------------------------------------------"

# Check Java
echo -n "Checking Java version: "
if command -v java >/dev/null 2>&1; then
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo -e "${GREEN}Found Java $java_version${NC}"
else
    echo -e "${RED}Java not found${NC}"
fi

# Check Node.js
echo -n "Checking Node.js version: "
if command -v node >/dev/null 2>&1; then
    node_version=$(node -v)
    echo -e "${GREEN}Found Node.js $node_version${NC}"
else
    echo -e "${RED}Node.js not found${NC}"
fi

# Check npm
echo -n "Checking npm version: "
if command -v npm >/dev/null 2>&1; then
    npm_version=$(npm -v)
    echo -e "${GREEN}Found npm $npm_version${NC}"
else
    echo -e "${RED}npm not found${NC}"
fi

# Check PostgreSQL
echo -n "Checking PostgreSQL version: "
if command -v psql >/dev/null 2>&1; then
    psql_version=$(psql --version)
    echo -e "${GREEN}Found $psql_version${NC}"
else
    echo -e "${RED}PostgreSQL not found${NC}"
fi

# Check PostGIS
echo -n "Checking PostGIS: "
if psql -t -c "SELECT PostGIS_Version();" postgres >/dev/null 2>&1; then
    postgis_version=$(psql -t -c "SELECT PostGIS_Version();" postgres)
    echo -e "${GREEN}Found PostGIS $postgis_version${NC}"
else
    echo -e "${RED}PostGIS not found or not accessible${NC}"
fi

# Check Nginx
echo -n "Checking Nginx: "
if command -v nginx >/dev/null 2>&1; then
    nginx_version=$(nginx -v 2>&1)
    echo -e "${GREEN}Found $nginx_version${NC}"
else
    echo -e "${YELLOW}Nginx not found (optional if using node serve)${NC}"
fi

# Check system resources
echo -e "\nSystem Resources:"
echo "----------------"
# Check RAM
total_ram=$(free -h | awk '/^Mem:/{print $2}')
available_ram=$(free -h | awk '/^Mem:/{print $7}')
echo -e "Total RAM: ${GREEN}$total_ram${NC}"
echo -e "Available RAM: ${GREEN}$available_ram${NC}"

# Check Disk Space
disk_space=$(df -h / | awk 'NR==2 {print $4}')
echo -e "Available Disk Space: ${GREEN}$disk_space${NC}"

# Check ports
echo -e "\nChecking required ports:"
echo "----------------------"
for port in 6565 3000 5432; do
    if netstat -tuln | grep ":$port " >/dev/null 2>&1; then
        echo -e "Port $port: ${RED}In use${NC}"
    else
        echo -e "Port $port: ${GREEN}Available${NC}"
    fi
done

echo -e "\nPrerequisite Check Complete!"
echo "Please ensure all required components are installed and configured properly."
