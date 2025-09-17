#!/bin/bash

# Script to pull, tag, and push all N4K images to Enterprise Private Registry
# Configure the target registry URL below

set -e

# Configure your enterprise registry URL here
ENTERPRISE_REGISTRY="artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker"

echo "🚀 Starting image migration to Enterprise Registry"
echo "=================================================="
echo "Target Registry: ${ENTERPRISE_REGISTRY}"
echo ""

# Function to pull, tag, and push an image
push_image() {
    local source_image="$1"
    local target_name="$2"
    local target_tag="$3"
    
    echo "📦 Processing: ${source_image}"
    echo "   └─ Target: ${ENTERPRISE_REGISTRY}/${target_name}:${target_tag}"
    
    # Pull the source image
    docker pull "${source_image}"
    
    # Tag for enterprise registry
    docker tag "${source_image}" "${ENTERPRISE_REGISTRY}/${target_name}:${target_tag}"
    
    # Push to enterprise registry
    docker push "${ENTERPRISE_REGISTRY}/${target_name}:${target_tag}"
    
    echo "   ✅ Success!"
    echo ""
}

# Parse registry URL to get login server
REGISTRY_LOGIN=$(echo ${ENTERPRISE_REGISTRY} | cut -d'/' -f1)

# Ensure you're logged into the enterprise registry
echo "🔐 Please ensure you're logged into your Enterprise Registry:"
echo "   docker login ${REGISTRY_LOGIN}"
echo ""
read -p "Press Enter to continue once you're logged in..."

echo "🏗️  Processing N4K/Kyverno images..."
echo "================================="

# N4K/Kyverno component images (9 images)
push_image "reg.nirmata.io/nirmata/kyverno:v1.13.6-n4k.nirmata.10" "nirmata/kyverno" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/background-controller:v1.13.6-n4k.nirmata.10" "nirmata/background-controller" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/cleanup-controller:v1.13.6-n4k.nirmata.10" "nirmata/cleanup-controller" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/reports-controller:v1.13.6-n4k.nirmata.10" "nirmata/reports-controller" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/kyvernopre:v1.13.6-n4k.nirmata.10" "nirmata/kyvernopre" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/kyverno-cli:v1.13.6-n4k.nirmata.10" "nirmata/kyverno-cli" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/kubectl:1.31.1" "nirmata/kubectl" "1.31.1"
push_image "reg.nirmata.io/nirmata/kubectl:1.32.1" "nirmata/kubectl" "1.32.1"
push_image "busybox:1.35" "nirmata/busybox" "1.35"

echo "🏗️  Processing Operator images..."
echo "==============================="

# Operator component images (2 images)
push_image "ghcr.io/nirmata/nirmata-kyverno-operator:v0.4.13" "ghcr.io/nirmata/nirmata-kyverno-operator" "v0.4.13"
push_image "ghcr.io/nirmata/kubectl:1.29.1" "nirmata/kubectl" "1.29.1"

echo "🎉 All images successfully pushed to Enterprise Registry!"
echo "========================================================"
echo ""
echo "📋 Summary - Images now available at:"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/kyverno:v1.13.6-n4k.nirmata.10"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/background-controller:v1.13.6-n4k.nirmata.10"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/cleanup-controller:v1.13.6-n4k.nirmata.10"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/reports-controller:v1.13.6-n4k.nirmata.10"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/kyvernopre:v1.13.6-n4k.nirmata.10"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/kyverno-cli:v1.13.6-n4k.nirmata.10"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/kubectl:1.31.1"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/kubectl:1.32.1"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/kubectl:1.29.1"
echo "   ${ENTERPRISE_REGISTRY}/nirmata/busybox:1.35"
echo "   ${ENTERPRISE_REGISTRY}/ghcr.io/nirmata/nirmata-kyverno-operator:v0.4.13"
echo ""
echo "🚀 Ready for Helm deployment with Enterprise registry!"
