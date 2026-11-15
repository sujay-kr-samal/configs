
import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root

    signal closeRequested()

    property color primaryColor: "#8ce2bf"
    property color primaryContainerColor: "#29483c"
    property color backgroundColor: "#0e1514"
    property color surfaceColor: "#151b19"
    property color surfaceContainerColor: "#1a2120"
    property color foregroundColor: "#dde4e2"
    property color mutedForegroundColor: "#bec9c6"
    property color outlineColor: "#3f4947"
    property string searchText: ""
    property int selectedIndex: 0

    function focusSearch() {
        searchField.forceActiveFocus()
    }

    function clearSearchFocus() {
        searchField.focus = false
    }

    function getApps() {
        const apps = DesktopEntries.applications.values || []
        const query = searchText.trim().toLowerCase()

        return apps.filter(app => {
            if (!app || !app.name)
                return false

            return query === ""
                || app.name.toLowerCase().includes(query)
                || (app.genericName || "").toLowerCase().includes(query)
                || (app.comment || "").toLowerCase().includes(query)
        })
    }

    function appIconName(iconName) {
        if (!iconName || iconName === "preferences-system-network"
                || iconName === "applications-system")
            return "application-x-executable"

        return iconName
    }

    function refreshApps() {
        appList.model = getApps()
        selectedIndex = 0
        appList.currentIndex = appList.count > 0 ? 0 : -1
    }

    function launchApp(index) {
        const apps = getApps()

        if (index < 0 || index >= apps.length)
            return

        apps[index].execute()
        closeRequested()
    }

    onSelectedIndexChanged: {
        if (appList.count > 0) {
            appList.currentIndex = selectedIndex
            appList.positionViewAtIndex(selectedIndex, GridView.Contain)
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.refreshApps() }
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: root.surfaceColor
        border.color: root.outlineColor
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16

            Item {
                id: headerRow
                width: parent.width
                height: 30

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Applications"
                    color: root.foregroundColor
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    width: 42
                    height: 24
                    radius: 12
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.primaryContainerColor
                    border.color: root.outlineColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: appList.count
                        color: root.primaryColor
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                id: searchBox
                width: parent.width
                height: 50
                radius: 15
                  color: searchField.activeFocus
                      ? root.surfaceContainerColor
                      : root.backgroundColor
                  border.color: searchField.activeFocus
                          ? root.primaryColor
                          : root.outlineColor
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                TextField {
                    id: searchField

                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: text.length > 0 ? 56 : 15

                    placeholderText: "Search applications"
                    color: root.foregroundColor
                    placeholderTextColor: root.mutedForegroundColor
                    selectionColor: root.primaryColor
                    selectedTextColor: root.backgroundColor

                    font.pixelSize: 14
                    background: Rectangle {
                        color: "transparent"
                        border.width: 0
                    }

                    onTextChanged: {
                        root.searchText = text
                        root.refreshApps()
                    }

                    Keys.onEscapePressed: root.closeRequested()

                    Keys.onDownPressed: {
                        if (root.selectedIndex < appList.count - 1)
                            root.selectedIndex++
                    }

                    Keys.onUpPressed: {
                        if (root.selectedIndex > 0)
                            root.selectedIndex--
                    }

                    Keys.onReturnPressed: root.launchApp(root.selectedIndex)
                    Keys.onEnterPressed: root.launchApp(root.selectedIndex)
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchField.text.length > 0
                    text: "Clear"
                    color: root.primaryColor
                    font.pixelSize: 11
                    font.weight: Font.Medium

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchField.clear()
                            searchField.forceActiveFocus()
                        }
                    }
                }
            }

            Text {
                id: appsLabel
                text: "All apps"
                color: root.mutedForegroundColor
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            GridView {
                id: appList

                width: parent.width
                height: Math.max(
                    0,
                    parent.height - headerRow.height - searchBox.height
                    - appsLabel.implicitHeight - parent.spacing * 3
                )
                cellWidth: width / 4
                cellHeight: 98
                clip: true
                model: root.getApps()

                delegate: Item {
                    id: appDelegate
                    required property var modelData
                    required property int index
                    property bool useFallbackIcon: false

                    width: appList.cellWidth
                    height: appList.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 16
                           color: root.selectedIndex === index
                               ? root.primaryContainerColor : mouseArea.containsMouse
                                   ? "#24ffffff" : "transparent"
                        border.width: root.selectedIndex === index ? 1 : 0
                           border.color: root.primaryColor

                        Behavior on color { ColorAnimation { duration: 130 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 48
                                height: 48

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 15
                                     color: Qt.rgba(root.foregroundColor.r,
                                                root.foregroundColor.g,
                                                root.foregroundColor.b, 0.08)
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 34
                                    height: 34

                                    source: Quickshell.iconPath(
                                        appDelegate.useFallbackIcon
                                            ? "application-x-executable"
                                            : root.appIconName(modelData.icon)
                                    )

                                    fillMode: Image.PreserveAspectFit
                                    smooth: true

                                    onStatusChanged: {
                                        if (status === Image.Error && !appDelegate.useFallbackIcon)
                                            appDelegate.useFallbackIcon = true
                                    }
                                }
                            }

                            Text {
                                width: appList.cellWidth - 12

                                text: modelData.name
                                color: root.foregroundColor
                                font.pixelSize: 12

                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: root.selectedIndex = index
                            onClicked: root.launchApp(index)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: appList.count === 0

                    text: "No applications found"
                    color: root.mutedForegroundColor
                    font.pixelSize: 13
                }
            }
        }
    }

    Component.onCompleted: {
        refreshApps()

        console.log(
            "Lumen launcher: found",
            DesktopEntries.applications.values.length,
            "applications"
        )
    }
}
