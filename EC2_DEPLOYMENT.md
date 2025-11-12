# EC2 部署配置指南

## 概述

本项目配置了自动部署到 AWS EC2 的 GitLab CI/CD 流程。当代码推送到 `main` 分支时，会自动：

1. 构建 Docker 镜像
2. 运行测试
3. 推送镜像到 GitLab Container Registry
4. 通过 SSH 部署到 EC2 服务器

## 必需的 GitLab CI/CD 变量

在 GitLab 项目中配置以下变量（Settings → CI/CD → Variables）：

### SSH 连接配置

| 变量名 | 描述 | 示例值 | 类型 |
|--------|------|--------|------|
| `SSH_PRIVATE_KEY` | EC2 私钥内容 | `-----BEGIN RSA PRIVATE KEY-----\n...` | File |
| `EC2_HOST` | EC2 公网 IP 或域名 | `ec2-xx-xx-xx-xx.compute.amazonaws.com` | Variable |
| `EC2_USER` | SSH 登录用户名 | `ec2-user` 或 `ubuntu` | Variable |

### 数据库配置

| 变量名 | 描述 | 示例值 | 类型 |
|--------|------|--------|------|
| `DB_PASSWORD` | 生产数据库密码 | `your-secure-password` | Variable (Masked) |

### Registry 配置（GitLab 自动提供）

| 变量名 | 描述 | 自动提供 |
|--------|------|---------|
| `CI_REGISTRY` | Registry 地址 | ✅ |
| `CI_REGISTRY_USER` | Registry 用户 | ✅ |
| `CI_REGISTRY_PASSWORD` | Registry 密码 | ✅ |
| `CI_REGISTRY_IMAGE` | 镜像路径 | ✅ |
| `CI_COMMIT_SHA` | Commit SHA | ✅ |

## EC2 服务器准备

### 1. 安装 Docker 和 Docker Compose

```bash
# 对于 Amazon Linux 2023 / Amazon Linux 2
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 对于 Ubuntu
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### 2. 创建应用目录

```bash
mkdir -p ~/app
```

### 3. 配置安全组

确保 EC2 安全组开放以下端口：

- **22** - SSH（仅限 GitLab Runner IP 或你的 IP）
- **80** - HTTP（前端访问）
- **4000** - Phoenix 后端（可选，用于直接访问 API）

### 4. 配置 SSH 密钥

```bash
# 在本地生成密钥对（如果还没有）
ssh-keygen -t rsa -b 4096 -C "gitlab-ci@your-project"

# 将公钥添加到 EC2
cat ~/.ssh/id_rsa.pub | ssh ec2-user@YOUR_EC2_HOST 'cat >> ~/.ssh/authorized_keys'

# 将私钥内容添加到 GitLab CI/CD 变量 SSH_PRIVATE_KEY
cat ~/.ssh/id_rsa
```

## 部署流程

### 自动部署（推荐）

推送到 `main` 分支即可自动触发部署：

```bash
git push origin main
```

### 查看部署状态

访问 GitLab CI/CD 管道页面：
```
https://gitlab.com/Cello-miao/devops/-/pipelines
```

### 部署步骤说明

GitLab CI 会执行以下步骤：

1. **上传 docker-compose.prod.yml** - SCP 传输到 EC2
2. **配置环境变量** - 设置镜像标签和数据库密码
3. **登录 Docker Registry** - 使用 GitLab token
4. **拉取最新镜像** - 从 registry 拉取已测试的镜像
5. **启动服务** - 使用 docker compose up -d
6. **等待服务启动** - 10 秒延迟
7. **运行数据库迁移** - mix ecto.migrate
8. **验证部署** - 显示容器状态

## 手动部署到 EC2

如果需要手动部署：

```bash
# 1. 登录 EC2
ssh ec2-user@YOUR_EC2_HOST

# 2. 登录 GitLab Registry
docker login registry.gitlab.com

