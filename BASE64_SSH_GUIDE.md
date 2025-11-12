# Base64 SSH 密钥配置指南

## 概述

最新的 CI/CD 配置使用 **Base64 编码**方式处理 SSH 私钥，这是最简单可靠的方法。

## 为什么选择 Base64？

### ✅ 优点

1. **简单直接** - 单行命令即可编码/解码
2. **标准化** - Base64 是广泛使用的编码标准
3. **完整保留** - 不会丢失任何字符或格式
4. **易于复制** - 单行字符串在 GitLab UI 中容易处理
5. **无需预处理** - 解码后自动恢复原始格式

### 对比其他方法

| 方法 | 复杂度 | 可靠性 | GitLab 兼容性 | 推荐度 |
|------|--------|--------|---------------|--------|
| **Base64 编码** | ⭐ 简单 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ **推荐** |
| 多行 printf | ⭐⭐ 中等 | ⭐⭐⭐⭐ | ⭐⭐⭐ | 可选 |
| 单行 tr 替换 | ⭐⭐⭐ 复杂 | ⭐⭐⭐ | ⭐⭐⭐⭐ | 不推荐 |

## 快速开始

### 步骤 1：编码你的 SSH 私钥

```bash
# Linux 系统（使用 -w 0 禁用自动换行）
cat ~/.ssh/id_rsa | base64 -w 0

# macOS 系统（默认不换行）
cat ~/.ssh/id_rsa | base64

# 输出示例：
# LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBd...（很长的一行）
```

### 步骤 2：复制 Base64 字符串

复制完整的 Base64 输出（应该是一行很长的字符串）。

### 步骤 3：添加到 GitLab Variables

1. 访问 GitLab 项目页面
2. 进入 **Settings** → **CI/CD** → **Variables**
3. 点击 **Add variable**
4. 填写信息：
   - **Key**: `SSH_KEY_BASE64`
   - **Value**: 粘贴 Base64 字符串
   - **Type**: Variable
   - **Environment scope**: All (default)
   - **Flags**: 
     - ✅ Protect variable（只在受保护分支可用）
     - ✅ Mask variable（在日志中隐藏）
     - ✅ Expand variable reference（默认）

5. 点击 **Add variable**

### 步骤 4：验证配置

使用提供的测试脚本：

```bash
./test-ssh-key.sh
```

这个脚本会：
- ✅ 验证密钥文件存在
- ✅ 编码为 Base64
- ✅ 解码并验证
- ✅ 对比原始密钥
- ✅ 可选测试 EC2 连接
- ✅ 输出 GitLab 配置指南

## CI/CD 工作原理

在 `.gitlab-ci.yml` 中，密钥通过以下方式解码：

```yaml
before_script:
  - apk add --no-cache openssh-client
  - mkdir -p ~/.ssh
  - echo "$SSH_KEY_BASE64" | base64 -d > ~/.ssh/id_rsa
  - chmod 600 ~/.ssh/id_rsa
  - ssh-keyscan -H $EC2_HOST >> ~/.ssh/known_hosts 2>/dev/null || true
```

**工作流程**：
1. 从 GitLab Variables 读取 `$SSH_KEY_BASE64`
2. 使用 `base64 -d` 解码
3. 写入 `~/.ssh/id_rsa`
4. 设置正确的权限（600）
5. 添加 EC2 主机密钥到 known_hosts

## 本地测试

### 测试编码/解码

```bash
# 编码
SSH_KEY_BASE64=$(cat ~/.ssh/id_rsa | base64 -w 0)

# 解码
echo "$SSH_KEY_BASE64" | base64 -d > /tmp/test_key
chmod 600 /tmp/test_key

# 验证格式
ssh-keygen -l -f /tmp/test_key

# 对比原文件
diff ~/.ssh/id_rsa /tmp/test_key && echo "✅ 完全匹配"
```

### 测试 EC2 连接

```bash
# 使用解码后的密钥测试连接
ssh -i /tmp/test_key ec2-user@YOUR_EC2_HOST "echo '连接成功！'"
```

## 所需的 GitLab Variables

确保配置以下所有变量：

