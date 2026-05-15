#!/bin/bash

set -e

echo "============================================"
echo "Starting application with Docker Compose..."
echo "============================================"

# --build forces a rebuild of images
# -d runs in background (detached mode)
docker compose up --build -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

echo ""
echo "📋 Running containers:"
docker compose ps

echo ""
echo "🔍 Testing health endpoint..."
curl -f http://localhost:8080/health && echo "" && echo "✅ App is healthy!" || echo "❌ Health check failed"

echo ""
echo "📜 To view logs run: docker compose logs -f"
echo "🛑 To stop run: docker compose down"