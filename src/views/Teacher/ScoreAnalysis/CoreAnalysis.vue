<template>
  <div class="core-analysis">
    <!-- 跨班对比分析 -->
    <div class="analysis-section">
      <h3>跨班对比分析</h3>
      <div class="filter-row">
        <label>选择对比班级:</label>
        <select v-model="selectedClassA" @change="fetchCrossClassData">
          <option value="">请选择班级A</option>
          <option v-for="classItem in classes" :key="classItem.classId" :value="classItem.classId">
            {{ classItem.className }}
          </option>
        </select>
        <select v-model="selectedClassB" @change="fetchCrossClassData">
          <option value="">请选择班级B</option>
          <option v-for="classItem in classes" :key="classItem.classId" :value="classItem.classId">
            {{ classItem.className }}
          </option>
        </select>
        <label>选择科目:</label>
        <select v-model="selectedSubject" @change="fetchCrossClassData">
          <option value="">请选择科目</option>
          <option v-for="subject in currentSubjects" :key="subject.subject_id" :value="subject.subject_id">
            {{ subject.subject_name }}
          </option>
        </select>
      </div>



      <div v-if="crossClassData" class="chart-container">
        <div ref="radarChart" style="height: 400px;"></div>
      </div>
    </div>

    <!-- 时序演进分析 -->
    <div class="analysis-section">
      <h3>时序演进分析</h3>
      <div class="filter-row">
        <label>选择班级:</label>
        <select v-model="selectedClass" @change="fetchTrendData">
          <option value="">请选择班级</option>
          <option v-for="classItem in classes" :key="classItem.classId" :value="classItem.classId">
            {{ classItem.className }}
          </option>
        </select>
        <label>选择科目:</label>
        <select v-model="selectedTrendSubject" @change="fetchTrendData"> <!-- 修改为 selectedTrendSubject -->
          <option value="">请选择科目</option>
          <option v-for="subject in currentSubjects" :key="subject.subject_id" :value="subject.subject_id">
            {{ subject.subject_name }}
          </option>
        </select>
        <label>选择学生:</label>
        <select v-model="selectedStudent" @change="fetchTrendData">
          <option value="">全班趋势</option>
          <option v-for="student in classStudents" :key="student.studentNumber" :value="student.studentNumber">
            {{ student.studentName }} ({{ student.studentNumber }})
          </option>
        </select>
      </div>

      <div v-if="trendData" class="chart-container">
        <div ref="trendChart" style="height: 500px;"></div>
      </div>
    </div>

    <!-- 智能诊断系统 -->
    <div class="analysis-section">
      <h3>智能诊断系统</h3>
      <div class="filter-row">
        <div class="threshold-controls">
          <label>优秀阈值:</label>
          <input type="number" v-model="excellentThreshold" min="0" max="100" @change="fetchDiagnosisData">
          <label>危险阈值:</label>
          <input type="number" v-model="dangerThreshold" min="0" max="100" @change="fetchDiagnosisData">
        </div>
      </div>

      <div v-if="selectedClass && !diagnosisData" class="loading-tip">
        <el-icon class="is-loading"><loading /></el-icon>
        正在分析班级数据...
      </div>



      <div v-if="diagnosisData" class="diagnosis-results">
        <div class="header-info">
          最后更新时间：{{ diagnosisData.lastUpdated }}
          <el-tag type="success" size="small">
            {{ classes.find(c => c.classId === diagnosisData.classId)?.className }}
          </el-tag>
        </div>
        <div class="diagnosis-section">
          <h4>学生学业状态分析</h4>
          <div class="stats-overview">
            <div class="stat-card" v-for="stat in diagnosisStats" :key="stat.label">
              <div class="stat-value">{{ stat.value }}</div>
              <div class="stat-label">{{ stat.label }}</div>
            </div>
          </div>

          <div class="student-lists">
            <div class="student-category">
              <h5>优秀学生 <span class="badge excellent">{{ excellentStudents.length }}</span></h5>
              <ul>
                <li v-for="student in excellentStudents" :key="student.studentNumber">
                  {{ student.studentName }} ({{ student.studentNumber }}) -
                  <span v-for="sub in student.excellentSubjects" :key="sub.name" class="subject-tag excellent">
                {{ sub.name }}: {{ sub.score }}
              </span>
                </li>
              </ul>
            </div>

            <div class="student-category">
              <h5>临界生预警 <span class="badge warning">{{ criticalStudents.length }}</span></h5>
              <ul>
                <li v-for="student in criticalStudents" :key="student.studentNumber">
                  {{ student.studentName }} ({{ student.studentNumber }}) -
                  <span class="risk-level" :class="student.riskLevel">
                {{ student.riskSubject }}: {{ student.riskScore }} ({{ getRiskLabel(student.riskLevel) }})
              </span>
                </li>
              </ul>
            </div>

            <div class="student-category">
              <h5>偏科学生 <span class="badge unbalanced">{{ unbalancedStudents.length }}</span></h5>
              <ul>
                <li v-for="student in unbalancedStudents" :key="student.studentNumber">
                  {{ student.studentName }} ({{ student.studentNumber }}) -
                  偏科指数: <span class="unbalance-index">{{ student.unbalanceIndex.toFixed(2) }}</span>
                  <div class="subject-distribution">
                <span v-for="sub in student.subjects" :key="sub.name"
                      :title="`${sub.name}: ${sub.score}`"
                      :style="{ width: getSubjectWidth(sub.score) }"
                      :class="getSubjectClass(sub.score)">
                </span>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed, nextTick, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import teacherApi from '@/api/teacher.js'
