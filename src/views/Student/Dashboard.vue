<template>
  <div class="dashboard-container">
    <!-- 侧边栏 -->
    <div class="sidebar" :class="{ 'sidebar-collapsed': isCollapsed }">
      <button class="toggle-btn" @click="toggleSidebar">
        {{ isCollapsed ? '展开边栏' : '收起边栏' }}
      </button>

      <div class="sidebar-content" v-if="!isCollapsed">
        <button class="sidebar-btn" @click="setActiveComponent('StudentWelcome')">
          <i class="icon-home"></i> 学生首页
        </button>
        <button class="sidebar-btn" @click="setActiveComponent('MyClasses')">
          <i class="icon-class"></i> 我的班级
        </button>
        <button class="sidebar-btn" @click="setActiveComponent('MyScores')">
          <i class="icon-score"></i> 我的成绩
        </button>
        <button class="sidebar-btn" @click="setActiveComponent('RoleSwitcher')">
          <i class="icon-role"></i> 切换角色
        </button>
        <button class="sidebar-btn logout-btn" @click="logout">
          <i class="icon-logout"></i> 退出登录
        </button>
      </div>

      <!-- 个人信息按钮 -->
      <div class="profile-btn-container" @click="setActiveComponent('SetInformation')">
        <div class="profile-btn">
          <img :src="userAvatar" class="profile-avatar" @error="handleAvatarError">
          <span v-if="!isCollapsed" class="profile-text">个人信息</span>
        </div>
      </div>
    </div>

    <!-- 主内容区 -->
    <div class="main-content">
      <component :is="activeComponent" />
    </div>
  </div>
</template>

<script setup>
import { ref, shallowRef, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import myPower from '@/api/user.js'

import StudentWelcome from '@/views/Student/StudentWelcome.vue'
import MyClasses from '@/views/Student/MyClasses.vue'
import MyScores from '@/views/Student/MyScores.vue'
import RoleSwitcher from '@/views/User/RoleSwitcher.vue'
import SetInformation from "@/views/User/SetInformation.vue";

const authStore = useAuthStore()
const router = useRouter()

const isCollapsed = ref(true)
const activeComponent = shallowRef(StudentWelcome)
const userAvatar = ref('logo.svg')

const fetchUserAvatar = async () => {
  try {
    const token = authStore.user?.token
    if (!token) return

    const response = await myPower.getMyInformation(token)
    if (response.data?.user_profile_picture) {
      userAvatar.value = response.data.user_profile_picture
    }
  } catch (error) {
    console.error('获取用户头像失败:', error)
  }
}

const handleAvatarError = () => {
  userAvatar.value = 'logo.svg'
}

const toggleSidebar = () => {
  isCollapsed.value = !isCollapsed.value
}

const setActiveComponent = (component) => {
  switch(component) {
    case 'StudentWelcome':
      activeComponent.value = StudentWelcome
      break
    case 'MyClasses':
      activeComponent.value = MyClasses
      break
    case 'MyScores':
      activeComponent.value = MyScores
      break
    case 'RoleSwitcher':
      activeComponent.value = RoleSwitcher
      break
    case 'SetInformation':
      activeComponent.value = SetInformation
      break
    default:
      activeComponent.value = StudentWelcome
  }
}

const logout = () => {
  authStore.clearUser()
  router.push('/login')
}

onMounted(() => {
  fetchUserAvatar()
})
</script>

<style scoped>
/* 样式与Admin Dashboard类似，可以复用 */
.dashboard-container {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: 250px;
  background-color: #2c3e50;
  color: white;
  transition: all 0.3s ease;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  position: relative;
}

.sidebar-collapsed {
  width: 60px;
}

.toggle-btn {
  width: 100%;
  padding: 10px;
  background-color: #34495e;
  color: white;
  border: none;
  cursor: pointer;
}

.sidebar-content {
  padding: 20px;
  flex: 1;
}

.sidebar-btn {
  display: block;
  width: 100%;
  padding: 10px;
  margin-bottom: 10px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.3s;
}

.sidebar-btn:hover {
  background-color: #2980b9;
}

.sidebar-btn i {
  margin-right: 10px;
}

.logout-btn {
  background-color: #e74c3c;
}

.logout-btn:hover {
  background-color: #c0392b;
}

.main-content {
  flex: 1;
  padding: 20px;
  background-color: #f5f5f5;
}

.profile-btn-container {
  padding: 10px;
  cursor: pointer;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  transition: background-color 0.3s;
  margin-top: auto;
}

.profile-btn-container:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.profile-btn {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 5px;
}

.profile-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
}

.profile-text {
  font-size: 14px;
  color: white;
}

.sidebar-collapsed .profile-btn-container {
  padding: 10px 5px;
  display: flex;
  justify-content: center;
}

.sidebar-collapsed .profile-btn {
  justify-content: center;
}

.sidebar-collapsed .profile-avatar {
  margin: 0;
}
</style>
