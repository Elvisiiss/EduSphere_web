<template>
  <div class="score-management">
    <h2>成绩管理</h2>

    <div class="class-selector">
      <div class="filter-row">
        <label>选择班级:</label>
        <select v-model="selectedClass" @change="fetchClassSubjects">
          <option v-for="classItem in classes" :key="classItem.classId" :value="classItem.classId">
            {{ classItem.className }}
          </option>
        </select>
      </div>

      <div class="filter-row">
        <label>选择科目:</label>
        <select v-model="selectedSubject" @change="onSubjectChange">
          <option v-for="subject in subjects" :key="subject.subject_id" :value="subject.subject_id">
            {{ subject.subject_name }}
          </option>
        </select>
      </div>

      <div class="filter-row">
        <label>选择考试:</label>
        <select v-model="selectedExamName" @change="filterByExam">
          <option value="">全部考试</option>
          <option v-for="exam in uniqueExamNames" :key="exam" :value="exam">
            {{ exam }}
          </option>
        </select>
      </div>
    </div>

    <div v-if="selectedClass && selectedSubject" class="score-actions">
      <button @click="showAddScoreModal" class="add-score-btn">添加成绩</button>
      <button @click="sortByScore" class="sort-btn">按成绩排序</button>
      <button @click="confirmExport" class="export-btn">导出xlsx表</button>
      <button @click="importXlsx" class="import-btn">导入xlsx表</button>
      <input
          type="text"
          v-model="searchQuery"
          placeholder="搜索学生姓名或学号"
          class="search-input"
          @input="filterScores"
      >
    </div>

    <div v-if="isLoading" class="loading">
      <p>加载中...</p>
    </div>

    <div v-else-if="filteredScores.length > 0" class="score-list">
      <table>
        <thead>
        <tr>
          <th>学生姓名</th>
          <th>学号</th>
          <th>考试名称</th>
          <th>考试日期</th>
          <th>成绩</th>
          <th>评语</th>
          <th>操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="score in filteredScores" :key="score.scoreId">
          <td>{{ score.studentName }}</td>
          <td>{{ score.studentNumber }}</td>
          <td>{{ score.examName }}</td>
          <td>{{ formatDate(score.examDate) }}</td>
          <td :class="getScoreClass(score.score)">{{ score.score }}</td>
          <td>{{ score.comment || '无' }}</td>
          <td>
            <button @click="showEditScoreModal(score)" class="edit-btn">编辑</button>
            <button @click="confirmDeleteScore(score.scoreId)" class="delete-btn">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <div v-else-if="selectedClass && selectedSubject" class="no-scores">
      <p>暂无成绩记录</p>
    </div>

    <!-- 添加/编辑成绩模态框 -->
    <div v-if="showScoreModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="closeModal">&times;</span>
        <h2>{{ isEditingScore ? '编辑成绩' : '添加成绩' }}</h2>

        <div class="form-group">
          <label>学生:</label>
          <select v-model="currentScore.studentId" :disabled="isEditingScore">
            <option v-for="student in students" :key="student.studentId" :value="student.studentId">
              {{ student.studentName }} ({{ student.studentNumber }})
            </option>
          </select>
        </div>

        <div class="form-group">
          <label>考试名称:</label>
          <input type="text" v-model="currentScore.examName" required>
        </div>

        <div class="form-group">
          <label>考试日期:</label>
          <input type="date" v-model="currentScore.examDate" required>
        </div>

        <div class="form-group">
          <label>成绩:</label>
          <input type="number" v-model="currentScore.score" min="0" max="100" step="0.1" required>
        </div>

        <div class="form-group">
          <label>评语:</label>
          <textarea v-model="currentScore.comment" rows="3"></textarea>
        </div>

        <div v-if="errorMessage" class="error-message">
          {{ errorMessage }}
        </div>

        <div class="modal-actions">
          <button @click="saveScore" class="save-btn">{{ isEditingScore ? '更新' : '保存' }}</button>
          <button @click="closeModal" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>

    <!-- 删除确认模态框 -->
    <div v-if="showDeleteModal" class="modal">
      <div class="modal-content">
        <h2>确认删除</h2>
        <p>确定要删除这条成绩记录吗？此操作无法撤销。</p>
        <div class="modal-actions">
          <button @click="deleteScore" class="delete-btn">删除</button>
          <button @click="cancelDelete" class="cancel-btn">取消</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import teacherApi from '@/api/teacher.js'
