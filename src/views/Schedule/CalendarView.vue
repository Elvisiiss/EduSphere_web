<template>
  <div class="calendar-view">
    <div class="calendar-header">
      <div class="month-navigation">
        <button @click="prevMonth">&lt;</button>
        <h2>{{ currentMonth }} {{ currentYear }}</h2>
        <button @click="nextMonth">&gt;</button>
      </div>

      <!-- 状态筛选按钮组 -->
      <div class="status-filter">
        <button
            v-for="status in statusOptions"
            :key="status.value"
            @click="toggleStatus(status.value)"
            :class="{ active: selectedStatus.includes(status.value) }"
        >
          {{ status.label }}
        </button>
      </div>
    </div>

    <div class="calendar-grid">
      <div class="day-header" v-for="day in dayNames" :key="day">{{ day }}</div>
      <div
          v-for="day in daysInMonth"
          :key="day.date"
          class="calendar-day"
          :class="{
          'current-day': day.isCurrentDay,
          'other-month': !day.isCurrentMonth
        }"
          @click="selectDay(day)"
      >
        <div class="day-number">{{ day.day }}</div>
        <div class="schedules-preview">
          <div
              v-for="(schedule, index) in getSchedulesForDay(day.date)"
              :key="index"
              class="schedule-dot"
              :style="{ backgroundColor: scheduleColors[index % scheduleColors.length] }"
              :title="schedule.content"
          ></div>
        </div>
      </div>
    </div>

    <!-- 详情弹窗 -->
    <div v-if="selectedDay" class="day-details-popup">
      <div class="popup-content">
        <div class="popup-header">
          <h3>{{ formatSelectedDate(selectedDay.date) }}</h3>
          <button class="close-btn" @click="selectedDay = null">×</button>
        </div>

        <!-- 预测功能开关 -->
        <div class="prediction-switch">
          <label class="switch">
            <input type="checkbox" v-model="enablePrediction">
            <span class="slider round"></span>
            <span class="switch-label">启用预测</span>
          </label>
        </div>

        <!-- 日程列表 -->
        <div v-if="Object.keys(groupedSchedules).length === 0" class="no-schedules">
          <div class="empty-icon-placeholder"></div>
          <p>当天没有日程安排</p>
        </div>

        <div v-else class="schedule-groups">
          <div v-for="(group, state) in groupedSchedules" :key="state" class="schedule-group">
            <div class="group-header" @click="toggleGroup(state)">
              <h4>{{ stateNames[state] }} ({{ group.length }})</h4>
              <span class="toggle-icon">
                {{ groupExpanded[state] ? '▼' : '►' }}
              </span>
            </div>

            <ul v-if="groupExpanded[state]" class="schedules-list">
              <li
                  v-for="schedule in group"
                  :key="schedule.event.event_id"
                  class="schedule-item"
                  :class="`importance-${schedule.event.degree_of_importance}`"
              >
                <div class="schedule-info">
                  <div class="date-time">
                    <span class="time">{{ schedule.time }}</span>
                    <span v-if="schedule.event.is_prediction" class="predicted-tag">预测</span>
                  </div>
                  <div class="title">{{ schedule.event.event_name }}</div>
                  <div class="description">{{ schedule.event.event_describe }}</div>
                </div>
                <div class="actions">
                  <button @click="deleteSchedule(schedule.event.event_id)" class="btn-delete">
                    <i class="icon-trash"></i>
                  </button>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import {ref, computed, onMounted, watch} from 'vue'
import scheduleApi from '@/api/schedule'
import { useAuthStore } from '@/stores/auth'

const schedules = ref([])
const loading = ref(false)
const enablePrediction = ref(false)
const daySchedules = ref([])
const authStore = useAuthStore()
const user_token = authStore.user.token
const currentDate = ref(new Date())
const selectedDay = ref(null) // 初始化为null，不显示弹窗

const scheduleColors = ['#3498db', '#2ecc71', '#e74c3c', '#f39c12', '#9b59b6']
const dayNames = ['日', '一', '二', '三', '四', '五', '六']

const statusOptions = [
  { value: 'active', label: '活跃' },
  { value: 'completed', label: '已完成' },
  { value: 'cancelled', label: '已取消' },
  { value: 'deleted', label: '已删除' }
];
const selectedStatus = ref(['active']);

