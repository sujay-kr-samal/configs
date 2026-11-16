
import QtQuick
import Quickshell
import "../../.." as Lumen

Item {
    id: root

    property string timeText: Qt.formatDateTime(clock.date, "h:mm AP")
    property string dateText: Qt.formatDateTime(clock.date, "ddd, d MMM")

    implicitWidth: clockRow.implicitWidth + 24
    implicitHeight: 34

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2

                color: Qt.rgba(Lumen.Theme.surface.r, Lumen.Theme.surface.g,
                                             Lumen.Theme.surface.b, 0.88)
        border.width: 1
                border.color: Lumen.Theme.outline
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 9

        Text {
            text: root.timeText
            color: Lumen.Theme.foreground
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 14
            radius: 1
            color: Lumen.Theme.outline
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.dateText
            color: Lumen.Theme.mutedForeground
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
