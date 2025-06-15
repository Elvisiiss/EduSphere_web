<template>
  <div class="schedule-list">
    <div class="header">
      <div class="header-title">
        <h2>我的日程</h2>
        <div class="date-display">{{ currentDate }}</div>
      </div>

      <div class="filters">
        <!-- 特定日期查询 -->
        <div class="filter-card">
          <h4>特定日期查询</h4>
          <div class="filter-group">
            <label>查看日期:</label>
            <input type="date" v-model="specificDate">
            <label class="prediction-checkbox">
              <input type="checkbox" v-model="isPrediction"> 启用预测
            </label>
            <button @click="fetchSchedulesByDate">查询</button>
          </div>
        </div>

        <!-- 日期范围查询 -->
        <div class="filter-card">
          <h4>日期范围查询</h4>
          <div class="filter-group">
            <label>从:</label>
            <input type="date" v-model="startDate">
            <label>至:</label>
            <input type="date" v-model="endDate">
            <button @click="fetchSchedules">查询</button>
          </div>
        </div>

        <!-- 搜索框 -->
        <!-- 搜索框 -->
        <div class="filter-card">
          <h4>搜索日程</h4>
          <div class="filter-group">
            <input
                type="text"
                v-model="searchText"
                placeholder="搜索日程名称或描述..."
            >
          </div>

          <!-- 新增的搜索选项 -->
          <div class="search-options">
            <div
                class="search-option"
                :class="{ active: specificDateSearchEnabled }"
                @click="toggleSpecificDateSearch"
            >
              <input
                  type="checkbox"
                  :checked="specificDateSearchEnabled"
                  hidden
              >
              <span class="toggle-switch" :class="{ on: specificDateSearchEnabled }"></span>
              <span>特定日期查询</span>
            </div>

            <div
                class="search-option"
                :class="{ active: rangeSearchEnabled }"
                @click="toggleRangeSearch"
            >
              <input
                  type="checkbox"
                  :checked="rangeSearchEnabled"
                  hidden
              >
              <span class="toggle-switch" :class="{ on: rangeSearchEnabled }"></span>
              <span>日期范围查询</span>
            </div>
          </div>

          <button
              @click="searchByKeyword"
              class="btn-search"
              :disabled="searchLoading"
          >
            <span v-if="searchLoading">搜索中...</span>
            <span v-else>搜索</span>
          </button>
        </div>
      </div>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <div>加载中...</div>
    </div>

    <div v-else>
      <div v-if="filteredSchedules.length === 0" class="no-schedules">
        <img src="@/assets/no-data.svg" alt="没有日程" class="no-data-img">
        <div class="no-schedules-text">没有找到日程安排</div>
        <button @click="showToday" class="btn-show-today">查看今天的日程</button>
      </div>

      <!-- 分组展示日程 -->
      <div v-else class="schedule-groups">
        <div v-for="(group, groupName) in groupedSchedules" :key="groupName" class="schedule-group">
          <div class="group-header" @click="toggleGroup(groupName)">
            <div class="group-title">
              <span class="group-icon" :class="`group-${groupName.toLowerCase()}`"></span>
              <h3>{{ groupName }} <span class="item-count">({{ group.items.length }})</span></h3>
            </div>
            <span class="toggle-icon">
            {{ groupExpanded[groupName] ? '▼' : '►' }}
          </span>
          </div>

          <div v-if="groupExpanded[groupName]" class="schedules-container">
            <div
                v-for="item in group.items"
                :key="`${item.date}-${item.event.event_id}`"
                class="schedule-item"
                :class="`importance-${item.event.degree_of_importance}`"
            >
              <div class="schedule-image" v-if="item.event.img_url">
                <img :src="item.event.img_url" alt="日程图片">
              </div>
              <div class="schedule-info">
                <div class="date-time">
                  <span class="date">{{ formatDate(item.date) }}</span>
                  <span v-if="item.event.repeat_type && item.event.repeat_type !== 'none'" class="recurring-tag">
                  {{ getRecurringLabel(item.event.repeat_type) }}
                </span>
                  <span class="importance" :title="`重要性：${item.event.degree_of_importance}星`">
                  {{ '★'.repeat(item.event.degree_of_importance) }}
                </span>
                  <!-- 添加预测标签 -->
                  <span v-if="item.is_prediction" class="predicted-tag">预测</span>
                </div>
                <div class="title">{{ item.event.event_name }}</div>
                <div class="description">{{ item.event.event_describe }}</div>
              </div>
              <div class="actions">
                <!-- 按钮逻辑修改 -->
                <!-- 活跃日程和普通日程（非预测分类） -->
                <template v-if="groupName === '活跃日程' || groupName === '普通日程'">
                  <button
                      @click="finishSchedule(item.event.event_id)"
                      class="btn-finish"
                  >
                    完成
                  </button>
                  <button
                      @click="cancelSchedule(item.event.event_id)"
                      class="btn-cancel"
                  >
                    取消
                  </button>
                  <button @click="openEditDialog(item.event)" class="btn-edit">编辑</button>
                  <button @click="deleteSchedule(item.event.event_id)" class="btn-delete">删除</button>
                </template>

                <!-- 已完成和已取消分类 -->
                <template v-else-if="groupName === '已完成' || groupName === '已取消'">
                  <button
                      @click="restoreSchedule(item.event.event_id)"
                      class="btn-restore"
                  >
                    还原
                  </button>
                  <button @click="deleteSchedule(item.event.event_id)" class="btn-delete">删除</button>
                </template>

                <!-- 已删除分类 -->
                <template v-else-if="groupName === '已删除'">
                  <button
                      @click="restoreSchedule(item.event.event_id)"
                      class="btn-restore"
                  >
                    还原
                  </button>
                </template>

                <!-- 预测日程分类 -->
                <template v-else-if="groupName === '预测日程'">
                  <button @click="openViewDialog(item.event)" class="btn-view">查看</button>
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 编辑对话框 -->
    <div v-if="editDialogVisible" class="edit-dialog">
      <div class="dialog-overlay" @click="closeEditDialog"></div>
      <div class="dialog-content">
        <div class="dialog-header">
          <h3>编辑日程</h3>
          <button class="close-btn" @click="closeEditDialog">×</button>
        </div>

        <form @submit.prevent="submitEditForm">
          <!-- 基础信息 -->
          <div class="form-section">
            <h4>基本信息</h4>
            <div class="form-group">
              <label>事件名称：</label>
              <input type="text" v-model="editForm.event_name" required>
            </div>

            <div class="form-group">
              <label>事件描述：</label>
              <textarea v-model="editForm.event_describe" required></textarea>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>开始日期：</label>
                <input type="date" v-model="editForm.start_date" required>
              </div>

              <div class="form-group">
                <label>优先级：</label>
                <select v-model="editForm.degree_of_importance">
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
            <h4>重复规则</h4>
            <div class="form-group">
              <label>重复类型：</label>
              <select v-model="editForm.repeat_type" @change="resetEditRepeatConfig">
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
            <div v-if="editForm.repeat_type === 'weekly'" class="form-group">
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
            <div v-if="editForm.repeat_type === 'monthly_date'" class="form-group">
              <label>每月日期：</label>
              <input type="number" v-model="monthlyDateConfig.day" min="1" max="31">
            </div>

            <!-- 每月按周重复 -->
            <div v-if="editForm.repeat_type === 'monthly_week'" class="form-row">
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
            <div v-if="editForm.repeat_type === 'yearly'" class="form-row">
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
            <div v-if="editForm.repeat_type === 'custom'" class="form-row">
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
            <div v-if="editForm.repeat_type === 'custom' && customConfig.unit === 'week'" class="form-group">
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
            <h4>结束条件</h4>
            <div class="form-group">
              <label>结束类型：</label>
              <select v-model="editForm.end_type">
                <option value="never">永不结束</option>
                <option value="after_occurrences">重复次数后结束</option>
                <option value="on_date">指定日期结束</option>
              </select>
            </div>

            <div v-if="editForm.end_type === 'after_occurrences'" class="form-group">
              <label>重复次数：</label>
              <input type="number" v-model="editForm.end_value" min="1">
            </div>

            <div v-if="editForm.end_type === 'on_date'" class="form-group">
              <label>结束日期：</label>
              <input type="date" v-model="editForm.end_value">
            </div>
          </div>

          <!-- 其他信息 -->
          <div class="form-section">
            <h4>其他信息</h4>
            <div class="form-group">
              <label>图片URL：</label>
              <input type="url" v-model="editForm.img_url" placeholder="可选">
            </div>
          </div>

          <!-- 操作按钮 -->
          <div class="form-actions">
            <button type="submit" class="btn-submit">保存修改</button>
            <button type="button" @click="closeEditDialog" class="btn-reset">取消</button>
          </div>
        </form>
      </div>
    </div>
    <!-- 查看对话框（用于预测日程） -->
    <div v-if="viewDialogVisible" class="edit-dialog">
      <div class="dialog-overlay" @click="closeViewDialog"></div>
      <div class="dialog-content">
        <div class="dialog-header">
          <h3>查看日程详情</h3>
          <button class="close-btn" @click="closeViewDialog">×</button>
        </div>

        <div class="form-section">
          <h4>基本信息</h4>
          <div class="form-group">
            <label>事件名称：</label>
            <input type="text" v-model="viewForm.event_name" readonly>
          </div>

          <div class="form-group">
            <label>事件描述：</label>
            <textarea v-model="viewForm.event_describe" readonly></textarea>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>开始日期：</label>
              <input type="date" v-model="viewForm.start_date" readonly>
            </div>

            <div class="form-group">
              <label>优先级：</label>
              <input type="text" :value="getImportanceLabel(viewForm.degree_of_importance)" readonly>
            </div>
          </div>
        </div>

        <!-- 重复规则 -->
        <div class="form-section">
          <h4>重复规则</h4>
          <div class="form-group">
            <label>重复类型：</label>
            <input type="text" :value="getRepeatTypeLabel(viewForm.repeat_type)" readonly>
          </div>
        </div>

        <!-- 结束条件 -->
        <div class="form-section">
          <h4>结束条件</h4>
          <div class="form-group">
            <label>结束类型：</label>
            <input type="text" :value="getEndTypeLabel(viewForm.end_type)" readonly>
          </div>
        </div>

        <!-- 其他信息 -->
        <div class="form-section">
          <h4>其他信息</h4>
          <div class="form-group">
            <label>图片URL：</label>
            <input type="url" v-model="viewForm.img_url" readonly>
          </div>
        </div>

        <div class="form-actions">
          <button type="button" @click="closeViewDialog" class="btn-reset">关闭</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import {computed, onMounted, reactive, ref} from 'vue'
