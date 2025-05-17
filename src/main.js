import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import {useAuthStore} from "@/stores/auth.js";

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)

// 在挂载前加载用户数据
const authStore = useAuthStore()
authStore.loadUserFromStorage()

app.mount('#app')
