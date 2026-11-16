import QtQuick

Rectangle {
    id: root

    default property alias content: contentHost.data
    property alias contentHost: contentHost
    property bool clickable: false
    property bool hovered: false
    signal clicked()

    Item {
        id: contentHost
        anchors.fill: parent
    }

    TapHandler {
        target: root
        enabled: root.clickable
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
    }

    HoverHandler {
        target: root
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: root.hovered = hovered
    }

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
}
