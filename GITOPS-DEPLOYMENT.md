# GitOps Deployment Guide

This repository is configured for **GitOps deployment** with **ghcr.io/vikashkaushik01** registry.

## 🔐 **Secure Credential Management**

For GitOps deployment, credentials are **NOT** stored in Git. Create the imagePullSecret externally:

### **Before GitOps Deployment**

Create the required imagePullSecret in both namespaces:

```bash
# Create secret in operator namespace
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=vikashkaushik01 \
  --docker-password=<YOUR_GITHUB_TOKEN> \
  --docker-email=<YOUR_EMAIL> \
  --namespace=nirmata-system

# Create secret in kyverno namespace  
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=vikashkaushik01 \
  --docker-password=<YOUR_GITHUB_TOKEN> \
  --docker-email=<YOUR_EMAIL> \
  --namespace=kyverno
```

## 🚀 **GitOps Configuration**

### **Registry Settings**
All charts are pre-configured to use:
- **Registry**: `ghcr.io/vikashkaushik01`
- **Secret Name**: `ghcr-secret`
- **Namespaces**: `nirmata-system`, `kyverno`

### **ArgoCD Application Example**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n4k-deployment
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/nirmata/n4k-deploy.git
    targetRevision: main
    helm:
      valueFiles:
        - kyverno-chart/kyverno/values.yaml
        - operator-chart/nirmata-kyverno-operator/values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: kyverno
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## 📋 **Deployment Order**

1. **Create imagePullSecrets** (see commands above)
2. **Deploy Operator** (ArgoCD/Flux will use `operator-chart/`)  
3. **Deploy N4K** (ArgoCD/Flux will use `kyverno-chart/`)

## ✅ **Ready for GitOps!**

The main branch is now **GitOps-ready** with secure credential management! 🎉