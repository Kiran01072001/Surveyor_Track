#!/bin/bash

# Start Surveyor Tracking Backend with H2 In-Memory Database
# This is a TEMPORARY solution for testing without PostgreSQL

echo "========================================================"
echo "  Starting Surveyor Backend with H2 In-Memory Database"
echo "  WARNING: This is for testing only. Data will be lost on restart!"
echo "========================================================"
echo ""

# Path to JAR file - update if needed
BACKEND_JAR="surveyor-tracking-backend.jar"
if [ ! -f "$BACKEND_JAR" ]; then
    echo "Error: $BACKEND_JAR not found in current directory."
    echo "Please run this script from the directory containing the JAR file."
    exit 1
fi

# Start the application with H2 configuration
java -jar $BACKEND_JAR \
  --spring.datasource.url=jdbc:h2:mem:surveyordb \
  --spring.datasource.username=sa \
  --spring.datasource.password= \
  --spring.datasource.driver-class-name=org.h2.Driver \
  --spring.jpa.database-platform=org.hibernate.dialect.H2Dialect \
  --spring.h2.console.enabled=true \
  --spring.h2.console.path=/h2-console \
  --spring.jpa.hibernate.ddl-auto=create-drop

# Note: The application will create tables based on entity classes
# Data will be lost when the application is restarted
