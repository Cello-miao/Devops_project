# 生产环境部署指南# Deployment notes



## 自动化部署概述This repository includes a simple production deployment stack using Docker Compose

and a GitLab CI pipeline to build, test and push images.

本项目使用 GitLab CI/CD 实现全自动部署。当代码推送到 `main` 分支时，会自动执行：

Files added:

1. **Build** - 构建前端和后端 Docker 镜像

2. **Test** - 运行前端和后端测试- `docker-compose.prod.yml` — production compose file (postgres, backend, frontend, nginx proxy)

3. **Push** - 推送镜像到 GitLab Container Registry- `nginx.conf` — nginx config used by the `proxy` service. It proxies `/api` to the backend and serves the frontend via the `frontend` container.

4. **Deploy** - 自动部署到生产环境（无需手动触发）- `.env.prod.template` — environment variables template. Copy to `.env.prod` and fill before starting Compose.

- `.gitlab-ci.yml` — CI pipeline that builds images and runs tests. Customize registry and deploy steps for your environment.

## 部署文件说明

Quick start (single VM):

本仓库包含以下生产部署文件：

1. Copy the env template:

- `docker-compose.prod.yml` — 生产环境 compose 文件（使用 registry 镜像）

- `nginx.conf` — nginx 配置，代理 `/api` 到后端，服务前端静态文件```bash

- `.env.prod.template` — 环境变量模板cp .env.prod.template .env.prod

- `.gitlab-ci.yml` — CI/CD 管道配置（构建、测试、推送、自动部署）# Edit .env.prod and set real values for POSTGRES_PASSWORD, SECRET_KEY_BASE, etc.

```

## GitLab CI/CD 环境变量配置

2. Build & run:

在 GitLab 项目中配置以下变量（Settings → CI/CD → Variables）：

```bash

| 变量名 | 描述 | 是否必需 | 默认值 |docker compose -f docker-compose.prod.yml up --build -d

|--------|------|----------|--------|```

| `DB_PASSWORD_PROD` | 生产数据库密码 | 推荐 | `changeme` |

| `SECRET_KEY_BASE` | Phoenix 密钥 | 推荐 | 自动生成 |3. Visit http://<HOST> (mapped port 80). Nginx proxy forwards `/api` to the backend.

| `POSTGRES_USER` | 数据库用户名 | 可选 | `postgres` |

| `POSTGRES_DB` | 数据库名称 | 可选 | `signin_project_prod` |CI notes

| `CI_REGISTRY_USER` | Registry 用户 | 自动 | 由 GitLab 提供 |

| `CI_REGISTRY_PASSWORD` | Registry 密码 | 自动 | 由 GitLab 提供 |- The provided `.gitlab-ci.yml` builds frontend and backend Docker images, runs tests for both, and pushes images on `main`.

- Configure `CI_REGISTRY`, `CI_REGISTRY_USER`, and `CI_REGISTRY_PASSWORD` in your GitLab project variables to enable pushing.

**安全提示**：将敏感变量标记为 "Masked" 和 "Protected"

Customization

## 自动部署特性

- If your frontend Dockerfile already runs `npm run build` and serves static files via nginx inside the frontend image, the `proxy` can still be used to provide TLS/host routing.

✅ **无需手动触发** - 推送到 main 分支自动部署  - For Phoenix releases, consider replacing the `mix phx.server` command inside your backend Dockerfile with a release entrypoint and use `MIX_ENV=prod`.

✅ **使用 Registry 镜像** - 直接拉取已测试的镜像  
✅ **自动数据库迁移** - 部署时执行 `mix ecto.migrate`  
✅ **零停机更新** - 使用 Docker Compose 滚动更新  
✅ **版本标签** - 同时推送 commit SHA 和 latest 标签

## 本地手动部署（可选）

如果需要在本地或服务器上手动部署：

### 1. 准备环境变量

```bash
cp .env.prod.template .env.prod
# 编辑 .env.prod 设置真实值（数据库密码、密钥等）
```

### 2. 使用 Registry 镜像部署

