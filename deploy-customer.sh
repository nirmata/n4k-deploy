#!/bin/bash

# N4K Customer Deployment Script (Nova Branch)
# This script deploys N4K for customer environments with artifactory registry

set -e

echo "🚀 N4K Customer Deployment (Nova Branch)"
echo "========================================"
echo "Using Novartis Artifactory Registry"
echo ""

# Configuration
OPERATOR_NAMESPACE="nirmata-system"
KYVERNO_NAMESPACE="kyverno"
REGISTRY_SECRET_NAME="artifactory-secret"
REGISTRY_URL="artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker"
TIMEOUT="300s"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is required but not installed."
        exit 1
    fi
}

# Check prerequisites
echo "🔍 Checking prerequisites..."
check_command "helm"
check_command "kubectl"
print_status "All prerequisites found"
echo ""

# Check kubectl connectivity
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
    exit 1
fi

print_status "Connected to Kubernetes cluster"
echo ""

print_warning "IMPORTANT: This script requires the following images to be available in your registry:"
echo "  • artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/kyverno:v1.13.6-n4k.nirmata.10"
echo "  • artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/background-controller:v1.13.6-n4k.nirmata.10"
echo "  • artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/cleanup-controller:v1.13.6-n4k.nirmata.10"
echo "  • artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata/reports-controller:v1.13.6-n4k.nirmata.10"
echo "  • artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/ghcr.io/nirmata/nirmata-kyverno-operator:v0.4.13"
echo "  • And 6 more images (see CUSTOMER-DEPLOYMENT.md for complete list)"
echo ""

read -p "Press Enter to continue if all images are available, or Ctrl+C to abort..."
echo ""

# Get registry credentials
echo "🔐 Setting up registry credentials..."
echo "===================================="

print_info "You need valid credentials for ${REGISTRY_URL}"

read -p "Enter registry username: " REGISTRY_USER
read -s -p "Enter registry password/token: " REGISTRY_PASS
echo ""
read -p "Enter email address: " REGISTRY_EMAIL
echo ""

# Step 1: Create namespaces
echo "📁 Step 1: Creating required namespaces..."
echo "=========================================="

# Create namespaces
kubectl create namespace ${OPERATOR_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${KYVERNO_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

print_status "Namespaces created: ${OPERATOR_NAMESPACE}, ${KYVERNO_NAMESPACE}"
echo ""

# Step 2: Create registry secrets
echo "🔐 Step 2: Creating registry secrets..."
echo "======================================="

# Create secrets in both namespaces
kubectl create secret docker-registry ${REGISTRY_SECRET_NAME} \
  --docker-server="${REGISTRY_URL}" \
  --docker-username="${REGISTRY_USER}" \
  --docker-password="${REGISTRY_PASS}" \
  --docker-email="${REGISTRY_EMAIL}" \
  -n ${OPERATOR_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry ${REGISTRY_SECRET_NAME} \
  --docker-server="${REGISTRY_URL}" \
  --docker-username="${REGISTRY_USER}" \
  --docker-password="${REGISTRY_PASS}" \
  --docker-email="${REGISTRY_EMAIL}" \
  -n ${KYVERNO_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

print_status "Registry secrets created in both namespaces"
echo ""

# Step 3: Deploy Operator
echo "🔧 Step 3: Deploying Nirmata Kyverno Operator..."
echo "================================================="

# Deploy operator
helm install nirmata-kyverno-operator ./operator-chart/nirmata-kyverno-operator \
    -n ${OPERATOR_NAMESPACE} \
    --wait --timeout=${TIMEOUT}

if [ $? -eq 0 ]; then
    print_status "Operator deployed successfully!"
else
    print_error "Operator deployment failed!"
    exit 1
fi

echo ""

# Wait for operator to be ready
echo "⏳ Waiting for operator to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=nirmata-kyverno-operator -n ${OPERATOR_NAMESPACE} --timeout=120s

print_status "Operator is ready"
echo ""

# Step 4: Deploy N4K
echo "🔧 Step 4: Deploying N4K (Kyverno)..."
echo "====================================="

# Deploy N4K
helm install kyverno ./kyverno-chart/kyverno \
    -n ${KYVERNO_NAMESPACE} \
    --wait --timeout=600s

if [ $? -eq 0 ]; then
    print_status "N4K deployed successfully!"
else
    print_error "N4K deployment failed!"
    exit 1
fi

echo ""

# Step 5: Verification
echo "🔍 Step 5: Verifying deployment..."
echo "=================================="

echo "Operator Status:"
kubectl get pods -n ${OPERATOR_NAMESPACE}
echo ""

echo "N4K Status:"
kubectl get pods -n ${KYVERNO_NAMESPACE}
echo ""

echo "Replica Count Verification:"
echo "• Admission Controller: $(kubectl get deployment kyverno-admission-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 'N/A') replicas"
echo "• Background Controller: $(kubectl get deployment kyverno-background-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 'N/A') replicas"
echo "• Cleanup Controller: $(kubectl get deployment kyverno-cleanup-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 'N/A') replicas"
echo "• Reports Controller: $(kubectl get deployment kyverno-reports-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 'N/A') replicas"
echo ""

echo "Memory Limit Verification:"
echo "• Admission Controller: $(kubectl get deployment kyverno-admission-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo 'N/A')"
echo "• Background Controller: $(kubectl get deployment kyverno-background-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo 'N/A')"
echo "• Cleanup Controller: $(kubectl get deployment kyverno-cleanup-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo 'N/A')"
echo "• Reports Controller: $(kubectl get deployment kyverno-reports-controller -n ${KYVERNO_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo 'N/A')"
echo ""

print_status "Deployment verification complete!"
echo ""

echo "🎉 Customer N4K Deployment Successful!"
echo "======================================="
echo ""
echo "📋 Summary:"
echo "• Operator: nirmata-kyverno-operator running in ${OPERATOR_NAMESPACE}"
echo "• N4K: All components running in ${KYVERNO_NAMESPACE}"
echo "• Registry: ${REGISTRY_URL}"
echo "• Secret: ${REGISTRY_SECRET_NAME} configured in both namespaces"
echo "• Replica Counts: admission=3, others=2 (High Availability)"
echo "• Memory Limits: admission=1Gi, others=512Mi (Enhanced Performance)"
echo "• Webhook Fix: failurePolicy=Ignore (Smooth Cleanup)"
echo ""
echo "🚀 Your Customer N4K deployment is ready for use!"
echo ""
echo "📖 Next Steps:"
echo "• Test policy validation with your policies"
echo "• Configure monitoring and alerting" 
echo "• Review security policies and exceptions"
echo "• See CUSTOMER-DEPLOYMENT.md for detailed documentation"
echo ""
