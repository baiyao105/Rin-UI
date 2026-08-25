import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
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

    implicitWidth: 100
    implicitHeight: Math.min(listView.contentHeight + 6, maximumHeight)
    y: (parent.height - contextMenu.height) / 2
    height: implicitHeight  // 保持隐式绑定
    closePolicy: Popup.CloseOnPressOutside
    focus: true

    // 内容 / ListView //
    contentItem: Collections.ListView {
        id: listView
        clip: true
        focus: true
        focusPolicy: Qt.StrongFocus
        textRole: contextMenu.textRole
        anchors.fill: parent  // 清除边距
        anchors.topMargin: 2
        anchors.bottomMargin: 2

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            visible: false
        }

        onItemClicked: function(index) {
            contextMenu.close()
            contextMenu.itemSelected(index)
        }
    }

    onOpened: listView.forceActiveFocus()
    onAboutToShow: {
        listView.forceLayout()
        scrollBar.visible = false
    }
    // 关闭时重置键盘导航标记，避免下次鼠标打开时残留键盘高亮框
    onClosed: listView.keyboardNavigation = false

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

    // 按钮 / Button //


    // Behavior on y { NumberAnimation { duration: Utils.animationSpeed; easing.type:Easing.InOutQuart } }

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
            // NumberAnimation {
            //     target: shadow
            //     property: "opacity"
            //     from: 0
            //     to: 1
            //     duration: 600
            //     easing.type: Easing.InOutCubic
            // }
            NumberAnimation {
                target: contextMenu
                property: "height"
                from: 46
                to: Math.max(contextMenu.implicitHeight, 46)
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
                onFinished: {
                    scrollBar.visible = true;
                }
            }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: contextMenu
                property: "opacity"
                from: 1
                to: 0
                duration: 150
                easing.type: Easing.InOutQuart
            }
        }
    }
}
