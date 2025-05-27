import axios from 'axios'

const API_BASE_URL = 'http://10.168.82.63:8080/api/student'

export default {
    // 获取学生个人信息
    getStudentInfo(user_token) {
        return axios.post(`${API_BASE_URL}/get_student_info`, {
            user_token: user_token
        })
    },

    // 获取学生所在班级
    getStudentClasses(user_token) {
        return axios.post(`${API_BASE_URL}/get_student_classes`, {
            user_token: user_token
        })
    },

    // 获取学生成绩
    getStudentScores(user_token) {
        return axios.post(`${API_BASE_URL}/get_student_scores`, {
            user_token: user_token
        })
    },

    // 按科目筛选成绩
    getScoresBySubject(user_token, subject_id) {
        return axios.post(`${API_BASE_URL}/get_scores_by_subject`, {
            user_token: user_token,
            subject_id: subject_id
        })
    },

    //获得所有老师的名字，角色是教师和班主任。
    get_all_teacher_name(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_teacher_name`, {
            user_token: user_token
        })
    }
}
