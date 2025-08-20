#!/bin/bash

# Ultra Spec ERP - Codespaces Setup Script
# This script sets up the ERPNext development environment in GitHub Codespaces

set -e

echo "🚀 Setting up Ultra Spec ERP development environment..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update -qq
sudo apt-get install -y curl wget git build-essential

# Install Frappe Bench if not already installed
if ! command -v bench &> /dev/null; then
    echo "🔧 Installing Frappe Bench..."
    
    # Install bench dependencies
    sudo apt-get install -y python3-dev python3-pip python3-venv
    sudo apt-get install -y software-properties-common
    
    # Install Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Install yarn
    sudo npm install -g yarn
    
    # Install wkhtmltopdf
    sudo apt-get install -y wkhtmltopdf
    
    # Install Redis
    sudo apt-get install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
    
    # Install MariaDB
    sudo apt-get install -y mariadb-server mariadb-client
    sudo systemctl enable mariadb
    sudo systemctl start mariadb
    
    # Configure MariaDB for ERPNext
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';"
    sudo mysql -u root -proot -e "SET GLOBAL character_set_server = 'utf8mb4';"
    sudo mysql -u root -proot -e "SET GLOBAL collation_server = 'utf8mb4_unicode_ci';"
    
    # Install bench
    pip3 install frappe-bench
    
    # Add bench to PATH
    echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
    export PATH=$PATH:~/.local/bin
fi

# Create bench directory if it doesn't exist
if [ ! -d "/workspace/frappe-bench" ]; then
    echo "🏗️ Initializing Frappe Bench..."
    cd /workspace
    bench init frappe-bench --frappe-branch version-15
    cd frappe-bench
    
    # Create new site
    echo "🌐 Creating ERPNext site..."
    bench new-site ultra-spec-erp.localhost --admin-password admin --mariadb-root-password root
    
    # Install ERPNext
    echo "📱 Installing ERPNext..."
    bench get-app erpnext --branch version-15
    bench --site ultra-spec-erp.localhost install-app erpnext
    
    # Set site as default
    bench use ultra-spec-erp.localhost
else
    cd /workspace/frappe-bench
fi

# Install Ultra Spec ERP app if it exists
if [ -d "/workspace/ultra_spec_erp" ]; then
    echo "🌿 Installing Ultra Spec ERP app..."
    
    # Link the app to bench
    ln -sf /workspace/ultra_spec_erp /workspace/frappe-bench/apps/ultra_spec_erp
    
    # Install the app
    bench --site ultra-spec-erp.localhost install-app ultra_spec_erp
fi

# Set developer mode
echo "🔧 Configuring development settings..."
bench --site ultra-spec-erp.localhost set-config developer_mode 1
bench --site ultra-spec-erp.localhost set-config server_script_enabled 1

# Create development user
bench --site ultra-spec-erp.localhost add-user developer@ultraspec.com --first-name Developer --last-name User --password developer --user-type "System User"

# Set permissions
sudo chown -R $(whoami):$(whoami) /workspace/frappe-bench

echo "✅ Setup complete!"
echo ""
echo "🎉 Ultra Spec ERP development environment is ready!"
echo ""
echo "📋 Quick Start:"
echo "  1. cd /workspace/frappe-bench"
echo "  2. bench start"
echo "  3. Open http://localhost:8000"
echo "  4. Login with: Administrator / admin"
echo ""
echo "🔧 Development Commands:"
echo "  • bench start          - Start development server"
echo "  • bench migrate        - Run database migrations"
echo "  • bench build          - Build assets"
echo "  • bench restart        - Restart services"
echo ""
echo "🌿 Ultra Spec ERP is ready for hemp flower management development!"

