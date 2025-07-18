#!/bin/bash

# Restart Spring Boot Backend with CORS Fix
# This script restarts your Spring Boot application with proper CORS settings

echo "========================================================"
echo "  Restarting Surveyor Backend with CORS Fix"
echo "========================================================"
echo ""

# Find the process ID of the currently running Spring Boot application
echo "Looking for currently running Spring Boot process..."
SPRING_PID=$(ps -ef | grep "SurveyorTrackingBackend" | grep -v grep | awk '{print $2}')

if [ ! -z "$SPRING_PID" ]; then
    echo "Found Spring Boot process with PID: $SPRING_PID"
    echo "Stopping process..."
    kill -15 $SPRING_PID
    
    # Wait for process to stop
    sleep 5
    
    # Check if it's still running
    if ps -p $SPRING_PID > /dev/null; then
        echo "Process still running, force killing..."
        kill -9 $SPRING_PID
        sleep 2
    fi
    
    echo "Process stopped."
else
    echo "No running Spring Boot process found."
fi

# Navigate to the backend directory
cd SurveyorTrackingBackend

echo "Building with Maven..."
./mvnw clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "Build failed! Check Maven errors above."
    exit 1
fi

echo "Starting backend with CORS configurations..."
java -jar target/SurveyorTrackingBackend-0.0.1-SNAPSHOT.jar \
  --spring.web.cors.allowed-origins=http://localhost:9898,http://localhost:3000,http://localhost:6565,http://localhost:6060,http://127.0.0.1:9898,http://183.82.114.29:9898,http://183.82.114.29:6868,http://183.82.114.29:6565,http://183.82.114.29:6060,http://183.82.114.29:3000,file:// \
  --spring.web.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS \
  --spring.web.cors.allowed-headers=* \
  --spring.web.cors.max-age=3600 \
  --spring.web.cors.allow-credentials=false \
  --spring.web.cors.allow-credentials=false \
  --logging.level.org.springframework.web=DEBUG &

echo ""
echo "Backend started with PID: $!"
echo "CORS has been configured for all required origins"
echo ""
echo "To test login functionality:"
echo "1. Open the login-test.html file in your browser"
echo "2. The default configuration should work, but you can adjust the API host if needed"
echo "3. Click 'Test Login' to verify the login works"
echo "4. If CORS issues persist, click 'Test CORS Configuration' for more details"
echo ""
