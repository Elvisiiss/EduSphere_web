<template>
  <div class="score-analysis">
    <h2>成绩综合分析</h2>

    <div v-if="loading" class="loading">
      <p>加载中...</p>
      <div class="spinner"></div>
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
          <div class="exam-selector">
            <select v-model="selectedExams[0]" @change="fetchScores">
              <option value="">请选择考试</option>
              <option v-for="exam in uniqueExamNames.filter(name => name)" :key="exam" :value="exam">
                {{ exam }}
              </option>
            </select>
            <button v-if="selectedExams[0]" class="add-exam-btn" @click="addExamComparison" :disabled="selectedExams.length >= 2 || !selectedExams[0]">
              + 添加对比
            </button>
          </div>
        </div>

        <div v-if="selectedExams.length > 1" class="filter-row">
          <label>对比考试:</label>
          <select v-model="selectedExams[1]" @change="fetchScores">
            <option value="">请选择对比考试</option>
            <option v-for="exam in uniqueExamNames.filter(name => name && name !== selectedExams[0])" :key="exam" :value="exam">
              {{ exam }}
            </option>
          </select>
          <button class="remove-exam-btn" @click="removeExamComparison">×</button>
        </div>
      </div>

      <!-- 分析结果 -->
      <div v-if="selectedClassId && selectedSubjectId" class="analysis-result">
        <!-- 单场考试分析 -->
        <div v-if="selectedExams.length === 1 && selectedExams[0]" class="single-exam">
          <div class="stats-grid">
            <div class="stat-card" v-for="stat in singleExamStats" :key="stat.title">
              <h4>{{ stat.title }}</h4>
              <p class="stat-value">{{ stat.value }}</p>
              <p class="stat-label">{{ stat.label }}</p>
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

        <!-- 两场考试对比 -->
        <div v-if="selectedExams.length === 2 && selectedExams[0] && selectedExams[1]" class="exam-comparison">
          <div class="comparison-header">
            <h3>考试对比分析</h3>
            <div class="exam-titles">
              <span class="exam-title">{{ selectedExams[0] }}</span>
              <span class="vs">VS</span>
              <span class="exam-title">{{ selectedExams[1] }}</span>
            </div>
          </div>

          <!-- 统计对比 -->
          <div class="stats-comparison">
            <h4>数据对比</h4>
            <div class="comparison-stats-grid">
              <div class="comparison-stat-card" v-for="stat in comparisonStats" :key="stat.title">
                <div class="stat-title">{{ stat.title }}</div>
                <div class="stat-values">
                  <div class="stat-value" :class="{'better': stat.isFirstBetter}">
                    {{ stat.firstValue }}
                    <span v-if="stat.difference" class="difference-indicator">
                      <span v-if="stat.difference > 0">↑</span>
                      <span v-else-if="stat.difference < 0">↓</span>
                      {{ Math.abs(stat.difference) }}
                    </span>
                  </div>
                  <div class="stat-value" :class="{'better': !stat.isFirstBetter}">
                    {{ stat.secondValue }}
                  </div>
                </div>
                <div class="stat-progress">
                  <div class="progress-bar" :style="{ width: stat.progress + '%' }"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- 分数段对比 -->
          <div class="distribution-comparison">
            <h4>分数段对比</h4>
            <div class="comparison-bars">
              <div v-for="(rangeData, range) in comparisonDistribution" :key="range" class="comparison-distribution-item">
                <div class="range-label">{{ range }}</div>
                <div class="comparison-bars-container">
                  <div class="comparison-bar first" :style="{ width: rangeData.firstPercentage + '%' }">
                    <span class="bar-label">{{ rangeData.firstCount }}人</span>
                  </div>
                  <div class="comparison-bar second" :style="{ width: rangeData.secondPercentage + '%' }">
                    <span class="bar-label">{{ rangeData.secondCount }}人</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 学生成绩对比 (仅当同一班级时显示) -->
          <div v-if="isSameClassComparison" class="student-comparison">
            <h4>学生成绩变化</h4>
            <table>
              <thead>
              <tr>
                <th>学生姓名</th>
                <th>学号</th>
                <th>{{ selectedExams[0] }}</th>
                <th>{{ selectedExams[1] }}</th>
                <th>变化</th>
                <th>进步幅度</th>
              </tr>
              </thead>
              <tbody>
              <tr v-for="student in comparedStudents" :key="student.studentNumber">
                <td>{{ student.studentName }}</td>
                <td>{{ student.studentNumber }}</td>
                <td :class="getScoreClass(student.firstScore)">{{ student.firstScore }}</td>
                <td :class="getScoreClass(student.secondScore)">{{ student.secondScore }}</td>
                <td :class="getChangeClass(student.change)">
                  {{ student.change > 0 ? '+' : '' }}{{ student.change }}
                </td>
                <td>
                  <div class="progress-indicator" :class="getProgressClass(student.change)">
                    <div class="progress-bar" :style="{ width: Math.min(Math.abs(student.change) * 2, 100) + '%' }"></div>
                  </div>
                </td>
              </tr>
              </tbody>
            </table>
          </div>
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
const allScores = ref([]) // 存储所有考试成绩用于对比
const stats = ref({
  average: null,
  max: null,
  min: null,
  passRate: null,
  totalStudents: 0
})

