<template>
  <div class="auth">
    <div class="card">
      <div class="brand">
        <h2>Welcome</h2>
      </div>

      <div class="content">
        <p>This is the home page.</p>
        <p v-if="userDisplay">
          Logged in as: <span class="user-badge">{{ userDisplay }}</span>
        </p>

        <div class="controls">
          <button
            v-if="isLoggedIn"
            class="btn-logout"
            @click="disconnect"
          >
            Logout
          </button>
          <button
            v-if="isAdmin"
            class="btn-outline"
            @click="goToSkills"
          >
            Skills
          </button>
          <button
            v-if="isAdmin"
            class="btn-outline"
            @click="goToTasks"
          >
            Tasks
          </button>
          <button
            v-if="isLoggedIn"
            class="btn-outline"
            @click="goToProfile"
          >
            My Profile
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from '../services/api'

export default {
  name: 'Home',
  data() {
    return {}
  },
  computed: {
    userId() {
      return localStorage.getItem('userId')
    },
    isLoggedIn() {
      return !!(localStorage.getItem('xsrfToken') && localStorage.getItem('userId'))
    }
    ,
    userDisplay() {
      return (
        localStorage.getItem('roleId') ||
        localStorage.getItem('name') ||
        localStorage.getItem('email') ||
        localStorage.getItem('userId') ||
        null
      )
    }
    ,
    isAdmin() {
      const r = localStorage.getItem('roleId')
      if (!r) return false
      const v = String(r).toLowerCase()
      // Accept either a role name 'admin' or a numeric id '1' (common backends)
      return v === 'admin' || v === '1'
    }
  },
  created() {
    // Home is lightweight; skill/task management moved to dedicated pages
  },
  methods: {
    async disconnect() {
      try {
        await api.post('/users/sign_out')
      } catch (err) {
        // ignore server errors on logout
      }
      localStorage.removeItem('xsrfToken')
      localStorage.removeItem('userId')
      localStorage.removeItem('roleId')
      this.$router.push({ name: 'SignIn' })
    }
    ,
    goToSkills() { this.$router.push({ name: 'Skills' }) },
    goToSkill(id) { if (!id) return; this.$router.push({ name: 'SkillDetails', params: { skillId: id } }) },
    goToProfile() { this.$router.push({ name: 'Profile' }) },
    goToUsers() { this.$router.push({ name: 'Users' }) },
    goToTasks() { this.$router.push({ name: 'Tasks' }) },
    goToTask(id) { if (!id) return; this.$router.push({ name: 'TaskEdit', params: { taskId: id } }) }
  }
}
</script>

<style scoped>
/* Page background and centering (same as Authentication.vue) */
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
  max-width: 720px;
  background: #fff;
  border-radius: 12px;
  padding: 28px;
  box-shadow: 0 8px 28px rgba(20, 30, 60, 0.06);
  border: 1px solid rgba(20,30,60,0.04);
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 18px;
}

.brand h2 {
  margin: 0;
  font-size: 20px;
  color: #12263f;
}

.content { display: grid; gap: 12px }

p { color: #6b7280; line-height: 1.6; }

.user-badge {
  display: inline-block;
  margin-left: 8px;
  padding: 6px 10px;
  background: #ecfdf5;
  color: #2f855a;
  border: 1px solid rgba(47,133,90,0.12);
  border-radius: 8px;
  font-weight: 600;
}

.controls { display:flex; gap:10px; flex-wrap:wrap; margin-top:8px }
.btn-logout { background: #fff; border:1px solid #e6e9ef; padding:8px 12px; border-radius:8px; cursor:pointer }
.btn-outline { background: transparent; border:1px solid #d7e0ef; padding:8px 12px; border-radius:8px; cursor:pointer }

@media (max-width: 480px) {
  .card { padding: 20px; border-radius: 10px; }
  .brand h2 { font-size: 18px }
}

</style>
