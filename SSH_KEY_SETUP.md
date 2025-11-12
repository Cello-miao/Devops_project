# SSH 私钥配置指南

## 概述

GitLab CI/CD 部署到 EC2 需要 SSH 私钥。本指南说明如何准备和配置私钥。

## 支持的格式

我们的 CI 配置支持两种私钥格式：

### 格式 1：多行格式（推荐）✅

标准的 PEM 格式，直接复制粘贴到 GitLab。

**优点**：
- 不需要预处理
- 更直观，原始格式
- 复制粘贴即可使用

**示例**：
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdef...
... （多行）...
-----END RSA PRIVATE KEY-----
```

### 格式 2：单行格式

使用 `|` 分隔符替换换行符。

**优点**：
- 在某些 GitLab UI 版本中更容易输入
- 适合脚本自动化

**示例**：
```
-----BEGIN RSA PRIVATE KEY-----|MIIEpAIBAAKCAQEA1234567890abcdef...|...|-----END RSA PRIVATE KEY-----
```

## 准备步骤

### 步骤 1：生成 SSH 密钥对（如果还没有）

```bash
# 生成新的 RSA 密钥对
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gitlab_ci_key -N ""

# 会生成两个文件：
# - ~/.ssh/gitlab_ci_key      (私钥)
# - ~/.ssh/gitlab_ci_key.pub  (公钥)
```

### 步骤 2：添加公钥到 EC2

```bash
# 将公钥复制到 EC2
ssh-copy-id -i ~/.ssh/gitlab_ci_key.pub ec2-user@YOUR_EC2_HOST

# 或手动添加
cat ~/.ssh/gitlab_ci_key.pub | ssh ec2-user@YOUR_EC2_HOST 'cat >> ~/.ssh/authorized_keys'
```

### 步骤 3：准备私钥内容

选择以下任一方法：

#### 方法 A：多行格式（推荐）

```bash
# 直接查看私钥内容
cat ~/.ssh/gitlab_ci_key

# 输出类似：
# -----BEGIN RSA PRIVATE KEY-----
# MIIEpAIBAAKCAQEA...
# ...
# -----END RSA PRIVATE KEY-----
```

**在 GitLab 中设置**：
1. 复制完整的私钥内容（包括 BEGIN 和 END 行）
2. 粘贴到 GitLab Variables 的 `SSH_PRIVATE_KEY` 字段
3. 类型选择 **Variable**（不是 File）

#### 方法 B：单行格式

```bash
# 将换行符替换为 |
cat ~/.ssh/gitlab_ci_key | tr '\n' '|'

# 输出类似：
# -----BEGIN RSA PRIVATE KEY-----|MIIEpAIBAAKCAQEA...|...|-----END RSA PRIVATE KEY-----|
```

**在 GitLab 中设置**：
1. 复制转换后的单行内容
2. 粘贴到 GitLab Variables 的 `SSH_PRIVATE_KEY` 字段
3. 类型选择 **Variable**

## GitLab CI/CD 变量配置

### 位置
GitLab 项目 → Settings → CI/CD → Variables

### 必需的变量

| 变量名 | 值 | 类型 | 保护级别 |
|--------|---|------|---------|
| `SSH_PRIVATE_KEY` | 私钥内容（多行或单行） | Variable | ✅ Masked<br>✅ Protected |
| `EC2_HOST` | EC2 IP 或域名 | Variable | - |
| `EC2_USER` | SSH 用户名 | Variable | - |
| `DB_PASSWORD` | 数据库密码 | Variable | ✅ Masked<br>✅ Protected |

### 安全设置

1. **Masked（掩码）** - 在日志中隐藏变量值
2. **Protected（保护）** - 只在受保护分支（如 main）上可用
3. **Expand variable reference（展开变量引用）** - 默认启用

## 测试 SSH 连接

在本地测试 SSH 连接：

```bash
# 使用私钥连接 EC2
ssh -i ~/.ssh/gitlab_ci_key ec2-user@YOUR_EC2_HOST

