<template>
  <div class="register-container">
    <h1>用户注册</h1>
    <form @submit.prevent="handleSubmit">
      <div class="form-group">
        <label>邮箱</label>
        <input v-model="email" type="email" required>
      </div>

      <div class="form-group">
        <label>用户名</label>
        <input v-model="username" type="text" required>
      </div>

      <div class="form-group">
        <label>密码</label>
        <input v-model="password" type="password" required>
        <small>密码需包含大小写字母和数字，长度至少8位</small>
      </div>

      <div class="form-group">
        <label>确认密码</label>
        <input v-model="confirmPassword" type="password" required>
      </div>

      <div class="form-group" v-if="showCodeField">
        <label>验证码</label>
        <div class="code-input">
          <input v-model="code" type="text" required>
          <button
              type="button"
              @click="sendCode"
              :disabled="codeSent"
          >
            {{ codeSent ? `${countdown}s后重试` : '获取验证码' }}
          </button>
        </div>
      </div>

      <button
          type="button"
          class="submit-btn code-btn"
          @click="sendCode"
          :disabled="codeSent || showCodeField"
      >
        获取验证码
      </button>

      <button
          type="submit"
          class="submit-btn register-btn"
          :disabled="!showCodeField || loading"
      >
        {{ loading ? '处理中...' : '注册' }}
      </button>

      <div v-if="error" class="error-message">{{ error }}</div>

      <div class="login-link">
        已有账号？<router-link to="/login">立即登录</router-link>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import auth from "@/api/auth.js";

const email = ref('')
const username = ref('')
const password = ref('')
const confirmPassword = ref('')
const code = ref('')
const showCodeField = ref(false)
const codeSent = ref(false)
const countdown = ref(60)
const error = ref(null)
const loading = ref(false)

const router = useRouter()

const validatePassword = () => {
  const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[^]{8,}$/
  return regex.test(password.value)
}

const sendCode = async () => {
  error.value = null

  if (!email.value || !username.value || !password.value || !confirmPassword.value) {
    error.value = '请填写所有必填字段'
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

  try {
    await auth.sendRegisterCode(email.value)
    showCodeField.value = true
    codeSent.value = true
    startCountdown()
  } catch (err) {
    error.value = err.response?.data?.msg || '发送验证码失败'
  }
}

const startCountdown = () => {
  const timer = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0) {
      clearInterval(timer)
      codeSent.value = false
      countdown.value = 60
    }
  }, 1000)
}

const handleSubmit = async () => {
  if (!showCodeField.value) return

  error.value = null
  loading.value = true

  try {
    await auth.verifyRegisterCode({
      email: email.value,
      username: username.value,
      password: password.value,
      code: code.value
    })
    router.push('/login')
  } catch (err) {
    error.value = err.response?.data?.msg || '注册失败'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.register-container {
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

.code-input {
  display: flex;
  gap: 0.5rem;
}

button {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.submit-btn {
  width: 100%;
  padding: 0.75rem;
  margin-top: 0.5rem;
}

.register-btn {
  background: #28a745;
}

.code-btn {
  background: #007bff;
}

.error-message {
  color: #dc3545;
  margin-top: 1rem;
}

.login-link {
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