# N4K Deployment with GitHub Container Registry (GHCR)

This directory contains everything needed to deploy N4K (Nirmata for Kubernetes) using images from your personal GitHub Container Registry.

## 📁 Files Overview

### 📦 **Helm Charts** (Downloaded locally)
- `kyverno-3.3.34.tgz` - Main N4K/Kyverno Helm chart
- `nirmata-kyverno-operator-0.8.8.tgz` - Nirmata Kyverno Operator chart
- `charts/` - Extracted chart directories

### 🐳 **Image Management**
- `push-images-to-ghcr.sh` - Script to push all images to ghcr.io/vikashkaushik01
- Container images included:
  - **N4K Components**: kyverno, background-controller, cleanup-controller, reports-controller, kyvernopre, kyverno-cli
  - **Utilities**: kubectl (multiple versions), busybox
  - **Operator**: nirmata-kyverno-operator

### ⚙️ **Configuration Files**
- `n4k-values-ghcr.yaml` - Helm values for N4K deployment using GHCR images
- `operator-values-ghcr.yaml` - Helm values for Operator deployment using GHCR images

### 🚀 **Deployment Scripts**
- `deploy-with-ghcr.sh` - Complete deployment script using GHCR images

## 🎯 **Step-by-Step Deployment**

### **Step 1: Push Images to GHCR**
```bash
# First, login to GitHub Container Registry
docker login ghcr.io -u vikashkaushik01

# Run the image push script
./push-images-to-ghcr.sh
```
This will pull all 11 container images and push them to `ghcr.io/vikashkaushik01/`

### **Step 2: Deploy with Helm**
```bash
# Deploy both components using custom GHCR images
./deploy-with-ghcr.sh
```

### **Alternative: Manual Deployment**
```bash
# Deploy operator first
helm install nirmata-kyverno-operator ./charts/nirmata-kyverno-operator \
  -n nirmata-system --create-namespace \
  -f operator-values-ghcr.yaml

# Deploy N4K
helm install kyverno ./charts/kyverno \
  -n kyverno --create-namespace \
  -f n4k-values-ghcr.yaml
```

## 🐳 **Images Available in GHCR**

After running the push script, these images will be available:

### **N4K Component Images:**
- `ghcr.io/vikashkaushik01/kyverno:v1.13.6-n4k.nirmata.10`
- `ghcr.io/vikashkaushik01/background-controller:v1.13.6-n4k.nirmata.10`
- `ghcr.io/vikashkaushik01/cleanup-controller:v1.13.6-n4k.nirmata.10`
- `ghcr.io/vikashkaushik01/reports-controller:v1.13.6-n4k.nirmata.10`
- `ghcr.io/vikashkaushik01/kyvernopre:v1.13.6-n4k.nirmata.10`
- `ghcr.io/vikashkaushik01/kyverno-cli:v1.13.6-n4k.nirmata.10`

### **Utility Images:**
- `ghcr.io/vikashkaushik01/kubectl:1.29.1`
- `ghcr.io/vikashkaushik01/kubectl:1.31.1`
- `ghcr.io/vikashkaushik01/kubectl:1.32.1`
- `ghcr.io/vikashkaushik01/busybox:1.35`

### **Operator Image:**
- `ghcr.io/vikashkaushik01/nirmata-kyverno-operator:v0.4.13`

## ✅ **Verification**

After deployment, verify everything is running:

```bash
# Check operator pods
kubectl get pods -n nirmata-system

# Check N4K pods
kubectl get pods -n kyverno

# Check services
kubectl get svc -n nirmata-system
kubectl get svc -n kyverno
```

## 🔄 **For Customer Environment**

This same approach can be used for customer deployments:

1. **Replace registry**: Update values files to point to customer's registry
2. **Push images**: Use the same script pattern to push to customer's registry
3. **Deploy**: Use the same Helm commands with updated values

### **Example for Novartis Artifactory:**
Update the registry in values files from:
```yaml
registry: "ghcr.io/vikashkaushik01"
```
to:
```yaml
registry: "artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker"
```

## 📋 **Components Installed**

### **Nirmata Kyverno Operator** (namespace: nirmata-system)
- Manages Kyverno lifecycle
- Webhook-based policy validation
- Certificate management

### **N4K/Kyverno** (namespace: kyverno)
- Admission controller
- Background controller
- Cleanup controller
- Reports controller
- Policy exceptions enabled for all namespaces

## 🆘 **Troubleshooting**

### **Image Pull Issues:**
- Ensure you're logged into GHCR: `docker login ghcr.io`
- Check image visibility in GitHub packages
- Verify image tags match values files

### **Deployment Issues:**
- Check pod logs: `kubectl logs -n <namespace> <pod-name>`
- Verify RBAC permissions
- Check service endpoints

## 📞 **Support**

For issues or questions, contact the Nirmata team or check:
- [Kyverno Documentation](https://kyverno.io/docs/)
- [Nirmata Documentation](https://docs.nirmata.com/)
