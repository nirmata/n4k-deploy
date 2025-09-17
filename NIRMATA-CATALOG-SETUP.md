# Nirmata Catalog Setup Guide

## 🎯 Repository Configuration for Nirmata GitOps

Your `n4k-deploy` repository is now properly configured as a Helm Chart Repository for Nirmata catalog integration.

## 📋 What We Have Set Up

### ✅ Helm Chart Repository Structure
```
n4k-deploy/
├── index.yaml                     # Helm repo index
├── kyverno-3.3.34.tgz            # Packaged Kyverno chart
├── nirmata-kyverno-operator-0.8.8.tgz  # Packaged Operator chart
├── kyverno-chart/kyverno/         # Source Kyverno chart
└── operator-chart/nirmata-kyverno-operator/  # Source Operator chart
```

### ✅ Branch Configuration
- **Main Branch**: `ghcr.io/vikashkaushik01` registry
- **Nova Branch**: `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker` registry

## 🔧 Nirmata Catalog Integration

### Add Chart Repository in Nirmata

**For Main Branch (Your Deployment):**
```yaml
Name: nirmata-n4k-charts-main
Location: https://raw.githubusercontent.com/nirmata/n4k-deploy/main/
Username: vikashkaushik01
Password: <YOUR_GITHUB_PAT>
```

**For Nova Branch (Customer Deployment):**
```yaml
Name: nirmata-n4k-charts-nova
Location: https://raw.githubusercontent.com/nirmata/n4k-deploy/nova/
Username: vikashkaushik01
Password: <YOUR_GITHUB_PAT>
```

### Available Charts

After adding the repository, you'll see these charts in Nirmata catalog:

1. **`nirmata-kyverno-operator`** (Version: 0.8.8)
   - Size: 27KB (fits well within limits)
   - Contains: Operator deployment, RBAC, webhooks

2. **`kyverno`** (Version: 3.3.34)
   - Size: 365KB (compressed, fits within limits)
   - Contains: Full N4K deployment with all controllers

## 🚀 Deployment in Nirmata

### Step 1: Deploy Operator First
```yaml
Chart: nirmata-kyverno-operator
Namespace: nirmata-system
Values: Use default values from respective branch
```

### Step 2: Deploy Kyverno
```yaml
Chart: kyverno
Namespace: kyverno
Values: Use default values from respective branch
```

## 📊 Why This Approach Works

### Chart Package Sizes (Under Limits)
- **Operator**: 27KB → No secret size issues
- **Kyverno**: 365KB → Compressed, fits in 1MB limit

### Compression Benefits
- Raw templates: ~3.4MB
- Packaged charts: ~365KB
- **90% size reduction** through Helm packaging!

## 🎯 Key Benefits

### For You (Main Branch)
- ✅ Uses your GHCR registry
- ✅ Private images with ghcr-secret
- ✅ All performance optimizations preserved

### For Customer (Nova Branch)
- ✅ Uses their artifactory registry
- ✅ Correct image paths (no ghcr.io mixup)
- ✅ Private images with artifactory-secret
- ✅ All performance optimizations preserved

## 🔧 Configuration Features Included

Both branches include:
- **Enhanced Performance**: 
  - Admission Controller: 3 replicas, 1Gi memory
  - Other Controllers: 2 replicas, 512Mi memory
- **Smooth Cleanup**: Webhook failurePolicy=Ignore
- **Always Pull**: imagePullPolicy=Always for EC2 compatibility
- **Private Registry Support**: Proper imagePullSecrets configuration

## 🚨 Important Notes

### Registry URLs
- **Main**: All images from `ghcr.io/vikashkaushik01/[component]`
- **Nova**: All images from `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/[component]`

### Secret Requirements
- **Main**: Create `ghcr-secret` in both namespaces
- **Nova**: Create `artifactory-secret` in both namespaces

### Deployment Order
1. **Always deploy operator first** (small chart, no issues)
2. **Then deploy kyverno** (larger chart, but compressed fits limits)

## 📋 Troubleshooting

### If Chart Repository Fails to Load
- Verify URL: `https://raw.githubusercontent.com/nirmata/n4k-deploy/[branch]/`
- Check authentication credentials
- Ensure index.yaml is accessible

### If Deployment Fails
- Check imagePullSecrets are created
- Verify registry credentials
- Confirm namespace exists

### Size Limit Issues
- Use packaged charts (not raw chart directories)
- Deploy operator and kyverno as separate releases
- Consider our raw YAML approach if needed

## 🎉 Success Indicators

When working correctly:
- Repository shows in Nirmata catalog
- Both charts visible and installable
- Deployments complete without secret size errors
- All pods running with correct images from respective registries

## 🏢 Customer Bitbucket Setup

**For customers who can only access Bitbucket:**
- See `BITBUCKET-CUSTOMER-SETUP.md` for complete Bitbucket integration guide
- Use `setup-bitbucket-repo.sh` script to automate repository mirroring
- Customer will use their own Bitbucket repository as Helm chart repository
- URL format: `https://bitbucket.org/CUSTOMER_ORG/REPO_NAME/raw/nova/`

## 📞 Support

If issues persist:
- **GitHub Setup**: Check repository accessibility and verify Helm chart package integrity
- **Bitbucket Setup**: See BITBUCKET-CUSTOMER-SETUP.md for customer-specific instructions  
- **Configuration**: Confirm branch-specific configurations are correct
- **Alternatives**: Use the raw YAML approach documented in GITOPS-SOLUTION.md
