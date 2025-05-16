import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import "../../themes"
import "../../components"

Button {
    id: root
    property alias radius: background.radius

    background: Rectangle {
        id: background
        anchors.fill: parent
        color: hovered ? hoverColor : backgroundColor
        radius: height / 2

        border.width: Theme.currentTheme.appearance.borderWidth  // 边框宽度 / Border Width
        border.color: flat ? "transparent" :
            enabled ? highlighted ? primaryColor : Theme.currentTheme.colors.controlBorderColor :
            highlighted ? Theme.currentTheme.colors.disabledColor : Theme.currentTheme.colors.controlBorderColor

        // 裁切
        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        // 底部border
        Rectangle {
            id: indicator
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            height: Theme.currentTheme.appearance.borderWidth

            color: flat ? "transparent" :
                enabled ? highlighted ? Theme.currentTheme.colors.controlAccentBottomBorderColor
                        : Theme.currentTheme.colors.controlBottomBorderColor
                    : "transparent"
        }

        Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
        opacity: flat && !hovered || !hoverable ? 0 : 1
    }
}