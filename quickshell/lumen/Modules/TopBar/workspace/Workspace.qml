
import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    property var theme: null
    implicitWidth: workspaceRow.implicitWidth + 24
    implicitHeight: 36

    // Transparent rounded capsule
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.theme
               ? Qt.rgba(root.theme.surface.r, root.theme.surface.g,
                 root.theme.surface.b, 0.88) : "#55202020"
        border.width: 1
        border.color: root.theme ? root.theme.outline : "#30ffffff"
    }

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 7

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: workspace

                required property var modelData

                property bool focused: modelData.focused
                property bool active: modelData.active

                implicitWidth: focused ? 30 : 11
                implicitHeight: 11

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.centerIn: parent

                    width: parent.implicitWidth
                    height: parent.implicitHeight
                    radius: height / 2

                    color: workspace.focused
                        ? (root.theme ? root.theme.primary : "#ffffff")
                        : workspace.active
                            ? "#bbbbbb"
                            : "#66ffffff"

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: workspace.modelData.activate()
                }
            }
        }
    }
}
