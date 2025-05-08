import axios from 'axios'

const API_BASE_URL = 'http://localhost:8080/api'

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
        return axios.put(`${API_BASE_URL}/admin/users/${userId}`, data)
    },

    // 获取所有用户列表（管理员专用）
    getAllUsers(token) {
        return axios.post(`${API_BASE_URL}/admin/get_all_users_info`, {
            msg: "获取所有用户",
            user_token: token
        })
    },

    // 删除用户（管理员专用）
    deleteUser(token, user_id) {
        return axios.post(`${API_BASE_URL}/user-delete/users/${user_id}`, {
            token: token
        })
    }
}