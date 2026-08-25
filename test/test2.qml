import QtQuick
import QtQuick.Controls
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

    Button {
        text: "btn"
        highlighted: true
        ToolTip.visible: hovered
        ToolTip.text:"sdfsdfafsdaf"
    }
}