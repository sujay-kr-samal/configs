import QtQuick
import "../.." as Lumen

Rectangle {
    id: root

    property string title: ""
    property url iconSource
    property bool checked: false
    signal clicked()

    width: 0
    height: 62
    radius: 20
    color: checked ? Lumen.Theme.primaryContainer : Lumen.Theme.surfaceContainer

    Row {
        anchors.centerIn: parent
        spacing: 9

        Icon {
            width: 19
            height: 19
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconSource
            tint: root.checked
                ? Lumen.Theme.primaryContainerText
                : Lumen.Theme.foreground
        }

        Text {
            text: root.title
            color: root.checked
                ? Lumen.Theme.primaryContainerText
                : Lumen.Theme.foreground
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