import * as echarts from 'echarts'
import {ElMessage} from "element-plus";
import { Loading } from '@element-plus/icons-vue'
import axios from "axios";

const authStore = useAuthStore()
const token = authStore.user?.token

// 跨班对比数据
const selectedClassA = ref('')
const selectedClassB = ref('')
const selectedSubject = ref('')
const crossClassData = ref(null)
const subjectMatrixData = ref(null)
const radarChart = ref(null)
const matrixChart = ref(null)
const compareMode = ref('single') // 'single' 或 'multi'

// 时序分析数据
const selectedClass = ref('')
const selectedTrendSubject = ref('') // 新增：专门用于时序分析的科目选择
const selectedStudent = ref('')
const trendData = ref(null)
const classStudents = ref([])
const trendChart = ref(null)

// 智能诊断数据
const criticalStudents = ref([])
const unbalancedStudents = ref([])
const excellentThreshold = ref(90)
const dangerThreshold = ref(60)
const diagnosisStats = ref([])
const excellentStudents = ref([])
const diagnosisData = ref(null)
// 获取班级数据
const classes = ref([])
const currentSubjects = ref([])

onMounted(() => {
  fetchClasses()
})


// 获取班级列表
const fetchClasses = async () => {
  try {
    const response = await teacherApi.getTeacherClassForAll(token)
    if (response.data) {
      classes.value = response.data
      if (classes.value.length > 0) {
        // 设置默认值
        selectedClass.value = classes.value[0].classId
        selectedClassA.value = classes.value[0].classId
        selectedClassB.value = classes.value[1]?.classId || ''
        // 更新科目列表
        updateCurrentSubjects(selectedClass.value)
      }
    }
  } catch (err) {
    console.error('获取班级数据失败:', err)
  }
}

// 所有科目数据
const allSubjects = computed(() => {
  const subjects = []
  classes.value.forEach(cls => {
    cls.subjects.forEach(sub => {
      if (!subjects.some(s => s.subject_id === sub.subject_id)) {
        subjects.push(sub)
      }
    })
  })
  return subjects
})

// 切换对比模式
const toggleCompareMode = () => {
  compareMode.value = compareMode.value === 'single' ? 'multi' : 'single'
  if (compareMode.value === 'multi' && selectedClassA.value && selectedClassB.value) {
    fetchSubjectMatrixData()
  } else if (compareMode.value === 'single' && selectedClassA.value && selectedClassB.value && selectedSubject.value) {
    fetchCrossClassData()
  }
}

