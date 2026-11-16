pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool dndEnabled: false
    property bool keepDisplayOn: false
    property bool wifiEnabled: false
    property string wifiName: "Not connected"
    property alias notifications: notificationServer.trackedNotifications
    property var toastNotificationIds: []

    function queueNotificationToast(notification) {
        if (root.dndEnabled || root.toastNotificationIds.includes(notification.id))
            return
        root.toastNotificationIds = root.toastNotificationIds.concat([notification.id])
    }

    function removeNotificationToast(id) {
        root.toastNotificationIds = root.toastNotificationIds.filter(
            notificationId => notificationId !== id
        )
    }

    function refreshWifi() {
        wifiStatus.running = false
        wifiStatus.running = true
        wifiNameStatus.running = false
        wifiNameStatus.running = true
    }

    function toggleWifi() {
        wifiToggle.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
        wifiToggle.running = true
    }

    function dismissAllNotifications() {
        const items = notificationServer.trackedNotifications.values || []
        for (const notification of items)
            notification.dismiss()
        root.toastNotificationIds = []
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: function(notification) {
            notification.tracked = true
            root.queueNotificationToast(notification)
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
            .filter(node => !!node)
    }

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled
        if (root.dndEnabled)
            root.toastNotificationIds = []
    }

    Process {
        id: wifiStatus
        command: ["nmcli", "-t", "-f", "WIFI", "general"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: wifiNameStatus
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let name = ""
                for (const line of lines) {
                    const separator = line.lastIndexOf(":")
                    if (separator >= 0 && line.slice(separator + 1) === "802-11-wireless") {
                        name = line.slice(0, separator).replace(/\\:/g, ":")
                        break
                    }
                }
                root.wifiName = name || "Not connected"
            }
        }
    }

    Process {
        id: wifiToggle
        command: []
        running: false
        onExited: root.refreshWifi()
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refreshWifi()
    }

    Process {
        command: [
            "systemd-inhibit",
            "--what=idle:sleep",
            "--mode=block",
            "--why=Lumen Keep Display On",
            "sleep",
            "infinity"
        ]
        running: root.keepDisplayOn
    }
}