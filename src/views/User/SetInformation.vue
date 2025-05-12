<template>
  <div class="set-information">
    <h2>个人信息设置</h2>

    <div v-if="userInfo" class="info-form">
      <div class="form-group">
        <label>用户ID:</label>
        <input type="text" v-model="userInfo.user_id" disabled>
      </div>
      <div class="form-group">
        <label>昵称:</label>
        <input type="text" v-model="userInfo.user_nick_name">
      </div>
      <div class="form-group">
        <label>性别:</label>
        <select v-model="userInfo.user_gender">
          <option value="">请选择</option>
          <option value="男">男</option>
          <option value="女">女</option>
          <option value="其他">其他</option>
        </select>
      </div>
      <div class="form-group">
        <label>生日:</label>
        <input type="date" v-model="userInfo.user_birthday">
      </div>
      <div class="form-group">
        <label>个性签名:</label>
        <textarea v-model="userInfo.user_personalized_signature" rows="3"></textarea>
      </div>
      <div class="form-group">
        <label>头像URL:</label>
        <input type="text" v-model="userInfo.user_profile_picture">
        <div v-if="userInfo.user_profile_picture" class="avatar-preview">
          <img :src="userInfo.user_profile_picture" alt="头像预览" class="avatar-img">
        </div>
      </div>
      <div class="form-actions">
        <button @click="saveInformation" class="save-btn">保存信息</button>
        <button @click="resetForm" class="reset-btn">重置</button>
      </div>
    </div>

    <div v-else class="loading">
      加载用户信息中...
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import myPower from '@/api/user.js'

const authStore = useAuthStore()
const token = authStore.user?.token
const userInfo = ref(null)
const originalInfo = ref(null)

const fetchUserInformation = async () => {
  try {
    if (!token) {
      console.error('未找到用户token')
      return
    }
    const response = await myPower.getMyInformation(token)
    userInfo.value = response.data
    originalInfo.value = JSON.parse(JSON.stringify(response.data)) // Deep copy for reset
  } catch (error) {
    console.error('获取用户信息失败:', error)
  }
}

const saveInformation = async () => {
  try {
    console.log('Sending:', {
      token,
      userInfo: {...userInfo.value}
    });
    console.log({...userInfo.value})
    await myPower.setMyInformation(token, {...userInfo.value})
    alert('信息保存成功!')
    originalInfo.value = JSON.parse(JSON.stringify(userInfo.value)) // Update original after save
  } catch (error) {
    console.error('保存用户信息失败:', error)
    alert('保存失败，请重试')
  }
}

const resetForm = () => {
  if (originalInfo.value) {
    userInfo.value = JSON.parse(JSON.stringify(originalInfo.value))
  }
}

onMounted(() => {
  fetchUserInformation()
})
</script>

<style scoped>
.set-information {
  background-color: white;
  padding: 20px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  max-width: 800px;
  margin: 0 auto;
}

.info-form {
  margin-top: 20px;
}

.form-group {
  margin-bottom: 20px;
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
  border-radius: 4px;
  box-sizing: border-box;
}

.form-group textarea {
  resize: vertical;
}

.form-group select {
  height: 38px;
}

.avatar-preview {
  margin-top: 10px;
}

.avatar-img {
  max-width: 100px;
  max-height: 100px;
  border-radius: 50%;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 30px;
}

.save-btn {
  padding: 10px 20px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin-right: 10px;
}

.save-btn:hover {
  background-color: #27ae60;
}

.reset-btn {
  padding: 10px 20px;
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.reset-btn:hover {
  background-color: #7f8c8d;
}

.loading {
  text-align: center;
  padding: 20px;
  color: #7f8c8d;
}
</style>
