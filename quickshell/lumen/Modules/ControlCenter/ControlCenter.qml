
import QtQuick
import QtQuick.Controls
import QtQml
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal closeRequested()
    signal wallpaperApplied()

    property var theme: null
    property string wallpaperDirectory:
        Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string currentWallpaper: ""
    property string wallpaperMessage: "Choose a wallpaper"
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property bool dndEnabled: false
    property bool keepDisplayOn: false

    property string wifiName: "Checking..."
    property string bluetoothName: "No device connected"

    property real brightness: 41
    property real speaker: 17
    property real microphone: 100

    property int notificationCount: 0

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
            "sh",
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
        refreshProcess(wifiStatus)
        refreshProcess(wifiNameStatus)
        refreshProcess(bluetoothStatus)
        refreshProcess(bluetoothDeviceStatus)
        refreshProcess(brightnessStatus)
        refreshProcess(speakerStatus)
        refreshProcess(microphoneStatus)
        refreshProcess(dndStatus)
        refreshProcess(notificationStatus)
    }

    function setLevel(key, value) {
        value = Math.round(Math.max(0, Math.min(100, value)))

        if (key === "brightness") {
            brightness = value
            runCommand([
                "brightnessctl",
                "set", value + "%"
            ])
        } else if (key === "speaker") {
            speaker = value
            runCommand([
                "wpctl",
                "set-volume",
                "@DEFAULT_AUDIO_SINK@",
                (value / 100).toFixed(2)
            ])
        } else {
            microphone = value
            runCommand([
                "wpctl",
                "set-volume",
                "@DEFAULT_AUDIO_SOURCE@",
                (value / 100).toFixed(2)
            ])
        }
    }

    function toggleWifi() {
        wifiEnabled = !wifiEnabled
        runCommand([
            "nmcli",
            "radio",
            "wifi",
            wifiEnabled ? "on" : "off"
        ])
        refreshProcess(wifiStatus)
    }

    function toggleBluetooth() {
        bluetoothEnabled = !bluetoothEnabled
        runCommand([
            "bluetoothctl",
            "power",
            bluetoothEnabled ? "on" : "off"
        ])
        refreshProcess(bluetoothStatus)
    }

    function toggleDnd() {
        dndEnabled = !dndEnabled
        runCommand([
            "dunstctl",
            "set-paused",
            dndEnabled ? "true" : "false"
        ])
    }

    function toggleDisplay() {
        keepDisplayOn = !keepDisplayOn
    }

    function powerAction(action) {
        if (action === "Logout")
            runCommand(["hyprctl", "dispatch", "exit"])
        else if (action === "Restart")
            runCommand(["systemctl", "reboot"])
        else if (action === "Shutdown")
            runCommand(["systemctl", "poweroff"])
    }

    function clearNotifications() {
        runCommand(["dunstctl", "close-all"])
        runCommand(["dunstctl", "history-clear"])
        notificationCount = 0
        refreshProcess(notificationStatus)
    }

    // ---------------------------------------------------------
    // STATUS PROCESSES
    // ---------------------------------------------------------

    FolderListModel {
        id: wallpaperFiles
        folder: "file://" + root.wallpaperDirectory
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"]
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
        id: wifiStatus
        command: ["nmcli", "-t", "-f", "WIFI", "general"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled"
            }
        }
    }

    Process {
        id: wifiNameStatus
        command: [
            "nmcli", "-t",
            "-f", "NAME",
            "connection", "show", "--active"
        ]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                let name = ""

                for (let i = 0; i < lines.length; i++) {
                    let entry = lines[i].trim()

                    if (entry && entry !== "lo") {
                        name = entry
                        break
                    }
                }

                root.wifiName = name || "Not connected"
            }
        }
    }

    Process {
        id: bluetoothStatus
        command: ["bluetoothctl", "show"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.bluetoothEnabled =
                    text.indexOf("Powered: yes") !== -1
            }
        }
    }

    Process {
        id: bluetoothDeviceStatus
        command: ["bluetoothctl", "devices", "Connected"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                let name = "No device connected"

                if (lines.length > 0 &&
                    lines[0].trim().startsWith("Device ")) {
                    let parts = lines[0].trim().split(" ")
                    name = parts.slice(2).join(" ") || "Connected device"
                }

                root.bluetoothName = name
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

                    if (!isNaN(value))
                        root.brightness = value
                }
            }
        }
    }

    Process {
        id: speakerStatus
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let match = text.match(/Volume:\s*([0-9.]+)/)

                if (match)
                    root.speaker = Math.min(100, parseFloat(match[1]) * 100)
            }
        }
    }

    Process {
        id: microphoneStatus
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let match = text.match(/Volume:\s*([0-9.]+)/)

                if (match)
                    root.microphone = Math.min(100, parseFloat(match[1]) * 100)
            }
        }
    }

    Process {
        id: dndStatus
        command: ["dunstctl", "is-paused"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.dndEnabled = text.trim() === "true"
            }
        }
    }

    Process {
        id: notificationStatus
        command: ["dunstctl", "count", "displayed"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let count = parseInt(text.trim())
                root.notificationCount = isNaN(count) ? 0 : count
            }
        }
    }

    // Keep display inhibitor
    Process {
        id: displayInhibitor

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

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: root.refreshAll()
    }

    Component.onCompleted: refreshAll()

    // ---------------------------------------------------------
    // MAIN PANEL
    // ---------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        radius: 30
        color: root.theme
               ? Qt.rgba(root.theme.surface.r, root.theme.surface.g,
                 root.theme.surface.b, 0.97) : "#b8191a20"
        border.color: root.theme ? root.theme.outline : "#35ffffff"
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
                        color: "#555761"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Quick panel"
                        color: root.theme ? root.theme.foreground : "#f4f3f8"
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
                               ? (root.theme ? root.theme.primaryContainer : "#bcebd3")
                               : (root.theme ? root.theme.surfaceContainer : "#66363845")

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
                                        ? (root.theme ? root.theme.primary : "#86d5ac")
                                        : (root.theme ? root.theme.background : "#424b46")
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.centerIn: parent
                                    width: 21
                                    height: 21
                                    source: Qt.resolvedUrl("../../assets/icons/wifi.svg")
                                    sourceSize: Qt.size(21, 21)
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                width: parent.width - 105

                                Text {
                                    text: "Wi-Fi"
                                     color: root.wifiEnabled
                                         ? (root.theme ? root.theme.foreground : "#20352b")
                                         : (root.theme ? root.theme.foreground : "#f1f0f5")
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: root.wifiEnabled ? root.wifiName : "Off"
                                     color: root.theme
                                         ? root.theme.mutedForeground : "#a4ada7"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "›"
                                color: root.theme ? root.theme.primary : "#2b533f"
                                font.pixelSize: 24
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
                               ? (root.theme ? root.theme.primaryContainer : "#bcebd3")
                               : (root.theme ? root.theme.surfaceContainer : "#66363845")

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
                                        ? (root.theme ? root.theme.primary : "#86d5ac")
                                        : (root.theme ? root.theme.background : "#424b46")
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.centerIn: parent
                                    width: 21
                                    height: 21
                                    source: Qt.resolvedUrl("../../assets/icons/bluetooth.svg")
                                    sourceSize: Qt.size(21, 21)
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                width: parent.width - 105

                                Text {
                                    text: "Bluetooth"
                                     color: root.theme
                                         ? root.theme.foreground : "#f1f0f5"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: root.bluetoothEnabled ? root.bluetoothName : "Off"
                                     color: root.theme
                                         ? root.theme.mutedForeground : "#a4ada7"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "›"
                                color: root.theme ? root.theme.primary : "#2b533f"
                                font.pixelSize: 24
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
                                color: root.theme ? root.theme.foreground : "#f1f0f5"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: root.wallpaperMessage
                                color: root.theme
                                      ? root.theme.mutedForeground : "#a4a3af"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: wallpaperCount
                            width: implicitWidth
                            text: wallpaperFiles.count + " images"
                            color: root.theme
                                   ? root.theme.mutedForeground : "#a4a3af"
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
                                color: root.theme
                                       ? root.theme.surfaceContainer : "#252b2d"
                                border.width: root.wallpaperDirectory + "/"
                                              + wallpaperTile.wallpaperName
                                              === root.currentWallpaper ? 2 : 1
                                border.color: root.wallpaperDirectory + "/"
                                              + wallpaperTile.wallpaperName
                                              === root.currentWallpaper
                                    ? (root.theme ? root.theme.primary : "#8ce2bf")
                                    : (root.theme ? root.theme.outline : "#35ffffff")

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + root.wallpaperDirectory + "/"
                                            + wallpaperTile.wallpaperName
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
                    color: "#552b2d38"

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

                            delegate: Item {
                                id: sliderItem

                                required property var modelData

                                width: (parent.width - 24) / 3
                                height: parent.height

                                property real level:
                                    modelData.key === "brightness" ? root.brightness :
                                    modelData.key === "speaker" ? root.speaker :
                                    root.microphone

                                Column {
                                    anchors.fill: parent
                                    spacing: 7

                                    Rectangle {
                                        width: 34
                                        height: 34
                                        radius: 17
                                        color: "#554b4d59"
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Image {
                                            anchors.centerIn: parent
                                            width: 17
                                            height: 17
                                            source: Qt.resolvedUrl("../../assets/icons/" + sliderItem.modelData.icon + ".svg")
                                            sourceSize: Qt.size(17, 17)
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: sliderItem.modelData.name
                                        color: "#c1c0ca"
                                        font.pixelSize: 10
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Slider touch area
                                    Item {
                                        id: sliderArea

                                        width: parent.width
                                        height: 112

                                        // Rounded track
                                        Rectangle {
                                            id: sliderTrack

                                            width: 43
                                            height: 108
                                            radius: 10
                                            anchors.centerIn: parent

                                            color: "#554b4d59"

                                            // Prevent fill from escaping the track
                                            clip: true

                                            Rectangle {
                                                id: sliderFill

                                                width: parent.width
                                                height: Math.max(
                                                    0,
                                                    Math.min(
                                                        parent.height,
                                                        parent.height * sliderItem.level / 100
                                                    )
                                                )

                                                anchors.bottom: parent.bottom

                                                radius: 10

                                                      color: root.theme
                                                          ? root.theme.primary : "#8ce2bf"

                                                Behavior on height {
                                                    NumberAnimation {
                                                        duration: 100
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.top: sliderTrack.bottom
                                            anchors.topMargin: 8
                                            anchors.horizontalCenter: sliderTrack.horizontalCenter

                                            text: Math.round(sliderItem.level) + "%"
                                            color: "#ffffff"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }

                                        // Drag handler
                                        MouseArea {
                                            id: sliderMouse

                                            anchors.fill: parent

                                            acceptedButtons: Qt.LeftButton

                                            // Prevent parent Flickable from
                                            // stealing the slider drag.
                                            preventStealing: true

                                            function updateSlider(mouse) {
                                                let point = mapToItem(
                                                    sliderTrack,
                                                    mouse.x,
                                                    mouse.y
                                                )

                                                let y = Math.max(
                                                    0,
                                                    Math.min(
                                                        sliderTrack.height,
                                                        point.y
                                                    )
                                                )

                                                let newValue =
                                                    100 * (1 - y / sliderTrack.height)

                                                root.setLevel(
                                                    sliderItem.modelData.key,
                                                    newValue
                                                )
                                            }

                                            onPressed: function(mouse) {
                                                updateSlider(mouse)
                                            }

                                            onPositionChanged: function(mouse) {
                                                if (pressed)
                                                    updateSlider(mouse)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // QUICK TOGGLES

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 62
                        radius: 20
                           color: root.dndEnabled
                               ? (root.theme ? root.theme.primaryContainer : "#bcebd3")
                               : (root.theme ? root.theme.surfaceContainer : "#66363845")

                        Row {
                            anchors.centerIn: parent
                            spacing: 9

                            Image {
                                width: 19
                                height: 19
                                anchors.verticalCenter: parent.verticalCenter
                                source: Qt.resolvedUrl("../../assets/icons/moon.svg")
                                sourceSize: Qt.size(19, 19)
                            }

                            Text {
                                text: "Do not disturb"
                                color: root.theme ? root.theme.foreground : "#eeeeF4"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleDnd()
                        }
                    }

                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 62
                        radius: 20
                           color: root.keepDisplayOn
                               ? (root.theme ? root.theme.primaryContainer : "#bcebd3")
                               : (root.theme ? root.theme.surfaceContainer : "#66363845")

                        Row {
                            anchors.centerIn: parent
                            spacing: 9

                            Image {
                                width: 19
                                height: 19
                                anchors.verticalCenter: parent.verticalCenter
                                source: Qt.resolvedUrl("../../assets/icons/coffee.svg")
                                sourceSize: Qt.size(19, 19)
                            }

                            Text {
                                text: "Keep display on"
                                color: root.theme ? root.theme.foreground : "#eeeeF4"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleDisplay()
                        }
                    }
                }

                // POWER

                Column {
                    width: parent.width
                    spacing: 11

                    Text {
                        text: "POWER"
                        color: "#858590"
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
                                color: "#66363845"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Image {
                                        width: 19
                                        height: 19
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: Qt.resolvedUrl("../../assets/icons/" + modelData.icon + ".svg")
                                        sourceSize: Qt.size(19, 19)
                                    }

                                    Text {
                                        text: modelData.name
                                        color: "#eeeeF4"
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
                            color: "#f1f0f5"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 68
                            height: 32
                            radius: 16
                            color: "#55444855"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.clearNotifications()
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 20
                        color: "#552b2d38"

                        Column {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: root.notificationCount > 0
                                      ? root.notificationCount + " notification(s) active"
                                      : "No notifications"
                                color: "#d4d3dc"
                                font.pixelSize: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: root.notificationCount > 0
                                      ? "Use Clear all to dismiss"
                                      : "You're all caught up"
                                color: "#858590"
                                font.pixelSize: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "LUMEN"
                    color: "#686a76"
                    font.pixelSize: 9
                    font.letterSpacing: 3
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
