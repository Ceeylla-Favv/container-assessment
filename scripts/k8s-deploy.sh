#!/bin/bash

set -e

CLUSTER_NAME="muchtodo-cluster"
NAMESPACE="muchtodo"
PORT_FORWARD_PORT=30080

echo "============================================"
echo "Deploying MuchTodo to Kubernetes (Kind)"
echo "============================================"

# 1. Cluster setup
if kind get clusters | grep -q "$CLUSTER_NAME"; then
  echo "⚠️ Cluster exists: using $CLUSTER_NAME"
else
  echo "🔧 Creating Kind cluster..."
  kind create cluster --name "$CLUSTER_NAME"
fi


# 2. Build image
echo "🔨 Building backend image..."
docker build -t backend:latest .

echo "📥 Pulling MongoDB image..."
docker pull mongo:6.0

echo "📦 Loading images into Kind..."
kind load docker-image backend:latest --name "$CLUSTER_NAME"
kind load docker-image mongo:6.0 --name "$CLUSTER_NAME"


# 3. Apply Kubernetes resources
echo "📄 Applying manifests..."

kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml



# 4. Wait for namespace workloads

echo ""
echo "⏳ Waiting for MongoDB..."
kubectl wait --for=condition=ready pod \
  -l app=mongodb \
  -n "$NAMESPACE" \
  --timeout=180s

echo "⏳ Waiting for Backend..."
kubectl wait --for=condition=ready pod \
  -l app=backend \
  -n "$NAMESPACE" \
  --timeout=180s


# 5. Show cluster status (assessment evidence)
echo ""
echo "============================================"
echo "CLUSTER STATUS"
echo "============================================"

kubectl get all -n "$NAMESPACE"

echo ""
kubectl get ingress -n "$NAMESPACE"


# 6. Verify backend health BEFORE exposing it
echo ""
echo "⏳ Verifying backend is responding..."

# port-forward in background
kubectl port-forward svc/backend-service -n "$NAMESPACE" $PORT_FORWARD_PORT:8080 > /dev/null 2>&1 &
PF_PID=$!

sleep 5

# health check loop (reliable instead of single curl)
for i in {1..10}; do
  if curl -s http://localhost:$PORT_FORWARD_PORT/health > /dev/null; then
    echo "✅ Backend health check PASSED"
    break
  fi

  echo "⏳ Waiting for /health... ($i/10)"
  sleep 2
done


# 7. Final output
echo ""
echo "============================================"
echo "✅ DEPLOYMENT COMPLETE"
echo "============================================"

echo ""
echo "Access options:"
echo "--------------------------------------------"
echo "1) Port-forward"
echo "   kubectl port-forward svc/backend-service -n $NAMESPACE $PORT_FORWARD_PORT:8080"
echo "   http://localhost:$PORT_FORWARD_PORT/health"
echo ""
echo "2) Ingress"
echo "   kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80"
echo "   http://localhost:8081/health"
echo ""

echo "Port-forward PID: $PF_PID"