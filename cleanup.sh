#!/bin/bash

# N4K Cleanup Script
# This script removes N4K and Nirmata Kyverno Operator deployments

set -e

echo "🧹 N4K Cleanup Script"
echo "====================="
echo ""

# Configuration
OPERATOR_NAMESPACE="nirmata-system"
KYVERNO_NAMESPACE="kyverno"

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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is required but not installed."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is required but not installed."
    exit 1
fi

# Check kubectl connectivity
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
    exit 1
fi

print_status "Connected to Kubernetes cluster"
echo ""

# Warning message
print_warning "This will completely remove N4K and the Nirmata Kyverno Operator from your cluster."
print_warning "This includes all policies, policy reports, and configuration."
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""

# Remove N4K first
echo "🗑️  Step 1: Removing N4K (Kyverno)..."
echo "====================================="

if helm list -n ${KYVERNO_NAMESPACE} | grep -q kyverno; then
    echo "Uninstalling N4K Helm release..."
    helm uninstall kyverno -n ${KYVERNO_NAMESPACE}
    print_status "N4K Helm release removed"
else
    print_warning "N4K Helm release not found"
fi

# Wait for pods to terminate
echo "⏳ Waiting for N4K pods to terminate..."
kubectl wait --for=delete pod -l app.kubernetes.io/part-of=kyverno -n ${KYVERNO_NAMESPACE} --timeout=120s || true

echo ""

# Remove Operator
echo "🗑️  Step 2: Removing Nirmata Kyverno Operator..."
echo "================================================="

if helm list -n ${OPERATOR_NAMESPACE} | grep -q nirmata-kyverno-operator; then
    echo "Uninstalling Operator Helm release..."
    helm uninstall nirmata-kyverno-operator -n ${OPERATOR_NAMESPACE}
    print_status "Operator Helm release removed"
else
    print_warning "Operator Helm release not found"
fi

# Wait for operator pods to terminate
echo "⏳ Waiting for operator pods to terminate..."
kubectl wait --for=delete pod -l app.kubernetes.io/name=nirmata-kyverno-operator -n ${OPERATOR_NAMESPACE} --timeout=120s || true

echo ""

# Remove CRDs (optional)
echo "🗑️  Step 3: Cleaning up resources..."
echo "==================================="

# Remove webhooks that might be left behind
echo "Removing webhooks..."
kubectl delete validatingwebhookconfigurations -l webhook.kyverno.io/managed-by=kyverno --ignore-not-found=true
kubectl delete mutatingwebhookconfigurations -l webhook.kyverno.io/managed-by=kyverno --ignore-not-found=true
print_status "Webhooks removed"

# Remove policy reports
echo "Removing policy reports..."
kubectl delete clusterpolicyreports --all --ignore-not-found=true
kubectl delete policyreports --all-namespaces --all --ignore-not-found=true
print_status "Policy reports removed"

echo ""

# Remove namespaces
echo "🗑️  Step 4: Removing namespaces..."
echo "=================================="

read -p "Do you want to remove the namespaces (${KYVERNO_NAMESPACE} and ${OPERATOR_NAMESPACE})? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if kubectl get namespace ${KYVERNO_NAMESPACE} &> /dev/null; then
        kubectl delete namespace ${KYVERNO_NAMESPACE}
        print_status "Namespace ${KYVERNO_NAMESPACE} removed"
    else
        print_warning "Namespace ${KYVERNO_NAMESPACE} not found"
    fi
    
    if kubectl get namespace ${OPERATOR_NAMESPACE} &> /dev/null; then
        kubectl delete namespace ${OPERATOR_NAMESPACE}
        print_status "Namespace ${OPERATOR_NAMESPACE} removed"
    else
        print_warning "Namespace ${OPERATOR_NAMESPACE} not found"
    fi
else
    print_warning "Namespaces preserved"
fi

echo ""

# Remove CRDs (optional)
echo "🗑️  Step 5: CRD Cleanup (Optional)..."
echo "===================================="

read -p "Do you want to remove Kyverno CRDs? This will delete all policies and configurations! (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing Kyverno CRDs..."
    kubectl delete crd -l app.kubernetes.io/part-of=kyverno --ignore-not-found=true
    kubectl delete crd -l app.kubernetes.io/name=kyverno --ignore-not-found=true
    print_status "Kyverno CRDs removed"
else
    print_warning "CRDs preserved (policies and configurations remain)"
fi

echo ""

# Final verification
echo "🔍 Final verification..."
echo "======================="

echo "Remaining pods in ${OPERATOR_NAMESPACE}:"
kubectl get pods -n ${OPERATOR_NAMESPACE} 2>/dev/null || echo "Namespace not found or no pods"

echo ""
echo "Remaining pods in ${KYVERNO_NAMESPACE}:"
kubectl get pods -n ${KYVERNO_NAMESPACE} 2>/dev/null || echo "Namespace not found or no pods"

echo ""
print_status "Cleanup completed!"
echo ""

echo "🎉 N4K Cleanup Successful!"
echo "=========================="
echo ""
echo "📋 Summary:"
echo "• N4K components removed"
echo "• Operator removed"
echo "• Webhooks and policy reports cleaned up"
echo "• Cluster is ready for fresh deployment if needed"
echo ""
