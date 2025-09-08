#!/bin/bash

# Script to pull, tag, and push all N4K images to GitHub Container Registry
# Target registry: ghcr.io/vikashkaushik01

GHCR_REGISTRY="ghcr.io/vikashkaushik01"

echo "🚀 Starting image migration to ${GHCR_REGISTRY}"
echo "================================================================="

# Function to pull, tag, and push an image
push_image() {
    local source_image="$1"
    local target_name="$2"
    local target_tag="$3"
    
    echo "📦 Processing: ${source_image}"
    echo "   └─ Target: ${GHCR_REGISTRY}/${target_name}:${target_tag}"
    
    # Pull the source image
    docker pull "${source_image}"
    
    # Tag for GHCR
    docker tag "${source_image}" "${GHCR_REGISTRY}/${target_name}:${target_tag}"
    
    # Push to GHCR
    docker push "${GHCR_REGISTRY}/${target_name}:${target_tag}"
    
    echo "   ✅ Success!"
    echo ""
}

# Ensure you're logged into GHCR
echo "🔐 Please ensure you're logged into GitHub Container Registry:"
echo "   docker login ghcr.io -u vikashkaushik01"
echo ""
read -p "Press Enter to continue once you're logged in..."

echo "🏗️  Processing N4K/Kyverno images..."
echo "================================="

# # N4K/Kyverno component images (9 images)
# push_image "reg.nirmata.io/nirmata/kyverno:v1.13.6-n4k.nirmata.10" "kyverno" "v1.13.6-n4k.nirmata.10"
# push_image "reg.nirmata.io/nirmata/background-controller:v1.13.6-n4k.nirmata.10" "background-controller" "v1.13.6-n4k.nirmata.10"
# push_image "reg.nirmata.io/nirmata/cleanup-controller:v1.13.6-n4k.nirmata.10" "cleanup-controller" "v1.13.6-n4k.nirmata.10"
# push_image "reg.nirmata.io/nirmata/reports-controller:v1.13.6-n4k.nirmata.10" "reports-controller" "v1.13.6-n4k.nirmata.10"
# push_image "reg.nirmata.io/nirmata/kyvernopre:v1.13.6-n4k.nirmata.10" "kyvernopre" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/kyverno-cli:v1.13.6-n4k.nirmata.10" "kyverno-cli" "v1.13.6-n4k.nirmata.10"
push_image "reg.nirmata.io/nirmata/kubectl:1.31.1" "kubectl" "1.31.1"
push_image "reg.nirmata.io/nirmata/kubectl:1.32.1" "kubectl" "1.32.1"
push_image "busybox:1.35" "busybox" "1.35"

echo "🏗️  Processing Operator images..."
echo "==============================="

# Operator component images (2 images)
push_image "ghcr.io/nirmata/nirmata-kyverno-operator:v0.4.13" "nirmata-kyverno-operator" "v0.4.13"
push_image "ghcr.io/nirmata/kubectl:1.29.1" "kubectl" "1.29.1"

echo "🎉 All images successfully pushed to ${GHCR_REGISTRY}!"
echo "================================================================="
echo ""
echo "📋 Summary - Images now available at:"
echo "   ${GHCR_REGISTRY}/kyverno:v1.13.6-n4k.nirmata.10"
echo "   ${GHCR_REGISTRY}/background-controller:v1.13.6-n4k.nirmata.10"
echo "   ${GHCR_REGISTRY}/cleanup-controller:v1.13.6-n4k.nirmata.10"
echo "   ${GHCR_REGISTRY}/reports-controller:v1.13.6-n4k.nirmata.10"
echo "   ${GHCR_REGISTRY}/kyvernopre:v1.13.6-n4k.nirmata.10"
echo "   ${GHCR_REGISTRY}/kyverno-cli:v1.13.6-n4k.nirmata.10"
echo "   ${GHCR_REGISTRY}/kubectl:1.31.1"
echo "   ${GHCR_REGISTRY}/kubectl:1.32.1"
echo "   ${GHCR_REGISTRY}/kubectl:1.29.1"
echo "   ${GHCR_REGISTRY}/busybox:1.35"
echo "   ${GHCR_REGISTRY}/nirmata-kyverno-operator:v0.4.13"
echo ""
echo "🚀 Ready for Helm deployment with custom registry!"
