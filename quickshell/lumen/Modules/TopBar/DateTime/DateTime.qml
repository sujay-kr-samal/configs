
import QtQuick

Item {
    id: root

    property var theme: null
    property string timeText: ""
    property string dateText: ""

    implicitWidth: clockRow.implicitWidth + 24
    implicitHeight: 34

    function updateClock() {
        const now = new Date()
        timeText = Qt.formatDateTime(now, "h:mm AP")
        dateText = Qt.formatDateTime(now, "ddd, d MMM")
    }

    Component.onCompleted: updateClock()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2

        color: root.theme
               ? Qt.rgba(root.theme.surface.r, root.theme.surface.g,
                 root.theme.surface.b, 0.88) : "#55202020"
        border.width: 1
        border.color: root.theme ? root.theme.outline : "#30ffffff"
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 9

        Text {
            text: root.timeText
            color: root.theme ? root.theme.foreground : "#ffffff"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 14
            radius: 1
            color: "#666666"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.dateText
            color: root.theme ? root.theme.mutedForeground : "#c0c0c0"
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
