#!/bin/bash

# =============================================================================
# setup.sh — Kubernetes setup script for my-app
# Usage: bash setup.sh
# Requirements: Docker Desktop, minikube, kubectl must be installed
# =============================================================================

set -e  # stop the script immediately if any command fails

echo "================================================"
echo " my-app Kubernetes Setup"
echo "================================================"

# -----------------------------------------------------------------------------
# Step 1: Start minikube
# -----------------------------------------------------------------------------
echo ""
echo "[1/6] Starting minikube..."
minikube start

# -----------------------------------------------------------------------------
# Step 2: Point Docker CLI to minikube's internal Docker daemon
#         This means images you build will be available inside minikube
# -----------------------------------------------------------------------------
echo ""
echo "[2/6] Configuring Docker to use minikube's registry..."
eval $(minikube docker-env)

# -----------------------------------------------------------------------------
# Step 3: Build the Docker image inside minikube's environment
# -----------------------------------------------------------------------------
echo ""
echo "[3/6] Building Docker image: my-app:latest..."
docker build -t my-app:latest .

# -----------------------------------------------------------------------------
# Step 4: Apply Kubernetes manifests (deployment + service)
# -----------------------------------------------------------------------------
echo ""
echo "[4/6] Applying Kubernetes manifests from k8s/ folder..."
kubectl apply -f k8s/

# -----------------------------------------------------------------------------
# Step 5: Wait for pods to be ready
#         --timeout=90s means wait up to 90 seconds before giving up
# -----------------------------------------------------------------------------
echo ""
echo "[5/6] Waiting for pods to become ready..."
kubectl rollout status deployment/my-app --timeout=90s

# -----------------------------------------------------------------------------
# Step 6: Print pod and service status, then open the app URL
# -----------------------------------------------------------------------------
echo ""
echo "[6/6] Deployment complete. Here is the current status:"
echo ""
echo "--- Pods ---"
kubectl get pods

echo ""
echo "--- Services ---"
kubectl get services

echo ""
echo "--- App URL ---"
minikube service my-app-service --url

echo ""
echo "================================================"
echo " Setup finished! Use the URL above to test."
echo " Tip: run 'kubectl get pods' anytime to check"
echo " the status of your running containers."
echo "================================================"