// 获取班级学科强弱矩阵数据
const fetchSubjectMatrixData = async () => {
  if (!selectedClassA.value || !selectedClassB.value) return

  try {
    const classA = classes.value.find(c => c.classId === selectedClassA.value)
    const classB = classes.value.find(c => c.classId === selectedClassB.value)

    // 获取两班共有的科目
    const commonSubjects = classA.subjects.filter(subA =>
        classB.subjects.some(subB => subB.subject_id === subA.subject_id))

    // 获取各科目数据
    const matrixData = []

    for (const subject of commonSubjects) {
      // 获取班级A数据
      const dataA = await teacherApi.getClassScores(
          token,
          selectedClassA.value,
          subject.subject_id
      )
      // 获取班级B数据
      const dataB = await teacherApi.getClassScores(
          token,
          selectedClassB.value,
          subject.subject_id
      )

      // 计算统计指标
      const statsA = calculateStats(dataA)
      const statsB = calculateStats(dataB)

      // 计算优势指标 (班级A标准差 - 班级B标准差)
      const advantageScore = statsB.standardDeviation - statsA.standardDeviation

      matrixData.push({
        subject: subject.subject_name,
        classA: statsA,
        classB: statsB,
        advantageScore: advantageScore
      })
    }

    subjectMatrixData.value = matrixData.sort((a, b) => b.advantageScore - a.advantageScore)

    // 渲染矩阵图
    renderMatrixChart()
  } catch (err) {
    console.error('获取学科矩阵数据失败:', err)
  }
}

// 渲染学科强弱矩阵图
const renderMatrixChart = () => {
  if (!matrixChart.value || !subjectMatrixData.value) return

  const chart = echarts.init(matrixChart.value)

  // 准备数据
  const subjects = subjectMatrixData.value.map(item => item.subject)
  const classAAvg = subjectMatrixData.value.map(item => parseFloat(item.classA.average))
  const classBAvg = subjectMatrixData.value.map(item => parseFloat(item.classB.average))
  const classAStd = subjectMatrixData.value.map(item => parseFloat(item.classA.standardDeviation))
  const classBStd = subjectMatrixData.value.map(item => parseFloat(item.classB.standardDeviation))
  const advantageData = subjectMatrixData.value.map(item => item.advantageScore)

  const option = {
    title: {
      text: '班级学科强弱矩阵',
      subtext: '标准差越小表示成绩越稳定(优势学科)'
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      },
      formatter: function(params) {
        const data = subjectMatrixData.value[params[0].dataIndex]
        return `
          <strong>${data.subject}</strong><br/>
          班级A: 平均分 ${data.classA.average} | 标准差 ${data.classA.standardDeviation}<br/>
          班级B: 平均分 ${data.classB.average} | 标准差 ${data.classB.standardDeviation}<br/>
          优势指数: ${data.advantageScore.toFixed(2)}
        `
      }
    },
    legend: {
      data: ['班级A平均分', '班级B平均分', '班级A标准差', '班级B标准差', '优势指数']
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'value',
      name: '分数/标准差'
    },
    yAxis: {
      type: 'category',
      data: subjects,
      axisLabel: {
        interval: 0,
        rotate: 30
      }
    },
    series: [
      {
        name: '班级A平均分',
        type: 'bar',
        stack: 'classA',
        data: classAAvg,
        itemStyle: {
          color: '#5470C6'
        }
      },
      {
        name: '班级A标准差',
        type: 'bar',
        stack: 'classA',
        data: classAStd,
        itemStyle: {
          color: '#91CC75'
        }
      },
      {
        name: '班级B平均分',
        type: 'bar',
        stack: 'classB',
        data: classBAvg,
        itemStyle: {
          color: '#EE6666'
        }
      },
      {
        name: '班级B标准差',
        type: 'bar',
        stack: 'classB',
        data: classBStd,
        itemStyle: {
          color: '#FAC858'
        }
      },
      {
        name: '优势指数',
        type: 'scatter',
        data: advantageData.map((score, index) => ({
          value: [score, index],
          symbolSize: Math.abs(score) * 5 + 10,
          itemStyle: {
            color: score > 0 ? '#73C0DE' : '#FF7F7F'
          }
        })),
        symbol: 'circle',
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }
    ]
  }

  chart.setOption(option)

  // 响应式调整
  window.addEventListener('resize', function() {
    chart.resize()
  })
}

// 更新当前科目列表
const updateCurrentSubjects = (classId) => {
  const classInfo = classes.value.find(c => c.classId === classId)
  if (classInfo) {
    currentSubjects.value = classInfo.subjects
    if (currentSubjects.value.length > 0) {
      selectedSubject.value = currentSubjects.value[0].subject_id
      selectedTrendSubject.value = currentSubjects.value[0].subject_id // 设置默认值
    }
  }
}

