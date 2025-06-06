<template>
  <div class="add-schedule">
    <h2>添加新日程</h2>
    <form @submit.prevent="submitForm">
      <!-- 基础信息 -->
      <div class="form-section">
        <h3>基本信息</h3>
        <div class="form-group">
          <label>事件名称：</label>
          <input type="text" v-model="form.event_name" maxlength="20" required>
          <div class="char-counter">{{ form.event_name.length }}/20</div>
        </div>

        <div class="form-group">
          <label>事件描述：</label>
          <textarea v-model="form.event_describe" required></textarea>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>开始日期：</label>
            <input type="date" v-model="form.start_date" required>
          </div>

          <div class="form-group">
            <label>优先级：</label>
            <select v-model="form.degree_of_importance">
              <option value="1">高优先级</option>
              <option value="2">中优先级</option>
              <option value="3">低优先级</option>
              <option value="4">无优先级</option>
            </select>
          </div>
        </div>
      </div>

      <!-- 重复规则 -->
      <div class="form-section">
        <h3>重复规则</h3>
        <div class="form-group">
          <label>重复类型：</label>
          <select v-model="form.repeat_type" @change="resetRepeatConfig">
            <option value="none">不重复</option>
            <option value="daily">每天</option>
            <option value="weekly">每周</option>
            <option value="monthly_date">每月（按日期）</option>
            <option value="monthly_week">每月（按周）</option>
            <option value="yearly">每年</option>
            <option value="custom">自定义</option>
          </select>
        </div>

        <!-- 每周重复配置 -->
        <div v-if="form.repeat_type === 'weekly'" class="form-group">
          <label>重复星期：</label>
          <div class="weekdays">
            <button v-for="(day, index) in weekdays" :key="index"
                    type="button"
                    :class="{ 'active': weeklyConfig.days.includes(index) }"
                    @click="toggleWeekday(index)">
              {{ day }}
            </button>
          </div>
        </div>

        <!-- 每月按日期重复 -->
        <div v-if="form.repeat_type === 'monthly_date'" class="form-group">
          <label>每月日期：</label>
          <input type="number" v-model="monthlyDateConfig.day" min="1" max="31">
        </div>

        <!-- 每月按周重复 -->
        <div v-if="form.repeat_type === 'monthly_week'" class="form-row">
          <div class="form-group">
            <label>第几周：</label>
            <select v-model="monthlyWeekConfig.week">
              <option value="1">第一周</option>
              <option value="2">第二周</option>
              <option value="3">第三周</option>
              <option value="4">第四周</option>
              <option value="last">最后一周</option>
            </select>
          </div>

          <div class="form-group">
            <label>星期：</label>
            <select v-model="monthlyWeekConfig.day">
              <option v-for="(day, index) in weekdays" :key="index" :value="index">{{ day }}</option>
            </select>
          </div>
        </div>

        <!-- 每年重复 -->
        <div v-if="form.repeat_type === 'yearly'" class="form-row">
          <div class="form-group">
            <label>月份：</label>
            <input type="number" v-model="yearlyConfig.month" min="1" max="12">
          </div>

          <div class="form-group">
            <label>日期：</label>
            <input type="number" v-model="yearlyConfig.day" min="1" max="31">
          </div>
        </div>

        <!-- 自定义重复 -->
        <div v-if="form.repeat_type === 'custom'" class="form-row">
          <div class="form-group">
            <label>间隔：</label>
            <input type="number" v-model="customConfig.interval" min="1">
          </div>

          <div class="form-group">
            <label>单位：</label>
            <select v-model="customConfig.unit">
              <option value="day">天</option>
              <option value="week">周</option>
              <option value="month">月</option>
            </select>
          </div>
        </div>

        <!-- 自定义每周重复 -->
        <div v-if="form.repeat_type === 'custom' && customConfig.unit === 'week'" class="form-group">
          <label>重复星期：</label>
          <div class="weekdays">
            <button v-for="(day, index) in weekdays" :key="index"
                    type="button"
                    :class="{ 'active': customConfig.days.includes(index) }"
                    @click="toggleCustomWeekday(index)">
              {{ day }}
            </button>
          </div>
        </div>
      </div>

      <!-- 结束条件 -->
      <div class="form-section">
        <h3>结束条件</h3>
        <div class="form-group">
          <label>结束类型：</label>
          <select v-model="form.end_type">
            <option value="never">永不结束</option>
            <option value="after_occurrences">重复次数后结束</option>
            <option value="on_date">指定日期结束</option>
          </select>
        </div>

        <div v-if="form.end_type === 'after_occurrences'" class="form-group">
          <label>重复次数：</label>
          <input type="number" v-model="form.end_value" min="1">
        </div>

        <div v-if="form.end_type === 'on_date'" class="form-group">
          <label>结束日期：</label>
          <input type="date" v-model="form.end_value">
        </div>
      </div>

      <!-- 其他信息 -->
      <div class="form-section">
        <h3>其他信息</h3>
        <div class="form-group">
          <label>图片URL：</label>
          <input type="url" v-model="form.img_url" placeholder="可选">
        </div>
      </div>

      <!-- 操作按钮 -->
      <div class="form-actions">
        <button type="submit" class="btn-submit">添加日程</button>
        <button type="button" @click="resetForm" class="btn-reset">重置</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import scheduleApi from '@/api/schedule'
import { useAuthStore } from '@/stores/auth.js'

const authStore = useAuthStore()
const user_token = authStore.user.token

const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

// 主表单数据
const form = ref({
  user_token: user_token,
  event_name: '',
  event_describe: '',
  start_date: new Date().toISOString().split('T')[0],
  repeat_type: 'none',
  end_type: 'never',
  end_value: null,
  degree_of_importance: '4',
  img_url: ''
})

