import axios from 'axios'

const API_BASE_URL = 'http://localhost:8080/api/user'

export default {
    // 获取用户数据
    getUserData(identifier) {
        return axios.post(`${API_BASE_URL}/get-data`, {
            msg: "获取数据",
            e_mail: identifier.includes('@') ? identifier : null,
            user_name: !identifier.includes('@') ? identifier : null
        })
    },

    // 更新用户信息
    updateUser(userId, data) {
        return axios.put(`${API_BASE_URL}/users/${userId}`, data)
    },

    // 获取所有用户列表（管理员专用）
    getAllUsers() {
        return axios.get(`${API_BASE_URL}/users`)
    },

    // 删除用户（管理员专用）
    deleteUser(userId) {
        return axios.delete(`${API_BASE_URL}/users/${userId}`)
    }
}