import {ref} from 'vue'
import {useRouter} from 'vue-router'
import {useAuthStore} from '@/stores/auth'
import authApi from '@/api/auth'

export default function useAuth() {
    const router = useRouter()
    const authStore = useAuthStore()
    const error = ref(null)
    const loading = ref(false)

    // 登录逻辑
    const login = async (credentials) => {
        loading.value = true
        error.value = null
        try {
            let response
            if (credentials.type === 'password') {
                response = await authApi.loginWithPassword(credentials)
            } else {
                response = await authApi.loginWithCode(credentials)
            }

            authStore.setUser(response.data)

            // 根据权限重定向
            if (response.data.powers_id.includes(3)) {
                router.push('/admin')
            } else if (response.data.powers_id.includes(2)) {
                router.push('/teacher')
            } else if (response.data.powers_id.includes(1)) {
                router.push('/student')
            } else {
                router.push('/login')
            }
        } catch (err) {
            error.value = err.response?.data?.msg || '登录失败'
        } finally {
            loading.value = false
        }
    }

    // 注册逻辑
    const register = async (userData) => {
        loading.value = true
        error.value = null
        try {
            // 1. 发送验证码
            await authApi.sendRegisterCode(userData.email)

            // 2. 验证验证码并注册
            const response = await authApi.verifyRegisterCode(userData)

            // 3. 自动登录
            await login({
                type: 'password',
                status: 1,
                account: userData.email,
                password: userData.password
            })
        } catch (err) {
            error.value = err.response?.data?.msg || '注册失败'
        } finally {
            loading.value = false
        }
    }

    // 重置密码
    const resetPassword = async (resetData) => {
        loading.value = true
        error.value = null
        try {
            // 1. 验证验证码并重置密码
            await authApi.verifyResetPasswordCode(resetData)

            // 2. 自动登录
            await login({
                type: 'password',
                status: 1,
                account: resetData.email,
                password: resetData.password
            })
        } catch (err) {
            error.value = err.response?.data?.msg || '重置密码失败'
        } finally {
            loading.value = false
        }
    }

    // 登出
    const logout = () => {
        authStore.clearUser()
        router.push('/login')
    }

    // 根据角色重定向
    const redirectBasedOnRole = (powers_id) => {
        if (powers_id.includes(3)) {
            router.push('/admin')
        } else if (powers_id.includes(2)) {
            router.push('/teacher')
        } else if (powers_id.includes(1)) {
            router.push('/student')
        } else {
            router.push('/login')
        }
    }

    return {
        login,
        register,
        resetPassword,
        logout,
        redirectBasedOnRole,
        error,
        loading
    }
}