import scheduleApi from '@/api/schedule'
import {useAuthStore} from '@/stores/auth.js'

const authStore = useAuthStore()
const user_token = authStore.user.token

const startDate = ref('')
const endDate = ref('')
const searchText = ref('')
const loading = ref(false)
const schedules = ref([])
const editDialogVisible = ref(false)

const specificDate = ref('')
const isPrediction = ref(false)

const specificDateSearchEnabled = ref(false);
const rangeSearchEnabled = ref(false);
const searchLoading = ref(false);
const viewDialogVisible = ref(false)

const viewForm = ref({
  event_id: null,
  event_name: '',
  event_describe: '',
  start_date: '',
  repeat_type: 'none',
  end_type: 'never',
  end_value: null,
  degree_of_importance: '4',
  img_url: ''
})

const toggleSpecificDateSearch = () => {
  specificDateSearchEnabled.value = !specificDateSearchEnabled.value;
  if (specificDateSearchEnabled.value) {
    rangeSearchEnabled.value = false;
  }
};

const toggleRangeSearch = () => {
  rangeSearchEnabled.value = !rangeSearchEnabled.value;
  if (rangeSearchEnabled.value) {
    specificDateSearchEnabled.value = false;
  }
};

// 执行关键词搜索
const searchByKeyword = async () => {
  if (!searchText.value.trim()) {
    alert('请输入搜索关键词');
    return;
  }

  searchLoading.value = true;

  try {
    let dateParam = null;
    let startDateParam = null;
    let endDateParam = null;

    if (specificDateSearchEnabled.value) {
      dateParam = specificDate.value;
    } else if (rangeSearchEnabled.value) {
      startDateParam = startDate.value;
      endDateParam = endDate.value;
    }

    const response = await scheduleApi.find_events_by_key_word(
        user_token,
        searchText.value,
        dateParam,
        startDateParam,
        endDateParam
    );

    schedules.value = response.data;
    lastQueryType.value = 'search';
    updateGroupedSchedules();
  } catch (error) {
    console.error('搜索失败:', error);
    alert('搜索失败，请重试');
  } finally {
    searchLoading.value = false;
  }
};


