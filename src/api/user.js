import axios from 'axios'

const API_BASE_URL = 'http://localhost:8080/api/user'

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
    }
}
