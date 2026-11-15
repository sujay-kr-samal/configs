
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window

    property bool launcherVisible: false
    property color primaryColor: "#8ce2bf"
    property color primaryContainerColor: "#29483c"
    property color backgroundColor: "#0e1514"
    property color surfaceColor: "#151b19"
    property color surfaceContainerColor: "#1a2120"
    property color foregroundColor: "#dde4e2"
    property color mutedForegroundColor: "#bec9c6"
    property color outlineColor: "#3f4947"

    screen: Quickshell.screens[0]
    visible: launcherVisible
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: launcherVisible
                                 ? WlrKeyboardFocus.OnDemand
                                 : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    onLauncherVisibleChanged: {
        console.log("Launcher visibility:", launcherVisible)
        if (launcherVisible) {
            Qt.callLater(function() {
                launcher.focusSearch()
            })
        } else {
            launcher.clearSearchFocus()
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(window.backgroundColor.r, window.backgroundColor.g,
                           window.backgroundColor.b, 0.72)

            MouseArea {
                anchors.fill: parent
                onClicked: window.launcherVisible = false
            }
        }

        Launcher {
            id: launcher
            primaryColor: window.primaryColor
            primaryContainerColor: window.primaryContainerColor
            backgroundColor: window.backgroundColor
            surfaceColor: window.surfaceColor
            surfaceContainerColor: window.surfaceContainerColor
            foregroundColor: window.foregroundColor
            mutedForegroundColor: window.mutedForegroundColor
            outlineColor: window.outlineColor

            width: Math.min(560, parent.width - 40)
            height: Math.min(620, parent.height - 48)
            anchors.centerIn: parent

            onCloseRequested: window.launcherVisible = false
        }
    }
}
