import axios from 'axios'

const API_BASE_URL = 'http://localhost:8080/api/admin'

export default {
    // 更新用户信息
    updateUser(user_token, user_id, user_number, user_name, user_email, user_password) {
        return axios.post(`${API_BASE_URL}/update_user_info`, {
            msg: "更新用户信息",
            user_token: user_token,
            user_id: user_id,
            user_number: user_number,
            user_name: user_name,
            user_email: user_email,
            user_password: user_password
        })
    },

    // 获取所有用户列表（管理员专用）
    getAllUsers(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_users_info`, {
            msg: "获取所有用户",
            user_token: user_token
        })
    },

    // 删除用户（管理员专用）
    deleteUser(user_token, user_id) {
        return axios.post(`${API_BASE_URL}/user-delete/${user_id}`, {
            token: user_token
        })
    },

    getUserByUserId(user_token, user_id) {
        return axios.post(`${API_BASE_URL}/get_user_info_by_user_id`, {
            msg: "获取用户信息",
            user_token: user_token,
            user_id: user_id
        })
    }
}