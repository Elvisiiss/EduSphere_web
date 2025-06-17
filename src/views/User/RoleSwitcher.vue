<template>
  <div class="role-switcher">
    <h2>切换角色界面</h2>

    <div class="role-options">
      <button @click="switchToTeacher" class="role-btn teacher-btn">
        <i class="icon-teacher"></i>
        <span>教师面板</span>
      </button>

      <button @click="switchToStudent" class="role-btn student-btn">
        <i class="icon-student"></i>
        <span>学生面板</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {ElMessage} from "element-plus";

const router = useRouter()
const authStore = useAuthStore()
const powers = authStore.user?.powers || []

const switchToTeacher = () => {
  if (!powers.includes(2)){
    ElMessage.error("你无权去教师端")
  } else {
    router.push('/teacher')
    ElMessage.success("已切换")
  }
}

const switchToStudent = () => {
  if (!powers.includes(1)){
    ElMessage.error("你无权去学生端")
  } else {
    router.push('/student')
    ElMessage.success("已切换")
  }
}
</script>

<style scoped>
.role-switcher {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.role-options {
  display: flex;
  gap: 20px;
  margin-top: 20px;
}

.role-btn {
  flex: 1;
  padding: 30px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  transition: transform 0.3s, box-shadow 0.3s;
}

.role-btn:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.role-btn i {
  font-size: 2rem;
  margin-bottom: 10px;
}

.role-btn span {
  font-size: 1.2rem;
}

.teacher-btn {
  background-color: #3498db;
  color: white;
}

.student-btn {
  background-color: #2ecc71;
  color: white;
}
</style>
