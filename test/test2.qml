import QtQuick
import QtQuick.Controls
import QtQuick as QQ
// import RinUI
import Qt.labs.qmlmodels
import QtQuick.Controls.FluentWinUI3

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("HeaderView")




    // Rectangle {
    //     color: "transparent"
    //     anchors.fill: parent
    //     // The background color will show through the cell
    //     // spacing, and therefore become the grid line color.
    //     // color: Application.styleHints.appearance === Qt.Light ? palette.mid : palette.midlight
    //
    //     HorizontalHeaderView {
    //         id: horizontalHeader
    //         anchors.left: tableView.left
    //         anchors.top: parent.top
    //         syncView: tableView
    //         clip: true
    //
    //         model: [
    //             "Name",
    //             "Color"
    //         ]
    //     }
    //
    //     VerticalHeaderView {
    //         id: verticalHeader
    //         anchors.top: tableView.top
    //         anchors.left: parent.left
    //         syncView: tableView
    //         clip: true
    //     }
    //
    //     TableView {
    //         id: tableView
    //         anchors.left: verticalHeader.right
    //         anchors.top: horizontalHeader.bottom
    //         anchors.right: parent.right
    //         anchors.bottom: parent.bottom
    //         clip: true
    //
    //         columnSpacing: 1
    //         rowSpacing: 1
    //
    //         model: TableModel {
    //             TableModelColumn { display: "name"; edit:"name" }
    //             TableModelColumn { display: "color" ;edit:"color" }
    //
    //             rows: [
    //                 {
    //                     "name": "cat",
    //                     "color": "black"
    //                 },
    //                 {
    //                     "name": "dog",
    //                     "color": "brown"
    //                 },
    //                 {
    //                     "name": "bird",
    //                     "color": "white"
    //                 },
    //                 {
    //                     "name": "bird",
    //                     "color": "white"
    //                 }
    //             ]
    //         }
    //
    //         delegate: TableViewDelegate {
    //             // implicitWidth: 100
    //             // implicitHeight: 20
    //             // color: palette.base
    //             // Label {
    //             //     text: display
    //             // }
    //         }
    //     }
    // }

    QQ.ListView {
        id: listView
        width: 150
        height: 400
        // textRole: "name"

        model: studentsModel

        delegate: ItemDelegate {
            width: listView.width
            text: "sdfsdfsdfsdfsdfdsfdsfsdafasdkfhasdfhjkasdfhbjkasdhfjkashdfjkasdhjffsfsdf"
        }

        ListModel {
        id: studentsModel

        ListElement { name: qsTr("Aikiyo Fuuka") }  // 风香
        ListElement { name: qsTr("Hayase Yuuka") }  // 邮箱
        ListElement { name: qsTr("Hanaoka Yuzu") }  // 柚子
        ListElement { name: qsTr("Kuromi Serika") }  // 芹香
        ListElement { name: qsTr("Kurosaki Koyuki") }  // 小雪
        ListElement { name: qsTr("Kuda Izuna") }  // 泉奈
        ListElement { name: qsTr("Okusora Ayane") }  // 绫音
        ListElement { name: qsTr("Saiba Midori") }  // 绿
        ListElement { name: qsTr("Saiba Momoi") }  // 桃
        ListElement { name: qsTr("Shiromi Iori") }  // 伊织
        ListElement { name: qsTr("Shishidou Nonomi") }  // 野宫
        ListElement { name: qsTr("Sunaookami Shiroko") }  // 白子😋
        ListElement { name: qsTr("Tendou Aris") }  // aris
        ListElement { name: qsTr("Ushio Noa") }  // 诺亚
        ListElement { name: qsTr("Yutori Natsu") }  // 夏
    }
    }

    Button {
        text: "btn"
        highlighted: true
        ToolTip.visible: hovered
        ToolTip.text:"sdfsdfafsdaf"
    }
}