#!/bin/bash

# Docker Setup Script for Ubuntu
# Run this script with sudo: sudo ./setup_docker.sh

set -e

echo "🐳 Starting Docker Installation..."

# 1. Update apt and install prerequisites
echo "📦 Updating packages and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# 2. Add Docker's official GPG key
echo "🔑 Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Set up the repository
echo "📂 Setting up Docker repository..."
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Install Docker Engine
echo "⬇️ Installing Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Add current user to docker group (so you don't need sudo for docker commands)
echo "👤 Adding current user ($USER) to 'docker' group..."
sudo usermod -aG docker $USER

# 6. Enable and start Docker service
echo "🚀 Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# 7. Verification
echo "✅ Docker installed successfully!"
echo "⚠️  NOTE: You may need to log out and log back in for the group changes to take effect."
echo "   Or run: 'newgrp docker' to apply changes immediately."

echo "🔍 Verifying installation..."
docker compose version
docker --version

echo "🎉 Done! You are ready to deploy Vyana."
