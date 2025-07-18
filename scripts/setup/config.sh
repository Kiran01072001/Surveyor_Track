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

# Generate a JavaScript config file for direct import in browser
generate_js_config() {
  local output_file="$1"
  if [ -n "$output_file" ]; then
    cat > "$output_file" << EOF
// Auto-generated from config.sh - DO NOT EDIT MANUALLY
const CONFIG = {
  BACKEND_PORT: ${BACKEND_PORT},
  FRONTEND_PORT: ${FRONTEND_PORT},
  DATABASE_PORT: ${DATABASE_PORT},
  BACKEND_URL: "http://183.82.114.29:${BACKEND_PORT}",
  FRONTEND_URL: "http://183.82.114.29:${FRONTEND_PORT}",
  WS_URL: "ws://183.82.114.29:${BACKEND_PORT}/ws"
};
export default CONFIG;
EOF
    echo "Generated JavaScript config file at $output_file"
  fi
}

# This line is to confirm the config file has been loaded when sourced
echo "Loaded port configuration: Backend=$BACKEND_PORT, Frontend=$FRONTEND_PORT, Database=$DATABASE_PORT"
