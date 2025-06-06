import axios from 'axios'

const API_BASE_URL = 'http://10.168.82.63:8080/api/user'
// const API_BASE_URL = 'http://localhost:8080/api/user'

export default {
    // 获取我的所有信息
    getMyInformation(user_token) {
        return axios.post(`${API_BASE_URL}/get_my_information`, {
            msg: "获取我的所有信息",
            user_token: user_token
        })
    },

    // 设置我的所有信息
    setMyInformation(token, userInfo) {
        return axios.post(`${API_BASE_URL}/set_my_information`, {
            msg: "设置我的所有信息",
            user_token: token,
            user_id: userInfo.user_id,
            user_nick_name: userInfo.user_nick_name,
            user_gender: userInfo.user_gender,
            user_birthday: userInfo.user_birthday,
            user_personalized_signature: userInfo.user_personalized_signature,
            user_profile_picture: userInfo.user_profile_picture
        })
    },

    upload_img(user_token,file) {
        return axios.post(`${API_BASE_URL}/upload_img`, {
            msg: "上传图片",
            user_token: user_token,
            file: file
        })
    },

    get_all_my_img(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_my_img`, {
            msg: "获得我所有的图片",
            user_token: user_token
        })
    },

    delete_my_img(user_token, file_url) {
        return axios.post(`${API_BASE_URL}/delete_my_img`, {
            msg: "删除我的照片",
            file_url: file_url
        })
    }
}
