<template>
  <div class="role-management">
    <h2>角色管理</h2>

    <button @click="showAddRoleModal" class="add-btn">添加角色</button>

    <div v-if="roles.length > 0" class="role-list">
      <table>
        <thead>
        <tr>
          <th>ID</th>
          <th>角色名称</th>
          <th>权限列表</th>
          <th>操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="role in roles" :key="role.role_id">
          <td>{{ role.role_id }}</td>
          <td>{{ role.role_name }}</td>
          <td>
              <span v-if="role.powers && role.powers.length > 0">
                {{ getPowerNames(role.powers) }}
              </span>
            <span v-else class="no-powers">无权限</span>
          </td>
          <td>
            <button @click="showEditModal(role)" class="edit-btn">编辑</button>
            <button @click="deleteRole(role.role_id)" class="delete-btn">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <!-- 添加/编辑角色模态框 -->
    <div v-if="showModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="closeModal">&times;</span>
        <h2>{{ isEditing ? '编辑角色' : '添加角色' }}</h2>
        <div class="form-group">
          <label>角色名称:</label>
          <input type="text" v-model="currentRole.role_name" :class="{ 'input-error': nameError }">
          <span v-if="nameError" class="error-message">角色名称不能为空</span>
        </div>
        <div class="form-group">
          <label>权限:</label>
          <div class="power-checkboxes">
            <div v-for="power in allPowers" :key="power.power_id" class="checkbox-item">
              <input
                  type="checkbox"
                  :id="'power_' + power.power_id"
                  :value="power.power_id"
                  v-model="currentRole.selectedPowers"
              >
              <label :for="'power_' + power.power_id">{{ power.power_name }}</label>
            </div>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="saveRole" class="save-btn">{{ isEditing ? '更新' : '保存' }}</button>
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
import {ElMessage} from "element-plus";

const authStore = useAuthStore()
const token = authStore.user?.token
const roles = ref([])
const allPowers = ref([])
const showModal = ref(false)
const isEditing = ref(false)
const currentRole = ref({
  role_id: '',
  role_name: '',
  selectedPowers: []
})
const nameError = ref(false)

const fetchRoles = async () => {
  try {
    if (!token) {
      ElMessage.error('未找到用户token')
      return
    }
    const response = await adminPower.getAllRoles(token)
    if (response.data) {
      roles.value = response.data
    }
  } catch (error) {
    ElMessage.error('获取角色列表失败:', error)
  }
}

const fetchAllPowers = async () => {
  try {
    const response = await adminPower.getAllPowers(token)
    if (response.data) {
      allPowers.value = response.data
    }
  } catch (error) {
    ElMessage.error('获取权限列表失败:', error)
  }
}

// 根据权限ID数组获取权限名称
const getPowerNames = (powerIds) => {
  return powerIds.map(powerId => {
    const power = allPowers.value.find(p => p.power_id === powerId)
    return power ? power.power_name : '未知权限'
  }).join(', ')
}

const showAddRoleModal = () => {
  nameError.value = false
  currentRole.value = {
    role_id: '',
    role_name: '',
    selectedPowers: []
  }
  isEditing.value = false
  showModal.value = true
}

const showEditModal = (role) => {
  nameError.value = false
  currentRole.value = {
    role_id: role.role_id,
    role_name: role.role_name,
    selectedPowers: role.powers ? [...role.powers] : []
  }
  isEditing.value = true
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

const saveRole = async () => {
  if (!currentRole.value.role_name || currentRole.value.role_name.trim() === '') {
    nameError.value = true
    ElMessage.error('角色名称不能为空')
    return
  }
  nameError.value = false
  try {
    if (isEditing.value) {
      // 更新角色
      await adminPower.updateRole(
          token,
          currentRole.value.role_name,
          currentRole.value.role_id,
          currentRole.value.selectedPowers
      )

      // 更新本地数据
      const index = roles.value.findIndex(r => r.role_id === currentRole.value.role_id)
      if (index !== -1) {
        roles.value[index].role_name = currentRole.value.role_name
        roles.value[index].powers = [...currentRole.value.selectedPowers]
      }
    } else {
      // 添加新角色
      const response = await adminPower.addOneRole(
          token,
          currentRole.value.role_name,
          currentRole.value.selectedPowers
      )
      if (response.data) {
        // 添加新角色到列表
        const newRole = {
          ...response.data,
          powers: [...currentRole.value.selectedPowers]
        }
        roles.value.push(newRole)
      }
    }
    closeModal()
    fetchRoles()
    fetchAllPowers()
    ElMessage.success(isEditing.value ? '更新角色成功' : '添加角色成功')
  } catch (error) {
    ElMessage.error(isEditing.value ? '更新角色失败:' : '添加角色失败:', error)
  }
}

const deleteRole = async (roleId) => {
  if (confirm('确定要删除这个角色吗？')) {
    try {
      await adminPower.deleteRole(token, roleId)
      roles.value = roles.value.filter(role => role.role_id !== roleId)
      ElMessage.success('删除角色成功')
    } catch (error) {
      ElMessage.error('删除角色失败:', error)
    }
  }
}

onMounted(() => {
  fetchRoles()
  fetchAllPowers()
})
</script>

<style scoped>
.role-management {
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

.role-list {
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

.no-powers {
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

.form-group input[type="text"] {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 3px;
}

.power-checkboxes {
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

.input-error {
  border-color: #e74c3c !important;
}

.error-message {
  color: #e74c3c;
  font-size: 12px;
  display: block;
  margin-top: 5px;
}
</style>
