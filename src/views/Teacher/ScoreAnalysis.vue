<template>
  <div class="score-analysis">
    <h2>成绩综合分析</h2>

    <div v-if="loading" class="loading">
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error">
      <p>加载失败: {{ error }}</p>
      <button @click="fetchData" class="retry-btn">重试</button>
    </div>

    <div v-else class="analysis-content">
      <!-- 筛选条件 -->
      <div class="filter-section">
        <div class="filter-row">
          <label>选择班级:</label>
          <select v-model="selectedClassId" @change="onClassChange">
            <option v-for="classItem in classes" :key="classItem.classId" :value="classItem.classId">
              {{ classItem.className }}
            </option>
          </select>
        </div>

        <div class="filter-row">
          <label>选择科目:</label>
          <select v-model="selectedSubjectId" @change="onSubjectChange">
            <option v-for="subject in currentSubjects" :key="subject.subject_id" :value="subject.subject_id">
              {{ subject.subject_name }}
            </option>
          </select>
        </div>

        <div class="filter-row">
          <label>选择考试:</label>
          <select v-model="selectedExamName" @change="fetchScores">
            <option value="">全部考试</option>
            <option v-for="exam in uniqueExamNames" :key="exam" :value="exam">
              {{ exam }}
            </option>
          </select>
        </div>
      </div>

      <!-- 分析结果 -->
      <div v-if="selectedClassId && selectedSubjectId" class="analysis-result">
        <div class="stats-grid">
          <div class="stat-card">
            <h4>平均分</h4>
            <p class="stat-value">{{ stats.average ? stats.average.toFixed(3) : '--' }}</p>
          </div>
          <div class="stat-card">
            <h4>最高分</h4>
            <p class="stat-value">{{ stats.max || '--' }}</p>
          </div>
          <div class="stat-card">
            <h4>最低分</h4>
            <p class="stat-value">{{ stats.min || '--' }}</p>
          </div>
          <div class="stat-card">
            <h4>及格率</h4>
            <p class="stat-value">{{ stats.passRate ? `${stats.passRate}%` : '--' }}</p>
          </div>
        </div>

        <div class="score-distribution">
          <h4>分数段分布</h4>
          <div class="distribution-bars">
            <div v-for="(count, range) in scoreDistribution" :key="range" class="distribution-item">
              <div class="range-label">{{ range }}</div>
              <div class="bar-container">
                <div class="bar" :style="{ width: calculateBarWidth(count, stats.totalStudents) }"></div>
                <span class="count">{{ count }}人</span>
              </div>
            </div>
          </div>
        </div>

        <div class="student-scores">
          <h4>学生成绩列表</h4>
          <table>
            <thead>
            <tr>
              <th>学生姓名</th>
              <th>学号</th>
              <th>成绩</th>
              <th>评语</th>
            </tr>
            </thead>
            <tbody>
            <tr v-for="score in currentScores" :key="score.scoreId">
              <td>{{ score.studentName }}</td>
              <td>{{ score.studentNumber }}</td>
              <td :class="getScoreClass(score.score)">{{ score.score }}</td>
              <td>{{ score.comment || '无' }}</td>
            </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div v-else class="no-data">
        <p>请选择班级和科目查看分析结果</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import teacherApi from '@/api/teacher.js'

const authStore = useAuthStore()
const token = authStore.user?.token

const loading = ref(true)
const error = ref(null)
const classes = ref([])
const currentScores = ref([])
const stats = ref({
  average: null,
  max: null,
  min: null,
  passRate: null,
  totalStudents: 0
})

const selectedClassId = ref('')
const selectedSubjectId = ref('')
const selectedExamName = ref('')

const fetchData = async () => {
  try {
    loading.value = true
    error.value = null
    const response = await teacherApi.getTeacherClassForAll(token)
    if (response.data) {
      classes.value = response.data
      if (classes.value.length > 0) {
        selectedClassId.value = classes.value[0].classId
        await fetchScores()
      }
    }
  } catch (err) {
    console.error('获取班级数据失败:', err)
    error.value = err.message || '获取班级数据失败'
  } finally {
    loading.value = false
  }
}

