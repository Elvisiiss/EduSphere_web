<template>
  <div class="visual-innovation">
    <!-- 筛选控制区 -->
    <div class="control-panel">
      <div class="filter-row">
        <label>选择班级:</label>
        <select v-model="selectedClass">
          <option value="">请选择班级</option>
          <option v-for="classItem in classes" :key="classItem.classId" :value="classItem.classId">
            {{ classItem.className }}
          </option>
        </select>

        <label>选择科目:</label>
        <div class="subject-checkboxes">
          <label v-for="subject in currentSubjects" :key="subject.subject_id">
            <input
                type="checkbox"
                v-model="selectedSubjects"
                :value="subject.subject_id"
            >
            {{ subject.subject_name }}
          </label>
        </div>

        <label>分数范围:</label>
        <el-slider
            v-model="scoreRange"
            range
            :min="0"
            :max="100"
            @change="renderParallelChart"
        />
      </div>
    </div>

    <!-- 动态平行坐标系 -->
    <div class="chart-section">
      <h3>动态平行坐标系</h3>
      <div class="chart-container">
        <div ref="parallelChart" style="height: 500px;"></div>
      </div>
    </div>

    <!-- 三维成绩地形图 -->
    <div class="chart-section">
      <h3>三维成绩地形图</h3>
      <div class="chart-container">
        <div ref="terrainChart" style="height: 500px;"></div>
      </div>
    </div>

    <!-- 智能叙事看板 -->
    <div class="insight-panel" v-if="analysisInsights.length > 0">
      <h3>智能分析结论</h3>
      <ul>
        <li v-for="(insight, index) in analysisInsights" :key="index">
          {{ insight }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import * as echarts from 'echarts'
import 'echarts-gl'
import { useAuthStore } from '@/stores/auth'
import teacherApi from '@/api/teacher.js'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()
const token = authStore.user?.token

// 数据状态
const classes = ref([])
const selectedClass = ref('')
const currentSubjects = ref([])
const selectedSubjects = ref([])
const scoreRange = ref([0, 100])
const studentsData = ref([])
const selectedStudent = ref(null)
const analysisInsights = ref([])

// 图表引用
const parallelChart = ref(null)
const terrainChart = ref(null)

// 获取班级数据
const fetchClasses = async () => {
  try {
    const response = await teacherApi.getTeacherClassForAll(token)
    if (response.data) {
      classes.value = response.data
      if (classes.value.length > 0) {
        selectedClass.value = classes.value[0].classId
        updateCurrentSubjects(selectedClass.value)
      }
    }
  } catch (err) {
    console.error('获取班级数据失败:', err)
    ElMessage.error('获取班级数据失败')
  }
}

// 更新当前科目列表
const updateCurrentSubjects = (classId) => {
  const classInfo = classes.value.find(c => c.classId === classId)
  if (classInfo) {
    currentSubjects.value = classInfo.subjects
    selectedSubjects.value = currentSubjects.value.map(sub => sub.subject_id)
  }
}

// 获取学生成绩数据
const fetchStudentScores = async () => {
  if (!selectedClass.value) return

  try {
    const allScores = []

    // 获取每个科目的成绩数据
    for (const subject of currentSubjects.value) {
      const response = await teacherApi.getClassScores(
          token,
          selectedClass.value,
          subject.subject_id
      )

      if (Array.isArray(response.data)) {
        allScores.push(...response.data)
      }
    }

    // 处理数据：按学生分组
    const studentsMap = new Map()
    allScores.forEach(score => {
      if (!studentsMap.has(score.studentNumber)) {
        studentsMap.set(score.studentNumber, {
          studentId: score.studentId,
          studentName: score.studentName,
          studentNumber: score.studentNumber,
          scores: {},
          exams: new Set()
        })
      }

      const student = studentsMap.get(score.studentNumber)
      if (!student.scores[score.examName]) {
        student.scores[score.examName] = {}
      }

      student.scores[score.examName][score.subjectId] = score.score
      student.exams.add(score.examName)
    })

    studentsData.value = Array.from(studentsMap.values())

    // 渲染图表
    renderParallelChart()
    renderTerrainChart()
    generateAnalysisInsights()
  } catch (err) {
    console.error('获取学生成绩失败:', err)
    ElMessage.error('获取学生成绩失败')
  }
}

// 渲染动态平行坐标系
const renderParallelChart = () => {
  if (!parallelChart.value || studentsData.value.length === 0) return

  const chart = echarts.init(parallelChart.value)

  // 准备平行坐标系维度 - 简化版，只使用考试名称作为维度
  const dimensions = ['studentName']
  const exams = Array.from(new Set(studentsData.value.flatMap(s => Array.from(s.exams))))

  // 添加考试作为维度
  exams.forEach(exam => {
    dimensions.push(exam)
  })

  // 准备数据 - 保持与维度一致的结构
  const seriesData = studentsData.value.map(student => {
    const dataItem = { studentName: student.studentName };

    // 添加考试成绩
    exams.forEach(exam => {
      // 获取该学生的该考试的第一个科目成绩
      const score = student.scores[exam] ? Object.values(student.scores[exam])[0] : null
      dataItem[exam] = score
    });

    return dataItem;
  });

  // 筛选在分数范围内的数据
  const filteredData = seriesData.filter(item => {
    return exams.some(exam => {
      const score = item[exam]
      return score !== null && score >= scoreRange.value[0] && score <= scoreRange.value[1]
    })
  })

  const option = {
    title: {
      text: '学生成绩动态平行坐标系',
      subtext: '点击学生可高亮其所有学科轨迹'
    },
    tooltip: {
      trigger: 'item',
      formatter: params => {
        const studentName = params.data.studentName
        let html = `<div style="font-weight:bold">${studentName}</div>`

        exams.forEach(exam => {
          const score = params.data[exam]
          if (score !== null) {
            html += `<div>${exam}: ${score}</div>`
          }
        })

        return html
      }
    },
    parallelAxis: dimensions.map((dim, index) => {
      if (index === 0) {
        return {
          dim: index,
          name: '学生',
          type: 'category',
          data: filteredData.map(item => item.studentName),
          axisLabel: {
            interval: 0,
            rotate: 45
          }
        }
      } else {
        return {
          dim: index,
          name: dim, // 直接使用考试名称
          type: 'value',
          min: 0,
          max: 100,
          axisLabel: {
            formatter: '{value}'
          }
        }
      }
    }),
    series: {
      type: 'parallel',
      lineStyle: {
        width: 1,
        opacity: 0.3
      },
      data: filteredData,
      emphasis: {
        lineStyle: {
          width: 3,
          opacity: 1
        }
      },
      selected: selectedStudent.value
          ? {
            studentName: selectedStudent.value.studentName
          }
          : undefined
    }
  }

  chart.setOption(option, true)
  console.log(option)

  // 添加点击事件
  chart.on('click', params => {
    if (params.data) {
      selectedStudent.value = studentsData.value.find(
          s => s.studentName === params.data.studentName
      )
      renderParallelChart() // 重新渲染以高亮选中学生
    }
  })

  // 响应式调整
  window.addEventListener('resize', () => chart.resize())
}

// 渲染三维成绩地形图

const renderTerrainChart = () => {
  if (!terrainChart.value || studentsData.value.length === 0) return

  const chart = echarts.init(terrainChart.value)

  // 准备数据 - 按考试和科目计算班级平均分
  const exams = Array.from(
      new Set(studentsData.value.flatMap(s => Array.from(s.exams)))
  ).sort((a, b) => {
    // 确保a和b都是有效的考试对象
    if (!a || !b) return 0
    return new Date(a.examDate) - new Date(b.examDate)
  })
  console.log('Exams:', exams);
  console.log('Students data:', studentsData.value);
  const subjects = currentSubjects.value
  console.log('Subjects:', subjects);
  // 计算每个考试每个科目的班级平均分
  const data = exams.map((exam, examIndex) => {
    return subjects.map((subject, subjectIndex) => {
      const scores = studentsData.value
          .map(student => student.scores[exam]?.[subject.subject_id])
          .filter(score => score !== undefined && score !== null)

      const avg = scores.length > 0
          ? scores.reduce((sum, val) => sum + val, 0) / scores.length
          : 0

      return [examIndex, subjectIndex, avg]
    })
  }).flat()

  // 计算进步/退步速率 (与前一次考试比较)
  const rateData = exams.map((exam, examIndex) => {
    if (examIndex === 0) return subjects.map(() => 0)

    return subjects.map((subject, subjectIndex) => {
      const prevScores = studentsData.value
          .map(student => student.scores[exams[examIndex-1]]?.[subject.subject_id])
          .filter(score => score !== undefined && score !== null)

      const currentScores = studentsData.value
          .map(student => student.scores[exam]?.[subject.subject_id])
          .filter(score => score !== undefined && score !== null)

      if (prevScores.length === 0 || currentScores.length === 0) return 0

      const prevAvg = prevScores.reduce((sum, val) => sum + val, 0) / prevScores.length
      const currentAvg = currentScores.reduce((sum, val) => sum + val, 0) / currentScores.length

      return currentAvg - prevAvg
    })
  })

  const option = {
    title: {
      text: '三维成绩地形图',
      subtext: 'X轴: 考试时间序列 | Y轴: 学科列表 | Z轴: 班级平均分 | 颜色: 进步/退步速率'
    },
    tooltip: {},
    grid3D: {
      viewControl: {
        autoRotate: true,
        autoRotateSpeed: 10,
        distance: 120
      },
      axisPointer: {
        lineStyle: {
          color: '#ffbd67'
        }
      }
    },
    xAxis3D: {
      type: 'category',
      data: exams,
      name: '考试时间序列'
    },
    yAxis3D: {
      type: 'category',
      data: subjects.map(s => s.subject_name),
      name: '学科列表'
    },
    zAxis3D: {
      type: 'value',
      name: '班级平均分',
      min: 0,
      max: 100
    },
    visualMap: {
      min: -20,
      max: 20,
      dimension: 3,
      inRange: {
        color: ['#313695', '#4575b4', '#74add1', '#abd9e9', '#e0f3f8',
          '#ffffbf', '#fee090', '#fdae61', '#f46d43', '#d73027', '#a50026']
      }
    },
    series: [{
      type: 'bar3D',
      data: data.map((item, index) => {
        const examIndex = item[0]
        const subjectIndex = item[1]
        return {
          value: [...item, rateData[examIndex][subjectIndex]],
          itemStyle: {
            opacity: 0.8
          }
        }
      }),
      shading: 'lambert',
      label: {
        show: false
      },
      emphasis: {
        label: {
          show: true,
          formatter: params => {
            return `平均分: ${params.value[2].toFixed(1)}\n变化: ${params.value[3].toFixed(1)}`
          }
        },
        itemStyle: {
          color: '#ffbd67'
        }
      }
    }]
  }

  chart.setOption(option)

  // 响应式调整
  window.addEventListener('resize', () => chart.resize())
}

// 生成智能分析结论
const generateAnalysisInsights = () => {
  if (studentsData.value.length === 0) return

  const insights = []
  const exams = Array.from(
      new Set(studentsData.value.flatMap(s => Array.from(s.exams)))
  ).sort((a, b) => new Date(a.examDate) - new Date(b.examDate))

  // 1. 分析各科目整体趋势
  currentSubjects.value.forEach(subject => {
    const subjectScores = exams.map(exam => {
      const scores = studentsData.value
          .map(student => student.scores[exam]?.[subject.subject_id])
          .filter(score => score !== undefined && score !== null)

      if (scores.length === 0) return null

      const avg = scores.reduce((sum, val) => sum + val, 0) / scores.length
      const stdDev = Math.sqrt(
          scores.map(s => Math.pow(s - avg, 2)).reduce((a, b) => a + b, 0) / scores.length
      )

      return { exam, avg, stdDev }
    }).filter(item => item !== null)

    if (subjectScores.length < 2) return

    // 计算整体趋势
    const first = subjectScores[0]
    const last = subjectScores[subjectScores.length - 1]
    const trend = last.avg - first.avg
    const stdDevChange = last.stdDev - first.stdDev

    let trendMsg = ''
    if (trend > 5) {
      trendMsg = `${subject.subject_name}整体进步显著，平均分上升了${trend.toFixed(1)}分`
    } else if (trend < -5) {
      trendMsg = `${subject.subject_name}整体有所退步，平均分下降了${Math.abs(trend).toFixed(1)}分`
    } else {
      trendMsg = `${subject.subject_name}成绩保持稳定`
    }

    if (stdDevChange > 2) {
      trendMsg += `，但标准差扩大${stdDevChange.toFixed(1)}分，说明两极分化加剧`
    } else if (stdDevChange < -2) {
      trendMsg += `，且标准差缩小${Math.abs(stdDevChange).toFixed(1)}分，说明成绩分布更集中`
    }

    insights.push(trendMsg)

    // 找出进步最大的考试区间
    let maxImprove = 0
    let maxImproveInterval = ''
    for (let i = 1; i < subjectScores.length; i++) {
      const improve = subjectScores[i].avg - subjectScores[i-1].avg
      if (improve > maxImprove) {
        maxImprove = improve
        maxImproveInterval = `${subjectScores[i-1].exam}到${subjectScores[i].exam}`
      }
    }

    if (maxImprove > 5) {
      insights.push(
          `${subject.subject_name}在${maxImproveInterval}进步最大，平均分提升了${maxImprove.toFixed(1)}分`
      )
    }
  })

  // 2. 分析学生个体表现
  if (selectedStudent.value) {
    const student = selectedStudent.value
    const studentInsights = []

    // 找出最强和最弱科目
    const subjectAverages = {}
    currentSubjects.value.forEach(subject => {
      const scores = exams
          .map(exam => student.scores[exam]?.[subject.subject_id])
          .filter(score => score !== undefined && score !== null)

      if (scores.length > 0) {
        subjectAverages[subject.subject_name] =
            scores.reduce((sum, val) => sum + val, 0) / scores.length
      }
    })

    const sortedSubjects = Object.entries(subjectAverages)
        .sort((a, b) => b[1] - a[1])

    if (sortedSubjects.length > 0) {
      studentInsights.push(
          `${student.studentName}的最强科目是${sortedSubjects[0][0]}，平均分${sortedSubjects[0][1].toFixed(1)}分`
      )

      if (sortedSubjects.length > 1) {
        studentInsights.push(
            `最弱科目是${sortedSubjects[sortedSubjects.length-1][0]}，平均分${sortedSubjects[sortedSubjects.length-1][1].toFixed(1)}分`
        )
      }
    }

    // 找出进步最大的科目
    let maxImproveSubject = ''
    let maxImproveValue = 0
    currentSubjects.value.forEach(subject => {
      const firstScore = student.scores[exams[0]]?.[subject.subject_id]
      const lastScore = student.scores[exams[exams.length-1]]?.[subject.subject_id]

      if (firstScore && lastScore) {
        const improve = lastScore - firstScore
        if (improve > maxImproveValue) {
          maxImproveValue = improve
          maxImproveSubject = subject.subject_name
        }
      }
    })

    if (maxImproveValue > 5) {
      studentInsights.push(
          `${student.studentName}在${maxImproveSubject}科目进步最大，提升了${maxImproveValue.toFixed(1)}分`
      )
    }

    insights.push(...studentInsights)
  }

  analysisInsights.value = insights
}

// 监听选择变化
watch(selectedClass, (newVal) => {
  updateCurrentSubjects(newVal)
  fetchStudentScores()
})

watch(selectedSubjects, () => {
  renderParallelChart()
  renderTerrainChart()
  generateAnalysisInsights()
}, { deep: true })

watch(scoreRange, () => {
  renderParallelChart()
}, { deep: true })

watch(selectedStudent, () => {
  generateAnalysisInsights()
})

// 初始化
onMounted(() => {
  fetchClasses()
})
</script>

<style scoped>
.visual-innovation {
  padding: 20px;
  background-color: #f5f7fa;
}

.control-panel {
  background-color: white;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.filter-row {
  display: flex;
  align-items: center;
  gap: 15px;
  flex-wrap: wrap;
}

.filter-row label {
  font-weight: bold;
  white-space: nowrap;
}

.filter-row select {
  padding: 8px 12px;
  border-radius: 4px;
  border: 1px solid #dcdfe6;
  min-width: 180px;
}

.subject-checkboxes {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.subject-checkboxes label {
  display: flex;
  align-items: center;
  gap: 5px;
  cursor: pointer;
}

.chart-section {
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.chart-section h3 {
  margin-top: 0;
  margin-bottom: 15px;
  color: #333;
}

.chart-container {
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 10px;
  background-color: white;
}

.insight-panel {
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.insight-panel h3 {
  margin-top: 0;
  color: #333;
  border-bottom: 1px solid #eee;
  padding-bottom: 10px;
}

.insight-panel ul {
  list-style-type: none;
  padding-left: 0;
}

.insight-panel li {
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
  line-height: 1.6;
}

.insight-panel li:last-child {
  border-bottom: none;
}

.el-slider {
  width: 200px;
}
</style>