// 修改后的跨班对比数据获取
const fetchCrossClassData = async () => {
  if (!selectedClassA.value || !selectedClassB.value) return;
  if (compareMode.value === 'single' && !selectedSubject.value) return;

  try {
    // 获取班级A数据 - 添加更健壮的数据处理
    const responseA = await teacherApi.getClassScores(
        token,
        selectedClassA.value,
        selectedSubject.value
    );

    // 获取班级B数据
    const responseB = await teacherApi.getClassScores(
        token,
        selectedClassB.value,
        selectedSubject.value
    );

    // 更健壮的数据提取逻辑
    const extractScores = (response) => {
      // 情况1: 直接返回数组
      if (Array.isArray(response)) return response;
      // 情况2: 返回对象包含data属性
      if (response && Array.isArray(response.data)) return response.data;
      // 情况3: 其他情况返回空数组
      console.warn('无法解析的响应数据格式:', response);
      return [];
    };

    const dataA = extractScores(responseA);
    const dataB = extractScores(responseB);

    const statsA = calculateStats(dataA);
    const statsB = calculateStats(dataB);

    crossClassData.value = {
      classA: statsA,
      classB: statsB,
      subjectName: allSubjects.value.find(s => s.subject_id === selectedSubject.value)?.subject_name || selectedSubject.value,
      classNameA: classes.value.find(c => c.classId === selectedClassA.value)?.className || '未知班级A',
      classNameB: classes.value.find(c => c.classId === selectedClassB.value)?.className || '未知班级B'
    };

    // 确保DOM更新后再渲染图表
    nextTick(() => {
      renderRadarChart();
    });
  } catch (err) {
    console.error('跨班对比数据获取失败:', err);
    // 可以添加用户提示
    ElMessage.error('获取对比数据失败，请稍后重试');
  }
};


// 修改后的时序数据获取
const fetchTrendData = async () => {
  if (!selectedClass.value || !selectedTrendSubject.value) return // 使用 selectedTrendSubject

  try {
    const response = await teacherApi.getClassScores(
        token,
        selectedClass.value,
        selectedTrendSubject.value, // 使用 selectedTrendSubject
        null // 获取所有考试
    )

    // 确保我们处理的是数组数据
    const scores = Array.isArray(response?.data) ? response.data : []

    if (scores.length === 0) {
      ElMessage.warning('没有找到相关考试数据')
      return
    }

    // 处理学生数据
    processStudentData(scores)

    // 按考试时间排序
    const sortedScores = scores.sort((a, b) =>
        new Date(a.examDate) - new Date(b.examDate))

    // 处理趋势数据
    processTrendData(sortedScores)

    // 渲染趋势图
    renderTrendChart()
  } catch (err) {
    console.error('时序数据获取失败:', err)
    ElMessage.error('获取时序数据失败，请稍后重试')
  }
}

// 处理学生数据
const processStudentData = (scores) => {
  if (!Array.isArray(scores)) {
    console.warn('processStudentData: scores不是数组', scores)
    classStudents.value = []
    return
  }

  const studentsMap = new Map()
  scores.forEach(score => {
    if (!studentsMap.has(score.studentNumber)) {
      studentsMap.set(score.studentNumber, {
        studentNumber: score.studentNumber,
        studentName: score.studentName
      })
    }
  })
  classStudents.value = Array.from(studentsMap.values())
}

// 处理趋势数据
const processTrendData = (sortedScores) => {
  if (!Array.isArray(sortedScores)) {
    console.warn('processTrendData: sortedScores不是数组', sortedScores)
    trendData.value = null
    return
  }

  // 按考试分组
  const examGroups = {}
  sortedScores.forEach(score => {
    if (!examGroups[score.examName]) {
      examGroups[score.examName] = {
        examName: score.examName,
        date: score.examDate?.split('T')[0] || '未知日期',
        scores: [],
        studentScores: {}
      }
    }
    examGroups[score.examName].scores.push(score.score)
    examGroups[score.examName].studentScores[score.studentNumber] = score.score
  })

  // 计算班级平均分
  const examAverages = Object.values(examGroups).map(item => ({
    examName: item.examName,
    date: item.date,
    average: (item.scores.reduce((a, b) => a + b, 0) / item.scores.length)
  }))

  // 如果选择了特定学生，获取该学生成绩
  let studentScores = []
  if (selectedStudent.value) {
    studentScores = Object.values(examGroups).map(item => ({
      examName: item.examName,
      date: item.date,
      score: item.studentScores[selectedStudent.value] || null
    }))
  }

  trendData.value = {
    examAverages,
    studentScores,
    hasStudentData: selectedStudent.value !== ''
  }
}

