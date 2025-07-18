#!/bin/bash

# ===================================================================
# Surveyor Tracking Dashboard - Production Deployment Script
# ===================================================================
# This script compiles and packages the entire application for production
# - Builds the Spring Boot backend JAR
# - Builds the React frontend for production
# - Creates deployment package with all necessary files
# ===================================================================

set -e  # Exit on any error

# Parse command line arguments
RUN_TESTS=false
SKIP_FRONTEND=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --run-tests)
            RUN_TESTS=true
            shift
            ;;
        --skip-frontend)
            SKIP_FRONTEND=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --run-tests      Run backend tests before building (default: skip)"
            echo "  --skip-frontend  Skip frontend build (use existing build)"
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

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT=$(pwd)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="surveyor-tracking-production-${TIMESTAMP}"
PACKAGE_DIR="${PROJECT_ROOT}/${PACKAGE_NAME}"
BACKEND_DIR="${PROJECT_ROOT}/SurveyorTrackingBackend"
FRONTEND_DIR="${PROJECT_ROOT}/surveyor-tracking-dashboard"
DEPLOY_SOURCE="${PROJECT_ROOT}/deploy"

echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          SURVEYOR TRACKING DEPLOYMENT           ║${NC}"
echo -e "${CYAN}║              Production Package Builder          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📁 Project root: ${PROJECT_ROOT}${NC}"
echo -e "${BLUE}📦 Package name: ${PACKAGE_NAME}${NC}"
echo -e "${BLUE}🏗️  Build timestamp: ${TIMESTAMP}${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print step headers
print_step() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔄 $1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Step 1: Checking Prerequisites"
    
    local all_good=true
    
    # Check Java
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        echo -e "${GREEN}✅ Java found: ${JAVA_VERSION}${NC}"
    else
        echo -e "${RED}❌ Java not found. Please install Java 17 or higher.${NC}"
        all_good=false
    fi
    
    # Check Maven
    if command_exists mvn; then
        MVN_VERSION=$(mvn -version | head -n 1 | cut -d' ' -f3)
        echo -e "${GREEN}✅ Maven found: ${MVN_VERSION}${NC}"
    else
        echo -e "${RED}❌ Maven not found. Please install Maven.${NC}"
        all_good=false
    fi
    
    # Check Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}✅ Node.js found: ${NODE_VERSION}${NC}"
    else
        echo -e "${RED}❌ Node.js not found. Please install Node.js.${NC}"
        all_good=false
    fi
    
    # Check npm
    if command_exists npm; then
        NPM_VERSION=$(npm --version)
        echo -e "${GREEN}✅ npm found: ${NPM_VERSION}${NC}"
    else
        echo -e "${RED}❌ npm not found. Please install npm.${NC}"
        all_good=false
    fi
    
    # Check directories
    if [ -d "$BACKEND_DIR" ]; then
        echo -e "${GREEN}✅ Backend directory found${NC}"
    else
        echo -e "${RED}❌ Backend directory not found: ${BACKEND_DIR}${NC}"
        all_good=false
    fi
    
    if [ -d "$FRONTEND_DIR" ]; then
        echo -e "${GREEN}✅ Frontend directory found${NC}"
    else
        echo -e "${RED}❌ Frontend directory not found: ${FRONTEND_DIR}${NC}"
        all_good=false
    fi
    
    if [ -d "$DEPLOY_SOURCE" ]; then
        echo -e "${GREEN}✅ Deploy directory found${NC}"
    else
        echo -e "${RED}❌ Deploy directory not found: ${DEPLOY_SOURCE}${NC}"
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        echo -e "\n${RED}❌ Prerequisites check failed. Please fix the issues above and try again.${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}✅ All prerequisites satisfied!${NC}"
}

