# 🚀 快速命令参考

## 启动/停止服务

```bash
# 启动所有服务（后台）
docker compose up -d

# 启动并查看日志
docker compose up

# 停止所有服务
docker compose down

# 停止并删除数据
docker compose down -v

# 重启特定服务
docker compose restart backend
docker compose restart frontend
```

## 查看状态和日志

```bash
# 查看服务状态
docker compose ps

# 查看所有日志
docker compose logs

# 实时跟踪日志
docker compose logs -f

# 查看特定服务日志
docker compose logs backend
docker compose logs frontend
docker compose logs -f backend
```

## 进入容器

```bash
# 进入后端容器
docker compose exec backend sh

# 进入前端容器
docker compose exec frontend sh

# 进入数据库
docker compose exec db psql -U postgres -d signin_project_dev
```

## 数据库操作

```bash
# 运行迁移
docker compose exec backend mix ecto.migrate

# 回滚迁移
docker compose exec backend mix ecto.rollback

# 重置数据库
docker compose exec backend mix ecto.reset

# 创建迁移
docker compose exec backend mix ecto.gen.migration migration_name

# 查看迁移状态
docker compose exec backend mix ecto.migrations
```

## 代码质量检查

```bash
# 后端 Credo 检查
docker compose exec backend mix credo
docker compose exec backend mix credo --strict

# 后端格式化
docker compose exec backend mix format
docker compose exec backend mix format --check-formatted

# 前端 ESLint 检查
docker compose exec frontend npm run lint
```

## 运行测试

```bash
# 使用测试脚本（推荐）
./run-tests.sh

# 运行特定测试文件
./run-tests.sh test/signin_project_web/controllers/user_controller_test.exs

# 运行特定测试行
./run-tests.sh test/path/to/test.exs:123

# 查看详细输出
./run-tests.sh --trace
```

## 构建镜像

```bash
# 构建所有镜像
docker compose build

# 构建特定镜像
docker compose build backend
docker compose build frontend

# 强制重新构建（不使用缓存）
docker compose build --no-cache backend

# 构建生产镜像
docker build -f backend/Dockerfile -t backend:prod ./backend
docker build -f frontend/Dockerfile -t frontend:prod ./frontend
```

## 前端开发

```bash
# 安装新依赖
docker compose exec frontend npm install package-name

# 更新依赖
docker compose exec frontend npm update

# 构建生产版本
docker compose exec frontend npm run build
```

## 后端开发

```bash
# 安装新依赖
docker compose exec backend mix deps.get

# 编译
docker compose exec backend mix compile

# 启动 IEx 控制台
docker compose exec backend iex -S mix

# 生成新的 Controller
docker compose exec backend mix phx.gen.json Context Schema schemas field:type

# 生成新的迁移
docker compose exec backend mix ecto.gen.migration create_table_name
```

## API 测试

```bash
# 测试注册
curl -X POST http://localhost:4000/api/users/sign_up \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# 测试登录
curl -X POST http://localhost:4000/api/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# 测试获取用户信息（需要 token）
curl -X GET http://localhost:4000/api/users/me \
  -H "x-xsrf-token: YOUR_TOKEN_HERE"

# 列出所有技能
curl http://localhost:4000/api/skills

# 列出所有任务
curl http://localhost:4000/api/tasks
```

## 访问应用

```bash
# 前端（开发）
open http://localhost:5173

# 后端 API
open http://localhost:4000

# 或使用 curl 测试
curl http://localhost:5173
curl http://localhost:4000/api/
```

## 清理

```bash
# 删除所有停止的容器
docker compose rm

# 删除未使用的镜像
docker image prune

# 删除未使用的卷
docker volume prune

# 完全清理项目
docker compose down -v
docker image rm devops_project_new-backend devops_project_new-frontend
```

## 故障排查

```bash
# 检查容器健康状态
docker compose ps

# 查看容器详细信息
docker compose logs backend --tail=50
docker compose logs backend --since=5m

# 检查网络连接
docker compose exec frontend ping backend
docker compose exec backend ping db

# 检查端口占用
docker compose exec backend netstat -tlnp
docker compose exec frontend netstat -tlnp

# 重新构建并启动
docker compose down
docker compose build
docker compose up
```

## Git 操作

```bash
# 查看状态
git status

# 提交更改
git add .
git commit -m "Your commit message"

# 推送到远程
git push origin master

# 拉取最新代码
git pull origin master

# 创建新分支
git checkout -b feature-name

# 合并分支
git checkout master
git merge feature-name
```

## 生产部署

```bash
# 1. 复制环境变量模板
cp .env.prod.template .env.prod

# 2. 编辑生产配置
nano .env.prod

# 3. 构建生产镜像
docker build -f backend/Dockerfile -t backend:prod ./backend
docker build -f frontend/Dockerfile -t frontend:prod ./frontend

# 4. 启动生产环境
docker compose -f docker-compose.prod.yml up -d

# 5. 查看生产日志
docker compose -f docker-compose.prod.yml logs -f
```

## 环境变量

```bash
# 开发环境
export DB_HOST=db
export DB_USER=postgres
export DB_PASSWORD=postgres
export MIX_ENV=dev

# 测试环境
export MIX_ENV=test

# 生产环境（从 .env.prod 加载）
source .env.prod
```

## 有用的别名

添加到 `~/.bashrc` 或 `~/.zshrc`:

```bash
# Docker Compose 简写
alias dc='docker compose'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcp='docker compose ps'

# 项目特定
alias backend='docker compose exec backend'
alias frontend='docker compose exec frontend'
alias db='docker compose exec db psql -U postgres -d signin_project_dev'

# 测试
alias test='./run-tests.sh'

# 代码质量
alias credo='docker compose exec backend mix credo'
alias format='docker compose exec backend mix format'
alias lint='docker compose exec frontend npm run lint'
```

## 监控资源使用

```bash
# 查看容器资源使用
docker stats

# 查看特定容器
docker stats devops_project_new-backend-1

# 查看磁盘使用
docker system df

# 查看网络
docker network ls
docker network inspect devops_project_new_default
```

## 备份和恢复

```bash
# 备份数据库
docker compose exec db pg_dump -U postgres signin_project_dev > backup.sql

# 恢复数据库
docker compose exec -T db psql -U postgres -d signin_project_dev < backup.sql

# 导出 Docker 卷
docker run --rm -v devops_project_new_db_data_dev:/data -v $(pwd):/backup alpine tar czf /backup/db-backup.tar.gz -C /data .

# 导入 Docker 卷
docker run --rm -v devops_project_new_db_data_dev:/data -v $(pwd):/backup alpine tar xzf /backup/db-backup.tar.gz -C /data
```

## 性能分析

```bash
# Phoenix 开发工具
# 访问: http://localhost:4000/dev/dashboard

# 查看 Elixir 观察器
docker compose exec backend iex -S mix
# 在 iex 中运行: :observer.start()

# 前端构建分析
docker compose exec frontend npm run build -- --debug
```

---

**更多命令请参考各个文档：**
- `TESTING_GUIDE.md` - 测试详细指南
- `DEPLOYMENT.md` - 部署指南
- `TROUBLESHOOTING_405.md` - 故障排查
- `FINAL_REPORT.md` - 完整项目报告
