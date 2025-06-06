<template>
  <div class="upload-img-container">
    <div class="tabs">
      <button
          @click="activeTab = 'upload'"
          :class="{ active: activeTab === 'upload' }"
      >
        上传文件
      </button>
      <button
          @click="activeTab = 'gallery'; fetchFiles();"
          :class="{ active: activeTab === 'gallery' }"
      >
        我的文件
      </button>
    </div>

    <!-- 上传文件区域 -->
    <div v-if="activeTab === 'upload'" class="upload-section">
      <div class="upload-box" @dragover.prevent @drop="handleDrop">
        <input
            type="file"
            ref="fileInput"
            @change="handleFileSelect"
            accept="*"
            multiple
            class="hidden-input"
        >
        <div class="upload-prompt">
          <p v-if="!selectedFiles.length">拖放文件到此处或<span class="browse-link" @click="triggerFileInput">点击浏览</span></p>
          <div v-else class="selected-files">
            <p>已选择 {{ selectedFiles.length }} 个文件</p>
            <div class="file-names">
              <span v-for="(file, index) in selectedFiles" :key="index">
                {{ file.name }}<span v-if="index < selectedFiles.length - 1">, </span>
              </span>
            </div>
          </div>
        </div>
      </div>

      <button
          @click="uploadFiles"
          :disabled="!selectedFiles.length || isUploading"
          class="upload-btn"
      >
        {{ isUploading ? `上传中... (${uploadProgress}%)` : '开始上传' }}
      </button>
    </div>

    <!-- 文件展示区域 -->
    <!-- 文件展示区域 -->
    <div v-else class="gallery-section">
      <div v-if="isLoading" class="loading">加载文件中...</div>

      <div v-else-if="files.length === 0" class="empty-gallery">
        <p>您还没有上传任何文件</p>
      </div>

      <div v-else class="file-grid">
        <div v-for="(file, index) in files" :key="index" class="file-item">
          <div class="file-icon-container">
            <template v-if="isImage(file.name)">
              <img :src="file.url" alt="用户上传的文件" class="file-thumbnail" />
            </template>
            <template v-else>
              <div class="file-icon">
                <span>{{ getFileExtension(file.name) }}</span>
              </div>
            </template>
          </div>
          <div class="file-info">
            <div class="file-name" :title="file.name">{{ file.name }}</div>
            <div class="file-type">{{ getFileType(file.name) }}</div>
          </div>
          <div class="file-actions">
            <button @click="copyFileUrl(file.url)" class="action-btn copy-btn">复制链接</button>
            <button @click="deleteFile(file.url)" class="action-btn delete-btn">删除</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import userAPI from '@/api/user.js'
import Swal from "sweetalert2";

const authStore = useAuthStore()
const token = ref('')

// 标签页状态
const activeTab = ref('upload')

// 文件上传相关状态
const fileInput = ref(null)
const selectedFiles = ref([])
const isUploading = ref(false)
const uploadProgress = ref(0)

// 文件展示相关状态
const files = ref([])
const isLoading = ref(false)

// 初始化获取token
onMounted(() => {
  token.value = authStore.user?.token || ''
})

// 触发文件选择对话框
const triggerFileInput = () => {
  fileInput.value.click()
}

// 处理文件选择
const handleFileSelect = (event) => {
  selectedFiles.value = Array.from(event.target.files)
}

// 处理文件拖放
const handleDrop = (event) => {
  event.preventDefault()
  selectedFiles.value = Array.from(event.dataTransfer.files)
}

// 复制文件URL
const copyFileUrl = (text) => {
  const textarea = document.createElement('textarea');
  textarea.value = text;
  document.body.appendChild(textarea);
  textarea.select();

  try {
    const successful = document.execCommand('copy');
    Swal.fire(successful ? '链接已复制！' : '复制失败，请手动复制');
  } catch (err) {
    Swal.fire('复制失败，请手动复制');
    console.error('复制失败:', err);
  } finally {
    document.body.removeChild(textarea);
  }
};

// 上传文件
const uploadFiles = async () => {
  if (!token.value || !selectedFiles.value.length) return

  isUploading.value = true
  uploadProgress.value = 0

  try {
    for (const file of selectedFiles.value) {
      const formData = new FormData()
      formData.append('file', file)
      formData.append('msg', '上传文件')
      formData.append('user_token', token.value)
      formData.append('file_name', file.name)  // 添加文件名参数

      await userAPI.upload_img(
          token.value,
          file,
          file.name
      )
    }

    Swal.fire('文件上传成功！')
    selectedFiles.value = []
  } catch (error) {
    console.error('上传失败:', error)
    Swal.fire('文件上传失败，请重试')
  } finally {
    isUploading.value = false
    uploadProgress.value = 0
  }
}

// 获取所有文件
const fetchFiles = async () => {
  if (!token.value) return

  isLoading.value = true
  files.value = []

  try {
    const response = await userAPI.get_all_my_img(token.value)
    // 修改点：直接使用API返回的文件名和URL
    files.value = response.data.map(item => ({
      name: item.file_name,
      url: item.file_url
    }))
  } catch (error) {
    console.error('获取文件失败:', error)
  } finally {
    isLoading.value = false
  }
}

