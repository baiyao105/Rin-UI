import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

Popup {
    id: root

    width: 300
    height: 330
    implicitHeight: 330

    // 覆盖式对齐：高亮条中心与触发按钮中心重合；放不下时由基类回退到 Bottom/Top
    position: Position.AlignCenter

    // 高亮条（Tumbler 高亮区）中心相对 popup 几何中心的补偿：
    // popup 中心比高亮条中心低 (buttonRow.height + 分割线) / 2
    alignOffsetY: (buttonRow.implicitHeight + 1) / 2

    property var value1: undefined
    property var value2: undefined
    property var value3: undefined

    property alias index1: hours.currentIndex
    property alias index2: minutes.currentIndex
    property alias index3: added.currentIndex

    property var model1: 12
    property var model2: 60
    property var model3: [qsTr("AM"), qsTr("PM")]

    property bool gotData: typeof value1!== "undefined" && typeof value2!== "undefined"

    signal valueChanged(var value1, var value2, var value3)

    function formatText(count, modelData) {
        let data = modelData;
        return data.toString().length < 2 && count === 60  ? "0" + data
            : data === 0 && count === 12 ? 12 : data
    }

    property int visibleItemCount: 7

    // 数字/文字 选择 //
    Component {
        id: delegateComponent

        Text {
            readonly property bool highlighted: Tumbler.displacement < 0.5 && Tumbler.displacement > -0.5
            text: formatText(Tumbler.tumbler.count, modelData)
            color: highlighted? Theme.currentTheme.colors.textOnAccentColor : Theme.currentTheme.colors.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            // 点击选择喵 看看啥时候把背景加上
            MouseArea {
                anchors.fill: parent
                onClicked: Tumbler.tumbler.currentIndex = index
            }
        }
    }
    padding: 0

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: -2

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            leftPadding: 4
            rightPadding: 4

            frameless: true
            background: Rectangle {
                id: highlightBackground
                anchors.centerIn: parent
                height: 40
                radius: Theme.currentTheme.appearance.buttonRadius
                color: Theme.currentTheme.colors.primaryColor
                width: parent.width - parent.leftPadding - parent.rightPadding
            }

            RowLayout {
                id: tumblerRow
                anchors.fill: parent

                Tumbler {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: hours
                    model: model1
                    visibleItemCount: root.visibleItemCount
                    delegate: delegateComponent
                }
                ToolSeparator {
                    Layout.fillHeight: true
                }
                Tumbler {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: minutes
                    model: model2
                    visibleItemCount: root.visibleItemCount
                    delegate: delegateComponent
                }
                ToolSeparator {
                    Layout.fillHeight: true
                    visible: added.visible
                }
                Tumbler {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: added
                    model: model3
                    visibleItemCount: root.visibleItemCount
                    delegate: delegateComponent
                    visible: typeof model3 !== "undefined"
                }
            }
        }

        Rectangle {  // 分割线
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.currentTheme.colors.dividerBorderColor
        }

        // 确认/取消 按钮区域
        RowLayout {
            id: buttonRow
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 0

            // confirm
            ToolButton {
                Layout.fillWidth: true
                flat: true
                icon.name: "ic_fluent_checkmark_20_regular"
                onClicked: {
                    value1 = hours.currentItem.text
                    value2 = minutes.currentItem.text
                    typeof model3 !== "undefined" ? value3 = added.currentItem.text : undefined
                    valueChanged(value1, value2, value3)
                    root.close()
                }
            }
            ToolSeparator {
                implicitHeight: 40
            }
            // cancel
            ToolButton {
                Layout.fillWidth: true
                flat: true
                icon.name: "ic_fluent_dismiss_20_regular"
                onClicked: {
                    root.close()
                }
            }
        }
    }

    enter: Transition {
        enabled: position !== Position.None
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: Utils.appearanceSpeed
                easing.type: Easing.OutQuint
            }
            // AlignCenter（高亮条覆盖对齐）：从中间（高亮条处）向上下扩散。
            // y 与 height 同参数联动（y = posY + (H - height)/2），保证高亮条中心全程钉在按钮处：
            // height: H/2 → H, y: posY + H/4 → posY
            // Bottom：从下往上滑入(y -15)；Top：从上往下滑入(y +15)
            NumberAnimation {
                target: root
                property: "y"
                from: root._resolvedPosition === Position.AlignCenter
                    ? root.posY + root.implicitHeight / 4
                    : root.posY + (root._resolvedPosition !== Position.Center
                        ? (root._resolvedPosition === Position.Top ? 15
                            : root._resolvedPosition === Position.Bottom ? -15 : 0) : 0)
                to: root.posY
                duration: Utils.animationSpeedMiddle * 0.8
                easing.type: Easing.OutQuint
            }
            // 高度生长仅在覆盖对齐时生效（避让滑入时高度不变）
            NumberAnimation {
                target: root
                property: "height"
                from: root._resolvedPosition === Position.AlignCenter
                    ? root.implicitHeight / 2 : root.implicitHeight
                to: root.implicitHeight
                duration: Utils.animationSpeedMiddle * 0.8
                easing.type: Easing.OutQuint
            }
            ScriptAction {
                script: {
                    hours.positionViewAtIndex(
                        typeof value1 === "undefined" ? 0
                        : typeof model1 === "number" ? value1 : model1.indexOf(value1), Tumbler.Center
                    )
                    minutes.positionViewAtIndex(
                        typeof value2 === "undefined" ? 0
                        : typeof model2 === "number" ? value2 : model2.indexOf(value2), Tumbler.Center
                    )
                    added.positionViewAtIndex(
                        typeof value3 === "undefined" ? 0
                        : typeof model3 === "number" ? value3 : model3.indexOf(parseInt(value3)), Tumbler.Center
                    )
                }
            }
        }
    }
}
