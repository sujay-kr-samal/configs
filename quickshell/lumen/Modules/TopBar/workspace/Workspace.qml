
import QtQuick
import Quickshell.Hyprland
import "../../.." as Lumen

Item {
    id: root

    implicitWidth: workspaceRow.implicitWidth + 24
    implicitHeight: 36

    // Transparent rounded capsule
    Rectangle {
        anchors.fill: parent
        radius: height / 2
                color: Qt.rgba(Lumen.Theme.surface.r, Lumen.Theme.surface.g,
                                             Lumen.Theme.surface.b, 0.88)
        border.width: 1
                border.color: Lumen.Theme.outline
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
                visible: modelData.id > 0

                property bool active: modelData.active
                property bool focused: modelData.focused

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
                        ? Lumen.Theme.primary
                        : workspace.active
                            ? Lumen.Theme.tertiary
                            : Qt.rgba(Lumen.Theme.foreground.r,
                                      Lumen.Theme.foreground.g,
                                      Lumen.Theme.foreground.b, 0.4)

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
