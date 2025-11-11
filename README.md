# Sign-in Project

A full-stack web application with Vue.js frontend and Elixir/Phoenix backend, designed for containerized development and deployment.

## 📁 Project Structure

```
├── frontend/          # Vue 3 + Vite application
│   ├── src/
│   ├── Dockerfile     # Production image
│   └── Dockerfile.dev # Development image
├── backend/           # Elixir/Phoenix API
│   ├── lib/
│   ├── Dockerfile     # Production image (release)
│   └── Dockerfile.dev # Development image
├── docker-compose.yml      # Development environment
├── docker-compose.prod.yml # Production environment
├── .gitlab-ci.yml         # CI/CD pipeline
└── docs/
    ├── FRONTEND_SETUP.md
    ├── BACKEND_SETUP.md
    ├── DEPLOYMENT.md
    └── ARCHITECTURE.md
```

## 🚀 Quick Start

### Development (Docker Compose)

Start all services (PostgreSQL, backend, frontend):

```bash
docker compose up
```

Services will be available at:
- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:4000
- **PostgreSQL**: localhost:5432

### Local Development (without Docker)

#### Backend

```bash
cd backend
mix deps.get
mix ecto.setup
mix phx.server
```

#### Frontend

```bash
cd frontend
npm install
npm run dev
```

## 📖 Documentation

- **[Frontend Setup Guide](FRONTEND_SETUP.md)** - Vue/Vite development, testing, and build
- **[Backend Setup Guide](BACKEND_SETUP.md)** - Phoenix/Elixir setup, database, authentication
- **[Architecture Overview](ARCHITECTURE.md)** - System design, CI/CD, deployment strategies
- **[Deployment Guide](DEPLOYMENT.md)** - Production deployment with Docker Compose

## 🛠 Tech Stack

**Frontend**
- Vue 3
- Vite
- Vue Router
- Axios / Fetch API

**Backend**
- Elixir 1.14+
- Phoenix Framework
- PostgreSQL
- JWT authentication (Joken)
- bcrypt (password hashing)

**DevOps**
- Docker & Docker Compose
- GitLab CI/CD
- nginx (reverse proxy)

## 🧪 Testing

```bash
# Frontend tests
cd frontend
npm run test

# Backend tests
cd backend
mix test
```

## 📝 Environment Variables

Copy the template and configure:

```bash
# Development
cp .env.dev.template .env.dev

# Production
cp .env.prod.template .env.prod
```

Key variables:
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`

## 🐛 Troubleshooting

### EMFILE: too many open files (Vite)

If you encounter this error when running `npm run dev`, the `vite.config.js` has been configured with ignore patterns. If the issue persists:

```bash
# Increase file descriptor limit (temporary)
ulimit -n 65536

# Or use polling mode
CHOKIDAR_USEPOLLING=true npm run dev
```

### Backend compilation errors

```bash
cd backend
rm -rf _build deps
mix deps.get
mix compile
```

## 📄 License

[Your License Here]

## 👥 Contributors

[Your Team/Contributors]
