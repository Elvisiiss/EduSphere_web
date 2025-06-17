<template>
  <div class="power-management">
    <h2>权限管理</h2>

    <div v-if="powers.length > 0" class="power-list">
      <table>
        <thead>
        <tr>
          <th>ID</th>
          <th>权限名称</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="power in powers" :key="power.power_id">
          <td>{{ power.power_id }}</td>
          <td>{{ power.power_name }}</td>
        </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import adminPower from '@/api/admin.js'

const authStore = useAuthStore()
const token = authStore.user?.token
const powers = ref([])

const fetchPowers = async () => {
  try {
    if (!token) {
      console.error('未找到用户token')
      return
    }
    const response = await adminPower.getAllPowers(token)
    powers.value = response.data
  } catch (error) {
    console.error('获取权限列表失败:', error)
  }
}

onMounted(() => {
  fetchPowers()
})
</script>

<style scoped>
.power-management {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.power-list {
  margin-top: 20px;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
}

th {
  background-color: #f2f2f2;
}
</style>
