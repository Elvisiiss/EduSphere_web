<script setup>
import { ref, computed, watch, nextTick, onMounted } from 'vue'
import { useDragAndDrop } from './dragAndDrop'
import { useAuthStore } from '@/stores/auth'
import teacherApi from '@/api/teacher.js'
import * as echarts from 'echarts'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()
const token = authStore.user?.token

// 数据状态
const classes = ref([])
const students = ref([])
const subjects = ref([])
const exams = ref([])
const isLoading = ref(false)

// 拖拽区域状态
const sourceItems = ref([])
const compareDimensions = ref({
  class: [],
  student: [],
  subject: [],
  exam: []
})

// 对比结果数据
const comparisonData = ref(null)
const chartInstance = ref(null)

// 初始化数据
const initData = async () => {
  try {
    isLoading.value = true

    // 获取班级数据
    const classResponse = await teacherApi.getTeacherClassForAll(token)
    classes.value = classResponse.data || []

    // 初始化源项目
    sourceItems.value = [
      {
        type: 'class',
        label: '班级',
        items: classes.value.map(c => ({
          id: c.classId,
          name: c.className,
          rawData: c
        }))
      },
      {
        type: 'subject',
        label: '科目',
        items: classes.value.flatMap(c =>
            c.subjects.map(s => ({
              id: s.subject_id,
              name: s.subject_name,
              rawData: s
            }))
                .filter((s, i, arr) => arr.findIndex(t => t.id === s.id) === i)
        )
      }
    ]

    // 默认选中第一个班级
    if (classes.value.length > 0) {
      await fetchClassData(classes.value[0].classId)
    }
  } catch (error) {
    ElMessage.error('初始化数据失败: ' + error.message)
  } finally {
    isLoading.value = false
  }
}

// 获取班级相关数据
const fetchClassData = async (classId) => {
  try {
    isLoading.value = true

    // 获取学生数据
    const scoresResponse = await teacherApi.getClassScores(token, classId)
    if (scoresResponse.data && scoresResponse.data.length > 0) {
      const uniqueStudents = {}
      const uniqueExams = {}

      scoresResponse.data.forEach(item => {
        // 处理学生数据
        if (!uniqueStudents[item.studentNumber]) {
          uniqueStudents[item.studentNumber] = {
            id: item.studentNumber,
            name: `${item.studentName} (${item.studentNumber})`,
            rawData: {
              studentId: item.studentId,
              studentName: item.studentName,
              studentNumber: item.studentNumber
            }
          }
        }

        // 处理考试数据
        if (!uniqueExams[item.examName]) {
          uniqueExams[item.examName] = {
            id: item.examName,
            name: item.examName,
            rawData: {
              examName: item.examName,
              examDate: item.examDate
            }
          }
        }
      })

      students.value = Object.values(uniqueStudents)
      exams.value = Object.values(uniqueExams)

      // 更新源项目
      sourceItems.value = [
        ...sourceItems.value.filter(item => item.type !== 'student' && item.type !== 'exam'),
        {
          type: 'student',
          label: '学生',
          items: students.value
        },
        {
          type: 'exam',
          label: '考试',
          items: exams.value
        }
      ]
    }
  } catch (error) {
    ElMessage.error('获取班级数据失败: ' + error.message)
  } finally {
    isLoading.value = false
  }
}

// 拖拽相关逻辑
const {
  dragStart,
  dragOver,
  dropOnSource,
  dropOnCompare,
  removeFromCompare
} = useDragAndDrop(sourceItems, compareDimensions)

// 执行对比分析
const performComparison = async () => {
  try {
    isLoading.value = true

    // 构建请求参数
    const params = {
      classIds: compareDimensions.value.class.map(c => c.id),
      studentNumbers: compareDimensions.value.student.map(s => s.id),
      subjectIds: compareDimensions.value.subject.map(s => s.id),
      examNames: compareDimensions.value.exam.map(e => e.id)
    }

    // 如果没有选择任何维度，则提示用户
    if (Object.values(params).every(arr => arr.length === 0)) {
      ElMessage.warning('请至少选择一个对比维度')
      return
    }

    // 获取对比数据
    const response = await teacherApi.getComparisonData(token, params)
    comparisonData.value = response.data

    // 渲染图表
    renderComparisonChart()
  } catch (error) {
    ElMessage.error('对比分析失败: ' + error.message)
  } finally {
    isLoading.value = false
  }
}

