# Backend Setup Guide

This guide covers setup, development, testing, and deployment of the Elixir/Phoenix backend.

## Prerequisites

- Elixir 1.14+ and Erlang/OTP 26+
- PostgreSQL 13+
- Docker (optional, for containerized dev)

## Installation

### Local Setup

```bash
cd backend

# Install Hex package manager
mix local.hex --force

# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# This runs:
# - mix ecto.create (create DB)
# - mix ecto.migrate (run migrations)
# - mix run priv/repo/seeds.exs (seed data)
```

### Docker Setup

```bash
docker compose up backend
```

## Development

### Running the Server

```bash
mix phx.server
```

The API server starts on http://localhost:4000.

### Interactive Shell

```bash
iex -S mix phx.server
```

### Project Structure

```
backend/
├── lib/
│   ├── signin_project/         # Business logic
│   │   ├── accounts/           # User accounts context
│   │   ├── repo.ex             # Ecto repository
│   │   └── ...
│   ├── signin_project_web/     # Web layer
│   │   ├── controllers/        # API controllers
│   │   ├── router.ex           # Route definitions
│   │   ├── endpoint.ex         # HTTP endpoint
│   │   └── gettext.ex          # Internationalization
│   └── signin_project.ex       # Application module
├── priv/
│   ├── repo/migrations/        # Database migrations
│   └── static/                 # Static assets
├── test/                       # Test files
├── config/                     # Configuration
├── mix.exs                     # Project definition
└── Dockerfile                  # Production image
```

## Database

### Create Migration

```bash
mix ecto.gen.migration create_users
```

Edit the migration file in `priv/repo/migrations/`, then run:

```bash
mix ecto.migrate
```

### Rollback

```bash
mix ecto.rollback
```

### Reset Database

```bash
mix ecto.reset
```

## Authentication

This project uses JWT (JSON Web Tokens) for authentication:

- **Library**: Joken
- **Password Hashing**: bcrypt_elixir

### Generate Secret Key

```bash
mix phx.gen.secret
```

Add to `config/runtime.exs` or `.env.prod`:

```elixir
config :signin_project, SigninProjectWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")
```

## API Endpoints

Example routes (see `lib/signin_project_web/router.ex`):

```
POST   /api/users/register      # Register new user
POST   /api/users/sign_in       # Sign in (get JWT)
GET    /api/users/me            # Get current user (requires auth)
```

## Testing

```bash
# Run all tests
mix test

# Run specific test file
mix test test/signin_project_web/controllers/user_controller_test.exs

# Run with coverage
mix test --cover
```

## Code Quality

### Format Code

```bash
mix format
```

### Static Analysis (optional)

```bash
# Install Credo
mix deps.get

# Run Credo
mix credo
```

## CORS Configuration

The backend uses `cors_plug` to handle Cross-Origin Resource Sharing.

Configuration in `lib/signin_project_web/endpoint.ex`:

```elixir
plug CORSPlug,
  origin: ["http://localhost:5173"],  # Frontend dev server
  methods: ["GET", "POST", "PUT", "DELETE"],
  headers: ["Authorization", "Content-Type"]
```

For production, update `origin` to your frontend domain.

## Docker

### Development Image

```bash
docker build -f Dockerfile.dev -t backend-dev .
docker run -p 4000:4000 -e DATABASE_URL=postgres://user:pass@db:5432/myapp backend-dev
```

### Production Image (Release)

```bash
docker build -t backend-prod .
docker run -p 4000:4000 -e SECRET_KEY_BASE=... -e DATABASE_URL=... backend-prod
```

The production Dockerfile builds an Elixir release for optimal performance.

## Environment Variables

Required environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:pass@localhost/db` |
| `SECRET_KEY_BASE` | Phoenix secret (64+ chars) | Generate with `mix phx.gen.secret` |
| `PORT` | HTTP port | `4000` |
| `PHX_HOST` | Public hostname | `example.com` |
| `MIX_ENV` | Environment | `dev`, `test`, `prod` |

## Common Issues

### Port Already in Use

```bash
# Kill process on port 4000
lsof -ti:4000 | xargs kill -9
```

### Database Connection Error

Check PostgreSQL is running:

```bash
# macOS
brew services start postgresql

# Linux
sudo systemctl start postgresql

# Docker
docker compose up db
```

### Compilation Errors

```bash
# Clean build artifacts
mix clean

# Remove dependencies and reinstall
rm -rf _build deps
mix deps.get
mix compile
```

### expo_po_parser Error

If you see "module :expo_po_parser is not available":

```bash
rm -f ~/.hex/cache.ets
mix deps.clean expo --all
mix deps.get
mix deps.compile expo
mix compile
```

## Production Release

Build a production release:

```bash
MIX_ENV=prod mix release
```

Run the release:

```bash
_build/prod/rel/signin_project/bin/signin_project start
```

## Deployment

See [DEPLOYMENT.md](../DEPLOYMENT.md) for production deployment with Docker Compose and CI/CD.

## Resources

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir Documentation](https://elixir-lang.org/)
- [Ecto Documentation](https://hexdocs.pm/ecto/)
- [Joken (JWT)](https://hexdocs.pm/joken/)
