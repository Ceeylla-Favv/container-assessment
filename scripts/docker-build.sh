#!/bin/bash

# Exit immediately if any command fails
set -e

echo "============================================"
echo "Building Docker image for backend..."
echo "============================================"

# Build the image and tag it as backend:latest
docker build -t backend:latest .

echo ""
echo "✅ Build successful!"
echo ""
echo "Image details:"
docker images backend:latest