// 智能诊断数据获取
const fetchDiagnosisData = async () => {
  if (!selectedClass.value) {
    diagnosisData.value = null // 清空数据
    return
  }

  try {
    // 重置所有数据
    diagnosisData.value = null
    criticalStudents.value = []
    unbalancedStudents.value = []
    excellentStudents.value = []
    diagnosisStats.value = []

    // Get class info
    const classInfo = classes.value.find(c => c.classId === selectedClass.value)
    if (!classInfo) return

    // Get all subject scores for the class
    const allSubjectScores = {}
    const studentRecords = {} // To store all student data
    for (const subject of classInfo.subjects) {
      const response = await teacherApi.getClassScores(
          token,
          selectedClass.value,
          subject.subject_id
      )

      const scores = Array.isArray(response.data) ? response.data : []
      allSubjectScores[subject.subject_id] = scores

      // Build student records
      scores.forEach(score => {
        if (!studentRecords[score.studentNumber]) {
          studentRecords[score.studentNumber] = {
            studentNumber: score.studentNumber,
            studentName: score.studentName,
            subjects: [],
            riskSubjects: [],
            excellentSubjects: []
          }
        }

        const subjectData = {
          id: subject.subject_id,
          name: subject.subject_name,
          score: score.score
        }

        studentRecords[score.studentNumber].subjects.push(subjectData)

        // Check for risk levels
        const riskLevel = getRiskLevel(score.score)
        if (riskLevel) {
          studentRecords[score.studentNumber].riskSubjects.push({
            ...subjectData,
            riskLevel
          })
        }

        // Check for excellent scores
        if (score.score >= excellentThreshold.value) {
          studentRecords[score.studentNumber].excellentSubjects.push(subjectData)
        }
      })
    }

    // Process all students
    Object.values(studentRecords).forEach(student => {
      // 1. Identify excellent students (any subject >= excellent threshold)
      if (student.excellentSubjects.length > 0) {
        excellentStudents.value.push({
          ...student,
          excellentCount: student.excellentSubjects.length
        })
      }

      // 2. Identify critical students (any subject <= danger threshold)
      const criticalSubjects = student.riskSubjects.filter(sub =>
          sub.riskLevel === 'danger' || sub.riskLevel === 'warning'
      )

      if (criticalSubjects.length > 0) {
        // Find the most critical subject
        const mostCritical = criticalSubjects.reduce((prev, current) =>
            (prev.score < current.score) ? prev : current
        )

        criticalStudents.value.push({
          ...student,
          riskSubject: mostCritical.name,
          riskScore: mostCritical.score,
          riskLevel: mostCritical.riskLevel
        })
      }

      // 3. Calculate unbalance index for all students with multiple subjects
      if (student.subjects.length > 1) {
        const scores = student.subjects.map(sub => sub.score)
        const stdDev = calculateStandardDeviation(scores)

        // Calculate normalized unbalance index (0-100 scale)
        const maxPossibleStdDev = 50 // Theoretical max for 0-100 scores
        const unbalanceIndex = (stdDev / maxPossibleStdDev) * 100

        student.unbalanceIndex = Math.min(unbalanceIndex, 100) // Cap at 100

        // Only include if significantly unbalanced
        if (unbalanceIndex > 20) { // Threshold for being considered unbalanced
          unbalancedStudents.value.push(student)
        }
      }
    })

    // Sort students
    excellentStudents.value.sort((a, b) => b.excellentCount - a.excellentCount)
    criticalStudents.value.sort((a, b) => a.riskScore - b.riskScore)
    unbalancedStudents.value.sort((a, b) => b.unbalanceIndex - a.unbalanceIndex)

    // Calculate class statistics
    calculateClassStatistics(allSubjectScores, classInfo)

    diagnosisData.value = {
      lastUpdated: new Date().toLocaleString(),
      classId: selectedClass.value
    }
  } catch (err) {
    diagnosisData.value = null
    console.error('智能诊断数据获取失败:', err)
    ElMessage.error('获取诊断数据失败，请稍后重试')
  }
}

