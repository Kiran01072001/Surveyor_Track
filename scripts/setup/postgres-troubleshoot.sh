#!/bin/bash

# PostgreSQL Connection Troubleshooter
# This script helps diagnose PostgreSQL connection problems on production server

echo "========================================================"
echo "  PostgreSQL Connection Troubleshooter for Surveyor App"
echo "========================================================"
echo ""

# Configuration - Update these values as needed
PG_HOST="183.82.114.29"
PG_PORT="5432"
PG_DB="location"
PG_USER="postgres"
PG_PASSWORD="NeoGeo@9876"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 1. Check if netcat is installed for network tests
echo -e "${YELLOW}[1/6] Checking if network tools are available...${NC}"
if ! command -v nc &> /dev/null; then
    echo -e "${RED}ERROR: 'nc' (netcat) is not installed. Install it to run network tests:${NC}"
    echo "    Ubuntu/Debian: sudo apt-get install netcat"
    echo "    RHEL/CentOS: sudo yum install nc"
    echo "    macOS: brew install netcat"
    # Try alternatives
    HAS_TELNET=$(command -v telnet &> /dev/null && echo "yes" || echo "no")
    HAS_CURL=$(command -v curl &> /dev/null && echo "yes" || echo "no")
    
    if [ "$HAS_CURL" == "yes" ]; then
        echo -e "${YELLOW}Using curl as alternative for basic connectivity test${NC}"
    elif [ "$HAS_TELNET" == "yes" ]; then
        echo -e "${YELLOW}Using telnet as alternative for basic connectivity test${NC}"
    else
        echo -e "${RED}No network testing tools available. Please install nc, curl or telnet.${NC}"
    fi
else
    echo -e "${GREEN}✓ Network testing tools available${NC}"
fi

# 2. Check basic network connectivity to PostgreSQL server
echo ""
echo -e "${YELLOW}[2/6] Testing network connectivity to PostgreSQL server...${NC}"
echo "    Host: $PG_HOST"
echo "    Port: $PG_PORT"

# Try multiple tools
if command -v nc &> /dev/null; then
    NC_RESULT=$(nc -z -w5 $PG_HOST $PG_PORT 2>&1 && echo "success" || echo "failed")
    if [ "$NC_RESULT" == "success" ]; then
        echo -e "${GREEN}✓ Connection to $PG_HOST:$PG_PORT successful (netcat)${NC}"
    else
        echo -e "${RED}✗ Cannot connect to $PG_HOST:$PG_PORT (netcat)${NC}"
    fi
