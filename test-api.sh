#!/bin/bash

echo "🧪 Testing API connectivity..."
echo ""

# Test 1: Backend health
echo "1️⃣ Testing backend health from host:"
curl -s http://localhost:4000/api/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Backend is accessible from host"
else
    echo "   ❌ Backend is NOT accessible from host"
fi

# Test 2: Frontend to backend connectivity
echo ""
echo "2️⃣ Testing frontend → backend connectivity:"
docker compose exec -T frontend wget -qO- http://backend:4000/api/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Frontend can reach backend via Docker network"
else
    echo "   ❌ Frontend CANNOT reach backend"
fi

# Test 3: Check if services are running
echo ""
echo "3️⃣ Checking service status:"
docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"

# Test 4: Test sign_in endpoint
echo ""
echo "4️⃣ Testing POST /api/users/sign_in:"
response=$(curl -s -X POST http://localhost:4000/api/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  -w "\n%{http_code}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ] || [ "$http_code" = "401" ] || [ "$http_code" = "422" ]; then
    echo "   ✅ Endpoint responds correctly (HTTP $http_code)"
    echo "   Response: $(echo $body | head -c 100)..."
elif [ "$http_code" = "405" ]; then
    echo "   ❌ Method Not Allowed (HTTP 405)"
    echo "   This means the endpoint doesn't accept POST requests"
else
    echo "   ⚠️  Unexpected response (HTTP $http_code)"
    echo "   Response: $body"
fi

echo ""
echo "📊 Test complete!"
echo ""
echo "💡 To view logs:"
echo "   docker compose logs -f frontend"
echo "   docker compose logs -f backend"
