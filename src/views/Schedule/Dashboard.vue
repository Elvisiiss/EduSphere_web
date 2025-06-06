<template>
  <div class="dashboard-container">
    <!-- 顶栏 -->
    <div class="topbar">
      <div class="topbar-content">
        <button class="topbar-btn" @click="setActiveComponent('ScheduleList')">
          <i class="icon-list"></i> 我的日程
        </button>
        <button class="topbar-btn" @click="setActiveComponent('AddSchedule')">
          <i class="icon-add"></i> 添加日程
        </button>
        <button class="topbar-btn" @click="setActiveComponent('CalendarView')">
          <i class="icon-calendar"></i> 日历视图
        </button>
      </div>
    </div>

    <!-- 主内容区 -->
    <div class="main-content">
      <component :is="activeComponent" />
    </div>
  </div>
</template>

<script setup>
import { ref, shallowRef } from 'vue'
import ScheduleList from './ScheduleList.vue'
import AddSchedule from './AddSchedule.vue'
import CalendarView from './CalendarView.vue'

const activeComponent = shallowRef(ScheduleList)

const setActiveComponent = (component) => {
  switch(component) {
    case 'ScheduleList':
      activeComponent.value = ScheduleList
      break
    case 'AddSchedule':
      activeComponent.value = AddSchedule
      break
    case 'CalendarView':
      activeComponent.value = CalendarView
      break
    default:
      activeComponent.value = ScheduleList
  }
}
</script>

<style scoped>
.dashboard-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.topbar {
  width: 100%;
  background-color: #2c3e50;
  color: white;
  padding: 0.5rem 1rem;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.topbar-content {
  display: flex;
  justify-content: center;
  gap: 1rem;
  max-width: 1200px;
  margin: 0 auto;
}

.topbar-btn {
  background: transparent;
  border: none;
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1rem;
}

.topbar-btn:hover {
  background-color: #34495e;
}

.main-content {
  flex: 1;
  padding: 1rem;
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
}
</style>
