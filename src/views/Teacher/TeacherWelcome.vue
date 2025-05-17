<template>
  <div class="user-info">
    <p>欢迎, {{ authStore.user?.name }}</p>
    <p>邮箱: {{ authStore.user?.e_mail }}</p>
    <p>角色: 教师</p>
  </div>
  <div class="welcome-container">
    <div class="welcome-message">
      <h1>教师工作台</h1>
      <p>请从左侧边栏选择您要执行的操作</p>
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()
</script>

<style scoped>
.welcome-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 70vh;
}

.welcome-message {
  text-align: center;
  padding: 30px;
  background-color: white;
  border-radius: 10px;
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.welcome-message h1 {
  color: #3498db;
  margin-bottom: 20px;
}

.welcome-message p {
  color: #7f8c8d;
  font-size: 1.2rem;
}

.user-info {
  background-color: white;
  padding: 15px;
  margin-bottom: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}
</style>