const fetchScores = async () => {
  if (!selectedClassId.value || !selectedSubjectId.value) return

  try {
    loading.value = true
    const response = await teacherApi.getClassScores(
        token,
        selectedClassId.value,
        selectedSubjectId.value,
        selectedExamName.value || null
    )

    if (response.data) {
      currentScores.value = response.data
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
  if (currentScores.value.length === 0) {
    resetStats()
    return
  }

  const scores = currentScores.value.map(s => s.score)
  const passScore = 60 // 及格分数线
  const passedCount = scores.filter(s => s >= passScore).length

  stats.value = {
    average: (scores.reduce((a, b) => a + b, 0) / scores.length),
        max: Math.max(...scores),
    min: Math.min(...scores),
    passRate: ((passedCount / scores.length) * 100).toFixed(1),
    totalStudents: currentScores.value.length
  }
}

const resetStats = () => {
  stats.value = {
    average: null,
    max: null,
    min: null,
    passRate: null,
    totalStudents: 0
  }
}

const onClassChange = () => {
  selectedSubjectId.value = ''
  selectedExamName.value = ''
  currentScores.value = []
  resetStats()
}

const onSubjectChange = () => {
  selectedExamName.value = ''
  fetchScores()
}

const currentSubjects = computed(() => {
  const classItem = classes.value.find(c => c.classId === selectedClassId.value)
  return classItem ? classItem.subjects : []
})

const uniqueExamNames = computed(() => {
  const examNames = new Set()
  currentScores.value.forEach(score => examNames.add(score.examName))
  return Array.from(examNames)
})

const scoreDistribution = computed(() => {
  const distribution = {
    '90-100': 0,
    '80-89': 0,
    '70-79': 0,
    '60-69': 0,
    '0-59': 0
  }

  currentScores.value.forEach(score => {
    if (score.score >= 90) distribution['90-100']++
    else if (score.score >= 80) distribution['80-89']++
    else if (score.score >= 70) distribution['70-79']++
    else if (score.score >= 60) distribution['60-69']++
    else distribution['0-59']++
  })

  return distribution
})

const calculateBarWidth = (count, total) => {
  return total > 0 ? `${(count / total) * 100}%` : '0%'
}

const getScoreClass = (score) => {
  if (score >= 90) return 'excellent'
  if (score >= 80) return 'good'
  if (score >= 60) return 'average'
  return 'poor'
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.score-analysis {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  min-height: 70vh;
}

.loading, .error, .no-data {
  margin-top: 20px;
  padding: 20px;
  text-align: center;
  background-color: #f9f9f9;
  border-radius: 5px;
}

.error {
  color: #e74c3c;
}

.no-data {
  color: #7f8c8d;
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

.filter-section {
  margin-bottom: 20px;
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}

.filter-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.filter-row label {
  font-weight: bold;
}

.filter-row select {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  min-width: 150px;
}

.analysis-result {
  margin-top: 20px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 15px;
  margin-bottom: 20px;
}

.stat-card {
  background-color: #f8f9fa;
  padding: 15px;
  border-radius: 5px;
  text-align: center;
}

.stat-card h4 {
  margin: 0 0 5px 0;
  color: #7f8c8d;
  font-size: 0.9rem;
}

.stat-value {
  font-size: 1.3rem;
  font-weight: bold;
  margin: 0;
  color: #2c3e50;
}

.score-distribution {
  margin: 30px 0;
}

.score-distribution h4 {
  margin-bottom: 15px;
  color: #2c3e50;
}

.distribution-bars {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.distribution-item {
  display: flex;
  align-items: center;
  gap: 15px;
}

.range-label {
  width: 60px;
  font-size: 0.9rem;
  color: #555;
}

.bar-container {
  flex-grow: 1;
  display: flex;
  align-items: center;
  gap: 10px;
}

.bar {
  height: 25px;
  background-color: #3498db;
  border-radius: 3px;
  transition: width 0.5s ease;
}

.count {
  font-size: 0.9rem;
  color: #7f8c8d;
  min-width: 50px;
  text-align: right;
}

.student-scores {
  margin-top: 30px;
}

.student-scores h4 {
  margin-bottom: 15px;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
}

th, td {
  border: 1px solid #ddd;
  padding: 10px;
  text-align: left;
}

th {
  background-color: #f2f2f2;
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
