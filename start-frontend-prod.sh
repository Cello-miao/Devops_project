#!/bin/bash

echo "🛑 Stopping all existing frontend containers..."
docker stop frontend-prod-80 frontend-prod 2>/dev/null
docker rm frontend-prod-80 frontend-prod 2>/dev/null

echo ""
echo "🔨 Rebuilding frontend production image..."
docker build -f frontend/Dockerfile -t frontend:prod ./frontend

echo ""
echo "🚀 Starting production frontend with backend connection..."
docker run -d \
  --name frontend-prod \
  --network devops_project_new_default \
  -p 80:80 \
  frontend:prod

echo ""
echo "✅ Production frontend started!"
echo ""
echo "📍 Access URLs:"
echo "   Development: http://localhost:5173  (recommended for development)"
echo "   Production:  http://localhost       (port 80)"
echo ""
echo "💡 Backend API: http://localhost:4000"
echo ""
echo "🔍 Check logs:"
echo "   docker logs -f frontend-prod"
