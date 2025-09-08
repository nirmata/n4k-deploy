# N4K Deployment Repository

This repository contains Helm charts and configurations for deploying N4K (Nirmata for Kubernetes) and the Nirmata Kyverno Operator using custom container registries.

## 📁 Repository Structure

```
n4k-deploy/
├── kyverno-chart/                     # N4K (Kyverno) Helm Chart
│   ├── kyverno/                       # Main Helm chart directory
│   │   ├── Chart.yaml
│   │   ├── values.yaml                # Default values
│   │   ├── templates/                 # Helm templates
│   │   └── charts/                    # Sub-charts (CRDs, etc.)
│   └── values-ghcr.yaml               # 🔧 Custom values for GHCR deployment
├── operator-chart/                    # Nirmata Kyverno Operator Helm Chart
│   ├── nirmata-kyverno-operator/      # Main Helm chart directory
│   │   ├── Chart.yaml
│   │   ├── values.yaml                # Default values
│   │   ├── templates/                 # Helm templates
│   │   └── crds/                      # Custom Resource Definitions
│   └── values-ghcr.yaml               # 🔧 Custom values for GHCR deployment
├── push-images-to-ghcr.sh             # 🐳 Script to push images to GHCR
├── deploy.sh                          # 🚀 One-click deployment script
├── cleanup.sh                         # 🧹 Cleanup/uninstall script
├── GHCR-DEPLOYMENT-README.md           # 📖 Detailed deployment guide
└── README.md                          # 📋 This file
```

## 🚀 Quick Start

### Prerequisites
- Helm 3.x installed
- kubectl configured for your cluster
- Docker/Podman for image operations
- Access to a container registry (GHCR, Artifactory, etc.)

### 1. Push Images to Your Registry
```bash
# Edit the script with your registry details
./push-images-to-ghcr.sh
```

### 2. One-Click Deployment
```bash
# Deploy both operator and N4K
./deploy.sh
```

### Alternative: Manual Deployment

#### Deploy Operator First
```bash
helm install nirmata-kyverno-operator ./operator-chart/nirmata-kyverno-operator \
  -n nirmata-system --create-namespace \
  -f operator-chart/values-ghcr.yaml
```

#### Deploy N4K
```bash
helm install kyverno ./kyverno-chart/kyverno \
  -n kyverno --create-namespace \
  -f kyverno-chart/values-ghcr.yaml
```

## 🐳 Container Images

### N4K Components (9 images):
- `kyverno:v1.13.6-n4k.nirmata.10`
- `background-controller:v1.13.6-n4k.nirmata.10`
- `cleanup-controller:v1.13.6-n4k.nirmata.10`
- `reports-controller:v1.13.6-n4k.nirmata.10`
- `kyvernopre:v1.13.6-n4k.nirmata.10`
- `kyverno-cli:v1.13.6-n4k.nirmata.10`
- `kubectl:1.31.1`
- `kubectl:1.32.1`
- `busybox:1.35`

### Operator Components (2 images):
- `nirmata-kyverno-operator:v0.4.13`
- `kubectl:1.29.1`

## ⚙️ Custom Values Configuration

### For GHCR (GitHub Container Registry):
- **Registry**: `ghcr.io/your-username`
- **Authentication**: Image pull secrets configured
- **All defaults overridden**: Registry and defaultRegistry set to `~`

### For Customer Registries (e.g., Artifactory):
Update the values files to point to customer's registry:
```yaml
# Example for Novartis Artifactory
image:
  registry: ~
  defaultRegistry: ~
  repository: artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kyverno
```

## 🔐 Security Features

- **Policy Exceptions**: Enabled for all namespaces
- **Image Pull Secrets**: Configured for private registries
- **Webhook Protection**: Active policy validation
- **Certificate Management**: Automated by operator
- **Non-root Containers**: Security contexts enforced

## 📋 Deployment Order

1. **Create Namespaces**: `nirmata-system` and `kyverno`
2. **Setup Image Pull Secrets**: For private registry access
3. **Deploy Operator**: Manages N4K lifecycle
4. **Deploy N4K**: Main policy engine components

## 🛠️ Customization for Different Environments

### Development Environment:
- Use public images for faster deployment
- Minimal resource requests
- Single replica configurations

### Production Environment:
- Private registry images
- High availability (multiple replicas)
- Resource limits and requests properly set
- Network policies configured

### Air-Gapped Environment:
- All images pushed to internal registry
- Custom CA certificates if needed
- Offline documentation available

## 🧪 Testing

After deployment, verify with:
```bash
# Check operator status
kubectl get pods -n nirmata-system

# Check N4K components
kubectl get pods -n kyverno

# Test policy validation
kubectl apply -f test-policy.yaml
```

## 🧹 Cleanup

To remove the deployment:
```bash
./cleanup.sh
```

Or manually:
```bash
helm uninstall kyverno -n kyverno
helm uninstall nirmata-kyverno-operator -n nirmata-system
kubectl delete namespace kyverno nirmata-system
```

## 📞 Support

- **Chart Source**: Official Nirmata Helm repositories
- **Version**: Kyverno v3.3.34, Operator v0.8.8
- **Documentation**: See `GHCR-DEPLOYMENT-README.md` for detailed instructions

## 🔄 Updates

To update to newer versions:
1. Pull latest charts from Nirmata repositories
2. Update image tags in values files
3. Push new images to your registry
4. Upgrade Helm deployments

---

**Note**: This repository contains tested configurations for deploying N4K with custom container registries. Modify the values files according to your environment's requirements.
