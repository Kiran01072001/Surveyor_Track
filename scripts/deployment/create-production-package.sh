#!/bin/bash

# Production Deployment Package Creator
# This script creates a complete deployment package for the production server

echo "🚀 Creating Production Deployment Package..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current directory
PROJECT_ROOT=$(pwd)
PACKAGE_NAME="surveyor-tracking-production-$(date +%Y%m%d_%H%M%S)"
PACKAGE_DIR="$PROJECT_ROOT/$PACKAGE_NAME"

echo -e "${BLUE}Project root: $PROJECT_ROOT${NC}"
echo -e "${BLUE}Package name: $PACKAGE_NAME${NC}"

# Create package directory
mkdir -p "$PACKAGE_DIR"

echo -e "\n${YELLOW}Step 1: Copying deployment artifacts...${NC}"

# Copy the entire deploy directory
if [ -d "deploy" ]; then
    cp -r deploy/* "$PACKAGE_DIR/"
    echo "✅ Deploy directory copied"
else
    echo "❌ Deploy directory not found!"
    exit 1
fi

# Ensure scripts are executable
chmod +x "$PACKAGE_DIR"/*.sh

echo -e "\n${YELLOW}Step 2: Creating production-specific files...${NC}"

# Create production deployment instructions
cat > "$PACKAGE_DIR/DEPLOY_INSTRUCTIONS.md" << 'EOF'
# Production Deployment Instructions

## Server: neogeo@183.82.114.29

### Prerequisites
1. Java 17 or higher
2. Node.js and npm (for serve package as fallback)
3. Nginx (optional but recommended)

### Deployment Steps

1. **Upload the package to the server:**
   ```bash
   scp -r surveyor-tracking-production-* neogeo@183.82.114.29:~/
   ```

2. **SSH to the server:**
   ```bash
   ssh neogeo@183.82.114.29
   ```

3. **Navigate to the deployment directory:**
   ```bash
   cd surveyor-tracking-production-*
   ```

4. **Check prerequisites (optional):**
   ```bash
   ./check-prerequisites.sh
   ```

5. **Setup nginx configuration (if nginx is available):**
   ```bash
   ./setup-nginx.sh
   ```

6. **Start the application:**
   ```bash
   ./start.sh
   ```

7. **Verify deployment:**
   - Backend API: http://183.82.114.29/api/surveyors
   - Frontend: http://183.82.114.29 (nginx) or http://183.82.114.29:9898 (serve)

8. **Check status:**
   ```bash
   ./check-status.sh
   ```

### Stopping the Application
```bash
./stop.sh
```

### Logs
- Backend: `backend.log`
- Frontend (serve): `frontend.log`
- Nginx: Check system nginx logs

### Configuration
- Edit `config.sh` to change ports
- Restart application after configuration changes

### Troubleshooting
1. Check if ports are available: `netstat -tulpn | grep :PORT`
2. Check firewall: `sudo ufw status`
3. Check logs: `tail -f backend.log`
4. Test backend directly: `curl http://183.82.114.29:6565/api/surveyors`
EOF

# Create a comprehensive status check script for production
cat > "$PACKAGE_DIR/check-status.sh" << 'EOF'
#!/bin/bash

# Production Status Checker
echo "🔍 Checking Surveyor Tracking Application Status..."

# Load configuration
if [ -f "config.sh" ]; then
    source config.sh
else
    BACKEND_PORT=6565
    FRONTEND_PORT=9898
fi

echo "Configuration: Backend=$BACKEND_PORT, Frontend=$FRONTEND_PORT"
echo ""

# Check if processes are running
echo "📊 Process Status:"
if [ -f backend.pid ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ Backend is running (PID: $BACKEND_PID)"
    else
        echo "❌ Backend PID file exists but process is not running"
        rm backend.pid
    fi
else
    echo "❌ Backend is not running (no PID file)"
fi

if [ -f frontend.pid ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "✅ Frontend (serve) is running (PID: $FRONTEND_PID)"
    else
        echo "❌ Frontend PID file exists but process is not running"
        rm frontend.pid
    fi
else
    echo "ℹ️  Frontend (serve) is not running (might be using nginx)"
fi

# Check nginx
if command -v nginx >/dev/null 2>&1; then
    if pgrep nginx > /dev/null; then
        echo "✅ Nginx is running"
    else
        echo "⚠️  Nginx is installed but not running"
    fi
else
    echo "ℹ️  Nginx is not installed"
fi

echo ""

# Check port availability
echo "🔌 Port Status:"
if netstat -tuln 2>/dev/null | grep -q ":$BACKEND_PORT "; then
    echo "✅ Backend port $BACKEND_PORT is in use"
else
    echo "❌ Backend port $BACKEND_PORT is not in use"
fi

if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    echo "✅ HTTP port 80 is in use (likely nginx)"
elif netstat -tuln 2>/dev/null | grep -q ":$FRONTEND_PORT "; then
    echo "✅ Frontend port $FRONTEND_PORT is in use"
else
    echo "❌ No frontend port is in use"
fi

echo ""

# Test API endpoints
echo "🧪 API Tests:"
if curl -s --max-time 5 "http://localhost:$BACKEND_PORT/api/surveyors" > /dev/null; then
    echo "✅ Backend API is responding"
else
    echo "❌ Backend API is not responding"
fi

if curl -s --max-time 5 "http://localhost/api/surveyors" > /dev/null; then
    echo "✅ Frontend proxy to backend is working"
elif curl -s --max-time 5 "http://localhost:$FRONTEND_PORT" > /dev/null; then
    echo "✅ Frontend is accessible on port $FRONTEND_PORT"
else
    echo "❌ Frontend is not accessible"
fi

echo ""

# File checks
echo "📁 File Status:"
if [ -f "surveyor-tracking-backend.jar" ]; then
    echo "✅ Backend JAR file exists"
else
    echo "❌ Backend JAR file missing"
fi

if [ -d "frontend" ] && [ -f "frontend/index.html" ]; then
    echo "✅ Frontend files exist"
else
    echo "❌ Frontend files missing"
fi

if [ -f "nginx.conf" ]; then
    echo "✅ Nginx configuration exists"
else
    echo "ℹ️  Nginx configuration not generated"
fi

echo ""
echo "📋 Summary:"
echo "Access your application at:"
echo "  - http://183.82.114.29 (if nginx is running)"
echo "  - http://183.82.114.29:$FRONTEND_PORT (if using serve)"
echo "  - Backend API: http://183.82.114.29/api (via nginx) or http://183.82.114.29:$BACKEND_PORT/api"
EOF

# Create prerequisites checker
cat > "$PACKAGE_DIR/check-prerequisites.sh" << 'EOF'
#!/bin/bash

echo "🔍 Checking Production Server Prerequisites..."

# Check Java
echo "☕ Java:"
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✅ Java is installed: $JAVA_VERSION"
    
    # Check if it's Java 17 or higher
    JAVA_MAJOR=$(java -version 2>&1 | grep -oP 'version "?(1\.)?\K\d+' | head -1)
    if [ "$JAVA_MAJOR" -ge 17 ]; then
        echo "✅ Java version is compatible (17+)"
    else
        echo "⚠️  Java version might be too old. Java 17+ recommended."
    fi
else
    echo "❌ Java is not installed"
    echo "   Install with: sudo apt update && sudo apt install openjdk-17-jdk"
fi

echo ""

# Check Node.js
echo "📦 Node.js:"
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js is installed: $NODE_VERSION"
else
    echo "❌ Node.js is not installed"
    echo "   Install with: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
fi

# Check npm
if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm is installed: $NPM_VERSION"
else
    echo "❌ npm is not installed"
fi

echo ""

# Check Nginx
echo "🌐 Nginx:"
if command -v nginx >/dev/null 2>&1; then
    NGINX_VERSION=$(nginx -version 2>&1)
    echo "✅ Nginx is installed: $NGINX_VERSION"
else
    echo "⚠️  Nginx is not installed (optional)"
    echo "   Install with: sudo apt update && sudo apt install nginx"
fi

echo ""

# Check ports
echo "🔌 Port Availability:"
PORTS_TO_CHECK="80 6565 9898"
for port in $PORTS_TO_CHECK; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "⚠️  Port $port is in use"
    else
        echo "✅ Port $port is available"
    fi
done

echo ""

# Check firewall
echo "🔥 Firewall Status:"
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null || echo "Permission denied")
    echo "UFW: $UFW_STATUS"
    if [[ "$UFW_STATUS" == *"active"* ]]; then
        echo "⚠️  Firewall is active. Make sure ports 80, 6565, and 9898 are allowed"
        echo "   Allow with: sudo ufw allow 80 && sudo ufw allow 6565 && sudo ufw allow 9898"
    fi
else
    echo "UFW not found, checking iptables..."
    if command -v iptables >/dev/null 2>&1; then
        echo "iptables is available (manual firewall check required)"
    else
        echo "No common firewall tools found"
    fi
fi

echo ""
echo "🎯 Prerequisites Summary:"
echo "✅ = Ready  ⚠️ = Needs attention  ❌ = Missing"
EOF

# Make all scripts executable
chmod +x "$PACKAGE_DIR"/*.sh

echo -e "\n${YELLOW}Step 3: Creating transfer scripts...${NC}"

# Create upload script for easy deployment
cat > "$PROJECT_ROOT/upload-to-production.sh" << EOF
#!/bin/bash

# Upload deployment package to production server
echo "🚀 Uploading deployment package to production server..."

PACKAGE_DIR="$PACKAGE_NAME"

if [ ! -d "\$PACKAGE_DIR" ]; then
    echo "❌ Package directory not found: \$PACKAGE_DIR"
    echo "Run ./create-production-package.sh first"
    exit 1
fi

echo "📦 Uploading \$PACKAGE_DIR to neogeo@183.82.114.29..."

# Upload the package
scp -r "\$PACKAGE_DIR" neogeo@183.82.114.29:~/

if [ \$? -eq 0 ]; then
    echo "✅ Upload completed successfully!"
    echo ""
    echo "🔗 Next steps:"
    echo "1. SSH to the server: ssh neogeo@183.82.114.29"
    echo "2. Navigate to the package: cd \$PACKAGE_DIR"
    echo "3. Check prerequisites: ./check-prerequisites.sh"
    echo "4. Start the application: ./start.sh"
    echo "5. Check status: ./check-status.sh"
    echo ""
    echo "🌐 Once deployed, access your application at:"
    echo "   http://183.82.114.29"
else
    echo "❌ Upload failed!"
    exit 1
fi
EOF

chmod +x "$PROJECT_ROOT/upload-to-production.sh"

echo -e "\n${YELLOW}Step 4: Creating final package summary...${NC}"

# Create package info
cat > "$PACKAGE_DIR/PACKAGE_INFO.txt" << EOF
Surveyor Tracking Production Package
===================================

Created: $(date)
Package: $PACKAGE_NAME
Target Server: neogeo@183.82.114.29

Contents:
- surveyor-tracking-backend.jar (Spring Boot application)
- frontend/ (React build files)
- config.sh (Port configuration)
- start.sh (Application startup script)
- stop.sh (Application shutdown script)
- nginx.conf.template (Nginx configuration template)
- setup-nginx.sh (Nginx setup script)
- check-prerequisites.sh (System requirements checker)
- check-status.sh (Application status checker)
- DEPLOY_INSTRUCTIONS.md (Deployment guide)

Quick Start:
1. Upload: Use ../upload-to-production.sh
2. SSH: ssh neogeo@183.82.114.29
3. Deploy: cd $PACKAGE_NAME && ./start.sh

Application URLs:
- Frontend: http://183.82.114.29
- Backend API: http://183.82.114.29/api
- Direct Backend: http://183.82.114.29:6565/api
EOF

echo -e "\n${GREEN}✅ Production package created successfully!${NC}"
echo -e "\n📦 Package location: ${BLUE}$PACKAGE_DIR${NC}"
echo -e "\n🚀 To deploy to production server:"
echo -e "   ${YELLOW}./upload-to-production.sh${NC}"
echo -e "\n📋 Package contents:"
ls -la "$PACKAGE_DIR"

echo -e "\n${GREEN}Ready for production deployment! 🎉${NC}"
