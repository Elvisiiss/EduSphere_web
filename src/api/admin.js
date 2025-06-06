import axios from 'axios'

const API_BASE_URL = 'http://10.168.82.63:8080/api/admin'
// const API_BASE_URL = 'http://localhost:8080/api/admin'

export default {
    /**
     * 用户管理  users表
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
     * 角色管理  roles表
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
     * 权限管理  powers表
     * */
    // 获取所有权限列表(权限管理：查)
    getAllPowers(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_powers`, {
            msg: "获取权限列表",
            user_token: user_token
        })
    },


    /**
     * 学科管理 subjects表
     */
    //增加一个学科(学科管理：增)
    addOneSubject(user_token,subject_name,subject_desc) {
        return axios.post(`${API_BASE_URL}/add_one_subject`, {
            msg: "增加学科",
            user_token: user_token,
            subject_name: subject_name,
            subject_desc: subject_desc
        })
    },

    //获取所有学科信息(学科管理:查)
    getAllSubjects(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_subjects`, {
            msg: "获取所有学科信息",
            user_token: user_token
        })
    },

    //修改学科(学科管理:改)
    updateSubject(user_token,subject_id,subject_name,subject_desc) {
        return axios.post(`${API_BASE_URL}/update_subject`, {
            msg: "修改学科",
            user_token: user_token,
            subject_id: subject_id,
            subject_name: subject_name,
            subject_desc: subject_desc
        })
    },


    //删除学科(学科管理:删)
    deleteSubject(user_token,subject_id) {
        return axios.post(`${API_BASE_URL}/delete_subject`, {
            msg: "删除学科",
            user_token: user_token,
            subject_id: subject_id,
        })
    },


    /**
     * 班级管理  classes表
    * */
    //增加一个班级(班级管理：增)
    addOneClass(user_token, class_name, class_grade, head_teacher_id, subjects_id, subject_teacher) {
        return axios.post(`${API_BASE_URL}/add_one_class`, {
            msg: "增加班级",
            user_token: user_token,
            class_name: class_name,
            class_grade: class_grade,
            head_teacher_id: head_teacher_id,
            subjects_id: subjects_id,
            subject_teacher: subject_teacher
        })
    },
    //获取所有的班级(班级管理：查)
    getAllClasses(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_classes`, {
            msg: "获取所有班级",
            user_token: user_token,
        })
    },

    //获取所有的教师
    getAllTeacher(user_token) {
        return axios.post(`${API_BASE_URL}/get_all_teacher`, {
            msg: "获取所有的教师",
            user_token: user_token,
        })
        /*
        响应：
        [
            {
            user_id:1,
            user_name:"李世民",
            role_name:"班主任"
            },{
            user_id:1,
            user_name:"李世民",
            role_name:"教师"
            },{
            user_id:2,
            user_name:"李翔",
            role_name:"教师"
            }

        ]
        * */
    },

    //修改班级信息(班级管理:改)
    updateClassInformation(user_token, class_id, class_name, class_grade, head_teacher_id, subjects_id, subject_teacher) {
        return axios.post(`${API_BASE_URL}/update_class_information`, {
            msg: "修改班级信息",
            user_token: user_token,
            class_id: class_id,
            class_name: class_name,
            class_grade: class_grade,
            head_teacher_id: head_teacher_id,
            subjects_id: subjects_id,
            subject_teacher: subject_teacher
        })
    },
    updateClassPeople(user_token,class_id,student_id,subject_teacher) {
        return axios.post(`${API_BASE_URL}/update_class_people`, {
            msg: "修改班级信息",
            user_token: user_token,
            class_id: class_id,
            student_id:student_id,
            subject_teacher: subject_teacher
            /*
            * 示例：
            user_token:'7339fef7-0708-49a3-a83e-d86be3a2ea12'
            class_id:1
            student_id: [5,6,10]
            subject_teacher:
            [
            teacher_id:1,
            subject_id:1
            ],[
            teacher_id:2,
            subject_id:3
            ]
            * */
        })
    },

    //删除班级(班级管理:删)
    deleteClass(user_token, class_id) {
        return axios.post(`${API_BASE_URL}/delete_class`, {
            msg: "删除班级",
            user_token: user_token,
            class_id: class_id,
        })
    }
}
