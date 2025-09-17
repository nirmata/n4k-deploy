# GitOps Helm Secret Size Issue - Customer Solution

## Problem Summary

**Local Deployment**: ✅ Works fine (Helm 3.18.2 compresses 3.4MB chart → 667KB secret)
**Customer GitOps**: ❌ Fails with "Too long: must have at most 1048576 bytes"

## Root Cause

GitOps platforms often use:
- Older Helm versions with less efficient compression
- Additional metadata that bloats secrets  
- Different processing pipelines
- Platform-specific overhead

## Solution 1: Switch to Raw YAML Deployment (RECOMMENDED)

Instead of Helm charts in GitOps, use pre-rendered YAML manifests:

### Step 1: Generate Manifests Locally
```bash
# Generate operator manifest
helm template nirmata-kyverno-operator ./operator-chart/nirmata-kyverno-operator \
  -n nirmata-system > manifests/operator.yaml

# Generate kyverno manifest  
helm template kyverno ./kyverno-chart/kyverno \
  -n kyverno > manifests/kyverno.yaml
```

### Step 2: Split Large Manifest
```bash
# Split kyverno manifest into smaller files (if needed)
mkdir -p manifests/kyverno
cd manifests
csplit -f kyverno/part- -b %02d.yaml kyverno.yaml '/---/' {*}
```

### Step 3: Deploy via GitOps
```yaml
# gitops-app-operator.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n4k-operator
spec:
  source:
    path: manifests/
    targetRevision: HEAD
    directory:
      include: operator.yaml

---
# gitops-app-kyverno.yaml  
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n4k-kyverno
spec:
  source:
    path: manifests/kyverno/
    targetRevision: HEAD
```

## Solution 2: Multi-App Approach

Deploy as separate GitOps applications:

```yaml
# App 1: Operator (small, no issues)
apiVersion: argoproj.io/v1alpha1
kind: Application  
metadata:
  name: n4k-operator
spec:
  source:
    path: operator-chart/nirmata-kyverno-operator

---
# App 2: Kyverno CRDs only
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n4k-crds
spec:
  source:
    path: kyverno-chart/kyverno
    helm:
      values: |
        crds:
          install: true
        admissionController:
          enabled: false
        backgroundController:
          enabled: false
        cleanupController:
          enabled: false
        reportsController:
          enabled: false

---
# App 3: Kyverno Core Components
apiVersion: argoproj.io/v1alpha1  
kind: Application
metadata:
  name: n4k-core
spec:
  source:
    path: kyverno-chart/kyverno
    helm:
      values: |
        crds:
          install: false
        backgroundController:
          enabled: false
        cleanupController:
          enabled: false
        reportsController:
          enabled: false
```

## Solution 3: Nirmata Platform Specific

For Nirmata GitOps platform:

1. **Enable Raw YAML Mode**: Switch from Helm to raw YAML deployment mode
2. **Use Kustomize**: Convert charts to Kustomize overlays
3. **Contact Support**: Request Helm version upgrade or secret size limit increase

## Implementation for Customer

### Immediate Fix (Raw YAML):

1. **Generate manifests locally**:
   ```bash
   # Use the nova branch for customer
   git checkout nova
   
   # Generate operator manifest
   helm template nirmata-kyverno-operator ./operator-chart/nirmata-kyverno-operator \
     -n nirmata-system > customer-manifests/operator.yaml
   
   # Generate kyverno manifest
   helm template kyverno ./kyverno-chart/kyverno \
     -n kyverno > customer-manifests/kyverno.yaml
   ```

2. **Commit manifests to nova branch**:
   ```bash
   git add customer-manifests/
   git commit -m "Add pre-rendered manifests for GitOps deployment"
   git push origin nova
   ```

3. **Customer deploys raw YAML** instead of Helm charts

### Benefits:
- ✅ No Helm secret size limits
- ✅ Works with all GitOps platforms  
- ✅ Faster deployment (no rendering needed)
- ✅ Preserves all configurations (replicas, memory, registry)

## Testing the Solution

```bash
# Test manifest sizes
ls -lh customer-manifests/
wc -l customer-manifests/*.yaml

# Validate manifests
kubectl apply --dry-run=client -f customer-manifests/
```

## Long-term Recommendations

1. **Use Raw YAML for large charts** in GitOps environments
2. **Keep Helm for local development** and testing
3. **Automate manifest generation** in CI/CD pipeline
4. **Version control rendered manifests** alongside charts
