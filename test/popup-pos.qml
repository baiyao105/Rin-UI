import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


Window {
    id: root
    width: 800
    height: 600
    visible: true

    SettingCard {
        title: "popup position"

        ComboBox {
            id: positionComboBox
            model: ListModel {
                ListElement { text: "Top"; pos: Position.Top }
                ListElement { text: "Bottom"; pos: Position.Bottom }
                ListElement { text: "Left"; pos: Position.Left }
                ListElement { text: "Center"; pos: Position.Center }
                ListElement { text: "Right"; pos: Position.Right }
            }
            textRole: "text"
            currentIndex: 1
        }
    }

    Button {
        x: root.width / 2
        y: root.height /2
        text: qsTr("Open Popup")
        onClicked: {
            popup.open()
        }
         DragHandler {
            id: dragHandler
        }

        Popup {
            id: popup
            width: 200
            height: 160
            // modal: modalSwitch.checked

            position: positionComboBox.model.get(positionComboBox.currentIndex).pos

            Column {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: qsTr("Simple Popup")
                }
                Button {
                    text: qsTr("Close")
                    onClicked: popup.close()
                }
            }
        }
    }
}