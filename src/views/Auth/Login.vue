<template>
  <div class="login-container">
    <h1>学伴云平台登录</h1>
    <form @submit.prevent="handleSubmit">
      <div class="form-group">
        <label>登录方式</label>
        <select v-model="loginType">
          <option value="password">密码登录</option>
          <option value="code">验证码登录</option>
        </select>
      </div>

      <div class="form-group">
        <label>{{ loginType === 'password' ? '用户名/邮箱' : '邮箱' }}</label>
        <input
            v-model="account"
            :type="loginType === 'password' ? 'text' : 'email'"
            required
        >
      </div>

      <div class="form-group" v-if="loginType === 'password'">
        <label>密码</label>
        <input v-model="password" type="password" required>
      </div>

      <div class="form-group" v-if="loginType === 'code'">
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

      <button type="submit" class="submit-btn">登录</button>

      <div class="links">
        <router-link to="/register">注册账号</router-link>
        <router-link to="/reset-password">忘记密码</router-link>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import authApi from '@/api/auth'

const loginType = ref('password')
const account = ref('')
const password = ref('')
const code = ref('')
const codeSent = ref(false)
const countdown = ref(60)
const errorMessage = ref('')
const router = useRouter()
const authStore = useAuthStore()

const sendCode = async () => {
  if (!account.value.includes('@')) {
    errorMessage.value = '验证码登录需要使用邮箱'
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
  try {
    let response
    if (loginType.value === 'password') {
      const status = account.value.includes('@') ? 1 : 0
      response = await authApi.loginWithPassword({
        status,
        account: account.value,
        password: password.value
      })
    } else {
      response = await authApi.loginWithCode({
        email: account.value,
        code: code.value
      })
    }

    authStore.setUser(response.data)

    // 根据角色跳转到不同页面
    if (response.data.role_id === 0) {
      router.push('/student')
    } else {
      router.push('/teacher')
    }
  } catch (error) {
    errorMessage.value = error.response?.data?.msg || '登录失败'
  }
}
</script>

<style scoped>
.login-container {
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
}

input, select {
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
}

.submit-btn {
  width: 100%;
  padding: 0.75rem;
  margin-top: 1rem;
}

.links {
  display: flex;
  justify-content: space-between;
  margin-top: 1rem;
}

.error {
  color: red;
  margin-top: 1rem;
}
</style>