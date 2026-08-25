import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


ApplicationWindow {
    width: 1000
    height: 750
    visible: true

    // ── FPS counter ──
    property int _frameCount: 0
    property real _fps: 0

    // ── Adjustable parameters ──
    property int panelCount: 12
    property int blurValue: 30
    property real downsampleValue: 0.5
    property real tintOpacityValue: 1.0
    property real luminosityOpacityValue: -1
    property real noiseOpacityValue: 0.02

    onFrameSwapped: _frameCount++

    // ── Background layer (all Acrylic panels share this as source) ──
    Item {
        id: backgroundLayer
        anchors.fill: parent
        z: -1

        // Animated gradient
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    SequentialAnimation on color {
                        loops: Animation.Infinite
                        ColorAnimation { from: "#1a1a2e"; to: "#16213e"; duration: 3000 }
                        ColorAnimation { from: "#16213e"; to: "#0f3460"; duration: 3000 }
                        ColorAnimation { from: "#0f3460"; to: "#1a1a2e"; duration: 3000 }
                    }
                }
                GradientStop {
                    position: 1
                    SequentialAnimation on color {
                        loops: Animation.Infinite
                        ColorAnimation { from: "#e94560"; to: "#533483"; duration: 4000 }
                        ColorAnimation { from: "#533483"; to: "#e94560"; duration: 4000 }
                    }
                }
            }
        }

        // Grid lines
        Canvas {
            anchors.fill: parent
            opacity: 0.15
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#ffffff"
                ctx.lineWidth = 1
                for (var gx = 0; gx < width; gx += 40) {
                    ctx.beginPath()
                    ctx.moveTo(gx, 0)
                    ctx.lineTo(gx, height)
                    ctx.stroke()
                }
                for (var gy = 0; gy < height; gy += 40) {
                    ctx.beginPath()
                    ctx.moveTo(0, gy)
                    ctx.lineTo(width, gy)
                    ctx.stroke()
                }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.05; to: 0.25; duration: 2000; easing: Easing.InOutSine }
                NumberAnimation { from: 0.25; to: 0.05; duration: 2000; easing: Easing.InOutSine }
            }
        }

        // Rotating squares
        Repeater {
            model: 8
            Rectangle {
                width: 40 + index * 15
                height: width
                color: Qt.hsla(index / 8, 0.7, 0.5, 0.3)
                radius: 4

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 5000 + index * 1500
                    loops: Animation.Infinite
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 50 + index * 120
                        to: 150 + index * 120
                        duration: 3000 + index * 500
                        easing: Easing.InOutQuad
                    }
                    NumberAnimation {
                        from: 150 + index * 120
                        to: 50 + index * 120
                        duration: 3000 + index * 500
                        easing: Easing.InOutQuad
                    }
                }

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 100 + index * 80
                        to: 250 + index * 80
                        duration: 4000 + index * 600
                        easing: Easing.InOutQuad
                    }
                    NumberAnimation {
                        from: 250 + index * 80
                        to: 100 + index * 80
                        duration: 4000 + index * 600
                        easing: Easing.InOutQuad
                    }
                }
            }
        }

        // Floating particles
        Repeater {
            model: 50
            Rectangle {
                x: Math.random() * backgroundLayer.width
                y: Math.random() * backgroundLayer.height
                width: 4 + Math.random() * 16
                height: width
                radius: width / 2
                color: Qt.hsla(Math.random(), 0.8, 0.7, 0.6)

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: x; to: x + (Math.random() - 0.5) * 300; duration: 2000 + Math.random() * 4000 }
                    NumberAnimation { from: x + (Math.random() - 0.5) * 300; to: x; duration: 2000 + Math.random() * 4000 }
                }
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { from: y; to: y + (Math.random() - 0.5) * 200; duration: 2500 + Math.random() * 4000 }
                    NumberAnimation { from: y + (Math.random() - 0.5) * 200; to: y; duration: 2500 + Math.random() * 4000 }
                }
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.1; to: 0.9; duration: 1000 + Math.random() * 2000; easing: Easing.InOutSine }
                    NumberAnimation { from: 0.9; to: 0.1; duration: 1000 + Math.random() * 2000; easing: Easing.InOutSine }
                }
            }
        }

        // Large pulsing circles
        Repeater {
            model: 5
            Rectangle {
                x: 100 + index * 200
                y: 200 + (index % 3) * 150
                width: 120 + index * 30
                height: width
                radius: width / 2
                color: Qt.hsla(0.5 + index * 0.1, 0.6, 0.5, 0.2)

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.1; to: 0.5; duration: 2000 + index * 500; easing: Easing.InOutSine }
                    NumberAnimation { from: 0.5; to: 0.1; duration: 2000 + index * 500; easing: Easing.InOutSine }
                }
                NumberAnimation on scale {
                    from: 0.8
                    to: 1.3
                    duration: 3000 + index * 400
                    loops: Animation.Infinite
                    easing: Easing.InOutSine
                    running: true
                }
            }
        }

        // Moving rectangles
        Repeater {
            model: 12
            Rectangle {
                width: 60 + Math.random() * 80
                height: 30 + Math.random() * 40
                radius: 6
                color: Qt.hsla(Math.random(), 0.5, 0.4, 0.35)

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: Math.random() * backgroundLayer.width; to: Math.random() * backgroundLayer.width; duration: 3000 + Math.random() * 5000; easing: Easing.InOutCubic }
                }
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { from: Math.random() * backgroundLayer.height; to: Math.random() * backgroundLayer.height; duration: 4000 + Math.random() * 5000; easing: Easing.InOutCubic }
                }
                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 6000 + Math.random() * 8000
                    loops: Animation.Infinite
                }
            }
        }
    }

    // ── Control bar ──
    Rectangle {
        id: controlBar
        width: parent.width
        height: 44
        color: "#1e1e2e"
        z: 10

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            spacing: 12

            Button {
                text: showPanels.checked ? "Hide Panels" : "Show Panels"
                checkable: true
                checked: true
                id: showPanels
                font.pixelSize: 13
                onCheckedChanged: acrylicGrid.opacity = checked ? 1 : 0
            }

            Text {
                text: "FPS: " + (_fps || 0).toFixed(1)
                color: "#cdd6f4"
                font.pixelSize: 14
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Panels: " + acrylicGrid.children.length
                color: "#a6adc8"
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Timer {
            interval: 1000
            repeat: true
            running: true
            onTriggered: {
                _fps = _frameCount
                _frameCount = 0
            }
        }
    }

    // ── Parameter panel ──
    Rectangle {
        id: paramPanel
        anchors.top: controlBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 120
        color: "#181825"
        z: 9

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Row {
                spacing: 16
                width: parent.width

                // Panel count
                Column {
                    width: 200
                    spacing: 2

                    Text {
                        text: "Panel Count: " + panelCount
                        color: "#cdd6f4"
                        font.pixelSize: 12
                    }
                    Slider {
                        width: parent.width
                        from: 1
                        to: 48
                        stepSize: 1
                        value: panelCount
                        onValueChanged: panelCount = value
                    }
                }

                // Blur Radius
                Column {
                    width: 200
                    spacing: 2

                    Text {
                        text: "Blur Radius: " + blurValue
                        color: "#cdd6f4"
                        font.pixelSize: 12
                    }
                    Slider {
                        width: parent.width
                        from: 0
                        to: 80
                        stepSize: 1
                        value: blurValue
                        onValueChanged: blurValue = value
                    }
                }

                // Downsample
                Column {
                    width: 200
                    spacing: 2

                    Text {
                        text: "Downsample: " + downsampleValue.toFixed(2)
                        color: "#cdd6f4"
                        font.pixelSize: 12
                    }
                    Slider {
                        width: parent.width
                        from: 0.1
                        to: 1
                        stepSize: 0.05
                        value: downsampleValue
                        onValueChanged: downsampleValue = value
                    }
                }

                // Noise Opacity
                Column {
                    width: 200
                    spacing: 2

                    Text {
                        text: "Noise Opacity: " + noiseOpacityValue.toFixed(2)
                        color: "#cdd6f4"
                        font.pixelSize: 12
                    }
                    Slider {
                        width: parent.width
                        from: 0
                        to: 0.1
                        stepSize: 0.01
                        value: noiseOpacityValue
                        onValueChanged: noiseOpacityValue = value
                    }
                }
            }
        }
    }

    // ── Scrollable acrylic grid ──
    ScrollView {
        anchors.top: paramPanel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        contentWidth: availableWidth

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Grid {
            id: acrylicGrid
            columns: 4
            spacing: 16
            x: 16
            y: 16
            width: parent.width - 32

            // ── Generate Acrylic panels (all live) ──
            Repeater {
                model: panelCount

                Rectangle {
                    required property int index

                    width: (acrylicGrid.width - (acrylicGrid.columns - 1) * acrylicGrid.spacing) / acrylicGrid.columns
                    height: 180
                    radius: 12
                    color: "transparent"

                    AcrylicBrush {
                        sourceItem: backgroundLayer
                        live: true
                        tintColor: Theme.currentTheme.isDark ? "#CC1F1F1F" : "#CCFFFFFF"
                        blur: blurValue
                        downsample: downsampleValue
                        tintOpacity: tintOpacityValue
                        tintLuminosityOpacity: luminosityOpacityValue
                        noiseOpacity: noiseOpacityValue
                        clipToRadius: true
                    }

                    // Accent border
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 2
                        border.color: "#89b4fa"
                        visible: true
                    }

                    // Label
                    Text {
                        anchors.centerIn: parent
                        text: "Panel " + (parent.index + 1)
                        color: "#cdd6f4"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.verticalCenter
                        anchors.topMargin: 24
                        text: "live"
                        color: "#89b4fa"
                        font.pixelSize: 12
                    }

                    // Draggable to test offset updates
                    MouseArea {
                        anchors.fill: parent
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        cursorShape: Qt.OpenHandCursor
                        onDoubleClicked: {
                            parent.x = (parent.index % acrylicGrid.columns) * (parent.width + acrylicGrid.spacing) + 16
                            parent.y = Math.floor(parent.index / acrylicGrid.columns) * (parent.height + acrylicGrid.spacing) + 16
                        }
                    }
                }
            }
        }
    }
}