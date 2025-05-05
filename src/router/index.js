import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
    {
        path: '/',
        redirect: (to) => {
            const authStore = useAuthStore()
            if (!authStore.isAuthenticated) return '/login'

            switch (authStore.user?.role_id) {
                case 0: return '/student'
                case 1: return '/teacher'
                case 2: return '/admin'
                default: return '/login'
            }
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
        meta: { requiresAuth: true, allowedRoles: [0, 1, 2] }
    },
    {
        path: '/teacher',
        name: 'TeacherDashboard',
        component: () => import('@/views/Teacher/Dashboard.vue'),
        meta: { requiresAuth: true, allowedRoles: [1, 2] }
    },
    {
        path: '/admin',
        name: 'AdminDashboard',
        component: () => import('@/views/Admin/Dashboard.vue'),
        meta: { requiresAuth: true, allowedRoles: [2] }
    },
    // 捕获所有未匹配的路由
    {
        path: '/:pathMatch(.*)*',
        redirect: (to) => {
            const authStore = useAuthStore()
            if (!authStore.isAuthenticated) return '/login'

            switch (authStore.user?.role_id) {
                case 0: return '/student'
                case 1: return '/teacher'
                case 2: return '/admin'
                default: return '/login'
            }
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

    // 检查角色权限
    if (to.meta.allowedRoles) {
        const userRole = authStore.user?.role_id
        if (!userRole || !to.meta.allowedRoles.includes(userRole)) {
            // 根据用户角色重定向到合适的仪表盘
            switch (userRole) {
                case 0: return next('/student')
                case 1: return next('/teacher')
                case 2: return next('/admin')
                default: return next('/login')
            }
        }
    }

    next()
})

export default router