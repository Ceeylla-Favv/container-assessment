# MuchTodo – Container Assessment

This project containerizes and deploys the MuchTodo backend application using Docker, Docker Compose, Kubernetes, and Kind.

The application is a Golang backend API connected to MongoDB and deployed locally using Kubernetes.

---

# Project Overview

This assessment demonstrates:

- Docker multi-stage builds
- Docker Compose orchestration
- Kubernetes deployments
- Kubernetes services
- ConfigMaps & Secrets
- Persistent storage
- Health checks
- Ingress configuration
- Kind local Kubernetes cluster setup
- Deployment automation scripts

---

# Tech Stack

- Golang
- MongoDB
- Docker
- Docker Compose
- Kubernetes
- Kind
- NGINX Ingress Controller

---

# Architecture

LOCAL DEVELOPMENT (Docker Compose)
┌─────────────────────────────────────────┐
│  app-network (Docker bridge network)    │
│                                         │
│  ┌─────────────┐    ┌────────────────┐  │
│  │   backend   │───▶│    mongodb     │  │
│  │  :8080      │    │    :27017      │  │
│  └─────────────┘    └────────────────┘  │
│         │                  │            │
│    localhost:8080     mongo_data volume │
└─────────────────────────────────────────┘

KUBERNETES (Kind Cluster)
┌──────────────────────────────────────────────────────┐
│  Namespace: muchtodo                                 │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │  backend Deployment (2 replicas)               │  │
│  │  ┌──────────────┐  ┌──────────────┐            │  │
│  │  │  backend Pod │  │  backend Pod │            │  │
│  │  └──────┬───────┘  └──────┬───────┘            │  │
│  └─────────┼─────────────────┼────────────────────┘  │
│            └────────┬────────┘                        │
│                     ▼                                 │
│  ┌─────────────────────────────────────────────────┐ │
│  │  backend-service (NodePort :30080)              │ │
│  └─────────────────────────────┬───────────────────┘ │
│                                 │                     │
│  ┌──────────────────────────────▼──────────────────┐ │
│  │  Ingress (routes / → backend-service:8080)      │ │
│  └─────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │  mongodb Deployment (1 replica)                │  │
│  │  ┌──────────────┐                              │  │
│  │  │  mongodb Pod │◀── mongodb-pvc (1Gi storage) │  │
│  │  └──────────────┘                              │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌─────────────────────────────────────────────────┐ │
│  │  mongodb-service (ClusterIP :27017)             │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
        │
   localhost:30080 (NodePort — accessible from host)

---

# Project Structure

```bash
much-to-do/
├── Server/
│   └── MuchToDo/                  # Go application source code
│       ├── go.mod
│       ├── go.sum
│       ├── cmd/
│       │   └── api/
│       │       └── main.go        # Application entry point
│       └── internal/
│           ├── auth/
│           ├── cache/
│           ├── config/
│           ├── database/
│           ├── handlers/
│           ├── middleware/
│           ├── routes/
│           └── logger/
├── Dockerfile                     # Multi-stage Docker build
├── docker-compose.yml             # Local development setup
├── .dockerignore                  # Files excluded from Docker build
├── .env                           # Local secrets — NOT committed to git
├── .env.example                   # Placeholder template — committed to git
├── kubernetes/
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-configmap.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-deployment.yaml
│   │   └── mongodb-service.yaml
│   ├── backend/
│   │   ├── backend-secret.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-env-file-configmap.yaml
│   │   ├── backend-env-secret.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   └── ingress.yaml
├── scripts/
│   ├── docker-build.sh            # Build Docker image
│   ├── docker-run.sh              # Start with Docker Compose
│   ├── k8s-deploy.sh              # Full Kubernetes deployment
│   └── k8s-cleanup.sh            # Tear down Kubernetes resources
├── evidence/                      # Screenshots for submission
└── README.md
````

---

# Prerequisites

Ensure the following are installed:

* Docker
* kubectl
* Kind
* Go (optional for local development)

Verify installations:

```bash
docker --version
kubectl version --client
kind version
```

---

# Phase 1 — Docker Setup

# Docker Build

Build the backend image:

```bash
docker build -t backend:latest .
```

Or run the helper script:

```bash
./scripts/docker-build.sh
```

---

# Docker Compose

Start the application and MongoDB:

```bash
docker compose up -d
```

Or run:

```bash
./scripts/docker-run.sh
```

---

# Verify Docker Deployment

Check running containers:

```bash
docker ps
```

Test the backend health endpoint:

```bash
curl http://localhost:8080/health
```

Expected response:

```json
{
  "cache": "disabled",
  "database": "ok"
}
```

---

# Phase 2 — Kubernetes Deployment

# Create Kind Cluster

Create the cluster manually:

```bash
kind create cluster --name muchtodo-cluster
```

Or use the deployment script:

```bash
./scripts/k8s-deploy.sh
```

---

# Install NGINX Ingress Controller

Install ingress controller for Kind:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/kind/deploy.yaml
```

