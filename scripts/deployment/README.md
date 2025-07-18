# Surveyor Tracking Dashboard - Deployment Scripts

This directory contains comprehensive deployment scripts for the Surveyor Tracking Dashboard project.

## 🚀 Quick Start

For a complete production build and deployment:

```bash
./scripts/deployment/build-production.sh
```

For rapid development iterations:

```bash
./scripts/deployment/quick-deploy.sh
```

## 📁 Available Scripts

### 1. `build-production.sh` - Complete Production Build

**Purpose**: Creates a complete, production-ready deployment package.

**Features**:
- ✅ Prerequisites checking (Java, Maven, Node.js, npm)
- 🏗️ Builds Spring Boot backend JAR (54MB)
- 🌐 Builds React frontend for production (6.9MB)
- 📦 Creates timestamped deployment package
- 📄 Generates deployment documentation
- 🗜️ Creates compressed archive (50MB)
- 🏷️ Includes version and build information

**Usage**:
```bash
# Standard production build
./scripts/deployment/build-production.sh

# Build with tests (disabled by default)
./scripts/deployment/build-production.sh --run-tests

# Skip frontend build (use existing build)
./scripts/deployment/build-production.sh --skip-frontend

# Show help
./scripts/deployment/build-production.sh --help
```

**Output**:
- Directory: `surveyor-tracking-production-YYYYMMDD_HHMMSS/`
- Archive: `surveyor-tracking-production-YYYYMMDD_HHMMSS.tar.gz`
- Documentation: `DEPLOYMENT_GUIDE.md` and `VERSION_INFO.txt`

### 2. `quick-deploy.sh` - Rapid Development Deployment

**Purpose**: Quick build and deployment to production server for development iterations.

**Features**:
- 🔗 SSH connection testing
- 🏗️ Calls build-production.sh
- 📤 Uploads to production server via SCP
- 🚀 Deploys and starts services on server
- 🛑 Stops existing services first

**Usage**:
```bash
# Full build and deploy
./scripts/deployment/quick-deploy.sh

# Frontend only
./scripts/deployment/quick-deploy.sh --frontend-only

# Backend only
./scripts/deployment/quick-deploy.sh --backend-only

# Upload existing package
./scripts/deployment/quick-deploy.sh --upload-only

# Show help
./scripts/deployment/quick-deploy.sh --help
```

**Requirements**:
- SSH key authentication to `neogeo@183.82.114.29`
- Network connectivity to production server

### 3. `create-production-package.sh` - Legacy Script

**Purpose**: Older version of production packaging (kept for reference).

**Status**: ⚠️ Legacy - Use `build-production.sh` instead.

### 4. `deploy.sh` - Legacy Deployment

**Purpose**: Original deployment script.

**Status**: ⚠️ Legacy - Use `build-production.sh` + `quick-deploy.sh` instead.

### 5. Other Scripts

- `upload-to-production.sh` - Simple upload utility
- `start-with-*.sh` - Development startup scripts with different configurations

## 🏭 Production Deployment Process

### Step 1: Build Production Package

```bash
cd /path/to/Tracking
./scripts/deployment/build-production.sh
```

This creates:
```
surveyor-tracking-production-YYYYMMDD_HHMMSS/
├── surveyor-tracking-backend.jar     # Spring Boot JAR (54MB)
├── frontend/build/                   # React production build
├── start.sh                          # Service startup script
├── stop.sh                           # Service shutdown script
├── config.sh                         # Port configuration
├── nginx.conf.template               # Nginx configuration
├── DEPLOYMENT_GUIDE.md               # Deployment instructions
└── VERSION_INFO.txt                  # Build information
```

### Step 2: Manual Upload (if not using quick-deploy.sh)

```bash
scp surveyor-tracking-production-YYYYMMDD_HHMMSS.tar.gz neogeo@183.82.114.29:/home/neogeo/
```

### Step 3: Deploy on Server

```bash
ssh neogeo@183.82.114.29
cd /home/neogeo/
tar -xzf surveyor-tracking-production-YYYYMMDD_HHMMSS.tar.gz
cd surveyor-tracking-production-YYYYMMDD_HHMMSS
./stop.sh    # Stop existing services
./start.sh   # Start new services
```

### Step 4: Verify Deployment

- **Frontend**: http://183.82.114.29:9898
- **Backend**: http://183.82.114.29:6565
- **Health Check**: http://183.82.114.29:6565/api/health

## 🔧 Configuration

### Port Configuration

Edit `/deploy/config.sh`:

```bash
BACKEND_PORT=6565    # Spring Boot API
FRONTEND_PORT=9898   # React frontend
DATABASE_PORT=5432   # PostgreSQL
```

### Build Configuration

The frontend build automatically configures API endpoints based on the port settings in `config.sh`.

## 🐛 Troubleshooting

### Build Issues

1. **Java not found**: Install Java 17+
2. **Maven not found**: Install Apache Maven
3. **Node.js not found**: Install Node.js 16+
4. **npm not found**: Install npm

### Test Failures

Tests are skipped by default in production builds. To enable:

```bash
./scripts/deployment/build-production.sh --run-tests
```

### Deployment Issues

1. **SSH connection failed**: Check SSH keys and network
2. **Upload failed**: Check disk space and permissions
3. **Service start failed**: Check port availability and logs

### Log Checking

On production server:

```bash
cd /home/neogeo/surveyor-tracking-production-YYYYMMDD_HHMMSS
tail -f backend.log     # Backend logs
tail -f frontend.log    # Frontend logs (if using serve)
```

## 📊 Package Contents

A typical production package includes:

| Component | Size | Description |
|-----------|------|-------------|
| Backend JAR | ~54MB | Spring Boot application with embedded Tomcat |
| Frontend Build | ~7MB | Optimized React production build |
| Scripts | ~10KB | Startup, shutdown, and configuration scripts |
| Documentation | ~5KB | Deployment guide and version info |
| **Total** | **~61MB** | Complete deployment package |
| **Archive** | **~50MB** | Compressed tar.gz for upload |

## 🔄 Development Workflow

### For Major Changes
```bash
./scripts/deployment/build-production.sh
./scripts/deployment/quick-deploy.sh --upload-only
```

### For Frontend-Only Changes
```bash
./scripts/deployment/quick-deploy.sh --frontend-only
```

### For Backend-Only Changes
```bash
./scripts/deployment/quick-deploy.sh --backend-only
```

## 🎯 Best Practices

1. **Always test locally first** before deploying to production
2. **Use build-production.sh** for complete builds
3. **Use quick-deploy.sh** for rapid iterations
4. **Keep previous packages** for quick rollback
5. **Monitor logs** after deployment
6. **Verify health endpoints** after deployment

## 📝 Notes

- Tests are skipped by default in production builds for speed
- Source maps warnings from react-datepicker are cosmetic and don't affect functionality
- The build process automatically configures API endpoints based on port settings
- All scripts include comprehensive error handling and colored output
- Archives are timestamped to avoid conflicts
