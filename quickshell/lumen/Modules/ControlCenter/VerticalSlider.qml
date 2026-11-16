import QtQuick
import "../.." as Lumen

Item {
    id: root

    property string label: ""
    property string iconName: ""
    property real value: 0
    property real minimumValue: 0
    signal valueEdited(real value)
    signal dragStarted()
    signal dragFinished()

    implicitWidth: 70
    implicitHeight: 176

    Column {
        anchors.fill: parent
        spacing: 7

        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: Qt.rgba(Lumen.Theme.surfaceContainerHigh.r,
                           Lumen.Theme.surfaceContainerHigh.g,
                           Lumen.Theme.surfaceContainerHigh.b, 0.9)
            anchors.horizontalCenter: parent.horizontalCenter

            Icon {
                anchors.centerIn: parent
                width: 17
                height: 17
                source: Qt.resolvedUrl("../../assets/icons/" + root.iconName + ".svg")
            }
        }

        Text {
            width: parent.width
            text: root.label
            color: Lumen.Theme.mutedForeground
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            id: sliderArea
            width: parent.width
            height: 112

            Rectangle {
                id: sliderTrack
                width: 43
                height: 108
                radius: 10
                anchors.centerIn: parent
                color: Qt.rgba(Lumen.Theme.surfaceContainerHigh.r,
                               Lumen.Theme.surfaceContainerHigh.g,
                               Lumen.Theme.surfaceContainerHigh.b, 0.9)
                clip: true

                Rectangle {
                    width: parent.width
                    height: Math.max(0, Math.min(parent.height,
                        parent.height * (root.value - root.minimumValue)
                        / (100 - root.minimumValue)))
                    anchors.bottom: parent.bottom
                    radius: 10
                    color: Lumen.Theme.primary
                    Behavior on height { NumberAnimation { duration: 100 } }
                }
            }

            Text {
                anchors.top: sliderTrack.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: sliderTrack.horizontalCenter
                text: Math.round(root.value) + "%"
                color: Lumen.Theme.foreground
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                preventStealing: true

                function updateValue(mouse) {
                    const point = mapToItem(sliderTrack, mouse.x, mouse.y)
                    const y = Math.max(0, Math.min(sliderTrack.height, point.y))
                    const value = 100 * (1 - y / sliderTrack.height)
                    root.valueEdited(Math.max(root.minimumValue, value))
                }

                onPressed: function(mouse) {
                    root.dragStarted()
                    updateValue(mouse)
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        updateValue(mouse)
                }
                onReleased: root.dragFinished()
                onCanceled: root.dragFinished()
            }
        }
    }
}
