# GitLab CI/CD Docker 版本修复

## 问题描述

GitLab CI Pipeline 失败，错误信息：
```
ERROR: Error response from daemon: client version 1.40 is too old. 
Minimum supported API version is 1.44, please upgrade your client to a newer version
```

## 根本原因

使用 `docker:stable` 和 `docker:dind` 标签时，GitLab Runner 可能拉取不同版本的镜像：
- `docker:stable` → 可能是旧版本（API 1.40）
- `docker:dind` → 可能是新版本（需要 API 1.44+）

这导致 Docker 客户端和守护进程 API 版本不匹配。

## 解决方案

### 修复前
```yaml
variables:
  DOCKER_DRIVER: overlay2

services:
  - docker:dind

build_frontend:
  stage: build
  image: docker:stable  # ❌ 版本不确定
```

### 修复后
```yaml
variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"  # ✅ 启用 TLS

services:
  - docker:27-dind  # ✅ 明确版本

build_frontend:
  stage: build
  image: docker:27  # ✅ 与 dind 版本匹配
```

## 变更清单

### 1. 更新 services
```yaml
services:
  - docker:27-dind  # 使用 Docker 27 版本
```

### 2. 添加 TLS 配置
```yaml
variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"  # Docker 18.09+ 需要
```

### 3. 更新所有 Docker 镜像引用
- `image: docker:stable` → `image: docker:27`
- 适用于所有使用 Docker 的 job：
  - `build_frontend`
  - `build_backend`
  - `push_images`

## 验证

### 本地验证
```bash
# 验证 YAML 语法
yamllint .gitlab-ci.yml

# 应该没有错误输出
```

### GitLab 验证
推送代码后，在 GitLab 中查看 Pipeline：
1. 访问: https://gitlab.com/Cello-miao/devops/-/pipelines
2. 查看最新 Pipeline 状态
3. 检查 `build_frontend` 和 `build_backend` 任务

## Docker 版本说明

### 可用的 Docker 镜像标签

| 标签 | 说明 | 推荐 |
|------|------|------|
| `docker:27` | Docker 27.x 最新版本 | ✅ 推荐（稳定） |
| `docker:27-dind` | Docker 27 with Docker-in-Docker | ✅ 推荐 |
| `docker:26` | Docker 26.x | ✅ 可用 |
| `docker:stable` | 指向最新稳定版 | ⚠️ 版本可能变化 |
| `docker:latest` | 最新版本 | ❌ 不推荐（不稳定） |
| `docker:dind` | DinD 最新版 | ⚠️ 版本可能变化 |

### API 版本兼容性

| Docker 版本 | API 版本 | 说明 |
|-------------|----------|------|
| 27.x | 1.46 | 最新稳定版 |
| 26.x | 1.45 | 支持 |
| 25.x | 1.44 | 最低要求 |
| 24.x | 1.43 | 旧版 |
| 20.x | 1.40 | ❌ 太旧 |

## 其他优化

### 1. 使用构建缓存
```yaml
build_backend:
  stage: build
  image: docker:27
  script:
    - docker build 
      --cache-from "$CI_REGISTRY_IMAGE/backend:latest"
      -t "$CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA"
      -f backend/Dockerfile backend/
```

### 2. 使用 BuildKit
```yaml
variables:
  DOCKER_BUILDKIT: 1
```

### 3. 并行构建
```yaml
build_frontend:
  parallel: 2  # 并行构建
```

### 4. 仅在特定分支构建
```yaml
build_backend:
  only:
    - main
    - dev
    - /^release-.*$/  # 匹配 release-* 分支
```

## 完整配置示例

```yaml
---
stages:
  - build
  - test
  - push
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  DOCKER_BUILDKIT: 1

services:
  - docker:27-dind

before_script:
  - docker info

build_backend:
  stage: build
  image: docker:27
  script:
    - docker build -t "$CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA"
      -f backend/Dockerfile backend/
  only:
    - main
    - dev

test_backend:
  stage: test
  image: elixir:1.17-alpine
  services:
    - postgres:15-alpine
  variables:
    POSTGRES_DB: test
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    DB_HOST: postgres
  script:
    - cd backend
    - mix local.hex --force
    - mix local.rebar --force
    - mix deps.get
    - mix test
  only:
    - main
    - dev

push_images:
  stage: push
  image: docker:27
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login
      -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY
    - docker push "$CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA"
    - docker tag "$CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA"
      "$CI_REGISTRY_IMAGE/backend:latest"
    - docker push "$CI_REGISTRY_IMAGE/backend:latest"
  only:
    - main
```

## 故障排查

### 问题 1: Docker 连接失败
```
Cannot connect to the Docker daemon
```

**解决方案**:
```yaml
variables:
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"
  DOCKER_TLS_VERIFY: 1
  DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"
```

### 问题 2: 权限问题
```
permission denied while trying to connect to the Docker daemon
```

**解决方案**: 确保 runner 有 Docker 权限，或使用 `docker:dind` service。

### 问题 3: 构建超时
```
Job timed out
```

**解决方案**: 增加超时时间
```yaml
build_backend:
  timeout: 30m
```

### 问题 4: 镜像拉取失败
```
Error pulling image
```

**解决方案**: 使用镜像缓存或私有 registry
```yaml
services:
  - name: docker:27-dind
    alias: docker
    command: ["--registry-mirror=https://mirror.gcr.io"]
```

## 监控和调试

### 查看 Docker 信息
```yaml
before_script:
  - docker version
  - docker info
  - docker --version
```

### 查看环境变量
```yaml
before_script:
  - env | sort
  - echo "Docker host: $DOCKER_HOST"
```

### 测试 Docker 连接
```yaml
script:
  - docker run hello-world
  - docker ps
```

## 相关资源

- [GitLab CI Docker Documentation](https://docs.gitlab.com/ee/ci/docker/)
- [Docker Hub - Docker Images](https://hub.docker.com/_/docker)
- [Docker API Compatibility](https://docs.docker.com/engine/api/)
- [GitLab Docker Best Practices](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html)

## 总结

✅ **修复完成**
- 使用明确的 Docker 版本（`docker:27`）
- 客户端和守护进程版本匹配
- 添加 TLS 配置
- YAML 语法正确

✅ **最佳实践**
- 始终使用具体版本号，不使用 `stable` 或 `latest`
- 确保 `image` 和 `services` 版本一致
- 启用 BuildKit 加速构建
- 使用缓存减少构建时间

🚀 **现在可以推送代码触发 Pipeline！**