const getCurrentDate = () => {
  const now = new Date();
  return now.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    weekday: 'long'
  });
}

const showToday = () => {
  specificDate.value = formatDateForInput(new Date());
  fetchSchedulesByDate();
}

const currentDate = ref(getCurrentDate());

// 记录上次查询类型的变量
const lastQueryType = ref('specific') // 'specific' 或 'range'

// 分组状态管理
const groupExpanded = ref({})
const groupedSchedules = ref({})

// 状态名称映射
const stateNames = {
  active: '活跃日程',
  completed: '已完成',
  cancelled: '已取消',
  deleted: '已删除',
  predicted: '预测日程',
  normal: '普通日程'
}

// 编辑表单相关状态
const editForm = ref({
  event_id: null,
  event_name: '',
  event_describe: '',
  start_date: '',
  repeat_type: 'none',
  end_type: 'never',
  end_value: null,
  degree_of_importance: '4',
  img_url: ''
})

// 星期名称
const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

// 各种重复类型的配置
const weeklyConfig = reactive({days: []})
const monthlyDateConfig = reactive({day: 1})
const monthlyWeekConfig = reactive({week: '1', day: 1})
const yearlyConfig = reactive({month: 1, day: 1})
const customConfig = reactive({
  unit: 'day',
  interval: 1,
  days: []
})

