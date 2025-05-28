import { ref } from 'vue'

export const useDragAndDrop = (sourceItems, compareDimensions) => {
    // 当前被拖拽的项目
    const draggedItem = ref(null)
    const draggedType = ref(null)

    // 开始拖拽
    const dragStart = (event, type, item) => {
        event.dataTransfer.setData('text/plain', JSON.stringify(item))
        draggedItem.value = item
        draggedType.value = type
        event.currentTarget.style.opacity = '0.4'
    }

    // 拖拽经过元素
    const dragOver = (event) => {
        event.preventDefault()
        event.dataTransfer.dropEffect = 'move'
    }

    // 在源区域放置（排序）
    const dropOnSource = (event, type) => {
        event.preventDefault()
        if (draggedType.value !== type) return

        const sourceList = sourceItems.value.find(item => item.type === type).items
        const dropIndex = Array.from(event.currentTarget.parentNode.children).indexOf(event.currentTarget)

        // 从原位置移除
        const itemIndex = sourceList.findIndex(item => item.id === draggedItem.value.id)
        if (itemIndex > -1) {
            sourceList.splice(itemIndex, 1)
        }

        // 插入到新位置
        sourceList.splice(dropIndex, 0, draggedItem.value)

        resetDragState(event)
    }

    // 在对比区域放置
    const dropOnCompare = (event, targetType) => {
        event.preventDefault()

        // 如果拖拽的不是当前类型的项目，且不是从源区域拖拽的，则不允许放置
        if (draggedType.value !== targetType &&
            !sourceItems.value.some(group => group.type === draggedType.value)) {
            return
        }

        // 检查是否已存在相同项目
        const exists = compareDimensions.value[targetType].some(
            item => item.id === draggedItem.value.id
        )

        if (!exists) {
            // 添加到对比区域
            compareDimensions.value[targetType].push({
                ...draggedItem.value,
                // 如果是跨类型拖拽，保持原始类型信息
                originalType: draggedType.value !== targetType ? draggedType.value : undefined
            })
        }

        resetDragState(event)
    }

    // 从对比区域移除项目
    const removeFromCompare = (type, id) => {
        compareDimensions.value[type] = compareDimensions.value[type].filter(
            item => item.id !== id
        )
    }

    // 重置拖拽状态
    const resetDragState = (event) => {
        if (event.currentTarget) {
            event.currentTarget.style.opacity = '1'
        }
        draggedItem.value = null
        draggedType.value = null
    }

    return {
        draggedItem,
        draggedType,
        dragStart,
        dragOver,
        dropOnSource,
        dropOnCompare,
        removeFromCompare
    }
}
