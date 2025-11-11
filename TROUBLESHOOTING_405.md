# 405 错误修复说明

## 问题描述

前端访问 `api/users/sign_in` 时收到 **405 (Method Not Allowed)** 错误。

## 根本原因

在 Docker Compose 环境中：
- 前端容器的 Vite 代理配置使用 `http://localhost:4000` 作为目标
- 但在 Docker 网络中，前端容器的 `localhost` 指向自己，而不是后端容器
- 应该使用 Docker 服务名 `backend` 来访问后端服务

## 解决方案

### 1. 修改 Vite 配置

**文件**: `frontend/vite.config.js`

```javascript
proxy: {
  '/api': {
    // 使用环境变量，Docker 中使用服务名，本地开发使用 localhost
    target: process.env.VITE_API_TARGET || 'http://backend:4000',
    changeOrigin: true,
    secure: false,
    rewrite: (path) => path
  }
}
```

### 2. 更新 Docker Compose 配置

**文件**: `docker-compose.yml`

```yaml
frontend:
  environment:
    # 告诉 Vite 在 Docker 网络中使用 backend 服务名
    VITE_API_TARGET: http://backend:4000
```

### 3. 重启前端服务

```bash
docker compose restart frontend
```

## 验证

### 测试网络连接

```bash
# 从前端容器测试能否访问后端
docker compose exec frontend wget -O- http://backend:4000/api/
```

### 测试 API 调用

在浏览器中访问 `http://localhost:5173`，尝试登录：
- 前端发送请求到 `/api/users/sign_in`
- Vite 代理转发到 `http://backend:4000/api/users/sign_in`
- 后端正确处理 POST 请求

## 工作原理

```
┌─────────────┐                  ┌──────────────┐
│   浏览器     │                  │  前端容器     │
│ localhost   │ ────访问────>    │  (Vite)      │
│  :5173      │                  │  172.20.0.4  │
└─────────────┘                  └──────┬───────┘
                                        │
                                   代理转发
                                   /api/* →
                                   backend:4000
                                        │
                                        ▼
                                ┌──────────────┐
                                │  后端容器     │
                                │  (Phoenix)   │
                                │  172.20.0.3  │
                                │  :4000       │
                                └──────────────┘
```

### Docker 网络说明

- **服务名解析**: Docker Compose 自动为每个服务创建 DNS 记录
- **frontend** 容器可以通过 `backend` 主机名访问后端
- **backend** 容器可以通过 `db` 主机名访问数据库
- 浏览器通过 `localhost:5173` 访问前端，由 Docker 端口映射处理

## 本地开发注意事项

如果直接在主机上运行前端（不用 Docker）：

```bash
# 在 frontend 目录下
npm run dev
```

此时 `process.env.VITE_API_TARGET` 为空，会使用默认值 `http://backend:4000`。

**但这会失败**，因为主机上没有 `backend` DNS 记录。

### 解决方法 1：添加环境变量

```bash
# 临时设置
VITE_API_TARGET=http://localhost:4000 npm run dev

# 或创建 .env.local
echo "VITE_API_TARGET=http://localhost:4000" > .env.local
npm run dev
```

### 解决方法 2：修改默认值

```javascript
target: process.env.VITE_API_TARGET || 'http://localhost:4000',
```

## 其他可能的 405 错误原因

1. **CORS 预检请求未处理**
   - 后端需要处理 OPTIONS 请求
   - Phoenix 的 CORSPlug 应该自动处理

2. **HTTP 方法错误**
   - 确认前端使用 POST 方法
   - 确认后端路由定义为 `post "/users/sign_in"`

3. **路径不匹配**
   - 前端: `/api/users/sign_in`
   - 后端: `scope "/api"` + `post "/users/sign_in"`
   - 完整路径: `/api/users/sign_in` ✅

4. **Content-Type 错误**
   - 确认前端发送 `Content-Type: application/json`
   - 确认后端 API pipeline 接受 `["json"]`

## 调试命令

```bash
# 查看前端日志
docker compose logs -f frontend

# 查看后端日志
docker compose logs -f backend

# 进入前端容器
docker compose exec frontend sh

# 从前端容器测试后端连接
docker compose exec frontend wget -qO- http://backend:4000/api/

# 查看 Docker 网络
docker network inspect devops_project_new_default

# 测试从主机访问
curl -X POST http://localhost:4000/api/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 总结

✅ **修复完成**
- Vite 代理现在使用正确的后端地址 `backend:4000`
- 前端可以正常调用后端 API
- 405 错误已解决

🔍 **核心问题**
- Docker 网络隔离：容器内的 `localhost` 不是主机的 `localhost`
- 必须使用 Docker 服务名进行容器间通信

📝 **最佳实践**
- 使用环境变量配置不同环境的 API 地址
- Docker 环境使用服务名
- 本地开发使用 localhost
