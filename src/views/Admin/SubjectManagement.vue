<template>
  <div class="subject-management">
    <h2>科目管理</h2>

    <button @click="showAddSubjectModal" class="add-btn">添加科目</button>

    <div v-if="subjects.length > 0" class="subject-list">
      <table>
        <thead>
        <tr>
          <th>ID</th>
          <th>科目名称</th>
          <th>科目描述</th>
          <th>操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="subject in subjects" :key="subject.subject_id">
          <td>{{ subject.subject_id }}</td>
          <td>{{ subject.subject_name }}</td>
          <td>{{ subject.subject_desc }}</td>
          <td>
            <button @click="showEditModal(subject)" class="edit-btn">编辑</button>
            <button @click="deleteSubject(subject.subject_id)" class="delete-btn">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <!-- 添加/编辑科目模态框 -->
    <div v-if="showSubjectModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="closeModal">&times;</span>
        <h2>{{ isEditing ? '编辑科目' : '添加科目' }}</h2>
        <div class="form-group">
          <label>科目名称:</label>
          <input type="text" v-model="currentSubject.subject_name">
        </div>
        <div class="form-group">
          <label>科目描述:</label>
          <input type="text" v-model="currentSubject.subject_desc">
        </div>
        <div class="modal-actions">
          <button @click="saveSubject" class="save-btn">{{ isEditing ? '更新' : '保存' }}</button>
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
const subjects = ref([])
const showSubjectModal = ref(false)
const isEditing = ref(false)
const currentSubject = ref({
  subject_id: '',
  subject_name: '',
  subject_desc: ''
})

const fetchSubjects = async () => {
  try {
    if (!token) {
      console.error('未找到用户token')
      return
    }
    const response = await adminPower.getAllSubjects(token)
    subjects.value = response.data
  } catch (error) {
    console.error('获取科目列表失败:', error)
  }
}

const showAddSubjectModal = () => {
  currentSubject.value = {
    subject_id: '',
    subject_name: '',
    subject_desc: ''
  }
  isEditing.value = false
  showSubjectModal.value = true
}

const showEditModal = (subject) => {
  currentSubject.value = {
    subject_id: subject.subject_id,
    subject_name: subject.subject_name,
    subject_desc: subject.subject_desc
  }
  isEditing.value = true
  showSubjectModal.value = true
}

const closeModal = () => {
  showSubjectModal.value = false
}

const saveSubject = async () => {
  try {
    if (isEditing.value) {
      // 更新科目
      await adminPower.updateSubject(
          token,
          currentSubject.value.subject_id,
          currentSubject.value.subject_name,
          currentSubject.value.subject_desc
      )

      // 更新本地数据
      const index = subjects.value.findIndex(s => s.subject_id === currentSubject.value.subject_id)
      if (index !== -1) {
        subjects.value[index] = { ...currentSubject.value }
      }
    } else {
      // 添加新科目
      const response = await adminPower.addOneSubject(
          token,
          currentSubject.value.subject_name,
          currentSubject.value.subject_desc
      )
      if (response.data) {
        subjects.value.push(response.data)
      }
    }
    closeModal()
  } catch (error) {
    console.error(isEditing.value ? '更新科目失败:' : '添加科目失败:', error)
  }
}

const deleteSubject = async (subjectId) => {
  if (confirm('确定要删除这个科目吗？')) {
    try {
      await adminPower.deleteSubject(token, subjectId)
      subjects.value = subjects.value.filter(subject => subject.subject_id !== subjectId)
    } catch (error) {
      console.error('删除科目失败:', error)
    }
  }
}

onMounted(() => {
  fetchSubjects()
})
</script>

<style scoped>
.subject-management {
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

.subject-list {
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

.form-group input {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 3px;
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
