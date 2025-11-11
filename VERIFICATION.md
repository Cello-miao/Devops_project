# 本地验证检查清单

## ✅ 前端验证

- [ ] `npm install` 成功
- [ ] `npm run lint` 通过
- [ ] `npm test` 通过
- [ ] `npm run build` 成功生成dist
- [ ] `docker build -f frontend/Dockerfile.dev` 成功
- [ ] `docker build -f frontend/Dockerfile` 成功
- [ ] 前端在 http://localhost:5173 可访问

## ✅ 后端验证

- [ ] `mix deps.get` 成功
- [ ] `mix credo suggest --strict` 通过
- [ ] `mix format --check-formatted` 通过
- [ ] `docker build -f backend/Dockerfile.dev` 成功
- [ ] `docker build -f backend/Dockerfile` 成功（多阶段构建）

## ✅ Docker Compose验证

- [ ] `docker-compose up --build` 无错误
- [ ] 前端容器运行正常
- [ ] 后端容器运行正常
- [ ] PostgreSQL容器运行正常
- [ ] 前端可访问 http://localhost:5173
- [ ] 后端API返回 http://localhost:4000/api
- [ ] 数据库连接成功

## ✅ 版本控制

- [ ] `git init` 初始化
- [ ] `.gitignore` 配置正确
- [ ] 第一次提交完成
- [ ] 提交消息清晰

## ✅ 文档

- [ ] `README.md` 完成
- [ ] `FRONTEND_SETUP.md` 完成
- [ ] `BACKEND_SETUP.md` 完成
- [ ] `ARCHITECTURE.md` 完成

## 验证日期

- 前端验证：____
- 后端验证：____
- Docker验证：____
- 所有检查完成：____