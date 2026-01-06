#!/bin/bash
# Vyana Backend - Azure Ubuntu VPS Setup Script
# Run this on your Azure Ubuntu VPS

set -e

echo "🚀 Setting up Vyana Backend on Azure Ubuntu VPS..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "📦 Installing Docker Compose..."
sudo apt install -y docker-compose-plugin

# Create app directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/vyana
sudo chown $USER:$USER /opt/vyana
cd /opt/vyana

# Clone repository (or copy files)
echo "📥 Clone your repository here or copy files..."
echo "   git clone https://github.com/suryaprakash251201/vyana.git ."
echo "   cd services/vyana_backend"

echo ""
echo "✅ Base setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. cd /opt/vyana/services/vyana_backend"
echo "   2. Create .env file with your API keys"
echo "   3. Run: docker compose up -d"
echo "   4. Check: docker compose logs -f"
echo ""
echo "🔒 Don't forget to:"
echo "   - Open port 8080 in Azure Network Security Group"
echo "   - Set up SSL with Nginx reverse proxy (optional)"
