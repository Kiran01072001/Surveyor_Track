#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Checking current Java version...${NC}"
java -version

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
    else
        OS="Unknown"
    fi
}

# Install Java 17 based on OS
install_java() {
    detect_os
    echo -e "${GREEN}Detected OS: $OS${NC}"
    
    case $OS in
        "Ubuntu" | "Debian")
            echo -e "${GREEN}Installing Java 17 on Ubuntu/Debian...${NC}"
            sudo apt update
            sudo apt install -y openjdk-17-jdk
            ;;
            
        "CentOS Linux" | "Red Hat Enterprise Linux" | "Fedora")
            echo -e "${GREEN}Installing Java 17 on RHEL/CentOS/Fedora...${NC}"
            sudo dnf install -y java-17-openjdk-devel
            ;;
            
        "Amazon Linux")
            echo -e "${GREEN}Installing Java 17 on Amazon Linux...${NC}"
            sudo amazon-linux-extras enable java-openjdk17
            sudo yum install -y java-17-openjdk-devel
            ;;
            
        *)
            echo -e "${RED}Unsupported OS: $OS${NC}"
            echo "Please install Java 17 manually for your operating system"
            exit 1
            ;;
    esac
}

# Check if Java 17 is already installed
if java -version 2>&1 | grep -q "version \"17"; then
    echo -e "${GREEN}Java 17 is already installed!${NC}"
else
    echo -e "${GREEN}Java 17 not found. Installing...${NC}"
    install_java
fi

# Verify installation
echo -e "\n${GREEN}Verifying Java installation...${NC}"
java -version

# Set JAVA_HOME
echo -e "\n${GREEN}Setting up JAVA_HOME...${NC}"
JAVA_PATH=$(readlink -f $(which java))
JAVA_HOME=${JAVA_PATH%/bin/java}
echo "JAVA_HOME=$JAVA_HOME"

# Add JAVA_HOME to profile if not already present
if ! grep -q "JAVA_HOME=" ~/.profile; then
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.profile
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.profile
    echo -e "${GREEN}Added JAVA_HOME to ~/.profile${NC}"
fi

echo -e "\n${GREEN}Java 17 setup complete!${NC}"
echo "Please run 'source ~/.profile' to apply changes in the current session"
