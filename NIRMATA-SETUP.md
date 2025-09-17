# Nirmata Catalog Setup Instructions

## 🎯 Adding Repository to Nirmata Catalog

### Option 1: Direct GitHub Access

**For Your Deployment (Main Branch):**
```yaml
Repository Name: nirmata-n4k-charts-main
Location: https://raw.githubusercontent.com/nirmata/n4k-deploy/main/
Username: vikashkaushik01
Password: <YOUR_GITHUB_PAT>
```

**For Customer Deployment (Nova Branch):**
```yaml
Repository Name: nirmata-n4k-charts-nova  
Location: https://raw.githubusercontent.com/nirmata/n4k-deploy/nova/
Username: vikashkaushik01
Password: <YOUR_GITHUB_PAT>
```

### Option 2: Customer Bitbucket Mirror

#### For Novartis (Bitbucket Enterprise) - READY TO USE:
**Repository already mirrored to:**
```yaml
Repository Name: novartis-n4k-charts
Location: https://bitbucketenterprise.aws.novartis.net/projects/ZEP/repos/n4k-engine-nirmata/raw/nova/
Username: NOVARTIS_BITBUCKET_USERNAME
Password: NOVARTIS_BITBUCKET_PASSWORD
```

**Verify files are accessible:**
- Index: `https://bitbucketenterprise.aws.novartis.net/projects/ZEP/repos/n4k-engine-nirmata/raw/nova/index.yaml`
- Operator Chart: `https://bitbucketenterprise.aws.novartis.net/projects/ZEP/repos/n4k-engine-nirmata/raw/nova/nirmata-kyverno-operator-0.8.8.tgz`
- Kyverno Chart: `https://bitbucketenterprise.aws.novartis.net/projects/ZEP/repos/n4k-engine-nirmata/raw/nova/kyverno-3.3.34.tgz`

#### For Other Customers:
**Customer Manual Steps:**
1. Create Bitbucket repository
2. Clone nova branch: `git clone -b nova https://github.com/nirmata/n4k-deploy.git`
3. Add Bitbucket remote: `git remote add bitbucket https://bitbucket.org/ORG/REPO.git`
4. Push: `git push bitbucket nova`

**Nirmata Configuration:**
```yaml
Repository Name: customer-n4k-charts
Location: https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/
Username: BITBUCKET_USERNAME
Password: BITBUCKET_APP_PASSWORD
```

## 📦 Available Charts

After adding repository, you'll see these charts in Nirmata catalog:

| Chart Name | Version | Description |
|------------|---------|-------------|
| `nirmata-kyverno-operator` | 0.8.8 | Enterprise Kyverno Operator (27KB) |
| `kyverno` | 3.3.34 | Complete N4K deployment (365KB) |

## 🔧 Prerequisites

### Main Branch (Your Deployment)
```bash
# Create namespaces
kubectl create namespace nirmata-system
kubectl create namespace kyverno

# Create GHCR secrets
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=vikashkaushik01 \
  --docker-password=<YOUR_GITHUB_PAT> \
  --namespace=nirmata-system

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=vikashkaushik01 \
  --docker-password=<YOUR_GITHUB_PAT> \
  --namespace=kyverno
```

### Nova Branch (Customer Deployment)
```bash
# Create namespaces
kubectl create namespace nirmata-system
kubectl create namespace kyverno

# Create Artifactory secrets
kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net \
  --docker-username=ARTIFACTORY_USER \
  --docker-password=ARTIFACTORY_PASS \
  --namespace=nirmata-system

kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net \
  --docker-username=ARTIFACTORY_USER \
  --docker-password=ARTIFACTORY_PASS \
  --namespace=kyverno
```

## 🚀 Deployment in Nirmata

### Step 1: Deploy Operator First
```yaml
Chart: nirmata-kyverno-operator
Version: 0.8.8
Namespace: nirmata-system
Repository: [your-repository-name]
```

**Wait for operator pods to be running before proceeding**

### Step 2: Deploy Kyverno
```yaml
Chart: kyverno
Version: 3.3.34
Namespace: kyverno
Repository: [your-repository-name]
```

## ✅ Verification

### Check Operator Deployment
```bash
kubectl get pods -n nirmata-system
```
Expected: 1 operator pod running

### Check Kyverno Deployment
```bash
kubectl get pods -n kyverno
```
Expected:
- 3x admission-controller replicas (1Gi memory each)
- 2x background-controller replicas (512Mi memory each)  
- 2x cleanup-controller replicas (512Mi memory each)
- 2x reports-controller replicas (512Mi memory each)

### Check Images Are Correct

**Main Branch - Should show GHCR images:**
```bash
kubectl get pods -n kyverno -o yaml | grep "image:" | head -5
# Expected: ghcr.io/vikashkaushik01/[component]
```

**Nova Branch - Should show Artifactory images:**
```bash
kubectl get pods -n kyverno -o yaml | grep "image:" | head -5  
# Expected: artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/[component]
```

## 🚨 Troubleshooting

### Repository Not Found
- Verify URL is accessible in browser
- Check credentials (GitHub PAT or Bitbucket App Password)
- Ensure repository is public or credentials have read access

### Novartis Bitbucket Enterprise Specific
- **Authentication**: Use Novartis Active Directory credentials or Bitbucket App Password
- **Network**: Ensure Nirmata platform can access `bitbucketenterprise.aws.novartis.net`
- **Test Access**: Verify you can access the raw files directly in browser:
  - `https://bitbucketenterprise.aws.novartis.net/projects/ZEP/repos/n4k-engine-nirmata/raw/nova/index.yaml`
- **Permissions**: Ensure your user has read access to ZEP project

### ImagePullBackOff Errors
- Check secrets exist: `kubectl get secrets -n [namespace] | grep [secret-name]`
- Verify registry credentials are correct
- Confirm image pull policy allows pulling

### Charts Not Visible
- Check index.yaml is accessible: `[REPO_URL]/index.yaml`
- Verify repository format is correct Helm repository
- Check chart URLs in index.yaml match actual file locations

## 📊 Configuration Details

### Registry Configurations

**Main Branch:**
- **Registry**: `ghcr.io/vikashkaushik01`
- **Secret**: `ghcr-secret`
- **Example**: `ghcr.io/vikashkaushik01/nirmata-kyverno-operator:v0.4.13`

**Nova Branch:**
- **Registry**: `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata`
- **Secret**: `artifactory-secret`
- **Example**: `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/nirmata-kyverno-operator:v0.4.13`

### Performance Settings (Both Branches)
- **Admission Controller**: 3 replicas, 1Gi memory limit
- **Background Controller**: 2 replicas, 512Mi memory limit
- **Cleanup Controller**: 2 replicas, 512Mi memory limit
- **Reports Controller**: 2 replicas, 512Mi memory limit
- **Image Pull Policy**: Always (for EC2 compatibility)

### Operational Features
- **Webhook Failure Policy**: Ignore (smooth cleanup)
- **Policy Reports Cleanup**: Enabled
- **Auto Webhook Generation**: Disabled

## ⏰ Deployment Time

**Expected deployment time:** 15-20 minutes total
- Operator deployment: 5 minutes
- Kyverno deployment: 10-15 minutes
- Verification: 5 minutes

## 🎉 Success Criteria

✅ Repository visible in Nirmata catalog  
✅ Both charts deployable from catalog  
✅ All pods running with correct replica counts  
✅ Images pulling from correct registry  
✅ No ImagePullBackOff errors  
✅ Memory limits applied correctly
