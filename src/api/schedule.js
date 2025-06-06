import axios from 'axios'

const API_BASE_URL = 'http://10.168.82.63:8080/api/schedule'
// const API_BASE_URL = 'http://localhost:8080/api/schedule'

export default {
    // 获取时间范围内的日程
    get_schedules_by_range(user_token, start_date, end_date) {
        return axios.post(`${API_BASE_URL}/get_the_schedule_within_the_time_range`, {
            msg: "获取时间范围内的日程",
            user_token: user_token,
            start_date: start_date,
            end_date: end_date
        })
    },

    // 获取特定日期的日程
    get_schedules_by_date(user_token, date, is_prediction) {
        return axios.post(`${API_BASE_URL}/get_schedules_by_date`, {
            msg: "获取特定日期的日程",
            user_token: user_token,
            is_prediction: is_prediction,
            date: date
        })
    },

    // 创建新日程
    create_schedule(user_token,
                    event_name,
                    event_describe,
                    repeat_type,
                    repeat_config,
                    start_date,
                    end_type,
                    end_value,
                    degree_of_importance,
                    img_url
    ) {
        return axios.post(`${API_BASE_URL}/create_a_new_schedule`, {
            msg: "创建新日程",
            user_token: user_token,
            event_name: event_name,
            event_describe: event_describe,
            repeat_type: repeat_type,
            repeat_config: repeat_config,
            start_date: start_date,
            end_type: end_type,
            end_value: end_value,
            degree_of_importance: degree_of_importance,
            img_url: img_url
        })
    },

    // 更新日程
    update_schedule(user_token,
                    event_id,
                    event_name,
                    event_describe,
                    repeat_type,
                    repeat_config,
                    start_date,
                    end_type,
                    end_value,
                    degree_of_importance,
                    img_url
    ) {
        return axios.post(`${API_BASE_URL}/update_schedule`, {
            msg: "更新日程",
            user_token: user_token,
            event_id: event_id,
            event_name: event_name,
            event_describe: event_describe,
            repeat_type: repeat_type,
            repeat_config: repeat_config,
            start_date: start_date,
            end_type: end_type,
            end_value: end_value,
            degree_of_importance: degree_of_importance,
            img_url: img_url
        })
    },

    // 删除日程
    delete_schedule(user_token, event_id) {
        return axios.post(`${API_BASE_URL}/delete_schedule`, {
            msg: "删除日程",
            user_token: user_token,
            event_id: event_id
        })
    },

    // 取消日程
    cancel_schedule(user_token, event_id) {
        return axios.post(`${API_BASE_URL}/cancel_event`, {
            msg: "取消日程",
            user_token: user_token,
            event_id: event_id
        })
    },

    // 还原日程
    restore_schedule(user_token, event_id) {
        return axios.post(`${API_BASE_URL}/restore_schedule`, {
            msg: "还原日程",
            user_token: user_token,
            event_id: event_id
        })
    },

    // 完成事件
    finish_event(user_token, event_id) {
        return axios.post(`${API_BASE_URL}/finish_event`, {
            msg: "完成事件",
            user_token: user_token,
            event_id: event_id
        })
    },

    // 通过关键词找事件
    find_events_by_key_word(user_token, str, date, start_date, end_date) {
        return axios.post(`${API_BASE_URL}/find_events_by_key_word`, {
            msg: "通过关键词找事件",
            user_token: user_token,
            str: str,
            date: date,
            start_date: start_date,
            end_date: end_date
        })
    }
}