// 完成事件方法
const finishSchedule = async (event_id) => {
  try {
    await scheduleApi.finish_event(user_token, event_id)
    // 根据上次查询类型重新获取数据
    if (lastQueryType.value === 'specific') {
      await fetchSchedulesByDate()
    } else {
      await fetchSchedules()
    }
  } catch (error) {
    console.error('完成事件失败:', error)
  }
}

const cancelSchedule = async (event_id) => {
  if (confirm('确定要取消这个日程吗？')) {
    try {
      await scheduleApi.cancel_schedule(user_token, event_id)
      // 根据上次查询类型重新获取数据
      if (lastQueryType.value === 'specific') {
        await fetchSchedulesByDate()
      } else {
        await fetchSchedules()
      }
    } catch (error) {
      console.error('取消日程失败:', error)
    }
  }
}

const restoreSchedule = async (event_id) => {
  try {
    await scheduleApi.restore_schedule(user_token, event_id)
    // 根据上次查询类型重新获取数据
    if (lastQueryType.value === 'specific') {
      await fetchSchedulesByDate()
    } else {
      await fetchSchedules()
    }
  } catch (error) {
    console.error('还原日程失败:', error)
  }
}

const openViewDialog = (event) => {
  // 填充查看表单
  viewForm.value = {
    event_id: event.event_id,
    event_name: event.event_name,
    event_describe: event.event_describe,
    start_date: event.start_date,
    repeat_type: event.repeat_type,
    end_type: event.end_type,
    end_value: event.end_value,
    degree_of_importance: String(event.degree_of_importance),
    img_url: event.img_url || ''
  }

  viewDialogVisible.value = true
}

const closeViewDialog = () => {
  viewDialogVisible.value = false
}

const getRepeatTypeLabel = (type) => {
  const labels = {
    none: '不重复',
    daily: '每天',
    weekly: '每周',
    monthly_date: '每月（按日期）',
    monthly_week: '每月（按周）',
    yearly: '每年',
    custom: '自定义'
  }
  return labels[type] || type
}

// 获取结束类型标签
const getEndTypeLabel = (type) => {
  const labels = {
    never: '永不结束',
    after_occurrences: '重复次数后结束',
    on_date: '指定日期结束'
  }
  return labels[type] || type
}

// 获取重要性标签
const getImportanceLabel = (level) => {
  const labels = {
    '1': '高优先级',
    '2': '中优先级',
    '3': '低优先级',
    '4': '无优先级'
  }
  return labels[level] || level
}

// 按特定日期查询方法
const fetchSchedulesByDate = async () => {
  if (!specificDate.value) {
    return
  }

  loading.value = true
  try {
    const response = await scheduleApi.get_schedules_by_date(
        user_token,
        specificDate.value,
        isPrediction.value
    )
    schedules.value = response.data
    // 记录查询类型
    lastQueryType.value = 'specific'
    // 更新分组
    updateGroupedSchedules()
  } catch (error) {
    console.error('加载日程失败:', error)
  } finally {
    loading.value = false
  }
}

const filteredSchedules = computed(() => {
  if (!searchText.value) return [...schedules.value]

  const searchLower = searchText.value.toLowerCase()
  return schedules.value.filter(item =>
      item.event.event_name.toLowerCase().includes(searchLower) ||
      (item.event.event_describe && item.event.event_describe.toLowerCase().includes(searchLower))
  )
})

