#!/bin/bash

CLUSTER_NAME="muchtodo-cluster"

echo "============================================"
echo "Cleaning up Kubernetes resources..."
echo "============================================"

echo "🗑️  Deleting Kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME"

echo ""
echo "✅ Cleanup complete! All Kubernetes resources removed."
echo "ℹ️  Docker images are still on your machine."
echo "    To remove them run: docker rmi backend:latest"