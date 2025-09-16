#!/bin/bash

# Create GHCR imagePullSecrets for GitOps deployment
# Run this script BEFORE deploying via ArgoCD/Flux

set -e

# GHCR Configuration
GHCR_REGISTRY="ghcr.io"
GHCR_USERNAME="vikashkaushik01"
SECRET_NAME="ghcr-secret"

echo "🔐 Creating GHCR imagePullSecrets for GitOps deployment"
echo ""

# Prompt for token (more secure than hardcoding)
echo "Enter your GitHub Personal Access Token:"
read -s GHCR_TOKEN

if [ -z "$GHCR_TOKEN" ]; then
    echo "❌ Token cannot be empty!"
    exit 1
fi

echo "Enter your email address:"
read GHCR_EMAIL

if [ -z "$GHCR_EMAIL" ]; then
    echo "❌ Email cannot be empty!"
    exit 1
fi

echo ""
echo "📦 Creating secret in nirmata-system namespace..."
kubectl create secret docker-registry ${SECRET_NAME} \
  --docker-server=${GHCR_REGISTRY} \
  --docker-username=${GHCR_USERNAME} \
  --docker-password=${GHCR_TOKEN} \
  --docker-email=${GHCR_EMAIL} \
  --namespace=nirmata-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Creating secret in kyverno namespace..."
kubectl create secret docker-registry ${SECRET_NAME} \
  --docker-server=${GHCR_REGISTRY} \
  --docker-username=${GHCR_USERNAME} \
  --docker-password=${GHCR_TOKEN} \
  --docker-email=${GHCR_EMAIL} \
  --namespace=kyverno \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ GHCR imagePullSecrets created successfully!"
echo ""
echo "🔍 Verify secrets:"
echo "  kubectl get secret ${SECRET_NAME} -n nirmata-system"
echo "  kubectl get secret ${SECRET_NAME} -n kyverno"
echo ""
echo "🚀 Ready for GitOps deployment with:"
echo "  Registry: ${GHCR_REGISTRY}/${GHCR_USERNAME}"
echo "  Secret: ${SECRET_NAME}"