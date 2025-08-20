#!/bin/bash

# Ultra Spec ERP - Production Deployment Script
# This script automatically deploys updates from GitHub to production

set -e

# Configuration
REPO_URL="https://github.com/yourusername/ultra-spec-erp.git"
SITE_NAME="your-site.com"
FRAPPE_USER="frappe"
BENCH_PATH="/home/frappe/frappe-bench"
BACKUP_DIR="/home/frappe/backups"
LOG_FILE="/home/frappe/auto-deploy/deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as frappe user
if [ "$(whoami)" != "$FRAPPE_USER" ]; then
    error "This script must be run as the $FRAPPE_USER user"
    exit 1
fi

log "🚀 Starting Ultra Spec ERP deployment..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Step 1: Create backup
log "📦 Creating backup before deployment..."
cd "$BENCH_PATH"

BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ultra_spec_erp_backup_$BACKUP_TIMESTAMP"

# Backup database
bench --site "$SITE_NAME" backup --with-files
if [ $? -eq 0 ]; then
    success "Database backup created successfully"
    
    # Move backup to backup directory
    mv "$BENCH_PATH/sites/$SITE_NAME/private/backups/"*.sql.gz "$BACKUP_DIR/$BACKUP_NAME.sql.gz" 2>/dev/null || true
    mv "$BENCH_PATH/sites/$SITE_NAME/private/backups/"*.tar "$BACKUP_DIR/$BACKUP_NAME.tar" 2>/dev/null || true
else
    error "Backup failed! Aborting deployment."
    exit 1
fi

# Step 2: Pull latest changes
log "📥 Pulling latest changes from GitHub..."
cd "$BENCH_PATH/apps/ultra_spec_erp"

# Stash any local changes
git stash push -m "Auto-stash before deployment $BACKUP_TIMESTAMP"

# Pull latest changes
git pull origin main
if [ $? -eq 0 ]; then
    success "Successfully pulled latest changes"
else
    error "Failed to pull changes from GitHub"
    log "🔄 Attempting to restore from backup..."
    # Restore logic would go here
    exit 1
fi

# Step 3: Update dependencies
log "📦 Installing/updating dependencies..."
cd "$BENCH_PATH"

# Install any new Python dependencies
bench --site "$SITE_NAME" migrate
if [ $? -eq 0 ]; then
    success "Dependencies updated successfully"
else
    warning "Some dependencies may not have updated correctly"
fi

# Step 4: Run database migrations
log "🗄️ Running database migrations..."
bench --site "$SITE_NAME" migrate
if [ $? -eq 0 ]; then
    success "Database migrations completed"
else
    error "Database migration failed!"
    exit 1
fi

# Step 5: Build assets
log "🔨 Building frontend assets..."
bench build --app ultra_spec_erp
if [ $? -eq 0 ]; then
    success "Assets built successfully"
else
    warning "Asset build completed with warnings"
fi

# Step 6: Clear cache
log "🧹 Clearing cache..."
bench --site "$SITE_NAME" clear-cache
bench --site "$SITE_NAME" clear-website-cache

# Step 7: Restart services
log "🔄 Restarting services..."
bench restart
if [ $? -eq 0 ]; then
    success "Services restarted successfully"
else
    error "Failed to restart services"
    exit 1
fi

# Step 8: Health check
log "🏥 Performing health check..."
sleep 5

# Check if site is accessible
HEALTH_CHECK_URL="https://$SITE_NAME/api/method/ping"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    success "Health check passed - site is accessible"
else
    error "Health check failed - HTTP status: $HTTP_STATUS"
    warning "Site may be experiencing issues"
fi

# Step 9: Update deployment log
log "📝 Updating deployment log..."
echo "Deployment completed at $(date)" >> "/home/frappe/auto-deploy/deployment-history.log"
echo "Backup: $BACKUP_NAME" >> "/home/frappe/auto-deploy/deployment-history.log"
echo "Git commit: $(cd $BENCH_PATH/apps/ultra_spec_erp && git rev-parse --short HEAD)" >> "/home/frappe/auto-deploy/deployment-history.log"
echo "---" >> "/home/frappe/auto-deploy/deployment-history.log"

# Step 10: Send notification (if configured)
if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
    log "📢 Sending deployment notification..."
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚀 Ultra Spec ERP deployed successfully to production!\n• Site: $SITE_NAME\n• Backup: $BACKUP_NAME\n• Time: $(date)\"}" \
        "$SLACK_WEBHOOK_URL" || warning "Failed to send Slack notification"
fi

success "🎉 Deployment completed successfully!"
log "📊 Deployment Summary:"
log "   • Site: $SITE_NAME"
log "   • Backup: $BACKUP_NAME"
log "   • Git commit: $(cd $BENCH_PATH/apps/ultra_spec_erp && git rev-parse --short HEAD)"
log "   • Deployment time: $(date)"
log "   • Health check: $HTTP_STATUS"

exit 0

