<template>
  <div class="auth">
    <div class="card">
      <div class="brand">
        <div class="" />
        <h2>Sign In</h2>
      </div>

      <form
        class="form"
        @submit.prevent="signIn"
      >
        <div class="field">
          <label for="email">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            autocomplete="email"
          >
        </div>

        <div class="field">
          <label for="password">Password</label>
          <input
            id="password"
            v-model="password"
            type="password"
            required
            autocomplete="current-password"
          >
        </div>

        <button
          class="btn-primary"
          type="submit"
        >
          Sign In
        </button>
      </form>

      <div class="aux">
        <router-link
          to="/sign_up"
          class="link-signup"
        >
          Don't have an account? Sign up
        </router-link>
      </div>

      <p
        v-if="error"
        class="error"
      >
        {{ error }}
      </p>
    </div>
  </div>
</template>

<script>
import api from '../services/api'
import { useRouter } from 'vue-router'

export default {
  name: 'Authentication',
  setup() {
    const router = useRouter()
    return { router }
  },
  data() {
    return {
      email: '',
      password: '',
      error: null
    }
  },
  methods: {
    async signIn() {
      this.error = null
      try {
        // Send flat payload expected by the sign_in controller
        const payload = { email: this.email, password: this.password }
        const res = await api.post('/users/sign_in', payload)
        // Expecting response.data to contain xsrfToken, userId, roleId
        const data = res.data || {}
        const xsrf = data.xsrf_token || data.xsrfToken
        const userId = data.id || data.userId
        const roleId = data.role || data.roleId

        if (xsrf && userId) {
          localStorage.setItem('xsrfToken', xsrf)
          localStorage.setItem('userId', String(userId))
          if (roleId) localStorage.setItem('roleId', String(roleId))
          // Navigate to Home after successful sign-in.
          this.$router.push({ name: 'Home' })
        } else if (res.status === 200) {
          // server returned 200 but without expected body
          this.error = 'Signed in but server returned unexpected response.'
        } else {
          this.error = res.data?.error || 'Invalid response from server.'
        }
      } catch (err) {
        const resp = err.response?.data
        if (err.response?.status === 422 && resp) {
          // format validation errors
          if (resp.errors && typeof resp.errors === 'object') {
            const parts = []
            for (const [k, v] of Object.entries(resp.errors)) {
              const msgs = Array.isArray(v) ? v.join(', ') : String(v)
              parts.push(`${k} ${msgs}`)
            }
            this.error = parts.join('; ')
          } else if (resp.error) {
            this.error = resp.error
          } else {
            this.error = JSON.stringify(resp)
          }
        } else {
          this.error = err.response?.data?.message || err.message || 'Sign in failed.'
        }
      }
    }
  }
}
</script>

<style scoped>
/* Page background and centering */
.auth {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: linear-gradient(135deg, #f5f7ff 0%, #e8f0ff 100%);
}

/* Card */
.card {
  width: 100%;
  max-width: 420px;
  background: #fff;
  border-radius: 12px;
  padding: 28px;
  box-shadow: 0 8px 28px rgba(20, 30, 60, 0.08);
  border: 1px solid rgba(20,30,60,0.04);
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 18px;
}

.logo {
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg,#6a8cff,#7ee1ff);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  font-weight: 700;
  font-size: 18px;
}

.brand h2 {
  margin: 0;
  font-size: 20px;
  color: #12263f;
}

.form {
  display: grid;
  gap: 12px;
}

.field {
  display: flex;
  flex-direction: column;
}

.field label {
  font-size: 13px;
  color: #5b6b80;
  margin-bottom: 6px;
}

.field input {
  height: 44px;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid #d7e0ef;
  background: #fbfdff;
  outline: none;
  transition: box-shadow .12s ease, border-color .12s ease;
}

.field input:focus {
  box-shadow: 0 4px 14px rgba(110,140,255,0.12);
  border-color: #7aa0ff;
}

.btn-primary {
  margin-top: 6px;
  height: 46px;
  width: 100%;
  border: none;
  border-radius: 10px;
  background: linear-gradient(90deg,#4b6bff,#6ad0ff);
  color: white;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 6px 20px rgba(75,107,255,0.18);
  transition: transform .08s ease, box-shadow .12s ease;
}

.btn-primary:active { transform: translateY(1px); }
.btn-primary:hover { box-shadow: 0 10px 28px rgba(75,107,255,0.22); }

.error {
  margin-top: 14px;
  color: #b83a3a;
  font-weight: 600;
}

/* Responsive */
@media (max-width: 480px) {
  .card { padding: 20px; border-radius: 10px; }
  .brand h2 { font-size: 18px }
}

.aux { margin-top: 10px; text-align: center }
.link-signup { color: #4b6bff; font-weight: 600; text-decoration: none }
.link-signup:hover { text-decoration: underline }

</style>