const calculateClassStatistics = (allSubjectScores, classInfo) => {
  let totalStudents = 0
  let excellentCount = 0
  let dangerCount = 0
  let warningCount = 0

  // Count students in each category
  excellentCount = excellentStudents.value.length
  dangerCount = criticalStudents.value.filter(s => s.riskLevel === 'danger').length
  warningCount = criticalStudents.value.filter(s => s.riskLevel === 'warning').length

  // Get unique student count
  const allStudents = new Set()
  Object.values(allSubjectScores).forEach(scores => {
    scores.forEach(score => allStudents.add(score.studentNumber))
  })
  totalStudents = allStudents.size

  // Prepare stats for display
  diagnosisStats.value = [
    { label: '总学生数', value: totalStudents },
    { label: '优秀学生', value: excellentCount },
    { label: '危险临界生', value: dangerCount },
    { label: '预警临界生', value: warningCount },
    { label: '偏科学生', value: unbalancedStudents.value.length },
    { label: '平均偏科指数', value: calculateAverageUnbalanceIndex().toFixed(2) }
  ]
}

const calculateAverageUnbalanceIndex = () => {
  if (unbalancedStudents.value.length === 0) return 0
  const sum = unbalancedStudents.value.reduce((acc, student) =>
      acc + student.unbalanceIndex, 0)
  return sum / unbalancedStudents.value.length
}

const getSubjectWidth = (score) => {
  return `${score}%`
}

const getSubjectClass = (score) => {
  if (score >= excellentThreshold.value) return 'excellent'
  if (score < dangerThreshold.value) return 'danger'
  return 'normal'
}

const getRiskLabel = (level) => {
  switch(level) {
    case 'danger': return '危险'
    case 'warning': return '预警'
    case 'excellent': return '优秀'
    default: return ''
  }
}

// 添加默认统计值函数
const getDefaultStats = () => ({
  average: '0.0',
  max: '0.0',
  min: '0.0',
  passRate: '0.0',
  standardDeviation: '0.0',
  count: 0
});

// 修改后的雷达图渲染函数
const renderRadarChart = () => {
  if (!radarChart.value || !crossClassData.value) {
    console.warn('渲染雷达图缺少必要参数:', {
      chartRef: !!radarChart.value,
      data: !!crossClassData.value
    });
    return;
  }

  const chart = echarts.init(radarChart.value);

  // 确保容器有尺寸
  if (radarChart.value.offsetWidth === 0 || radarChart.value.offsetHeight === 0) {
    console.warn('图表容器尺寸为0，延迟渲染');
    setTimeout(renderRadarChart, 100);
    return;
  }

  try {
    const option = {
      title: {
        text: '同科目对比雷达图',
        subtext: `${crossClassData.value.subjectName} 学科对比`
      },
      tooltip: {
        trigger: 'item'
      },
      legend: {
        data: [crossClassData.value.classNameA, crossClassData.value.classNameB]
      },
      radar: {
        indicator: [
          { name: '平均分', max: 100 },
          { name: '最高分', max: 100 },
          { name: '最低分', max: 100 },
          { name: '及格率(%)', max: 100 },
          { name: '标准差', max: Math.max(
                parseFloat(crossClassData.value.classA.standardDeviation),
                parseFloat(crossClassData.value.classB.standardDeviation)
            ) * 1.5 || 20 } // 默认最大值
        ],
        radius: '65%'
      },
      series: [{
        type: 'radar',
        data: [
          {
            value: [
              parseFloat(crossClassData.value.classA.average) || 0,
              parseFloat(crossClassData.value.classA.max) || 0,
              parseFloat(crossClassData.value.classA.min) || 0,
              parseFloat(crossClassData.value.classA.passRate) || 0,
              parseFloat(crossClassData.value.classA.standardDeviation) || 0
            ],
            name: crossClassData.value.classNameA,
            areaStyle: { color: 'rgba(84, 112, 198, 0.4)' },
            lineStyle: { width: 2, color: '#5470C6' }
          },
          {
            value: [
              parseFloat(crossClassData.value.classB.average) || 0,
              parseFloat(crossClassData.value.classB.max) || 0,
              parseFloat(crossClassData.value.classB.min) || 0,
              parseFloat(crossClassData.value.classB.passRate) || 0,
              parseFloat(crossClassData.value.classB.standardDeviation) || 0
            ],
            name: crossClassData.value.classNameB,
            areaStyle: { color: 'rgba(238, 102, 102, 0.4)' },
            lineStyle: { width: 2, color: '#EE6666' }
          }
        ]
      }]
    };

    chart.setOption(option);

    // 响应式调整
    const resizeHandler = () => chart.resize();
    window.addEventListener('resize', resizeHandler);

    // 清理
    onUnmounted(() => {
      window.removeEventListener('resize', resizeHandler);
      chart.dispose();
    });
  } catch (err) {
    console.error('渲染雷达图失败:', err);
  }
};

