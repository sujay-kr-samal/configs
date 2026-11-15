import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

Item {
    id: root

    signal openControlCenter()
    property var theme: null

    implicitWidth: rightRow.implicitWidth
    implicitHeight: 38

    // Local icon helper
    function iconPath(name) {
        return Qt.resolvedUrl("../../../assets/icons/" + name + ".svg")
    }

    Row {
        id: rightRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // ==================================
        // SYSTEM STATUS PILL
        // ==================================

        Rectangle {
            id: systemPill

            width: systemRow.implicitWidth + 24
            height: 34
            radius: height / 2

                 color: root.theme
                     ? Qt.rgba(root.theme.surface.r, root.theme.surface.g,
                         root.theme.surface.b, 0.88) : "#55202020"
            border.width: 1
                 border.color: root.theme ? root.theme.outline : "#30ffffff"

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            Row {
                id: systemRow

                anchors.centerIn: parent
                spacing: 13

                // Wi-Fi
                Image {
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.iconPath("wifi")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                // Bluetooth
                Image {
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.iconPath("bluetooth")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                // Speaker
                Image {
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.iconPath("volume-2")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                // Microphone
                Image {
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.iconPath("mic")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                // Battery
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Image {
                        width: 17
                        height: 17
                        anchors.verticalCenter: parent.verticalCenter

                        source: {
                            if (!UPower.displayDevice.ready)
                                return root.iconPath("battery-full")

                            if (UPower.displayDevice.state === UPowerDeviceState.Charging)
                                return root.iconPath("battery-charging")

                            if (UPower.displayDevice.percentage <= 0.2)
                                return root.iconPath("battery-low")

                            return root.iconPath("battery-full")
                        }

                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: UPower.displayDevice.ready
                            ? Math.round(UPower.displayDevice.percentage * 100) + "%"
                            : "--%"

                        color: "#ffffff"
                        font.pixelSize: 11
                    }
                }

                // Power
                Image {
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.iconPath("power")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            MouseArea {
                id: systemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: root.openControlCenter()
            }

            states: State {
                when: systemMouse.containsMouse
                PropertyChanges {
                    systemPill.color: root.theme
                        ? Qt.rgba(root.theme.surfaceContainer.r,
                                  root.theme.surfaceContainer.g,
                                  root.theme.surfaceContainer.b, 0.95)
                        : "#78323a35"
                    systemPill.border.color: root.theme ? root.theme.primary : "#558ce2bf"
                }
            }
        }

        // ==================================
        // RUNNING APPLICATIONS PILL
        // ==================================

        Rectangle {
            id: appsPill

            visible: trayRepeater.count > 0

            width: visible ? appsRow.implicitWidth + 20 : 0
            height: 34
            radius: height / 2

                 color: root.theme
                     ? Qt.rgba(root.theme.surface.r, root.theme.surface.g,
                         root.theme.surface.b, 0.88) : "#55202020"
            border.width: 1
                 border.color: root.theme ? root.theme.outline : "#30ffffff"

            Row {
                id: appsRow

                anchors.centerIn: parent
                spacing: 10

                Repeater {
                    id: trayRepeater

                    model: SystemTray.items

                    delegate: Item {
                        id: trayItem

                        required property var modelData

                        width: 19
                        height: 19

                        IconImage {
                            anchors.centerIn: parent

                            width: 18
                            height: 18

                            source: trayItem.modelData.icon
                        }

                        MouseArea {
                            id: trayMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                trayItem.modelData.activate()
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            z: -1
                            radius: 5
                            color: trayMouse.containsMouse ? "#33413d" : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        ToolTip {
                            visible: trayMouse.containsMouse
                            text: trayItem.modelData.tooltipTitle
                                  || trayItem.modelData.title
                            delay: 500
                        }
                    }
                }
            }
        }
    }
}
