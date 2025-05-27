<template>
  <div class="class-students">
    <div class="header">
      <h2>{{ classInfo.className }} - 学生管理</h2>
      <div class="header-actions">
        <button @click="goBack" class="back-btn">返回班级管理</button>
        <button @click="showAddStudentModal" class="add-btn">添加学生</button>
      </div>
    </div>

    <div v-if="loading" class="loading">
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error">
      <p>加载失败: {{ error }}</p>
      <button @click="fetchClassData" class="retry-btn">重试</button>
    </div>

    <div v-else class="student-list-container">
      <div class="search-bar">
        <input
            type="text"
            v-model="searchQuery"
            placeholder="搜索学生姓名或学号"
            @input="filterStudents"
            class="search-input"
        >
        <span class="student-count">共 {{ filteredStudents.length }} 名学生</span>
      </div>

      <div v-if="filteredStudents.length > 0" class="student-list">
        <table>
          <thead>
          <tr>
            <th>学号</th>
            <th>姓名</th>
            <th>性别</th>
            <th>联系电话</th>
            <th>入学日期</th>
            <th>操作</th>
          </tr>
          </thead>
          <tbody>
          <tr v-for="student in filteredStudents" :key="student.studentId">
            <td>{{ student.studentNumber }}</td>
            <td>{{ student.studentName }}</td>
            <td>{{ student.gender === 'W' ? '女' : '男' }}</td>
            <td>{{ student.phone || '--' }}</td>
            <td>{{ formatDate(student.enrollmentDate) }}</td>
            <td>
              <button @click="viewStudentDetails(student)" class="view-btn">查看</button>
              <button @click="editStudent(student)" class="edit-btn">编辑</button>
              <button @click="confirmDeleteStudent(student.studentId)" class="delete-btn">删除</button>
            </td>
          </tr>
          </tbody>
        </table>
      </div>

      <div v-else class="no-students">
        <p>没有找到匹配的学生</p>
      </div>
    </div>

    <!-- 学生详情模态框 -->
    <div v-if="selectedStudent" class="modal" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>学生详情 - {{ selectedStudent.studentName }}</h3>
          <button @click="closeModal" class="close-btn">&times;</button>
        </div>

        <div class="modal-body">
          <div class="student-info">
            <div class="info-row">
              <span class="info-label">学号:</span>
              <span class="info-value">{{ selectedStudent.studentNumber }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">姓名:</span>
              <span class="info-value">{{ selectedStudent.studentName }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">性别:</span>
              <span class="info-value">{{ selectedStudent.gender === 'M' ? '男' : '女' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">出生日期:</span>
              <span class="info-value">{{ formatDate(selectedStudent.birthDate) }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">联系电话:</span>
              <span class="info-value">{{ selectedStudent.phone || '--' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">邮箱:</span>
              <span class="info-value">{{ selectedStudent.email || '--' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">家庭住址:</span>
              <span class="info-value">{{ selectedStudent.address || '--' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">入学日期:</span>
              <span class="info-value">{{ formatDate(selectedStudent.enrollmentDate) }}</span>
            </div>
          </div>

          <div class="student-scores">
            <h4>成绩概览</h4>
            <div v-if="studentScores.length > 0" class="score-summary">
              <div v-for="subject in subjects" :key="subject.subject_id" class="subject-score">
                <span class="subject-name">{{ subject.subject_name }}:</span>
                <span :class="getScoreClass(getLatestScore(subject.subject_id))">
                  {{ getLatestScore(subject.subject_id) || '--' }}
                </span>
              </div>
            </div>
            <div v-else class="no-scores">
              <p>暂无成绩记录</p>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="closeModal" class="close-btn">关闭</button>
        </div>
      </div>
    </div>

    <!-- 修改后的添加学生模态框 -->
    <div v-if="showStudentModal" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>添加学生到班级</h3>
          <button @click="closeStudentModal" class="close-btn">&times;</button>
        </div>

        <div class="modal-body">
          <!-- 搜索和添加现有学生部分 -->
          <div class="add-existing-student">
            <div class="search-add">
              <input
                  type="text"
                  v-model="studentSearchQuery"
                  placeholder="搜索学生姓名或学号"
                  @input="searchNonClassStudents"
                  class="search-input"
              >
              <button @click="searchNonClassStudents" class="search-btn">搜索</button>
            </div>

            <div class="student-selector">
              <div v-if="nonClassStudentsLoading" class="loading-small">
                <p>加载中...</p>
              </div>
              <div v-else-if="nonClassStudentsError" class="error-small">
                <p>{{ nonClassStudentsError }}</p>
              </div>
              <div v-else>
                <table class="student-select-table">
                  <thead>
                  <tr>
                    <th>选择</th>
                    <th>学号</th>
                    <th>姓名</th>
                    <th>邮箱</th>
                  </tr>
                  </thead>
                  <tbody>
                  <tr v-for="student in nonClassStudents" :key="student.user_id">
                    <td>
                      <input
                          type="checkbox"
                          v-model="selectedStudents"
                          :value="student.user_id"
                      >
                    </td>
                    <td>{{ student.user_number }}</td>
                    <td>{{ student.user_name }}</td>
                    <td>{{ student.user_email }}</td>
                  </tr>
                  </tbody>
                </table>

                <div v-if="nonClassStudents.length === 0" class="no-students">
                  <p>没有找到匹配的学生</p>
                </div>

                <div class="pagination">
                  <button
                      @click="prevPage"
                      :disabled="currentPage === 1"
                      class="page-btn"
                  >
                    上一页
                  </button>
                  <span>第 {{ currentPage }} 页</span>
                  <button
                      @click="nextPage"
                      :disabled="nonClassStudents.length < pageSize"
                      class="page-btn"
                  >
                    下一页
                  </button>
                </div>
              </div>
            </div>

            <div class="selected-actions">
              <button
                  @click="addSelectedStudents"
                  :disabled="selectedStudents.length === 0"
                  class="add-selected-btn"
              >
                添加选中学生 ({{ selectedStudents.length }})
              </button>
            </div>
          </div>

          <div v-if="errorMessage" class="error-message">
            {{ errorMessage }}
          </div>
        </div>

        <div class="modal-footer">
          <button @click="closeStudentModal" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>

    <!-- 删除确认模态框 -->
    <div v-if="showDeleteModal" class="modal">
      <div class="modal-content">
        <h2>确认删除</h2>
        <p>确定要删除这名学生吗？此操作无法撤销。</p>
        <div class="modal-actions">
          <button @click="deleteStudent" class="delete-btn">删除</button>
          <button @click="cancelDelete" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import teacherApi from '@/api/teacher.js'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const token = authStore.user?.token
const classId = route.params.classId

const nonClassStudents = ref([])
const nonClassStudentsLoading = ref(false)
const nonClassStudentsError = ref(null)
const studentSearchQuery = ref('')
const selectedStudents = ref([])
const currentPage = ref(1)
const pageSize = ref(10)
const totalStudents = ref(0)

const loading = ref(true)
const error = ref(null)
const classInfo = ref({})
const students = ref([])
const filteredStudents = ref([])
const subjects = ref([])
const studentScores = ref([])
const searchQuery = ref('')
const selectedStudent = ref(null)
const showStudentModal = ref(false)
const isEditing = ref(false)
const currentStudent = ref({
  studentId: '',
  studentNumber: '',
  studentName: '',
  gender: 'M',
  birthDate: '',
  phone: '',
  email: '',
  address: '',
  enrollmentDate: new Date().toISOString().split('T')[0]
})
const showDeleteModal = ref(false)
const studentToDelete = ref(null)
const errorMessage = ref('')

const fetchClassData = async () => {
  try {
    loading.value = true
    error.value = null

    // 获取班级信息 - 添加parseInt确保类型一致
    const classResponse = await teacherApi.getTeacherClasses(token)
    if (classResponse.data) {
      const foundClass = classResponse.data.find(c => c.classId === parseInt(classId))
      if (foundClass) {
        classInfo.value = foundClass
        subjects.value = foundClass.subjects
      }
    }

    // 获取学生列表 - 确保传递正确的classId
    const studentsResponse = await teacherApi.getClassStudents(token, parseInt(classId))
    if (studentsResponse.data) {
      students.value = studentsResponse.data
      filteredStudents.value = [...students.value]
    }
  } catch (err) {
    console.error('获取班级数据失败:', err)
    error.value = err.message || '获取班级数据失败'
  } finally {
    loading.value = false
  }
}

const fetchNonClassStudents = async () => {
  try {
    nonClassStudentsLoading.value = true
    nonClassStudentsError.value = null

    const response = await teacherApi.getNonClassStudents(
        token,
        parseInt(classId),
        currentPage.value,
        pageSize.value,
        studentSearchQuery.value
    )

    // 直接使用响应数组
    nonClassStudents.value = response.data
    totalStudents.value = response.data.length
  } catch (err) {
    console.error('获取非本班学生失败:', err)
    nonClassStudentsError.value = err.message || '获取学生列表失败'
  } finally {
    nonClassStudentsLoading.value = false
  }
}

const searchNonClassStudents = () => {
  currentPage.value = 1
  fetchNonClassStudents()
}

// 分页控制
const nextPage = () => {
  currentPage.value++
  fetchNonClassStudents()
}

const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
    fetchNonClassStudents()
  }
}

// 添加选中的学生
const addSelectedStudents = async () => {
  try {
    loading.value = true
    errorMessage.value = ''

    // 调用API添加学生到班级
    await teacherApi.addStudentsToClass(
        token,
        parseInt(classId),
        selectedStudents.value
    )

    // 刷新学生列表
    await fetchClassData()
    selectedStudents.value = []
    studentSearchQuery.value = ''
    fetchNonClassStudents()
  } catch (err) {
    console.error('添加学生失败:', err)
    errorMessage.value = err.message || '添加学生失败'
  } finally {
    loading.value = false
  }
}

const filterStudents = () => {
  if (!searchQuery.value) {
    filteredStudents.value = [...students.value]
    return
  }

  const query = searchQuery.value.toLowerCase()
  filteredStudents.value = students.value.filter(student =>
      student.studentName.toLowerCase().includes(query) ||
      student.studentNumber.toLowerCase().includes(query))
}

const viewStudentDetails = async (student) => {
  selectedStudent.value = student
  try {
    // 获取学生所有科目成绩
    const response = await teacherApi.getStudentAllScores(token, student.studentId)
    if (response.data) {
      studentScores.value = response.data
    }
  } catch (err) {
    console.error('获取学生成绩失败:', err)
    errorMessage.value = '获取学生成绩失败'
  }
}

const getLatestScore = (subjectId) => {
  const subjectScores = studentScores.value
      .filter(score => score.subject_id === subjectId)
      .sort((a, b) => new Date(b.examDate) - new Date(a.examDate))

  return subjectScores.length > 0 ? subjectScores[0].score : null
}

// 修改showAddStudentModal函数
const showAddStudentModal = () => {
  currentStudent.value = {
    studentId: '',
    studentNumber: '',
    studentName: '',
    gender: 'M',
    birthDate: '',
    phone: '',
    email: '',
    address: '',
    enrollmentDate: new Date().toISOString().split('T')[0]
  }
  isEditing.value = false
  errorMessage.value = ''
  showStudentModal.value = true

  // 加载非本班学生
  fetchNonClassStudents()
}

const editStudent = (student) => {
  currentStudent.value = {
    ...student,
    birthDate: student.birthDate ? student.birthDate.split('T')[0] : '',
    enrollmentDate: student.enrollmentDate ? student.enrollmentDate.split('T')[0] : ''
  }
  isEditing.value = true
  errorMessage.value = ''
  showStudentModal.value = true
}

const closeStudentModal = () => {
  showStudentModal.value = false
}

const saveStudent = async () => {
  // 验证表单
  if (!currentStudent.value.studentNumber || !currentStudent.value.studentName ||
      !currentStudent.value.gender || !currentStudent.value.birthDate ||
      !currentStudent.value.enrollmentDate) {
    errorMessage.value = '请填写所有必填字段'
    return
  }

  try {
    if (isEditing.value) {
      // 更新学生信息
      await teacherApi.updateStudentInfo(token, currentStudent.value.studentId, {
        studentName: currentStudent.value.studentName,
        gender: currentStudent.value.gender,
        birthDate: currentStudent.value.birthDate,
        phone: currentStudent.value.phone,
        email: currentStudent.value.email,
        address: currentStudent.value.address,
        enrollmentDate: currentStudent.value.enrollmentDate
      })
    } else {
      // 添加新学生
      await teacherApi.addStudentToClass(token, classId, currentStudent.value)
    }

    closeStudentModal()
    await fetchClassData()
  } catch (err) {
    console.error(isEditing.value ? '更新学生信息失败:' : '添加学生失败:', err)
    errorMessage.value = err.message || (isEditing.value ? '更新学生信息失败' : '添加学生失败')
  }
}

const confirmDeleteStudent = (studentId) => {
  studentToDelete.value = studentId
  showDeleteModal.value = true
}

const cancelDelete = () => {
  studentToDelete.value = null
  showDeleteModal.value = false
}

const deleteStudent = async () => {
  try {
    await teacherApi.removeStudentFromClass(token, classId, studentToDelete.value)
    await fetchClassData()
    showDeleteModal.value = false
    studentToDelete.value = null
  } catch (err) {
    console.error('删除学生失败:', err)
    errorMessage.value = '删除学生失败'
  }
}

const closeModal = () => {
  selectedStudent.value = null
}

const getScoreClass = (score) => {
  if (score == null) return ''
  if (score >= 90) return 'excellent'
  if (score >= 80) return 'good'
  if (score >= 60) return 'average'
  return 'poor'
}

const formatDate = (dateString) => {
  if (!dateString) return '--'
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN')
}

const goBack = () => {
  router.push({ name: 'TeacherDashboard' })
}

onMounted(() => {
  fetchClassData()
})
</script>

<style scoped>
.class-students {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  min-height: 70vh;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.back-btn {
  padding: 8px 16px;
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.add-btn {
  padding: 8px 16px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.loading, .error, .no-students {
  margin-top: 20px;
  padding: 20px;
  text-align: center;
  background-color: #f9f9f9;
  border-radius: 5px;
}

.error {
  color: #e74c3c;
}

.retry-btn {
  margin-top: 10px;
  padding: 8px 16px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.search-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.search-input {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  width: 300px;
}

.student-count {
  color: #7f8c8d;
  font-size: 0.9rem;
}

.student-list {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  border: 1px solid #ddd;
  padding: 12px;
  text-align: left;
}

th {
  background-color: #f2f2f2;
  position: sticky;
  top: 0;
}

.view-btn, .edit-btn, .delete-btn {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin-right: 5px;
}

.view-btn {
  background-color: #3498db;
  color: white;
}

.edit-btn {
  background-color: #f39c12;
  color: white;
}

.delete-btn {
  background-color: #e74c3c;
  color: white;
}

/* 模态框样式 */
.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background-color: white;
  border-radius: 8px;
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 20px rgba(0,0,0,0.2);
}

.modal-header {
  padding: 20px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #777;
}

.modal-body {
  padding: 20px;
}

.student-info {
  margin-bottom: 20px;
}

.info-row {
  display: flex;
  margin-bottom: 10px;
}

.info-label {
  font-weight: bold;
  min-width: 100px;
  color: #555;
}

.info-value {
  flex: 1;
}

.student-scores {
  margin-top: 20px;
}

.student-scores h4 {
  margin-bottom: 15px;
  color: #2c3e50;
}

.score-summary {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
}

.subject-score {
  display: flex;
  justify-content: space-between;
  padding: 8px;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.subject-name {
  color: #555;
}

.modal-footer {
  padding: 15px 20px;
  border-top: 1px solid #eee;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

/* 表单样式 */
.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
  color: #555;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.error-message {
  color: #e74c3c;
  margin-top: 15px;
}

/* 成绩颜色样式 */
.excellent {
  color: #27ae60;
  font-weight: bold;
}

.good {
  color: #2980b9;
}

.average {
  color: #f39c12;
}

.poor {
  color: #e74c3c;
  font-weight: bold;
}

/* 删除确认模态框 */
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 15px 20px;
  border-top: 1px solid #eee;
}

.save-btn {
  padding: 8px 16px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.cancel-btn {
  padding: 8px 16px;
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}


.add-existing-student {
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.search-add {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
}

.search-input {
  flex: 1;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.search-btn {
  padding: 8px 15px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.student-selector {
  margin-top: 10px;
  max-height: 300px;
  overflow-y: auto;
}

.student-select-table {
  width: 100%;
  border-collapse: collapse;
}

.student-select-table th,
.student-select-table td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
}

.student-select-table th {
  background-color: #f2f2f2;
}

.loading-small, .error-small {
  padding: 10px;
  text-align: center;
}

.error-small {
  color: #e74c3c;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
  margin-top: 10px;
}

.page-btn {
  padding: 5px 10px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.page-btn:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}

.selected-actions {
  margin-top: 15px;
  text-align: right;
}

.add-selected-btn {
  padding: 8px 15px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.add-selected-btn:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}

.form-section {
  margin-top: 20px;
}
</style>
