#!/bin/bash

set -e

CLUSTER_NAME="muchtodo-cluster"
NAMESPACE="muchtodo"

echo "============================================"
echo "Deploying MuchTodo to Kubernetes (Kind)"
echo "============================================"

# Step 1: Check if cluster already exists
if kind get clusters | grep -q "$CLUSTER_NAME"; then
  echo "⚠️  Cluster '$CLUSTER_NAME' already exists. Using existing cluster."
else
  echo "🔧 Creating Kind cluster..."
  kind create cluster --name "$CLUSTER_NAME"
  echo "✅ Cluster created!"
fi

# Step 2: Build the Docker image
echo ""
echo "🔨 Building Docker image..."
docker build -t backend:latest .

# Step 3: Load the image into Kind
# Kind's containers can't access your local Docker images directly
# This command copies the image into the Kind cluster
echo ""
echo "📦 Loading image into Kind cluster..."
kind load docker-image backend:latest --name "$CLUSTER_NAME"

# Step 4: Apply manifests in order
echo ""
echo "📄 Applying Kubernetes manifests..."

kubectl apply -f kubernetes/namespace.yaml
echo "  ✅ Namespace created"

kubectl apply -f kubernetes/mongodb/
echo "  ✅ MongoDB resources applied"

kubectl apply -f kubernetes/backend/
echo "  ✅ Backend resources applied"

kubectl apply -f kubernetes/ingress.yaml
echo "  ✅ Ingress applied"

# Step 5: Wait for MongoDB to be ready
echo ""
echo "⏳ Waiting for MongoDB pod to be ready (this may take a minute)..."
kubectl wait --for=condition=ready pod \
  -l app=mongodb \
  -n "$NAMESPACE" \
  --timeout=120s

# Step 6: Wait for backend to be ready
echo ""
echo "⏳ Waiting for backend pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=backend \
  -n "$NAMESPACE" \
  --timeout=120s

# Step 7: Show status
echo ""
echo "============================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "============================================"
echo ""
echo "📋 All resources in namespace '$NAMESPACE':"
kubectl get all -n "$NAMESPACE"

echo ""
echo "🌐 Access your app at: http://localhost:30080"
echo "🔍 Health check:       http://localhost:30080/health"