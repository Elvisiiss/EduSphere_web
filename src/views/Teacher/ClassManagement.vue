<template>
  <div class="class-management">
    <h2>班级管理</h2>

    <div v-if="loading" class="loading">
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error">
      <p>加载失败: {{ error }}</p>
      <button @click="fetchTeacherClasses" class="retry-btn">重试</button>
    </div>

    <div v-else-if="classes.length > 0" class="class-list">
      <div v-for="classItem in classes" :key="classItem.classId" class="class-card">
        <div class="class-header">
          <h3>{{ classItem.className }}</h3>
          <span v-if="classItem.headTeacherId === user_id" class="head-teacher-badge">班主任</span>
        </div>

        <div class="class-info">
          <p>学生人数: {{ classItem.studentCount }}</p>
          <p>所授科目: {{ formatSubjects(classItem.subjects) }}</p>
        </div>

        <div class="class-actions">
          <button @click="viewClassDetails(classItem)" class="view-btn">查看详情</button>
        </div>
      </div>
    </div>

    <div v-else class="no-classes">
      <p>您目前没有负责任何班级</p>
    </div>

    <!-- 班级详情模态框 -->
    <div v-if="selectedClass" class="modal" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ selectedClass.className }}           详情</h3>
          <button @click="closeModal" class="close-btn">&times;</button>
        </div>

        <div class="modal-body">
          <div class="detail-item">
            <span class="detail-label">班主任:</span>
            <span>{{ selectedClass.headTeacherId === user_id ? '是' : '否' }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">学生人数:</span>
            <span>{{ selectedClass.studentCount }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">教授科目:</span>
            <div class="subjects-list">
              <div v-for="subject in selectedClass.subjects" :key="subject.subject_id" class="subject-item">
                {{ subject.subject_name }} ({{ subject.subject_desc }})
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="navigateToClassScores(selectedClass.classId)" class="action-btn">
            查看成绩
          </button>
          <button @click="navigateToClassStudents(selectedClass.classId)" class="action-btn">
            查看学生
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import teacherApi from '@/api/teacher.js'

const router = useRouter()
const authStore = useAuthStore()
const token = authStore.user?.token
const classes = ref([])
const loading = ref(true)
const error = ref(null)
const selectedClass = ref(null)
const user_id = authStore.user?.user_id

const fetchTeacherClasses = async () => {
  try {
    loading.value = true
    error.value = null
    const response = await teacherApi.getTeacherClasses(token)
    if (response.data) {
      classes.value = response.data
    }
  } catch (err) {
    console.error('获取班级列表失败:', err)
    error.value = err.message || '获取班级列表失败'
  } finally {
    loading.value = false
  }
}

const formatSubjects = (subjects) => {
  return subjects.map(s => s.subject_name).join(', ')
}

const viewClassDetails = (classItem) => {
  selectedClass.value = classItem
}

const closeModal = () => {
  selectedClass.value = null
}

const navigateToClassScores = (classId) => {
  router.push({ name: 'ClassScores', params: { classId } })
}

const navigateToClassStudents = (classId) => {
  router.push({ name: 'ClassStudents', params: { classId } })
}

onMounted(() => {
  fetchTeacherClasses()
})
</script>

<style scoped>
.class-management {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  min-height: 70vh;
  position: relative;
}

.loading, .error, .no-classes {
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

.class-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.class-card {
  border: 1px solid #ddd;
  border-radius: 5px;
  padding: 15px;
  transition: all 0.3s;
  background-color: white;
}

.class-card:hover {
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
  transform: translateY(-2px);
}

.class-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
  border-bottom: 1px solid #eee;
  padding-bottom: 10px;
}

.head-teacher-badge {
  background-color: #e74c3c;
  color: white;
  padding: 3px 8px;
  border-radius: 3px;
  font-size: 0.8rem;
}

.class-info p {
  margin: 8px 0;
  color: #555;
}

.class-actions {
  margin-top: 15px;
  display: flex;
  justify-content: flex-end;
}

.view-btn {
  padding: 8px 16px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.view-btn:hover {
  background-color: #2980b9;
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
  max-width: 600px;
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

.detail-item {
  margin-bottom: 15px;
  display: flex;
}

.detail-label {
  font-weight: bold;
  min-width: 100px;
  color: #555;
}

.subjects-list {
  margin-top: 5px;
}

.subject-item {
  padding: 5px 0;
  border-bottom: 1px dashed #eee;
}

.modal-footer {
  padding: 15px 20px;
  border-top: 1px solid #eee;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.action-btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.action-btn:nth-child(1) {
  background-color: #3498db;
  color: white;
}

.action-btn:nth-child(2) {
  background-color: #2ecc71;
  color: white;
}

.action-btn:hover {
  opacity: 0.9;
}
</style>
