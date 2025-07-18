#!/bin/bash

# Upload deployment package to production server
echo "🚀 Uploading deployment package to production server..."

PACKAGE_DIR="surveyor-tracking-production-20250609_120352"

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "❌ Package directory not found: $PACKAGE_DIR"
    echo "Run ./create-production-package.sh first"
    exit 1
fi

echo "📦 Uploading $PACKAGE_DIR to neogeo@183.82.114.29..."

# Upload the package
scp -r "$PACKAGE_DIR" neogeo@183.82.114.29:~/

if [ $? -eq 0 ]; then
    echo "✅ Upload completed successfully!"
    echo ""
    echo "🔗 Next steps:"
    echo "1. SSH to the server: ssh neogeo@183.82.114.29"
    echo "2. Navigate to the package: cd $PACKAGE_DIR"
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
