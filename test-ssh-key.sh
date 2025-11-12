#!/bin/bash
# SSH 密钥 Base64 编码测试脚本

set -e

echo "🔐 SSH 密钥 Base64 编码测试"
echo "================================"
echo

# 检查私钥文件
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "❌ 未找到 ~/.ssh/id_rsa"
    echo "请先生成 SSH 密钥对："
    echo "  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa"
    exit 1
fi

echo "✅ 找到私钥文件: ~/.ssh/id_rsa"
echo

# 1. 编码私钥
echo "步骤 1: 编码私钥为 Base64..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    SSH_KEY_BASE64=$(cat ~/.ssh/id_rsa | base64)
else
    # Linux
    SSH_KEY_BASE64=$(cat ~/.ssh/id_rsa | base64 -w 0)
fi

echo "✅ Base64 编码完成"
echo "编码长度: ${#SSH_KEY_BASE64} 字符"
echo "前 50 字符: ${SSH_KEY_BASE64:0:50}..."
echo

# 2. 测试解码
echo "步骤 2: 测试解码..."
echo "$SSH_KEY_BASE64" | base64 -d > /tmp/test_decoded_key
chmod 600 /tmp/test_decoded_key

echo "✅ 解码成功"
echo

# 3. 验证密钥格式
echo "步骤 3: 验证密钥格式..."
if ssh-keygen -l -f /tmp/test_decoded_key > /dev/null 2>&1; then
    KEY_INFO=$(ssh-keygen -l -f /tmp/test_decoded_key)
    echo "✅ 密钥格式正确"
    echo "密钥信息: $KEY_INFO"
else
    echo "❌ 密钥格式错误"
    exit 1
fi
echo

# 4. 对比原始密钥
echo "步骤 4: 对比原始密钥..."
if diff -q ~/.ssh/id_rsa /tmp/test_decoded_key > /dev/null 2>&1; then
    echo "✅ 编码/解码完全匹配"
else
    echo "❌ 编码/解码不匹配"
    exit 1
fi
echo

# 5. 测试 EC2 连接（可选）
echo "步骤 5: 测试 EC2 连接（可选）"
echo "如果你已配置 EC2，请设置环境变量："
echo "  export EC2_HOST=your-ec2-host"
echo "  export EC2_USER=ec2-user"
echo

if [ -n "$EC2_HOST" ] && [ -n "$EC2_USER" ]; then
    echo "测试连接到 $EC2_USER@$EC2_HOST..."
    if ssh -i /tmp/test_decoded_key -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        $EC2_USER@$EC2_HOST "echo 'Connection test successful!'" 2>/dev/null; then
        echo "✅ EC2 连接测试成功"
    else
        echo "⚠️  EC2 连接测试失败（请检查主机、用户名和公钥配置）"
    fi
    echo
fi

# 6. 输出 GitLab 配置指南
echo "=========================================="
echo "📋 GitLab CI/CD 变量配置"
echo "=========================================="
echo
echo "变量名: SSH_KEY_BASE64"
echo "变量值（复制以下内容到 GitLab）:"
echo "----------------------------------------"
echo "$SSH_KEY_BASE64"
echo "----------------------------------------"
echo
echo "配置步骤："
echo "1. 访问 GitLab 项目 → Settings → CI/CD → Variables"
echo "2. 点击 'Add variable'"
echo "3. Key: SSH_KEY_BASE64"
echo "4. Value: 粘贴上面的 Base64 字符串"
echo "5. 勾选: ✅ Mask variable"
echo "6. 勾选: ✅ Protect variable"
echo "7. 点击 'Add variable'"
echo

# 清理
rm -f /tmp/test_decoded_key

echo "✅ 测试完成！"
echo
echo "下一步："
echo "- 将上面的 Base64 字符串添加到 GitLab Variables"
echo "- 确保 EC2_HOST, EC2_USER, DB_PASSWORD 也已配置"
echo "- 推送代码到 main 分支触发部署"
