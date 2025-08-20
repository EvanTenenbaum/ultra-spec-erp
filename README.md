# Ultra Spec ERP - Hemp Flower Wholesale Management System

## 🌿 Overview

Ultra Spec ERP is a specialized ERP system built on ERPNext for hemp flower wholesale brokerage operations. This system provides comprehensive management for inventory, sales, purchasing, compliance, and customer relationships in the hemp flower industry.

## 🚀 Quick Start with GitHub Codespaces

### Option 1: One-Click Development Environment
1. Click the "Code" button above
2. Select "Codespaces" tab
3. Click "Create codespace on main"
4. Wait 2-3 minutes for ERPNext environment to be ready
5. Start developing immediately!

### Option 2: Local Development
```bash
git clone https://github.com/yourusername/ultra-spec-erp.git
cd ultra-spec-erp
./setup-local-development.sh
```

## 📋 Features

### Core Hemp Flower Management
- **Strain Tracking**: Comprehensive strain profiles with THC/CBD content
- **Inventory Management**: Real-time stock levels, batch tracking, expiration dates
- **Compliance Tracking**: COA management, regulatory compliance reporting
- **Quality Control**: Testing results, quality grades, inspection records

### Business Operations
- **Customer Portal**: Self-service ordering, order history, account management
- **Vendor Management**: Supplier profiles, purchase orders, payment tracking
- **Sales Management**: Quotes, orders, invoicing, payment processing
- **Reporting**: Business intelligence, compliance reports, financial analytics

### Mobile-First Design
- **Touch-Optimized Interface**: Designed for tablets and smartphones
- **Barcode Scanning**: Quick product identification and inventory updates
- **Offline Capability**: Continue working without internet connection
- **Real-time Sync**: Automatic data synchronization when connected

## 🛠 Development Workflow

### Feature Development Cycle
```
1. 💡 Plan Feature → 2. 🔧 Develop → 3. 🧪 Test → 4. 🚀 Deploy
   (Planning)          (Codespace)    (Local)     (Auto-Deploy)
```

### Deployment Process
1. **Develop** in GitHub Codespaces
2. **Test** features locally
3. **Push** to main branch
4. **Auto-deploy** to production (via webhook)
5. **Verify** deployment success

## 📁 Project Structure

```
ultra-spec-erp/
├── ultra_spec_erp/           # Main ERPNext app
│   ├── ultra_spec_erp/       # App modules
│   ├── hooks.py              # ERPNext hooks
│   └── setup.py              # App configuration
├── deployment/               # Deployment automation
│   ├── deploy.sh            # Production deployment
│   ├── backup.sh            # Backup scripts
│   └── webhook-listener.py  # GitHub webhook handler
├── .devcontainer/           # Codespaces configuration
├── .github/workflows/       # GitHub Actions
├── docs/                    # Documentation
└── README.md               # This file
```

## 🔧 Configuration

### Environment Variables
```bash
# Production deployment
PRODUCTION_SERVER=your-server-ip
FRAPPE_USER=frappe
SITE_NAME=your-site.com

# GitHub webhook
WEBHOOK_SECRET=your-webhook-secret
DEPLOY_KEY_PATH=/path/to/deploy/key
```

### ERPNext Configuration
- **Version**: ERPNext v15
- **Database**: MariaDB
- **Web Server**: Nginx
- **SSL**: Let's Encrypt

## 📚 Documentation

- [Development Setup](docs/development-setup.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Feature Documentation](docs/features.md)
- [API Reference](docs/api-reference.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Develop in Codespaces
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For support and questions:
- Create an issue in this repository
- Email: support@ultraspecerp.com
- Documentation: [docs.ultraspecerp.com](https://docs.ultraspecerp.com)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Ready to start developing?** Click the Codespaces button above and you'll have a full ERPNext development environment in 2 minutes! 🚀