import * as XLSX from 'xlsx'


const authStore = useAuthStore()
const token = authStore.user?.token

const classes = ref([])
const subjects = ref([])
const students = ref([])
const scores = ref([])
const filteredScores = ref([])

const selectedClass = ref('')
const selectedSubject = ref('')
const selectedExamName = ref('')
const searchQuery = ref('')
const isLoading = ref(false)
const errorMessage = ref('')

const showScoreModal = ref(false)
const showDeleteModal = ref(false)
const isEditingScore = ref(false)
const scoreToDelete = ref(null)
const currentScore = ref({
  scoreId: '',
  studentId: '',
  examName: '',
  examDate: new Date().toISOString().split('T')[0],
  score: '',
  comment: ''
})

const uniqueExamNames = computed(() => {
  const examNames = new Set()
  scores.value.forEach(score => examNames.add(score.examName))
  return Array.from(examNames).sort()
})

const onSubjectChange = async () => {
  selectedExamName.value = ''
  await fetchClassScores()
}

const filterByExam = () => {
  if (!selectedExamName.value) {
    filteredScores.value = [...scores.value]
    return
  }
  filteredScores.value = scores.value.filter(
      score => score.examName === selectedExamName.value
  )
}

const fetchTeacherClasses = async () => {
  isLoading.value = true
  try {
    const response = await teacherApi.getTeacherClasses(token)
    if (response.data) {
      classes.value = response.data
      if (classes.value.length > 0) {
        selectedClass.value = classes.value[0].classId
        await fetchClassSubjects()
      }
    }
  } catch (error) {
    console.error('获取班级列表失败:', error)
    errorMessage.value = '获取班级列表失败，请稍后重试'
  } finally {
    isLoading.value = false
  }
}

const fetchClassSubjects = async () => {
  if (!selectedClass.value) return

  isLoading.value = true
  try {
    const classItem = classes.value.find(c => c.classId === selectedClass.value)
    if (classItem) {
      subjects.value = classItem.subjects
      if (subjects.value.length > 0) {
        selectedSubject.value = subjects.value[0].subject_id
        await Promise.all([fetchClassStudents(), fetchClassScores()])
      }
    }
  } catch (error) {
    console.error('获取科目列表失败:', error)
    errorMessage.value = '获取科目列表失败，请稍后重试'
  } finally {
    isLoading.value = false
  }
}

const fetchClassStudents = async () => {
  if (!selectedClass.value) return

  try {
    const response = await teacherApi.getClassStudents(token, selectedClass.value)
    if (response.data) {
      students.value = response.data
    }
  } catch (error) {
    console.error('获取学生列表失败:', error)
    errorMessage.value = '获取学生列表失败，请稍后重试'
  }
}

const fetchClassScores = async () => {
  if (!selectedClass.value || !selectedSubject.value) return

  isLoading.value = true
  try {
    const response = await teacherApi.getClassScores(
        token,
        selectedClass.value,
        selectedSubject.value,
        null
    )
    if (response.data) {
      scores.value = response.data
      filteredScores.value = [...scores.value]
    }
  } catch (error) {
    console.error('获取成绩列表失败:', error)
    errorMessage.value = '获取成绩列表失败，请稍后重试'
  } finally {
    isLoading.value = false
  }
}

