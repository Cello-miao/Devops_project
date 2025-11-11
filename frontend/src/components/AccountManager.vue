
<template>
  <div class="card">
    <h2>My Profile</h2>
    <form
      class="form"
      @submit.prevent="save"
    >
      <div class="field">
        <label for="name">First name</label>
        <input
          id="name"
          v-model="user.name"
          type="text"
          required
        >
      </div>

      <div class="field">
        <label for="surname">Last name</label>
        <input
          id="surname"
          v-model="user.surname"
          type="text"
          required
        >
      </div>

      <div class="field">
        <label for="email">Email</label>
        <input
          id="email"
          v-model="user.email"
          type="email"
          required
        >
      </div>

      <div class="field">
        <label for="password">Password (change)</label>
        <input
          id="password"
          v-model="password"
          type="password"
        >
      </div>

      <div class="field">
        <label for="role">Role</label>
        <select
          id="role"
          v-model="user.role"
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

      <!-- <div class="field">
        <label>Skills</label>
        <div style="display:flex; gap:8px; align-items:center">
          <select v-model="newSkillId">
            <option :value="null">-- choose skill --</option>
            <option v-for="s in allSkills" :value="s.id" :key="s.id">{{ s.name }}</option>
          </select>
          <button class="btn-primary" @click.prevent="addSkill">Add</button>
        </div>
      </div> -->

      <ul>
        <li
          v-for="s in displayedSkills"
          :key="s.id"
        >
          {{ s.name }} <button @click.prevent="removeSkill(s.id)">
            Remove
          </button>
        </li>
      </ul>

      <div>
        <button
          class="btn-primary"
          type="submit"
        >
          Save
        </button>
      </div>

      <p
        v-if="error"
        class="error"
      >
        {{ error }}
      </p>
      <p
        v-if="success"
        class="success"
      >
        {{ success }}
      </p>
    </form>
  </div>
</template>

<script>
import api from '../services/api'

export default {
  name: 'AccountManager',
  data() {
    return { user: {}, password: '', allSkills: [], newSkillId: null, error: null, success: null }
  },
  computed: {
    // Normalize a displayed list of skills for the user so the template
    // can render regardless of the API returning ids, nested objects,
    // or full skill objects.
    displayedSkills() {
      const u = this.user || {}
      const raw = u.skills || []
      // If raw is an array of primitive ids (numbers/strings), map to allSkills
      if (!Array.isArray(raw)) return []
      const result = raw.map(item => {
        // If item is a primitive id
        if (typeof item === 'number' || typeof item === 'string') {
          const found = (this.allSkills || []).find(s => String(s.id) === String(item))
          return { id: item, name: found ? found.name : String(item) }
        }
        // If item has .skill or .skill_id
        if (item.skill && (item.skill.id || item.skill.name)) {
          return { id: item.skill.id || item.skill_id || item.id, name: item.skill.name || item.name || String(item.skill.id || item.id) }
        }
        // If item has id/name directly
        if (item.id || item.name) {
          return { id: item.id, name: item.name || String(item.id) }
        }
        // Fallback to stringify
        return { id: JSON.stringify(item), name: String(item) }
      })
      return result
    }
  },
  async created() {
    await this.load()
  },
  methods: {
    async load() {
      try {
        const res = await api.get('/users/me')
        this.user = res.data || {}
        const s = await api.get('/skills')
        this.allSkills = s.data || []
      } catch (err) {
        console.error('load profile', err)
        this.error = 'Failed to load profile'
      }
    },
    async save() {
      this.error = null
      this.success = null
      try {
        const payload = { user: { ...this.user } }
        if (this.password) payload.user.password = this.password
        await api.put('/users/me', payload)
        this.password = ''
        this.success = 'Profile saved.'
        await this.load()
      } catch (err) {
        console.error('save profile', err)
        this.error = err.response?.data?.message || 'Failed to save profile'
      }
    },
    async addSkill() {
      if (!this.newSkillId) return
      try {
        await api.post(`/users/${this.user.id}/skills`, { skill_id: this.newSkillId })
        this.newSkillId = null
        await this.load()
      } catch (err) {
        console.error('add skill', err)
        this.error = 'Failed to add skill'
      }
    },
    async removeSkill(id) {
      try {
        await api.delete(`/users/${this.user.id}/skills/${id}`)
        await this.load()
      } catch (err) {
        console.error('remove skill', err)
        this.error = 'Failed to remove skill'
      }
    }
  }
}
</script>

<style scoped>
.card { max-width: 520px; margin: 24px auto; background: #fff; padding: 20px; border-radius: 10px; box-shadow: 0 8px 28px rgba(20,30,60,0.06) }
.form { display:grid; gap:12px }
.field { display:flex; flex-direction:column }
.field label { font-size:13px; color:#5b6b80; margin-bottom:6px }
.field input, .field select { height:44px; padding:8px 12px; border-radius:8px; border:1px solid #d7e0ef }
.btn-primary { margin-top:6px; height:46px; width:100%; border:none; border-radius:10px; background:linear-gradient(90deg,#4b6bff,#6ad0ff); color:#fff; font-weight:600; cursor: pointer; box-shadow: 0 6px 20px rgba(75,107,255,0.18); transition: transform .08s ease, box-shadow .12s ease; }
.btn-primary:active { transform: translateY(1px); }
.btn-primary:hover { box-shadow: 0 10px 28px rgba(75,107,255,0.22); }
.field input:focus, .field select:focus { box-shadow: 0 4px 14px rgba(110,140,255,0.12); border-color: #7aa0ff; outline: none }
.error { margin-top:12px; color:#b83a3a; font-weight:600 }
.success { margin-top:12px; color:#2b8a3e; font-weight:600 }
</style>
