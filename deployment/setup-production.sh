#!/bin/bash

# Ultra Spec ERP - Production Server Setup Script
# This script sets up automatic deployment on your production server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (you'll need to update these)
GITHUB_REPO="https://github.com/yourusername/ultra-spec-erp.git"
WEBHOOK_SECRET="your-webhook-secret-here"
SITE_NAME="your-site.com"

echo -e "${BLUE}🚀 Ultra Spec ERP - Production Deployment Setup${NC}"
echo "=============================================="

# Check if running as frappe user
if [ "$(whoami)" != "frappe" ]; then
    echo -e "${RED}❌ This script must be run as the frappe user${NC}"
    echo "Please run: sudo su - frappe"
    exit 1
fi

echo -e "${GREEN}✅ Running as frappe user${NC}"

# Step 1: Create auto-deploy directory
echo -e "${BLUE}📁 Creating auto-deploy directory...${NC}"
mkdir -p /home/frappe/auto-deploy
mkdir -p /home/frappe/backups

# Step 2: Clone the repository
echo -e "${BLUE}📥 Cloning Ultra Spec ERP repository...${NC}"
cd /home/frappe/frappe-bench/apps

if [ -d "ultra_spec_erp" ]; then
    echo -e "${YELLOW}⚠️ ultra_spec_erp directory already exists, updating...${NC}"
    cd ultra_spec_erp
    git pull origin main
else
    git clone "$GITHUB_REPO" ultra_spec_erp
    cd ultra_spec_erp
fi

# Step 3: Install the app
echo -e "${BLUE}📱 Installing Ultra Spec ERP app...${NC}"
cd /home/frappe/frappe-bench
bench --site "$SITE_NAME" install-app ultra_spec_erp

# Step 4: Copy deployment scripts
echo -e "${BLUE}📋 Setting up deployment scripts...${NC}"
cp /home/frappe/frappe-bench/apps/ultra_spec_erp/deployment/deploy.sh /home/frappe/auto-deploy/
cp /home/frappe/frappe-bench/apps/ultra_spec_erp/deployment/webhook-listener.py /home/frappe/auto-deploy/

# Make scripts executable
chmod +x /home/frappe/auto-deploy/deploy.sh
chmod +x /home/frappe/auto-deploy/webhook-listener.py

# Step 5: Update configuration in deploy script
echo -e "${BLUE}⚙️ Configuring deployment script...${NC}"
sed -i "s|REPO_URL=\".*\"|REPO_URL=\"$GITHUB_REPO\"|" /home/frappe/auto-deploy/deploy.sh
sed -i "s|SITE_NAME=\".*\"|SITE_NAME=\"$SITE_NAME\"|" /home/frappe/auto-deploy/deploy.sh

# Step 6: Create systemd service for webhook listener
echo -e "${BLUE}🔧 Creating webhook listener service...${NC}"
sudo tee /etc/systemd/system/ultra-spec-webhook.service > /dev/null <<EOF
[Unit]
Description=Ultra Spec ERP Webhook Listener
After=network.target

[Service]
Type=simple
User=frappe
Group=frappe
WorkingDirectory=/home/frappe/auto-deploy
ExecStart=/usr/bin/python3 /home/frappe/auto-deploy/webhook-listener.py
Restart=always
RestartSec=10
Environment=WEBHOOK_SECRET=$WEBHOOK_SECRET
Environment=WEBHOOK_PORT=9000

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ultra-spec-webhook

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Enable and start the service
echo -e "${BLUE}🚀 Starting webhook listener service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable ultra-spec-webhook
sudo systemctl start ultra-spec-webhook

# Step 8: Configure Nginx for webhook endpoint
echo -e "${BLUE}🌐 Configuring Nginx for webhook...${NC}"
NGINX_CONFIG="/etc/nginx/sites-available/$SITE_NAME"

if [ -f "$NGINX_CONFIG" ]; then
    # Add webhook location to existing config
    sudo sed -i '/location \/ {/i\
    # GitHub webhook endpoint\
    location /webhook {\
        proxy_pass http://127.0.0.1:9000;\
        proxy_set_header Host $host;\
        proxy_set_header X-Real-IP $remote_addr;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
    }\
' "$NGINX_CONFIG"

    # Reload Nginx
    sudo nginx -t && sudo systemctl reload nginx
    echo -e "${GREEN}✅ Nginx configuration updated${NC}"
else
    echo -e "${YELLOW}⚠️ Nginx config not found at $NGINX_CONFIG${NC}"
    echo "You'll need to manually add the webhook endpoint to your Nginx config"
fi

# Step 9: Test the setup
echo -e "${BLUE}🧪 Testing deployment setup...${NC}"

# Test webhook listener
sleep 2
if curl -s http://localhost:9000/health > /dev/null; then
    echo -e "${GREEN}✅ Webhook listener is running${NC}"
else
    echo -e "${RED}❌ Webhook listener is not responding${NC}"
fi

# Test deployment script
if [ -x "/home/frappe/auto-deploy/deploy.sh" ]; then
    echo -e "${GREEN}✅ Deployment script is executable${NC}"
else
    echo -e "${RED}❌ Deployment script is not executable${NC}"
fi

# Step 10: Create backup script
echo -e "${BLUE}💾 Creating backup script...${NC}"
tee /home/frappe/auto-deploy/backup.sh > /dev/null <<'EOF'
#!/bin/bash
# Ultra Spec ERP - Backup Script

SITE_NAME="your-site.com"
BACKUP_DIR="/home/frappe/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

cd /home/frappe/frappe-bench

echo "Creating backup for $SITE_NAME..."
bench --site "$SITE_NAME" backup --with-files

# Move backups to backup directory
mv "sites/$SITE_NAME/private/backups/"*.sql.gz "$BACKUP_DIR/backup_$TIMESTAMP.sql.gz" 2>/dev/null || true
mv "sites/$SITE_NAME/private/backups/"*.tar "$BACKUP_DIR/backup_$TIMESTAMP.tar" 2>/dev/null || true

echo "Backup completed: backup_$TIMESTAMP"

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "backup_*.tar" -mtime +7 -delete
EOF

chmod +x /home/frappe/auto-deploy/backup.sh
sed -i "s|SITE_NAME=\".*\"|SITE_NAME=\"$SITE_NAME\"|" /home/frappe/auto-deploy/backup.sh

# Step 11: Setup daily backups
echo -e "${BLUE}⏰ Setting up daily backups...${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * * /home/frappe/auto-deploy/backup.sh") | crontab -

echo ""
echo -e "${GREEN}🎉 Ultra Spec ERP Production Setup Complete!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}📋 Setup Summary:${NC}"
echo "• Auto-deploy directory: /home/frappe/auto-deploy"
echo "• Webhook listener: http://your-server.com/webhook"
echo "• Service status: sudo systemctl status ultra-spec-webhook"
echo "• Logs: sudo journalctl -u ultra-spec-webhook -f"
echo "• Manual deploy: /home/frappe/auto-deploy/deploy.sh"
echo "• Backup script: /home/frappe/auto-deploy/backup.sh"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Update WEBHOOK_SECRET in /etc/systemd/system/ultra-spec-webhook.service"
echo "2. Add webhook URL to your GitHub repository settings"
echo "3. Test deployment by pushing to main branch"
echo ""
echo -e "${BLUE}📞 GitHub Webhook URL:${NC}"
echo "https://$SITE_NAME/webhook"
echo ""
echo -e "${GREEN}✅ Ready for automatic deployments!${NC}"

