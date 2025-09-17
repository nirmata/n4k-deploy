#!/bin/bash

# Generate Customer Manifests for GitOps Deployment
# Solves Helm secret size limit by pre-rendering YAML manifests

set -e

echo "🚀 Generating Customer Manifests for GitOps"
echo "==========================================="
echo "This script generates pre-rendered YAML manifests to avoid Helm secret size limits"
echo ""

# Create manifests directory
MANIFEST_DIR="customer-manifests"
mkdir -p ${MANIFEST_DIR}

echo "📁 Created manifests directory: ${MANIFEST_DIR}"
echo ""

# Generate Operator Manifest (small, no issues)
echo "🔧 Generating Operator Manifest..."
helm template nirmata-kyverno-operator ./operator-chart/nirmata-kyverno-operator \
    --namespace nirmata-system \
    --include-crds > ${MANIFEST_DIR}/operator.yaml

OPERATOR_SIZE=$(wc -c < ${MANIFEST_DIR}/operator.yaml)
echo "✅ Operator manifest: ${OPERATOR_SIZE} bytes"
echo ""

# Generate Kyverno Manifest
echo "🔧 Generating Kyverno Manifest..."
helm template kyverno ./kyverno-chart/kyverno \
    --namespace kyverno \
    --include-crds > ${MANIFEST_DIR}/kyverno.yaml

KYVERNO_SIZE=$(wc -c < ${MANIFEST_DIR}/kyverno.yaml)
echo "✅ Kyverno manifest: ${KYVERNO_SIZE} bytes"
echo ""

# Check if Kyverno manifest is too large for single file deployment
if [ ${KYVERNO_SIZE} -gt 500000 ]; then
    echo "⚠️  Kyverno manifest is large (${KYVERNO_SIZE} bytes)"
    echo "🔧 Splitting into smaller files for better GitOps compatibility..."
    
    mkdir -p ${MANIFEST_DIR}/kyverno-split
    
    # Split by resource type for better organization
    echo "📋 Splitting by resource types..."
    
    # Extract CRDs
    kubectl apply --dry-run=client -f ${MANIFEST_DIR}/kyverno.yaml -o yaml | \
        yq eval 'select(.kind == "CustomResourceDefinition")' > ${MANIFEST_DIR}/kyverno-split/01-crds.yaml
    
    # Extract RBAC
    kubectl apply --dry-run=client -f ${MANIFEST_DIR}/kyverno.yaml -o yaml | \
        yq eval 'select(.kind == "ClusterRole" or .kind == "ClusterRoleBinding" or .kind == "ServiceAccount" or .kind == "Role" or .kind == "RoleBinding")' > ${MANIFEST_DIR}/kyverno-split/02-rbac.yaml
    
    # Extract ConfigMaps and Secrets
    kubectl apply --dry-run=client -f ${MANIFEST_DIR}/kyverno.yaml -o yaml | \
        yq eval 'select(.kind == "ConfigMap" or .kind == "Secret")' > ${MANIFEST_DIR}/kyverno-split/03-config.yaml
    
    # Extract Services
    kubectl apply --dry-run=client -f ${MANIFEST_DIR}/kyverno.yaml -o yaml | \
        yq eval 'select(.kind == "Service")' > ${MANIFEST_DIR}/kyverno-split/04-services.yaml
    
    # Extract Deployments and Jobs
    kubectl apply --dry-run=client -f ${MANIFEST_DIR}/kyverno.yaml -o yaml | \
        yq eval 'select(.kind == "Deployment" or .kind == "Job" or .kind == "DaemonSet")' > ${MANIFEST_DIR}/kyverno-split/05-workloads.yaml
    
    # Extract everything else
    kubectl apply --dry-run=client -f ${MANIFEST_DIR}/kyverno.yaml -o yaml | \
        yq eval 'select(.kind != "CustomResourceDefinition" and .kind != "ClusterRole" and .kind != "ClusterRoleBinding" and .kind != "ServiceAccount" and .kind != "Role" and .kind != "RoleBinding" and .kind != "ConfigMap" and .kind != "Secret" and .kind != "Service" and .kind != "Deployment" and .kind != "Job" and .kind != "DaemonSet")' > ${MANIFEST_DIR}/kyverno-split/06-other.yaml
    
    # Remove empty files
    find ${MANIFEST_DIR}/kyverno-split -name "*.yaml" -size 0 -delete
    
    echo "✅ Split into files:"
    ls -la ${MANIFEST_DIR}/kyverno-split/
    echo ""