const showAddScoreModal = () => {
  currentScore.value = {
    scoreId: '',
    studentId: students.value.length > 0 ? students.value[0].studentId : '',
    examName: '',
    examDate: new Date().toISOString().split('T')[0],
    score: '',
    comment: ''
  }
  isEditingScore.value = false
  errorMessage.value = ''
  showScoreModal.value = true
}

const showEditScoreModal = (score) => {
  currentScore.value = {
    scoreId: score.scoreId,
    studentId: score.studentId,
    examName: score.examName,
    examDate: score.examDate.split('T')[0],
    score: score.score,
    comment: score.comment
  }
  isEditingScore.value = true
  errorMessage.value = ''
  showScoreModal.value = true
}

const closeModal = () => {
  showScoreModal.value = false
}

const saveScore = async () => {
  // 验证表单
  if (!currentScore.value.examName || !currentScore.value.examDate || !currentScore.value.score) {
    errorMessage.value = '请填写所有必填字段'
    return
  }

  try {
    if (isEditingScore.value) {
      // 更新成绩
      await teacherApi.updateStudentScore(
          token,
          currentScore.value.scoreId,
          currentScore.value.score,
          currentScore.value.comment
      )
    } else {
      // 添加新成绩
      await teacherApi.submitStudentScore(
          token,
          selectedClass.value,
          currentScore.value.studentId,
          selectedSubject.value,
          currentScore.value.examName,
          currentScore.value.examDate,
          currentScore.value.score,
          currentScore.value.comment
      )
    }

    closeModal()
    await fetchClassScores()
  } catch (error) {
    console.error(isEditingScore.value ? '更新成绩失败:' : '添加成绩失败:', error)
    errorMessage.value = isEditingScore.value ? '更新成绩失败' : '添加成绩失败'
  }
}

const confirmDeleteScore = (scoreId) => {
  scoreToDelete.value = scoreId
  showDeleteModal.value = true
}

const cancelDelete = () => {
  scoreToDelete.value = null
  showDeleteModal.value = false
}

const deleteScore = async () => {
  try {
    await teacherApi.deleteStudentScore(token, scoreToDelete.value)
    await fetchClassScores()
    showDeleteModal.value = false
    scoreToDelete.value = null
  } catch (error) {
    console.error('删除成绩失败:', error)
    errorMessage.value = '删除成绩失败'
  }
}



const sortByScore = () => {
  filteredScores.value.sort((a, b) => b.score - a.score)
}

const filterScores = () => {
  if (!searchQuery.value) {
    filteredScores.value = [...scores.value]
    return
  }

  const query = searchQuery.value.toLowerCase()
  filteredScores.value = scores.value.filter(score =>
      score.studentName.toLowerCase().includes(query) ||
      score.studentNumber.toLowerCase().includes(query)
  )
}

const getScoreClass = (score) => {
  if (score >= 90) return 'excellent'
  if (score >= 80) return 'good'
  if (score >= 60) return 'average'
  return 'poor'
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN')
}

const confirmExport = () => {
  const className = classes.value.find(c => c.classId === selectedClass.value)?.className || '未知班级'
  const subjectName = subjects.value.find(s => s.subject_id === selectedSubject.value)?.subject_name || '未知科目'

  if (confirm(`您现在选择的班级为"${className}"，科目为"${subjectName}"，是否确定导出xlsx成绩表模板？`)) {
    exportXlsxTemplate()
  }
}

const exportXlsxTemplate = () => {
  const className = classes.value.find(c => c.classId === selectedClass.value)?.className || '未知班级'
  const subjectName = subjects.value.find(s => s.subject_id === selectedSubject.value)?.subject_name || '未知科目'

  // Prepare data for export
  const exportData = [
    ['考试名称#考试日期', '成绩', '评语'],
    ...students.value.map(student => [
      `${student.studentNumber}#${student.studentName}`,
      '', // Empty score
      ''  // Empty comment
    ])
  ]

  // Create worksheet
  const ws = XLSX.utils.aoa_to_sheet(exportData)

  // Create workbook
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, `${className}#${subjectName}`)

  // Export file
  XLSX.writeFile(wb, `${className}-${subjectName}-成绩模板.xlsx`)
}

