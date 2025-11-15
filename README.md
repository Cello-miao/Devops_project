# Sign-in Project

A full-stack web application with Vue.js frontend and Elixir/Phoenix backend, containerized for development and production deployment with automated CI/CD pipeline.

## 📁 Project Structure

```
├── frontend/               # Vue 3 + Vite application
│   ├── src/
│   ├── Dockerfile         # Production image
│   └── Dockerfile.dev     # Development image
├── backend/                # Elixir/Phoenix API
│   ├── lib/
│   ├── Dockerfile         # Production image (release)
│   └── Dockerfile.dev     # Development image
├── docker-compose.yml      # Development environment
├── docker-compose.prod.yml # Production environment
├── .gitlab-ci.yml         # CI/CD pipeline
├── .env                   # Development secrets (gitignored)
└── .env.prod              # Production secrets (gitignored)
```

## 🚀 How to Run Your Project

### Prerequisites

- Docker & Docker Compose installed
- Git
- (Optional) Node.js 20+ and Elixir 1.17+ for local development

### Option 1: Run with Docker Compose (Recommended)

#### 1. Clone the Repository

```bash
git clone https://gitlab.com/Cello-miao/devops.git
cd devops_project_new
```

#### 2. Set Up Environment Variables

Create a `.env` file with your configuration:

```bash
# Create .env file
cat > .env << EOF
# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=signin_project_dev

# Backend Configuration
SECRET_KEY_BASE=$(openssl rand -base64 64)
PHX_SERVER=true
MIX_ENV=dev

# Database Connection
DB_HOST=db
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=signin_project_dev
EOF
```

#### 3. Start All Services

```bash
# Start in detached mode
docker compose up -d

# Or watch logs
docker compose up
```

#### 4. Access the Application

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:4000
- **PostgreSQL**: localhost:5432

#### 5. Stop Services

```bash
docker compose down

# Remove volumes (database data)
docker compose down -v
```

### Option 2: Run Locally (Without Docker)

#### Backend Setup

```bash
cd backend

# Install dependencies
mix deps.get

# Set up database
mix ecto.create
mix ecto.migrate

# Start Phoenix server
mix phx.server
```

Backend runs at: http://localhost:4000

#### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

Frontend runs at: http://localhost:5173

## How to Deploy It

### Deployment Architecture

- **CI/CD**: GitLab CI/CD pipeline
- **Target**: AWS EC2 instance
- **Containers**: Docker Compose with nginx reverse proxy
- **Database**: PostgreSQL 15
- **Current Production**: http://98.83.35.237

### Prerequisites for Deployment

1. **GitLab Repository** with CI/CD enabled
2. **AWS EC2 Instance** (Amazon Linux 2023 recommended)
3. **GitLab CI/CD Variables** configured
4. **SSH Access** to EC2 instance

### Step 1: Configure EC2 Instance

#### Install Docker on EC2 (Amazon Linux)

```bash
# SSH into your EC2 instance
ssh ec2-user@your-ec2-ip

# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -aG docker ec2-user

# Log out and log back in for group changes to take effect
exit
ssh ec2-user@your-ec2-ip

# Verify Docker installation
docker --version

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version
```

#### Configure SSH Access

```bash
# On your local machine, generate SSH key (if not exists)
ssh-keygen -t rsa -b 4096

# Copy public key to EC2
ssh-copy-id ec2-user@your-ec2-ip

# Convert private key to base64 for GitLab
cat ~/.ssh/id_rsa | base64 -w 0
```

### Step 2: Configure GitLab CI/CD Variables

Go to your GitLab project: **Settings > CI/CD > Variables**

Add the following variables:

| Variable | Value | Protected | Masked |
|----------|-------|-----------|--------|
| `SSH_KEY_BASE64` | Base64-encoded private SSH key | ✅ | ✅ |
| `EC2_HOST` | Your EC2 public IP address | ✅ | ❌ |
| `EC2_USER` | EC2 username (use `ec2-user` for Amazon Linux) | ✅ | ❌ |
| `SECRET_KEY_BASE` | Phoenix secret (64 bytes, base64) | ✅ | ✅ |
| `DB_PASSWORD` | Production database password | ✅ | ✅ |
| `CI_REGISTRY` | `registry.gitlab.com` | ❌ | ❌ |
| `CI_REGISTRY_USER` | Your GitLab username | ✅ | ❌ |
| `CI_REGISTRY_PASSWORD` | GitLab access token | ✅ | ✅ |

