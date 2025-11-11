#!/bin/bash

set -e

echo "🧪 Running Backend Tests in Docker"
echo ""

# 确保数据库在运行
echo "📦 Starting database..."
cd "$(dirname "$0")"
docker compose up -d db
sleep 3

echo ""
echo "🔨 Building and running tests..."
echo ""

# 运行测试容器
docker run --rm \
  --network devops_project_new_default \
  -v "$(pwd)/backend:/app" \
  -w /app \
  -e DB_HOST=db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e MIX_ENV=test \
  elixir:1.17-alpine sh -c "
    echo '📥 Installing dependencies...' && \
    apk add --no-cache build-base git postgresql-client > /dev/null 2>&1 && \
    mix local.hex --force > /dev/null 2>&1 && \
    mix local.rebar --force > /dev/null 2>&1 && \
    echo '📦 Getting mix dependencies...' && \
    mix deps.get --only test && \
    echo '🗄️  Setting up test database...' && \
    mix ecto.create --quiet && \
    mix ecto.migrate --quiet && \
    echo '' && \
    echo '✅ Running tests:' && \
    echo '-------------------' && \
    mix test \$@
  " -- "$@"

echo ""
echo "✅ Tests complete!"