```bash
# 登录 GitLab Container Registry
docker login registry.gitlab.com

# 设置镜像变量
export FRONTEND_IMAGE="registry.gitlab.com/cello-miao/devops/frontend:latest"
export BACKEND_IMAGE="registry.gitlab.com/cello-miao/devops/backend:latest"
export DB_PASSWORD_PROD="your-secure-password"
export SECRET_KEY_BASE="$(openssl rand -base64 48)"

# 拉取并启动服务
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# 执行数据库迁移
docker compose -f docker-compose.prod.yml exec backend mix ecto.migrate
```

### 3. 访问应用

- **前端**: http://localhost/ (端口 80)
- **后端 API**: http://localhost/api
- **健康检查**: http://localhost/api/health

## 部署架构

```
┌─────────────────────────────────────────────┐
│         Nginx Proxy (Port 80)               │
│  - 前端静态文件                               │
│  - 后端 API 反向代理 (/api)                  │
└─────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
┌──────────────────┐  ┌──────────────────┐
│   Frontend       │  │   Backend        │
│   (nginx:80)     │  │   (Phoenix:4000) │
└──────────────────┘  └──────────────────┘
                              │
                              ▼
                      ┌──────────────────┐
                      │   PostgreSQL     │
                      │   (Port 5432)    │
                      └──────────────────┘
```

## 监控和维护

### 查看服务状态
```bash
docker compose -f docker-compose.prod.yml ps
```

### 查看日志
```bash
# 所有服务
docker compose -f docker-compose.prod.yml logs -f

# 特定服务
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
```

### 重启服务
```bash
docker compose -f docker-compose.prod.yml restart
```

### 停止服务
```bash
docker compose -f docker-compose.prod.yml down

# 删除数据卷（谨慎！会丢失数据库数据）
docker compose -f docker-compose.prod.yml down -v
```

## 回滚操作

使用特定 commit SHA 的镜像回滚：

```bash
export FRONTEND_IMAGE="registry.gitlab.com/cello-miao/devops/frontend:OLD_COMMIT_SHA"
export BACKEND_IMAGE="registry.gitlab.com/cello-miao/devops/backend:OLD_COMMIT_SHA"

docker compose -f docker-compose.prod.yml up -d
```

## CI/CD 管道说明

GitLab CI 管道包含 4 个阶段：

1. **build** - 构建 Docker 镜像（所有分支）
2. **test** - 运行测试（所有分支）
3. **push** - 推送镜像到 registry（仅 main 分支）
4. **deploy** - 自动部署到生产环境（仅 main 分支）

查看管道状态：https://gitlab.com/Cello-miao/devops/-/pipelines

## 故障排查

### 服务无法启动
```bash
docker compose -f docker-compose.prod.yml logs
docker compose -f docker-compose.prod.yml ps -a
```

### 数据库连接失败
```bash
docker compose -f docker-compose.prod.yml exec backend sh
# 在容器内测试
mix ecto.create
```

### 镜像拉取失败
```bash
# 确保已登录
docker login registry.gitlab.com

# 手动拉取测试
docker pull registry.gitlab.com/cello-miao/devops/frontend:latest
docker pull registry.gitlab.com/cello-miao/devops/backend:latest
```

## 安全建议

1. ✅ 更改默认密码 - 设置强 `DB_PASSWORD_PROD`
2. ✅ 保护环境变量 - 在 GitLab 中标记为 Masked/Protected
3. ✅ 使用 HTTPS - 配置 SSL/TLS 证书（Nginx）
4. ✅ 限制访问 - 配置防火墙规则
5. ✅ 定期备份 - 备份 PostgreSQL 数据卷

## 生产优化建议

### Phoenix Release（推荐）

考虑使用 Phoenix release 替代 `mix phx.server`：

```dockerfile
# 在 backend/Dockerfile 中
RUN mix release
CMD ["/app/_build/prod/rel/signin_project/bin/signin_project", "start"]
```

### 数据库备份

```bash
# 备份数据库
docker compose -f docker-compose.prod.yml exec db \
  pg_dump -U postgres signin_project_prod > backup.sql

# 恢复数据库
cat backup.sql | docker compose -f docker-compose.prod.yml exec -T db \
  psql -U postgres signin_project_prod
```

## 联系支持

- **CI/CD 日志**: https://gitlab.com/Cello-miao/devops/-/pipelines
- **项目 Issues**: https://gitlab.com/Cello-miao/devops/-/issues
- **Docker 日志**: `docker compose -f docker-compose.prod.yml logs`
