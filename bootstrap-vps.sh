#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling
set -e
trap 'echo -e "${RED}Script failed at line $LINENO${NC}"; exit 1' ERR

print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're running as root
if [ "$EUID" -eq 0 ]; then 
    print_warning "Running as root, consider running as user instead"
fi

print_status "Starting VPS bootstrap process..."

# Step 1: Check Ubuntu version
print_status "Checking Ubuntu version..."
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)
print_status "Detected Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME)"

# Validate supported versions
if [[ "$UBUNTU_VERSION" != "18.04" && "$UBUNTU_VERSION" != "20.04" && "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    print_warning "Untested Ubuntu version. Script optimized for 18.04/20.04/22.04/24.04"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 2: Update system
print_status "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Step 3: Install prerequisites
print_status "Installing prerequisites..."
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release \
    git \
    htop \
    net-tools

# Step 4: Install Docker
print_status "Installing Docker..."

# Remove old versions if any
apt-get remove -y -qq docker docker-engine docker.io containerd runc 2>/dev/null || true

if [[ "$UBUNTU_VERSION" == "18.04" ]]; then

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    # Set up stable repository
    add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu bionic stable"

    # Install Docker Engine (no buildx or compose plugin)
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io
else

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up stable repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update -qq
    apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
fi

# Step 5: Install Docker Compose (standalone version - optional)
print_status "Installing Docker Compose (standalone)..."
if [[ "$UBUNTU_VERSION" == "18.04" ]]; then
    # Use a compatible version for 18.04
    DOCKER_COMPOSE_VERSION="1.29.2"
else
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
fi
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Step 6: Configure Docker
print_status "Configuring Docker..."

if ! getent group docker > /dev/null; then
    groupadd docker
fi
if [ "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
else
    usermod -aG docker "$USER"
fi
systemctl enable docker.service
systemctl enable containerd.service

# Configure Docker daemon (optional optimizations)
mkdir -p /etc/docker
cat <<EOF | tee /etc/docker/daemon.json > /dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Step 7: Verify installations
print_status "Verifying installations..."

# Check Docker
docker --version
docker run --rm hello-world

# Check Docker Compose
docker-compose --version
docker compose version

print_status "Installation complete!"

# Step 8: Post-installation recommendations
echo -e "\n${GREEN}=== Post-installation Steps ===${NC}"
print_status "1. Log out and back in for group changes to take effect"
print_status "2. Test Docker without sudo: docker run hello-world"
print_status "3. Consider security hardening:"
echo "   - Set up firewall (ufw)"
echo "   - Configure SSH key authentication only"
echo "   - Set up fail2ban"
echo "   - Regular security updates"

# Show Docker info
echo -e "\n${GREEN}=== Docker Info ===${NC}"
docker info --format 'Server Version: {{.ServerVersion}}'
docker system info --format 'Containers: {{.Containers}}'