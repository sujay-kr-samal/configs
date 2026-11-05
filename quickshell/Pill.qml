import QtQuick
import QtQuick.Layouts

Rectangle {
    id: pill
    default property alias content: row.data
    property int padding: 12
    property int spacing: 10
    property real bgAlpha: 0.55

    implicitHeight: 30
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    color: Qt.alpha(Colors.container, bgAlpha)
    border.color: Colors.border
    border.width: 1

    Behavior on bgAlpha { NumberAnimation { duration: 250 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: pill.spacing
    }
}
