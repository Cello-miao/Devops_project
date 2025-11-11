# Architecture & CI/CD Documentation

This document describes the system architecture, technology stack, deployment strategy, and CI/CD pipeline.

## 🏗 System Architecture

### Overview

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Client    │──────▶│    nginx    │──────▶│   Backend   │
│  (Browser)  │      │   (Proxy)   │      │  (Phoenix)  │
└─────────────┘      └─────────────┘      └──────┬──────┘
                            │                     │
                            │                     ▼
                            │              ┌─────────────┐
                            │              │  PostgreSQL │
                            ▼              └─────────────┘
                     ┌─────────────┐
                     │  Frontend   │
                     │   (Vue)     │
                     └─────────────┘
```

### Components

#### Frontend (Vue 3 + Vite)
- **Framework**: Vue 3 with Composition API
- **Build Tool**: Vite (fast HMR, optimized production builds)
- **Router**: Vue Router 4
- **HTTP Client**: Axios or Fetch API
- **Deployment**: Static files served by nginx

#### Backend (Elixir + Phoenix)
- **Framework**: Phoenix (Elixir web framework)
- **Language**: Elixir (functional, concurrent, fault-tolerant)
- **Database**: PostgreSQL with Ecto ORM
- **Authentication**: JWT (Joken) + bcrypt password hashing
- **API**: RESTful JSON API
- **Deployment**: Elixir release (OTP application)

#### Database (PostgreSQL)
- **Version**: PostgreSQL 15
- **ORM**: Ecto (Elixir database wrapper)
- **Migrations**: Version-controlled with `mix ecto.migrate`

#### Reverse Proxy (nginx)
- **Routes**:
  - `/api/*` → Backend (port 4000)
  - `/*` → Frontend static files (port 80)
- **Features**: Load balancing, TLS termination (in production with SSL), compression

## 🔄 Environments

### Development

**Setup**: `docker-compose.yml`

Services:
- **db**: PostgreSQL 15 (port 5432)
- **backend**: Phoenix dev server with hot reload (port 4000)
- **frontend**: Vite dev server with HMR (port 5173)

**Volumes**: Source code mounted for live reload

**Start**:
```bash
docker compose up
```

### Production

**Setup**: `docker-compose.prod.yml`

Services:
- **db**: PostgreSQL 15 (internal only)
- **backend**: Phoenix release (exposed via proxy)
- **frontend**: nginx serving static build (exposed via proxy)
- **proxy**: nginx reverse proxy (port 80/443)

**Volumes**: Persistent data only (no source mounts)

**Start**:
```bash
cp .env.prod.template .env.prod
# Edit .env.prod with real values
docker compose -f docker-compose.prod.yml up -d
```

## 🚀 CI/CD Pipeline

### GitLab CI Stages

Defined in `.gitlab-ci.yml`:

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Build   │──▶│   Test   │──▶│   Push   │──▶│  Deploy  │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
```

#### 1. Build Stage

- **build_frontend**: Build frontend Docker image
- **build_backend**: Build backend Docker image
- **Trigger**: On all branches
- **Artifacts**: Docker images tagged with `$CI_COMMIT_SHA`

#### 2. Test Stage

- **test_frontend**: Run `npm test` in Node.js container
- **test_backend**: Run `mix test` in Elixir container
- **Trigger**: On all branches
- **Fail Fast**: Pipeline stops if tests fail

#### 3. Push Stage

- **push_images**: Push Docker images to GitLab Container Registry
- **Trigger**: Only on `main` branch
- **Requires**: Docker login with `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD`

#### 4. Deploy Stage (Manual)

- **deploy_prod**: Manual deployment to production
- **Trigger**: Manual approval on `main` branch
- **Implementation**: SSH to server and run `docker compose -f docker-compose.prod.yml pull && docker compose -f docker-compose.prod.yml up -d`

### GitLab CI Variables

Configure in GitLab Project Settings → CI/CD → Variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `CI_REGISTRY` | Docker registry URL | `registry.gitlab.com` |
| `CI_REGISTRY_USER` | Registry username | GitLab CI token |
| `CI_REGISTRY_PASSWORD` | Registry password | GitLab CI token |
| `SSH_PRIVATE_KEY` | SSH key for deployment | (Base64 encoded) |
| `DEPLOY_SERVER` | Production server address | `user@example.com` |

## 🐳 Docker Strategy

### Multi-Stage Builds

Both frontend and backend use multi-stage builds:

**Frontend**:
1. **Builder**: Install deps, run `npm run build`
2. **Runtime**: Copy built files to nginx, serve on port 80

**Backend**:
1. **Builder**: Compile Elixir, build release
2. **Runtime**: Run release binary (smaller image, no build tools)

### Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| **Images** | `Dockerfile.dev` | `Dockerfile` |
| **Volumes** | Source mounted | None (code in image) |
| **Hot Reload** | Yes | No |
| **Build Optimization** | Minimal | Full optimization |
| **Image Size** | Larger (includes dev tools) | Smaller (runtime only) |

## 🔒 Security Considerations

### Secrets Management

- **Never commit** `.env.prod` or secrets to Git
- Use GitLab CI/CD variables or external secret managers (Vault, AWS Secrets Manager)
- Rotate `SECRET_KEY_BASE` and database passwords regularly

### CORS Configuration

- **Dev**: Allow `http://localhost:5173`
- **Prod**: Restrict to your frontend domain only

### Authentication

- JWT tokens with expiration
- Passwords hashed with bcrypt (cost factor 12+)
- HTTPS enforced in production

## 📊 Monitoring & Logging

### Recommended Tools

- **Logging**: Phoenix Logger, structured logs with JSON
- **Monitoring**: Phoenix LiveDashboard (built-in)
- **APM**: Consider New Relic, AppSignal, or DataDog
- **Error Tracking**: Sentry for both frontend and backend

### Health Checks

Add health endpoints:

```elixir
# Backend: lib/signin_project_web/router.ex
get "/health", HealthController, :index
```

```js
// Frontend: public/health.html (static)
OK
```

## 🚢 Deployment Strategies

### Option 1: Single VM with Docker Compose

- **Pros**: Simple, low cost
- **Cons**: No auto-scaling, single point of failure
- **Use Case**: Small projects, MVP

### Option 2: Kubernetes

- **Setup**: Convert to Kubernetes manifests (Deployment, Service, Ingress)
- **Pros**: Auto-scaling, high availability, self-healing
- **Cons**: Complex, higher cost
- **Use Case**: Production-grade applications

### Option 3: Platform-as-a-Service

- **Options**: Fly.io, Render, Heroku
- **Pros**: Managed infrastructure, easy deployment
- **Cons**: Vendor lock-in, cost at scale
- **Use Case**: Fast iteration, small teams

## 📈 Scaling Considerations

### Horizontal Scaling

- **Frontend**: Nginx can serve multiple replicas (stateless)
- **Backend**: Phoenix handles concurrency well; add replicas behind load balancer
- **Database**: Use read replicas for read-heavy workloads

### Caching

- **Frontend**: CDN for static assets (CloudFront, Cloudflare)
- **Backend**: Redis for session/token caching (if needed)
- **Database**: Query caching in Ecto

### Performance

- **Frontend**: Code splitting, lazy loading routes
- **Backend**: Connection pooling (default 10 in Ecto)
- **Database**: Indexes on frequently queried columns

## 🛠 Development Workflow

1. **Branch**: Create feature branch from `main`
2. **Develop**: Use `docker compose up` for local dev
3. **Test**: Run tests locally (`npm test`, `mix test`)
4. **Commit**: Push to GitLab
5. **CI**: GitLab runs build and test stages
6. **Review**: Create merge request, get approval
7. **Merge**: Merge to `main`, trigger push stage
8. **Deploy**: Manually trigger deploy stage in GitLab UI

## 📝 Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Dev environment setup |
| `docker-compose.prod.yml` | Production environment setup |
| `.gitlab-ci.yml` | CI/CD pipeline definition |
| `nginx.conf` | Reverse proxy config |
| `.env.prod.template` | Production env variables template |
| `frontend/vite.config.js` | Vite build config & dev proxy |
| `backend/config/runtime.exs` | Phoenix runtime config |

## 🔗 External Services

### Optional Integrations

- **Email**: Swoosh (already included) + SMTP provider (SendGrid, Mailgun)
- **Storage**: S3 for file uploads
- **Search**: Elasticsearch or Algolia
- **Queue**: Oban (Elixir job queue)

## 📚 Resources

- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