const fetchSchedules = async () => {
  loading.value = true
  try {
    const response = await scheduleApi.get_schedules_by_range(
        user_token,
        startDate.value,
        endDate.value
    )
    schedules.value = response.data
    // 记录查询类型
    lastQueryType.value = 'range'
    // 更新分组
    updateGroupedSchedules()
  } catch (error) {
    console.error('加载日程失败:', error)
  } finally {
    loading.value = false
  }
}

const deleteSchedule = async (event_id) => {
  if (confirm('确定要删除这个日程吗？')) {
    try {
      await scheduleApi.delete_schedule(user_token, event_id)
      // 根据上次查询类型重新获取数据
      if (lastQueryType.value === 'specific') {
        await fetchSchedulesByDate()
      } else {
        await fetchSchedules()
      }
    } catch (error) {
      console.error('删除失败:', error)
    }
  }
}

const openEditDialog = (event) => {
  console.log('编辑事件 ID:', event.event_id)

  // 填充编辑表单
  editForm.value = {
    event_id: event.event_id,
    event_name: event.event_name,
    event_describe: event.event_describe,
    start_date: event.start_date,
    repeat_type: event.repeat_type,
    end_type: event.end_type,
    end_value: event.end_value,
    degree_of_importance: String(event.degree_of_importance),
    img_url: event.img_url || ''
  }

  // 解析重复配置
  parseRepeatConfig(event.repeat_config_json)
  editDialogVisible.value = true

}

const closeEditDialog = () => {
  editDialogVisible.value = false
}

const parseRepeatConfig = (config) => {
  if (!config) return

  // 重置所有配置
  resetEditRepeatConfig()

  switch (editForm.value.repeat_type) {
    case 'weekly':
      if (config.days) {
        weeklyConfig.days = [...config.days]
      }
      break
    case 'monthly_date':
      if (config.day) {
        monthlyDateConfig.day = config.day
      }
      break
    case 'monthly_week':
      if (config.week && config.day) {
        monthlyWeekConfig.week = config.week
        monthlyWeekConfig.day = config.day
      }
      break
    case 'yearly':
      if (config.month && config.day) {
        yearlyConfig.month = config.month
        yearlyConfig.day = config.day
      }
      break
    case 'custom':
      if (config.unit && config.interval) {
        customConfig.unit = config.unit
        customConfig.interval = config.interval
      }
      if (config.days) {
        customConfig.days = [...config.days]
      }
      break
  }
}

// 重置重复配置
const resetEditRepeatConfig = () => {
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

// 生成重复配置
const generateRepeatConfig = () => {
  switch (editForm.value.repeat_type) {
    case 'weekly':
      return {days: [...weeklyConfig.days]}
    case 'monthly_date':
      return {day: monthlyDateConfig.day}
    case 'monthly_week':
      return {week: monthlyWeekConfig.week, day: monthlyWeekConfig.day}
    case 'yearly':
      return {month: yearlyConfig.month, day: yearlyConfig.day}
    case 'custom':
      const config = {unit: customConfig.unit, interval: customConfig.interval}
      if (customConfig.unit === 'week' && customConfig.days.length > 0) {
        config.days = [...customConfig.days]
      }
      return config
    default:
      return {}
  }
}

// 提交编辑表单
const submitEditForm = async () => {
  try {
    const repeat_config = generateRepeatConfig()

    const scheduleData = {
      user_token: user_token,
      event_id: editForm.value.event_id,
      event_name: editForm.value.event_name,
      event_describe: editForm.value.event_describe,
      repeat_type: editForm.value.repeat_type,
      repeat_config: JSON.stringify(repeat_config),
      start_date: editForm.value.start_date,
      end_type: editForm.value.end_type,
      end_value: editForm.value.end_type === 'never' ? null : editForm.value.end_value,
      degree_of_importance: editForm.value.degree_of_importance,
      img_url: editForm.value.img_url
    }

    // 调用API更新日程
    await scheduleApi.update_schedule(
        scheduleData.user_token,
        scheduleData.event_id,
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

    // 根据上次查询类型重新获取数据
    if (lastQueryType.value === 'specific') {
      await fetchSchedulesByDate()
    } else {
      await fetchSchedules()
    }

    closeEditDialog()
  } catch (error) {
    console.error('更新日程失败:', error)
  }
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'short'
  })
}

const getRecurringLabel = (type) => {
  const labels = {
    none: '单次',
    daily: '每天',
    weekly: '每周',
    monthly_date: '每月',
    monthly_week: '每月(周)',
    yearly: '每年',
    custom: '自定义'
  }
  return labels[type] || '重复'
}

