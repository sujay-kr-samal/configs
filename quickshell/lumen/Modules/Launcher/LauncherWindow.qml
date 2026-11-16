
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../.." as Lumen

PanelWindow {
    id: window

    signal closeRequested()

    property bool launcherVisible: false

    screen: Quickshell.screens.find(
        candidate => Hyprland.focusedMonitor
                     && candidate.name === Hyprland.focusedMonitor.name
    ) || Quickshell.screens[0]
    visible: launcherVisible || overlay.opacity > 0.01
    color: "transparent"
    mask: launcherVisible ? null : emptyInputMask

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: launcherVisible
                                 ? WlrKeyboardFocus.Exclusive
                                 : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    onLauncherVisibleChanged: {
        if (launcherVisible) {
            focusTimer.restart()
        } else {
            focusTimer.stop()
            launcher.clearSearchFocus()
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        repeat: false

        onTriggered: {
            if (window.launcherVisible)
                launcher.prepareForOpen()
        }
    }

    Item {
        id: emptyInputArea
        width: 0
        height: 0
    }

    Region {
        id: emptyInputMask
        item: emptyInputArea
    }

    Item {
        id: overlay
        visible: window.launcherVisible || opacity > 0.01
        enabled: window.launcherVisible
        opacity: window.launcherVisible ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Lumen.Theme.background.r, Lumen.Theme.background.g,
                           Lumen.Theme.background.b, 0.72)

            MouseArea {
                anchors.fill: parent
                onClicked: window.closeRequested()
            }
        }

        Launcher {
            id: launcher
            scale: window.launcherVisible ? 1 : 0.98

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            width: Math.min(620, parent.width - 36)
            height: Math.min(640, parent.height - 44)
            anchors.centerIn: parent

            onCloseRequested: window.closeRequested()
        }
    }
}
