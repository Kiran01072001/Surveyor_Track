#!/bin/bash
# Script to update port configuration

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Config file location
CONFIG_FILE="./deploy/config.sh"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${YELLOW}Config file not found at $CONFIG_FILE${NC}"
  echo "Creating default config file..."
  
  # Create directory if it doesn't exist
  mkdir -p ./deploy
  
  # Create default config file
  cat > "$CONFIG_FILE" << EOF
#!/bin/bash
# Centralized port configuration for deployment
# ----------------------------------------------
# This file is the central location for all port configurations
# Edit this file to change port numbers across the entire application

# ----------------------------------------------
# CONFIGURATION SECTION - MODIFY AS NEEDED
# ----------------------------------------------

# Backend API port
BACKEND_PORT=6565

# Frontend port
FRONTEND_PORT=9898

# Database port
DATABASE_PORT=5432

# ----------------------------------------------
# DO NOT MODIFY BELOW THIS LINE
# ----------------------------------------------

# Export the variables to be used by other scripts
export BACKEND_PORT
export FRONTEND_PORT
export DATABASE_PORT

# This line is to confirm the config file has been loaded when sourced
echo "Loaded port configuration: Backend=\$BACKEND_PORT, Frontend=\$FRONTEND_PORT, Database=\$DATABASE_PORT"
EOF

  chmod +x "$CONFIG_FILE"
  echo -e "${GREEN}Default config file created at $CONFIG_FILE${NC}"
fi

# Source the current config
source "$CONFIG_FILE"

# Display current values
echo "Current port configuration:"
echo "--------------------------"
echo "1. Backend API port: $BACKEND_PORT"
echo "2. Frontend port: $FRONTEND_PORT"
echo "3. Database port: $DATABASE_PORT"
echo "--------------------------"

# Ask if user wants to update
read -p "Do you want to update these values? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "No changes made."
  exit 0
fi

# Ask for new port values
read -p "Enter new Backend port [$BACKEND_PORT]: " new_backend
read -p "Enter new Frontend port [$FRONTEND_PORT]: " new_frontend
read -p "Enter new Database port [$DATABASE_PORT]: " new_database

# Use default values if nothing entered
new_backend=${new_backend:-$BACKEND_PORT}
new_frontend=${new_frontend:-$FRONTEND_PORT}
new_database=${new_database:-$DATABASE_PORT}

# Update config file
sed -i.bak "s/BACKEND_PORT=$BACKEND_PORT/BACKEND_PORT=$new_backend/" "$CONFIG_FILE"
sed -i.bak "s/FRONTEND_PORT=$FRONTEND_PORT/FRONTEND_PORT=$new_frontend/" "$CONFIG_FILE"
sed -i.bak "s/DATABASE_PORT=$DATABASE_PORT/DATABASE_PORT=$new_database/" "$CONFIG_FILE"

# Remove backup file
rm "${CONFIG_FILE}.bak"

echo -e "${GREEN}Port configuration updated:${NC}"
echo "Backend port: $new_backend"
echo "Frontend port: $new_frontend"
echo "Database port: $new_database"

# Ask if user wants to apply changes to the application
read -p "Do you want to apply these changes to the app configuration? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Updating application configuration..."
  if [ -d "surveyor-tracking-dashboard" ]; then
    cd surveyor-tracking-dashboard
    npm run setup
    echo -e "${GREEN}Application configuration updated.${NC}"
  else
    echo -e "${YELLOW}Cannot find surveyor-tracking-dashboard directory.${NC}"
    echo "Please run the following command manually:"
    echo "  cd surveyor-tracking-dashboard && npm run setup"
  fi
else
  echo "Configuration updated but not applied to application."
  echo "To apply changes later, run: cd surveyor-tracking-dashboard && npm run setup"
fi
