
import QtQuick
import QtQuick.Controls
import QtQml
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import "../.." as Lumen

Item {
    id: root

    signal closeRequested()
    signal wallpaperApplied()

    property string wallpaperDirectory:
        Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string currentWallpaper: ""
    property string wallpaperMessage: "Choose a wallpaper"
    property bool wifiEnabled: Lumen.ControlCenterState.wifiEnabled
    property string wifiName: Lumen.ControlCenterState.wifiName
    property bool bluetoothEnabled: Bluetooth.defaultAdapter
        ? Bluetooth.defaultAdapter.enabled : false
    property string bluetoothName: {
        if (!Bluetooth.defaultAdapter)
            return "No device connected"
        const devices = Bluetooth.defaultAdapter.devices.values || []
        const connected = devices.find(device => device.connected)
        return connected ? connected.name : "No device connected"
    }
    property bool sliderDragging: false
    property string pendingLevelKey: ""
    property real pendingLevel: 0
    property string powerActionPending: ""

    focus: true

    Keys.onEscapePressed: function(event) {
        event.accepted = true
        root.closeRequested()
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
    }

    property real brightness: 41
    property real speaker: Pipewire.defaultAudioSink
        && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio.volume * 100 : 0
    property real microphone: Pipewire.defaultAudioSource
        && Pipewire.defaultAudioSource.audio
        ? Pipewire.defaultAudioSource.audio.volume * 100 : 0

    property int notificationCount:
        (Lumen.ControlCenterState.notifications.values || []).length

    // ---------------------------------------------------------
    // COMMAND HELPERS
    // ---------------------------------------------------------

    function runCommand(args) {
        Quickshell.execDetached(args)
    }

    function selectWallpaper(path) {
        if (wallpaperProcess.running)
            return

        wallpaperMessage = "Applying wallpaper and colors..."
        wallpaperProcess.command = [
            "bash",
            Quickshell.env("HOME") + "/.config/quickshell/set-wallpaper.sh",
            path
        ]
        wallpaperProcess.running = true
    }

    function refreshProcess(proc) {
        proc.running = false
        proc.running = true
    }

    function refreshAll() {
        refreshProcess(brightnessStatus)
    }

    function setLevel(key, value) {
        value = Math.round(Math.max(key === "brightness" ? 5 : 0,
                                    Math.min(100, value)))

        if (key === "brightness") {
            brightness = value
        } else if (key === "speaker") {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                Pipewire.defaultAudioSink.audio.volume = value / 100
            return
        } else {
            if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio)
                Pipewire.defaultAudioSource.audio.volume = value / 100
            return
        }

        pendingLevelKey = key
        pendingLevel = value
        if (!levelApplyTimer.running)
            levelApplyTimer.start()
    }

    function applyPendingLevel() {
        if (pendingLevelKey === "brightness") {
            runCommand(["brightnessctl", "set", pendingLevel + "%"])
        }
    }

    function flushPendingLevel() {
        if (pendingLevelKey === "brightness") {
            levelApplyTimer.stop()
            applyPendingLevel()
        }
    }

    function toggleWifi() {
        Lumen.ControlCenterState.toggleWifi()
    }

    function toggleBluetooth() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
    }

    function toggleDnd() {
        Lumen.ControlCenterState.toggleDnd()
    }

    function toggleDisplay() {
        Lumen.ControlCenterState.keepDisplayOn =
            !Lumen.ControlCenterState.keepDisplayOn
    }

    function powerAction(action) {
        if (powerActionPending !== action) {
            powerActionPending = action
            powerConfirmTimer.restart()
            return
        }

        powerConfirmTimer.stop()
        powerActionPending = ""
        if (action === "Logout")
            runCommand(["hyprctl", "dispatch", "exit"])
        else if (action === "Restart")
            runCommand(["systemctl", "reboot"])
        else if (action === "Shutdown")
            runCommand(["systemctl", "poweroff"])
    }

    function clearNotifications() {
        Lumen.ControlCenterState.dismissAllNotifications()
    }

    // ---------------------------------------------------------
    // STATUS PROCESSES
    // ---------------------------------------------------------

    FolderListModel {
        id: wallpaperFiles
        folder: "file://" + root.wallpaperDirectory
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Name
    }

    FileView {
        id: currentWallpaperFile
        path: Quickshell.env("HOME") + "/.cache/current-wall"
        watchChanges: true
        onLoaded: root.currentWallpaper = currentWallpaperFile.text().trim()
    }

    Process {
        id: wallpaperProcess
        command: []
        running: false

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.wallpaperMessage = "Wallpaper and colors updated"
                currentWallpaperFile.reload()
                root.wallpaperApplied()
            } else {
                root.wallpaperMessage = "Could not apply wallpaper"
                console.warn("Wallpaper command failed with exit code", exitCode)
            }
        }
    }

    Process {
        id: brightnessStatus
        command: ["brightnessctl", "-m"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(",")

                if (parts.length >= 4) {
                    let value = parseFloat(parts[3].replace("%", ""))

                    if (!isNaN(value) && !root.sliderDragging)
                        root.brightness = Math.max(5, value)
                }
            }
        }
    }

    Timer {
        id: levelApplyTimer
        interval: 50
        repeat: false
        onTriggered: root.applyPendingLevel()
    }

    Timer {
        id: powerConfirmTimer
        interval: 2500
        repeat: false
        onTriggered: root.powerActionPending = ""
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible
        triggeredOnStart: true

        onTriggered: root.refreshAll()
    }

    // ---------------------------------------------------------
    // MAIN PANEL
    // ---------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        radius: 30
                color: Qt.rgba(Lumen.Theme.surface.r, Lumen.Theme.surface.g,
                                             Lumen.Theme.surface.b, 0.97)
                border.color: Lumen.Theme.outline
        border.width: 1
        clip: true

        Flickable {
            anchors.fill: parent
            anchors.margins: 22

            contentWidth: width
            contentHeight: content.implicitHeight

            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                width: parent.width
                spacing: 19

                // HEADER

                Column {
                    width: parent.width
                    spacing: 13

                    Rectangle {
                        width: 34
                        height: 4
                        radius: 2
                        color: Lumen.Theme.outline
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Quick panel"
                        color: Lumen.Theme.foreground
                        font.pixelSize: 23
                        font.weight: Font.Medium
                    }
                }

                // CONNECTIVITY

                Column {
                    width: parent.width
                    spacing: 9

                    // WIFI

                    Rectangle {
                        width: parent.width
                        height: 70
                        radius: 24
                           color: root.wifiEnabled
                               ? Lumen.Theme.primaryContainer
                               : Lumen.Theme.surfaceContainer

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 13

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 21
                                    color: root.wifiEnabled
                                        ? Lumen.Theme.primary
                                        : Lumen.Theme.background
                                anchors.verticalCenter: parent.verticalCenter

                                Icon {
                                    anchors.centerIn: parent
                                    width: 21
                                    height: 21
                                    source: Qt.resolvedUrl("../../assets/icons/wifi.svg")
                                    tint: root.wifiEnabled
                                        ? Lumen.Theme.primaryText
                                        : Lumen.Theme.foreground
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                width: parent.width - 68

                                Text {
                                    text: "Wi-Fi"
                                     color: root.wifiEnabled
                                         ? Lumen.Theme.primaryContainerText
                                         : Lumen.Theme.foreground
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: root.wifiEnabled ? root.wifiName : "Off"
                                     color: Lumen.Theme.mutedForeground
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleWifi()
                        }
                    }

                    // BLUETOOTH

                    Rectangle {
                        width: parent.width
                        height: 70
                        radius: 24
                           color: root.bluetoothEnabled
                               ? Lumen.Theme.primaryContainer
                               : Lumen.Theme.surfaceContainer

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 13

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 21
                                    color: root.bluetoothEnabled
                                        ? Lumen.Theme.primary
                                        : Lumen.Theme.background
                                anchors.verticalCenter: parent.verticalCenter

                                Icon {
                                    anchors.centerIn: parent
                                    width: 21
                                    height: 21
                                    source: Qt.resolvedUrl("../../assets/icons/bluetooth.svg")
                                    tint: root.bluetoothEnabled
                                        ? Lumen.Theme.primaryText
                                        : Lumen.Theme.foreground
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                width: parent.width - 68

                                Text {
                                    text: "Bluetooth"
                                     color: Lumen.Theme.foreground
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: root.bluetoothEnabled ? root.bluetoothName : "Off"
                                     color: Lumen.Theme.mutedForeground
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleBluetooth()
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 9

                    Row {
                        width: parent.width
                        spacing: 8

                        Column {
                            width: parent.width - wallpaperCount.implicitWidth - 8
                            spacing: 3

                            Text {
                                text: "Wallpaper"
                                color: Lumen.Theme.foreground
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: root.wallpaperMessage
                                  color: Lumen.Theme.mutedForeground
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: wallpaperCount
                            width: implicitWidth
                            text: wallpaperFiles.count + " images"
                            color: Lumen.Theme.mutedForeground
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    GridView {
                        id: wallpaperGrid
                        width: parent.width
                        height: 126
                        clip: true
                        cellWidth: (width - 16) / 3
                        cellHeight: 116
                        model: wallpaperFiles

                        delegate: Item {
                            id: wallpaperTile
                            property string wallpaperName: fileName
                            width: wallpaperGrid.cellWidth
                            height: wallpaperGrid.cellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3
                                radius: 11
                                clip: true
                                    color: Lumen.Theme.surfaceContainer
                                border.width: root.wallpaperDirectory + "/"
                                              + wallpaperTile.wallpaperName
                                              === root.currentWallpaper ? 2 : 1
                                border.color: root.wallpaperDirectory + "/"
                                              + wallpaperTile.wallpaperName
                                              === root.currentWallpaper
                                    ? Lumen.Theme.primary
                                    : Lumen.Theme.outline

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + root.wallpaperDirectory + "/"
                                            + wallpaperTile.wallpaperName
                                    sourceSize: Qt.size(240, 160)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !wallpaperProcess.running
                                    onClicked: root.selectWallpaper(
                                        root.wallpaperDirectory + "/"
                                        + wallpaperTile.wallpaperName
                                    )
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------
                // FIXED VERTICAL SLIDERS
                // -------------------------------------------------

                Rectangle {
                    width: parent.width
                    height: 202
                    radius: 10
                    color: Qt.rgba(Lumen.Theme.surfaceContainerHigh.r,
                                   Lumen.Theme.surfaceContainerHigh.g,
                                   Lumen.Theme.surfaceContainerHigh.b, 0.85)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Repeater {
                            model: [
                                { name: "Brightness", icon: "monitor", key: "brightness" },
                                { name: "Speaker", icon: "volume-2", key: "speaker" },
                                { name: "Mic", icon: "mic", key: "mic" }
                            ]

                            delegate: VerticalSlider {
                                required property var modelData
                                width: (parent.width - 24) / 3
                                height: parent.height
                                label: modelData.name
                                iconName: modelData.icon
                                value: modelData.key === "brightness" ? root.brightness
                                    : modelData.key === "speaker" ? root.speaker
                                    : root.microphone
                                minimumValue: modelData.key === "brightness" ? 5 : 0
                                onValueEdited: value => root.setLevel(modelData.key, value)
                                onDragStarted: root.sliderDragging = true
                                onDragFinished: {
                                    root.flushPendingLevel()
                                    root.sliderDragging = false
                                }
                            }
                        }
                    }
                }

                // QUICK TOGGLES

                Row {
                    width: parent.width
                    spacing: 10

                    ToggleTile {
                        width: (parent.width - 10) / 2
                        title: "Do not disturb"
                        iconSource: Qt.resolvedUrl("../../assets/icons/moon.svg")
                        checked: Lumen.ControlCenterState.dndEnabled
                        onClicked: root.toggleDnd()
                    }

                    ToggleTile {
                        width: (parent.width - 10) / 2
                        title: "Keep display on"
                        iconSource: Qt.resolvedUrl("../../assets/icons/coffee.svg")
                        checked: Lumen.ControlCenterState.keepDisplayOn
                        onClicked: root.toggleDisplay()
                    }
                }

                // POWER

                Column {
                    width: parent.width
                    spacing: 11

                    Text {
                        text: "POWER"
                        color: Lumen.Theme.mutedForeground
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                    }

                    Row {
                        width: parent.width
                        spacing: 9

                        Repeater {
                            model: [
                                { name: "Logout", icon: "log-out" },
                                { name: "Restart", icon: "rotate-ccw" },
                                { name: "Shutdown", icon: "power" }
                            ]

                            delegate: Rectangle {
                                required property var modelData

                                width: (parent.width - 18) / 3
                                height: 64
                                radius: 19
                                color: Lumen.Theme.surfaceContainer

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Icon {
                                        width: 19
                                        height: 19
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: Qt.resolvedUrl("../../assets/icons/" + modelData.icon + ".svg")
                                    }

                                    Text {
                                        text: root.powerActionPending === modelData.name
                                            ? "Confirm?" : modelData.name
                                        color: Lumen.Theme.foreground
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.powerAction(modelData.name)
                                }
                            }
                        }
                    }
                }

                // NOTIFICATIONS

                Column {
                    width: parent.width
                    spacing: 11

                    Item {
                        width: parent.width
                        height: 36

                        Text {
                            text: root.notificationCount > 0
                                  ? "Notifications (" + root.notificationCount + ")"
                                  : "Notifications"
                            color: Lumen.Theme.foreground
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 68
                            height: 32
                            radius: 16
                            color: Lumen.Theme.surfaceContainerHigh
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: Lumen.Theme.foreground
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.clearNotifications()
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: Math.min(Math.max(contentHeight, 76), 210)
                        implicitHeight: 76
                        clip: true
                        spacing: 7
                        model: Lumen.ControlCenterState.notifications

                        delegate: Rectangle {
                            id: notificationRow
                            required property var modelData
                            width: ListView.view.width
                            height: 68
                            radius: 12
                            color: Lumen.Theme.surfaceContainerHigh

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: dismissButton.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: notificationRow.modelData.appName
                                        ? notificationRow.modelData.appName + " · "
                                          + notificationRow.modelData.summary
                                        : notificationRow.modelData.summary
                                    color: Lumen.Theme.foreground
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: notificationRow.modelData.body
                                    color: Lumen.Theme.mutedForeground
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                id: dismissButton
                                anchors.right: parent.right
                                anchors.rightMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                                radius: 8
                                color: dismissMouse.containsMouse
                                    ? Qt.rgba(Lumen.Theme.foreground.r,
                                              Lumen.Theme.foreground.g,
                                              Lumen.Theme.foreground.b, 0.1)
                                    : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Lumen.Theme.mutedForeground
                                    font.pixelSize: 17
                                }

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notificationRow.modelData.dismiss()
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.notificationCount === 0
                            text: "You're all caught up"
                            color: Lumen.Theme.mutedForeground
                            font.pixelSize: 12
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "LUMEN"
                    color: Lumen.Theme.outline
                    font.pixelSize: 9
                    font.letterSpacing: 3
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