# 3. 拉取镜像
cd ~/app
export FRONTEND_IMAGE="registry.gitlab.com/cello-miao/devops/frontend:latest"
export BACKEND_IMAGE="registry.gitlab.com/cello-miao/devops/backend:latest"
export DB_PASSWORD="your-password"
export POSTGRES_PASSWORD="your-password"

docker compose -f docker-compose.prod.yml pull

# 4. 启动服务
docker compose -f docker-compose.prod.yml up -d

# 5. 运行迁移
docker compose -f docker-compose.prod.yml exec backend mix ecto.migrate

# 6. 查看状态
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f
```

## 访问应用

部署完成后，访问：

- **前端**: `http://YOUR_EC2_HOST/`
- **后端 API**: `http://YOUR_EC2_HOST:4000/api/health`
- **健康检查**: `http://YOUR_EC2_HOST:4000/api/health`

## 监控和维护

### 查看日志

```bash
ssh ec2-user@YOUR_EC2_HOST
cd ~/app
docker compose -f docker-compose.prod.yml logs -f
```

### 重启服务

```bash
ssh ec2-user@YOUR_EC2_HOST
cd ~/app
docker compose -f docker-compose.prod.yml restart
```

### 停止服务

```bash
ssh ec2-user@YOUR_EC2_HOST
cd ~/app
docker compose -f docker-compose.prod.yml down
```

### 查看容器状态

```bash
ssh ec2-user@YOUR_EC2_HOST
cd ~/app
docker compose -f docker-compose.prod.yml ps
docker stats
```

## 故障排查

### SSH 连接失败

```bash
# 测试 SSH 连接
ssh -vvv ec2-user@YOUR_EC2_HOST

# 检查密钥权限
chmod 600 ~/.ssh/id_rsa

# 检查 EC2 安全组是否开放 22 端口
```

### Docker 拉取镜像失败

```bash
# 在 EC2 上手动测试
docker login registry.gitlab.com
docker pull registry.gitlab.com/cello-miao/devops/frontend:latest
```

### 容器启动失败

```bash
# 查看详细日志
ssh ec2-user@YOUR_EC2_HOST
cd ~/app
docker compose -f docker-compose.prod.yml logs backend
docker compose -f docker-compose.prod.yml logs frontend
docker compose -f docker-compose.prod.yml logs db
```

### 数据库连接失败

```bash
# 检查环境变量
ssh ec2-user@YOUR_EC2_HOST "cd ~/app && docker compose -f docker-compose.prod.yml config"

# 进入 backend 容器测试
docker compose -f docker-compose.prod.yml exec backend sh
# 在容器内
env | grep DB
```

## 回滚

使用特定版本的镜像回滚：

```bash
ssh ec2-user@YOUR_EC2_HOST
cd ~/app

export FRONTEND_IMAGE="registry.gitlab.com/cello-miao/devops/frontend:OLD_COMMIT_SHA"
export BACKEND_IMAGE="registry.gitlab.com/cello-miao/devops/backend:OLD_COMMIT_SHA"

docker compose -f docker-compose.prod.yml up -d
```

## 安全最佳实践

1. ✅ **限制 SSH 访问** - 只允许 GitLab Runner 和管理员 IP
2. ✅ **使用强密码** - 数据库密码至少 16 字符
3. ✅ **保护私钥** - SSH_PRIVATE_KEY 标记为 Masked 和 Protected
4. ✅ **定期更新** - 保持 Docker 和系统更新
5. ✅ **配置 HTTPS** - 使用 Let's Encrypt 证书
6. ✅ **定期备份** - 备份数据库和应用数据

## 性能优化

### 启用 Docker 日志轮转

```bash
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### 配置资源限制

在 `docker-compose.prod.yml` 中添加：

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

## 联系支持

- **CI/CD 管道**: https://gitlab.com/Cello-miao/devops/-/pipelines
- **项目 Issues**: https://gitlab.com/Cello-miao/devops/-/issues
- **EC2 文档**: https://docs.aws.amazon.com/ec2/