// 更新分组日程
const updateGroupedSchedules = () => {
  const groups = {}

  // 搜索模式
  if (lastQueryType.value === 'search') {
    groups['搜索结果'] = { items: [...filteredSchedules.value] };
  }

  // 特定日期+预测模式：按预测状态分组
  if (lastQueryType.value === 'specific' && isPrediction.value) {
    groups['预测日程'] = { items: [] }
    groups['普通日程'] = { items: [] }

    filteredSchedules.value.forEach(item => {
      if (item.event.is_prediction) {
        groups['预测日程'].items.push(item)
      } else {
        groups['普通日程'].items.push(item)
      }
    })
  }
  // 其他情况：按状态分组
  else {
    groups['活跃日程'] = { items: [] }
    groups['已完成'] = { items: [] }
    groups['已取消'] = { items: [] }
    groups['已删除'] = { items: [] }

    filteredSchedules.value.forEach(item => {
      const state = item.event.state
      if (state === 'active') groups['活跃日程'].items.push(item)
      else if (state === 'completed') groups['已完成'].items.push(item)
      else if (state === 'cancelled') groups['已取消'].items.push(item)
      else if (state === 'deleted') groups['已删除'].items.push(item)
    })
  }

  // 移除空分组
  Object.keys(groups).forEach(key => {
    if (groups[key].items.length === 0) {
      delete groups[key]
    } else {
      // 初始化分组展开状态
      if (groupExpanded.value[key] === undefined) {
        groupExpanded.value[key] = true
      }
    }
  })

  groupedSchedules.value = groups;
}

// 切换分组展开状态
const toggleGroup = (groupName) => {
  groupExpanded.value[groupName] = !groupExpanded.value[groupName]
}

onMounted(() => {
  const today = new Date()
  const oneWeekAgo = new Date()
  oneWeekAgo.setDate(today.getDate() - 7)

  startDate.value = formatDateForInput(oneWeekAgo)
  endDate.value = formatDateForInput(today)
  specificDate.value = formatDateForInput(today) // 默认显示今天的日程

  // 默认使用特定日期查询
  fetchSchedulesByDate()
})

// 将日期格式化为 YYYY-MM-DD 格式
const formatDateForInput = (date) => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}
</script>

