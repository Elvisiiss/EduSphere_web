<template>
  <div class="score-analysis">
    <!-- 新增导航菜单 -->
    <div class="analysis-navbar">
      <button
          class="nav-btn"
          @click="activeTab = 'core'"
          :class="{ active: activeTab === 'core' }"
      >
        核心分析维度
      </button>
      <button
          class="nav-btn"
          @click="activeTab = 'visual'"
          :class="{ active: activeTab === 'visual' }"
      >
        可视化创新
      </button>
      <button
          class="nav-btn"
          @click="activeTab = 'interactive'"
          :class="{ active: activeTab === 'interactive' }"
      >
        交互分析
      </button>
    </div>

    <!-- 内容渲染区域 -->
    <div v-if="loading" class="loading">
      <!-- 加载中状态 -->
    </div>
    <div v-else-if="error" class="error">
      <!-- 错误状态 -->
    </div>
    <div v-else class="analysis-content">
      <!-- 核心分析模块 -->
      <CoreAnalysis
          v-show="activeTab === 'core'"
          :selectedClassId="selectedClassId"
          :selectedSubjectId="selectedSubjectId"
      />

      <!-- 可视化创新模块 -->
      <VisualInnovation
          v-show="activeTab === 'visual'"
          :allScores="allScores"
          :selectedExams="selectedExams"
      />

      <!-- 交互分析模块 -->
      <InteractiveAnalysis
          v-show="activeTab === 'interactive'"
          @drag-start="handleDragStart"
      />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import CoreAnalysis from './ScoreAnalysis/CoreAnalysis.vue'
import VisualInnovation from './ScoreAnalysis/VisualInnovation.vue'
import InteractiveAnalysis from './ScoreAnalysis/InteractiveAnalysis.vue'

// 新增导航状态
const activeTab = ref('core')

// 传递原有数据到子模块
const selectedClassId = ref('')
const selectedSubjectId = ref('')
const allScores = ref([])
const selectedExams = ref([''])

// 拖拽交互处理（示例）
const handleDragStart = (dimension) => {
  console.log('开始拖拽对比维度:', dimension)
  // 可扩展拖拽逻辑
}
</script>

<style scoped>
.analysis-navbar {
  background-color: #f8fafc;
  padding: 15px 20px;
  border-radius: 8px;
  margin-bottom: 25px;
  display: flex;
  gap: 20px;
}

.nav-btn {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  background-color: #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
}

.nav-btn.active {
  background-color: #3498db;
  color: white;
  box-shadow: 0 4px 12px rgba(0,0,0,0.2);
}
</style>
