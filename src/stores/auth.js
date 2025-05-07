import { defineStore } from 'pinia'
import { ref } from 'vue'
import router from '@/router'

export const useAuthStore = defineStore('auth', () => {
    const user = ref(null)
    const isAuthenticated = ref(false)

    function setUser(userData) {
        user.value = userData
        isAuthenticated.value = true
        // 保存到localStorage
        localStorage.setItem('user', JSON.stringify(userData))
    }

    function clearUser() {
        user.value = null
        isAuthenticated.value = false
        localStorage.removeItem('user')
    }

    function loadUserFromStorage() {
        const userData = localStorage.getItem('user')
        if (userData) {
            user.value = JSON.parse(userData)
            isAuthenticated.value = true
        }
    }

    function isStudent() {
        return user.value?.role_id === 1
    }

    function isTeacher() {
        return user.value?.role_id === 2
    }

    function isAdmin() {
        return user.value?.role_id === 3
    }

    function redirectBasedOnRole() {
        if (isStudent()) {
            router.push('/admin')
        } else if (isTeacher()) {
            router.push('/teacher')
        } else if (isAdmin()) {
            router.push('/student')
        } else {
            router.push('/login')
        }
    }

    return {
        user,
        isAuthenticated,
        setUser,
        clearUser,
        loadUserFromStorage,
        isStudent,
        isTeacher,
        isAdmin,
        redirectBasedOnRole
    }
})