import axios from 'axios'

const API_BASE_URL = 'http://localhost:8080/api/user'

export default {
    // 发送注册验证码
    sendRegisterCode(email) {
        return axios.post(`${API_BASE_URL}/register/send-code`, {
            msg: "创建用户发送验证码",
            e_mail: email
        })
    },

    // 验证注册验证码并创建用户
    verifyRegisterCode(data) {
        return axios.post(`${API_BASE_URL}/register/verify-code`, {
            msg: "创建用户确认验证码",
            e_mail: data.email,
            user_name: data.username,
            passwd: data.password,
            mail_code: data.code
        })
    },

    // 发送重置密码验证码
    sendResetPasswordCode(email) {
        return axios.post(`${API_BASE_URL}/reset-password/send-code`, {
            msg: "忘记密码发送验证码",
            e_mail: email
        })
    },

    // 验证重置密码验证码并设置新密码
    verifyResetPasswordCode(data) {
        return axios.post(`${API_BASE_URL}/reset-password/verify-code`, {
            msg: "提交新密码",
            e_mail: data.email,
            new_passwd: data.password,
            mail_code: data.code
        })
    },

    // 用户名密码登录
    loginWithPassword(data) {
        return axios.post(`${API_BASE_URL}/login/password`, {
            msg: data.status === 0 ? "登录用户名密码" : "登录邮箱密码",
            status: data.status,
            [data.status === 0 ? 'user_name' : 'e_mail']: data.account,
            passwd: data.password
        })
    },

    // 发送登录验证码
    sendLoginCode(email) {
        return axios.post(`${API_BASE_URL}/login/send-code`, {
            msg: "登录发送验证码",
            e_mail: email
        })
    },

    // 验证码登录
    loginWithCode(data) {
        return axios.post(`${API_BASE_URL}/login/verify-code`, {
            msg: "登录邮箱验证码",
            e_mail: data.email,
            mail_code: data.code
        })
    },

    // 获取用户数据
    getUserData(identifier) {
        return axios.post(`${API_BASE_URL}/get-data`, {
            msg: "获取数据",
            e_mail: identifier.includes('@') ? identifier : null,
            user_name: !identifier.includes('@') ? identifier : null
        })
    }
}