const importXlsx = () => {
  const className = classes.value.find(c => c.classId === selectedClass.value)?.className || '未知班级'
  const subjectName = subjects.value.find(s => s.subject_id === selectedSubject.value)?.subject_name || '未知科目'

  if (confirm(`您现在选择的班级为"${className}"，科目为"${subjectName}"，是否确定导入xlsx成绩表？`)) {
    const input = document.createElement('input')
    input.type = 'file'
    input.accept = '.xlsx,.xls'

    input.onchange = async e => {
      const file = e.target.files[0]
      if (!file) return

      try {
        isLoading.value = true
        const data = await file.arrayBuffer()
        const workbook = XLSX.read(data)

        // Get first sheet
        const worksheet = workbook.Sheets[workbook.SheetNames[0]]
        const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 })

        // Process data (skip header row)
        const examInfo = jsonData[0][0].split('#')
        const exam_name = examInfo[0] || '未命名考试'
        const exam_date = examInfo[1] || new Date().toISOString().split('T')[0]

        const scoresToImport = []

        for (let i = 1; i < jsonData.length; i++) {
          const row = jsonData[i]
          if (!row || !row[0]) continue

          const studentInfo = row[0].split('#')
          const studentNumber = studentInfo[0]
          const studentName = studentInfo[1] || ''
          const score = row[1]
          const comment = row[2] || ''

          const student = students.value.find(s => s.studentNumber === studentNumber)
          if (student && score) {
            scoresToImport.push({
              student_id: student.studentId,
              exam_name,
              exam_date,
              score,
              comment
            })
          }
        }

        // Send to backend
        await teacherApi.importStudentScores(
            token,
            selectedClass.value,
            selectedSubject.value,
            scoresToImport
        )

        // Refresh data
        await fetchClassScores()
      } catch (error) {
        console.error('导入失败:', error)
        errorMessage.value = '导入失败，请检查文件格式'
      } finally {
        isLoading.value = false
      }
    }

    input.click()
  }
}

onMounted(() => {
  fetchTeacherClasses()
})
</script>

<style scoped>
.score-management {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.class-selector {
  margin: 20px 0;
  display: flex;
  align-items: center;
}

.class-selector select {
  margin-left: 10px;
  padding: 5px;
  border: 1px solid #ddd;
  border-radius: 3px;
  min-width: 150px;
}

.score-actions {
  margin-bottom: 20px;
  display: flex;
  gap: 10px;
  align-items: center;
}

.add-score-btn {
  padding: 8px 15px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.sort-btn {
  padding: 8px 15px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.search-input {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 3px;
  flex-grow: 1;
  max-width: 300px;
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
  padding: 8px;
  text-align: left;
}

th {
  background-color: #f2f2f2;
  position: sticky;
  top: 0;
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

.no-scores {
  margin-top: 20px;
  padding: 20px;
  text-align: center;
  background-color: #f9f9f9;
  border-radius: 5px;
}

.loading {
  margin-top: 20px;
  padding: 20px;
  text-align: center;
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
  max-height: 90vh;
  overflow-y: auto;
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
  font-weight: bold;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 3px;
}

.form-group textarea {
  resize: vertical;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  gap: 10px;
}

.save-btn {
  padding: 8px 15px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.cancel-btn {
  padding: 8px 15px;
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.error-message {
  color: #e74c3c;
  margin-bottom: 15px;
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

.class-selector {
  margin: 20px 0;
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  align-items: center;
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

.export-btn {
  padding: 8px 15px;
  background-color: #9b59b6;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.import-btn {
  padding: 8px 15px;
  background-color: #1abc9c;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}
</style>
