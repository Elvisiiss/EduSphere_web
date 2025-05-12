import axios from 'axios'

const API_BASE_URL = 'http://localhost:8080/api/admin'

export default {
    /**
     * 用户管理
     * */
    // 增加一个角色(用户管理：增)
    addOneUser(user_token, user_name, user_email, user_number, user_roles_id) {
        return axios.post(`${API_BASE_URL}/add_one_user`, {
            msg: "添加用户",
            user_token: user_token,
            user_name: user_name,
            user_email: user_email,
            user_password: user_number,
            user_number: user_number,
            user_roles_id: user_roles_id
        })
    },
    // 获取所有用户列表(用户管理：查)
    getAllUsers(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_users_info`, {
            msg: "获取所有用户",
            user_token: user_token
        })
    },
    getUserByUserId(user_token, user_id) {
        return axios.post(`${API_BASE_URL}/get_user_info_by_user_id`, {
            msg: "获取用户信息",
            user_token: user_token,
            user_id: user_id
        })
    },
    // 更新用户信息(用户管理：改)
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
    updateUserRole(user_token, user_id, user_roles_id) {
        return axios.post(`${API_BASE_URL}/update_user_role`, {
            msg: "更新用户角色",
            user_token: user_token,
            user_id: user_id,
            user_roles_id: user_roles_id
        })
    },
    // 删除用户(用户管理：删)
    deleteUser(user_token, user_id) {
        return axios.post(`${API_BASE_URL}/delete_user`, {
            user_token: user_token,
            user_id: user_id
        })
    },


    /**
     * 角色管理
     * */
    // 增加一个角色(用户管理：增)
    addOneRole(user_token, role_name, role_powers) {
        return axios.post(`${API_BASE_URL}/add_one_role`, {
            msg: "增加角色",
            user_token: user_token,
            role_name: role_name,
            role_powers: role_powers
        })
    },
    // 获取所有角色列表(用户管理：查)
    getAllRoles(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_roles`, {
            msg: "获取所有角色",
            user_token: user_token
        })
    },
    getRoleByRoleId(user_token, role_id) {
        return axios.post(`${API_BASE_URL}/get_role_info_by_role_id`, {
            msg: "获取角色的所有权力",
            user_token: user_token,
            user_id: role_id
        })
    },
    // 更新角色信息(角色管理：改)
    updateRole(user_token, role_name, role_id, role_powers) {
        return axios.post(`${API_BASE_URL}/update_role_power`, {
            msg: "更新角色权力",
            user_token: user_token,
            role_name: role_name,
            role_id: role_id,
            role_powers: role_powers
        })
    },
    // 删除角色(角色管理：删)
    deleteRole(user_token, role_id) {
        return axios.post(`${API_BASE_URL}/delete_role`, {
            user_token: user_token,
            role_id: role_id
        })
    },


    /**
     * 权限管理
     * */
    // 获取所有权限列表(用户管理：查)
    getAllPowers(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_powers`, {
            msg: "获取权限列表",
            user_token: user_token
        })
    },
}