# 如果成功，应该能登录到 EC2
```

## 验证 CI 配置

### 本地模拟 CI 环境

```bash
# 测试多行格式
export SSH_PRIVATE_KEY="$(cat ~/.ssh/gitlab_ci_key)"
printf "%s\n" "$SSH_PRIVATE_KEY" > /tmp/test_key
chmod 600 /tmp/test_key
ssh -i /tmp/test_key ec2-user@YOUR_EC2_HOST "echo 'Connection successful!'"

# 测试单行格式
export SSH_PRIVATE_KEY="$(cat ~/.ssh/gitlab_ci_key | tr '\n' '|')"
echo "$SSH_PRIVATE_KEY" | tr '|' '\n' > /tmp/test_key
chmod 600 /tmp/test_key
ssh -i /tmp/test_key ec2-user@YOUR_EC2_HOST "echo 'Connection successful!'"
```

## 故障排查

### 问题 1：Permission denied (publickey)

**原因**：公钥未添加到 EC2 或私钥格式错误

**解决方案**：
```bash
# 重新添加公钥到 EC2
cat ~/.ssh/gitlab_ci_key.pub | ssh -i ~/.ssh/original_key ec2-user@YOUR_EC2_HOST 'cat >> ~/.ssh/authorized_keys'

# 验证 EC2 上的 authorized_keys
ssh ec2-user@YOUR_EC2_HOST "cat ~/.ssh/authorized_keys"
```

### 问题 2：Host key verification failed

**原因**：EC2 主机密钥未添加到 known_hosts

**解决方案**：
```bash
# 手动添加主机密钥
ssh-keyscan -H YOUR_EC2_HOST >> ~/.ssh/known_hosts
```

CI 配置已包含此步骤：
```yaml
- ssh-keyscan -H $EC2_HOST >> ~/.ssh/known_hosts 2>/dev/null || true
```

### 问题 3：私钥格式错误

**症状**：`Load key: invalid format`

**检查**：
```bash
# 验证私钥格式
openssl rsa -in ~/.ssh/gitlab_ci_key -check

# 应该输出：RSA key ok
```

**修复**：
```bash
# 转换为正确格式
openssl rsa -in ~/.ssh/gitlab_ci_key -out ~/.ssh/gitlab_ci_key_fixed
mv ~/.ssh/gitlab_ci_key_fixed ~/.ssh/gitlab_ci_key
chmod 600 ~/.ssh/gitlab_ci_key
```

### 问题 4：GitLab UI 多行输入问题

**症状**：在 GitLab Variables 中无法正确粘贴多行内容

**解决方案**：使用单行格式
```bash
cat ~/.ssh/gitlab_ci_key | tr '\n' '|'
```

## 最佳实践

1. ✅ **专用密钥** - 为 CI/CD 生成专用的 SSH 密钥对，不要使用个人密钥
2. ✅ **限制权限** - 在 EC2 的 `~/.ssh/authorized_keys` 中限制密钥权限
3. ✅ **定期轮换** - 定期更换 SSH 密钥（建议 3-6 个月）
4. ✅ **监控访问** - 监控 EC2 的 SSH 登录日志
5. ✅ **备份密钥** - 安全备份私钥（加密存储）

## 限制 SSH 密钥权限（高级）

在 EC2 的 `~/.ssh/authorized_keys` 中添加限制：

```bash
# 只允许特定命令
command="cd ~/app && docker compose -f docker-compose.prod.yml up -d" ssh-rsa AAAAB3NzaC1...

# 限制来源 IP（如果 GitLab Runner 有固定 IP）
from="1.2.3.4" ssh-rsa AAAAB3NzaC1...

# 禁止端口转发
no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAB3NzaC1...
```

## 相关文档

- [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [OpenSSH Documentation](https://www.openssh.com/manual.html)

## 支持

如有问题，请查看：
- GitLab CI/CD 日志
- EC2 系统日志：`/var/log/auth.log`（Ubuntu）或 `/var/log/secure`（Amazon Linux）
- 项目 Issues：https://gitlab.com/Cello-miao/devops/-/issues
