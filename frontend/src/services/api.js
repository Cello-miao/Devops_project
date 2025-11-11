import axios from 'axios'

// Configure baseURL so the dev proxy in vite.config.js can forward /api
// requests to the backend and avoid CORS during development. You can set
// VITE_API_URL to override the URL in different environments.
const baseURL = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL,
  withCredentials: true, // ensure HttpOnly cookies (if any) are sent
  headers: {
    'Content-Type': 'application/json'
  }
})

// Attach XSRF token from localStorage to every request (as required)
api.interceptors.request.use((config) => {
  const xsrf = localStorage.getItem('xsrfToken')
  if (xsrf) {
    // axios normalizes headers; set header expected by backend
    config.headers['x-xsrf-token'] = xsrf
  }
  return config
})

export default api
