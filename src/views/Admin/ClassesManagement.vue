<template>
  <div class="classes-management">
    <h2>班级管理</h2>

    <button @click="showAddClassModal" class="add-btn">添加班级</button>

    <div v-if="classes.length > 0" class="classes-list">
      <table>
        <thead>
        <tr>
          <th>ID</th>
          <th>班级名称</th>
          <th>年级</th>
          <th>班主任</th>
          <th>科目及教师</th>
          <th>操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="classItem in classes" :key="classItem.class_id">
          <td>{{ classItem.class_id }}</td>
          <td>{{ classItem.class_name }}</td>
          <td>{{ classItem.class_grade }}</td>
          <td>{{ getTeacherName(classItem.head_teacher_id) }}</td>
          <td>
            <div v-if="classItem.subject_teacher && classItem.subject_teacher.length > 0">
              <div v-for="(st, index) in classItem.subject_teacher" :key="index">
                {{ getSubjectName(st.subject_id) }} - {{ getTeacherName(st.teacher_id) }}
              </div>
            </div>
            <span v-else class="no-subjects">无科目</span>
          </td>
          <td>
            <button @click="showEditModal(classItem)" class="edit-btn">编辑</button>
            <button @click="deleteClass(classItem.class_id)" class="delete-btn">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <!-- 添加/编辑班级模态框 -->
    <div v-if="showClassModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="closeModal">&times;</span>
        <h2>{{ isEditing ? '编辑班级' : '添加班级' }}</h2>
        <div class="form-group">
          <label>班级名称:</label>
          <input type="text" v-model="currentClass.class_name" required>
        </div>
        <div class="form-group">
          <label>年级:</label>
          <input type="text" v-model="currentClass.class_grade" required>
        </div>
        <div class="form-group">
          <label>班主任:</label>
          <select v-model="currentClass.head_teacher_id" required>
            <option value="">请选择班主任</option>
            <option v-for="teacher in teachers" :key="teacher.user_id" :value="teacher.user_id">
              {{ teacher.user_name }}
            </option>
          </select>
        </div>
        <div class="form-group">
          <label>科目及对应教师:</label>
          <div class="subject-teacher-pairs">
            <div v-for="(pair, index) in currentClass.subject_teacher" :key="index" class="pair-item">
              <div class="subject-select">
                <select v-model="pair.subject_id" @change="updateSubjectSelection(index)" required>
                  <option value="">选择科目</option>
                  <option
                      v-for="subject in availableSubjects(index)"
                      :key="subject.subject_id"
                      :value="subject.subject_id"
                  >
                    {{ subject.subject_name }}
                  </option>
                </select>
              </div>
              <div class="teacher-select">
                <select v-model="pair.teacher_id" :disabled="!pair.subject_id" required>
                  <option value="">选择教师</option>
                  <option
                      v-for="teacher in teachers"
                      :key="teacher.user_id"
                      :value="teacher.user_id"
                  >
                    {{ teacher.user_name }}
                  </option>
                </select>
              </div>
              <button
                  @click="removeSubjectPair(index)"
                  class="remove-pair-btn"
                  v-if="currentClass.subject_teacher.length > 1"
              >
                删除
              </button>
            </div>
            <button @click="addSubjectPair" class="add-pair-btn">添加科目</button>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="saveClass" class="save-btn">{{ isEditing ? '更新' : '保存' }}</button>
          <button @click="closeModal" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'
import adminPower from '@/api/admin.js'
import { ref, onMounted, computed } from 'vue'
import {ElMessage} from "element-plus";

const authStore = useAuthStore()
const token = authStore.user?.token
const classes = ref([])
const allSubjects = ref([])
const teachers = ref([])
const showClassModal = ref(false)
const isEditing = ref(false)
const currentClass = ref({
  class_id: '',
  class_name: '',
  class_grade: '',
  head_teacher_id: '',
  subject_teacher: [{ subject_id: '', teacher_id: '' }] // 与API响应结构保持一致
})

const fetchClasses = async () => {
  try {
    if (!token) {
      console.error('未找到用户token')
      return
    }
    const response = await adminPower.getAllClasses(token)
    classes.value = response.data
  } catch (error) {
    console.error('获取班级列表失败:', error)
  }
}

const availableSubjects = computed(() => (currentIndex) => {
  return allSubjects.value.filter(subject => {
    // 当前已选中的科目在其他位置未被选中
    return !currentClass.value.subject_teacher.some((pair, index) =>
        index !== currentIndex && pair.subject_id === subject.subject_id
    )
  })
})

const fetchAllSubjects = async () => {
  try {
    const response = await adminPower.getAllSubjects(token)
    allSubjects.value = response.data
  } catch (error) {
    console.error('获取科目列表失败:', error)
  }
}

const fetchTeachers = async () => {
  try {
    const response = await adminPower.getAllUsers(token)
    // 过滤出教师角色(假设角色ID 2是教师)
    teachers.value = response.data.filter(user =>
        user.user_roles_id && user.user_roles_id.includes(2)
    )
  } catch (error) {
    console.error('获取教师列表失败:', error)
  }
}

const getTeacherName = (teacherId) => {
  if (!teacherId) return '未分配'
  const teacher = teachers.value.find(t => t.user_id === teacherId)
  return teacher ? teacher.user_name : '未知教师'
}

