import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "../../.." as Lumen

Item {
    id: root

    signal openControlCenter()

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

            property bool hovered: systemMouse.containsMouse

            width: systemRow.implicitWidth + 24
            height: 34
            radius: height / 2
              color: Qt.rgba(Lumen.Theme.surface.r, Lumen.Theme.surface.g,
                                Lumen.Theme.surface.b, 0.88)
            border.width: 1
              border.color: Lumen.Theme.outline

              Behavior on color { ColorAnimation { duration: 140 } }
              Behavior on border.color { ColorAnimation { duration: 140 } }

            Row {
                id: systemRow

                anchors.centerIn: parent
                spacing: 13

                // Wi-Fi
                Image {
                    id: wifiStatusIcon
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.iconPath("wifi")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: Lumen.ControlCenterState.wifiEnabled ? 1 : 0.4
                }

                // Bluetooth
                Image {
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.iconPath("bluetooth")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                        ? 1 : 0.4
                }

                // Speaker
                Image {
                    width: 17
                    height: 17
                    anchors.verticalCenter: parent.verticalCenter
                    source: !Pipewire.defaultAudioSink
                              || !Pipewire.defaultAudioSink.audio
                              || Pipewire.defaultAudioSink.audio.muted
                              || Pipewire.defaultAudioSink.audio.volume < 0.01
                        ? root.iconPath("volume-x")
                        : root.iconPath("volume-2")
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
                    opacity: !Pipewire.defaultAudioSource
                             || !Pipewire.defaultAudioSource.audio
                             || Pipewire.defaultAudioSource.audio.muted
                        ? 0.4 : 1
                }

                // Battery
                Row {
                    visible: UPower.displayDevice.isPresent
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

                        color: Lumen.Theme.foreground
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
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openControlCenter()
            }

            states: State {
                when: systemPill.hovered
                PropertyChanges {
                    systemPill.color: Qt.rgba(Lumen.Theme.surfaceContainer.r,
                                              Lumen.Theme.surfaceContainer.g,
                                              Lumen.Theme.surfaceContainer.b, 0.95)
                    systemPill.border.color: Lumen.Theme.primary
                }
            }
        }

        // ==================================
        // RUNNING APPLICATIONS PILL
        // ==================================

        Pill {
            id: appsPill

            clickable: true
            visible: trayRepeater.count > 0

            onClicked: root.openControlCenter()

            width: visible ? appsRow.implicitWidth + 20 : 0
            height: 34
            radius: height / 2

                 color: Qt.rgba(Lumen.Theme.surface.r, Lumen.Theme.surface.g,
                                Lumen.Theme.surface.b, 0.88)
            border.width: 1
                 border.color: Lumen.Theme.outline

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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            cursorShape: Qt.PointingHandCursor

                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton ||
                                    trayItem.modelData.onlyMenu) {
                                    if (trayItem.modelData.hasMenu)
                                        trayMenu.open()
                                } else {
                                    trayItem.modelData.activate()
                                }
                            }
                        }

                        QsMenuAnchor {
                            id: trayMenu
                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                        }

                        Rectangle {
                            anchors.fill: parent
                            z: -1
                            radius: 5
                            color: trayMouse.containsMouse
                                ? Qt.rgba(Lumen.Theme.primary.r,
                                          Lumen.Theme.primary.g,
                                          Lumen.Theme.primary.b, 0.18)
                                : "transparent"
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
