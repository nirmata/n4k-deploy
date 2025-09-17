#!/bin/bash

# N4K Split Component Deployment Script
# Solves GitOps Helm secret size limit issue by deploying components separately

set -e

echo "🚀 N4K Split Component Deployment"
echo "================================="
echo "Deploying N4K components separately to avoid Helm secret size limits"
echo ""

# Configuration
OPERATOR_NAMESPACE="nirmata-system"
KYVERNO_NAMESPACE="kyverno"
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

print_info "This script deploys N4K components as separate Helm releases"
print_info "This avoids the 1MB Kubernetes secret size limit for large charts"
echo ""

# Test component sizes first
echo "📏 Testing component sizes to verify they're under 1MB limit..."
echo "=============================================================="

echo "Testing admission controller only..."
ADMISSION_SIZE=$(helm template kyverno-core ./kyverno-chart/kyverno \
    --set backgroundController.enabled=false \
    --set reportsController.enabled=false \
    --set cleanupController.enabled=false \
    --set test.enabled=false \
    --set grafana.enabled=false 2>/dev/null | wc -c)

echo "Admission controller size: ${ADMISSION_SIZE} bytes"
if [ ${ADMISSION_SIZE} -lt 1048576 ]; then
    print_status "Admission controller: Under 1MB limit ✓"
else
    print_error "Admission controller: Still over 1MB limit!"
fi

echo "Testing background controller only..."
BACKGROUND_SIZE=$(helm template kyverno-background ./kyverno-chart/kyverno \
    --set admissionController.enabled=false \
    --set reportsController.enabled=false \
    --set cleanupController.enabled=false \
    --set backgroundController.enabled=true \
    --set crds.install=false \
    --set test.enabled=false \
    --set grafana.enabled=false 2>/dev/null | wc -c)

echo "Background controller size: ${BACKGROUND_SIZE} bytes"
if [ ${BACKGROUND_SIZE} -lt 1048576 ]; then
    print_status "Background controller: Under 1MB limit ✓"
else
    print_error "Background controller: Still over 1MB limit!"
fi

echo ""
echo "📋 Size Test Results:"
echo "• Admission controller: ${ADMISSION_SIZE} bytes"
echo "• Background controller: ${BACKGROUND_SIZE} bytes"
echo "• 1MB limit: 1,048,576 bytes"
echo ""

if [ ${ADMISSION_SIZE} -lt 1048576 ] && [ ${BACKGROUND_SIZE} -lt 1048576 ]; then
    print_status "Split deployment approach will work! All components under 1MB"
    echo ""
    read -p "Continue with actual deployment? (y/N): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled by user"
        exit 0
    fi
else
    print_warning "Some components are still over 1MB. Consider further optimization."
    echo ""
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled due to size concerns"
        exit 1
    fi
fi

echo ""
echo "🚀 Starting deployment..."
echo ""
