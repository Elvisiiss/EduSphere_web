import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
    {
        path: '/',
        redirect: (to) => {
            const authStore = useAuthStore()
            if (!authStore.isAuthenticated) return '/login'

            const powers = authStore.user?.powers || []

            // 按照优先级重定向
            if (powers.includes(3)) return '/admin'
            if (powers.includes(2)) return '/teacher'
            if (powers.includes(1)) return '/student'
            return '/login'
        }
    },
    {
        path: '/login',
        name: 'Login',
        component: () => import('@/views/Auth/Login.vue'),
        meta: { requiresAuth: false }
    },
    {
        path: '/register',
        name: 'Register',
        component: () => import('@/views/Auth/Register.vue'),
        meta: { requiresAuth: false }
    },
    {
        path: '/reset-password',
        name: 'ResetPassword',
        component: () => import('@/views/Auth/ResetPassword.vue'),
        meta: { requiresAuth: false }
    },
    {
        path: '/student',
        name: 'StudentDashboard',
        component: () => import('@/views/Student/Dashboard.vue'),
        meta: {
            requiresAuth: true,
            requiredPower: 1  // 必须拥有power 1才能访问
        }
    },
    {
        path: '/teacher',
        name: 'TeacherDashboard',
        component: () => import('@/views/Teacher/Dashboard.vue'),
        meta: {
            requiresAuth: true,
            requiredPower: 2  // 必须拥有power 2才能访问
        }
    },
    {
        path: '/admin',
        name: 'AdminDashboard',
        component: () => import('@/views/Admin/Dashboard.vue'),
        meta: {
            requiresAuth: true,
            requiredPower: 3  // 必须拥有power 3才能访问
        }
    },
    // 捕获所有未匹配的路由
    {
        path: '/:pathMatch(.*)*',
        redirect: (to) => {
            const authStore = useAuthStore()
            if (!authStore.isAuthenticated) return '/login'

            const powers = authStore.user?.powers || []

            if (powers.includes(3)) return '/admin'
            if (powers.includes(2)) return '/teacher'
            if (powers.includes(1)) return '/student'
            return '/login'
        }
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

router.beforeEach((to, from, next) => {
    const authStore = useAuthStore()

    // 检查是否需要认证
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
        return next('/login')
    }

    // 检查权限
    if (to.meta.requiredPower) {
        const userPowers = authStore.user?.powers || []

        if (!userPowers.includes(to.meta.requiredPower)) {
            // 根据用户拥有的最高权限重定向
            if (userPowers.includes(3)) {
                return next('/admin')
            } else if (userPowers.includes(2)) {
                return next('/teacher')
            } else if (userPowers.includes(1)) {
                return next('/student')
            } else {
                return next('/login')
            }
        }
    }

    next()
})

export default router