# Ultra Spec ERP - Quick Reference Guide

## 🚀 Daily Development Commands

### Starting Development in Codespaces

```bash
# 1. Open your Codespace (GitHub → Code → Codespaces → Open)
# 2. Navigate to bench directory
cd /workspace/frappe-bench

# 3. Start ERPNext development server
bench start

# 4. Access ERPNext at forwarded port 8000
# Login: Administrator / admin
```

### Common Development Tasks

**Create New DocType:**
```bash
bench --site ultra-spec-erp.localhost new-doctype "Your DocType Name"
```

**Install/Update App:**
```bash
bench --site ultra-spec-erp.localhost install-app ultra_spec_erp
bench --site ultra-spec-erp.localhost migrate
```

**Build Assets:**
```bash
bench build --app ultra_spec_erp
```

**Clear Cache:**
```bash
bench --site ultra-spec-erp.localhost clear-cache
bench --site ultra-spec-erp.localhost clear-website-cache
```

### Git Workflow

**Daily Development:**
```bash
# Pull latest changes
git pull origin main

# Make your changes...

# Stage and commit
git add .
git commit -m "Feature: Your change description"

# Push to trigger deployment
git push origin main
```

**Feature Branches (Recommended):**
```bash
# Create feature branch
git checkout -b feature/hemp-strain-tracking

# Make changes and commit
git add .
git commit -m "Add hemp strain tracking functionality"

# Push feature branch
git push origin feature/hemp-strain-tracking

# Create Pull Request on GitHub
# Merge to main triggers deployment
```

## 🔧 Production Server Commands

### Deployment Management

**Manual Deployment:**
```bash
ssh frappe@your-server.com
/home/frappe/auto-deploy/deploy.sh
```

**Check Deployment Status:**
```bash
# Webhook service status
sudo systemctl status ultra-spec-webhook

# View deployment logs
tail -f /home/frappe/auto-deploy/deploy.log

# View webhook logs
sudo journalctl -u ultra-spec-webhook -f
```

**Manual Backup:**
```bash
/home/frappe/auto-deploy/backup.sh
```

### Troubleshooting

**Restart Services:**
```bash
# Restart webhook listener
sudo systemctl restart ultra-spec-webhook

# Restart ERPNext
cd /home/frappe/frappe-bench
bench restart
```

**Check System Health:**
```bash
# ERPNext health check
bench --site your-site.com doctor

# System resources
htop
df -h

# Check logs
tail -f /home/frappe/frappe-bench/logs/web.error.log
```

## 📁 File Structure Reference

```
ultra-spec-erp/
├── .devcontainer/           # Codespaces configuration
│   ├── devcontainer.json   # Main config
│   └── setup.sh           # Setup script
├── .github/workflows/      # GitHub Actions
│   └── deploy.yml         # Auto-deployment
├── ultra_spec_erp/        # ERPNext app
│   ├── hooks.py          # App hooks
│   ├── setup.py          # App setup
│   └── ultra_spec_erp/   # App modules
├── deployment/            # Deployment scripts
│   ├── deploy.sh         # Production deploy
│   ├── webhook-listener.py # Webhook handler
│   └── setup-production.sh # Server setup
└── docs/                 # Documentation
    ├── SETUP-INSTRUCTIONS.md
    └── QUICK-REFERENCE.md
```

## 🌿 Hemp Flower ERP Features

### Core Modules to Develop

**Strain Management:**
- Strain profiles (THC/CBD content)
- Harvest tracking
- Quality grades
- COA management

**Inventory Management:**
- Real-time stock levels
- Batch tracking
- Expiration dates
- Location tracking

**Sales & CRM:**
- Customer portal
- Quote generation
- Order processing
- Payment tracking

**Compliance:**
- Regulatory reporting
- License tracking
- Lab test results
- Audit trails

### Development Priorities

1. **Phase 1**: Basic strain and inventory tracking
2. **Phase 2**: Customer portal and ordering
3. **Phase 3**: Advanced reporting and analytics
4. **Phase 4**: Mobile optimization and offline sync

## 🔗 Useful Links

- **Your Codespace**: [GitHub Repository → Code → Codespaces]
- **Production Site**: https://your-domain.com
- **ERPNext Docs**: https://frappeframework.com/docs
- **Frappe Framework**: https://frappeframework.com/docs/v15/user
- **GitHub Actions**: [Your Repository → Actions tab]

## 📞 Emergency Procedures

**If Deployment Fails:**
1. Check GitHub Actions logs
2. SSH to production server
3. Check webhook logs: `sudo journalctl -u ultra-spec-webhook -f`
4. Run manual deployment: `/home/frappe/auto-deploy/deploy.sh`
5. If needed, restore backup

**If Production Site is Down:**
1. Check server status: `systemctl status nginx`
2. Check ERPNext: `bench --site your-site.com doctor`
3. Restart services: `bench restart`
4. Check logs: `tail -f /home/frappe/frappe-bench/logs/*.log`

**Rollback Procedure:**
```bash
# List available backups
ls -la /home/frappe/backups/

# Restore from backup
cd /home/frappe/frappe-bench
bench --site your-site.com restore /home/frappe/backups/backup_TIMESTAMP.sql.gz
```

## 💡 Pro Tips

- **Use feature branches** for larger changes
- **Test in Codespaces** before pushing to main
- **Monitor deployment logs** after each push
- **Keep backups** before major changes
- **Use descriptive commit messages**
- **Document new features** as you build them

---

**Happy developing! 🚀 Your Ultra Spec ERP is ready for rapid iteration.**

