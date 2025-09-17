# N4K Customer Deployment Guide (Nova Branch)

This guide provides step-by-step instructions for deploying N4K (Nirmata Kyverno) in customer environments using the nova branch configuration.

## Pre-requisites

Before deploying N4K, ensure you have:

1. **Kubernetes Cluster Access**: kubectl configured with cluster-admin permissions
2. **Helm 3.x**: Installed and configured
3. **Registry Access**: Valid credentials for `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker`
4. **Images**: All N4K images pushed to your artifactory registry

## Required Images

The following images must be available in your artifactory registry:

### Kyverno Components (9 images):
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kyverno:v1.13.6-n4k.nirmata.10`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/background-controller:v1.13.6-n4k.nirmata.10`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/cleanup-controller:v1.13.6-n4k.nirmata.10`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/reports-controller:v1.13.6-n4k.nirmata.10`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kyvernopre:v1.13.6-n4k.nirmata.10`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kyverno-cli:v1.13.6-n4k.nirmata.10`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kubectl:1.31.1`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kubectl:1.32.1`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/busybox:1.35`

### Operator Components (2 images):
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/ghcr.io/nirmata/nirmata-kyverno-operator:v0.4.13`
- `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kubectl:1.29.1`

## Step 1: Create Required Namespaces

```bash
# Create operator namespace
kubectl create namespace nirmata-system

# Create kyverno namespace  
kubectl create namespace kyverno
```

## Step 2: Create Registry Secrets

Create the registry secret for pulling images from artifactory:

```bash
# Create secret in nirmata-system namespace (for operator)
kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker \
  --docker-username=<YOUR_USERNAME> \
  --docker-password=<YOUR_PASSWORD> \
  --docker-email=<YOUR_EMAIL> \
  -n nirmata-system

# Create secret in kyverno namespace (for N4K components)
kubectl create secret docker-registry artifactory-secret \
  --docker-server=artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker \
  --docker-username=<YOUR_USERNAME> \
  --docker-password=<YOUR_PASSWORD> \
  --docker-email=<YOUR_EMAIL> \
  -n kyverno
```

## Step 3: Deploy Nirmata Kyverno Operator

```bash
# Deploy the operator
helm install nirmata-kyverno-operator ./operator-chart/nirmata-kyverno-operator \
  -n nirmata-system \
  --wait --timeout=300s

# Verify operator is running
kubectl get pods -n nirmata-system
kubectl logs -n nirmata-system deployment/nirmata-kyverno-operator
```

## Step 4: Deploy N4K (Kyverno)

```bash
# Deploy N4K components
helm install kyverno ./kyverno-chart/kyverno \
  -n kyverno \
  --wait --timeout=600s

# Verify all components are running
kubectl get pods -n kyverno
```

## Step 5: Verification

### Check Pod Status
```bash
# Check operator
kubectl get pods -n nirmata-system

# Check N4K components
kubectl get pods -n kyverno
```

### Verify Replica Counts
- **Admission Controller**: 3 replicas (High Availability)
- **Background Controller**: 2 replicas  
- **Cleanup Controller**: 2 replicas
- **Reports Controller**: 2 replicas

### Verify Memory Limits
- **Admission Controller**: 1Gi memory limit
- **Other Controllers**: 512Mi memory limit

### Check Services
```bash
kubectl get svc -n nirmata-system
kubectl get svc -n kyverno
```

## Configuration Features

This deployment includes:

- **Enhanced Performance**: Optimized replica counts and memory limits
- **Private Registry**: Full artifactory.f1.novartis.net integration  
- **Smooth Cleanup**: Webhook failurePolicy set to Ignore for proper uninstall
- **Always Pull**: ImagePullPolicy set to Always for latest images
- **Production Ready**: Tested and validated configuration

## Troubleshooting

### Image Pull Issues
```bash
# Check if secrets are created
kubectl get secrets -n nirmata-system | grep artifactory
kubectl get secrets -n kyverno | grep artifactory

# Check pod events for image pull errors
kubectl describe pod <pod-name> -n <namespace>
```

### Operator Issues  
```bash
# Check operator logs
kubectl logs -n nirmata-system deployment/nirmata-kyverno-operator

# Check webhook configuration
kubectl get validatingwebhookconfigurations | grep kyverno-operator
```

### Component Issues
```bash
# Check component logs
kubectl logs -n kyverno deployment/kyverno-admission-controller
kubectl logs -n kyverno deployment/kyverno-background-controller
kubectl logs -n kyverno deployment/kyverno-cleanup-controller
kubectl logs -n kyverno deployment/kyverno-reports-controller
```

## Uninstall

To cleanly remove N4K:

```bash
# Uninstall N4K
helm uninstall kyverno -n kyverno

# Uninstall Operator  
helm uninstall nirmata-kyverno-operator -n nirmata-system

# Optional: Remove namespaces
kubectl delete namespace kyverno
kubectl delete namespace nirmata-system
```

## Support

For support and additional documentation, contact the Nirmata support team.
