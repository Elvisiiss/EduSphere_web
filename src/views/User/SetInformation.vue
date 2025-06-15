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
        <button @click="showResetPasswordModal = true" class="reset-password-btn">重置密码</button>
        <button @click="saveInformation" class="save-btn">保存信息</button>
        <button @click="resetForm" class="reset-btn">重置</button>
      </div>
    </div>

    <div v-else class="loading">
      加载用户信息中...
    </div>

    <!-- Reset Password Modal -->
    <div v-if="showResetPasswordModal" class="modal-overlay" @click.self="showResetPasswordModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>重置密码</h3>
          <button class="modal-close" @click="showResetPasswordModal = false">&times;</button>
        </div>

        <div class="reset-methods-tabs">
          <button
              @click="activeResetMethod = 'password'"
              :class="{ active: activeResetMethod === 'password' }"
          >
            密码方式
          </button>
          <button
              @click="activeResetMethod = 'email'"
              :class="{ active: activeResetMethod === 'email' }"
          >
            邮箱方式
          </button>
        </div>

        <div class="reset-method-content">
          <!-- Password Method -->
          <div v-if="activeResetMethod === 'password'" class="password-method">
            <div class="form-group">
              <label>旧密码:</label>
              <input type="password" v-model="oldPassword" placeholder="请输入当前密码">
            </div>
            <div class="form-group">
              <label>新密码:</label>
              <input type="password" v-model="newPassword" placeholder="请输入新密码">
              <small class="password-hint">密码需包含大小写字母和数字，长度至少8位</small>
            </div>
            <div class="form-group">
              <label>确认新密码:</label>
              <input type="password" v-model="confirmNewPassword" placeholder="请再次输入新密码">
            </div>
            <button @click="resetPasswordWithOldPassword" class="submit-btn" :disabled="passwordLoading">
              <span v-if="!passwordLoading">确认修改</span>
              <span v-else class="loading-spinner"></span>
            </button>
            <div v-if="passwordError" class="error-message">
              <i class="error-icon"></i>
              <span>{{ passwordError }}</span>
            </div>
          </div>

          <!-- Email Method -->
          <div v-if="activeResetMethod === 'email'" class="email-method">
            <div class="form-group">
              <label>邮箱:</label>
              <input type="email" v-model="resetEmail" placeholder="请输入注册邮箱" required disabled>
            </div>
            <div class="form-group" v-if="showResetCodeField">
              <label>新密码:</label>
              <input type="password" v-model="resetPassword" placeholder="请输入新密码" required>
              <small class="password-hint">密码需包含大小写字母和数字，长度至少8位</small>
            </div>
            <div class="form-group" v-if="showResetCodeField">
              <label>确认新密码:</label>
              <input type="password" v-model="resetConfirmPassword" placeholder="请再次输入新密码" required>
            </div>
            <div class="form-group" v-if="showResetCodeField">
              <label>验证码:</label>
              <input type="text" v-model="resetCode" placeholder="请输入验证码" required>
            </div>
            <button @click="handleResetPassword" class="submit-btn" :disabled="emailLoading">
              <span v-if="!emailLoading">{{ showResetCodeField ? '重置密码' : '获取验证码' }}</span>
              <span v-else class="loading-spinner"></span>
            </button>
            <div v-if="emailError" class="error-message">
              <i class="error-icon"></i>
              <span>{{ emailError }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import myPower from '@/api/user.js'
import authApi from '@/api/auth'

const authStore = useAuthStore()
const token = authStore.user?.token
const userInfo = ref(null)
const originalInfo = ref(null)

// Reset Password Modal State
const showResetPasswordModal = ref(false)
const activeResetMethod = ref('password') // 'password' or 'email'

// Password method state
const oldPassword = ref('')
const newPassword = ref('')
const confirmNewPassword = ref('')
const passwordError = ref(null)
const passwordLoading = ref(false)

// Email method state
const resetEmail = ref(authStore.user?.e_mail)
const resetPassword = ref('')
const resetConfirmPassword = ref('')
const resetCode = ref('')
const showResetCodeField = ref(false)
const emailError = ref(null)
const emailLoading = ref(false)

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
    originalInfo.value = JSON.parse(JSON.stringify(userInfo.value)) // Update original after save
  } catch (error) {
    console.error('保存用户信息失败:', error)
  }
}