// 渲染对比图表
const renderComparisonChart = () => {
  if (!comparisonData.value) return

  // 销毁旧图表实例
  if (chartInstance.value) {
    chartInstance.value.dispose()
  }

  const chartDom = document.getElementById('comparison-chart')
  if (!chartDom) return

  chartInstance.value = echarts.init(chartDom)

  // 根据数据类型决定图表类型
  const chartType = determineChartType()

  // 准备图表数据
  const { xAxisData, seriesData } = prepareChartData(chartType)

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      }
    },
    legend: {
      data: seriesData.map(s => s.name)
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: xAxisData,
      axisLabel: {
        rotate: 30
      }
    },
    yAxis: {
      type: 'value',
      name: '分数'
    },
    series: seriesData
  }

  // 特殊处理不同类型图表
  if (chartType === 'radar') {
    option.radar = {
      indicator: xAxisData.map(item => ({ name: item, max: 100 }))
    }
    option.series.forEach(s => {
      s.type = 'radar'
    })
  }

  chartInstance.value.setOption(option)

  // 响应式调整
  window.addEventListener('resize', function() {
    chartInstance.value.resize()
  })
}

// 根据选择的维度决定图表类型
const determineChartType = () => {
  const { class: classes, student: students, subject: subjects, exam: exams } = compareDimensions.value

  // 如果有时间维度，使用折线图
  if (exams.length > 0) return 'line'

  // 如果对比多个班级或多个学生，使用柱状图
  if (classes.length > 1 || students.length > 1) return 'bar'

  // 默认使用雷达图
  return 'radar'
}

// 准备图表数据
const prepareChartData = (chartType) => {
  const data = comparisonData.value
  let xAxisData = []
  let seriesData = []

  // 根据不同类型准备数据
  if (chartType === 'line') {
    // 时间序列数据
    xAxisData = [...new Set(data.map(item => item.examName))]

    // 按班级/学生分组
    const groups = {}
    data.forEach(item => {
      const groupKey = item.className || item.studentName
      if (!groups[groupKey]) {
        groups[groupKey] = {
          name: groupKey,
          type: 'line',
          data: new Array(xAxisData.length).fill(null)
        }
      }

      const index = xAxisData.indexOf(item.examName)
      groups[groupKey].data[index] = item.score
    })

    seriesData = Object.values(groups)
  } else if (chartType === 'bar') {
    // 对比数据
    const dimension = compareDimensions.value.class.length > 0 ? 'class' :
        compareDimensions.value.student.length > 0 ? 'student' :
            compareDimensions.value.subject.length > 0 ? 'subject' : 'exam'

    xAxisData = compareDimensions.value[dimension].map(item => item.name)

    // 如果有科目维度，则按科目分组
    if (compareDimensions.value.subject.length > 0) {
      const subjects = compareDimensions.value.subject

      subjects.forEach(subject => {
        seriesData.push({
          name: subject.name,
          type: 'bar',
          data: xAxisData.map(cls => {
            const item = data.find(d =>
                (d.classId === cls.id || d.studentNumber === cls.id) &&
                d.subjectId === subject.id
            )
            return item ? item.score : 0
          })
        })
      })
    } else {
      // 没有科目维度，直接显示平均分
      seriesData.push({
        name: '平均分',
        type: 'bar',
        data: xAxisData.map(cls => {
          const items = data.filter(d => d.classId === cls.id || d.studentNumber === cls.id)
          return items.length > 0 ?
              items.reduce((sum, item) => sum + item.score, 0) / items.length : 0
        })
      })
    }
  } else {
    // 雷达图数据
    const indicators = [...new Set(data.map(item => item.subjectName || '综合评分'))]
    xAxisData = indicators

    // 按班级/学生分组
    const groups = {}
    data.forEach(item => {
      const groupKey = item.className || item.studentName
      if (!groups[groupKey]) {
        groups[groupKey] = {
          name: groupKey,
          value: new Array(indicators.length).fill(0),
          count: new Array(indicators.length).fill(0)
        }
      }

      const index = indicators.indexOf(item.subjectName || '综合评分')
      groups[groupKey].value[index] += item.score
      groups[groupKey].count[index]++
    })

    seriesData = Object.entries(groups).map(([name, group]) => ({
      name,
      value: group.value.map((sum, i) => group.count[i] > 0 ? sum / group.count[i] : 0)
    }))
  }

  return { xAxisData, seriesData }
}

// 监听班级变化
watch(() => compareDimensions.value.class, (newClasses) => {
  if (newClasses.length > 0) {
    fetchClassData(newClasses[0].id)
  }
}, { deep: true })

// 初始化
onMounted(() => {
  initData()
})
</script>

