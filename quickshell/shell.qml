import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int pillTop: 4
    readonly property int iconSize: 13
    readonly property int textSize: 13

    // true when the focused workspace has at least one window
    readonly property bool hasWindows:
        (Hyprland.focusedWorkspace?.toplevels?.values?.length ?? 0) > 0
    readonly property real pillAlpha: hasWindows ? 0.96 : 0.55

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Launcher {}
    Wallpapers {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            // visible when hovering the top edge OR nothing is open
            property bool hovered: false
            readonly property bool shown: !root.hasWindows || hovered

            anchors { top: true; left: true; right: true }
            implicitHeight: 40
            color: "transparent"
            exclusiveZone: 0   // never push windows down

            // hidden: only a thin strip at the top catches the mouse
            mask: Region { item: bar.shown ? barRow : strip }

            Timer {
                id: hideTimer
                interval: 350
                onTriggered: bar.hovered = false
            }

            Item {
                id: barRow
                anchors.fill: parent

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) { hideTimer.stop(); bar.hovered = true; }
                        else hideTimer.restart();
                    }
                }

                // hover trigger at the very top edge
                Item {
                    id: strip
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 4
                }

                Item {
                    id: content
                    width: parent.width
                    height: parent.height
                    y: bar.shown ? 0 : -height
                    opacity: bar.shown ? 1 : 0
                    Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    // ---------- Workspaces (far left) ----------
                    Pill {
                        id: wsPill
                        bgAlpha: root.pillAlpha
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.top: parent.top
                        anchors.topMargin: root.pillTop
                        padding: 12
                        spacing: 10

                        Repeater {
                            model: 4
                            delegate: Text {
                                required property int index
                                readonly property int wsId: index + 1
                                readonly property bool active: Hyprland.focusedWorkspace?.id === wsId

                                text: wsId
                                font.pixelSize: root.textSize
                                font.bold: active
                                color: active ? Colors.primary : Colors.textDimTint
                                Behavior on color { ColorAnimation { duration: 200 } }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace " + parent.wsId)
                                }
                            }
                        }
                    }

                    // ---------- Clock (center) ----------
                    Pill {
                        id: clockPill
                        bgAlpha: root.pillAlpha
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: root.pillTop
                        padding: 14

                        Text {
                            text: Qt.formatDateTime(clock.date, "MMM d · h:mm AP").toUpperCase()
                            font.pixelSize: root.textSize
                            font.letterSpacing: 0.5
                            color: Colors.textTint
                        }
                    }

                    // ---------- System icons (far right) ----------
                    Pill {
                        id: trayPill
                        bgAlpha: root.pillAlpha
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.top: parent.top
                        anchors.topMargin: root.pillTop
                        padding: 12
                        spacing: 12

                        // Wi-Fi
                        Text {
                            text: "\uf1eb"
                            font.family: root.iconFont
                            font.pixelSize: root.iconSize
                            color: Colors.primary
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["nm-connection-editor"])
                            }
                        }

                        // Volume (scroll to change, click to mute)
                        Text {
                            readonly property var audio: Pipewire.defaultAudioSink?.audio
                            text: (audio?.muted ?? false) ? "\uf6a9" : "\uf028"
                            font.family: root.iconFont
                            font.pixelSize: root.iconSize
                            color: Colors.primary
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (parent.audio) parent.audio.muted = !parent.audio.muted
                                onWheel: wheel => {
                                    if (!parent.audio) return;
                                    const d = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                    parent.audio.volume = Math.max(0, Math.min(1, parent.audio.volume + d));
                                }
                            }
                        }

                        // Mic (click to mute)
                        Text {
                            readonly property var audio: Pipewire.defaultAudioSource?.audio
                            text: (audio?.muted ?? false) ? "\uf131" : "\uf130"
                            font.family: root.iconFont
                            font.pixelSize: root.iconSize
                            color: (audio?.muted ?? false) ? Colors.textDimTint : Colors.primary
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (parent.audio) parent.audio.muted = !parent.audio.muted
                            }
                        }

                        // Battery
                        Text {
                            readonly property var dev: UPower.displayDevice
                            readonly property real pct: dev?.percentage ?? 1
                            text: pct > 0.85 ? "\uf240" : pct > 0.6 ? "\uf241" : pct > 0.35 ? "\uf242" : pct > 0.1 ? "\uf243" : "\uf244"
                            font.family: root.iconFont
                            font.pixelSize: root.iconSize
                            color: pct < 0.15 ? "#ff6b6b" : Colors.primary
                        }

                        // Power profile (click to cycle)
                        Text {
                            text: "\uf0e7"
                            font.family: root.iconFont
                            font.pixelSize: root.iconSize
                            color: Colors.primary
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["sh", "-c",
                                    "p=$(powerprofilesctl get); case $p in power-saver) n=balanced;; balanced) n=performance;; *) n=power-saver;; esac; powerprofilesctl set $n"])
                            }
                        }

                        // Power menu
                        Text {
                            text: "\uf011"
                            font.family: root.iconFont
                            font.pixelSize: root.iconSize
                            color: Colors.primary
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["wlogout"])
                            }
                        }
                    }

                    // ---------- Tray apps (Steam, Telegram, ...) ----------
                    Pill {
                        id: appsPill
                        visible: SystemTray.items.values.length > 0
                        bgAlpha: root.pillAlpha
                        anchors.right: trayPill.left
                        anchors.rightMargin: 6
                        anchors.top: parent.top
                        anchors.topMargin: root.pillTop
                        padding: 10
                        spacing: 8

                        Repeater {
                            model: SystemTray.items

                            delegate: IconImage {
                                id: trayIcon
                                required property var modelData
                                implicitSize: 16
                                source: modelData.icon

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor

                                    function openMenu() {
                                        if (!trayIcon.modelData.hasMenu) return;
                                        const p = trayIcon.mapToItem(null, 0, trayIcon.height + 4);
                                        trayIcon.modelData.display(bar, p.x, p.y);
                                    }

                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton) {
                                            if (trayIcon.modelData.onlyMenu) openMenu();
                                            else trayIcon.modelData.activate();
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            trayIcon.modelData.secondaryActivate();
                                        } else {
                                            openMenu();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
