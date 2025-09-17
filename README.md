# N4K Helm Chart Repository

## Overview
This repository contains Helm charts for N4K (Kyverno) and Nirmata Kyverno Operator deployment.

## Available Charts

### nirmata-kyverno-operator (v0.8.8)
Enterprise Kyverno Operator for managing Kyverno installations.

### kyverno (v3.3.34)  
Complete N4K deployment with all controllers and components.

## Usage

Add this repository to Helm:
```bash
helm repo add n4k-charts https://raw.githubusercontent.com/nirmata/n4k-deploy/[BRANCH]/
helm repo update
```

Install operator first:
```bash
helm install operator n4k-charts/nirmata-kyverno-operator -n nirmata-system --create-namespace
```

Install kyverno:
```bash
helm install kyverno n4k-charts/kyverno -n kyverno --create-namespace
```

## Configuration

### Main Branch
- Registry: `ghcr.io/vikashkaushik01`
- Image Pull Secret: `ghcr-secret`

### Nova Branch  
- Registry: `artifactory.f1.novartis.net/to-ddi-diu-zephyr-docker/nirmata`
- Image Pull Secret: `artifactory-secret`

## Prerequisites

Create appropriate image pull secrets in both namespaces before deployment.