| 变量名 | 描述 | 示例值 | 必需 | 保护设置 |
|--------|------|--------|------|---------|
| `SSH_KEY_BASE64` | Base64 编码的私钥 | `LS0tLS1CRU...` | ✅ | Masked, Protected |
| `EC2_HOST` | EC2 公网 IP 或域名 | `ec2-1-2-3-4.compute.amazonaws.com` | ✅ | - |
| `EC2_USER` | SSH 登录用户名 | `ec2-user` 或 `ubuntu` | ✅ | - |
| `DB_PASSWORD` | 生产数据库密码 | `your-secure-password` | ✅ | Masked, Protected |

## 故障排查

### 问题 1：解码失败

**症状**：`base64: invalid input`

**原因**：Base64 字符串包含换行符

**解决方案**：
```bash
# 重新编码，确保使用 -w 0（Linux）
cat ~/.ssh/id_rsa | base64 -w 0

# 或者移除换行符
cat ~/.ssh/id_rsa | base64 | tr -d '\n'
```

### 问题 2：密钥格式错误

**症状**：`Load key: invalid format`

**检查**：
```bash
# 验证原始密钥
ssh-keygen -l -f ~/.ssh/id_rsa

# 验证解码后的密钥
echo "$SSH_KEY_BASE64" | base64 -d | ssh-keygen -l -f /dev/stdin
```

### 问题 3：权限被拒绝

**症状**：`Permission denied (publickey)`

**检查清单**：
- ✅ 公钥已添加到 EC2 的 `~/.ssh/authorized_keys`
- ✅ EC2 用户名正确（`ec2-user`, `ubuntu`, `admin` 等）
- ✅ EC2 安全组允许 SSH（端口 22）
- ✅ 密钥对匹配（私钥和公钥是一对）

**验证公钥**：
```bash
# 本地公钥指纹
ssh-keygen -l -f ~/.ssh/id_rsa.pub

# EC2 授权密钥指纹
ssh ec2-user@YOUR_EC2_HOST "ssh-keygen -l -f ~/.ssh/authorized_keys"
```

### 问题 4：GitLab Variables 未找到

**症状**：CI 日志显示 `$SSH_KEY_BASE64: not found`

**检查**：
1. 变量名拼写正确（区分大小写）
2. 变量在正确的项目中配置
3. 如果变量是 Protected，确保在 Protected 分支（main）上运行
4. 变量的 Environment scope 设置为 All 或匹配当前环境

## 安全最佳实践

1. ✅ **专用密钥对** - 为 CI/CD 创建专用的 SSH 密钥
2. ✅ **保护变量** - 启用 Masked 和 Protected 标志
3. ✅ **最小权限** - EC2 密钥只授予必要的权限
4. ✅ **定期轮换** - 每 3-6 个月更换一次密钥
5. ✅ **监控访问** - 定期检查 EC2 SSH 登录日志
6. ✅ **备份密钥** - 安全存储私钥备份

## 额外资源

### 生成新的 SSH 密钥对

```bash
# 生成 4096 位 RSA 密钥
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gitlab_ci_key -C "gitlab-ci@your-project"

# 或者使用 Ed25519（更安全，更短）
ssh-keygen -t ed25519 -f ~/.ssh/gitlab_ci_key -C "gitlab-ci@your-project"
```

### 添加公钥到 EC2

```bash
# 方法 1：使用 ssh-copy-id
ssh-copy-id -i ~/.ssh/gitlab_ci_key.pub ec2-user@YOUR_EC2_HOST

# 方法 2：手动添加
cat ~/.ssh/gitlab_ci_key.pub | ssh ec2-user@YOUR_EC2_HOST 'cat >> ~/.ssh/authorized_keys'

# 方法 3：通过 AWS Console
# 在 EC2 实例的用户数据中添加公钥
```

### 限制 SSH 密钥权限（高级）

在 EC2 的 `~/.ssh/authorized_keys` 中：

```bash
# 限制命令
command="docker compose -f ~/app/docker-compose.prod.yml up -d" ssh-rsa AAAAB3NzaC1...

# 限制源 IP
from="1.2.3.4" ssh-rsa AAAAB3NzaC1...

# 禁用转发
no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAB3NzaC1...
```

## 总结

使用 Base64 编码 SSH 私钥是：
- ✅ **最简单** - 单行命令
- ✅ **最可靠** - 标准编码，不丢失信息
- ✅ **最安全** - 配合 GitLab Protected Variables
- ✅ **最易维护** - 清晰的配置流程

按照本指南配置后，你的 CI/CD 管道将能够自动部署到 EC2！🚀
