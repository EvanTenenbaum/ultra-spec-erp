# Ultra Spec ERP - GitHub Codespaces Setup Instructions

## 🚀 Complete Setup Guide for Automatic Deployment

This comprehensive guide will walk you through setting up GitHub Codespaces for your Ultra Spec ERP system with automatic deployment to your production server. By following these instructions, you'll have a complete development and deployment pipeline that allows you to make changes in a cloud-based development environment and automatically deploy them to your live server.

## 📋 Prerequisites

Before beginning this setup, ensure you have:

- **GitHub Account**: A GitHub account with repository creation permissions
- **Production Server**: Your Hostinger VPS with ERPNext v15 already installed and running
- **SSH Access**: SSH access to your production server with frappe user privileges
- **Domain Name**: Your production domain configured and pointing to your server
- **Basic Command Line Knowledge**: Familiarity with basic terminal/command line operations

## 🎯 What You'll Achieve

After completing this setup, you'll have:

- **Cloud Development Environment**: GitHub Codespaces with ERPNext pre-configured
- **Automatic Deployment**: Push code changes and they automatically deploy to production
- **Backup System**: Automatic backups before each deployment
- **Health Monitoring**: Deployment success/failure notifications
- **Rollback Capability**: Ability to quickly revert changes if needed

---

## Phase 1: GitHub Repository Setup

### Step 1: Create Your GitHub Repository

1. **Log in to GitHub** and navigate to your dashboard
2. **Click "New repository"** (green button or plus icon)
3. **Configure repository settings**:
   - Repository name: `ultra-spec-erp`
   - Description: `Hemp Flower Wholesale ERP System`
   - Visibility: `Private` (recommended for business applications)
   - Initialize with README: ✅ **Check this box**
   - Add .gitignore: Select `Python`
   - Choose a license: `MIT License` (or your preferred license)

4. **Click "Create repository"**

### Step 2: Upload Configuration Files

Now you need to upload all the configuration files I've created for you. You'll upload these files in the following order:

#### 2.1: Upload Repository Structure Files

**Upload these files to the root directory of your repository:**

1. **README.md** - Replace the default README with the comprehensive one I created
2. **.gitignore** - Add ERPNext-specific ignores (create this file with the content below)

Create `.gitignore` with this content:
```
# ERPNext specific
*.pyc
__pycache__/
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Frappe specific
sites/*/private/backups/*
sites/*/private/files/*
sites/*/public/files/*
sites/*/logs/*
sites/*/site_config.json
sites/*/locks/*

# Node modules
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```

#### 2.2: Upload Codespaces Configuration

**Create the `.devcontainer` folder and upload:**

1. **`.devcontainer/devcontainer.json`** - Main Codespaces configuration
2. **`.devcontainer/setup.sh`** - Codespaces setup script

#### 2.3: Upload GitHub Actions Workflow

**Create the `.github/workflows` folder and upload:**

1. **`.github/workflows/deploy.yml`** - Automatic deployment workflow

#### 2.4: Upload ERPNext App Files

**Create the `ultra_spec_erp` folder structure and upload:**

1. **`ultra_spec_erp/hooks.py`** - ERPNext app hooks
2. **`ultra_spec_erp/setup.py`** - App setup configuration
3. **`ultra_spec_erp/__init__.py`** - App initialization
4. **`ultra_spec_erp/requirements.txt`** - Python dependencies
5. **`ultra_spec_erp/ultra_spec_erp/__init__.py`** - Module initialization

#### 2.5: Upload Deployment Scripts

**Create the `deployment` folder and upload:**

1. **`deployment/deploy.sh`** - Production deployment script
2. **`deployment/webhook-listener.py`** - GitHub webhook listener
3. **`deployment/setup-production.sh`** - Production server setup script

### Step 3: Configure Repository Settings

1. **Go to repository Settings** (tab at the top of your repository)
2. **Navigate to "Secrets and variables" → "Actions"**
3. **Add the following repository secrets** (click "New repository secret" for each):

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `PRODUCTION_HOST` | Your server's IP address | `123.456.789.012` |
| `PRODUCTION_USER` | SSH username (usually 'frappe') | `frappe` |
| `PRODUCTION_SSH_KEY` | Private SSH key for deployment | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `PRODUCTION_PORT` | SSH port (usually 22) | `22` |
| `SLACK_WEBHOOK_URL` | (Optional) Slack notifications | `https://hooks.slack.com/...` |

**To generate SSH key for deployment:**
```bash
# On your local machine or in a terminal
ssh-keygen -t rsa -b 4096 -C "github-deploy@ultraspec.com"
# Save as: github_deploy_key (don't use a passphrase)
# Copy the private key content to PRODUCTION_SSH_KEY secret
# Copy the public key to your server's authorized_keys
```

