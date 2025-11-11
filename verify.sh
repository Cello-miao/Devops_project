#!/bin/bash

echo "🔍 开始本地验证..."

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 计数器
PASSED=0
FAILED=0

# 函数：检查命令
check_command() {
    if eval "$1" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAILED++))
    fi
}

echo ""
echo "=== 前端检查 ==="
cd frontend
check_command "npm run lint" "前端Lint检查"
check_command "npm test" "前端单元测试"
check_command "npm run build" "前端构建"
cd ..

echo ""
echo "=== 后端检查 ==="
cd backend
check_command "mix credo suggest --strict" "后端代码质量检查"
check_command "mix format --check-formatted" "后端代码格式检查"
cd ..

echo ""
echo "=== Docker检查 ==="
check_command "docker build -f frontend/Dockerfile.dev -t frontend:dev ./frontend" "前端dev镜像构建"
check_command "docker build -f backend/Dockerfile.dev -t backend:dev ./backend" "后端dev镜像构建"

echo ""
echo "=== 验证结果 ==="
echo -e "${GREEN}通过：$PASSED${NC}"
echo -e "${RED}失败：$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！${NC}"
    exit 0
else
    echo -e "${RED}✗ 部分检查失败，请修复后重试${NC}"
    exit 1
fi