const getSubjectName = (subjectId) => {
  const subject = allSubjects.value.find(s => s.subject_id === subjectId)
  return subject ? subject.subject_name : '未知科目'
}

const showAddClassModal = async () => {
  await fetchAllSubjects()
  await fetchTeachers()
  currentClass.value = {
    class_id: '',
    class_name: '',
    class_grade: '',
    head_teacher_id: '',
    subject_teacher: [{ subject_id: '', teacher_id: '' }]
  }
  isEditing.value = false
  showClassModal.value = true
}

const showEditModal = async (classItem) => {
  await fetchAllSubjects()
  await fetchTeachers()

  currentClass.value = {
    class_id: classItem.class_id,
    class_name: classItem.class_name,
    class_grade: classItem.class_grade,
    head_teacher_id: classItem.head_teacher_id,
    subject_teacher: classItem.subject_teacher && classItem.subject_teacher.length > 0
        ? [...classItem.subject_teacher]
        : [{ subject_id: '', teacher_id: '' }]
  }

  // 确保每个科目教师对都有正确的结构
  currentClass.value.subject_teacher = currentClass.value.subject_teacher.map(st => ({
    subject_id: st.subject_id || '',
    teacher_id: st.teacher_id || ''
  }))

  isEditing.value = true
  showClassModal.value = true
}

const closeModal = () => {
  showClassModal.value = false
}

const saveClass = async () => {
  try {
    // 验证必填字段
    if (!currentClass.value.class_name || !currentClass.value.class_grade || !currentClass.value.head_teacher_id) {
      ElMessage.error('请填写所有必填字段（班级名称、年级、班主任）')
      return
    }

    // 验证科目教师对
    const invalidPairs = currentClass.value.subject_teacher.some(
        pair => pair.subject_id && !pair.teacher_id
    )
    if (invalidPairs) {
      ElMessage.error('请为所有已选科目选择对应的教师')
      return
    }

    // 检查是否有至少一个有效的科目教师对
    const validPairs = currentClass.value.subject_teacher.filter(
        pair => pair.subject_id && pair.teacher_id
    )

    if (validPairs.length === 0) {
      ElMessage.error('请至少添加一个科目及对应教师')
      return
    }

    // 提取科目ID数组
    const subjects_id = validPairs.map(pair => pair.subject_id)

    if (isEditing.value) {
      // 更新班级
      await adminPower.updateClassInformation(
          token,
          currentClass.value.class_id,
          currentClass.value.class_name,
          currentClass.value.class_grade,
          currentClass.value.head_teacher_id,
          subjects_id,
          validPairs
      )

      // 更新本地数据
      const index = classes.value.findIndex(c => c.class_id === currentClass.value.class_id)
      if (index !== -1) {
        classes.value[index] = {
          ...classes.value[index],
          class_name: currentClass.value.class_name,
          class_grade: currentClass.value.class_grade,
          head_teacher_id: currentClass.value.head_teacher_id,
          subject_teacher: [...validPairs]
        }
      }
      ElMessage.success('班级更新成功')
    } else {
      // 添加新班级
      const response = await adminPower.addOneClass(
          token,
          currentClass.value.class_name,
          currentClass.value.class_grade,
          currentClass.value.head_teacher_id,
          subjects_id,
          validPairs
      )
      if (response.data) {
        classes.value.push(response.data)
        ElMessage.success('班级添加成功')
      }
    }
    closeModal()
    fetchClasses()
    fetchTeachers()
    fetchAllSubjects()
  } catch (error) {
    ElMessage.error(isEditing.value ? '更新班级失败:' : '添加班级失败:', error)
  }
}

const addSubjectPair = () => {
  currentClass.value.subject_teacher.push({ subject_id: '', teacher_id: '' })
}

const removeSubjectPair = (index) => {
  currentClass.value.subject_teacher.splice(index, 1)
}

const updateSubjectSelection = (index) => {
  // 当科目改变时重置教师选择
  currentClass.value.subject_teacher[index].teacher_id = ''
}

const deleteClass = async (classId) => {
  if (confirm('确定要删除这个班级吗？  这将会连同删除班级与学科老师的联结关系，以及该班级所有的在数据库内的成绩')) {
    try {
      await adminPower.deleteClass(token, classId)
      classes.value = classes.value.filter(classItem => classItem.class_id !== classId)
      ElMessage.success('删除班级成功')
    } catch (error) {
      ElMessage.error('删除班级失败:', error)
    }
  }
}

onMounted(() => {
  fetchClasses()
  fetchTeachers()
  fetchAllSubjects()
})
</script>

<style scoped>
.classes-management {
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

.classes-list {
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

.no-subjects {
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
  width: 600px;
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

.form-group input,
.form-group select {
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

.subject-teacher-pairs {
  margin-top: 10px;
}

.pair-item {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
  align-items: center;
}

.subject-select, .teacher-select {
  flex: 1;
}

.subject-select select, .teacher-select select {
  width: 100%;
}

.remove-pair-btn {
  padding: 5px 10px;
  background-color: #e74c3c;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.add-pair-btn {
  padding: 5px 10px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  margin-top: 5px;
}
</style>