const resetForm = () => {
  if (originalInfo.value) {
    userInfo.value = JSON.parse(JSON.stringify(originalInfo.value))
  }
}

// Password reset methods
const validatePassword = (password) => {
  const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[^]{8,}$/
  return regex.test(password)
}

const resetPasswordWithOldPassword = async () => {
  if (!validatePassword(newPassword.value)) {
    passwordError.value = '密码需包含大小写字母和数字，长度至少8位'
    return
  }

  if (newPassword.value !== confirmNewPassword.value) {
    passwordError.value = '两次输入的密码不一致'
    return
  }

  passwordLoading.value = true
  passwordError.value = null

  try {
    const response = await myPower.resetPasswordWithOld(
      token,
      oldPassword.value,
      newPassword.value
    )

    if (response.data.code === 'success') {
      showResetPasswordModal.value = false
      // Clear form
      oldPassword.value = ''
      newPassword.value = ''
      confirmNewPassword.value = ''
    } else {
      passwordError.value = response.data.msg || '密码修改失败'
    }
  } catch (error) {
    console.error('密码修改失败:', error)
    passwordError.value = error.response?.data?.msg || '密码修改失败'
  } finally {
    passwordLoading.value = false
  }
}

const handleResetPassword = async () => {
  if (!showResetCodeField.value) {
    await sendResetCode()
    return
  }

  if (!validatePassword(resetPassword.value)) {
    emailError.value = '密码需包含大小写字母和数字，长度至少8位'
    return
  }

  if (resetPassword.value !== resetConfirmPassword.value) {
    emailError.value = '两次输入的密码不一致'
    return
  }

  emailLoading.value = true
  emailError.value = null

  try {
    const response = await authApi.verifyResetPasswordCode({
      email: resetEmail.value,
      password: resetPassword.value,
      code: resetCode.value
    })

    if (response.data.code === 'success') {
      showResetPasswordModal.value = false
      // Clear form
      resetEmail.value = ''
      resetPassword.value = ''
      resetConfirmPassword.value = ''
      resetCode.value = ''
      showResetCodeField.value = false
    } else {
      emailError.value = response.data.msg || '重置密码失败'
    }
  } catch (error) {
    console.error('重置密码失败:', error)
    emailError.value = error.response?.data?.msg || '重置密码失败'
  } finally {
    emailLoading.value = false
  }
}

const sendResetCode = async () => {
  emailLoading.value = true
  emailError.value = null

  try {
    await authApi.sendResetPasswordCode(resetEmail.value)
    showResetCodeField.value = true
  } catch (error) {
    console.error('发送验证码失败:', error)
    emailError.value = error.response?.data?.msg || '发送验证码失败'
  } finally {
    emailLoading.value = false
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
  position: relative;
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
  gap: 10px;
}

.reset-password-btn {
  padding: 10px 20px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.reset-password-btn:hover {
  background-color: #2980b9;
}

.save-btn {
  padding: 10px 20px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
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

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background-color: white;
  border-radius: 8px;
  width: 100%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
  padding: 20px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.modal-header h3 {
  margin: 0;
  font-size: 20px;
  color: #2c3e50;
}

.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #7f8c8d;
  padding: 0;
}

.modal-close:hover {
  color: #34495e;
}

.reset-methods-tabs {
  display: flex;
  border-bottom: 1px solid #e0e0e0;
  margin-bottom: 20px;
}

.reset-methods-tabs button {
  flex: 1;
  padding: 10px;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  cursor: pointer;
  font-weight: 500;
  color: #7f8c8d;
}

.reset-methods-tabs button.active {
  color: #3498db;
  border-bottom-color: #3498db;
}

.reset-method-content {
  padding: 10px 0;
}

.password-hint {
  color: #7f8c8d;
  font-size: 12px;
  margin-top: 5px;
  display: block;
}

.submit-btn {
  width: 100%;
  padding: 12px;
  background: #3498db;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  cursor: pointer;
  margin-top: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 48px;
}

.submit-btn:hover {
  background: #2980b9;
}

.submit-btn:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.error-message {
  display: flex;
  align-items: center;
  margin-top: 15px;
  padding: 10px;
  background: #fdecea;
  border-radius: 6px;
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
</style>