const toggleStatus = (status) => {
  const index = selectedStatus.value.indexOf(status);
  if (index > -1) {
    selectedStatus.value.splice(index, 1);
  } else {
    selectedStatus.value.push(status);
  }
};

const stateNames = {
  active: '活跃日程',
  completed: '已完成',
  cancelled: '已取消',
  deleted: '已删除',
  predicted: '预测日程', // 添加预测分组名称
  normal: '普通日程'    // 添加普通分组名称
}

const groupExpanded = ref({})
const groupedSchedules = computed(() => {
  const groups = {};

  // 启用预测时的分组逻辑
  if (enablePrediction.value) {
    groups.predicted = []; // 预测日程
    groups.normal = [];    // 普通日程

    daySchedules.value.forEach(schedule => {
      if (schedule.event.is_prediction) {
        groups.predicted.push(schedule);
      } else {
        groups.normal.push(schedule);
      }
    });
  }
  // 未启用预测时的分组逻辑
  else {
    // 初始化状态分组
    const stateGroups = {
      active: [],
      completed: [],
      cancelled: [],
      deleted: []
    };

    daySchedules.value.forEach(schedule => {
      const state = schedule.event.state;
      if (stateGroups[state] && selectedStatus.value.includes(state)) {
        stateGroups[state].push(schedule);
      }
    });

    // 将状态分组复制到最终分组对象
    Object.assign(groups, stateGroups);
  }

  // 过滤掉空分组
  return Object.fromEntries(
      Object.entries(groups).filter(([_, items]) => items.length > 0)
  );
});

const toggleGroup = (state) => {
  groupExpanded.value[state] = !groupExpanded.value[state];
}



// 当前月份和年份
const currentMonth = computed(() => {
  return currentDate.value.toLocaleDateString('zh-CN', { month: 'long' })
})

const currentYear = computed(() => {
  return currentDate.value.getFullYear()
})

const formatDateLocal = (date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

// 生成月历天数数组 - 完整的实现
const daysInMonth = computed(() => {
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth()

  // 当月第一天
  const firstDay = new Date(year, month, 1)
  // 当月最后一天
  const lastDay = new Date(year, month + 1, 0)
  // 上个月最后几天
  const prevLastDay = new Date(year, month, 0).getDate()

  // 当月第一天是星期几（0-6，0为周日）
  const firstDayIndex = firstDay.getDay()
  // 当月最后一天是星期几
  const lastDayIndex = lastDay.getDay()

  const days = []

  // 添加上个月的最后几天
  for (let i = firstDayIndex; i > 0; i--) {
    const date = new Date(year, month - 1, prevLastDay - i + 1)
    days.push({
      day: prevLastDay - i + 1,
      date: formatDateLocal(date),
      isCurrentMonth: false
    })
  }

  // 添加当月所有天
  for (let i = 1; i <= lastDay.getDate(); i++) {
    const date = new Date(year, month, i)
    days.push({
      day: i,
      date: formatDateLocal(date),
      isCurrentMonth: true,
      isCurrentDay: isToday(date)
    })
  }

  // 添加下个月的前几天（补齐42个格子）
  for (let i = 1; i <= 42 - days.length; i++) {
    const date = new Date(year, month + 1, i)
    days.push({
      day: i,
      date: formatDateLocal(date),
      isCurrentMonth: false
    })
  }

  return days
})

// 检查是否是今天
const isToday = (date) => {
  const today = new Date()
  return (
      date.getDate() === today.getDate() &&
      date.getMonth() === today.getMonth() &&
      date.getFullYear() === today.getFullYear()
  )
}

// 获取某天的日程
const getSchedulesForDay = (date) => {
  return schedules.value.filter(schedule =>
      schedule.date === date &&
      selectedStatus.value.includes(schedule.event.state))
};

// 选择日期（修复问题）
const selectDay = async (day) => {
  selectedDay.value = day; // 存储整个day对象

  try {
    const response = await scheduleApi.get_schedules_by_date(
        user_token,
        day.date, // 使用day.date作为日期参数
        enablePrediction.value
    );
    daySchedules.value = response.data;
  } catch (error) {
    console.error('加载日程详情失败:', error);
    daySchedules.value = [];
  }
};

// 删除日程
const deleteSchedule = async (id) => {
  if (confirm('确定要删除这个日程吗？')) {
    try {
      await scheduleApi.delete_schedule(user_token, id)
      schedules.value = schedules.value.filter(schedule => schedule.event.event_id !== id)
      // 更新当前显示的日程
      if (selectedDay.value) {
        daySchedules.value = daySchedules.value.filter(s => s.event.event_id !== id)
      }
    } catch (error) {
      console.error('删除日程失败:', error);
    }
  }
}

// 格式化选中的日期
const formatSelectedDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    weekday: 'long'
  })
}

