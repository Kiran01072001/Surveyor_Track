#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Checking Surveyor Tracking Application Status..."
echo "----------------------------------------"

# Check if processes are running
echo -e "\n1. Checking Process Status:"
if [ -f deploy/backend.pid ]; then
    if ps -p $(cat deploy/backend.pid) > /dev/null; then
        echo -e "${GREEN}✓ Backend process is running (PID: $(cat deploy/backend.pid))${NC}"
    else
        echo -e "${RED}✗ Backend process is not running${NC}"
    fi
else
    echo -e "${RED}✗ Backend PID file not found${NC}"
fi

if [ -f deploy/frontend.pid ]; then
    if ps -p $(cat deploy/frontend.pid) > /dev/null; then
        echo -e "${GREEN}✓ Frontend process is running (PID: $(cat deploy/frontend.pid))${NC}"
    else
        echo -e "${RED}✗ Frontend process is not running${NC}"
    fi
else
    echo -e "${RED}✗ Frontend PID file not found${NC}"
fi

# Import port configurations
if [ -f "deploy/config.sh" ]; then
    source deploy/config.sh
else
    # Default values if config file is not found
    BACKEND_PORT=6565
    FRONTEND_PORT=9898
fi

# Check if ports are in use
echo -e "\n2. Checking Port Status:"
if netstat -tuln | grep ":${BACKEND_PORT} " > /dev/null; then
    echo -e "${GREEN}✓ Backend port (${BACKEND_PORT}) is active${NC}"
else
    echo -e "${RED}✗ Backend port (${BACKEND_PORT}) is not active${NC}"
fi

if netstat -tuln | grep ":${FRONTEND_PORT} " > /dev/null; then
    echo -e "${GREEN}✓ Frontend port (${FRONTEND_PORT}) is active${NC}"
else
    echo -e "${RED}✗ Frontend port (${FRONTEND_PORT}) is not active${NC}"
fi

# Check if services are responding
echo -e "\n3. Checking API Health:"
if curl -s "http://183.82.114.29:${BACKEND_PORT}/api/health" > /dev/null; then
    echo -e "${GREEN}✓ Backend API is responding${NC}"
else
    echo -e "${RED}✗ Backend API is not responding${NC}"
fi

if curl -s "http://183.82.114.29:${FRONTEND_PORT}" | grep -q "html"; then
    echo -e "${GREEN}✓ Frontend is serving content${NC}"
else
    echo -e "${RED}✗ Frontend is not serving content${NC}"
fi

# Check PostgreSQL connection
echo -e "\n4. Checking Database Connection:"
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PostgreSQL is accepting connections${NC}"
else
    echo -e "${RED}✗ PostgreSQL is not accessible${NC}"
fi

# Check logs for errors
echo -e "\n5. Recent Error Logs:"
echo "Backend Errors:"
if [ -f deploy/backend.log ]; then
    grep -i "error\|exception" deploy/backend.log | tail -n 5
else
    echo -e "${YELLOW}No backend log file found${NC}"
fi

echo -e "\nFrontend Errors:"
if [ -f deploy/frontend.log ]; then
    grep -i "error" deploy/frontend.log | tail -n 5
else
    echo -e "${YELLOW}No frontend log file found${NC}"
fi

# Memory usage
echo -e "\n6. Memory Usage:"
echo "Backend Memory Usage:"
if [ -f deploy/backend.pid ]; then
    ps -o pid,ppid,%mem,%cpu,cmd -p $(cat deploy/backend.pid) 2>/dev/null || echo -e "${RED}Process not found${NC}"
fi

echo -e "\nFrontend Memory Usage:"
if [ -f deploy/frontend.pid ]; then
    ps -o pid,ppid,%mem,%cpu,cmd -p $(cat deploy/frontend.pid) 2>/dev/null || echo -e "${RED}Process not found${NC}"
fi

echo -e "\nCheck complete! Please review any errors above."
