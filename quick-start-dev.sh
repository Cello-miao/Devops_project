#!/bin/bash

# Quick start script for development environment

echo "🚀 Starting development environment..."
echo ""

# Check if backend:dev image exists
if ! docker images | grep -q "backend.*dev"; then
    echo "❌ Backend dev image not found. Building..."
    docker build -f backend/Dockerfile.dev -t backend:dev ./backend
fi

# Check if frontend:dev image exists (optional, we can use volume mount)
echo "✅ Backend dev image ready"

# Start docker-compose
echo ""
echo "🐳 Starting services with docker-compose..."
docker-compose up

