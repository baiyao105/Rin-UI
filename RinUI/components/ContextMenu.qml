import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import "../themes"
import "../components"
import "ListAndCollections" as Collections


Popup {
    id: contextMenu
    position: Position.None

    // 选中信号 / Signal //
    signal itemSelected(int index)

    property alias model: listView.model
    property alias currentIndex: listView.currentIndex
    property int maximumHeight: 300  // 最大高度
    property string textRole: ""

    // 菜单最小宽度（通常为锚点控件宽度，避免比控件窄）
    property real minimumWidth: parent ? parent.width : 100

    // 布局常量
    QtObject {
        id: consts
        readonly property real margin: 8       // 与窗口边缘的安全距离
        readonly property real listInset: 2    // ListView 上下内边距
        readonly property real textPadding: 21 // 行文字左右留白（leftPadding 16 + rightPadding 5）
        readonly property real animHeight: 46  // 打开动画的初始高度
    }

    // 内部状态（按职责分组到 props，避免顶层属性名过多）
    QtObject {
        id: props

        // 定位
        property int mode: 0          // 0=居中(选中项对准锚点) 1=对齐上 2=对齐下
        property bool busy: false     // 定位计算进行中（避免宽度回调重入）

        // 打开动画缓存（求值为数值，避免动画期间绑定被 height 变化反复重求值）
        property bool animating: false       // 打开动画进行中（期间 contentY 由动画驱动）
        property real heightFrom: consts.animHeight
        property real heightTo: consts.animHeight
        property real yFrom: 0
        property real yTo: 0
        property real startContentY: 0       // 起始滚动（展开时先显示选中项附近）
        property real finalContentY: 0       // 最终滚动（动画结束时收敛，消除与 layout 的偏差）
    }

    implicitWidth: minimumWidth
    implicitHeight: Math.min(listView.contentHeight + consts.listInset * 2, maximumHeight)
    closePolicy: Popup.CloseOnPressOutside
    focus: true

    // 隐藏的测量文本：与列表项使用同一 Text/字体，用于计算最长单行宽度
    Text {
        id: textProbe
        visible: false
        typography: Typography.Body
        wrapMode: Text.NoWrap
    }

    // 内容 / ListView //
    contentItem: Collections.ListView {
        id: listView
        clip: true
        focus: true
        focusPolicy: Qt.StrongFocus
        textRole: contextMenu.textRole
        anchors.fill: parent  // 清除边距
        anchors.topMargin: consts.listInset
        anchors.bottomMargin: consts.listInset

        onItemClicked: function(index) {
            contextMenu.close()
            contextMenu.itemSelected(index)
        }

        // 展开动画完成后才显示；平时按内容是否溢出决定
        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            visible: !props.animating && listView.contentHeight > listView.height
        }
    }

    // ---------- 定位 / Positioning ----------
    function _overlay() {
        return Overlay.overlay
    }

    // 提取单个数据项显示的文字
    function _textValue(data) {
        if (data === null || data === undefined)
            return ""
        if (textRole && typeof data === "object") {
            var v = data[textRole]
            return (v !== undefined && v !== null) ? String(v) : ""
        }
        return String(data)
    }

    // 收集全部文字（兼容 DelegateModel / ListModel / 数组 / 类 ListModel）
    function _collectTexts() {
        var src = model
        // 展开 DelegateModel（ComboBox 的 popup model 即 delegateModel）
        if (src && typeof src === "object" && !Array.isArray(src)
                && typeof src.get !== "function" && src.model !== undefined && src.model !== null) {
            src = src.model
        }

        var texts = []
        var i
        if (Array.isArray(src)) {
            for (i = 0; i < src.length; i++)
                texts.push(_textValue(src[i]))
        } else if (src && typeof src.get === "function") {
            var n = src.count || 0
            for (i = 0; i < n; i++)
                texts.push(_textValue(src.get(i)))
        } else if (src && typeof src.count === "number") {
            for (i = 0; i < src.count; i++) {
                var d
                try { d = src[i] } catch (e) { d = undefined }
                texts.push(_textValue(d))
            }
        }
        return texts
    }

    // 最长文字宽度（不换行）
    function _measureMaxTextWidth() {
        var texts = _collectTexts()
        var maxW = 0
        for (var i = 0; i < texts.length; i++) {
            textProbe.text = texts[i]
            maxW = Math.max(maxW, textProbe.implicitWidth)
        }
        return maxW
    }

    // 某水平候选位置的可见宽度
    function _visibleAreaX(xx, w, overlay) {
        var left = Math.max(xx, consts.margin)
        var right = Math.min(xx + w, overlay.width - consts.margin)
        return Math.max(0, right - left)
    }

    // 依据锚点（parent=combobox）与窗口边界计算 位置/高度/滚动。
    // 优先级：窗口边界避让 > 选中项与 combobox 的对齐
    function _computeLayout() {
        var overlay = _overlay()
        if (!overlay || !parent)
            return null

        listView.forceLayout()

        var contentH = listView.contentHeight
        var count = listView.count
        if (count < 1 || contentH <= 0)
            return null

        var anchorOrigin = parent.mapToItem(overlay, 0, 0)
        var anchorX = anchorOrigin.x
        var anchorY = anchorOrigin.y
        var anchorW = parent.width
        var anchorH = parent.height

        var rowH = contentH / count
        var hasSelection = listView.currentIndex >= 0
        var idx = hasSelection ? Math.min(listView.currentIndex, count - 1) : 0
        var selTop = idx * rowH
        var fullH = contentH + consts.listInset * 2
        var maxAvailH = overlay.height - consts.margin * 2

        // 选中项顶部相对锚点顶部应处的位置（行高大于控件高时不居中，避免顶部裁剪）
        var offset = Math.max(0, (anchorH - rowH) / 2)

        // 高度上限：无论对齐与否，都先夹紧到窗口内（边界优先）
        var menuH = Math.min(fullH, maximumHeight, maxAvailH)

        var mode = 0
        var popupY = anchorY + (anchorH - menuH) / 2
        var contentY = 0
        var aligned = false

        if (hasSelection) {
            // 1) 居中：选中项对准 combobox（仅当整块都落在窗口内才采用）
            var centerY = anchorY + offset - consts.listInset - selTop
            if (centerY >= consts.margin && centerY + menuH <= overlay.height - consts.margin) {
                mode = 0
                popupY = centerY
                contentY = 0
                aligned = true
            } else {
                // 2) 对齐上：菜单顶部贴 combobox 顶部，选中项在列表最上方
                var topY = anchorY + offset - consts.listInset
                var topH = topY >= consts.margin
                    ? Math.min(menuH, overlay.height - topY - consts.margin,
                               contentH - selTop + consts.listInset * 2)
                    : 0
                // 3) 对齐下：菜单底部贴 combobox 底部，选中项尽量在列表最下方。
                //    高度不再受“选中项须贴列表最下方”约束（窗口边界避让优先）：
                //    下方空间不足时整块向上生长，选中项由 contentY 夹紧处理（会回到顶部）。
                var bottom = anchorY + anchorH - offset + consts.listInset
                var bottomH = Math.min(menuH, bottom - consts.margin)
                var bottomY = bottom - bottomH
                var topOk = topH >= consts.listInset * 2 + rowH
                var bottomOk = bottomH >= consts.listInset * 2 + rowH && bottomY >= consts.margin

                // 居中溢出上方优先对齐上、溢出下方优先对齐下；一侧不可行则换另一侧
                if (centerY < consts.margin) {
                    if (topOk) {
                        mode = 1; popupY = topY; menuH = topH; aligned = true
                    } else if (bottomOk) {
                        mode = 2; popupY = bottomY; menuH = bottomH; aligned = true
                    }
                } else {
                    if (bottomOk) {
                        mode = 2; popupY = bottomY; menuH = bottomH; aligned = true
                    } else if (topOk) {
                        mode = 1; popupY = topY; menuH = topH; aligned = true
                    }
                }
            }
        }

        // 兜底：无法对齐时，边界内就近放置（边界优先于对齐），选中项尽量可见
        if (hasSelection && !aligned) {
            mode = 0
            menuH = Math.min(fullH, maximumHeight, maxAvailH)
            popupY = anchorY + (anchorH - menuH) / 2
            var listH = menuH - consts.listInset * 2
            contentY = Math.max(0, Math.min(selTop - (listH - rowH) / 2,
                                            Math.max(0, contentH - listH)))
        }

        // 滚动位置：居中最终置顶（选中项对准 combobox）；对齐上/下复用 _scrollFor
        if (hasSelection && mode !== 0)
            contentY = _scrollFor(menuH, mode)

        // 最终夹紧：不越过窗口边界（最高优先级）
        menuH = Math.max(menuH, consts.listInset * 2)
        menuH = Math.min(menuH, maxAvailH)
        var minY = consts.margin
        var maxY = overlay.height - menuH - consts.margin
        popupY = Math.max(minY, Math.min(popupY, Math.max(minY, maxY)))

        // x：未选中时居中；否则默认左对齐，右侧放不下翻转到右对齐；
        // 都放不下选可见面积更大的一侧并夹紧
        var menuW = contextMenu.width
        var xLeft = anchorX
        var xRight = anchorX + anchorW - menuW
        var xCenter = anchorX + (anchorW - menuW) / 2
        var fitsL = xLeft >= consts.margin && xLeft + menuW <= overlay.width - consts.margin
        var fitsR = xRight >= consts.margin && xRight + menuW <= overlay.width - consts.margin
        var fitsC = !hasSelection && xCenter >= consts.margin && xCenter + menuW <= overlay.width - consts.margin
        var popupX
        if (fitsC)
            popupX = xCenter
        else if (fitsL)
            popupX = xLeft
        else if (fitsR)
            popupX = xRight
        else
            popupX = _visibleAreaX(xRight, menuW, overlay) > _visibleAreaX(xLeft, menuW, overlay) ? xRight : xLeft
        popupX = Math.max(consts.margin, Math.min(popupX, overlay.width - menuW - consts.margin))

        var local = overlay.mapToItem(parent, popupX, popupY)
        return { x: local.x, y: local.y, height: menuH, contentY: contentY, mode: mode }
    }

    // 按模式与菜单高度计算应保持的滚动位置（动画期间跟随；mode 省略时用 props.mode）
    function _scrollFor(menuH, mode) {
        if (mode === undefined)
            mode = props.mode
        var overlay = _overlay()
        if (!overlay || !parent)
            return listView.contentY
        var contentH = listView.contentHeight
        var count = listView.count
        // 无内容或未选中：保持滚动在顶部
        if (count < 1 || contentH <= 0 || listView.currentIndex < 0)
            return 0

        var rowH = contentH / count
        var selTop = Math.max(0, Math.min(listView.currentIndex, count - 1)) * rowH
        var listH = menuH - consts.listInset * 2
        var contentY
        if (mode === 1)
            contentY = selTop                        // 对齐上：选中项在可视窗口顶部
        else if (mode === 2)
            contentY = selTop + rowH - listH         // 对齐下：选中项在可视窗口底部
        else
            contentY = selTop + consts.listInset - menuH / 2  // 居中：动画期间选中项位于可视窗口中部
        return Math.max(0, Math.min(contentY, Math.max(0, contentH - listH)))
    }

    // 更新菜单宽度（不换行：宽到足以单行排开全部项；极端情况夹紧到窗口宽度内，靠 elide 省略）
    function _updateWidth() {
        var overlay = _overlay()
        var w = Math.max(minimumWidth, _measureMaxTextWidth() + consts.textPadding)
        if (overlay)
            w = Math.min(w, overlay.width - consts.margin * 2)
        contextMenu.width = Math.max(minimumWidth, w)
    }

    // 应用完整定位；返回是否成功（内容未就绪时返回 false）
    function _applyPosition() {
        props.busy = true
        _updateWidth()
        var layout = _computeLayout()
        if (layout) {
            props.mode = layout.mode
            contextMenu.height = layout.height
            contextMenu.x = layout.x
            contextMenu.y = layout.y
            listView.contentY = layout.contentY

            // 缓存打开动画的起始/结束值（求值为数值，动画期间不被 height 变化重求值）
            props.heightFrom = Math.min(consts.animHeight, contextMenu.height)
            props.heightTo = contextMenu.height
            props.yTo = contextMenu.y
            props.startContentY = _scrollFor(props.heightFrom)   // 起始滚动：先对准选中项
            props.finalContentY = layout.contentY
            if (props.mode === 2)
                // 对齐下：底部固定，y 随高度反向补偿 → 菜单始终自 combobox 底边向上生长
                // （contentY 被夹到 0 时旧公式退化为固定顶部、向下生长，方向就反了）
                props.yFrom = contextMenu.y + props.heightTo - props.heightFrom
            else if (listView.currentIndex < 0)
                // 未选中（居中）：垂直中心固定，向上下对称展开，起始即居中
                props.yFrom = contextMenu.y + (props.heightTo - props.heightFrom) / 2
            else
                // mode 0/1 选中：contentY 与 y 同缓动同步，令 “y - contentY” 恒为常量 → 选中项全程贴住 combobox
                props.yFrom = contextMenu.y - props.finalContentY + props.startContentY
        }
        props.busy = false
        return layout !== null
    }

    // 打开时定位入口：隐藏滚动条并计算布局；内容未就绪时推迟重试。
    // ComboBox 等宿主需在同步 currentIndex 之后调用本函数（保证布局基于最新索引计算）
    function relayout() {
        props.animating = true   // 展开动画期间隐藏滚动条
        if (!_applyPosition())
            retryTimer.start()
    }
    onAboutToShow: relayout()
    onHeightChanged: {
        // 打开动画期间 contentY 由动画本身驱动，这里仅在非动画时跟随高度
        if (visible && !props.animating)
            listView.contentY = _scrollFor(height)
    }
    onWidthChanged: {
        if (visible && !props.busy)
            _applyPosition()
    }
    onModelChanged: {
        if (visible)
            _applyPosition()
    }

    // 内容（contentHeight）尚未就绪时，待 popup 显示后重试定位
    Timer {
        id: retryTimer
        interval: 16
        repeat: false
        onTriggered: { if (contextMenu.visible) _applyPosition() }
    }

    Connections {
        target: contextMenu._overlay()
        function onWidthChanged() { if (contextMenu.visible) contextMenu._applyPosition() }
        function onHeightChanged() { if (contextMenu.visible) contextMenu._applyPosition() }
    }

    Connections {
        target: contextMenu.parent
        function onWidthChanged() { if (contextMenu.visible) contextMenu._applyPosition() }
        function onHeightChanged() { if (contextMenu.visible) contextMenu._applyPosition() }
    }

    onOpened: {
        _applyPosition()               // 布局稳定后再确认一次最终位置/滚动
        listView.forceActiveFocus()
    }
    // 关闭时重置状态，避免下次打开残留动画/键盘高亮
    onClosed: {
        listView.keyboardNavigation = false
        props.animating = false
    }

    // 背景 / Background //
    background: Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.currentTheme.appearance.windowRadius
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        border.color: Theme.currentTheme.colors.controlBorderColor

        // 阴影 / Shadow //
        layer.enabled: true
        layer.effect: Shadow {
            id: shadow
            style: "flyout"
            source: background
        }
    }

    // 动画：高度从起始高度展开到最终高度，同时 y 与 contentY 以相同缓动同步移动，
    // 令 “y - contentY” 保持常量，选中项全程贴住 combobox——
    // mode 0（居中）：从选中项（combobox）处向上下展开，过渡到最终位置
    // mode 1（对齐上）：顶部固定，内容自顶部向下展开
    // mode 2（对齐下）：底部固定，内容自底部向上展开
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: contextMenu
                property: "opacity"
                from: 0
                to: 1
                duration: 70
                easing.type: Easing.InOutQuart
            }
            NumberAnimation {
                target: contextMenu
                property: "height"
                from: props.heightFrom
                to: props.heightTo
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
                onStarted: {
                    listView.contentY = props.startContentY
                }
                onFinished: {
                    // 展开完成：动画结束，滚动条恢复按需显示，并收敛到最终滚动位置
                    props.animating = false
                    listView.contentY = props.finalContentY
                }
            }
            NumberAnimation {
                target: contextMenu
                property: "y"
                from: props.yFrom
                to: props.yTo
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
            }
            // 滚动与 y 同步动画（同一时长/缓动），保证选中项与 combobox 精确对准
            NumberAnimation {
                target: listView
                property: "contentY"
                from: props.startContentY
                to: props.finalContentY
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
            }
        }
    }
    exit: Transition { }
}
