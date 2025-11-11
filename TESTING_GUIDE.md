# 测试指南

## 问题说明

在本地直接运行 `mix test` 会失败，因为：
- 数据库在 Docker 容器中 (`db:5432`)
- 本地配置指向 `localhost:5432`
- 测试需要使用 `Ecto.Adapters.SQL.Sandbox` 连接池

## 解决方案

### 方案 1：在 Docker 容器中运行测试（推荐）

#### 步骤 1：启动专用测试容器

```bash
# 创建测试容器并连接到数据库
docker run --rm -it \
  --network devops_project_new_default \
  -v $(pwd)/backend:/app \
  -w /app \
  -e DB_HOST=db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e MIX_ENV=test \
  elixir:1.17-alpine sh
```

#### 步骤 2：在容器中安装依赖并运行测试

```bash
# 安装系统依赖
apk add --no-cache build-base git postgresql-client

# 安装 Elixir 工具
mix local.hex --force
mix local.rebar --force

# 获取依赖
mix deps.get

# 创建并迁移测试数据库
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate

# 运行测试
mix test

# 运行特定测试
mix test test/signin_project_web/controllers/user_controller_test.exs

# 退出容器
exit
```

### 方案 2：使用快捷脚本

创建测试脚本 `run-tests.sh`:

```bash
#!/bin/bash

echo "🧪 Running tests in Docker container..."

# 确保数据库在运行
docker compose up -d db
sleep 2

# 运行测试容器
docker run --rm \
  --network devops_project_new_default \
  -v $(pwd)/backend:/app \
  -w /app \
  -e DB_HOST=db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e MIX_ENV=test \
  elixir:1.17-alpine sh -c "
    apk add --no-cache build-base git postgresql-client > /dev/null 2>&1 && \
    mix local.hex --force > /dev/null 2>&1 && \
    mix local.rebar --force > /dev/null 2>&1 && \
    mix deps.get && \
    mix ecto.create && \
    mix ecto.migrate && \
    mix test
  "
```

使用方法：

```bash
chmod +x run-tests.sh
./run-tests.sh
```

### 方案 3：在已运行的 backend 容器中测试（不推荐）

这会污染开发数据库：

```bash
docker compose exec backend sh -c "
  MIX_ENV=test mix ecto.create && \
  MIX_ENV=test mix ecto.migrate && \
  MIX_ENV=test mix test
"
```

**注意**：这会创建 `signin_project_test` 数据库，但容器默认使用 `dev` 环境。

### 方案 4：本地运行（需要本地 PostgreSQL）

如果你安装了本地 PostgreSQL：

```bash
cd backend

# 创建测试数据库
MIX_ENV=test mix ecto.create

# 运行迁移
MIX_ENV=test mix ecto.migrate

# 运行测试
mix test
```

## 为什么会这样？

### 配置分离

1. **开发环境** (`config/dev.exs`):
   - 使用 `DBConnection.ConnectionPool`
   - 适合长时间运行的服务器
   - 连接到 `signin_project_dev`

2. **测试环境** (`config/test.exs`):
   - 使用 `Ecto.Adapters.SQL.Sandbox`
   - 每个测试独立事务，互不影响
   - 连接到 `signin_project_test`

### Docker 网络

- 容器间通信: 使用服务名 `db`
- 主机到容器: 使用 `localhost`
- 测试需要访问 Docker 网络中的数据库

## 添加测试

### 示例：Controller 测试

创建 `test/signin_project_web/controllers/user_controller_test.exs`:

```elixir
defmodule SigninProjectWeb.UserControllerTest do
  use SigninProjectWeb.ConnCase
  
  describe "POST /api/users/sign_up" do
    test "creates user with valid data", %{conn: conn} do
      params = %{
        email: "test@example.com",
        password: "password123",
        name: "Test User"
      }
      
      conn = post(conn, ~p"/api/users/sign_up", params)
      
      assert %{"id" => _id, "email" => "test@example.com"} = json_response(conn, 200)
    end
    
    test "returns error with invalid data", %{conn: conn} do
      params = %{email: "invalid", password: "short"}
      
      conn = post(conn, ~p"/api/users/sign_up", params)
      
      assert json_response(conn, 422)
    end
  end
end
```

### 示例：Context 测试

创建 `test/signin_project/accounts_test.exs`:

```elixir
defmodule SigninProject.AccountsTest do
  use SigninProject.DataCase
  
  alias SigninProject.Accounts
  
  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{
        email: "user@example.com",
        password: "secure_password",
        name: "John Doe"
      }
      
      assert {:ok, user} = Accounts.create_user(attrs)
      assert user.email == "user@example.com"
      assert user.name == "John Doe"
    end
    
    test "returns error with invalid email" do
      attrs = %{email: "invalid", password: "password"}
      
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end
  end
end
```

## GitLab CI 中的测试

GitLab CI 会自动运行测试（已配置）：

```yaml
test_backend:
  stage: test
  image: elixir:1.17-alpine
  services:
    - postgres:15-alpine
  variables:
    DB_HOST: postgres
    DB_USER: postgres
    DB_PASSWORD: postgres
    MIX_ENV: test
  script:
    - cd backend
    - mix local.hex --force
    - mix local.rebar --force
    - mix deps.get
    - mix ecto.create
    - mix ecto.migrate
    - mix test
```

## 常见问题

### Q: 为什么不能直接在 backend 容器中运行 mix test？

A: backend 容器启动时使用 `MIX_ENV=dev`，需要重新配置才能运行测试。

### Q: 测试数据会影响开发数据库吗？

A: 不会。测试使用独立的 `signin_project_test` 数据库。

### Q: 如何快速运行单个测试？

A: 使用方案 1，在容器中运行：
```bash
mix test test/path/to/test.exs:123
```

### Q: 如何查看测试覆盖率？

A: 安装 `excoveralls` 并配置后：
```bash
MIX_ENV=test mix coveralls
```

## 最佳实践

1. ✅ 使用独立测试容器，保持环境一致性
2. ✅ 每次测试前重置数据库
3. ✅ 使用 factories 或 fixtures 创建测试数据
4. ✅ 测试应该独立，不依赖执行顺序
5. ✅ 使用描述性的测试名称
6. ✅ 测试边界情况和错误处理

## 资源

- [Elixir Testing Guide](https://hexdocs.pm/ex_unit/ExUnit.html)
- [Phoenix Testing Guide](https://hexdocs.pm/phoenix/testing.html)
- [Ecto Sandbox](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html)
