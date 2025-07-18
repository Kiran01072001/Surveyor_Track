#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Import config.sh if it exists, otherwise set defaults
if [ -f "./deploy/config.sh" ]; then
    echo "Loading port configuration from config.sh"
    source ./deploy/config.sh
else
    echo "Using default port configuration"
    BACKEND_PORT=6565
    FRONTEND_PORT=9898
    DATABASE_PORT=5432
fi

echo -e "${GREEN}Starting deployment process...${NC}"
echo "Using backend port: $BACKEND_PORT"
echo "Using frontend port: $FRONTEND_PORT"

# Build Backend
echo -e "\n${GREEN}Building Spring Boot Backend...${NC}"
cd SurveyorTrackingBackend
./mvnw clean package -DskipTests
if [ $? -ne 0 ]; then
    echo -e "${RED}Backend build failed!${NC}"
    exit 1
fi
echo -e "${GREEN}Backend built successfully!${NC}"

# Build Frontend
echo -e "\n${GREEN}Building React Frontend...${NC}"
cd ../surveyor-tracking-dashboard
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}Frontend npm install failed!${NC}"
    exit 1
fi

# Use the custom build script that incorporates port configuration
npm run build:config
if [ $? -ne 0 ]; then
    echo -e "${RED}Frontend build failed!${NC}"
    exit 1
fi
echo -e "${GREEN}Frontend built successfully!${NC}"

# Create deployment directory
echo -e "\n${GREEN}Preparing deployment files...${NC}"
cd ..
mkdir -p deploy

# Backup config.sh if it exists
if [ -f deploy/config.sh ]; then
    cp deploy/config.sh deploy/config.sh.backup
fi

# Clean deploy directory but preserve config files
find deploy -type f ! -name "config.sh*" ! -name "*.template" -delete

# Copy backend jar
cp SurveyorTrackingBackend/target/*.jar deploy/surveyor-tracking-backend.jar

# Copy frontend build
cp -r surveyor-tracking-dashboard/build deploy/frontend

# Create startup script
echo -e "\n${GREEN}Creating startup script...${NC}"
cat > deploy/start.sh << 'EOL'
#!/bin/bash

# Load configuration
if [ -f "config.sh" ]; then
    source config.sh
else
    echo "Warning: config.sh not found, using defaults"
    BACKEND_PORT=6565
    FRONTEND_PORT=9898
fi

# Start Backend
echo "Starting Spring Boot Backend on port $BACKEND_PORT..."
nohup java -jar surveyor-tracking-backend.jar > backend.log 2>&1 &
echo $! > backend.pid

# Serve Frontend with nginx if installed, otherwise use serve
if command -v nginx >/dev/null 2>&1; then
    echo "Nginx detected, configuring and starting nginx..."
    
    # Get current directory (deployment directory)
    DEPLOY_DIR=$(pwd)
    FRONTEND_PATH="$DEPLOY_DIR/frontend"
    
    # Create nginx configuration from template
    if [ -f "nginx.conf.template" ]; then
        echo "Creating nginx configuration..."
        sed -e "s|/path/to/frontend|$FRONTEND_PATH|g" \
            -e "s|\$BACKEND_PORT|$BACKEND_PORT|g" \
            -e "s|\$FRONTEND_PORT|$FRONTEND_PORT|g" \
            nginx.conf.template > nginx.conf
        
        # Test nginx configuration
        nginx -t -c "$DEPLOY_DIR/nginx.conf"
        if [ $? -eq 0 ]; then
            echo "Starting nginx with custom configuration..."
            nginx -c "$DEPLOY_DIR/nginx.conf"
            echo "Nginx started successfully"
            echo "Frontend accessible on port 80 (http://localhost or http://your-server-ip)"
        else
            echo "Nginx configuration test failed, falling back to serve"
            echo "Installing serve..."
            npm install -g serve
            echo "Starting Frontend server on port $FRONTEND_PORT..."
            nohup serve -s frontend -l $FRONTEND_PORT > frontend.log 2>&1 &
            echo $! > frontend.pid
        fi
    else
        echo "nginx.conf.template not found, falling back to serve"
        echo "Installing serve..."
        npm install -g serve
        echo "Starting Frontend server on port $FRONTEND_PORT..."
        nohup serve -s frontend -l $FRONTEND_PORT > frontend.log 2>&1 &
        echo $! > frontend.pid
    fi
else
    echo "Nginx not found, using serve..."
    echo "Installing serve..."
    npm install -g serve
    echo "Starting Frontend server on port $FRONTEND_PORT..."
    nohup serve -s frontend -l $FRONTEND_PORT > frontend.log 2>&1 &
    echo $! > frontend.pid
fi

echo "Deployment complete!"
echo "Backend running on port $BACKEND_PORT"
if command -v nginx >/dev/null 2>&1 && [ -f nginx.conf ]; then
    echo "Frontend served by nginx on port 80"
    echo "Access your application at: http://183.82.114.29"
else
    echo "Frontend running on port $FRONTEND_PORT"
    echo "Access your application at: http://183.82.114.29:$FRONTEND_PORT"
fi
EOL
EOL

# Create stop script
cat > deploy/stop.sh << 'EOL'
#!/bin/bash

# Stop Backend
if [ -f backend.pid ]; then
    echo "Stopping backend..."
    kill $(cat backend.pid)
    rm backend.pid
    echo "Backend stopped"
else
    echo "Backend PID file not found"
fi

# Stop Frontend (serve)
if [ -f frontend.pid ]; then
    echo "Stopping frontend (serve)..."
    kill $(cat frontend.pid)
    rm frontend.pid
    echo "Frontend (serve) stopped"
fi

# Stop Nginx if it's running with our config
if [ -f nginx.conf ]; then
    echo "Stopping nginx..."
    nginx -s quit -c "$(pwd)/nginx.conf" 2>/dev/null || nginx -s stop 2>/dev/null
    echo "Nginx stopped"
fi

echo "All services stopped"
EOL

# Create nginx configuration template
cat > deploy/nginx.conf.template << 'EOL'
server {
    listen 80;
    server_name localhost;

    # Frontend
    location / {
        root /path/to/frontend;
        try_files $uri $uri/ /index.html;
        index index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSocket endpoint
    location /ws {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
EOL

# Make scripts executable
chmod +x deploy/start.sh deploy/stop.sh

# Restore config.sh if it was backed up
if [ -f deploy/config.sh.backup ]; then
    cp deploy/config.sh.backup deploy/config.sh
    rm deploy/config.sh.backup
elif [ ! -f deploy/config.sh ]; then
    # Create default config.sh if it doesn't exist
    cat > deploy/config.sh << 'CONFIG_EOF'
#!/bin/bash
# Centralized port configuration for deployment
BACKEND_PORT=6565
FRONTEND_PORT=9898
DATABASE_PORT=5432
export BACKEND_PORT FRONTEND_PORT DATABASE_PORT
echo "Loaded port configuration: Backend=$BACKEND_PORT, Frontend=$FRONTEND_PORT, Database=$DATABASE_PORT"
CONFIG_EOF
    chmod +x deploy/config.sh
fi

echo -e "${GREEN}Deployment package created successfully!${NC}"
echo -e "\nDeployment instructions:"
echo "1. Copy the 'deploy' directory to your production server"
echo "2. Configure application.properties in the JAR if needed"
echo "3. Configure nginx.conf.template with your domain"
echo "4. Run ./start.sh to start the application"
echo "5. Use ./stop.sh to stop the application"
