#!/bin/bash

# N4K Deployment Script
# This script deploys both the operator and N4K components using custom registry images

set -e

echo "🚀 N4K Deployment with Custom Registry Images"
echo "=============================================="
echo ""

# Configuration
OPERATOR_NAMESPACE="nirmata-system"
KYVERNO_NAMESPACE="kyverno"
TIMEOUT="300s"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Check if values files exist
if [ ! -f "operator-chart/values-ghcr.yaml" ] || [ ! -f "kyverno-chart/values-ghcr.yaml" ]; then
    print_error "Custom values files not found. Please ensure values-ghcr.yaml files exist in chart directories."
    exit 1
fi

# Check kubectl connectivity
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
    exit 1
fi

print_status "Connected to Kubernetes cluster"
echo ""

# Deploy Operator
echo "🔧 Step 1: Deploying Nirmata Kyverno Operator..."
echo "================================================="

# Create namespace if it doesn't exist
kubectl create namespace ${OPERATOR_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy operator
helm install nirmata-kyverno-operator ./operator-chart/nirmata-kyverno-operator \
    -n ${OPERATOR_NAMESPACE} \
    -f operator-chart/values-ghcr.yaml \
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

# Deploy N4K
echo "🔧 Step 2: Deploying N4K (Kyverno)..."
echo "====================================="

# Create namespace if it doesn't exist
kubectl create namespace ${KYVERNO_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy N4K
helm install kyverno ./kyverno-chart/kyverno \
    -n ${KYVERNO_NAMESPACE} \
    -f kyverno-chart/values-ghcr.yaml \
    --wait --timeout=600s

if [ $? -eq 0 ]; then
    print_status "N4K deployed successfully!"
else
    print_error "N4K deployment failed!"
    exit 1
fi

echo ""

# Verify deployment
echo "🔍 Verifying deployment..."
echo "=========================="

echo "Operator Status:"
kubectl get pods -n ${OPERATOR_NAMESPACE}
echo ""

echo "N4K Status:"
kubectl get pods -n ${KYVERNO_NAMESPACE}
echo ""

echo "Services:"
echo "Operator Services:"
kubectl get svc -n ${OPERATOR_NAMESPACE}
echo ""
echo "N4K Services:"
kubectl get svc -n ${KYVERNO_NAMESPACE}
echo ""

print_status "Deployment verification complete!"
echo ""

echo "🎉 N4K Deployment Successful!"
echo "=============================="
echo ""
echo "📋 Summary:"
echo "• Operator: nirmata-kyverno-operator running in ${OPERATOR_NAMESPACE}"
echo "• N4K: All components running in ${KYVERNO_NAMESPACE}"
echo "• Policy Exceptions: Enabled for all namespaces"
echo "• Custom Registry: Images pulled from your private registry"
echo ""
echo "🚀 Your N4K deployment is ready for use!"
echo ""
echo "📖 Next Steps:"
echo "• Test policy validation with sample policies"
echo "• Configure monitoring and alerting"
echo "• Review security policies and exceptions"
echo ""
