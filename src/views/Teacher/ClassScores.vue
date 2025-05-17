<template>
  <div class="class-scores">
    <div class="header">
      <h2>{{ classInfo.className }} - 成绩总览</h2>
      <button @click="goBack" class="back-btn">返回班级管理</button>
    </div>

    <div v-if="loading" class="loading">
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error">
      <p>加载失败: {{ error }}</p>
      <button @click="fetchClassData" class="retry-btn">重试</button>
    </div>

    <div v-else class="score-overview">
      <div class="subject-selector">
        <label>选择科目:</label>
        <select v-model="selectedSubject" @change="fetchSubjectScores">
          <option v-for="subject in subjects" :key="subject.subject_id" :value="subject.subject_id">
            {{ subject.subject_name }}
          </option>
        </select>
      </div>

      <div v-if="selectedSubject" class="score-stats">
        <div class="stat-card">
          <h3>平均分</h3>
          <p class="stat-value">{{ stats.average || '--' }}</p>
        </div>
        <div class="stat-card">
          <h3>最高分</h3>
          <p class="stat-value">{{ stats.max || '--' }}</p>
        </div>
        <div class="stat-card">
          <h3>最低分</h3>
          <p class="stat-value">{{ stats.min || '--' }}</p>
        </div>
        <div class="stat-card">
          <h3>及格率</h3>
          <p class="stat-value">{{ stats.passRate ? `${stats.passRate}%` : '--' }}</p>
        </div>
      </div>

      <div v-if="selectedSubject && scores.length > 0" class="score-list">
        <table>
          <thead>
          <tr>
            <th>学生姓名</th>
            <th>学号</th>
            <th>最近考试</th>
            <th>最近成绩</th>
            <th>操作</th>
          </tr>
          </thead>
          <tbody>
          <tr v-for="student in studentsWithScores" :key="student.studentId">
            <td>{{ student.studentName }}</td>
            <td>{{ student.studentNumber }}</td>
            <td>{{ student.latestExam || '--' }}</td>
            <td :class="getScoreClass(student.latestScore)">
              {{ student.latestScore || '--' }}
            </td>
            <td>
              <button @click="viewStudentScores(student.studentId)" class="view-btn">查看详情</button>
            </td>
          </tr>
          </tbody>
        </table>
      </div>

      <div v-else-if="selectedSubject" class="no-scores">
        <p>暂无成绩记录</p>
      </div>
    </div>

    <!-- 学生成绩详情模态框 -->
    <div v-if="selectedStudent" class="modal" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ selectedStudent.studentName }} ({{ selectedStudent.studentNumber }}) 成绩详情</h3>
          <button @click="closeModal" class="close-btn">&times;</button>
        </div>

        <div class="modal-body">
          <div class="detail-item">
            <span class="detail-label">科目:</span>
            <span>{{ subjects.find(s => s.subject_id === selectedSubject)?.subject_name }}</span>
          </div>

          <div class="score-history">
            <h4>历史成绩</h4>
            <table>
              <thead>
              <tr>
                <th>考试名称</th>
                <th>考试日期</th>
                <th>成绩</th>
                <th>评语</th>
              </tr>
              </thead>
              <tbody>
              <tr v-for="score in studentScores" :key="score.scoreId">
                <td>{{ score.examName }}</td>
                <td>{{ formatDate(score.examDate) }}</td>
                <td :class="getScoreClass(score.score)">{{ score.score }}</td>
                <td>{{ score.comment || '无' }}</td>
              </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="closeModal" class="close-btn">关闭</button>
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

const loading = ref(true)
const error = ref(null)
const classInfo = ref({})
const subjects = ref([])
const students = ref([])
const scores = ref([])
const selectedSubject = ref(null)
const stats = ref({})
const selectedStudent = ref(null)
const studentScores = ref([])

