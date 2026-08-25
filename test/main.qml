import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window as QQW
import Qt5Compat.GraphicalEffects
import RinUI

QQW.Window {
    id: window

    x: fullScreenWindow ? QQW.Screen.virtualX + (safeFullscreen ? 1 : 0) : 80
    y: fullScreenWindow ? QQW.Screen.virtualY + (safeFullscreen ? 1 : 0) : 80
    width: fullScreenWindow ? QQW.Screen.width - (safeFullscreen ? 2 : 0) : 1200
    height: fullScreenWindow ? QQW.Screen.height - (safeFullscreen ? 2 : 0) : 760
    visible: true
    color: "transparent"
    title: "Transparent QQuickWindow Isolation MVP"

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.Window | Qt.WindowStaysOnTopHint

    property bool mouseHovered: false
    property bool editMode: false
    property bool transparentInput: false
    property bool bottomLayer: false
    property bool topMost: true
    property bool toolWindow: true
    property bool fullScreenWindow: true
    property bool safeFullscreen: true
    property bool enableFullscreenOpenGLBorderWorkaround: true
    property bool maskEnabled: true
    property bool stressMask: false
    property bool compatEffects: true
    property bool childLayers: true
    property bool clippedWidgets: true
    property bool watermarkEnabled: true
    property int widgetCount: 5
    property real contentOpacity: 0.75

    onTransparentInputChanged: Mvp.setTransparentInput(transparentInput)
    onBottomLayerChanged: Mvp.setBottomLayer(bottomLayer)
    onTopMostChanged: Mvp.setTopMost(topMost)
    onToolWindowChanged: Mvp.setToolWindow(toolWindow)
    onMaskEnabledChanged: maskEnabled ? Mvp.applyMask() : Mvp.clearMask()
    onStressMaskChanged: Mvp.setStressMask(stressMask)

    Rectangle {
        anchors.fill: parent
        visible: window.editMode
        color: "black"
        opacity: 0.25
    }

    Text {
        x: widgetsLoader.x
        y: widgetsLoader.y + widgetsLoader.height / 3
        visible: window.watermarkEnabled
        text: "MVP WATERMARK"
        font.pixelSize: 48
        font.bold: true
        rotation: -30
        opacity: 0.12
        color: "gray"
        z: 999
    }

    ColumnLayout {
        id: widgetsLoader
        objectName: "widgetsLoader"
        x: Math.round((window.width - width) / 2)
        y: Math.round((window.height - height) / 2)
        width: 760
        spacing: 24

        signal geometryChanged()
        onXChanged: geometryChanged()
        onYChanged: geometryChanged()
        onWidthChanged: geometryChanged()
        onHeightChanged: geometryChanged()

        Repeater {
            model: window.widgetCount

            Item {
                objectName: "mvpWidget"
                Layout.preferredWidth: 460 + index * 70
                Layout.preferredHeight: index === 0 ? 56 : 100
                clip: window.clippedWidgets
                opacity: window.mouseHovered ? 0.8 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                Item {
                    anchors.fill: parent
                    visible: window.compatEffects

                    Rectangle {
                        id: borderRect
                        anchors.fill: parent
                        radius: background.radius
                        layer.enabled: window.childLayers
                        layer.effect: LinearGradient {
                            start: Qt.point(0, 0)
                            end: Qt.point(width, height)
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.alpha("#ffffff", 0.9) }
                                GradientStop { position: 0.5; color: Qt.alpha("#ffffff", 0) }
                                GradientStop { position: 0.6; color: Qt.alpha("#ffffff", 0) }
                                GradientStop { position: 1; color: Qt.alpha("#ffffff", 0.9) }
                            }
                        }
                    }

                    layer.enabled: window.childLayers
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: borderRect.width
                            height: borderRect.height
                            radius: borderRect.radius
                            color: "transparent"
                            border.width: 1.5
                        }
                    }
                    opacity: 1
                    z: 1
                }

                Rectangle {
                    id: simpleBorder
                    anchors.fill: parent
                    visible: !window.compatEffects
                    radius: background.radius
                    color: "transparent"
                    border.width: 1.5
                    border.color: Qt.alpha("#ffffff", 0.6)
                    z: 1
                }

                Rectangle {
                    id: background
                    anchors.fill: parent
                    radius: height * 0.22
                    color: Qt.alpha(index % 2 ? "#FBFAFF" : "#1E1D22", index % 2 ? 0.7 : 0.65)
                    opacity: window.contentOpacity
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.topMargin: index === 0 ? 12 : 16
                    anchors.bottomMargin: index === 0 ? 10 : 18
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 12
                        color: Qt.alpha("#4099b2", 0.9)
                        layer.enabled: window.childLayers
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Widget " + (index + 1)
                            color: index % 2 ? "#202020" : "white"
                            font.pixelSize: 18
                        }

                        Text {
                            text: "isolation toggles: fullscreen/tool/topmost/mask/effects/layers/clip"
                            color: index % 2 ? "#606060" : "#cfcfcf"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: controls.implicitHeight + 32
        color: Qt.alpha("#202020", 0.72)
        z: 1000
    }

    Flow {
        id: controls
        objectName: "controls"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 8
        z: 1001

        Button { text: window.maskEnabled ? "Mask ON" : "Mask OFF"; onClicked: window.maskEnabled = !window.maskEnabled }
        Button { text: window.stressMask ? "Stress ON" : "Stress OFF"; onClicked: window.stressMask = !window.stressMask }
        Button { text: window.compatEffects ? "Effects ON" : "Effects OFF"; onClicked: window.compatEffects = !window.compatEffects }
        Button { text: window.childLayers ? "Layers ON" : "Layers OFF"; onClicked: window.childLayers = !window.childLayers }
        Button { text: window.clippedWidgets ? "Clip ON" : "Clip OFF"; onClicked: window.clippedWidgets = !window.clippedWidgets }
        Button { text: window.fullScreenWindow ? "Fullscreen ON" : "Fullscreen OFF"; onClicked: window.fullScreenWindow = !window.fullScreenWindow }
        Button { text: window.safeFullscreen ? "SafeFull ON" : "SafeFull OFF"; onClicked: window.safeFullscreen = !window.safeFullscreen }
        Button { text: window.toolWindow ? "Tool ON" : "Tool OFF"; onClicked: window.toolWindow = !window.toolWindow }
        Button { text: window.topMost ? "TopMost ON" : "TopMost OFF"; onClicked: window.topMost = !window.topMost }
        Button { text: window.bottomLayer ? "Bottom ON" : "Bottom OFF"; onClicked: window.bottomLayer = !window.bottomLayer }
        Button { text: window.transparentInput ? "InputTransparent ON" : "InputTransparent OFF"; onClicked: window.transparentInput = !window.transparentInput }
        Button { text: window.watermarkEnabled ? "Watermark ON" : "Watermark OFF"; onClicked: window.watermarkEnabled = !window.watermarkEnabled }
        Button { text: "One Widget"; onClicked: window.widgetCount = 1; }
        Button { text: "Five Widgets"; onClicked: window.widgetCount = 5; }
        Button { text: "Show Again"; onClicked: Mvp.showAgain() }
    }

    Timer {
        interval: 300
        running: true
        repeat: false
        onTriggered: Mvp.applyMask()
    }

    Connections {
        target: Mvp
        function onRequestHoverState(value) {
            window.mouseHovered = value
        }
    }
}
