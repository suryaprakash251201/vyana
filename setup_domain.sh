#!/bin/bash

# Deploy Script for Vyana VPS
# Usage: ./setup_domain.sh

DOMAIN="vyana.suryaprakashinfo.in"
EMAIL="admin@suryaprakashinfo.in" # Replace with your email

echo "Starting setup for $DOMAIN..."

# 1. Install Nginx and Certbot
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# 2. Configure Nginx
cat <<EOF | sudo tee /etc/nginx/sites-available/vyana
server {
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# 3. Enable Site
sudo ln -s /etc/nginx/sites-available/vyana /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# 4. Obtain SSL Certificate
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "Setup complete! https://$DOMAIN/ should now be pointing to localhost:8000"
