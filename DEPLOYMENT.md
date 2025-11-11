# Deployment notes

This repository includes a simple production deployment stack using Docker Compose
and a GitLab CI pipeline to build, test and push images.

Files added:

- `docker-compose.prod.yml` — production compose file (postgres, backend, frontend, nginx proxy)
- `nginx.conf` — nginx config used by the `proxy` service. It proxies `/api` to the backend and serves the frontend via the `frontend` container.
- `.env.prod.template` — environment variables template. Copy to `.env.prod` and fill before starting Compose.
- `.gitlab-ci.yml` — CI pipeline that builds images and runs tests. Customize registry and deploy steps for your environment.

Quick start (single VM):

1. Copy the env template:

```bash
cp .env.prod.template .env.prod
# Edit .env.prod and set real values for POSTGRES_PASSWORD, SECRET_KEY_BASE, etc.
```

2. Build & run:

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

3. Visit http://<HOST> (mapped port 80). Nginx proxy forwards `/api` to the backend.

CI notes

- The provided `.gitlab-ci.yml` builds frontend and backend Docker images, runs tests for both, and pushes images on `main`.
- Configure `CI_REGISTRY`, `CI_REGISTRY_USER`, and `CI_REGISTRY_PASSWORD` in your GitLab project variables to enable pushing.

Customization

- If your frontend Dockerfile already runs `npm run build` and serves static files via nginx inside the frontend image, the `proxy` can still be used to provide TLS/host routing.
- For Phoenix releases, consider replacing the `mix phx.server` command inside your backend Dockerfile with a release entrypoint and use `MIX_ENV=prod`.