elif command -v curl &> /dev/null; then
    CURL_RESULT=$(curl -s --connect-timeout 5 telnet://$PG_HOST:$PG_PORT >/dev/null 2>&1 && echo "success" || echo "failed")
    if [ "$CURL_RESULT" == "success" ]; then
        echo -e "${GREEN}✓ Connection to $PG_HOST:$PG_PORT successful (curl)${NC}"
    else
        echo -e "${RED}✗ Cannot connect to $PG_HOST:$PG_PORT (curl)${NC}"
    fi
elif command -v telnet &> /dev/null; then
    echo "Trying telnet $PG_HOST $PG_PORT (will timeout in 5 seconds if failed)..."
    TELNET_RESULT=$(timeout 5 telnet $PG_HOST $PG_PORT 2>&1 | grep -i connected)
    if [ ! -z "$TELNET_RESULT" ]; then
        echo -e "${GREEN}✓ Connection to $PG_HOST:$PG_PORT successful (telnet)${NC}"
    else
        echo -e "${RED}✗ Cannot connect to $PG_HOST:$PG_PORT (telnet timed out)${NC}"
    fi
else
    echo -e "${RED}✗ Cannot test network connectivity - no tools available${NC}"
fi

# 3. Check if PostgreSQL client is installed
echo ""
echo -e "${YELLOW}[3/6] Checking for PostgreSQL client...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${RED}✗ PostgreSQL client (psql) is not installed.${NC}"
    echo "Install it to perform database connection tests:"
    echo "    Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "    RHEL/CentOS: sudo yum install postgresql"
    echo "    macOS: brew install postgresql"
    HAS_PSQL="no"
else
    echo -e "${GREEN}✓ PostgreSQL client installed${NC}"
    HAS_PSQL="yes"
fi

# 4. Check PostgreSQL connection with credentials if psql is available
echo ""
echo -e "${YELLOW}[4/6] Testing database connection with credentials...${NC}"
if [ "$HAS_PSQL" == "yes" ]; then
    # Create a temporary pgpass file to avoid password prompt
    PGPASS_FILE=$(mktemp)
    chmod 600 $PGPASS_FILE
    echo "$PG_HOST:$PG_PORT:$PG_DB:$PG_USER:$PG_PASSWORD" > $PGPASS_FILE
    export PGPASSFILE=$PGPASS_FILE
    
    # Try to connect and run a simple query
    PSQL_RESULT=$(PGPASSFILE=$PGPASS_FILE psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -c "SELECT 1 AS connection_test;" 2>&1)
    PSQL_EXIT_CODE=$?
    
    # Clean up
    rm $PGPASS_FILE
    
    if [ $PSQL_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
    else
        echo -e "${RED}✗ Database connection failed${NC}"
        echo "Error: $PSQL_RESULT"
        
        # Check for common error patterns
        if [[ $PSQL_RESULT == *"password authentication failed"* ]]; then
            echo -e "${YELLOW}→ The username/password combination is incorrect${NC}"
        elif [[ $PSQL_RESULT == *"does not exist"* ]]; then
            echo -e "${YELLOW}→ The database '$PG_DB' does not exist${NC}"
        elif [[ $PSQL_RESULT == *"Connection refused"* ]]; then
            echo -e "${YELLOW}→ Connection refused - PostgreSQL may not be running or not accepting connections from this IP${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Skipping database connection test (psql not installed)${NC}"
fi

# 5. Check JVM environment for the application
echo ""
echo -e "${YELLOW}[5/6] Checking Java environment...${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java not found. The application requires Java 17 or higher.${NC}"
else
    JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    echo -e "${GREEN}✓ Java is installed: $JAVA_VERSION${NC}"
    
    # Check if JAVA_HOME is set
    if [ -z "$JAVA_HOME" ]; then
        echo -e "${YELLOW}⚠ JAVA_HOME environment variable is not set${NC}"
    else
        echo -e "${GREEN}✓ JAVA_HOME is set to: $JAVA_HOME${NC}"
    fi
fi

# 6. Check configuration file
echo ""
echo -e "${YELLOW}[6/6] Checking application configuration...${NC}"
APP_JAR="surveyor-tracking-backend.jar"
if [ -f "$APP_JAR" ]; then
    echo -e "${GREEN}✓ Application JAR file found: $APP_JAR${NC}"
    
    # Extract application.properties from JAR to verify database settings
    echo "Extracting application.properties to verify database configuration..."
    jar xf $APP_JAR BOOT-INF/classes/application.properties 2>/dev/null
    
    if [ -f "BOOT-INF/classes/application.properties" ]; then
        DB_URL=$(grep "spring.datasource.url" BOOT-INF/classes/application.properties | cut -d= -f2-)
        DB_USER=$(grep "spring.datasource.username" BOOT-INF/classes/application.properties | cut -d= -f2-)
        DB_PASS_MASKED=$(grep "spring.datasource.password" BOOT-INF/classes/application.properties | sed 's/=.*$/=********/')
        
        echo -e "${GREEN}Database configuration in JAR:${NC}"
        echo "  URL: $DB_URL"
        echo "  Username: $DB_USER"
        echo "  Password: $DB_PASS_MASKED"
        
        # Clean up
        rm -rf BOOT-INF
    else
        echo -e "${RED}✗ Could not extract application.properties from JAR${NC}"
    fi
else
    echo -e "${YELLOW}Application JAR file not found in current directory.${NC}"
    echo "Make sure you're running this script from the directory containing the JAR file."
fi

# Summary and recommendations
echo ""
echo "========================================================"
echo "                 DIAGNOSIS SUMMARY                      "
echo "========================================================"

if [ "$NC_RESULT" == "failed" ] || [ "$CURL_RESULT" == "failed" ] || [ -z "$TELNET_RESULT" ]; then
    echo -e "${RED}✗ NETWORK CONNECTIVITY ISSUE DETECTED${NC}"
    echo ""
    echo "Recommendations:"
    echo "1. Verify that the PostgreSQL server is running at $PG_HOST:$PG_PORT"
    echo "2. Check firewall rules on both the PostgreSQL server and this machine"
    echo "3. Verify that PostgreSQL is configured to accept remote connections:"
    echo "   • Check pg_hba.conf for client authentication settings"
    echo "   • Check postgresql.conf for listen_addresses (should be '*' or include your IP)"
    echo ""
    echo "To modify PostgreSQL configuration on the database server:"
    echo "  1. Edit pg_hba.conf: Add this line to allow your application's IP:"
    echo "     host    $PG_DB    $PG_USER    YOUR_APP_IP/32    md5"
    echo "  2. Edit postgresql.conf: Set listen_addresses = '*'"
    echo "  3. Restart PostgreSQL: sudo systemctl restart postgresql"
fi

if [ "$HAS_PSQL" == "yes" ] && [ $PSQL_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}✗ DATABASE AUTHENTICATION ISSUE DETECTED${NC}"
    echo ""
    echo "Recommendations:"
    echo "1. Verify username and password are correct"
    echo "2. Confirm the database '$PG_DB' exists"
    echo "3. Check that user '$PG_USER' has sufficient privileges"
fi

echo ""
echo "For temporary testing purposes, try using a local H2 database by adding"
echo "these properties to your application.properties or as command-line arguments:"
echo ""
echo "java -jar $APP_JAR \\
  --spring.datasource.url=jdbc:h2:mem:testdb \\
  --spring.datasource.username=sa \\
  --spring.datasource.password= \\
  --spring.datasource.driver-class-name=org.h2.Driver \\
  --spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"

echo ""
echo "========================================================"

# Done
echo ""
echo "Connection troubleshooting complete."
echo ""
