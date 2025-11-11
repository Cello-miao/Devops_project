# GitLab CI 配置修复

## 修复的问题

### 1. ❌ 缺少文档开始标记
**问题**: `missing document start "---"`  
**修复**: 在文件开头添加 `---`

### 2. ❌ 重复的键
**问题**: `duplication of key "stages"` 和 `duplication of key "variables"`  
**修复**: 合并重复的定义，移除第二组配置

### 3. ❌ 行太长 (> 80 字符)
**问题**: 多行超过 80 字符限制  
**修复**: 使用 YAML 多行语法拆分长行

**修复前**:
```yaml
- docker build -t "$CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHA" -f frontend/Dockerfile frontend/
```

**修复后**:
```yaml
- docker build -t "$CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHA"
  -f frontend/Dockerfile frontend/
```

### 4. ❌ 文件末尾多余空行
**问题**: `too many blank lines (1 > 0)`  
**修复**: 删除文件末尾的空行

### 5. 🔄 镜像版本更新
**修复**: 
- `hexpm/elixir:1.14.4-erlang-26.2-alpine` → `elixir:1.17-alpine`
- 使用官方 Docker Hub 镜像

## 最终配置结构

```yaml
---
stages:
  - build    # 构建 Docker 镜像
  - test     # 运行测试
  - push     # 推送镜像到 Registry
  - deploy   # 部署到生产环境

variables:
  DOCKER_DRIVER: overlay2

cache:
  paths:
    - frontend/node_modules/
    - backend/_build/
    - backend/deps/

# 4 个构建/测试任务
build_frontend, build_backend, test_frontend, test_backend

# 推送镜像 (仅 main 分支)
push_images

# 手动部署到生产环境
deploy_prod
```

## 验证结果

```bash
$ yamllint .gitlab-ci.yml
# ✅ 无错误输出
```

## 使用说明

### 在 GitLab 中配置变量

在项目 Settings > CI/CD > Variables 中添加：

| 变量名 | 描述 | 示例 |
|--------|------|------|
| `CI_REGISTRY` | Docker Registry URL | `registry.gitlab.com` |
| `CI_REGISTRY_IMAGE` | 镜像名称 | `registry.gitlab.com/user/project` |
| `CI_REGISTRY_USER` | Registry 用户名 | `gitlab-ci-token` |
| `CI_REGISTRY_PASSWORD` | Registry 密码 | `$CI_JOB_TOKEN` |

### 触发 Pipeline

```bash
# 推送代码到任意分支 - 触发 build + test
git push origin feature-branch

# 推送到 main 分支 - 触发 build + test + push
git push origin main

# 部署到生产环境 - 在 GitLab UI 手动触发 deploy_prod
```

## Pipeline 流程

```
┌─────────┐
│  Build  │  构建前端和后端 Docker 镜像
└────┬────┘
     │
┌────▼────┐
│  Test   │  运行 Elixir 测试和 Node.js 测试
└────┬────┘
     │
┌────▼────┐
│  Push   │  推送镜像到 Registry (仅 main 分支)
└────┬────┘
     │
┌────▼────┐
│ Deploy  │  部署到生产环境 (手动触发)
└─────────┘
```

## 最佳实践

✅ 所有分支都会运行 build 和 test  
✅ 只有 main 分支会 push 镜像  
✅ 部署需要手动触发，防止意外部署  
✅ 使用缓存加速依赖安装  
✅ 使用官方镜像确保兼容性  

## 文件位置

📄 `.gitlab-ci.yml` - 项目根目录
