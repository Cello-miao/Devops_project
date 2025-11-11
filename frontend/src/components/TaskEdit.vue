<template>
  <div class="card">
    <h2>Edit Task</h2>
    <div v-if="task">
      <div class="field">
        <label>Title</label><input v-model="task.title">
      </div>
      <div class="field">
        <label>Description</label><textarea v-model="task.description" />
      </div>
      <!-- <div class="field"><label>Status</label><select v-model="task.status"><option>todo</option><option>in_progress</option><option>done</option></select></div> -->
      <div class="field">
        <label>Skills</label>
        <select v-model="selectedSkill">
          <option
            v-for="s in allSkills"
            :key="s.id"
            :value="s.id"
          >
            {{ s.name }}
          </option>
        </select>
        <button @click.prevent="addSkill">
          Add
        </button>
      </div>
      <div>
        <h4>Assigned users</h4>
        <ul>
          <li
            v-for="u in task.assigned_users || []"
            :key="u.id"
          >
            {{ u.name }} <button @click.prevent="unassign(u.id)">
              Unassign
            </button>
          </li>
        </ul>
      </div>
      <button
        class="btn-primary"
        @click="save"
      >
        Save
      </button>
      <button @click="del">
        Delete
      </button>
    </div>
  </div>
</template>

<script>
import api from '../services/api'

export default {
  name: 'TaskEdit',
  data() { return { task: null, allSkills: [], selectedSkill: null } },
  async created() { await this.load() },
  methods: {
    async load() {
      const id = this.$route.params.taskId
      const res = await api.get(`/tasks/${id}`)
      this.task = res.data || {}
      const s = await api.get('/skills')
      this.allSkills = s.data || []
    },
    async save() { await api.put(`/tasks/${this.task.id}`, { task: this.task }); await this.load() },
    async del() { await api.delete(`/tasks/${this.task.id}`); this.$router.push('/tasks') },
    async addSkill() { if (!this.selectedSkill) return; await api.post(`/tasks/${this.task.id}/skills`, { skill_id: this.selectedSkill }); await this.load() },
    async unassign(userId) { await api.post(`/tasks/${this.task.id}/unassign`, { user_id: userId }); await this.load() }
  }
}
</script>

<style scoped>
.card{padding:18px}
.field{margin-bottom:8px}
</style>