// 修改后的统计指标计算函数
const calculateStats = (scores) => {
  // 防御性处理：确保scores是数组
  if (!Array.isArray(scores)) {
    console.error('calculateStats: scores参数不是数组', scores);
    return getDefaultStats();
  }

  // 提取有效分数并转换为数字
  const validScores = scores
      .map(item => {
        // 处理可能的嵌套结构
        const scoreValue = item?.score ?? item?.scoreValue ?? null;
        if (scoreValue !== null) {
          const score = parseFloat(scoreValue);
          return isNaN(score) ? null : score;
        }
        return null;
      })
      .filter(score => score !== null && score >= 0 && score <= 100); // 过滤掉无效分数

  if (validScores.length === 0) {
    console.warn('calculateStats: 无有效分数数据', scores);
    return getDefaultStats();
  }

  // 计算统计指标
  const sum = validScores.reduce((a, b) => a + b, 0);
  const average = sum / validScores.length;
  const max = Math.max(...validScores);
  const min = Math.min(...validScores);
  const passCount = validScores.filter(s => s >= 60).length;
  const passRate = (passCount / validScores.length) * 100;
  const standardDeviation = calculateStandardDeviation(validScores);

  return {
    average: average.toFixed(1),
    max: max.toFixed(1),
    min: min.toFixed(1),
    passRate: passRate.toFixed(1),
    standardDeviation: standardDeviation.toFixed(1),
    count: validScores.length // 添加样本数用于调试
  };
};

// 标准差计算函数
const calculateStandardDeviation = (values) => {
  const mean = values.reduce((a, b) => a + b, 0) / values.length
  const variance = values.reduce((acc, val) => acc + Math.pow(val - mean, 2), 0) / values.length
  return Math.sqrt(variance)
}

// 临界生风险等级判断
const getRiskLevel = (score) => {
  if (score >= excellentThreshold.value) return 'excellent'
  if (score < dangerThreshold.value) return 'danger'
  if (score < dangerThreshold.value + 10) return 'warning'
  return null
}



// 修改后的趋势图渲染函数
const renderTrendChart = () => {
  if (!trendChart.value || !trendData.value) return

  const chart = echarts.init(trendChart.value)

  // 准备数据
  const xAxisData = trendData.value.examAverages.map(item => item.examName)
  const averageData = trendData.value.examAverages.map(item => item.average)

  const series = [{
    name: '班级平均分',
    type: 'line',
    data: averageData.map(value => parseFloat(value.toFixed(3))),
    symbol: 'circle',
    symbolSize: 8,
    lineStyle: {
      width: 3,
      color: '#5470C6'
    },
    itemStyle: {
      color: '#5470C6'
    },
    markLine: {
      data: [{ type: 'average', name: '平均线' }],
      lineStyle: {
        color: '#5470C6',
        type: 'dashed'
      }
    }
  }]

  // 如果选择了学生，添加学生数据
  if (trendData.value.hasStudentData) {
    const studentData = trendData.value.studentScores.map(item => item.score)
    series.push({
      name: '学生成绩',
      type: 'line',
      data: studentData,
      symbol: 'diamond',
      symbolSize: 10,
      lineStyle: {
        width: 3,
        color: '#EE6666'
      },
      itemStyle: {
        color: '#EE6666'
      },
      markPoint: {
        data: [
          { type: 'max', name: '最高分' },
          { type: 'min', name: '最低分' }
        ]
      }
    })
  }

  const option = {
    title: {
      text: '成绩趋势分析',
      subtext: trendData.value.hasStudentData
          ? `${classStudents.value.find(s => s.studentNumber === selectedStudent.value)?.studentName || '学生'} vs 班级平均`
          : '班级平均成绩趋势'
    },
    tooltip: {
      trigger: 'axis',
      formatter: params => {
        let result = `${params[0].axisValue}<br>`
        params.forEach(param => {
          result += `${param.seriesName}: ${param.value}<br>`
        })
        return result
      }
    },
    legend: {
      data: series.map(item => item.name)
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: xAxisData,
      axisLabel: {
        rotate: 30
      }
    },
    yAxis: {
      type: 'value',
      name: '分数',
      min: 0,
      max: 100
    },
    series: series
  }

  chart.setOption(option)

  // 响应式调整
  const resizeHandler = () => chart.resize()
  window.addEventListener('resize', resizeHandler)

  // 清理
  onUnmounted(() => {
    window.removeEventListener('resize', resizeHandler)
    chart.dispose()
  })
}

