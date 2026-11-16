
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "." as Lumen
import "Modules/Launcher"
import "Modules/TopBar/workspace"
import "Modules/TopBar/DateTime"
import "Modules/TopBar/Right"
import "Modules/ControlCenter"

ShellRoot {
    id: root

    property bool launcherVisible: false
    property bool controlCenterVisible: false
    property string controlCenterScreenName: ""

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.launcherVisible = !root.launcherVisible
        }

        function close() {
            root.launcherVisible = false
        }

        function toggleControlCenter() {
            if (root.controlCenterVisible) {
                root.controlCenterVisible = false
                return
            }

            if (!Hyprland.focusedMonitor)
                return

            root.controlCenterScreenName = Hyprland.focusedMonitor.name
            root.controlCenterVisible = true
        }

        function closeControlCenter() {
            root.controlCenterVisible = false
        }
    }

    LauncherWindow {
        id: launcherWindow
        launcherVisible: root.launcherVisible
        onCloseRequested: root.launcherVisible = false
    }
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 48
            color: "transparent"

            Workspace {
                anchors {
                    left: parent.left
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
            }

            DateTime {
                anchors.centerIn: parent
            }

            Right {
                anchors {
                    right: parent.right
                    rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                onOpenControlCenter: {
                    root.controlCenterScreenName = modelData.name
                    root.controlCenterVisible = true
                }
            }

            // Lumen Control Center
            PopupWindow {
                id: controlPopup

                anchor.window: bar
                anchor.rect.x: Math.max(12, bar.width - implicitWidth - 18)
                anchor.rect.y: bar.height + 8

                implicitWidth: Math.min(390, bar.screen.width - 24)
                implicitHeight: Math.min(750, bar.screen.height - bar.height - 20)

                color: "transparent"
                visible: root.controlCenterVisible
                         && modelData.name === root.controlCenterScreenName
                grabFocus: true

                onVisibleChanged: {
                    if (!visible && root.controlCenterVisible
                        && modelData.name === root.controlCenterScreenName) {
                        root.controlCenterVisible = false
                    }
                }

                ControlCenter {
                    anchors.fill: parent
                    visible: controlPopup.visible

                    onWallpaperApplied: Lumen.Theme.reloadPalette()

                    onCloseRequested: {
                        root.controlCenterVisible = false
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notificationWindow
            required property var modelData
            screen: modelData
            visible: !!Hyprland.focusedMonitor
                     && modelData.name === Hyprland.focusedMonitor.name
            color: "transparent"
            mask: notificationInputMask
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors {
                top: true
                right: true
            }
            implicitWidth: 420
            implicitHeight: Math.min(notificationRenderer.implicitHeight, 600)

            NotificationPopups {
                id: notificationRenderer
                anchors.fill: parent
            }

            Region {
                id: notificationInputMask
                item: notificationRenderer.inputRegionItem
            }
        }
    }
}
