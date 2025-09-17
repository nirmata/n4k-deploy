# 🎯 Customer Deployment Checklist (30 Minutes)

## ✅ PRE-DEPLOYMENT VERIFICATION

### Repository Setup
- [ ] Nova branch accessible: `https://raw.githubusercontent.com/nirmata/n4k-deploy/nova/`
- [ ] index.yaml loads: `https://raw.githubusercontent.com/nirmata/n4k-deploy/nova/index.yaml`
- [ ] Charts accessible:
  - [ ] `kyverno-3.3.34.tgz` (365KB)
  - [ ] `nirmata-kyverno-operator-0.8.8.tgz` (27KB)

### Customer Bitbucket Setup (If Needed)
- [ ] Customer cloned nova branch: `git clone -b nova https://github.com/nirmata/n4k-deploy.git`
- [ ] Customer pushed to their Bitbucket: `git push bitbucket nova`
- [ ] Customer URL format: `https://bitbucket.org/CUSTOMER_ORG/REPO/raw/nova/`

## 🔧 KUBERNETES PREREQUISITES

### Namespaces
```bash
kubectl create namespace nirmata-system
kubectl create namespace kyverno
```

### Artifactory Secrets
```bash
# nirmata-system namespace
kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net \
  --docker-username=ARTIFACTORY_USER \
  --docker-password=ARTIFACTORY_PASS \
  --namespace=nirmata-system

# kyverno namespace  
kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net \
  --docker-username=ARTIFACTORY_USER \
  --docker-password=ARTIFACTORY_PASS \
  --namespace=kyverno
```

### Verify Prerequisites
- [ ] `kubectl get ns nirmata-system kyverno`
- [ ] `kubectl get secrets -n nirmata-system | grep artifactory`
- [ ] `kubectl get secrets -n kyverno | grep artifactory`

## 🎯 NIRMATA CATALOG CONFIGURATION

### Add Chart Repository
```yaml
Name: customer-n4k-charts
Location: https://bitbucket.org/CUSTOMER_ORG/REPO/raw/nova/
# OR if using GitHub directly:
# Location: https://raw.githubusercontent.com/nirmata/n4k-deploy/nova/
Username: BITBUCKET_USERNAME (or GitHub username)
Password: BITBUCKET_APP_PASSWORD (or GitHub PAT)
```

### Verify Repository
- [ ] Repository shows in Nirmata catalog
- [ ] Charts visible:
  - [ ] `nirmata-kyverno-operator` (v0.8.8)
  - [ ] `kyverno` (v3.3.34)

## 🚀 DEPLOYMENT SEQUENCE

### Step 1: Deploy Operator First
```yaml
Chart: nirmata-kyverno-operator
Version: 0.8.8
Namespace: nirmata-system
Repository: customer-n4k-charts
```

**Verify:**
- [ ] `kubectl get pods -n nirmata-system`
- [ ] Operator pod running
- [ ] No ImagePullBackOff errors

### Step 2: Deploy Kyverno
```yaml
Chart: kyverno
Version: 3.3.34
Namespace: kyverno
Repository: customer-n4k-charts
```

**Verify:**
- [ ] `kubectl get pods -n kyverno`
- [ ] All pods running:
  - [ ] 3x admission-controller replicas
  - [ ] 2x background-controller replicas
  - [ ] 2x cleanup-controller replicas
  - [ ] 2x reports-controller replicas

## 🔍 POST-DEPLOYMENT VERIFICATION

### Pod Status
```bash
kubectl get pods -n nirmata-system
kubectl get pods -n kyverno
```

### Image Verification
```bash
# Should show artifactory.f1.novartis.net images
kubectl get pods -n kyverno -o yaml | grep "image:"
kubectl get pods -n nirmata-system -o yaml | grep "image:"
```

### Resource Usage
```bash
# Check memory limits are applied
kubectl describe pods -n kyverno | grep -A2 "Limits:"
```

### Webhook Status
```bash
kubectl get validatingwebhookconfiguration
```

## 🚨 TROUBLESHOOTING

### Common Issues
- **ImagePullBackOff**: Check artifactory-secret exists and is correct
- **Chart not found**: Verify repository URL and credentials
- **Secret too large**: Should NOT happen (charts are compressed)
- **Webhook errors**: failurePolicy=Ignore should prevent blocking

### Quick Fixes
```bash
# Recreate secrets if needed
kubectl delete secret artifactory-secret -n nirmata-system
kubectl delete secret artifactory-secret -n kyverno
# Then recreate with correct credentials

# Check chart repository access
curl -u USERNAME:PASSWORD https://bitbucket.org/CUSTOMER_ORG/REPO/raw/nova/index.yaml
```

## ✅ SUCCESS CRITERIA

- [ ] Operator deployed and running in nirmata-system
- [ ] Kyverno deployed with correct replica counts
- [ ] All pods pulling images from artifactory registry
- [ ] No ImagePullBackOff or CrashLoopBackOff errors
- [ ] Memory limits applied (1Gi for admission, 512Mi for others)
- [ ] Webhook configured with failurePolicy: Ignore

## 📞 EMERGENCY CONTACTS

If deployment fails:
1. Check logs: `kubectl logs -n [namespace] [pod-name]`
2. Verify secrets: `kubectl get secrets -n [namespace]`
3. Check image pull: `kubectl describe pod -n [namespace] [pod-name]`
4. Review documentation: `MANUAL-BITBUCKET-SETUP.md`

---

**🎯 DEPLOYMENT TIME TARGET: 15-20 MINUTES TOTAL**
- Prerequisites: 5 minutes
- Nirmata setup: 5 minutes  
- Deployment: 10 minutes
- Buffer: 10 minutes