Wait for ingress controller to be ready:

```bash
kubectl get pods -n ingress-nginx -w
```

Expected:

```bash
ingress-nginx-controller-xxxxx   1/1   Running
```

---

# IMPORTANT FIX FOR KIND + INGRESS

The ingress controller deployment may remain in `Pending` state because Kind nodes do not include the required label.

Edit the ingress deployment:

```bash
kubectl edit deployment ingress-nginx-controller -n ingress-nginx
```

Remove this section:

```yaml
nodeSelector:
  ingress-ready: "true"
  kubernetes.io/os: linux
```

Save and exit.

After editing, verify the controller is running:

```bash
kubectl get pods -n ingress-nginx
```

---

# Deploy Application to Kubernetes

Run:

```bash
./scripts/k8s-deploy.sh
```

This script:

* Builds Docker image
* Loads images into Kind
* Deploys MongoDB
* Deploys backend API
* Deploys ingress resources
* Waits for pods to become ready

---

# Verify Kubernetes Resources

Check all resources:

```bash
kubectl get all -n muchtodo
```

Check ingress:

```bash
kubectl get ingress -n muchtodo
```

Check services:

```bash
kubectl get svc -n muchtodo
```

Check deployments:

```bash
kubectl get deployments -n muchtodo
```

Check pods:

```bash
kubectl get pods -n muchtodo
```

---

# Accessing the Application

## Option 1 — Access via Ingress (Recommended)

Port-forward the ingress controller:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 30080:80
```

Access the application:

```bash
http://localhost:30080/health
```

Expected response:

```json
{
  "cache": "disabled",
  "database": "ok"
}
```

---

## Option 2 — Access via Service Port Forward

Port-forward backend service directly:

```bash
kubectl port-forward svc/backend-service -n muchtodo 30080:8080
```

Then access:

```bash
http://localhost:30080/health
```

---

# Why NodePort Alone Does Not Work in Kind

Although the backend service exposes:

```yaml
nodePort: 30080
```

Kind runs Kubernetes nodes inside Docker containers.

This means NodePort ports are NOT automatically exposed to the host machine unless extra Kind networking configuration is added.

Because of this:

```bash
curl http://localhost:30080
```

will fail unless:

* ingress port-forwarding is used, OR
* backend service port-forwarding is used, OR
* Kind cluster is created with extraPortMappings

For simplicity, this project uses port-forwarding.

---

# MongoDB Persistence

MongoDB uses a PersistentVolumeClaim:

```yaml
kind: PersistentVolumeClaim
```

This ensures database data persists across pod restarts.

---

# ConfigMaps & Secrets

## ConfigMaps

Used for non-sensitive configuration:

* Application port
* Environment settings
* MongoDB configuration

## Secrets

Used for sensitive data:

* MongoDB URI
* Database credentials

---

# Health Checks

The backend deployment includes:

## Liveness Probe

Checks if the container is alive.

If it fails repeatedly, Kubernetes restarts the pod.

## Readiness Probe

Checks if the application is ready to receive traffic.

Traffic is only routed to healthy pods.

---

# Resource Limits

Backend containers include CPU and memory limits:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

This prevents resource exhaustion.

---

# Cleanup

Delete Kubernetes resources:

```bash
./scripts/k8s-cleanup.sh
```

Or manually delete cluster:

```bash
kind delete cluster --name muchtodo-cluster
```

---

# Evidence Checklist

The following screenshots were captured for submission:

* Docker build success
* Docker Compose running
* Docker application health response
* Kind cluster creation
* Kubernetes deployments running
* kubectl get all output
* kubectl get ingress output
* Application accessible via localhost

---

# Troubleshooting

## Pods stuck in ErrImageNeverPull

Cause:
Images were not loaded into Kind.

Fix:

```bash
kind load docker-image backend:latest --name muchtodo-cluster
kind load docker-image mongo:6.0 --name muchtodo-cluster
```

---

## Ingress Controller Pending

Cause:
Invalid nodeSelector for Kind.

Fix:
Remove:

```yaml
nodeSelector:
  ingress-ready: "true"
```

from ingress controller deployment.

---

## localhost:30080 not accessible

Cause:
Kind NodePort ports are not automatically exposed to host.

Fix:
Use:

```bash
kubectl port-forward
```