// 其他工具函数保持不变...

// 监听班级变化，更新科目列表
watch(selectedClass, (newVal) => {
  updateCurrentSubjects(newVal)
  fetchTrendData()
  fetchDiagnosisData()
})

// 监听跨班对比相关选择变化
watch([selectedClassA, selectedClassB, selectedSubject], () => {
  fetchCrossClassData()
})

// 监听时序分析科目变化
watch(selectedTrendSubject, () => {
  fetchTrendData()
})

watch(compareMode, () => {
  if (selectedClassA.value && selectedClassB.value) {
    fetchCrossClassData()
  }
})
</script>

<style scoped>
.compare-mode-btn {
  margin-left: 20px;
  padding: 5px 10px;
  background-color: #409eff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.compare-mode-btn:hover {
  background-color: #66b1ff;
}

.filter-row {
  display: flex;
  gap: 15px;
  align-items: center;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filter-row label {
  font-weight: bold;
}

.filter-row select {
  padding: 5px 10px;
  border-radius: 4px;
  border: 1px solid #dcdfe6;
}

.chart-container {
  margin-top: 20px;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 20px;
  background-color: white;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.analysis-section {
  background-color: white;
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
}

.filter-row {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.chart-container {
  border: 1px solid #f0f0f0;
  border-radius: 4px;
}

.student-list {
  list-style: none;
  padding: 0;
}

.student-list li {
  padding: 5px 0;
  display: flex;
  justify-content: space-between;
}

.riskLevel {
  padding: 2px 5px;
  border-radius: 3px;
}

.riskLevel.danger {
  color: #e74c3c;
  border: 1px solid #fcebeb;
}

.riskLevel.warning {
  color: #f39c12;
  border: 1px solid #fff3cd;
}

.riskLevel.excellent {
  color: #27ae60;
  border: 1px solid #e0f2d9;
}

.threshold-controls {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-left: 20px;
}

.threshold-controls input {
  width: 50px;
  padding: 5px;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
}

.diagnosis-results {
  margin-top: 20px;
}

.stats-overview {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 15px;
  margin-bottom: 20px;
}

.stat-card {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 15px;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #409eff;
}

.stat-label {
  font-size: 14px;
  color: #666;
}

.student-lists {
  display: grid;
  gap: 20px;
}

.student-category {
  background: white;
  border-radius: 8px;
  padding: 15px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}

.student-category h5 {
  margin-top: 0;
  margin-bottom: 10px;
  display: flex;
  align-items: center;
}

.badge {
  display: inline-block;
  min-width: 20px;
  padding: 2px 6px;
  border-radius: 10px;
  font-size: 12px;
  text-align: center;
  margin-left: 8px;
}

.badge.excellent {
  background: #e1f3d8;
  color: #67c23a;
}

.badge.warning {
  background: #faecd8;
  color: #e6a23c;
}

.badge.unbalanced {
  background: #fde2e2;
  color: #f56c6c;
}

.student-category ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.student-category li {
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.student-category li:last-child {
  border-bottom: none;
}

.subject-tag {
  display: inline-block;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 12px;
  margin-left: 5px;
}

.subject-tag.excellent {
  background: #e1f3d8;
  color: #67c23a;
}

.risk-level {
  font-weight: bold;
}

.risk-level.danger {
  color: #f56c6c;
}

.risk-level.warning {
  color: #e6a23c;
}

.risk-level.excellent {
  color: #67c23a;
}

.unbalance-index {
  font-weight: bold;
  color: #f56c6c;
}

.subject-distribution {
  display: flex;
  height: 6px;
  margin-top: 4px;
  border-radius: 3px;
  overflow: hidden;
}

.subject-distribution span {
  display: inline-block;
  height: 100%;
  margin-right: 1px;
}

.subject-distribution .excellent {
  background: #67c23a;
}

.subject-distribution .danger {
  background: #f56c6c;
}

.subject-distribution .normal {
  background: #409eff;
}
</style>
