import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import RinUI


Window {
    width: 800
    height: 600
    visible: true

    Button {
        text: "Open Window"
        onClicked: {
            subWindow.show()
        }
    }


    Window {
        id: subWindow
        width: 400
        height: 400
    }
}