const loadMonthSchedules = async () => {
  loading.value = true
  try {
    const year = currentDate.value.getFullYear()
    const month = currentDate.value.getMonth()
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)

    const response = await scheduleApi.get_schedules_by_range(
        user_token,
        formatDateLocal(firstDay),
        formatDateLocal(lastDay)
    )

    schedules.value = response.data // 存储API返回的数据
  } catch (error) {
    console.error('加载日程失败:', error)
  } finally {
    loading.value = false
  }
}

// 添加月份切换时的数据加载
const prevMonth = async () => {
  currentDate.value = new Date(
      currentDate.value.getFullYear(),
      currentDate.value.getMonth() - 1,
      1
  )
  await loadMonthSchedules()
}

// 下个月
const nextMonth = async () => {
  currentDate.value = new Date(
      currentDate.value.getFullYear(),
      currentDate.value.getMonth() + 1,
      1
  )
  await loadMonthSchedules()
}

onMounted(async () => {
  // 不再设置selectedDay.value，避免初始打开弹窗
  await loadMonthSchedules();
})

watch(enablePrediction, async (newVal) => {
  if (selectedDay.value) {
    try {
      const response = await scheduleApi.get_schedules_by_date(
          user_token,
          selectedDay.value.date,
          newVal
      );
      daySchedules.value = response.data;
    } catch (error) {
      console.error('重新加载日程失败:', error);
      daySchedules.value = [];
    }
  }
});
</script>

<style scoped>
.schedule-groups {
  margin-top: 15px;
}

.schedule-group {
  margin-bottom: 15px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.group-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 15px;
  background-color: #f7fafc;
  border-bottom: 1px solid #e2e8f0;
  cursor: pointer;
  transition: background-color 0.2s;
}

.group-header:hover {
  background-color: #edf2f7;
}

.group-header h4 {
  margin: 0;
  font-size: 1.1rem;
  color: #2d3748;
}

.toggle-icon {
  font-size: 0.9rem;
  color: #718096;
}

/* 调整原有样式适应新结构 */
.schedules-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.schedule-item {
  display: flex;
  justify-content: space-between;
  padding: 12px 15px;
  border-bottom: 1px solid #eee;
}

.schedule-item:last-child {
  border-bottom: none;
}

/* 整体样式优化 */
.calendar-view {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1.5rem;
  margin-bottom: 2rem;
  padding: 15px 20px;
  background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  color: white;
}

.month-navigation {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.calendar-header button {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  font-size: 1.2rem;
  cursor: pointer;
  color: white;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.calendar-header button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.1);
}

