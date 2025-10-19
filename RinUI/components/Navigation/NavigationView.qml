import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"
import "../../windows"


RowLayout {
    // 外观 / Appearance //
    property bool appLayerEnabled: true  // 应用层背景
    property alias navExpandWidth: navigationBar.expandWidth  // 导航栏宽度
    property alias navMinimumExpandWidth: navigationBar.minimumExpandWidth  // 导航栏保持展开时窗口的最小宽度

    property alias navigationBar: navigationBar  // 导航栏
    property alias navigationItems: navigationBar.navigationItems  // 导航栏item
    property alias currentPage: navigationBar.currentPage  // 当前页面索引
    property string defaultPage: ""  // 默认索引项
    property var lastPages: []  // 上个页面索引
    property int pushEnterFromY: height
    property var window: parent  // 窗口对象

    // 页面组件缓存(Component)
    property var componentCache: ({})
    property bool pushInProgress: false

    signal pageChanged()  // 页面切换信号

    id: navigationView
    anchors.fill: parent

    Connections {
        target: window
        function onWidthChanged() {
            navigationBar.collapsed = navigationBar.isNotOverMinimumWidth()  // 判断窗口是否小于最小宽度
        }
    }

    NavigationBar {
        id: navigationBar
        windowTitle: window.title
        windowIcon: window.icon
        windowWidth: window.width
        stackView: stackView
        z: 999
        Layout.fillHeight: true
    }

    // 主体内容区域
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // 导航栏展开自动收起
        MouseArea {
            id: collapseCatcher
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons

            visible: !navigationBar.collapsed && navigationBar.isNotOverMinimumWidth()

            onClicked: {
                navigationBar.collapsed = true
            }
        }

        Rectangle {
            id: appLayer
            width: parent.width + Utils.windowDragArea + radius
            height: parent.height + Utils.windowDragArea + radius
            color: Theme.currentTheme.colors.layerColor
            border.color: Theme.currentTheme.colors.cardBorderColor
            border.width: 1
            opacity: window.appLayerEnabled
            radius: Theme.currentTheme.appearance.windowRadius
        }


        StackView {
            id: stackView
            anchors.fill: parent
            anchors.leftMargin: 1
            anchors.topMargin: 1


            // 切换动画 / Page Transition //
            pushEnter : Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Utils.appearanceSpeed
                    easing.type: Easing.InOutQuad
                }

                PropertyAnimation {
                    property: "y"
                    from: pushEnterFromY
                    to: 0
                    duration: Utils.animationSpeedMiddle
                    easing.type: Easing.OutQuint
                }
            }

            pushExit : Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Utils.animationSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            popExit : Transition {
                SequentialAnimation {
                    PauseAnimation {  // 延时 200ms
                        duration: Utils.animationSpeedFast * 0.6
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Utils.appearanceSpeed
                        easing.type: Easing.InOutQuad
                    }
                }

                PropertyAnimation {
                    property: "y"
                    from: 0
                    to: pushEnterFromY
                    duration: Utils.animationSpeed
                    easing.type: Easing.InQuint
                }
            }

            popEnter : Transition {
                SequentialAnimation {
                    PauseAnimation {  // 延时 200ms
                        duration: Utils.animationSpeed
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            initialItem: Item {}

        }


        Component.onCompleted: {
            if (navigationItems.length > 0) {
                if (defaultPage !== "") {
                    safePush(defaultPage, false)
                } else {
                    safePush(navigationItems[0].page, false)  // 推送默认页面
                }  // 推送页面
            }
        }
    }

    function safePop() {
        // console.log("Popping Page; Depth:", stackView.depth)
        if (navigationBar.lastPages.length > 1) {
            navigationBar.currentPage = navigationBar.lastPages.pop()  // Retrieve and remove the last page
            navigationBar.lastPages = navigationBar.lastPages  // refresh
            stackView.pop()
        } else {
            console.log("Can't pop: only root page left")
        }
    }

    function pop() {
        safePop()
    }

    function push(page, reload, fromNavigation) {
        safePush(page, reload, fromNavigation)
    }

    function safePush(page, reload, fromNavigation) {
        if (pushInProgress) {
            console.log("Push already in progress, queuing...")
            Qt.callLater(function() { safePush(page, reload, fromNavigation) })
            return
        }

        // 无效检测
        if (!(typeof page === "object" || typeof page === "string" || page instanceof Component)) {
            console.error("Invalid page type:", typeof page)
            return
        }

        pushInProgress = true

        if (page instanceof Component) {
            // 对于Component类型, 直接使用
            asyncPush(page, page.toString(), reload)
        } else if (typeof page === "object" || typeof page === "string") {
            let pageKey = page.toString()
            // 检查缓存
            if (!componentCache[pageKey] || reload) {
                let component = Qt.createComponent(page)

                if (component.status === Component.Ready) {
                    componentCache[pageKey] = component
                    console.log("Created and cached component:", pageKey)
                    asyncPush(component, pageKey, reload)
                } else if (component.status === Component.Error) {
                    console.error("Failed to load:", page, component.errorString())
                    pushInProgress = false
                    navigationBar.lastPages.push(navigationBar.currentPage)
                    navigationBar.lastPages = navigationBar.lastPages
                    navigationBar.currentPage = pageKey
                    pageChanged()
                    stackView.push("ErrorPage.qml", {
                        errorMessage: component.errorString(),
                        page: page,
                    })
                    return
                } else {
                    // 组件还在加载中
                    component.statusChanged.connect(function() {
                        if (component.status === Component.Ready) {
                            componentCache[pageKey] = component
                            console.log("Async loaded and cached component:", pageKey)
                            asyncPush(component, pageKey, reload)
                        } else if (component.status === Component.Error) {
                            console.error("Failed to async load:", page, component.errorString())
                            pushInProgress = false
                        }
                    })
                    return
                }
            } else {
                console.log("Using cached component:", pageKey)
                asyncPush(componentCache[pageKey], pageKey, reload)
            }
        }
    }

    function asyncPush(component, pageKey, reload) {
        if (reload) {
            // 查找并销毁栈中的旧实例
            for (let i = 0; i < stackView.depth; i++) {
                let item = stackView.get(i)
                if (item && item.toString().includes(pageKey)) {
                    console.log("Destroying old instance for reload:", pageKey)
                    if (i === stackView.depth - 1) {
                        stackView.pop(null, StackView.Immediate)
                    } else {
                        // 非顶层特殊处理
                        while (stackView.depth > i) {
                            let topItem = stackView.pop(null, StackView.Immediate)
                            if (topItem === item) {
                                topItem.destroy()
                                break
                            }
                        }
                    }
                    break
                }
            }
        }
        // 创建新的页面实例
        let pageInstance = component.createObject(null)
        if (!pageInstance) {
            console.error("Failed to create page instance for:", pageKey)
            pushInProgress = false
            return
        }
        // 更新导航状态
        navigationBar.lastPages.push(navigationBar.currentPage)
        navigationBar.lastPages = navigationBar.lastPages
        navigationBar.currentPage = pageKey
        pageChanged()
        // 推送
        stackView.push(pageInstance)
        Qt.callLater(function() {
            pushInProgress = false
        })
    }

    function findPageByKey(key) {
        const item = menuItems.find(i => i.key === key);
        return item ? item.page : null;
    }
}
