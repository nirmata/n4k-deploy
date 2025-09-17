# Customer Setup: Bitbucket Helm Chart Repository

## 🎯 Overview for Customer

This guide helps the customer set up their own Bitbucket-based Helm chart repository for N4K deployment using Nirmata catalog.

## 📋 Customer Prerequisites

- Bitbucket repository with appropriate permissions
- Nirmata GitOps platform access
- Kubernetes cluster with proper RBAC

## 🔄 Step 1: Mirror Repository to Bitbucket

### Customer Actions:
```bash
# Clone the nova branch from GitHub
git clone -b nova https://github.com/nirmata/n4k-deploy.git
cd n4k-deploy

# Add customer's Bitbucket remote
git remote add bitbucket https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO.git

# Push nova branch to customer's Bitbucket
git push bitbucket nova

# Verify all files are pushed
git ls-remote bitbucket nova
```

### Required Files in Bitbucket Repository:
```
CUSTOMER_REPO/
├── index.yaml                                    # Helm repo index
├── kyverno-3.3.34.tgz                          # Packaged Kyverno chart  
├── nirmata-kyverno-operator-0.8.8.tgz          # Packaged Operator chart
├── kyverno-chart/kyverno/values.yaml           # Source chart with Artifactory config
├── operator-chart/nirmata-kyverno-operator/values.yaml  # Source chart with Artifactory config
└── BITBUCKET-CUSTOMER-SETUP.md                 # This guide
```

## 🔧 Step 2: Configure Nirmata Catalog

### Bitbucket Helm Chart Repository Configuration:
```yaml
Name: customer-n4k-charts
Location: https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/
Username: BITBUCKET_USERNAME
Password: BITBUCKET_APP_PASSWORD
```

### Important Notes:
- Replace `CUSTOMER_ORG` with your Bitbucket organization/workspace
- Replace `CUSTOMER_REPO` with your repository name
- Use Bitbucket **App Password** (not regular password)
- Ensure repository has **public read access** or proper credentials

## 🏗️ Step 3: Create Kubernetes Prerequisites

### Create Namespaces:
```bash
kubectl create namespace nirmata-system
kubectl create namespace kyverno
```

### Create Artifactory Secret:
```bash
# Create secret for Artifactory registry
kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net \
  --docker-username=YOUR_ARTIFACTORY_USERNAME \
  --docker-password=YOUR_ARTIFACTORY_PASSWORD \
  --namespace=nirmata-system

# Copy to kyverno namespace  
kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net \
  --docker-username=YOUR_ARTIFACTORY_USERNAME \
  --docker-password=YOUR_ARTIFACTORY_PASSWORD \
  --namespace=kyverno
```

## 📊 Step 4: Deploy via Nirmata Catalog

### Deploy Order (IMPORTANT):

**1. Deploy Operator First:**
```yaml
Chart: nirmata-kyverno-operator
Version: 0.8.8
Namespace: nirmata-system
Repository: customer-n4k-charts
```

**2. Deploy Kyverno:**
```yaml
Chart: kyverno  
Version: 3.3.34
Namespace: kyverno
Repository: customer-n4k-charts
```

## ✅ What's Pre-Configured in Nova Branch

### Registry Configuration:
- **All images**: `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/[component]`
- **Image pull secret**: `artifactory-secret`
- **Image pull policy**: `Always`

### Performance Configuration:
- **Admission Controller**: 3 replicas, 1Gi memory
- **Background Controller**: 2 replicas, 512Mi memory  
- **Cleanup Controller**: 2 replicas, 512Mi memory
- **Reports Controller**: 2 replicas, 512Mi memory

### Operational Configuration:
- **Webhook Failure Policy**: `Ignore` (smooth cleanup)
- **Policy Reports Cleanup**: Enabled
- **Auto Webhook Generation**: Disabled

## 🔍 Step 5: Verify Deployment

### Check Repository Access:
```bash
# Test Bitbucket raw file access
curl -u USERNAME:APP_PASSWORD https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/index.yaml

# Should return Helm index content
```

### Check Chart Installation:
```bash
# Add repo locally to test
helm repo add customer-charts https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/ \
  --username USERNAME --password APP_PASSWORD

# List available charts
helm search repo customer-charts
```

### Check Kubernetes Deployment:
```bash
# Check operator pods
kubectl get pods -n nirmata-system

# Check kyverno pods  
kubectl get pods -n kyverno

# Check image pull secrets
kubectl get secrets -n nirmata-system | grep artifactory
kubectl get secrets -n kyverno | grep artifactory
```

## 🚨 Troubleshooting

### Repository Access Issues:
- **403 Forbidden**: Check Bitbucket app password and permissions
- **404 Not Found**: Verify repository name and branch
- **Index not found**: Ensure `index.yaml` is in repository root

### Image Pull Issues:
- **ImagePullBackOff**: Check artifactory credentials in secrets
- **ErrImagePull**: Verify image paths in Artifactory registry
- **Authentication failed**: Recreate docker-registry secrets

### Chart Size Issues:
- **Secret too large**: Should NOT happen with packaged charts (365KB < 1MB)
- **If it happens**: Use raw YAML manifests approach from GITOPS-SOLUTION.md

### Deployment Order Issues:
- **Operator must be first**: Always deploy operator before kyverno
- **Namespace dependencies**: Ensure both namespaces exist before deployment
- **RBAC issues**: Check operator has proper cluster-admin permissions

## 📋 Customer Checklist

- [ ] Repository mirrored to Bitbucket with nova branch
- [ ] All required files present (index.yaml, .tgz files)
- [ ] Bitbucket app password created
- [ ] Repository access verified via curl/browser
- [ ] Kubernetes namespaces created
- [ ] Artifactory secrets created in both namespaces
- [ ] Nirmata chart repository configured
- [ ] Operator deployed successfully  
- [ ] Kyverno deployed successfully
- [ ] All pods running and pulling images correctly

## 🎯 Success Criteria

When everything is working:
- ✅ Bitbucket repository accessible from Nirmata
- ✅ Charts visible in Nirmata catalog
- ✅ Deployments complete without errors
- ✅ All pods running with correct Artifactory images
- ✅ No secret size limit issues (charts are compressed)
- ✅ Proper cleanup when uninstalling (webhook failurePolicy=Ignore)

## 📞 Support

If customer encounters issues:
1. **Repository access**: Check Bitbucket permissions and credentials
2. **Chart deployment**: Verify prerequisites (namespaces, secrets) 
3. **Image pull**: Confirm Artifactory registry connectivity
4. **Size limits**: Use compressed charts (not raw directories)
5. **Cleanup issues**: Webhook configured for smooth uninstall

## 🔗 Related Documentation

- `NIRMATA-CATALOG-SETUP.md` - General Nirmata catalog setup
- `GITOPS-SOLUTION.md` - Alternative raw YAML approach if needed
- `CUSTOMER-DEPLOYMENT.md` - Direct deployment scripts