const selectedClassId = ref('')
const selectedSubjectId = ref('')
const selectedExams = ref(['']) // 改为数组形式，支持多选对比

// 获取数据
const fetchData = async () => {
  try {
    loading.value = true
    error.value = null
    const response = await teacherApi.getTeacherClassForAll(token)
    if (response.data) {
      classes.value = response.data
      if (classes.value.length > 0) {
        selectedClassId.value = classes.value[0].classId
        await fetchAllScores()
      }
    }
  } catch (err) {
    console.error('获取班级数据失败:', err)
    error.value = err.message || '获取班级数据失败'
  } finally {
    loading.value = false
  }
}

// 获取所有考试成绩
const fetchAllScores = async () => {
  if (!selectedClassId.value || !selectedSubjectId.value) return

  try {
    loading.value = true
    const response = await teacherApi.getClassScores(
        token,
        selectedClassId.value,
        selectedSubjectId.value,
        null // 获取所有考试
    )

    if (response.data) {
      allScores.value = response.data
      updateCurrentScores()
    }
  } catch (err) {
    console.error('获取成绩数据失败:', err)
    error.value = err.message || '获取成绩数据失败'
  } finally {
    loading.value = false
  }
}

// 修改updateCurrentScores方法，添加有效性检查
const updateCurrentScores = () => {
  if (!selectedExams.value[0]) {
    currentScores.value = []
    resetStats()
    return
  }

  // 过滤时排除空值
  currentScores.value = allScores.value.filter(score =>
      selectedExams.value.some(exam => exam && score.examName === exam)
  )

  calculateStats()
}


