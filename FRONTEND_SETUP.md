# Frontend Setup Guide

This guide covers setup, development, testing, and deployment of the Vue.js frontend.

## Prerequisites

- Node.js 18+ (recommend 20)
- npm or yarn
- Docker (optional, for containerized dev)

## Installation

### Local Setup

```bash
cd frontend
npm install
```

### Docker Setup

```bash
docker compose up frontend
```

## Development

### Running Dev Server

```bash
npm run dev
```

The dev server starts on http://localhost:5173 with hot module replacement (HMR).

### Project Structure

```
frontend/
├── src/
│   ├── components/     # Reusable Vue components
│   ├── views/          # Page components (routed)
│   ├── services/       # API client services
│   ├── router.js       # Vue Router config
│   ├── main.js         # App entry point
│   └── App.vue         # Root component
├── public/             # Static assets
├── vite.config.js      # Vite configuration
├── package.json
└── Dockerfile          # Production image
```

## API Configuration

The frontend connects to the backend API. Configure the base URL:

**Development** (in `vite.config.js`):
```js
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:4000',
      changeOrigin: true
    }
  }
}
```

**Production** (set environment variable):
```bash
VITE_API_BASE_URL=https://your-domain.com/api
```

## Building

### Production Build

```bash
npm run build
```

This creates optimized static files in `dist/`.

### Preview Production Build

```bash
npm run preview
```

## Testing

```bash
# Run tests
npm run test

# Run tests in watch mode
npm run test:watch

# Coverage
npm run test:coverage
```

## Linting & Formatting

```bash
# Lint
npm run lint

# Fix lint errors
npm run lint:fix

# Format with Prettier (if configured)
npm run format
```

## Docker

### Development Image

```bash
docker build -f Dockerfile.dev -t frontend-dev .
docker run -p 5173:5173 -v $(pwd):/app frontend-dev
```

### Production Image

```bash
docker build -t frontend-prod .
docker run -p 80:80 frontend-prod
```

The production image uses nginx to serve static files.

## Environment Variables

Create a `.env.local` file (not committed):

```bash
VITE_API_BASE_URL=http://localhost:4000/api
VITE_APP_TITLE="Sign-in Project"
```

Access in code:
```js
const apiUrl = import.meta.env.VITE_API_BASE_URL
```

## Common Issues

### Port Already in Use

```bash
# Kill process on port 5173
npx kill-port 5173
```

### EMFILE: too many open files

Vite watches many files. If you hit OS limits:

```bash
# Temporary fix
ulimit -n 65536

# Or use polling
CHOKIDAR_USEPOLLING=true npm run dev
```

The `vite.config.js` already ignores large folders to reduce watchers.

### Module Not Found

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

## Dependencies

Key dependencies:
- **Vue 3** - Progressive JavaScript framework
- **Vite** - Next-generation frontend tooling
- **Vue Router** - Official router for Vue.js
- **Axios** - Promise-based HTTP client (or use Fetch API)

## Deployment

See [DEPLOYMENT.md](../DEPLOYMENT.md) for production deployment with Docker Compose and CI/CD.

## Resources

- [Vue 3 Documentation](https://vuejs.org/)
- [Vite Documentation](https://vitejs.dev/)
- [Vue Router](https://router.vuejs.org/)
