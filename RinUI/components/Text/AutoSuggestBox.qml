import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../themes"
import "../../components"


TextField {
    id: input
    property var suggestions: []
    property bool userInput: true
    property alias text: input.text
    signal suggestionChosen(string suggestion)

    placeholderText: "Type something..."

    function getFilteredSuggestions() {
        if (!suggestions) return []

        if (suggestions instanceof ListModel) {
            // ListModel 类型，遍历取 roleName 为 "text" 的值
            let res = []
            for (let i = 0; i < suggestions.count; i++) {
                let item = suggestions.get(i)
                if (item.text.startsWith(input.text))
                    res.push(item.text)
            }
            return res.length > 0 ? res : [qsTr("No results found")]
        } else if (Array.isArray(suggestions)) {
            // JS 数组
            let res = suggestions.filter(s => s.startsWith(input.text))
            return res.length > 0 ? res : [qsTr("No results found")]
        }
        return [qsTr("No results found")]
    }

    onTextChanged: {
        if (userInput) {
            filteredModel.model = getFilteredSuggestions()
            filteredModel.currentIndex = -1
            popup.open()
        }
    }


    Popup {
        id: popup
        width: input.width
        y: input.height
        implicitWidth: 100
        implicitHeight: Math.min(filteredModel.contentHeight + 6, maximumHeight)
        padding: 0


        ListView {
            id: filteredModel
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            clip: true

            ScrollBar.vertical: ScrollBar {
                id: scrollBar
                policy: ScrollBar.AsNeeded
            }

            delegate: ListViewDelegate {
                width: parent.width
                text: modelData
                onClicked: {
                    input.text = modelData
                    popup.close()
                    input.suggestionChosen(modelData)
                }
            }
        }
    }

    Keys.onPressed: {
        if (!popup.visible) return

        if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (filteredModel.count > 0) {
                filteredModel.currentIndex = Math.min(filteredModel.currentIndex + 1, filteredModel.count - 1)
                // 临时标记不是用户输入，避免触发过滤
                userInput = false
                text = filteredModel.model[filteredModel.currentIndex]  // 仅改变 text 不触发过滤
                userInput = true
            }
        } else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (filteredModel.count > 0) {
                filteredModel.currentIndex = Math.max(filteredModel.currentIndex - 1, 0)
                userInput = false
                text = filteredModel.model[filteredModel.currentIndex]
                userInput = true
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true
            if (filteredModel.currentIndex >= 0 && filteredModel.currentIndex < filteredModel.count) {
                let selected = filteredModel.model[filteredModel.currentIndex]
                text = selected
                popup.close()
                suggestionChosen(selected)
            }
        }
    }

}
