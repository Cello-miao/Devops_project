<template>
  <div class="auth">
    <div class="register card">
      <div class="brand">
        <div class="logo" />
        <h2>Sign Up</h2>
      </div>
      <form
        class="form"
        @submit.prevent="signUp"
      >
        <div class="field">
          <label for="name">First name</label>
          <input
            id="name"
            v-model="name"
            type="text"
            required
          >
        </div>

        <div class="field">
          <label for="surname">Last name</label>
          <input
            id="surname"
            v-model="surname"
            type="text"
            required
          >
        </div>

        <div class="field">
          <label for="email">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
          >
        </div>

        <div class="field">
          <label for="password">Password</label>
          <input
            id="password"
            v-model="password"
            type="password"
            required
          >
        </div>

        <div class="field">
          <label for="role">Role</label>
          <select
            id="role"
            v-model="role"
          >
            <option value="user">
              User
            </option>
            <option value="admin">
              Admin
            </option>
            <option value="manager">
              Manager
            </option>
            <option value="employee">
              Employee
            </option>
          </select>
        </div>

        <button
          class="btn-primary"
          type="submit"
        >
          Register
        </button>
      </form>

      <div class="aux">
        <router-link
          to="/sign_in"
          class="link-signup"
        >
          Already have an account? Sign in
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

export default {
  name: 'Registration',
  data() {
    return {
      name: '',
      surname: '',
      email: '',
      password: '',
      role: 'user',
      error: null
    }
  },
  methods: {
    async signUp() {
      this.error = null
      try {
        // Send raw password to server; server should handle hashing/salting.
        // Phoenix controllers commonly expect a `user` key, e.g. %{"user" => %{...}}
        const payload = {
          user: {
            email: this.email,
            name: this.name,
            surname: this.surname,
            role: this.role,
            password: this.password
          }
        }

        const res = await api.post('/users/sign_up', payload)
        const data = res.data || {}

        // If backend returns xsrf token and user id, store them and go Home
        if (data.xsrf_token || data.xsrfToken || data.id || data.userId) {
          const xsrf = data.xsrf_token || data.xsrfToken
          const userId = data.id || data.userId
          const roleId = data.role || data.roleId
          if (xsrf) localStorage.setItem('xsrfToken', xsrf)
          if (userId) localStorage.setItem('userId', String(userId))
          if (roleId) localStorage.setItem('roleId', String(roleId))
          this.$router.push({ name: 'Home' })
        } else if (res.status === 201 || res.status === 200) {
          // fallback: if server returned success status but no body, go Home
          this.$router.push({ name: 'Home' })
        } else {
          this.error = 'Registration failed.'
        }
      } catch (err) {
        // If server responded with validation errors (HTTP 422), format them
        const resp = err.response?.data
        if (err.response?.status === 422 && resp) {
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
          this.error = err.response?.data?.message || err.message || 'Registration failed.'
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

/* Style for select controls (Role) to match inputs */
.field select {
  height: 44px;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid #d7e0ef;
  background: #fbfdff;
  outline: none;
  transition: box-shadow .12s ease, border-color .12s ease;
  appearance: none; /* remove default arrow on some browsers */
  -webkit-appearance: none;
}

.field select:focus {
  box-shadow: 0 4px 14px rgba(110,140,255,0.12);
  border-color: #7aa0ff;
}

/* Optional role button styles if you later switch from <select> to buttons */
.role-options { display:flex; gap:8px; flex-wrap:wrap }
.role-option {
  padding: 8px 12px; border-radius:8px; border:1px solid #d7e0ef; background:#fff; cursor:pointer;
}
.role-option.active { background: linear-gradient(90deg,#4b6bff,#6ad0ff); color:#fff; border:none }

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

.aux { margin-top: 10px; text-align: center }
.link-signup { color: #4b6bff; font-weight: 600; text-decoration: none }
.link-signup:hover { text-decoration: underline }

/* Responsive */
@media (max-width: 480px) {
  .card { padding: 20px; border-radius: 10px; }
  .brand h2 { font-size: 18px }
}

</style>
