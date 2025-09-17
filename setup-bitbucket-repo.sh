#!/bin/bash

# Customer Setup Script: Mirror to Bitbucket
# This script helps customers set up their Bitbucket Helm chart repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Customer Bitbucket Setup for N4K Helm Charts${NC}"
echo "=================================================="

# Get customer's Bitbucket details
echo -e "\n${YELLOW}Please provide your Bitbucket repository details:${NC}"
read -p "Bitbucket Organization/Workspace: " CUSTOMER_ORG
read -p "Repository Name: " CUSTOMER_REPO
read -p "Bitbucket Username: " BITBUCKET_USER
read -s -p "Bitbucket App Password: " BITBUCKET_PASS
echo

# Validate inputs
if [[ -z "$CUSTOMER_ORG" || -z "$CUSTOMER_REPO" || -z "$BITBUCKET_USER" || -z "$BITBUCKET_PASS" ]]; then
    echo -e "${RED}❌ Error: All fields are required${NC}"
    exit 1
fi

BITBUCKET_URL="https://${BITBUCKET_USER}:${BITBUCKET_PASS}@bitbucket.org/${CUSTOMER_ORG}/${CUSTOMER_REPO}.git"
RAW_URL="https://bitbucket.org/${CUSTOMER_ORG}/${CUSTOMER_REPO}/raw/nova"

echo -e "\n${BLUE}📋 Configuration Summary:${NC}"
echo "Repository: https://bitbucket.org/${CUSTOMER_ORG}/${CUSTOMER_REPO}"
echo "Raw URL: ${RAW_URL}"
echo "Branch: nova (with Artifactory configuration)"

read -p "Continue with setup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo -e "\n${YELLOW}🔄 Step 1: Setting up Bitbucket remote${NC}"
if git remote get-url bitbucket >/dev/null 2>&1; then
    echo "Updating existing Bitbucket remote..."
    git remote set-url bitbucket "$BITBUCKET_URL"
else
    echo "Adding Bitbucket remote..."
    git remote add bitbucket "$BITBUCKET_URL"
fi

echo -e "\n${YELLOW}🔄 Step 2: Pushing nova branch to Bitbucket${NC}"
echo "Pushing to: ${CUSTOMER_ORG}/${CUSTOMER_REPO}"
git push bitbucket nova

echo -e "\n${YELLOW}🔍 Step 3: Verifying repository structure${NC}"
echo "Checking required files in Bitbucket..."

# Test file access
for file in "index.yaml" "kyverno-3.3.34.tgz" "nirmata-kyverno-operator-0.8.8.tgz"; do
    if curl -s -f -u "${BITBUCKET_USER}:${BITBUCKET_PASS}" "${RAW_URL}/${file}" > /dev/null; then
        echo -e "  ✅ ${file}"
    else
        echo -e "  ❌ ${file} - NOT FOUND"
    fi
done

echo -e "\n${GREEN}🎉 Setup Complete!${NC}"
echo "================================"
echo -e "\n${BLUE}�� NIRMATA CATALOG CONFIGURATION:${NC}"
echo "Name: customer-n4k-charts"
echo "Location: ${RAW_URL}/"
echo "Username: ${BITBUCKET_USER}"
echo "Password: <YOUR_BITBUCKET_APP_PASSWORD>"

echo -e "\n${BLUE}🔧 NEXT STEPS:${NC}"
echo "1. Add the chart repository in Nirmata using above details"
echo "2. Create kubernetes namespaces (nirmata-system, kyverno)"  
echo "3. Create artifactory-secret in both namespaces"
echo "4. Deploy nirmata-kyverno-operator first"
echo "5. Deploy kyverno chart"

echo -e "\n${BLUE}📖 For detailed instructions, see:${NC}"
echo "- BITBUCKET-CUSTOMER-SETUP.md"
echo "- NIRMATA-CATALOG-SETUP.md"

echo -e "\n${GREEN}✅ Your Bitbucket Helm chart repository is ready!${NC}"