# Function to build backend
build_backend() {
    print_step "Step 2: Building Spring Boot Backend"
    
    cd "$BACKEND_DIR"
    echo -e "${BLUE}📂 Current directory: $(pwd)${NC}"
    
    # Clean previous builds
    echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
    mvn clean -q
    
    # Option to run tests (disabled by default for production builds)
    if [ "$RUN_TESTS" = "true" ]; then
        echo -e "${YELLOW}🧪 Running tests...${NC}"
        mvn test -q
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Tests failed! Use --skip-tests or fix the test issues.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⏭️  Skipping tests (use --run-tests to enable)${NC}"
    fi
    
    # Build JAR
    echo -e "${YELLOW}🏗️  Building production JAR...${NC}"
    mvn package -DskipTests -q
    
    # Check if JAR was created
    JAR_FILE=$(find target -name "*.jar" -not -name "*sources.jar" | head -1)
    if [ -f "$JAR_FILE" ]; then
        JAR_SIZE=$(du -h "$JAR_FILE" | cut -f1)
        echo -e "${GREEN}✅ Backend JAR built successfully: ${JAR_FILE} (${JAR_SIZE})${NC}"
    else
        echo -e "${RED}❌ Backend JAR build failed!${NC}"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Function to build frontend
build_frontend() {
    if [ "$SKIP_FRONTEND" = "true" ]; then
        print_step "Step 3: Checking Existing Frontend Build"
        
        if [ -d "$FRONTEND_DIR/build" ]; then
            BUILD_SIZE=$(du -sh "$FRONTEND_DIR/build" | cut -f1)
            FILE_COUNT=$(find "$FRONTEND_DIR/build" -type f | wc -l)
            echo -e "${GREEN}✅ Using existing frontend build: build/ (${BUILD_SIZE}, ${FILE_COUNT} files)${NC}"
        else
            echo -e "${RED}❌ No existing frontend build found! Cannot skip frontend build.${NC}"
            exit 1
        fi
        return
    fi
    
    print_step "Step 3: Building React Frontend"
    
    cd "$FRONTEND_DIR"
    echo -e "${BLUE}📂 Current directory: $(pwd)${NC}"
    
    # Install dependencies
    echo -e "${YELLOW}📦 Installing/updating dependencies...${NC}"
    npm install --silent
    
    # Run setup script to configure ports
    echo -e "${YELLOW}⚙️  Running setup script...${NC}"
    npm run setup --silent
    
    # Build for production
    echo -e "${YELLOW}🏗️  Building production build...${NC}"
    npm run build --silent
    
    # Check if build was successful
    if [ -d "build" ]; then
        BUILD_SIZE=$(du -sh build | cut -f1)
        FILE_COUNT=$(find build -type f | wc -l)
        echo -e "${GREEN}✅ Frontend built successfully: build/ (${BUILD_SIZE}, ${FILE_COUNT} files)${NC}"
    else
        echo -e "${RED}❌ Frontend build failed!${NC}"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Function to create deployment package
create_package() {
    print_step "Step 4: Creating Deployment Package"
    
    # Create package directory
    echo -e "${YELLOW}📁 Creating package directory...${NC}"
    mkdir -p "$PACKAGE_DIR"
    
    # Copy deploy directory structure
    echo -e "${YELLOW}📋 Copying deployment configuration...${NC}"
    cp -r "$DEPLOY_SOURCE"/* "$PACKAGE_DIR/"
    
    # Copy backend JAR
    echo -e "${YELLOW}📦 Copying backend JAR...${NC}"
    JAR_FILE=$(find "$BACKEND_DIR/target" -name "*.jar" -not -name "*sources.jar" | head -1)
    if [ -f "$JAR_FILE" ]; then
        cp "$JAR_FILE" "$PACKAGE_DIR/surveyor-tracking-backend.jar"
        echo -e "${GREEN}✅ Backend JAR copied${NC}"
    else
        echo -e "${RED}❌ Backend JAR not found!${NC}"
        exit 1
    fi
    
    # Copy frontend build
    echo -e "${YELLOW}🌐 Copying frontend build...${NC}"
    if [ -d "$FRONTEND_DIR/build" ]; then
        rm -rf "$PACKAGE_DIR/frontend/build"
        cp -r "$FRONTEND_DIR/build" "$PACKAGE_DIR/frontend/"
        echo -e "${GREEN}✅ Frontend build copied${NC}"
    else
        echo -e "${RED}❌ Frontend build not found!${NC}"
        exit 1
    fi
    
    # Make scripts executable
    echo -e "${YELLOW}🔧 Making scripts executable...${NC}"
    find "$PACKAGE_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # Create deployment instructions
    create_deployment_docs
    
    # Create version info
    create_version_info
    
    echo -e "${GREEN}✅ Deployment package created successfully!${NC}"
}

# Function to create deployment documentation
create_deployment_docs() {
    echo -e "${YELLOW}📄 Creating deployment documentation...${NC}"
    
    cat > "$PACKAGE_DIR/DEPLOYMENT_GUIDE.md" << EOF
# Surveyor Tracking Dashboard - Production Deployment Guide

## Package Information
- **Build Date**: $(date)
- **Package Name**: ${PACKAGE_NAME}
- **Built From**: $(git rev-parse --short HEAD 2>/dev/null || echo "N/A")

## Server Requirements
- **Java**: 17 or higher
- **Memory**: Minimum 2GB RAM
- **Disk**: Minimum 1GB free space
- **Network**: Ports 6565 (backend) and 9898 (frontend) available

## Deployment Steps

### 1. Upload Package
\`\`\`bash
scp -r ${PACKAGE_NAME}.tar.gz neogeo@183.82.114.29:/home/neogeo/
\`\`\`

### 2. Extract on Server
\`\`\`bash
ssh neogeo@183.82.114.29
cd /home/neogeo/
tar -xzf ${PACKAGE_NAME}.tar.gz
cd ${PACKAGE_NAME}
\`\`\`

### 3. Stop Existing Services
\`\`\`bash
./stop.sh
\`\`\`

### 4. Start New Services
\`\`\`bash
./start.sh
\`\`\`

### 5. Verify Deployment
- Backend: http://183.82.114.29:6565/api/health
- Frontend: http://183.82.114.29:9898

## Files Included
- \`surveyor-tracking-backend.jar\` - Backend application
- \`frontend/build/\` - Frontend static files
- \`start.sh\` - Start all services
- \`stop.sh\` - Stop all services
- \`config.sh\` - Port configuration
- \`nginx.conf.template\` - Nginx configuration template

## Configuration
Edit \`config.sh\` to change port numbers if needed.

## Logs
- Backend logs: Check application output
- Frontend logs: Check web browser console
- System logs: \`journalctl -f\`

## Troubleshooting
1. Check Java version: \`java -version\`
2. Check ports: \`netstat -tulpn | grep -E '(6565|9898)'\`
3. Check processes: \`ps aux | grep java\`
4. Check disk space: \`df -h\`

## Rollback
Keep previous deployment package for quick rollback if needed.
EOF
}

# Function to create version info
create_version_info() {
    echo -e "${YELLOW}🏷️  Creating version info...${NC}"
    
    cat > "$PACKAGE_DIR/VERSION_INFO.txt" << EOF
Surveyor Tracking Dashboard - Production Build
==============================================

Build Information:
------------------
Timestamp: $(date)
Builder: $(whoami)
Host: $(hostname)
Package: ${PACKAGE_NAME}

Git Information:
---------------
$(if command_exists git; then
    echo "Commit: $(git rev-parse HEAD 2>/dev/null || echo 'N/A')"
    echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')"
    echo "Tag: $(git describe --tags --exact-match 2>/dev/null || echo 'N/A')"
    echo "Status: $(git status --porcelain 2>/dev/null | wc -l | xargs echo) modified files"
else
    echo "Git not available"
fi)

Component Versions:
------------------
$(java -version 2>&1 | head -1 || echo "Java: N/A")
$(mvn -version 2>/dev/null | head -1 || echo "Maven: N/A")
$(node --version 2>/dev/null | sed 's/^/Node.js: /' || echo "Node.js: N/A")
$(npm --version 2>/dev/null | sed 's/^/npm: /' || echo "npm: N/A")

Build Artifacts:
---------------
Backend JAR: $(ls -la "$PACKAGE_DIR/surveyor-tracking-backend.jar" 2>/dev/null | awk '{print $9 " (" $5 " bytes)"}' || echo "Not found")
Frontend Build: $(find "$PACKAGE_DIR/frontend/build" -type f 2>/dev/null | wc -l | xargs echo) files

Configuration:
-------------
Backend Port: 6565
Frontend Port: 9898
Database Port: 5432
EOF
}

# Function to create archive
create_archive() {
    print_step "Step 5: Creating Archive"
    
    echo -e "${YELLOW}🗜️  Creating compressed archive...${NC}"
    tar -czf "${PACKAGE_NAME}.tar.gz" -C "$PROJECT_ROOT" "$PACKAGE_NAME"
    
    if [ -f "${PACKAGE_NAME}.tar.gz" ]; then
        ARCHIVE_SIZE=$(du -h "${PACKAGE_NAME}.tar.gz" | cut -f1)
        echo -e "${GREEN}✅ Archive created: ${PACKAGE_NAME}.tar.gz (${ARCHIVE_SIZE})${NC}"
    else
        echo -e "${RED}❌ Archive creation failed!${NC}"
        exit 1
    fi
}

# Function to show summary
show_summary() {
    print_step "Deployment Package Summary"
    
    echo -e "${CYAN}📦 Package Details:${NC}"
    echo -e "   Name: ${PACKAGE_NAME}"
    echo -e "   Location: ${PROJECT_ROOT}/${PACKAGE_NAME}/"
    echo -e "   Archive: ${PROJECT_ROOT}/${PACKAGE_NAME}.tar.gz"
    
    if [ -d "$PACKAGE_DIR" ]; then
        PACKAGE_SIZE=$(du -sh "$PACKAGE_DIR" | cut -f1)
        FILE_COUNT=$(find "$PACKAGE_DIR" -type f | wc -l)
        echo -e "   Size: ${PACKAGE_SIZE} (${FILE_COUNT} files)"
    fi
    
    if [ -f "${PACKAGE_NAME}.tar.gz" ]; then
        ARCHIVE_SIZE=$(du -h "${PACKAGE_NAME}.tar.gz" | cut -f1)
        echo -e "   Archive Size: ${ARCHIVE_SIZE}"
    fi
    
    echo -e "\n${CYAN}🚀 Next Steps:${NC}"
    echo -e "   1. Review the deployment guide: ${PACKAGE_DIR}/DEPLOYMENT_GUIDE.md"
    echo -e "   2. Upload to production server:"
    echo -e "      ${BLUE}scp ${PACKAGE_NAME}.tar.gz neogeo@183.82.114.29:/home/neogeo/${NC}"
    echo -e "   3. Deploy on server:"
    echo -e "      ${BLUE}ssh neogeo@183.82.114.29${NC}"
    echo -e "      ${BLUE}cd /home/neogeo && tar -xzf ${PACKAGE_NAME}.tar.gz${NC}"
    echo -e "      ${BLUE}cd ${PACKAGE_NAME} && ./stop.sh && ./start.sh${NC}"
    
    echo -e "\n${GREEN}✅ Production package ready for deployment!${NC}"
}

# Main execution
main() {
    echo -e "\n${BLUE}🔧 Configuration:${NC}"
    echo -e "   Run tests: ${RUN_TESTS}"
    echo -e "   Skip frontend: ${SKIP_FRONTEND}"
    echo ""
    
    check_prerequisites
    build_backend
    build_frontend
    create_package
    create_archive
    show_summary
}

# Trap errors and cleanup
trap 'echo -e "\n${RED}❌ Build failed! Check the output above for errors.${NC}"; exit 1' ERR

# Run main function
main

echo -e "\n${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            DEPLOYMENT BUILD COMPLETE            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
