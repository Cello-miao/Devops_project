// Export a Promise-based CommonJS config so we can dynamically import
// ESM-only plugins (like @vitejs/plugin-vue) from a CJS environment.
// Vite supports configs that are a Promise resolving to the config object.

module.exports = (async () => {
  const { default: vue } = await import('@vitejs/plugin-vue')
  // return a plain config object; defineConfig is optional at runtime
  return {
    plugins: [vue()],
    // Dev server proxy to avoid CORS in development. Requests to /api/*
    // will be forwarded to the backend at localhost:4000. This makes
    // the browser think it's same-origin and avoids preflight/CORS issues.
    server: {
      // Reduce filesystem watchers by ignoring large folders. This helps avoid
      // "EMFILE: too many open files" errors on systems with low watcher limits.
      // See: https://vitejs.dev/config/server-options.html#server-watch
      watch: {
        // Ignore node_modules, Elixir/_build, deps, backend, git, and build artifacts
        ignored: [
          '**/node_modules/**',
          '**/.git/**',
          // Don't watch Vite config itself
          '**/vite.config.*',
          './vite.config.*',
          '**/_build/**',
          '**/deps/**',
          '../backend/**',
          '**/dist/**',
          '**/priv/**'
        ]
      },
      proxy: {
        '/api': {
          // Use Docker service name 'backend' in container, fallback to localhost for local dev
          target: process.env.VITE_API_TARGET || 'http://backend:4000',
          changeOrigin: true,
          secure: false,
          // keep the /api prefix so backend endpoints like /api/users/sign_in still match
          rewrite: (path) => path
        }
      }
    }
  }
})()
