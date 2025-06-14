<template>
  <div class="login-wrapper" :class="{ 'portrait-mode': isPortrait }">
    <div class="login-bg" v-if="isPortrait"></div>
    <div class="login-bg_h" v-else></div>
    <div class="login-container">
      <div class="login-header">
        <h1>学伴云平台</h1>
        <p>欢迎回来，请登录您的账号</p>
      </div>

      <form @submit.prevent="handleSubmit" class="login-form">
        <div class="form-group">
          <label>登录方式</label>
          <select v-model="loginType" class="form-control">
            <option value="user_number_password_login">学号登录</option>
            <option value="email_password_login">邮箱登录</option>
            <option value="verification_codes_login">验证码登录</option>
          </select>
        </div>

        <div class="form-group" v-if="loginType === 'user_number_password_login'">
          <label>学号</label>
          <input v-model="account" type="text" class="form-control" placeholder="请输入学号" required>
        </div>

        <div class="form-group" v-if="loginType === 'email_password_login' || loginType === 'verification_codes_login'">
          <label>邮箱</label>
          <input v-model="account" type="email" class="form-control" placeholder="请输入邮箱地址" required>
        </div>

        <div class="form-group" v-if="loginType === 'user_number_password_login' || loginType === 'email_password_login'">
          <label>密码</label>
          <input v-model="password" type="password" class="form-control" placeholder="请输入密码" required>
        </div>

        <div class="form-group" v-if="loginType === 'verification_codes_login'">
          <label>验证码</label>
          <div class="code-input-group">
            <input v-model="code" type="text" class="form-control" placeholder="请输入验证码" required>
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

        <button type="submit" class="submit-btn">
          <span v-if="!isLoading">登录</span>
          <span v-else class="loading-spinner"></span>
        </button>

        <div class="form-footer">
          <router-link to="/register" class="footer-link">注册账号</router-link>
          <router-link to="/reset-password" class="footer-link">忘记密码</router-link>
        </div>

        <div v-if="errorMessage" class="error-message">
          <i class="error-icon"></i>
          <span>{{ errorMessage }}</span>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import authApi from '@/api/auth'
import { useStorage } from '@vueuse/core'

const loginType = ref('user_number_password_login')
const account = ref('')
const password = ref('')
const code = ref('')
const codeSent = ref(false)
const countdown = ref(60)
const errorMessage = ref('')
const isLoading = ref(false)
const router = useRouter()
const authStore = useAuthStore()

// 添加屏幕方向检测
const isPortrait = ref(false)

const checkOrientation = () => {
  // 判断宽高比，小于1表示竖屏（手机端）
  isPortrait.value = window.innerWidth <= window.innerHeight
}

onMounted(() => {
  checkOrientation()
  window.addEventListener('resize', checkOrientation)
})

onUnmounted(() => {
  window.removeEventListener('resize', checkOrientation)
})

const token = useStorage('user_token', null, undefined, {
  serializer: {
    read: (v) => {
      if (!v) return null;
      try {
        return JSON.parse(v);
      } catch (e) {
        return null;
      }
    },
    write: (v) => JSON.stringify(v)
  }
})

const sendCode = async () => {
  if (!account.value.includes('@')) {
    errorMessage.value = '请输入有效的邮箱地址'
    return
  }

  try {
    await authApi.sendLoginCode(account.value)
    codeSent.value = true
    startCountdown()
  } catch (error) {
    errorMessage.value = error.response?.data?.msg || '发送验证码失败'
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
  errorMessage.value = ''
  isLoading.value = true

  try {
    let response
    if (loginType.value === 'user_number_password_login') {
      response = await authApi.loginWithPassword({
        status: 0,
        account: account.value,
        password: password.value
      })
    } else if (loginType.value === 'email_password_login') {
      response = await authApi.loginWithPassword({
        status: 1,
        account: account.value,
        password: password.value
      })
    } else if (loginType.value === 'verification_codes_login') {
      response = await authApi.loginWithCode({
        email: account.value,
        code: code.value
      })
    }

    authStore.setUser(response.data)

    const powers = response.data.powers_id
    if (powers.includes(3)) {
      router.push('/admin')
    } else if (powers.includes(2)) {
      router.push('/teacher')
    } else if (powers.includes(1)) {
      router.push('/student')
    } else {
      // 处理无权限情况
      authStore.clearUser()
      errorMessage.value = '您的账号没有访问权限'
    }
  } catch (error) {
    errorMessage.value = error.response?.data?.msg || '登录失败，请检查您的账号和密码'
  } finally {
    isLoading.value = false
  }
}
</script>


<style scoped>
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

.login-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 20px;
  position: relative;
}

.login-wrapper.portrait-mode {
  background: transparent;
}

.login-bg {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url('@/assets/login_background_perpendicular.jpg');
  background-size: cover;
  background-position: center;
  filter: blur(10px);
  z-index: 0;
}

.login-bg_h {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url('@/assets/login_background_horizontal.jpg');
  background-size: cover;
  background-position: center;
  filter: blur(10px);
  z-index: 0;
}

.login-container {
  width: 100%;
  max-width: 420px;
  background: rgba(255, 255, 255, 0.85);
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  padding: 40px;
  animation: fadeIn 0.5s ease;
  position: relative;
  z-index: 1;
}

/* 竖屏模式下容器背景半透明 */
.login-wrapper.portrait-mode .login-container {
  background: rgba(255, 255, 255, 0.85);
}

</style>