<style scoped>
/* 全局样式 */
.schedule-list {
  padding: 1.5rem;
  max-width: 1200px;
  margin: 0 auto;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.header {
  margin-bottom: 2rem;
  background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
  border-radius: 16px;
  padding: 1.5rem;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
  color: white;
}

.header-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.header-title h2 {
  margin: 0;
  font-size: 1.8rem;
  font-weight: 700;
}

.date-display {
  font-size: 1.1rem;
  opacity: 0.9;
  background: rgba(255, 255, 255, 0.15);
  padding: 0.5rem 1rem;
  border-radius: 12px;
}

.filters {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.filter-card {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  padding: 1.2rem;
  transition: transform 0.3s ease;
}

.filter-card:hover {
  transform: translateY(-5px);
}

.filter-card h4 {
  margin-top: 0;
  margin-bottom: 1rem;
  font-weight: 600;
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.95);
}

.filter-group {
  display: flex;
  flex-wrap: wrap;
  gap: 0.8rem;
  align-items: center;
}

.filter-group label {
  font-weight: 500;
  color: rgba(255, 255, 255, 0.9);
}

input[type="date"],
input[type="text"] {
  padding: 0.7rem;
  border: none;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  flex: 1;
  min-width: 120px;
}

button {
  padding: 0.7rem 1.2rem;
  background-color: rgba(255, 255, 255, 0.9);
  color: #2575fc;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: 600;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

button:hover {
  background-color: white;
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.prediction-checkbox {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-left: 0.5rem;
  color: rgba(255, 255, 255, 0.9);
}

/* 加载状态 */
.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem;
  gap: 1.5rem;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid rgba(37, 117, 252, 0.2);
  border-top: 4px solid #2575fc;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 无日程状态 */
.no-schedules {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem;
  text-align: center;
  gap: 1.5rem;
  background: #f8f9fa;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
}

.no-data-img {
  width: 200px;
  height: auto;
  opacity: 0.7;
}

.no-schedules-text {
  font-size: 1.2rem;
  color: #6c757d;
}

.btn-show-today {
  background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
  color: white;
  padding: 0.8rem 1.8rem;
  border-radius: 30px;
  font-weight: 600;
  margin-top: 1rem;
}

/* 日程分组 */
.schedule-groups {
  display: grid;
  gap: 1.8rem;
  margin-top: 1.5rem;
}

.schedule-group {
  background: white;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.08);
  transition: transform 0.3s ease;
}

.schedule-group:hover {
  transform: translateY(-5px);
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.15);
}

.group-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.2rem 1.5rem;
  background: linear-gradient(135deg, #f6f9ff 0%, #e6f0ff 100%);
  cursor: pointer;
  transition: background 0.3s;
}

.group-header:hover {
  background: linear-gradient(135deg, #e6f0ff 0%, #d4e5ff 100%);
}

.group-title {
  display: flex;
  align-items: center;
  gap: 0.8rem;
}

.group-icon {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: inline-block;
}

.group-active {
  background: linear-gradient(135deg, #00b09b 0%, #96c93d 100%);
}

.group-completed {
  background: linear-gradient(135deg, #3498db 0%, #2ecc71 100%);
}

.group-predicted {
  background: linear-gradient(135deg, #9b59b6 0%, #e74c3c 100%);
}

.group-normal {
  background: linear-gradient(135deg, #f39c12 0%, #e74c3c 100%);
}

.group-header h3 {
  margin: 0;
  font-size: 1.2rem;
  color: #2c3e50;
  font-weight: 600;
}

.item-count {
  font-weight: normal;
  color: #7f8c8d;
  font-size: 0.9rem;
}

.toggle-icon {
  font-size: 1.1rem;
  color: #7f8c8d;
}

/* 日程项 */
.schedules-container {
  display: grid;
  gap: 0.8rem;
  padding: 1.2rem;
}

.schedule-item {
  display: flex;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
  position: relative;
}

.schedule-item:hover {
  transform: translateY(-3px);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.schedule-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 6px;
}

.schedule-item.importance-1::before {
  background: linear-gradient(to bottom, #2ecc71, #27ae60);
}
.schedule-item.importance-2::before {
  background: linear-gradient(to bottom, #3498db, #2980b9);
}
.schedule-item.importance-3::before {
  background: linear-gradient(to bottom, #f39c12, #d35400);
}
.schedule-item.importance-4::before {
  background: linear-gradient(to bottom, #e74c3c, #c0392b);
}

.schedule-image {
  width: 120px;
  min-height: 120px;
  overflow: hidden;
  flex-shrink: 0;
  border-top-left-radius: 12px;
  border-bottom-left-radius: 12px;
}

.schedule-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.5s ease;
}

.schedule-item:hover .schedule-image img {
  transform: scale(1.05);
}

.schedule-info {
  flex: 1;
  padding: 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.date-time {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.6rem;
  font-size: 0.9rem;
  color: #7f8c8d;
}

.date {
  font-weight: 600;
  color: #2c3e50;
}

.recurring-tag {
  background: linear-gradient(135deg, #9b59b6, #8e44ad);
  color: white;
  padding: 0.2rem 0.7rem;
  border-radius: 15px;
  font-size: 0.75rem;
  font-weight: 500;
}

.importance {
  color: #f39c12;
  font-weight: bold;
  font-size: 0.95rem;
}

.predicted-tag {
  background: linear-gradient(135deg, #3498db, #2980b9);
  color: white;
  padding: 0.2rem 0.7rem;
  border-radius: 15px;
  font-size: 0.75rem;
  font-weight: 500;
}

.title {
  font-weight: 700;
  font-size: 1.2rem;
  color: #2c3e50;
}

.description {
  color: #7f8c8d;
  font-size: 0.95rem;
  line-height: 1.5;
}

.actions {
  display: flex;
  gap: 0.7rem;
  padding: 1.2rem;
  align-items: flex-start;
}

.btn-finish {
  background: linear-gradient(135deg, #2ecc71, #27ae60);
  color: white;
}

.btn-finish:hover {
  background: linear-gradient(135deg, #27ae60, #219653);
}

.btn-edit {
  background: linear-gradient(135deg, #3498db, #2980b9);
  color: white;
}

.btn-edit:hover {
  background: linear-gradient(135deg, #2980b9, #1f6aa5);
}

.btn-delete {
  background: linear-gradient(135deg, #e74c3c, #c0392b);
  color: white;
}

.btn-delete:hover {
  background: linear-gradient(135deg, #c0392b, #a93226);
}

/* 响应式调整 */
@media (max-width: 768px) {
  .schedule-item {
    flex-direction: column;
  }

  .schedule-image {
    width: 100%;
    height: 160px;
    border-top-left-radius: 12px;
    border-top-right-radius: 12px;
    border-bottom-left-radius: 0;
  }

  .actions {
    justify-content: center;
    padding-top: 0;
  }

  .filters {
    grid-template-columns: 1fr;
  }
}
.search-options {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin: 1rem 0;
}

.search-option {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.search-option:hover {
  background: rgba(255, 255, 255, 0.3);
}

.search-option.active {
  background: rgba(255, 255, 255, 0.4);
  box-shadow: 0 0 0 2px white;
}

.btn-search {
  width: 100%;
  background: linear-gradient(135deg, #ff9a9e 0%, #fad0c4 100%);
  color: #2c3e50;
  font-weight: bold;
  margin-top: 0.5rem;
}

.btn-search:hover {
  background: linear-gradient(135deg, #ff7b7f 0%, #f8c1b5 100%);
}

.edit-dialog {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.dialog-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  z-index: 1;
}

.dialog-content {
  position: relative;
  z-index: 2;
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  overflow-y: auto;
  padding: 1.5rem;
  animation: dialog-appear 0.3s ease-out;
}

@keyframes dialog-appear {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #eaeaea;
}

.dialog-header h3 {
  margin: 0;
  font-size: 1.5rem;
  color: #2c3e50;
  font-weight: 700;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.8rem;
  cursor: pointer;
  color: #7f8c8d;
  transition: all 0.3s;
  padding: 0.5rem;
  line-height: 1;
}

.close-btn:hover {
  color: #e74c3c;
  transform: scale(1.1);
}

/* 表单部分样式优化 */
.form-section {
  margin-bottom: 1.8rem;
  padding: 1.2rem;
  background: #f9fbfd;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

.form-section h4 {
  margin-top: 0;
  margin-bottom: 1.2rem;
  color: #3498db;
  font-weight: 600;
  font-size: 1.1rem;
  display: flex;
  align-items: center;
}

.form-section h4::before {
  content: "";
  display: inline-block;
  width: 4px;
  height: 16px;
  background: #3498db;
  border-radius: 2px;
  margin-right: 0.8rem;
}

.form-group {
  margin-bottom: 1.2rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #2c3e50;
}

input[type="text"],
input[type="date"],
input[type="number"],
input[type="url"],
textarea,
select {
  width: 100%;
  padding: 0.8rem 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: white;
  font-size: 1rem;
  transition: all 0.3s;
}

input[type="text"]:focus,
input[type="date"]:focus,
input[type="number"]:focus,
input[type="url"]:focus,
textarea:focus,
select:focus {
  border-color: #3498db;
  box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.2);
  outline: none;
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
  padding: 0.6rem 1rem;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.weekdays button.active {
  background: linear-gradient(135deg, #3498db, #2980b9);
  color: white;
  border-color: #2980b9;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #eee;
}

.btn-submit {
  background: linear-gradient(135deg, #2ecc71, #27ae60);
  color: white;
  padding: 0.8rem 1.8rem;
  border-radius: 8px;
  font-weight: 600;
  border: none;
  cursor: pointer;
}

.btn-reset {
  background: #e0e6ed;
  color: #4a5568;
  padding: 0.8rem 1.8rem;
  border-radius: 8px;
  font-weight: 600;
  border: none;
  cursor: pointer;
}

.btn-submit:hover {
  background: linear-gradient(135deg, #27ae60, #219653);
}

.btn-reset:hover {
  background: #d1d9e3;
}

.btn-cancel {
  background: linear-gradient(135deg, #f39c12, #d35400);
  color: white;
}

.btn-cancel:hover {
  background: linear-gradient(135deg, #d35400, #b34700);
}

.btn-restore {
  background: linear-gradient(135deg, #3498db, #2980b9);
  color: white;
}

.btn-restore:hover {
  background: linear-gradient(135deg, #2980b9, #1f6aa5);
}

.btn-view {
  background: linear-gradient(135deg, #9b59b6, #8e44ad);
  color: white;
}

.btn-view:hover {
  background: linear-gradient(135deg, #8e44ad, #7d3c98);
}

/* 只读输入框样式 */
input[readonly], textarea[readonly] {
  background-color: #f8f9fa;
  border: 1px solid #e9ecef;
  color: #6c757d;
  cursor: not-allowed;
}
</style>
