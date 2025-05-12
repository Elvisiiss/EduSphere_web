<template>
  <div class="user-management">
    <h2>用户管理</h2>

    <button @click="showAddUserModal" class="add-btn">添加用户</button>

    <div v-if="users.length > 0" class="user-list">
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
        <tr v-for="user in users" :key="user.user_id">
          <td>{{ user.user_id }}</td>
          <td>{{ user.user_number }}</td>
          <td>{{ user.user_name }}</td>
          <td>{{ user.user_email }}</td>
          <td>
              <span v-if="user.user_roles_id && user.user_roles_id.length > 0">
                {{ getRoleNames(user.user_roles_id) }}
              </span>
            <span v-else class="no-roles">无角色</span>
          </td>
          <td>
            <button @click="showEditModal(user)" class="edit-btn">编辑</button>
            <button @click="showEditRolesModal(user)" class="roles-btn">角色</button>
            <button @click="deleteUser(user.user_id)" class="delete-btn">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <!-- 添加/编辑用户模态框 -->
    <div v-if="showUserModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="closeModal">&times;</span>
        <h2>{{ isEditing ? '编辑用户' : '添加用户' }}</h2>
        <div class="form-group">
          <label>学号:</label>
          <input type="text" v-model="currentUser.user_number">
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
              v-if="isEditing"
              type="text"
              v-model="currentUser.user_password"
              placeholder="留空则不修改密码"
          >
          <input
              v-else
              type="text"
              disabled
              placeholder="密码默认为学号"
          >
        </div>
        <div class="modal-actions">
          <button @click="saveUser" class="save-btn">{{ isEditing ? '更新' : '保存' }}</button>
          <button @click="closeModal" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>

    <!-- 编辑用户角色模态框 -->
    <div v-if="showRolesModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="closeModal">&times;</span>
        <h2>编辑用户角色</h2>
        <div class="form-group">
          <label>用户名:</label>
          <input type="text" v-model="currentUser.user_name" disabled>
        </div>
        <div class="form-group">
          <label>角色:</label>
          <div class="role-checkboxes">
            <div v-for="role in allRoles" :key="role.role_id" class="checkbox-item">
              <input
                  type="checkbox"
                  :id="'role_' + role.role_id"
                  :value="role.role_id"
                  v-model="currentUser.selectedRoles"
              >
              <label :for="'role_' + role.role_id">{{ role.role_name }}</label>
            </div>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="saveUserRoles" class="save-btn">保存</button>
          <button @click="closeModal" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import adminPower from '@/api/admin.js'

const authStore = useAuthStore()
const token = authStore.user?.token
const users = ref([])
const allRoles = ref([])
const showUserModal = ref(false)
const showRolesModal = ref(false)
const isEditing = ref(false)
const currentUser = ref({
  user_id: '',
  user_number: '',
  user_name: '',
  user_email: '',
  user_password: '',
  selectedRoles: []
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

const fetchAllRoles = async () => {
  try {
    const response = await adminPower.getAllRoles(token)
    if (response.data) {
      allRoles.value = response.data
    }
  } catch (error) {
    console.error('获取角色列表失败:', error)
  }
}

// 根据角色ID数组获取角色名称
const getRoleNames = (roleIds) => {
  return roleIds.map(roleId => {
    const role = allRoles.value.find(r => r.role_id === roleId)
    return role ? role.role_name : '未知角色'
  }).join(', ')
}

const showAddUserModal = () => {
  currentUser.value = {
    user_id: '',
    user_number: '',
    user_name: '',
    user_email: '',
    user_password: '',
    selectedRoles: []
  }
  isEditing.value = false
  showUserModal.value = true
}

const showEditModal = (user) => {
  currentUser.value = {
    user_id: user.user_id,
    user_number: user.user_number,
    user_name: user.user_name,
    user_email: user.user_email,
    user_password: '',
    selectedRoles: user.user_roles_id ? [...user.user_roles_id] : []
  }
  isEditing.value = true
  showUserModal.value = true
}

const showEditRolesModal = (user) => {
  currentUser.value = {
    user_id: user.user_id,
    user_number: user.user_number,
    user_name: user.user_name,
    user_email: user.user_email,
    user_password: '',
    selectedRoles: user.user_roles_id ? [...user.user_roles_id] : []
  }
  showRolesModal.value = true
}

const closeModal = () => {
  showUserModal.value = false
  showRolesModal.value = false
}

const saveUser = async () => {
  try {
    if (isEditing.value) {
      // 更新用户
      await adminPower.updateUser(
          token,
          currentUser.value.user_id,
          currentUser.value.user_number,
          currentUser.value.user_name,
          currentUser.value.user_email,
          currentUser.value.user_password
      )

      // 更新本地数据
      const index = users.value.findIndex(u => u.user_id === currentUser.value.user_id)
      if (index !== -1) {
        users.value[index].user_number = currentUser.value.user_number
        users.value[index].user_name = currentUser.value.user_name
        users.value[index].user_email = currentUser.value.user_email
      }
    } else {
      // 添加新用户
      const response = await adminPower.addOneUser(
          token,
          currentUser.value.user_name,
          currentUser.value.user_email,
          currentUser.value.user_number,
          currentUser.value.selectedRoles,
          currentUser.value.user_password
      )
      if (response.data) {
        // 添加新用户到列表
        const newUser = {
          ...response.data,
          user_roles_id: [...currentUser.value.selectedRoles]
        }
        users.value.push(newUser)
      }
    }
    closeModal()
  } catch (error) {
    console.error(isEditing.value ? '更新用户失败:' : '添加用户失败:', error)
  }
}

const saveUserRoles = async () => {
  try {
    // 更新用户角色
    await adminPower.updateUserRole(
        token,
        currentUser.value.user_id,
        currentUser.value.selectedRoles
    )

    // 更新本地数据
    const index = users.value.findIndex(u => u.user_id === currentUser.value.user_id)
    if (index !== -1) {
      users.value[index].user_roles_id = [...currentUser.value.selectedRoles]
    }
    closeModal()
  } catch (error) {
    console.error('更新用户角色失败:', error)
  }
}

const deleteUser = async (userId) => {
  if (confirm('确定要删除这个用户吗？')) {
    try {
      await adminPower.deleteUser(token, userId)
      users.value = users.value.filter(user => user.user_id !== userId)
    } catch (error) {
      console.error('删除用户失败:', error)
    }
  }
}

onMounted(() => {
  viewUsers()
  fetchAllRoles()
})
</script>

<style scoped>
.user-management {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.add-btn {
  padding: 8px 15px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  margin-bottom: 20px;
}

.user-list {
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

.no-roles {
  color: #999;
  font-style: italic;
}

.edit-btn {
  padding: 5px 10px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  margin-right: 5px;
}

.roles-btn {
  padding: 5px 10px;
  background-color: #9b59b6;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  margin-right: 5px;
}

.delete-btn {
  padding: 5px 10px;
  background-color: #e74c3c;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  width: 500px;
  max-width: 90%;
}

.close {
  float: right;
  font-size: 24px;
  cursor: pointer;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
}

.form-group input {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 3px;
}

.form-group input:disabled {
  background-color: #f5f5f5;
}

.role-checkboxes {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 10px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 5px;
  min-width: 150px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

.save-btn {
  padding: 8px 15px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  margin-right: 10px;
}

.cancel-btn {
  padding: 8px 15px;
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}
</style>