const fetchClassData = async () => {
  try {
    loading.value = true
    error.value = null

    // 获取班级信息
    const classResponse = await teacherApi.getTeacherClasses(token)
    if (classResponse.data) {
      const foundClass = classResponse.data.find(c => c.classId === parseInt(classId))
      if (foundClass) {
        classInfo.value = foundClass
        subjects.value = foundClass.subjects
        if (subjects.value.length > 0) {
          selectedSubject.value = subjects.value[0].subject_id
        }
      }
    }

    // 获取学生列表
    const studentsResponse = await teacherApi.getClassStudents(token, classId)
    if (studentsResponse.data) {
      students.value = studentsResponse.data
    }

    if (selectedSubject.value) {
      await fetchSubjectScores()
    }
  } catch (err) {
    console.error('获取班级数据失败:', err)
    error.value = err.message || '获取班级数据失败'
  } finally {
    loading.value = false
  }
}

const fetchSubjectScores = async () => {
  if (!selectedSubject.value) return

  try {
    loading.value = true
    const response = await teacherApi.getClassScores(token, classId, selectedSubject.value, null)
    if (response.data) {
      scores.value = response.data
      calculateStats()
    }
  } catch (err) {
    console.error('获取成绩数据失败:', err)
    error.value = err.message || '获取成绩数据失败'
  } finally {
    loading.value = false
  }
}

const calculateStats = () => {
  if (scores.value.length === 0) {
    stats.value = {}
    return
  }

  const validScores = scores.value.map(s => s.score).filter(s => s != null)
  if (validScores.length === 0) {
    stats.value = {}
    return
  }

  const sum = validScores.reduce((a, b) => a + b, 0)
  const avg = sum / validScores.length
  const max = Math.max(...validScores)
  const min = Math.min(...validScores)
  const passCount = validScores.filter(s => s >= 60).length
  const passRate = (passCount / validScores.length * 100).toFixed(1)

  stats.value = {
    average: avg.toFixed(1),
    max: max.toFixed(1),
    min: min.toFixed(1),
    passRate
  }
}

const studentsWithScores = computed(() => {
  return students.value.map(student => {
    const studentScores = scores.value.filter(s => s.studentId === student.studentId)
    const latestScore = studentScores.length > 0
        ? studentScores.reduce((latest, current) =>
            new Date(current.examDate) > new Date(latest.examDate) ? current : latest
        ).score
        : null

    const latestExam = studentScores.length > 0
        ? studentScores.reduce((latest, current) =>
            new Date(current.examDate) > new Date(latest.examDate) ? current : latest
        ).examName
        : null

    return {
      ...student,
      latestScore,
      latestExam
    }
  })
})

const viewStudentScores = (studentId) => {
  selectedStudent.value = students.value.find(s => s.studentId === studentId)
  studentScores.value = scores.value
      .filter(s => s.studentId === studentId)
      .sort((a, b) => new Date(b.examDate) - new Date(a.examDate))
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
.class-scores {
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

.back-btn {
  padding: 8px 16px;
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.loading, .error, .no-scores {
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

.subject-selector {
  margin: 20px 0;
  display: flex;
  align-items: center;
}

.subject-selector label {
  margin-right: 10px;
  font-weight: bold;
}

.subject-selector select {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  min-width: 200px;
}

.score-stats {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
  margin: 20px 0;
}

.stat-card {
  background-color: #f8f9fa;
  padding: 15px;
  border-radius: 5px;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.stat-card h3 {
  margin-top: 0;
  color: #7f8c8d;
  font-size: 1rem;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: bold;
  margin-bottom: 0;
  color: #2c3e50;
}

.score-list {
  margin-top: 20px;
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

.view-btn {
  padding: 6px 12px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
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

.detail-item {
  margin-bottom: 15px;
  display: flex;
}

.detail-label {
  font-weight: bold;
  min-width: 80px;
  color: #555;
}

.score-history {
  margin-top: 20px;
}

.score-history h4 {
  margin-bottom: 15px;
  color: #2c3e50;
}

.modal-footer {
  padding: 15px 20px;
  border-top: 1px solid #eee;
  display: flex;
  justify-content: flex-end;
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
</style>