.calendar-header h2 {
  margin: 0;
  min-width: 200px;
  text-align: center;
  font-weight: 600;
  font-size: 1.8rem;
  text-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.status-filter {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.status-filter button {
  padding: 8px 15px;
  border: none;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.15);
  cursor: pointer;
  color: white;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.status-filter button:hover {
  background: rgba(255, 255, 255, 0.25);
}

.status-filter button.active {
  background: white;
  color: #2575fc;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
  margin-bottom: 30px;
}

.day-header {
  text-align: center;
  padding: 15px 5px;
  font-weight: bold;
  background: #f8f9fa;
  color: #495057;
  border-radius: 8px;
  font-size: 1.1rem;
}

.calendar-day {
  min-height: 120px;
  border: 1px solid #e9ecef;
  padding: 12px;
  cursor: pointer;
  transition: all 0.2s;
  background-color: #fff;
  border-radius: 10px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.03);
  position: relative;
  overflow: hidden;
}

.calendar-day:hover {
  background-color: #f8f9fa;
  transform: translateY(-3px);
  box-shadow: 0 5px 15px rgba(0,0,0,0.08);
}

.other-month {
  background-color: #f9f9f9;
  color: #adb5bd;
}

.current-day {
  background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
  border: 2px solid #3498db;
  position: relative;
}

.current-day::after {
  content: '今天';
  position: absolute;
  top: 5px;
  right: 5px;
  background: #3498db;
  color: white;
  font-size: 0.7rem;
  padding: 2px 6px;
  border-radius: 10px;
}

.day-number {
  font-weight: bold;
  margin-bottom: 8px;
  font-size: 1.2rem;
  color: #212529;
}

.schedules-preview {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  max-height: 60px;
  overflow: hidden;
}

.schedule-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

/* 详情弹窗样式优化 */
.day-details-popup {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(5px);
}

.popup-content {
  background-color: white;
  width: 90%;
  max-width: 600px;
  max-height: 85vh;
  overflow-y: auto;
  border-radius: 16px;
  padding: 25px;
  box-shadow: 0 10px 50px rgba(0, 0, 0, 0.3);
  position: relative;
}

.popup-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.popup-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.5rem;
}

.close-btn {
  background: none;
  border: none;
  font-size: 2rem;
  cursor: pointer;
  color: #95a5a6;
  transition: color 0.2s;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  color: #e74c3c;
}

.prediction-switch {
  margin-bottom: 20px;
  display: flex;
  align-items: center;
}

.switch {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 24px;
  margin-right: 10px;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: .4s;
  border-radius: 24px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: .4s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #9b59b6;
}

input:checked + .slider:before {
  transform: translateX(26px);
}

.switch-label {
  font-weight: 500;
  color: #2c3e50;
}

.no-schedules {
  text-align: center;
  padding: 30px 0;
  color: #95a5a6;
}

.no-schedules p {
  margin-top: 15px;
  font-size: 1.1rem;
}

.empty-icon {
  width: 100px;
  opacity: 0.6;
}

.schedules-list {
  list-style: none;
  padding: 0;
  margin-top: 15px;
}

.schedule-item {
  display: flex;
  justify-content: space-between;
  padding: 15px;
  border-radius: 10px;
  margin-bottom: 12px;
  background: #f8f9fa;
  transition: transform 0.2s;
  border-left: 4px solid;
}

.schedule-item:hover {
  transform: translateX(5px);
  background: #edf2f7;
}

.schedule-info {
  flex: 1;
}

.date-time {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
}

.time {
  font-weight: bold;
  margin-right: 10px;
  color: #2c3e50;
  font-size: 1.1rem;
}

.title {
  font-weight: 600;
  margin-bottom: 5px;
  color: #2c3e50;
  font-size: 1.1rem;
}

.description {
  color: #666;
  font-size: 0.95rem;
  line-height: 1.4;
}

.predicted-tag {
  background-color: #9b59b6;
  color: white;
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.actions {
  display: flex;
  align-items: center;
}

.btn-delete {
  background-color: #ff6b6b;
  color: white;
  border: none;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.2s;
}

.btn-delete:hover {
  background-color: #ff5252;
}

.icon-trash {
  display: inline-block;
  width: 18px;
  height: 18px;
  background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>');
}

/* 重要性颜色 */
.importance-1 { border-left-color: #2ecc71; }
.importance-2 { border-left-color: #3498db; }
.importance-3 { border-left-color: #f39c12; }
.importance-4 { border-left-color: #e74c3c; }

/* 响应式调整 */
@media (max-width: 768px) {
  .calendar-header {
    flex-direction: column;
    align-items: stretch;
    gap: 1rem;
  }

  .month-navigation {
    justify-content: center;
  }

  .status-filter {
    justify-content: center;
  }

  .calendar-day {
    min-height: 90px;
    padding: 8px;
  }

  .day-number {
    font-size: 1rem;
  }
}
.empty-icon-placeholder {
  width: 80px;
  height: 80px;
  margin: 0 auto 15px;
  background-color: #f0f0f0;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40px;
  color: #ccc;
}
.empty-icon-placeholder::after {
  content: "📅";
}
</style>
