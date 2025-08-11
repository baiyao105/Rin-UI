import QtQuick
import QtQuick.Controls
import QtQuick.Window as QQW
import QtQuick.Layouts
import QtQuick.Window
import RinUI


Window {
    width: 800
    height: 600
    visible: true

    Text{
        text: "Hello World"
        anchors.centerIn: parent
    }

    Button {
        text: "Open Window"
        Menu {
            id: menu
            MenuItem {
                text: "Sub Window"
                onClicked: {
                    subWindow.show()
                }
            }
            MenuItem {
                text: "Sub Window 2"
                onClicked: {
                    subWindow2.show()
                }
            }
            MenuItem {
                text: "Sub Window 3"
                onClicked: {
                    subWindow3.show()
                }
            }
        }
        onClicked: {
            menu.open()
        }
    }


    Item {
        QQW.Window {
            id: subWindow
            width: 400
            height: 400
        }

        Window {
            id: subWindow2
            width: 400
            height: 400
        }
        Window {
            id: subWindow3
            width: 400
            height: 400
        }
    }
}