#!/bin/bash

# Start Surveyor Tracking Backend with improved PostgreSQL settings
# This script adds robust connection settings to handle network issues better

echo "========================================================"
echo "  Starting Surveyor Backend with Improved PG Settings"
echo "========================================================"
echo ""

# Path to JAR file - update if needed
BACKEND_JAR="surveyor-tracking-backend.jar"
if [ ! -f "$BACKEND_JAR" ]; then
    echo "Error: $BACKEND_JAR not found in current directory."
    echo "Please run this script from the directory containing the JAR file."
    exit 1
fi

# Start the application with more robust PostgreSQL connection settings
java -jar $BACKEND_JAR \
  --spring.datasource.url=jdbc:postgresql://183.82.114.29:5432/location \
  --spring.datasource.username=postgres \
  --spring.datasource.password=NeoGeo@9876 \
  --spring.datasource.driver-class-name=org.postgresql.Driver \
  --spring.datasource.hikari.connection-timeout=30000 \
  --spring.datasource.hikari.maximum-pool-size=10 \
  --spring.datasource.hikari.minimum-idle=5 \
  --spring.datasource.hikari.idle-timeout=120000 \
  --spring.datasource.hikari.max-lifetime=1800000 \
  --logging.level.org.springframework=INFO \
  --logging.level.com.zaxxer.hikari=DEBUG
