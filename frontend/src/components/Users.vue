<template>
  <div class="card">
    <div class="header">
      <h2>Users</h2>
      <div>
        <button @click="load">
          Refresh
        </button>
      </div>
    </div>

    <table class="users-table">
      <thead>
        <tr>
          <th>ID</th>
          <th>First name</th>
          <th>Last name</th>
          <th>Email</th>
          <th>Role</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="u in users"
          :key="u.id"
        >
          <td>{{ u.id }}</td>
          <td>{{ u.name }}</td>
          <td>{{ u.surname }}</td>
          <td>{{ u.email }}</td>
          <td>{{ u.role }}</td>
          <td>
            <button @click="show(u.id)">
              View
            </button>
            <button
              v-if="isLoggedIn"
              @click="remove(u.id)"
            >
              Delete
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import api from '../services/api'

export default {
  name: 'Users',
  data() { return { users: [] } },
  computed: {
    isLoggedIn() { return !!(localStorage.getItem('xsrfToken') && localStorage.getItem('userId')) }
  },
  async created() { await this.load() },
  methods: {
    async load() { try { const res = await api.get('/users'); this.users = res.data || [] } catch (err) { console.error(err) } },
    async show(id) { this.$router.push({ name: 'UserDetails', params: { userId: id } }) },
    async remove(id) {
      if (!confirm('Delete user #' + id + '?')) return
      try { await api.delete(`/users/${id}`); await this.load() } catch (err) { console.error(err) }
    }
  }
}
</script>

<style scoped>
.card{padding:18px}
.header{display:flex;justify-content:space-between;align-items:center}
.users-table{width:100%;border-collapse:collapse}
.users-table th,.users-table td{padding:8px;border-bottom:1px solid #eee;text-align:left}
</style>
