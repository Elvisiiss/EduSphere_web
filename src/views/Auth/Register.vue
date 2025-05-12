<template>
  <div class="login-wrapper">
    <div class="login-container">
      <div class="login-header">
        <h1>学伴云平台</h1>
        <p>创建您的账号</p>
      </div>

      <form @submit.prevent="handleSubmit" class="login-form">
        <div class="form-group">
          <label>邮箱</label>
          <input v-model="email" type="email" class="form-control" placeholder="请输入邮箱地址" required>
        </div>

        <div class="form-group">
          <label>用户名</label>
          <input v-model="username" type="text" class="form-control" placeholder="请输入用户名" required>
        </div>

        <div class="form-group">
          <label>密码</label>
          <input v-model="password" type="password" class="form-control" placeholder="请输入密码" required>
          <small class="password-hint">密码需包含大小写字母和数字，长度至少8位</small>
        </div>

        <div class="form-group">
          <label>确认密码</label>
          <input v-model="confirmPassword" type="password" class="form-control" placeholder="请再次输入密码" required>
        </div>

        <div class="form-group">
          <label>验证码</label>
          <div class="code-input-group">
            <input
                v-model="code"
                type="text"
                class="form-control"
                placeholder="请输入验证码"
                required
                :disabled="!codeSent"
            >
            <button
                type="button"
                @click="sendCode"
                :disabled="codeSent"
                class="code-btn"
            >
              {{ codeSent ? `${countdown}s后重试` : '获取验证码' }}
            </button>
          </div>
        </div>

        <button
            type="submit"
            class="submit-btn register-btn"
            :disabled="loading"
        >
          <span v-if="!loading">注册</span>
          <span v-else class="loading-spinner"></span>
        </button>

        <div v-if="error" class="error-message">
          <i class="error-icon"></i>
          <span>{{ error }}</span>
        </div>

        <div class="form-footer">
          <router-link to="/login" class="footer-link">已有账号？立即登录</router-link>
        </div>
      </form>
    </div>
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
  if (!codeSent.value) return

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
.password-hint {
  color: #7f8c8d;
  font-size: 12px;
  margin-top: 5px;
}

.register-btn {
  background: #2ecc71;
}

.register-btn:hover {
  background: #27ae60;
}

/* 其他样式继承自Login.vue的样式 */
.login-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 20px;
}

.login-container {
  width: 100%;
  max-width: 420px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  padding: 40px;
  animation: fadeIn 0.5s ease;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h1 {
  color: #2c3e50;
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

.login-header p {
  color: #7f8c8d;
  font-size: 14px;
}

.login-form {
  margin-top: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-size: 14px;
  color: #34495e;
  font-weight: 500;
}

.form-control {
  width: 100%;
  padding: 12px 15px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  font-size: 14px;
  transition: border-color 0.3s;
  box-sizing: border-box;
}

.form-control:focus {
  border-color: #3498db;
  outline: none;
  box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
}

.code-input-group {
  display: flex;
  gap: 10px;
}

.code-btn {
  flex-shrink: 0;
  padding: 0 15px;
  background: #f8f9fa;
  color: #3498db;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.code-btn:hover:not(:disabled) {
  background: #e3f2fd;
}

.code-btn:disabled {
  color: #95a5a6;
  cursor: not-allowed;
  background: #f8f9fa;
}

.submit-btn {
  width: 100%;
  padding: 14px;
  background: #3498db;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s;
  margin-top: 10px;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 48px;
}

.submit-btn:hover {
  background: #2980b9;
}

.form-footer {
  display: flex;
  justify-content: space-between;
  margin-top: 20px;
}

.footer-link {
  color: #7f8c8d;
  font-size: 13px;
  text-decoration: none;
  transition: color 0.3s;
}

.footer-link:hover {
  color: #3498db;
}

.error-message {
  display: flex;
  align-items: center;
  margin-top: 20px;
  padding: 12px;
  background: #fdecea;
  border-radius: 8px;
  color: #d32f2f;
  font-size: 14px;
}

.error-icon {
  display: inline-block;
  width: 18px;
  height: 18px;
  margin-right: 8px;
  background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%23d32f2f"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>') no-repeat center;
}

.loading-spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 480px) {
  .login-container {
    padding: 30px 20px;
  }

  .code-input-group {
    flex-direction: column;
  }

  .code-btn {
    padding: 12px;
  }
}
</style>