---

## Phase 2: Production Server Configuration

### Step 1: Connect to Your Production Server

```bash
# SSH into your production server
ssh frappe@your-server-ip

# Or if you have a different SSH setup:
ssh -p 22 frappe@your-domain.com
```

### Step 2: Download and Run Setup Script

```bash
# Switch to frappe user if not already
sudo su - frappe

# Create temporary directory
mkdir -p /tmp/ultra-spec-setup
cd /tmp/ultra-spec-setup

# Download the setup script (you'll need to upload this first)
# For now, create it manually:
nano setup-production.sh
```

**Copy the content from `deployment/setup-production.sh` that I created, then:**

```bash
# Make executable and run
chmod +x setup-production.sh

# Update the configuration in the script:
nano setup-production.sh
# Change these lines:
# GITHUB_REPO="https://github.com/YOURUSERNAME/ultra-spec-erp.git"
# WEBHOOK_SECRET="your-webhook-secret-here"  # Generate a secure secret
# SITE_NAME="your-actual-domain.com"

# Run the setup
./setup-production.sh
```

### Step 3: Configure GitHub Webhook

1. **Generate a webhook secret:**
```bash
# Generate a secure random string
openssl rand -hex 32
# Copy this value - you'll need it for GitHub
```

2. **Update the webhook service configuration:**
```bash
sudo nano /etc/systemd/system/ultra-spec-webhook.service
# Update the WEBHOOK_SECRET line with your generated secret
```

3. **Restart the webhook service:**
```bash
sudo systemctl daemon-reload
sudo systemctl restart ultra-spec-webhook
sudo systemctl status ultra-spec-webhook
```

### Step 4: Configure GitHub Webhook

1. **Go to your GitHub repository**
2. **Click "Settings" → "Webhooks"**
3. **Click "Add webhook"**
4. **Configure webhook:**
   - Payload URL: `https://your-domain.com/webhook`
   - Content type: `application/json`
   - Secret: Enter the webhook secret you generated
   - Events: Select "Just the push event"
   - Active: ✅ Checked

5. **Click "Add webhook"**

---

## Phase 3: GitHub Codespaces Setup

### Step 1: Launch Your First Codespace

1. **Go to your GitHub repository**
2. **Click the green "Code" button**
3. **Select the "Codespaces" tab**
4. **Click "Create codespace on main"**

**Wait 3-5 minutes** for the environment to set up. You'll see:
- Container building
- ERPNext installation
- Dependencies installation
- Development environment configuration

### Step 2: Verify Codespace Setup

Once your Codespace is ready:

1. **Open a terminal** in Codespaces (Terminal → New Terminal)
2. **Navigate to the bench directory:**
```bash
cd /workspace/frappe-bench
```

3. **Start ERPNext:**
```bash
bench start
```

4. **Open the forwarded port** (Codespaces will show a notification)
   - Click on the port 8000 notification
   - Or go to the "Ports" tab and click the globe icon next to port 8000

5. **Log in to ERPNext:**
   - Username: `Administrator`
   - Password: `admin`

### Step 3: Install Ultra Spec ERP App

In your Codespace terminal:

```bash
# Navigate to bench directory
cd /workspace/frappe-bench

# Install the Ultra Spec ERP app
bench --site ultra-spec-erp.localhost install-app ultra_spec_erp

# Restart to apply changes
bench restart
```

---

## Phase 4: Development Workflow

### Step 1: Making Your First Change

Let's test the deployment pipeline with a simple change:

1. **In your Codespace, create a test file:**
```bash
# Create a simple test file
echo "# Ultra Spec ERP - Test Change $(date)" > test-deployment.md
```

2. **Commit and push the change:**
```bash
git add test-deployment.md
git commit -m "Test: First deployment pipeline test"
git push origin main
```

3. **Monitor the deployment:**
   - Go to your GitHub repository
   - Click on "Actions" tab
   - Watch the deployment workflow run
   - Check your production server logs:
   ```bash
   # On your production server
   sudo journalctl -u ultra-spec-webhook -f
   ```

### Step 2: Development Best Practices

**Daily Development Workflow:**

1. **Start your Codespace** (if not already running)
2. **Pull latest changes:**
```bash
cd /workspace/frappe-bench
git pull origin main
```

3. **Start development server:**
```bash
bench start
```

4. **Make your changes** using the VS Code interface
5. **Test changes** in the development environment
6. **Commit and push:**
```bash
git add .
git commit -m "Feature: Description of your changes"
git push origin main
```

7. **Verify deployment** on production server