// 删除文件
const deleteFile = async (fileUrl) => {
  if (!token.value || !confirm('确定要删除这个文件吗？')) return

  try {
    await userAPI.delete_my_img(token.value, fileUrl)
    files.value = files.value.filter(file => file.url !== fileUrl)
  } catch (error) {
    console.error('删除文件失败:', error)
  }
}

// 判断是否为图片文件
const isImage = (fileName) => {
  const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp']
  const ext = getFileExtension(fileName).toLowerCase()
  return imageExtensions.includes(ext)
}

// 获取文件扩展名
const getFileExtension = (fileName) => {
  return fileName.split('.').pop().split('?')[0]
}

// 获取文件名（从URL中提取）
const getFileName = (url) => {
  const path = url.split('/').pop()
  return path ? decodeURIComponent(path.split('?')[0]) : '未知文件'
}

// 获取文件类型描述
const getFileType = (fileName) => {
  const ext = getFileExtension(fileName).toLowerCase()
  const typeMap = {
    jpg: 'JPEG 图片',
    jpeg: 'JPEG 图片',
    png: 'PNG 图片',
    gif: 'GIF 图片',
    bmp: '位图图片',
    svg: '矢量图',
    webp: 'WebP 图片',
    pdf: 'PDF 文档',
    doc: 'Word 文档',
    docx: 'Word 文档',
    xls: 'Excel 表格',
    xlsx: 'Excel 表格',
    ppt: 'PPT 演示',
    pptx: 'PPT 演示',
    txt: '文本文件',
    zip: '压缩文件',
    rar: '压缩文件',
    '7z': '压缩文件',
    mp3: '音频文件',
    wav: '音频文件',
    mp4: '视频文件',
    mov: '视频文件',
    avi: '视频文件',
    mkv: '视频文件',
    exe: '应用程序',
    js: 'JavaScript 文件',
    json: 'JSON 文件',
    html: '网页文件',
    css: '样式表'
  }

  return typeMap[ext] || `${ext.toUpperCase()} 文件`
}
</script>

<style scoped>
.upload-img-container {
  max-width: 1000px;
  margin: 0 auto;
  padding: 20px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.tabs {
  display: flex;
  border-bottom: 1px solid #eee;
  margin-bottom: 20px;
}

.tabs button {
  padding: 10px 20px;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 16px;
  color: #666;
  position: relative;
}

.tabs button.active {
  color: #3498db;
  font-weight: bold;
}

.tabs button.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  width: 100%;
  height: 3px;
  background-color: #3498db;
}

/* 上传区域样式 */
.upload-section {
  text-align: center;
}

.upload-box {
  border: 2px dashed #ddd;
  border-radius: 8px;
  padding: 40px 20px;
  margin-bottom: 20px;
  transition: border-color 0.3s;
  cursor: pointer;
}

.upload-box:hover {
  border-color: #3498db;
}

.hidden-input {
  display: none;
}

.upload-prompt {
  color: #777;
}

.browse-link {
  color: #3498db;
  text-decoration: underline;
  cursor: pointer;
  margin-left: 5px;
}

.selected-files {
  margin-top: 15px;
}

.file-names {
  max-height: 100px;
  overflow-y: auto;
  margin-top: 10px;
  padding: 5px;
  background-color: #f9f9f9;
  border-radius: 4px;
  font-size: 14px;
}

.upload-btn {
  padding: 10px 25px;
  background-color: #2ecc71;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s;
}

.upload-btn:hover:not(:disabled) {
  background-color: #27ae60;
}

.upload-btn:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}

/* 文件展示区域样式 */
.gallery-section {
  min-height: 300px;
}

.loading, .empty-gallery {
  text-align: center;
  padding: 50px 0;
  color: #7f8c8d;
}

.file-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.file-item {
  position: relative;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s;
  background: #fff;
  display: flex;
  flex-direction: column;
  height: 240px;
}

.file-item:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.file-icon-container {
  height: 140px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f8f9fa;
  border-bottom: 1px solid #eee;
}

.file-icon {
  width: 80px;
  height: 80px;
  background: #3498db;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  font-size: 18px;
}

.file-thumbnail {
  width: 100%;
  height: 140px;
  object-fit: contain;
  background-color: #f8f9fa;
}

.file-info {
  padding: 12px;
  flex-grow: 1;
}

.file-name {
  font-size: 14px;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-bottom: 4px;
}

.file-type {
  font-size: 12px;
  color: #666;
}

.delete-btn {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 5px 10px;
  background-color: rgba(231, 76, 60, 0.9);
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  opacity: 0;
  transition: opacity 0.3s;
}

.file-item:hover .delete-btn {
  opacity: 1;
}

.file-actions {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.action-btn {
  flex: 1;
  padding: 6px 10px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.2s;
}

.copy-btn {
  background-color: #3498db;
  color: white;
}

.copy-btn:hover {
  background-color: #2980b9;
}

.delete-btn {
  background-color: #e74c3c;
  color: white;
}

.delete-btn:hover {
  background-color: #c0392b;
}

/* 调整文件信息区域 */
.file-info {
  padding: 12px;
}
</style>