else
    echo "✅ Kyverno manifest size is acceptable for single file deployment"
    echo ""
fi

# Generate namespace manifests
echo "📁 Generating Namespace Manifests..."
cat > ${MANIFEST_DIR}/00-namespaces.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: nirmata-system
  labels:
    name: nirmata-system
---
apiVersion: v1
kind: Namespace
metadata:
  name: kyverno
  labels:
    name: kyverno
EOF

echo "✅ Namespace manifest created"
echo ""

# Generate secret creation script
echo "🔐 Generating Secret Creation Script..."
cat > ${MANIFEST_DIR}/create-secrets.sh << 'EOF'
#!/bin/bash

echo "🔐 Creating Image Pull Secrets for N4K Deployment"
echo "================================================="

# Configuration - UPDATE THESE VALUES
REGISTRY_URL="artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker"
SECRET_NAME="artifactory-secret"

# Prompt for credentials
read -p "Enter registry username: " REGISTRY_USER
read -s -p "Enter registry password: " REGISTRY_PASS
echo ""
read -p "Enter email address: " REGISTRY_EMAIL

# Create secrets
kubectl create secret docker-registry ${SECRET_NAME} \
  --docker-server="${REGISTRY_URL}" \
  --docker-username="${REGISTRY_USER}" \
  --docker-password="${REGISTRY_PASS}" \
  --docker-email="${REGISTRY_EMAIL}" \
  -n nirmata-system --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry ${SECRET_NAME} \
  --docker-server="${REGISTRY_URL}" \
  --docker-username="${REGISTRY_USER}" \
  --docker-password="${REGISTRY_PASS}" \
  --docker-email="${REGISTRY_EMAIL}" \
  -n kyverno --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created in both namespaces"
EOF

chmod +x ${MANIFEST_DIR}/create-secrets.sh
echo "✅ Secret creation script: ${MANIFEST_DIR}/create-secrets.sh"
echo ""

# Generate deployment instructions
echo "📋 Generating Deployment Instructions..."
cat > ${MANIFEST_DIR}/README.md << EOF
# N4K GitOps Deployment Manifests

These pre-rendered YAML manifests solve the Helm secret size limit issue in GitOps platforms.

## Deployment Order

1. **Create Namespaces**:
   \`\`\`bash
   kubectl apply -f 00-namespaces.yaml
   \`\`\`

2. **Create Image Pull Secrets**:
   \`\`\`bash
   ./create-secrets.sh
   \`\`\`

3. **Deploy Operator**:
   \`\`\`bash
   kubectl apply -f operator.yaml
   \`\`\`

4. **Deploy Kyverno** (choose one):
   
   **Option A - Single File**:
   \`\`\`bash
   kubectl apply -f kyverno.yaml
   \`\`\`
   
   **Option B - Split Files** (if kyverno-split/ directory exists):
   \`\`\`bash
   kubectl apply -f kyverno-split/
   \`\`\`

## Verification

\`\`\`bash
# Check operator
kubectl get pods -n nirmata-system

# Check kyverno components  
kubectl get pods -n kyverno

# Verify replica counts and memory limits
kubectl get deployments -n kyverno -o wide
\`\`\`

## Features

- ✅ Replica Counts: admission=3, others=2
- ✅ Memory Limits: admission=1Gi, others=512Mi  
- ✅ Registry: artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker
- ✅ Secrets: artifactory-secret
- ✅ Webhook Fix: failurePolicy=Ignore

## GitOps Integration

Deploy these manifests via your GitOps platform (ArgoCD, Flux, etc.) instead of Helm charts.
EOF

echo "✅ Deployment instructions: ${MANIFEST_DIR}/README.md"
echo ""

# Summary
echo "🎉 Customer Manifests Generated Successfully!"
echo "============================================="
echo ""
echo "📁 Generated Files:"
find ${MANIFEST_DIR} -type f | sort
echo ""
echo "📏 File Sizes:"
find ${MANIFEST_DIR} -name "*.yaml" -exec ls -lh {} \; | awk '{print $9 ": " $5}'
echo ""
echo "📋 Next Steps:"
echo "1. Review generated manifests in ${MANIFEST_DIR}/"
echo "2. Test deployment locally: kubectl apply -f ${MANIFEST_DIR}/"
echo "3. Commit to git for customer GitOps deployment"
echo "4. Customer uses raw YAML instead of Helm charts"
echo ""
echo "✅ This approach avoids all Helm secret size limits!"
echo ""
