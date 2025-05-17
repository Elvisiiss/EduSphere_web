<template>
  <div class="my-classes">
    <h2>我的班级</h2>

    <div v-if="classes.length > 0" class="class-list">
      <div v-for="classItem in classes" :key="classItem.class_id" class="class-card">
        <div class="class-header">
          <h3>{{ classItem.class_name }} ({{ classItem.grade }})</h3>
        </div>

        <div class="class-info">
          <p>班主任: {{ classItem.head_teacher_name }}</p>
          <p>科目: {{ classItem.subjects.join(', ') }}</p>
          <p>同学人数: {{ classItem.student_count - 1 }}</p>
        </div>
      </div>
    </div>

    <div v-else class="no-classes">
      <p>您目前没有加入任何班级</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import studentApi from '@/api/student.js'

const authStore = useAuthStore()
const token = authStore.user?.token
const classes = ref([])

const fetchStudentClasses = async () => {
  try {
    const response = await studentApi.getStudentClasses(token)
    if (response.data) {
      classes.value = response.data
    }
  } catch (error) {
    console.error('获取班级列表失败:', error)
  }
}

onMounted(() => {
  fetchStudentClasses()
})
</script>

<style scoped>
.my-classes {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
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
  transition: box-shadow 0.3s;
}

.class-card:hover {
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.class-header {
  margin-bottom: 10px;
}

.class-info p {
  margin: 5px 0;
  color: #555;
}

.no-classes {
  margin-top: 20px;
  padding: 20px;
  text-align: center;
  background-color: #f9f9f9;
  border-radius: 5px;
}
</style>
