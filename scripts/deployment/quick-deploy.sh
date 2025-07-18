#!/bin/bash

# ===================================================================
# Surveyor Tracking Dashboard - Quick Deployment Script
# ===================================================================
# This script quickly rebuilds and uploads to production server
# Use this for rapid development iterations
# ===================================================================

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT=$(pwd)
PRODUCTION_SERVER="neogeo@183.82.114.29"
PRODUCTION_PATH="/home/neogeo"

echo -e "${CYAN}🚀 QUICK DEPLOY - Surveyor Tracking Dashboard${NC}"
echo -e "${BLUE}Project: ${PROJECT_ROOT}${NC}"
echo -e "${BLUE}Server: ${PRODUCTION_SERVER}${NC}"
echo ""

# Parse command line arguments
BUILD_BACKEND=true
BUILD_FRONTEND=true
UPLOAD_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --frontend-only)
            BUILD_BACKEND=false
            shift
            ;;
        --backend-only)
            BUILD_FRONTEND=false
            shift
            ;;
        --upload-only)
            UPLOAD_ONLY=true
            BUILD_BACKEND=false
            BUILD_FRONTEND=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --frontend-only  Build and deploy only frontend"
            echo "  --backend-only   Build and deploy only backend"
            echo "  --upload-only    Upload existing production package"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🔧 Configuration:${NC}"
echo -e "   Build backend: ${BUILD_BACKEND}"
echo -e "   Build frontend: ${BUILD_FRONTEND}"
echo -e "   Upload only: ${UPLOAD_ONLY}"
echo ""

# Function to check if SSH connection works
check_ssh() {
    echo -e "${YELLOW}🔗 Testing SSH connection...${NC}"
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$PRODUCTION_SERVER" exit 2>/dev/null; then
        echo -e "${GREEN}✅ SSH connection successful${NC}"
    else
        echo -e "${RED}❌ Cannot connect to production server. Check SSH keys and network.${NC}"
        exit 1
    fi
}

# Function to find latest production package
find_latest_package() {
    LATEST_PACKAGE=$(find "$PROJECT_ROOT" -name "surveyor-tracking-production-*.tar.gz" -type f -exec ls -t {} + | head -1)
    if [ -z "$LATEST_PACKAGE" ]; then
        echo -e "${RED}❌ No production package found. Run build-production.sh first.${NC}"
        exit 1
    fi
    PACKAGE_NAME=$(basename "$LATEST_PACKAGE" .tar.gz)
    echo -e "${GREEN}📦 Found package: ${PACKAGE_NAME}${NC}"
}

# Function to build production package
build_package() {
    echo -e "${YELLOW}🏗️  Building production package...${NC}"
    
    local build_args=""
    if [ "$BUILD_BACKEND" = "false" ] && [ "$BUILD_FRONTEND" = "false" ]; then
        echo -e "${RED}❌ Cannot build with both backend and frontend disabled.${NC}"
        exit 1
    fi
    
    if [ "$BUILD_FRONTEND" = "false" ]; then
        build_args="--skip-frontend"
    fi
    
    ./scripts/deployment/build-production.sh $build_args
    
    # Find the newly created package
    find_latest_package
}

# Function to upload to production
upload_package() {
    echo -e "${YELLOW}📤 Uploading to production server...${NC}"
    
    scp "$LATEST_PACKAGE" "$PRODUCTION_SERVER:$PRODUCTION_PATH/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Upload successful${NC}"
    else
        echo -e "${RED}❌ Upload failed${NC}"
        exit 1
    fi
}

# Function to deploy on server
deploy_on_server() {
    echo -e "${YELLOW}🚀 Deploying on production server...${NC}"
    
    ssh "$PRODUCTION_SERVER" << EOF
cd $PRODUCTION_PATH
echo "📁 Current directory: \$(pwd)"

# Extract new package
echo "📦 Extracting package..."
tar -xzf ${PACKAGE_NAME}.tar.gz

# Stop existing services
echo "🛑 Stopping existing services..."
if [ -f ${PACKAGE_NAME}/stop.sh ]; then
    cd ${PACKAGE_NAME}
    ./stop.sh || echo "No existing services to stop"
else
    echo "stop.sh not found, skipping service stop"
fi

# Start new services
echo "▶️  Starting new services..."
./start.sh

echo "✅ Deployment complete!"
echo "🌐 Frontend: http://183.82.114.29:9898"
echo "🔗 Backend: http://183.82.114.29:6565"
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Deployment successful!${NC}"
    else
        echo -e "${RED}❌ Deployment failed${NC}"
        exit 1
    fi
}

# Function to show summary
show_summary() {
    echo -e "\n${CYAN}🎉 QUICK DEPLOY COMPLETE${NC}"
    echo -e "${GREEN}✅ Application deployed successfully!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Access your application:${NC}"
    echo -e "   Frontend: http://183.82.114.29:9898"
    echo -e "   Backend:  http://183.82.114.29:6565"
    echo -e "   Health:   http://183.82.114.29:6565/api/health"
    echo ""
    echo -e "${YELLOW}📝 To check logs on server:${NC}"
    echo -e "   ssh $PRODUCTION_SERVER"
    echo -e "   cd $PRODUCTION_PATH/${PACKAGE_NAME}"
    echo -e "   tail -f backend.log"
    echo -e "   tail -f frontend.log"
}

# Main execution
main() {
    check_ssh
    
    if [ "$UPLOAD_ONLY" = "true" ]; then
        find_latest_package
    else
        build_package
    fi
    
    upload_package
    deploy_on_server
    show_summary
}

# Trap errors and cleanup
trap 'echo -e "\n${RED}❌ Quick deploy failed! Check the output above for errors.${NC}"; exit 1' ERR

# Run main function
main

echo -e "\n${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              QUICK DEPLOY COMPLETE              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