// 添加fetchScores方法
const fetchScores = () => {
  updateCurrentScores()
}
// 计算统计数据
const calculateStats = () => {
  if (!currentScores.value.length || !selectedExams.value[0]) {
    resetStats()
    return
  }

  // 如果是单场考试
  if (selectedExams.value.length === 1 || !selectedExams.value[1]) {
    const scores = currentScores.value.map(s => s.score)
    const passScore = 60
    const passedCount = scores.filter(s => s >= passScore).length

    stats.value = {
      average: (scores.reduce((a, b) => a + b, 0) / scores.length),
      max: Math.max(...scores),
      min: Math.min(...scores),
      passRate: ((passedCount / scores.length) * 100).toFixed(1),
      totalStudents: currentScores.value.length
    }
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

// 添加考试对比
const addExamComparison = () => {
  if (selectedExams.value.length < 2) {
    selectedExams.value.push('')
  }
}

// 移除考试对比
const removeExamComparison = () => {
  if (selectedExams.value.length > 1) {
    selectedExams.value.pop()
    updateCurrentScores()
  }
}

const onClassChange = () => {
  selectedSubjectId.value = ''
  selectedExams.value = [''] // 重置考试选择
  currentScores.value = []
  resetStats()
}

const onSubjectChange = () => {
  selectedExams.value = [''] // 重置考试选择
  fetchAllScores()
}

// 计算属性
const currentSubjects = computed(() => {
  const classItem = classes.value.find(c => c.classId === selectedClassId.value)
  return classItem ? classItem.subjects : []
})

const uniqueExamNames = computed(() => {
  const examNames = new Set()
  allScores.value.forEach(score => examNames.add(score.examName))
  return Array.from(examNames).filter(name => name)
})

const scoreDistribution = computed(() => {
  const distribution = {
    '90-100': 0,
    '80-89': 0,
    '70-79': 0,
    '60-69': 0,
    '0-59': 0
  }

  const scores = selectedExams.value.length === 1 ?
      currentScores.value.filter(s => s.examName === selectedExams.value[0]) :
      currentScores.value

  scores.forEach(score => {
    if (score.score >= 90) distribution['90-100']++
    else if (score.score >= 80) distribution['80-89']++
    else if (score.score >= 70) distribution['70-79']++
    else if (score.score >= 60) distribution['60-69']++
    else distribution['0-59']++
  })

  return distribution
})

const singleExamStats = computed(() => {
  return [
    { title: '平均分', value: stats.value.average ? stats.value.average.toFixed(1) : '--', label: '班级整体水平' },
    { title: '最高分', value: stats.value.max || '--', label: '班级最高成绩' },
    { title: '最低分', value: stats.value.min || '--', label: '班级最低成绩' },
    { title: '及格率', value: stats.value.passRate ? `${stats.value.passRate}%` : '--', label: '≥60分比例' }
  ]
})

// 对比统计
const comparisonStats = computed(() => {
  if (selectedExams.value.length !== 2 || !selectedExams.value[0] || !selectedExams.value[1]) return []

  const firstExamScores = allScores.value
      .filter(score => score.examName === selectedExams.value[0])
      .map(s => s.score)

  const secondExamScores = allScores.value
      .filter(score => score.examName === selectedExams.value[1])
      .map(s => s.score)

  if (firstExamScores.length === 0 || secondExamScores.length === 0) return []

  const firstAvg = firstExamScores.reduce((a, b) => a + b, 0) / firstExamScores.length
  const secondAvg = secondExamScores.reduce((a, b) => a + b, 0) / secondExamScores.length
  const avgDiff = secondAvg - firstAvg

  const firstMax = Math.max(...firstExamScores)
  const secondMax = Math.max(...secondExamScores)
  const maxDiff = secondMax - firstMax

  const firstMin = Math.min(...firstExamScores)
  const secondMin = Math.min(...secondExamScores)
  const minDiff = secondMin - firstMin

  const firstPassRate = (firstExamScores.filter(s => s >= 60).length / firstExamScores.length * 100).toFixed(1)
  const secondPassRate = (secondExamScores.filter(s => s >= 60).length / secondExamScores.length * 100).toFixed(1)
  const passRateDiff = (secondPassRate - firstPassRate).toFixed(1)

  return [
    {
      title: '平均分',
      firstValue: firstAvg.toFixed(1),
      secondValue: secondAvg.toFixed(1),
      difference: avgDiff.toFixed(1),
      isFirstBetter: avgDiff < 0,
      progress: Math.min(Math.max(50 + (avgDiff * 2), 100))
    },
    {
      title: '最高分',
      firstValue: firstMax,
      secondValue: secondMax,
      difference: maxDiff,
      isFirstBetter: maxDiff < 0,
      progress: Math.min(Math.max(50 + (maxDiff * 0.5), 100))
    },
    {
      title: '最低分',
      firstValue: firstMin,
      secondValue: secondMin,
      difference: minDiff,
      isFirstBetter: minDiff < 0,
      progress: Math.min(Math.max(50 + (minDiff * 0.5), 100))
    },
    {
      title: '及格率',
      firstValue: `${firstPassRate}%`,
      secondValue: `${secondPassRate}%`,
      difference: passRateDiff,
      isFirstBetter: passRateDiff < 0,
      progress: Math.min(Math.max(50 + (passRateDiff * 0.5), 100))
    }
  ]
})

// 分数段对比
const comparisonDistribution = computed(() => {
  if (selectedExams.value.length !== 2 || !selectedExams.value[0] || !selectedExams.value[1]) return {}

  const firstExamScores = allScores.value.filter(score => score.examName === selectedExams.value[0])
  const secondExamScores = allScores.value.filter(score => score.examName === selectedExams.value[1])

  const ranges = ['90-100', '80-89', '70-79', '60-69', '0-59']
  const result = {}

  ranges.forEach(range => {
    const [min, max] = range.split('-').map(Number)

    const firstCount = firstExamScores.filter(score => {
      const s = score.score
      return max === 100 ? s >= 90 : (s >= min && s <= max)
    }).length

    const secondCount = secondExamScores.filter(score => {
      const s = score.score
      return max === 100 ? s >= 90 : (s >= min && s <= max)
    }).length

    const firstPercentage = firstExamScores.length > 0 ? (firstCount / firstExamScores.length * 100) : 0
    const secondPercentage = secondExamScores.length > 0 ? (secondCount / secondExamScores.length * 100) : 0

    result[range] = {
      firstCount,
      secondCount,
      firstPercentage,
      secondPercentage
    }
  })

  return result
})

// 学生成绩对比
const comparedStudents = computed(() => {
  if (!isSameClassComparison.value || selectedExams.value.length !== 2 ||
      !selectedExams.value[0] || !selectedExams.value[1]) return []

  const firstExamScores = allScores.value.filter(score => score.examName === selectedExams.value[0])
  const secondExamScores = allScores.value.filter(score => score.examName === selectedExams.value[1])

  const students = []

  firstExamScores.forEach(firstScore => {
    const secondScore = secondExamScores.find(s => s.studentNumber === firstScore.studentNumber)
    if (secondScore) {
      students.push({
        studentName: firstScore.studentName,
        studentNumber: firstScore.studentNumber,
        firstScore: firstScore.score,
        secondScore: secondScore.score,
        change: secondScore.score - firstScore.score
      })
    }
  })

  // 按进步幅度排序
  return students.sort((a, b) => b.change - a.change)
})

// 是否为同一班级的对比
const isSameClassComparison = computed(() => {
  return selectedExams.value.length === 2 &&
      selectedExams.value[0] &&
      selectedExams.value[1] &&
      selectedExams.value[0] !== selectedExams.value[1]
})

// 辅助方法
const calculateBarWidth = (count, total) => {
  return total > 0 ? `${(count / total) * 100}%` : '0%'
}

const getScoreClass = (score) => {
  if (score >= 90) return 'excellent'
  if (score >= 80) return 'good'
  if (score >= 60) return 'average'
  return 'poor'
}

const getChangeClass = (change) => {
  if (change > 0) return 'improvement'
  if (change < 0) return 'decline'
  return 'no-change'
}

const getProgressClass = (change) => {
  if (change > 5) return 'excellent-progress'
  if (change > 0) return 'good-progress'
  if (change < -5) return 'poor-progress'
  if (change < 0) return 'decline-progress'
  return 'no-progress'
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

.score-analysis {
  background-color: white;
  padding: 25px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  min-height: 70vh;
  animation: fadeIn 0.5s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.loading, .error, .no-data {
  margin-top: 20px;
  padding: 20px;
  text-align: center;
  background-color: #f9f9f9;
  border-radius: 8px;
  animation: fadeIn 0.3s ease;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 15px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-radius: 50%;
  border-top-color: #3498db;
  animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error {
  color: #e74c3c;
  background-color: #fdecea;
}

.no-data {
  color: #7f8c8d;
  background-color: #f5f7fa;
}

.retry-btn {
  margin-top: 10px;
  padding: 8px 16px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.retry-btn:hover {
  background-color: #2980b9;
  transform: translateY(-2px);
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.filter-section {
  margin-bottom: 25px;
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  background-color: #f8fafc;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.05);
  animation: slideDown 0.4s ease;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-20px); }
  to { opacity: 1; transform: translateY(0); }
}

.filter-row {
  display: flex;
  align-items: center;
  gap: 10px;
  position: relative;
}

.filter-row label {
  font-weight: 600;
  color: #4a5568;
}

.filter-row select {
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  min-width: 180px;
  background-color: white;
  transition: all 0.3s ease;
}

.filter-row select:focus {
  border-color: #3498db;
  box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2);
  outline: none;
}

.exam-selector {
  display: flex;
  align-items: center;
  gap: 10px;
}

.add-exam-btn, .remove-exam-btn {
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.add-exam-btn {
  background-color: #2ecc71;
  color: white;
}

.add-exam-btn:hover:not(:disabled) {
  background-color: #27ae60;
  transform: translateY(-2px);
}

.add-exam-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.remove-exam-btn {
  background-color: #e74c3c;
  color: white;
  margin-left: 10px;
}

.remove-exam-btn:hover {
  background-color: #c0392b;
}

.analysis-result {
  margin-top: 20px;
  animation: fadeIn 0.5s ease;
}

/* 单场考试样式 */
.single-exam {
  animation: fadeIn 0.6s ease;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
  text-align: center;
  transition: all 0.3s ease;
  border-top: 4px solid #3498db;
}

.stat-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 15px rgba(0,0,0,0.1);
}

.stat-card h4 {
  margin: 0 0 5px 0;
  color: #718096;
  font-size: 0.9rem;
  font-weight: 600;
}

.stat-value {
  font-size: 1.8rem;
  font-weight: bold;
  margin: 10px 0;
  color: #2d3748;
}

.stat-label {
  font-size: 0.8rem;
  color: #a0aec0;
  margin: 0;
}

.score-distribution {
  margin: 40px 0;
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
}

.score-distribution h4 {
  margin-bottom: 20px;
  color: #2d3748;
  font-size: 1.1rem;
  font-weight: 600;
}

.distribution-bars {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.distribution-item {
  display: flex;
  align-items: center;
  gap: 15px;
}

.range-label {
  width: 70px;
  font-size: 0.95rem;
  color: #4a5568;
  font-weight: 500;
}

.bar-container {
  flex-grow: 1;
  display: flex;
  align-items: center;
  gap: 15px;
}

.bar {
  height: 28px;
  background: linear-gradient(90deg, #3498db, #4aa3df);
  border-radius: 4px;
  transition: width 0.8s ease;
  position: relative;
  overflow: hidden;
}

.bar::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(90deg, rgba(255,255,255,0.3), transparent);
}

.count {
  font-size: 0.95rem;
  color: #718096;
  min-width: 60px;
  text-align: right;
  font-weight: 500;
}

.student-scores {
  margin-top: 40px;
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
}

.student-scores h4 {
  margin-bottom: 20px;
  color: #2d3748;
  font-size: 1.1rem;
  font-weight: 600;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  animation: fadeIn 0.7s ease;
}

th, td {
  border: 1px solid #e2e8f0;
  padding: 12px 15px;
  text-align: left;
}

th {
  background-color: #f7fafc;
  color: #4a5568;
  font-weight: 600;
}

tr:nth-child(even) {
  background-color: #f8fafc;
}

tr:hover {
  background-color: #f0f5ff;
}

/* 成绩颜色样式 */
.excellent {
  color: #27ae60;
  font-weight: bold;
}

.good {
  color: #2980b9;
  font-weight: 500;
}

.average {
  color: #f39c12;
}

.poor {
  color: #e74c3c;
  font-weight: bold;
}

/* 考试对比样式 */
.exam-comparison {
  animation: fadeIn 0.6s ease;
}

.comparison-header {
  text-align: center;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e2e8f0;
}

.comparison-header h3 {
  color: #2d3748;
  margin-bottom: 10px;
}

.exam-titles {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20px;
  font-size: 1.1rem;
  font-weight: 600;
}

.exam-title {
  padding: 8px 15px;
  background-color: #f7fafc;
  border-radius: 6px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.vs {
  color: #718096;
  font-style: italic;
}

/* 对比统计卡片 */
.comparison-stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.comparison-stat-card {
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
  transition: all 0.3s ease;
}

.comparison-stat-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 12px rgba(0,0,0,0.1);
}

.stat-title {
  font-weight: 600;
  color: #4a5568;
  margin-bottom: 15px;
  text-align: center;
}

.stat-values {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 1.2rem;
  font-weight: bold;
  color: #2d3748;
  position: relative;
  padding: 0 10px;
}

.stat-value.better {
  color: #27ae60;
}

.difference-indicator {
  position: absolute;
  top: -15px;
  right: -10px;
  font-size: 0.8rem;
  background-color: #f8f9fa;
  padding: 2px 5px;
  border-radius: 10px;
  color: #27ae60;
}

.stat-value.better .difference-indicator {
  color: #27ae60;
}

.stat-value:not(.better) .difference-indicator {
  color: #e74c3c;
}

.stat-progress {
  height: 6px;
  background-color: #edf2f7;
  border-radius: 3px;
  margin-top: 15px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: linear-gradient(90deg, #3498db, #4aa3df);
  border-radius: 3px;
  transition: width 1s ease;
}

/* 分数段对比 */
.distribution-comparison {
  margin: 40px 0;
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
}

.distribution-comparison h4 {
  margin-bottom: 20px;
  color: #2d3748;
  font-size: 1.1rem;
  font-weight: 600;
}

.comparison-bars {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.comparison-distribution-item {
  display: flex;
  align-items: center;
  gap: 15px;
}

.comparison-bars-container {
  flex-grow: 1;
  display: flex;
  height: 30px;
  border-radius: 4px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.comparison-bar {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding-right: 10px;
  transition: width 1s ease;
  position: relative;
}

.comparison-bar.first {
  background: linear-gradient(90deg, #3498db, #4aa3df);
}

.comparison-bar.second {
  background: linear-gradient(90deg, #2ecc71, #4fd681);
}

.bar-label {
  color: white;
  font-size: 0.8rem;
  font-weight: 500;
  text-shadow: 0 1px 2px rgba(0,0,0,0.2);
}

/* 学生对比表格 */
.student-comparison {
  margin-top: 40px;
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
}

.student-comparison table th,
.student-comparison table td {
  text-align: center;
}

.improvement {
  color: #27ae60;
  font-weight: bold;
}

.decline {
  color: #e74c3c;
  font-weight: bold;
}

.no-change {
  color: #7f8c8d;
}
</style>
