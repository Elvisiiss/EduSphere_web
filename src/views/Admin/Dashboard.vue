<template>
  <div class="admin-dashboard">
    <h1>管理员仪表盘</h1>
    <p>欢迎, {{ authStore.user?.user_name }}</p>
    <p>邮箱: {{ authStore.user?.e_mail }}</p>
    <p>角色: 管理员</p>

    <div class="admin-actions">
      <button @click="viewUsers" class="action-btn">用户管理</button>
      <button @click="goToTeacher" class="action-btn">教师面板</button>
      <button @click="goToStudent" class="action-btn">学生面板</button>
    </div>

    <div v-if="users.length > 0" class="user-list">
      <h2>用户列表</h2>
      <table>
        <thead>
        <tr>
          <th>ID</th>
          <th>用户名</th>
          <th>邮箱</th>
          <th>角色</th>
          <th>操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="user in users" :key="user.id">
          <td>{{ user.id }}</td>
          <td>{{ user.user_name }}</td>
          <td>{{ user.e_mail }}</td>
          <td>{{ getRoleName(user.role_id) }}</td>
          <td>
            <button @click="editUser(user)" class="edit-btn">编辑</button>
            <button @click="deleteUser(user.id)" class="delete-btn">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <button @click="logout" class="logout-btn">退出登录</button>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import userApi from '@/api/user'

const authStore = useAuthStore()
const router = useRouter()
const users = ref([])

const getRoleName = (roleId) => {
  switch (roleId) {
    case 0: return '学生'
    case 1: return '教师'
    case 2: return '管理员'
    default: return '未知'
  }
}

const viewUsers = async () => {
  try {
    const response = await userApi.getAllUsers()
    users.value = response.data
  } catch (error) {
    console.error('获取用户列表失败:', error)
  }
}

const goToTeacher = () => {
  router.push('/teacher')
}

const goToStudent = () => {
  router.push('/student')
}

const editUser = (user) => {
  // 实现编辑用户逻辑
  console.log('编辑用户:', user)
}

const deleteUser = async (userId) => {
  if (confirm('确定要删除这个用户吗？')) {
    try {
      await userApi.deleteUser(userId)
      users.value = users.value.filter(user => user.id !== userId)
    } catch (error) {
      console.error('删除用户失败:', error)
    }
  }
}

const logout = () => {
  authStore.clearUser()
  router.push('/login')
}

onMounted(() => {
  viewUsers()
})
</script>

<style scoped>
.admin-dashboard {
  max-width: 1000px;
  margin: 0 auto;
  padding: 2rem;
}

.admin-actions {
  display: flex;
  gap: 1rem;
  margin: 2rem 0;
}

.action-btn {
  padding: 0.75rem 1.5rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.user-list {
  margin: 2rem 0;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 1rem;
}

th, td {
  border: 1px solid #ddd;
  padding: 0.75rem;
  text-align: left;
}

th {
  background-color: #f8f9fa;
}

.edit-btn {
  padding: 0.25rem 0.5rem;
  background: #17a2b8;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin-right: 0.5rem;
}

.delete-btn {
  padding: 0.25rem 0.5rem;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.logout-btn {
  margin-top: 2rem;
  padding: 0.75rem 1.5rem;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
</style>