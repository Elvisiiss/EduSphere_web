import axios from 'axios'

const API_BASE_URL = 'http://10.168.82.63:8080/api/teacher'

export default {
    // 获取教师个人信息
    getTeacherInfo(user_token) {
        return axios.post(`${API_BASE_URL}/get_teacher_info`, {
            user_token: user_token
        })
    },

    // 获取教师所教班级列表
    getTeacherClasses(user_token) {
        return axios.post(`${API_BASE_URL}/get_teacher_classes`, {
            user_token: user_token
        })
    },

    // 获取班级学生列表
    getClassStudents(user_token, class_id) {
        return axios.post(`${API_BASE_URL}/get_class_students`, {
            user_token: user_token,
            class_id: Number(class_id)
        })
    },

    // 分析用，获得所有有关班级成绩
    getTeacherClassForAll(user_token) {
        return axios.post(`${API_BASE_URL}/get_teacher_class_for_all`, {
            user_token: user_token
        })
    },



    // 提交学生成绩
    submitStudentScore(user_token, class_id, student_id, subject_id, exam_name, exam_date, score, comment) {
        return axios.post(`${API_BASE_URL}/submit_student_score`, {
            user_token: user_token,
            class_id: class_id,
            student_id: student_id,
            subject_id: subject_id,
            exam_name: exam_name,
            exam_date: exam_date,
            score: score,
            comment: comment
        })
    },

    // 更新学生成绩
    updateStudentScore(user_token, score_id, score, comment) {
        return axios.post(`${API_BASE_URL}/update_student_score`, {
            user_token: user_token,
            score_id: score_id,
            score: score,
            comment: comment
        })
    },

    // 获取班级成绩
    getClassScores(user_token, class_id, subject_id, exam_name) {
        return axios.post(`${API_BASE_URL}/get_class_scores`, {
            user_token: user_token,
            class_id: Number(class_id),
            subject_id: subject_id,
            exam_name: exam_name
        })
    },

    // 获取班级其他科目成绩(只读)
    getOtherSubjectScores(user_token, class_id) {
        return axios.post(`${API_BASE_URL}/get_other_subject_scores`, {
            user_token: user_token,
            class_id: class_id
        })
    },
    // 删除学生成绩
    deleteStudentScore(user_token, score_id) {
        return axios.post(`${API_BASE_URL}/delete_student_score`, {
            user_token: user_token,
            score_id: score_id
        })
    },
    // 获取学生所有科目成绩
    getStudentAllScores(user_token, student_id) {
        return axios.post(`${API_BASE_URL}/get_student_all_scores`, {
            user_token: user_token,
            student_id: student_id
        })
    },

    // 添加学生到班级
    addStudentToClass(user_token, class_id, student_data) {
        return axios.post(`${API_BASE_URL}/add_student_to_class`, {
            user_token: user_token,
            class_id: class_id,
            student_data: student_data
        })
    },

    // 更新学生信息
    updateStudentInfo(user_token, student_id, student_data) {
        return axios.post(`${API_BASE_URL}/update_student_info`, {
            user_token: user_token,
            student_id: student_id,
            student_data: student_data
        })
    },

    // 从班级移除学生
    removeStudentFromClass(user_token, class_id, student_id) {
        return axios.post(`${API_BASE_URL}/remove_student_from_class`, {
            user_token: user_token,
            class_id: Number(class_id),
            student_id: student_id
        })
    },

    // 获取所有非本班学生用户（分页）
    getNonClassStudents(user_token, class_id, page = 1, page_size = 10) {
        return axios.post(`${API_BASE_URL}/get_non_class_students`, {
            user_token: user_token,
            class_id: class_id,
            page: page,
            page_size: page_size
        })
    },

    addStudentsToClass(user_token, class_id, student_id) {
        return axios.post(`${API_BASE_URL}/add_students_to_class`, {
            user_token: user_token,
            class_id: class_id,
            student_id: student_id
        })
    },

    importStudentScores(user_token, class_id, subject_id, scores) {
        return axios.post(`${API_BASE_URL}/import_student_scores`, {
            user_token: user_token,
            class_id: class_id,
            subject_id: subject_id,
            scores: scores
        })
    },
}
