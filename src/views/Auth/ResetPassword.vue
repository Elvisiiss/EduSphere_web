<template>
  <div class="reset-password-container">
    <h1>重置密码</h1>
    <form @submit.prevent="handleSubmit">
      <div class="form-group">
        <label>邮箱</label>
        <input v-model="email" type="email" required>
      </div>

      <div class="form-group" v-if="showCodeField">
        <label>新密码</label>
        <input v-model="password" type="password" required>
        <small>密码需包含大小写字母和数字，长度至少8位</small>
      </div>

      <div class="form-group" v-if="showCodeField">
        <label>确认新密码</label>
        <input v-model="confirmPassword" type="password" required>
      </div>

      <div class="form-group" v-if="showCodeField">
        <label>验证码</label>
        <input v-model="code" type="text" required>
      </div>

      <button type="submit" class="submit-btn" :disabled="loading">
        {{ showCodeField ? '重置密码' : '获取验证码' }}
      </button>

      <div v-if="error" class="error-message">{{ error }}</div>

      <div class="links">
        <router-link to="/login">返回登录</router-link>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import useAuth from '@/composables/useAuth'
import auth from "@/api/auth.js";

const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const code = ref('')
const showCodeField = ref(false)

const { resetPassword, error, loading } = useAuth()
const router = useRouter()

const validatePassword = () => {
  const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[^]{8,}$/
  return regex.test(password.value)
}

const sendCode = async () => {
  try {
    await auth.sendResetPasswordCode(email.value)
    showCodeField.value = true
  } catch (err) {
    error.value = err.response?.data?.msg || '发送验证码失败'
  }
}

const handleSubmit = async () => {
  if (!showCodeField.value) {
    await sendCode()
    return
  }

  if (!validatePassword()) {
    error.value = '密码需包含大小写字母和数字，长度至少8位'
    return
  }

  if (password.value !== confirmPassword.value) {
    error.value = '两次输入的密码不一致'
    return
  }

  await resetPassword({
    email: email.value,
    password: password.value,
    code: code.value
  })
}
</script>

<style scoped>
.reset-password-container {
  max-width: 400px;
  margin: 0 auto;
  padding: 2rem;
  box-shadow: 0 0 10px rgba(0,0,0,0.1);
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

input {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.submit-btn {
  width: 100%;
  padding: 0.75rem;
  margin-top: 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.submit-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.error-message {
  color: #dc3545;
  margin-top: 1rem;
}

.links {
  margin-top: 1rem;
  text-align: center;
}

small {
  display: block;
  margin-top: 0.25rem;
  color: #6c757d;
  font-size: 0.875rem;
}
</style>