# ✅ 405 错误已修复

## 问题原因

前端 Vite 代理配置使用 `localhost:4000`，但在 Docker 容器中：
- 前端容器的 `localhost` 指向自己
- 无法访问后端容器
- 导致请求失败，返回 405 或连接错误

## 修复内容

### 1. frontend/vite.config.js
```javascript
proxy: {
  '/api': {
    target: process.env.VITE_API_TARGET || 'http://backend:4000',  // ✅ 使用 Docker 服务名
    changeOrigin: true,
    secure: false,
    rewrite: (path) => path
  }
}
```

### 2. docker-compose.yml
```yaml
frontend:
  environment:
    VITE_API_TARGET: http://backend:4000  # ✅ 设置环境变量
```

## 验证结果

✅ 后端从主机可访问: `http://localhost:4000`  
✅ 前端从主机可访问: `http://localhost:5173`  
✅ 前端容器可访问后端容器: `backend:4000`  
✅ API 端点工作正常: POST `/api/users/sign_in` 返回 401 (正确响应)

## 现在可以使用

打开浏览器访问: **http://localhost:5173**

尝试登录或注册：
- 注册: POST `/api/users/sign_up`
- 登录: POST `/api/users/sign_in`
- 获取用户信息: GET `/api/users/me`

所有 API 调用会正确代理到后端！

## 工作流程

```
浏览器
  ↓ 访问 http://localhost:5173
前端容器 (Vite)
  ↓ 代理 /api/* 请求
  ↓ 转发到 backend:4000
后端容器 (Phoenix)
  ↓ 处理请求
  ↓ 查询数据库 db:5432
数据库容器 (PostgreSQL)
```

🎉 **部署完成！所有服务正常运行！**
