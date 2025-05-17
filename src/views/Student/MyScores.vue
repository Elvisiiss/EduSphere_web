<template>
  <div class="my-scores">
    <h2>我的成绩</h2>

    <div class="subject-selector">
      <label>选择科目:</label>
      <select v-model="selectedSubject" @change="fetchScoresBySubject">
        <option value="">全部科目</option>
        <option v-for="subject in subjects" :key="subject.subject_id" :value="subject.subject_id">
          {{ subject.subject_name }}
        </option>
      </select>
    </div>

    <div v-if="scores.length > 0" class="score-list">
      <table>
        <thead>
        <tr>
          <th>科目</th>
          <th>考试名称</th>
          <th>考试日期</th>
          <th>成绩</th>
          <th>评语</th>
          <th>批改老师</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="score in scores" :key="score.score_id">
          <td>{{ score.subject_name }}</td>
          <td>{{ score.exam_name }}</td>
          <td>{{ formatDate(score.exam_date) }}</td>
          <td>{{ score.score }}</td>
          <td>{{ score.comment || '无' }}</td>
          <td>{{ score.teacher_name }}</td>
        </tr>
        </tbody>
      </table>
    </div>

    <div v-else class="no-scores">
      <p>暂无成绩记录</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import studentApi from '@/api/student.js'

const authStore = useAuthStore()
const token = authStore.user?.token

const scores = ref([])
const subjects = ref([])
const selectedSubject = ref('')

const fetchStudentScores = async () => {
  try {
    const response = await studentApi.getStudentScores(token)
    if (response.data) {
      scores.value = response.data.scores
      subjects.value = response.data.subjects
    }
  } catch (error) {
    console.error('获取成绩列表失败:', error)
  }
}

const fetchScoresBySubject = async () => {
  if (!selectedSubject.value) {
    fetchStudentScores()
    return
  }

  try {
    const response = await studentApi.getScoresBySubject(token, selectedSubject.value)
    if (response.data) {
      scores.value = response.data
    }
  } catch (error) {
    console.error('按科目获取成绩失败:', error)
  }
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString()
}

onMounted(() => {
  fetchStudentScores()
})
</script>

<style scoped>
.my-scores {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.subject-selector {
  margin: 20px 0;
  display: flex;
  align-items: center;
}

.subject-selector select {
  margin-left: 10px;
  padding: 5px;
  border: 1px solid #ddd;
  border-radius: 3px;
}

.score-list {
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

.no-scores {
  margin-top: 20px;
  padding: 20px;
  text-align: center;
  background-color: #f9f9f9;
  border-radius: 5px;
}
</style>
