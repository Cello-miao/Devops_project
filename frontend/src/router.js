import { createRouter, createWebHistory } from 'vue-router'
import Home from './views/Home.vue'
import Authentication from './components/Authentication.vue'
import Registration from './components/Registration.vue'
import SkillsManager from './components/SkillsManager.vue'
import SkillDetails from './components/SkillDetails.vue'
import AccountManager from './components/AccountManager.vue'
import Users from './components/Users.vue'
import Tasks from './components/Tasks.vue'
import TaskEdit from './components/TaskEdit.vue'

const routes = [
  // Require authentication for the root route so unauthenticated users
  // visiting '/' are redirected to the Sign In page by the global guard.
  { path: '/', name: 'Home', component: Home, meta: { requiresAuth: true } },
  { path: '/sign_in', name: 'SignIn', component: Authentication, meta: { requiresAuth: false } },
  { path: '/sign_up', name: 'SignUp', component: Registration, meta: { requiresAuth: false } }
  ,{ path: '/skills', name: 'Skills', component: SkillsManager }
  ,{ path: '/skills/:skillId', name: 'SkillDetails', component: SkillDetails }
  ,{ path: '/profile', name: 'Profile', component: AccountManager, meta: { requiresAuth: true } }
  ,{ path: '/users', name: 'Users', component: Users }
  ,{ path: '/tasks', name: 'Tasks', component: Tasks }
  ,{ path: '/tasks/:taskId', name: 'TaskEdit', component: TaskEdit }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Simple auth helper
function isAuthenticated() {
  return !!(localStorage.getItem('xsrfToken') && localStorage.getItem('userId'))
}

// Global guard: protect routes that set meta.requiresAuth = true
router.beforeEach((to, from, next) => {
  // If the route requires auth but the user is not authenticated, redirect to sign_in
  if (to.meta && to.meta.requiresAuth && !isAuthenticated()) {
    next({ name: 'SignIn' })
    return
  }

  // If the user is authenticated and tries to reach sign_in or sign_up, redirect to home
  if ((to.name === 'SignIn' || to.name === 'SignUp') && isAuthenticated()) {
    next({ name: 'Home' })
    return
  }

  // otherwise allow
  next()
})

export default router
