import QtQuick
import QtQuick.Effects
import "../.." as Lumen

Item {
    id: root

    property url source
    property color tint: Lumen.Theme.foreground

    Image {
        id: sourceImage
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: sourceImage
        colorization: 1
        colorizationColor: root.tint
    }
}