// 各种重复类型的配置
const weeklyConfig = reactive({ days: [] })
const monthlyDateConfig = reactive({ day: 1 })
const monthlyWeekConfig = reactive({ week: '1', day: 1 })
const yearlyConfig = reactive({ month: 1, day: 1 })
const customConfig = reactive({
  unit: 'day',
  interval: 1,
  days: []
})

// 设置默认日期为今天
const today = new Date()
form.value.start_date = today.toISOString().split('T')[0]

// 切换星期选择
const toggleWeekday = (index) => {
  const idx = weeklyConfig.days.indexOf(index)
  if (idx > -1) {
    weeklyConfig.days.splice(idx, 1)
  } else {
    weeklyConfig.days.push(index)
    weeklyConfig.days.sort()
  }
}

// 切换自定义重复的星期选择
const toggleCustomWeekday = (index) => {
  const idx = customConfig.days.indexOf(index)
  if (idx > -1) {
    customConfig.days.splice(idx, 1)
  } else {
    customConfig.days.push(index)
    customConfig.days.sort()
  }
}

// 重置重复配置
const resetRepeatConfig = () => {
  weeklyConfig.days = []
  monthlyDateConfig.day = 1
  monthlyWeekConfig.week = '1'
  monthlyWeekConfig.day = 1
  yearlyConfig.month = 1
  yearlyConfig.day = 1
  customConfig.unit = 'day'
  customConfig.interval = 1
  customConfig.days = []
}

// 生成重复配置
const generateRepeatConfig = () => {
  switch (form.value.repeat_type) {
    case 'weekly':
      return { days: [...weeklyConfig.days] }
    case 'monthly_date':
      return { day: monthlyDateConfig.day }
    case 'monthly_week':
      return { week: monthlyWeekConfig.week, day: monthlyWeekConfig.day }
    case 'yearly':
      return { month: yearlyConfig.month, day: yearlyConfig.day }
    case 'custom':
      const config = { unit: customConfig.unit, interval: customConfig.interval }
      if (customConfig.unit === 'week' && customConfig.days.length > 0) {
        config.days = [...customConfig.days]
      }
      return config
    default:
      return {}
  }
}

// 提交表单
const submitForm = async () => {
  try {
    const repeat_config = generateRepeatConfig()

    const scheduleData = {
      ...form.value,
      repeat_config: JSON.stringify(repeat_config),
      end_value: form.value.end_type === 'never' ? null : form.value.end_value
    }
    if (form.value.event_name.length > 20) {
      console.log('事件名称不能超过20个字');
      return;
    }

    // 调用API创建日程
    await scheduleApi.create_schedule(
        scheduleData.user_token,
        scheduleData.event_name,
        scheduleData.event_describe,
        scheduleData.repeat_type,
        scheduleData.repeat_config,
        scheduleData.start_date,
        scheduleData.end_type,
        scheduleData.end_value,
        scheduleData.degree_of_importance,
        scheduleData.img_url
    )

    resetForm()
  } catch (error) {
    console.error('添加日程失败:', error)
  }
}

// 重置表单
const resetForm = () => {
  form.value = {
    user_token: user_token,
    event_name: '',
    event_describe: '',
    start_date: new Date().toISOString().split('T')[0],
    repeat_type: 'none',
    end_type: 'never',
    end_value: null,
    degree_of_importance: '4',
    img_url: ''
  }
  resetRepeatConfig()
}
</script>

<style scoped>
.add-schedule {
  max-width: 800px;
  margin: 0 auto;
  padding: 1.5rem;
  background-color: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

h2 {
  text-align: center;
  color: #2c3e50;
  margin-bottom: 1.8rem;
  font-size: 1.8rem;
}

.form-section {
  margin-bottom: 1.8rem;
  padding: 1.2rem;
  background-color: #f9fafb;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
}

h3 {
  margin-top: 0;
  margin-bottom: 1.2rem;
  color: #3498db;
  font-size: 1.2rem;
  border-bottom: 1px solid #eaeaea;
  padding-bottom: 0.5rem;
}

.form-group {
  margin-bottom: 1.2rem;
}

label {
  display: block;
  margin-bottom: 0.6rem;
  font-weight: 600;
  color: #4a5568;
}

input[type="text"],
input[type="date"],
input[type="number"],
input[type="url"],
select,
textarea {
  width: 100%;
  padding: 0.8rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

input[type="text"]:focus,
input[type="date"]:focus,
input[type="number"]:focus,
input[type="url"]:focus,
select:focus,
textarea:focus {
  outline: none;
  border-color: #3498db;
  box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
}

textarea {
  min-height: 100px;
  resize: vertical;
}

.form-row {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.form-row .form-group {
  flex: 1;
  margin-bottom: 0;
}

.weekdays {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.weekdays button {
  flex: 1;
  min-width: 60px;
  padding: 0.6rem;
  background-color: #edf2f7;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.weekdays button:hover {
  background-color: #e2e8f0;
}

.weekdays button.active {
  background-color: #3498db;
  color: white;
  font-weight: bold;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1.5rem;
}

button {
  padding: 0.8rem 1.8rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-submit {
  background-color: #3498db;
  color: white;
}

.btn-submit:hover {
  background-color: #2980b9;
}

.btn-reset {
  background-color: #95a5a6;
  color: white;
}

.btn-reset:hover {
  background-color: #7f8c8d;
}

.char-counter {
  font-size: 0.8rem;
  text-align: right;
  color: #7f8c8d;
  margin-top: 0.3rem;
}
</style>