#### Generate Secrets

```bash
# Generate SECRET_KEY_BASE (use a different key than development)
openssl rand -base64 64

# Generate DB_PASSWORD
openssl rand -base64 32
```

### Step 3: Prepare Production Environment File

The `.env.prod` file will be automatically created on EC2 during deployment by GitLab CI/CD. It uses the variables configured in GitLab CI/CD settings.

If you need to create it manually, the format is:

```bash
# Production Environment Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=signin_project_prod

# Backend Configuration
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PHX_SERVER=true
MIX_ENV=prod

# Database Connection
DB_HOST=db
DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=signin_project_prod

# Docker Images (set by CI/CD)
BACKEND_IMAGE=${CI_REGISTRY_IMAGE}/backend:${CI_COMMIT_SHA}
FRONTEND_IMAGE=${CI_REGISTRY_IMAGE}/frontend:${CI_COMMIT_SHA}
```

### Step 4: Deploy via GitLab CI/CD

The deployment happens automatically when you push to `main` branch:

#### Pipeline Stages

1. **Build** - Build Docker images for frontend and backend
2. **Test** - Run backend and frontend tests
3. **Push** - Push images to GitLab Container Registry (main branch only)
4. **Deploy** - Deploy to EC2 production server (main branch only)

#### Trigger Deployment

```bash
# Make sure all changes are committed
git add .
git commit -m "feat: ready for deployment"

# Push to main branch (triggers CI/CD)
git push origin main
```

#### Monitor Deployment

1. Go to GitLab: **CI/CD > Pipelines**
2. Click on the running pipeline
3. Watch each stage execute
4. Check `deploy_prod` job logs for deployment progress

### Step 5: Verify Deployment

```bash
# SSH into EC2
ssh ec2-user@your-ec2-ip

# Check running containers
cd app
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend

# Check database
docker compose -f docker-compose.prod.yml exec db psql -U postgres -d signin_project_prod
```

#### Access Production Application

- **Frontend**: http://your-ec2-ip
- **Backend API**: http://your-ec2-ip/api

### Step 6: Manual Deployment (Alternative)

If you need to deploy manually without CI/CD:

```bash
# 1. SSH into EC2
ssh ec2-user@your-ec2-ip
mkdir -p app && cd app

# 2. Create .env.prod file
cat > .env.prod << EOF
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<your-db-password>
POSTGRES_DB=signin_project_prod
SECRET_KEY_BASE=<your-secret>
PHX_SERVER=true
MIX_ENV=prod
DB_HOST=db
DB_USER=postgres
DB_PASSWORD=<your-db-password>
DB_NAME=signin_project_prod
BACKEND_IMAGE=registry.gitlab.com/cello-miao/devops/backend:latest
FRONTEND_IMAGE=registry.gitlab.com/cello-miao/devops/frontend:latest
EOF

# 3. Copy docker-compose.prod.yml and nginx.conf
# (upload via scp or copy content)

# 4. Login to GitLab Registry
echo <your-gitlab-token> | docker login -u <your-username> --password-stdin registry.gitlab.com

# 5. Pull and start services
docker compose -f docker-compose.prod.yml --env-file .env.prod pull
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# 6. Run migrations
docker compose -f docker-compose.prod.yml --env-file .env.prod exec backend /app/bin/signin_project eval 'SigninProject.Release.migrate()'
```

## 🔄 Updating Production

To update production with new changes:

```bash
# 1. Commit and push changes
git add .
git commit -m "feat: new feature"
git push origin main

# 2. GitLab CI/CD automatically:
#    - Builds new images
#    - Runs tests
#    - Pushes to registry
#    - Deploys to EC2
#    - Runs migrations
#    - Verifies deployment
```

## 🛠 Tech Stack

**Frontend**
- Vue 3.3.4
- Vite 5.4.20
- Vue Router
- Axios for API calls

**Backend**
- Elixir 1.17
- Phoenix Framework 1.8.1
- PostgreSQL 15
- Ecto (ORM)
- JWT authentication (Joken)
- bcrypt_elixir (password hashing)

**DevOps**
- Docker & Docker Compose
- GitLab CI/CD (4 stages: build, test, push, deploy)
- nginx (reverse proxy)
- AWS EC2 (production hosting)

## 🧪 Testing

### Run Tests Locally

```bash
# Frontend tests
cd frontend
npm run test

# Backend tests
cd backend
MIX_ENV=test mix test
```

### CI/CD Tests

