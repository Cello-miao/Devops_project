<template>
  <div>
    <nav class="site-nav">
      <!-- <div class="nav-left">
        <router-link to="/">Home</router-link>
      </div>
      <div class="nav-right">
        <router-link v-if="!isLoggedIn" to="/sign_in">Sign In</router-link>
        <router-link v-if="!isLoggedIn" to="/sign_up">Sign Up</router-link>
        <button v-if="isLoggedIn" class="btn-logout" @click="disconnect">Logout</button>
      </div> -->
    </nav>

    

    <router-view />
  </div>
</template>

<script>
import api from './services/api'

export default {
  name: 'App',
  computed: {
    isLoggedIn() {
      return !!(localStorage.getItem('xsrfToken') && localStorage.getItem('userId'))
    }
    ,
    xsrfTokenDisplay() {
      return localStorage.getItem('xsrfToken') || '(none)'
    },
    userIdDisplay() {
      return localStorage.getItem('userId') || '(none)'
    },
    roleIdDisplay() {
      return localStorage.getItem('roleId') || '(none)'
    }
  },
  methods: {
    async disconnect() {
      try {
        // Attempt server-side sign out
        await api.post('/users/sign_out')
      } catch (err) {
        // ignore errors on disconnect
      }
      // Remove stored tokens
      localStorage.removeItem('xsrfToken')
      localStorage.removeItem('userId')
      localStorage.removeItem('roleId')
      this.$router.push({ name: 'SignIn' })
    }
  }
}
</script>

<style>
body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial }

.site-nav {
  display:flex;
  justify-content:space-between;
  align-items:center;
  gap:12px;
  padding:12px 20px;
  border-bottom:1px solid #eee;
  background: #fff;
}
.site-nav a { color: #334155; text-decoration: none; font-weight: 600 }
.btn-logout {
  background: transparent;
  border: 1px solid #e6e9ef;
  padding: 6px 10px;
  border-radius: 8px;
  cursor: pointer;
}
</style>
