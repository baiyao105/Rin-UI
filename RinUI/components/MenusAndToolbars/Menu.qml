import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"
import "../DialogsAndFlyouts/PopupPositioner.js" as PopupPositioner


QQC2.Menu {
    id: root

    property int position: Position.Bottom  // 位置
    property real posX: _targetX
    property real posY: _targetY
    property real _targetX: x
    property real _targetY: y
    property int _resolvedPosition: position
    property bool _repositionPending: false
    readonly property real _spacing: 5
    readonly property real _margin: 8

    function _scheduleReposition() {
        if (!visible || _repositionPending)
            return

        _repositionPending = true
        Qt.callLater(function() {
            _repositionPending = false
            _reposition()
        })
    }

    function _reposition() {
        var overlay = QQC2.Overlay.overlay
        if (!overlay || !parent)
            return

        var anchorOrigin = parent.mapToItem(overlay, 0, 0)
        var anchor = { x: anchorOrigin.x, y: anchorOrigin.y, width: parent.width, height: parent.height }
        var bounds = { x: 0, y: 0, width: overlay.width, height: overlay.height }
        var result = PopupPositioner.resolve(
            anchor, Math.max(width, implicitWidth), Math.max(height, implicitHeight),
            bounds, position, _spacing, _margin, Position)
        var localPosition = overlay.mapToItem(parent, result.x, result.y)

        _resolvedPosition = result.position
        _targetX = localPosition.x
        _targetY = localPosition.y
        x = _targetX
        y = _targetY
    }

    onAboutToShow: _reposition()
    onVisibleChanged: {
        if (visible)
            _scheduleReposition()
    }
    onPositionChanged: _scheduleReposition()
    onWidthChanged: _scheduleReposition()
    onHeightChanged: _scheduleReposition()
    onImplicitWidthChanged: _scheduleReposition()
    onImplicitHeightChanged: _scheduleReposition()

    Connections {
        target: QQC2.Overlay.overlay
        function onWidthChanged() { root._scheduleReposition() }
        function onHeightChanged() { root._scheduleReposition() }
    }

    width: Math.min(Math.max(contentItem.implicitWidth, 80), Math.max(0, QQC2.Overlay.overlay ? QQC2.Overlay.overlay.width - _margin * 2 : 0))
    height: Math.min(implicitHeight, Math.max(0, QQC2.Overlay.overlay ? QQC2.Overlay.overlay.height - _margin * 2 : 0))

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: Utils.animationSpeed
                easing.type: Easing.InOutQuart
            }
            NumberAnimation {
                target: root
                property: "height"
                from: (_resolvedPosition === Position.Top || _resolvedPosition === Position.Bottom ? 0 : root.implicitHeight)
                to: root.height
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuart
            }
            NumberAnimation {
                target: root
                property: "x"
                from: posX + (_resolvedPosition === Position.Left ? 5 : _resolvedPosition === Position.Right ? -5 : 0)
                to: posX
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
                onRunningChanged: {
                    scrollBar.visible = true;
                }
            }
            NumberAnimation {
                target: root
                property: "y"
                from: posY + (_resolvedPosition === Position.Top || _resolvedPosition === Position.Bottom
                    ? (_resolvedPosition === Position.Top ? height / 2 : _resolvedPosition === Position.Bottom ? -height / 2 : height / 2)
                    : 0)
                to: posY
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
                onRunningChanged: {
                    scrollBar.visible = true;
                }
            }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 1
                to: 0
                duration: 150
                easing.type: Easing.InOutQuart
            }
        }
    }

    topPadding: 5
    bottomPadding: 5

    background: Rectangle {
        anchors.fill: parent
        radius: Theme.currentTheme.appearance.windowRadius
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        border.color: Theme.currentTheme.colors.flyoutBorderColor

        layer.enabled: true
        layer.effect: Shadow {
            id: shadow
            style: "flyout"
            source: background
        }
    }

    delegate: MenuItem { }

    contentItem: Flickable {
        id: flickable
        clip: true
        anchors.fill: parent
        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        ColumnLayout {
            id: column
            x: -5
            spacing: 0
            Repeater {
                model: root.contentModel
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            visible: false  // 初始隐藏，在 enter 动画中显现
        }
    }
}