**Feature Development Examples:**

**Adding a new DocType (Hemp Strain):**
```bash
# In Codespaces terminal
cd /workspace/frappe-bench
bench --site ultra-spec-erp.localhost make-app ultra_spec_erp
bench --site ultra-spec-erp.localhost new-doctype "Hemp Strain"
```

**Customizing existing forms:**
```bash
# Navigate to your app directory
cd /workspace/frappe-bench/apps/ultra_spec_erp
# Edit files using VS Code interface
# Test changes with: bench restart
```

---

## Phase 5: Troubleshooting & Maintenance

### Common Issues and Solutions

**Issue 1: Codespace won't start**
```bash
# Check the setup log
cat /workspace/.devcontainer/setup.log

# Manually run setup if needed
bash /workspace/.devcontainer/setup.sh
```

**Issue 2: Deployment fails**
```bash
# Check deployment logs on production server
sudo journalctl -u ultra-spec-webhook -f

# Check deployment script logs
tail -f /home/frappe/auto-deploy/deploy.log

# Manual deployment
/home/frappe/auto-deploy/deploy.sh
```

**Issue 3: Webhook not receiving events**
```bash
# Check webhook service status
sudo systemctl status ultra-spec-webhook

# Check nginx configuration
sudo nginx -t

# Test webhook endpoint
curl -X POST https://your-domain.com/webhook
```

### Backup and Recovery

**Manual Backup:**
```bash
# On production server
/home/frappe/auto-deploy/backup.sh
```

**Restore from Backup:**
```bash
# Navigate to bench directory
cd /home/frappe/frappe-bench

# List available backups
ls -la /home/frappe/backups/

# Restore database
bench --site your-site.com restore /home/frappe/backups/backup_TIMESTAMP.sql.gz

# Restore files
tar -xf /home/frappe/backups/backup_TIMESTAMP.tar -C sites/your-site.com/
```

### Monitoring and Logs

**Key Log Locations:**
- Webhook logs: `sudo journalctl -u ultra-spec-webhook -f`
- Deployment logs: `/home/frappe/auto-deploy/deploy.log`
- ERPNext logs: `/home/frappe/frappe-bench/logs/`
- Nginx logs: `/var/log/nginx/`

**Health Checks:**
```bash
# Check webhook listener
curl http://localhost:9000/health

# Check ERPNext status
cd /home/frappe/frappe-bench && bench --site your-site.com doctor

# Check system resources
htop
df -h
```

---

## Phase 6: Advanced Configuration

### Customizing the Development Environment

**Adding VS Code Extensions:**
Edit `.devcontainer/devcontainer.json` and add extensions to the `extensions` array:
```json
"extensions": [
    "ms-python.python",
    "ms-python.black-formatter",
    "your-additional-extension"
]
```

**Environment Variables:**
Add custom environment variables in `.devcontainer/devcontainer.json`:
```json
"containerEnv": {
    "FRAPPE_SITE_NAME": "ultra-spec-erp.localhost",
    "DEVELOPER_MODE": "1",
    "YOUR_CUSTOM_VAR": "value"
}
```

### Production Optimizations

**Performance Tuning:**
```bash
# Optimize ERPNext for production
bench --site your-site.com set-config max_file_size 10485760
bench --site your-site.com set-config backup_limit 5
```

**Security Enhancements:**
```bash
# Enable additional security features
bench --site your-site.com set-config deny_multiple_sessions 1
bench --site your-site.com set-config session_expiry_key "24:00:00"
```

---

## 🎉 Congratulations!

You now have a complete GitHub Codespaces development environment with automatic deployment for your Ultra Spec ERP system. Here's what you've accomplished:

✅ **Cloud Development Environment**: ERPNext ready in 2 minutes
✅ **Automatic Deployment**: Push code → Live in production
✅ **Backup System**: Safe deployments with rollback capability
✅ **Professional Workflow**: Industry-standard development practices
✅ **Scalable Architecture**: Ready for team collaboration

### Next Steps

1. **Start developing features** for your hemp flower business
2. **Invite team members** to collaborate in Codespaces
3. **Set up monitoring** and alerting for production
4. **Plan your feature roadmap** using GitHub Issues
5. **Consider staging environment** for larger changes

### Support and Resources

- **Documentation**: Keep this guide handy for reference
- **GitHub Issues**: Use your repository's Issues tab for bug tracking
- **ERPNext Documentation**: [ERPNext Developer Guide](https://frappeframework.com/docs)
- **Frappe Framework**: [Frappe Documentation](https://frappeframework.com/docs)

**Happy coding! Your Ultra Spec ERP development environment is ready for rapid iteration and professional deployment.** 🚀

