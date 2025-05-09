<template>
  <div class="admin-dashboard">
    <h1>管理员仪表盘</h1>
    <p>欢迎, {{ authStore.user?.name }}</p>
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
          <th>学号</th>
          <th>用户名</th>
          <th>邮箱</th>
          <th>角色</th>
          <th>操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="user in users" :key="user.id">
          <td>{{ user.user_id }}</td>
          <td>{{ user.user_number }}</td>
          <td>{{ user.user_name }}</td>
          <td>{{ user.user_email }}</td>
          <td>{{ user.user_roles }}</td>
          <td>
            <button @click="showEditModal(user)" class="edit-btn">编辑</button>
            <button @click="deleteUser(user.id)" class="delete-btn">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <!-- 编辑用户模态框 -->
    <div v-if="showModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="closeModal">&times;</span>
        <h2>编辑用户</h2>
        <div class="form-group">
          <label>用户ID:</label>
          <input type="text" v-model="currentUser.user_id" disabled>
        </div>
        <div class="form-group">
          <label>用户名:</label>
          <input type="text" v-model="currentUser.user_name">
        </div>
        <div class="form-group">
          <label>邮箱:</label>
          <input type="email" v-model="currentUser.user_email">
        </div>
        <div class="form-group">
          <label>密码:</label>
          <input
              type="text"
              v-model="currentUser.user_password"
              :placeholder="!currentUser.user_password ? '如果内容为空则表示不修改密码' : ''"
          >
        </div>
        <div class="form-group">
          <label>Token:</label>
          <input type="text" v-model="currentUser.user_token" disabled>
        </div>
        <div class="modal-actions">
          <button @click="saveUser" class="save-btn">保存</button>
          <button @click="closeModal" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>

    <button @click="logout" class="logout-btn">退出登录</button>
  </div>
</template>

<script setup>
import {onMounted, ref} from 'vue'
import {useRouter} from 'vue-router'
import {useAuthStore} from '@/stores/auth'
import adminPower from '@/api/admin.js'

const authStore = useAuthStore()
const router = useRouter()
const users = ref([])
const token = authStore.user?.token
const showModal = ref(false)
const currentUser = ref({
  user_id: '',
  user_number:'',
  user_name: '',
  user_email: '',
  user_password: '',
  user_token: ''
})

const viewUsers = async () => {
  try {
    if (!token) {
      console.error('未找到用户token')
      return
    }
    const response = await adminPower.getAllUsers(token)
    users.value = response.data
  } catch (error) {
    console.error('获取用户列表失败:', error)
  }
}

const showEditModal = async (user) => {
  try {
    const response = await adminPower.getUserByUserId(token, user.user_id)
    currentUser.value = response
    console.log(response)
    showModal.value = true
    if (response) {
      currentUser.value = {
        user_id: response.data.user_id || '',
        user_number: response.data.user_number || '',
        user_name: response.data.user_name || '',
        user_email: response.data.user_email || '',
        user_password:'',
        user_token: response.data.user_token || ''
      };
      showModal.value = true;
    }
  } catch (error) {
    console.error('获取用户详情失败:', error)
  }
}

const closeModal = () => {
  showModal.value = false
}

const saveUser = async () => {
  try {
    await adminPower.updateUser(token, currentUser.value.user_id, currentUser.value.user_number, currentUser.value.user_name, currentUser.value.user_email, currentUser.value.user_password)
    // 更新本地用户列表
    const index = users.value.findIndex(u => u.user_id === currentUser.value.user_id)
    if (index !== -1) {
      users.value[index].user_number = currentUser.value.user_number
      users.value[index].user_name = currentUser.value.user_name
      users.value[index].user_email = currentUser.value.user_email
    }
    closeModal()
  } catch (error) {
    console.error('更新用户失败:', error)
  }
}

const goToTeacher = () => {
  router.push('/teacher')
}

const goToStudent = () => {
  router.push('/student')
}

const deleteUser = async (userId) => {
  if (confirm('确定要删除这个用户吗？')) {
    try {
      await adminPower.deleteUser(token, userId)
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
  position: relative;
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

/* 模态框样式 */
.modal {
  display: block;
  position: fixed;
  z-index: 1;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.4);
}

.modal-content {
  background-color: #fefefe;
  margin: 10% auto;
  padding: 20px;
  border: 1px solid #888;
  width: 50%;
  border-radius: 8px;
}

.close {
  color: #aaa;
  float: right;
  font-size: 28px;
  font-weight: bold;
  cursor: pointer;
}

.close:hover {
  color: black;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.form-group input {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.form-group input:disabled {
  background-color: #f5f5f5;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1rem;
}

.save-btn {
  padding: 0.5rem 1rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.cancel-btn {
  padding: 0.5rem 1rem;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
</style>