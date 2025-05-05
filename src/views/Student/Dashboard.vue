<template>
  <div class="dashboard">
    <h1>学生仪表盘</h1>
    <p>欢迎, {{ authStore.user?.user_name }}</p>
    <p>邮箱: {{ authStore.user?.e_mail }}</p>
    <p>角色: 学生</p>

    <button @click="logout" class="logout-btn">退出登录</button>
  </div>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const logout = () => {
  authStore.clearUser()
  router.push('/login')
}
</script>

<style scoped>
.dashboard {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.logout-btn {
  margin-top: 1rem;
  padding: 0.5rem 1rem;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
</style>