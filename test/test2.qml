import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import RinUI


Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Example")

    // 题1
    // RowLayout {
    //     anchors.centerIn: parent
    //     spacing: 10
    //
    //     RoundButton {
    //         width: 100
    //         height: 100
    //         text: "Take action"
    //     }
    //     RoundButton {
    //         width: 100
    //         height: 100
    //         text: "Cancel action"
    //     }
    // }

    property var subjects: ["Chinese", "Math", "English"]

    // 题2
    // Column {
    //     anchors.centerIn: parent
    //     ListView {
    //         id: subjectMgr
    //         width: 300
    //         height: 200
    //         model: subjects
    //     }
    //     Row {
    //         spacing: 10
    //         TextField {
    //             id: subjectName
    //             placeholderText: "Subject Name"
    //         }
    //
    //         Button {
    //             highlighted: true
    //             text: "Add"
    //             onClicked: {
    //                 subjects.push(subjectName.text)
    //                 console.log(subjects)
    //             }
    //         }
    //         Button {
    //             text: "Remove"
    //             onClicked: subjects.splice(subjectMgr.currentIndex, 1)
    //         }
    //     }
    // }

    // 题3
    // Item {
    //     signal clicked()
    //     property string text: "Button"
    //
    //     width: 100
    //     height: 32
    //     Rectangle {
    //         anchors.fill: parent
    //         color: "lightgray"
    //     }
    //     Text {
    //         anchors.centerIn: parent
    //         text: parent.text
    //     }
    //     MouseArea {
    //         anchors.fill: parent
    //         onClicked: clicked
    //     }
    // }
}