<template>
  <div class="interactive-analysis">
    <div class="analysis-header">
      <h2>拖拽式多维对比分析</h2>
      <p class="tip">拖拽左侧项目到右侧对比区域，自由组合分析维度</p>
    </div>

    <div class="analysis-container">
      <!-- 源项目区域 -->
      <div class="source-panel">
        <div
            v-for="group in sourceItems"
            :key="group.type"
            class="source-group"
        >
          <h4>{{ group.label }}</h4>
          <ul>
            <li
                v-for="item in group.items"
                :key="`${group.type}-${item.id}`"
                draggable="true"
                @dragstart="dragStart($event, group.type, item)"
                @dragover="dragOver($event)"
                @drop="dropOnSource($event, group.type)"
                class="source-item"
            >
              {{ item.name }}
            </li>
          </ul>
        </div>
      </div>

      <!-- 对比区域 -->
      <div class="compare-panel">
        <div class="compare-dimensions">
          <div
              v-for="(dimension, type) in compareDimensions"
              :key="type"
              class="dimension-group"
              @dragover="dragOver($event)"
              @drop="dropOnCompare($event, type)"
          >
            <h4>{{
                type === 'class' ? '班级' :
                    type === 'student' ? '学生' :
                        type === 'subject' ? '科目' : '考试'
              }}</h4>
            <div v-if="dimension.length > 0" class="dimension-items">
              <div
                  v-for="item in dimension"
                  :key="`${type}-${item.id}`"
                  class="dimension-item"
              >
                {{ item.name }}
                <el-icon
                    class="remove-icon"
                    @click="removeFromCompare(type, item.id)"
                >
                  <Close />
                </el-icon>
              </div>
            </div>
            <div v-else class="dimension-placeholder">
              拖拽{{
                type === 'class' ? '班级' :
                    type === 'student' ? '学生' :
                        type === 'subject' ? '科目' : '考试'
              }}到此处
            </div>
          </div>
        </div>

        <div class="compare-actions">
          <el-button
              type="primary"
              @click="performComparison"
              :loading="isLoading"
          >
            开始分析
          </el-button>
          <el-button @click="compareDimensions = {
            class: [],
            student: [],
            subject: [],
            exam: []
          }">
            清空选择
          </el-button>
        </div>
      </div>
    </div>

    <!-- 结果展示区域 -->
    <div class="result-panel" v-show="comparisonData">
      <div id="comparison-chart" style="width: 100%; height: 500px;"></div>

      <div class="data-table" v-if="comparisonData && comparisonData.length > 0">
        <h3>详细数据</h3>
        <el-table :data="comparisonData" border style="width: 100%">
          <el-table-column
              v-for="column in Object.keys(comparisonData[0])"
              :key="column"
              :prop="column"
              :label="{
              'classId': '班级ID',
              'className': '班级名称',
              'studentId': '学生ID',
              'studentName': '学生姓名',
              'studentNumber': '学号',
              'subjectId': '科目ID',
              'subjectName': '科目名称',
              'examName': '考试名称',
              'examDate': '考试日期',
              'score': '分数',
              'comment': '评语'
            }[column] || column"
          ></el-table-column>
        </el-table>
      </div>
    </div>
  </div>
</template>

<style scoped>
.interactive-analysis {
  padding: 20px;
  background-color: #f5f7fa;
  min-height: 100%;
}

.analysis-header {
  margin-bottom: 20px;
  padding: 15px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.analysis-header h2 {
  margin: 0;
  color: #303133;
}

.analysis-header .tip {
  margin: 5px 0 0;
  color: #909399;
  font-size: 14px;
}

.analysis-container {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.source-panel {
  flex: 1;
  padding: 15px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.source-group {
  margin-bottom: 20px;
}

.source-group h4 {
  margin: 0 0 10px;
  color: #606266;
  font-size: 14px;
}

.source-group ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.source-item {
  padding: 8px 12px;
  background-color: #f0f2f5;
  border-radius: 4px;
  cursor: grab;
  font-size: 13px;
  transition: all 0.2s;
}

.source-item:hover {
  background-color: #e1e4e8;
}

.compare-panel {
  flex: 2;
  padding: 15px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.compare-dimensions {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
  margin-bottom: 20px;
}

.dimension-group {
  min-height: 120px;
  padding: 15px;
  border: 1px dashed #dcdfe6;
  border-radius: 8px;
  transition: all 0.2s;
}

.dimension-group h4 {
  margin: 0 0 10px;
  color: #606266;
  font-size: 14px;
}

.dimension-items {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.dimension-item {
  position: relative;
  padding: 8px 12px;
  padding-right: 30px;
  background-color: #f0f9eb;
  border-radius: 4px;
  font-size: 13px;
}

.dimension-item .remove-icon {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  cursor: pointer;
  color: #67c23a;
  font-size: 12px;
}

.dimension-placeholder {
  color: #c0c4cc;
  font-size: 13px;
  text-align: center;
  padding: 20px 0;
}

.compare-actions {
  display: flex;
  justify-content: center;
  gap: 15px;
}

.result-panel {
  padding: 15px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.data-table {
  margin-top: 20px;
}

.data-table h3 {
  margin: 20px 0 15px;
  color: #303133;
}
</style>
