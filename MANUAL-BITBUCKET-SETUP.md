# Manual Bitbucket Setup for Customer

## 🎯 Simple Manual Steps

### Step 1: Customer Creates Bitbucket Repository
```bash
# Customer creates empty repository in Bitbucket:
# Name: n4k-deploy (or any name they want)
# Visibility: Private or Public (their choice)
```

### Step 2: Customer Clones Nova Branch
```bash
git clone -b nova https://github.com/nirmata/n4k-deploy.git
cd n4k-deploy
```

### Step 3: Customer Adds Their Bitbucket Remote
```bash
git remote add bitbucket https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO.git
```
*Replace CUSTOMER_ORG and CUSTOMER_REPO with their actual names*

### Step 4: Customer Pushes to Bitbucket
```bash
git push bitbucket nova
```

### Step 5: Customer Verifies Files Are Accessible
Test these URLs in browser (replace with their org/repo):
- `https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/index.yaml`
- `https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/kyverno-3.3.34.tgz`
- `https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/nirmata-kyverno-operator-0.8.8.tgz`

### Step 6: Customer Configures Nirmata Catalog
In Nirmata, add Helm Chart Repository:
```yaml
Name: customer-n4k-charts
Location: https://bitbucket.org/CUSTOMER_ORG/CUSTOMER_REPO/raw/nova/
Username: BITBUCKET_USERNAME
Password: BITBUCKET_APP_PASSWORD
```

### Step 7: Customer Creates Prerequisites
```bash
# Create namespaces
kubectl create namespace nirmata-system
kubectl create namespace kyverno

# Create artifactory secret (both namespaces)
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

### Step 8: Customer Deploys via Nirmata
1. Deploy `nirmata-kyverno-operator` chart first (namespace: nirmata-system)
2. Deploy `kyverno` chart second (namespace: kyverno)

## ✅ That's It!

**Customer now has:**
- Their own Bitbucket repository with all N4K charts
- Artifactory configuration for all images
- Working Nirmata catalog integration
- No dependency on GitHub access

**All images will pull from:** `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/[component]`