Tests run automatically on every push:
- Frontend: `npm run test --if-present`
- Backend: Full test suite with PostgreSQL test database

## 📝 Environment Variables

### Development Environment

```bash
# Create .env file directly
cat > .env << EOF
# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=signin_project_dev

# Backend Configuration
SECRET_KEY_BASE=$(openssl rand -base64 64)
PHX_SERVER=true
MIX_ENV=dev

# Database Connection
DB_HOST=db
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=signin_project_dev
EOF
```

### Production Environment

Production environment variables are managed through:
1. **GitLab CI/CD Variables** (secure secrets)
2. **`.env.prod` file** (generated on EC2 during deployment)

Never commit `.env` or `.env.prod` files (they are gitignored).

## 🔍 Monitoring and Logs

### View Application Logs

```bash
# Development
docker compose logs -f backend
docker compose logs -f frontend

# Production (on EC2)
cd app
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
docker compose -f docker-compose.prod.yml logs -f nginx
```

### Check Container Status

```bash
# Development
docker compose ps

# Production
docker compose -f docker-compose.prod.yml --env-file .env.prod ps
```

### Database Access

```bash
# Development
docker compose exec db psql -U postgres -d signin_project_dev

# Production
docker compose -f docker-compose.prod.yml exec db psql -U postgres -d signin_project_prod
```

## 🐛 Troubleshooting

### Development Issues

#### Port Already in Use

```bash
# Kill process using port 4000 (backend)
lsof -ti:4000 | xargs kill -9

# Kill process using port 5173 (frontend)
lsof -ti:5173 | xargs kill -9
```

#### Database Connection Failed

```bash
# Restart database container
docker compose restart db

# Reset database
docker compose down -v
docker compose up -d
cd backend && mix ecto.reset
```

#### EMFILE: Too Many Open Files (Vite)

```bash
# Increase file descriptor limit
ulimit -n 65536

# Or use polling mode
CHOKIDAR_USEPOLLING=true npm run dev
```

### Production Issues

#### Deployment Failed

```bash
# SSH into EC2 and check logs
ssh ec2-user@your-ec2-ip
cd app
docker compose -f docker-compose.prod.yml logs

# Check if containers are running
docker compose -f docker-compose.prod.yml ps
```

#### Migration Errors

```bash
# SSH into EC2
cd app

# Check migration status
docker compose -f docker-compose.prod.yml exec backend /app/bin/signin_project eval 'Ecto.Migrator.migrated_versions(SigninProject.Repo)'

# Run migrations manually
docker compose -f docker-compose.prod.yml exec backend /app/bin/signin_project eval 'SigninProject.Release.migrate()'
```

#### Container Won't Start

```bash
# Check container logs
docker compose -f docker-compose.prod.yml logs backend

# Restart specific service
docker compose -f docker-compose.prod.yml restart backend

# Full restart
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

#### GitLab CI/CD Pipeline Fails

1. Check pipeline logs in GitLab UI
2. Verify all CI/CD variables are set correctly
3. Ensure EC2 instance is accessible via SSH
4. Check Docker Registry credentials

### Common YAML Issues in .gitlab-ci.yml

If you see "script config should be a string or nested array":
- Ensure echo commands with colons are quoted: `'echo "Step 1: Message"'`
- Comments should be above commands, not as separate list items

## 📚 Additional Resources

### Documentation Files

- `docker-compose.yml` - Development services configuration
- `docker-compose.prod.yml` - Production services configuration
- `.gitlab-ci.yml` - CI/CD pipeline configuration
- `.env` - Development secrets (gitignored, create manually)
- `.env.prod` - Production secrets (gitignored, created by CI/CD)

### Useful Commands

```bash
# Generate Phoenix secret
mix phx.gen.secret

# Generate random password
openssl rand -base64 32

# Encode SSH key for GitLab
cat ~/.ssh/id_rsa | base64 -w 0

# Check Docker Compose config
docker compose config

# View environment variables in container
docker compose exec backend env
```

## Security Notes

1. **Never commit secrets** - Use `.env` files and keep them gitignored
2. **Use strong passwords** - Generate with `openssl rand -base64 32`
3. **Rotate secrets regularly** - Update GitLab CI/CD variables
4. **Limit EC2 access** - Configure security groups properly
5. **Use HTTPS in production** - Set up SSL/TLS certificates (Let's Encrypt)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📧 Support

For issues and questions:
- Open an issue in GitLab
- Check troubleshooting section above
- Review GitLab CI/CD logs for deployment issues
