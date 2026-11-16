import QtQuick
import Quickshell.Services.Notifications
import "../../.." as Lumen

Item {
    id: root

    property alias inputRegionItem: toastColumn
    implicitWidth: 420
    implicitHeight: Math.min(toastColumn.implicitHeight + 60, 600)
    visible: !Lumen.ControlCenterState.dndEnabled

    Column {
        id: toastColumn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 60
        anchors.rightMargin: 18
        width: Math.min(396, parent.width - 36)
        spacing: 12

        Repeater {
            model: {
                const notifications = Lumen.ControlCenterState.notifications.values || []
                const toastIds = Lumen.ControlCenterState.toastNotificationIds
                return notifications.filter(notification => notification
                    && toastIds.includes(notification.id))
            }

            delegate: Rectangle {
                id: toast
                required property var modelData
                property var notification: modelData
                property bool toastVisible: true
                visible: toastVisible
                width: toastColumn.width
                implicitHeight: toastContent.implicitHeight + 40
                radius: 16
                color: Qt.rgba(Lumen.Theme.surface.r, Lumen.Theme.surface.g,
                               Lumen.Theme.surface.b, 0.96)
                border.width: 1
                border.color: notification.urgency === NotificationUrgency.Critical
                    ? Qt.rgba(Lumen.Theme.error.r, Lumen.Theme.error.g,
                              Lumen.Theme.error.b, 0.72)
                    : Qt.rgba(Lumen.Theme.outline.r, Lumen.Theme.outline.g,
                              Lumen.Theme.outline.b, 0.5)

                Rectangle {
                    width: 3
                    radius: 2
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    color: toast.notification.urgency === NotificationUrgency.Critical
                        ? Lumen.Theme.error : Lumen.Theme.primary
                }

                Column {
                    id: toastContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    anchors.top: parent.top
                    anchors.topMargin: 22
                    anchors.bottomMargin: 18
                    spacing: 10

                    Image {
                        width: parent.width
                        height: toast.notification.image ? 64 : 0
                        visible: !!toast.notification.image
                        source: toast.notification.image
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        width: parent.width
                        text: toast.notification.appName || "Notification"
                        color: Lumen.Theme.mutedForeground
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: toast.notification.summary
                        color: Lumen.Theme.foreground
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        visible: toast.notification.body.length > 0
                        text: toast.notification.body
                        color: Lumen.Theme.mutedForeground
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        maximumLineCount: 5
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Repeater {
                            model: (toast.notification.actions || [])
                                .filter(action => action !== null)
                            delegate: Rectangle {
                                required property var modelData
                                width: actionLabel.implicitWidth + 20
                                height: 28
                                radius: 8
                                color: actionMouse.containsMouse
                                    ? Lumen.Theme.primaryContainer
                                    : Qt.rgba(Lumen.Theme.primary.r,
                                              Lumen.Theme.primary.g,
                                              Lumen.Theme.primary.b, 0.12)

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: parent.modelData.text
                                    color: Lumen.Theme.primaryContainerText
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        parent.modelData.invoke()
                                        toast.toastVisible = false
                                        Lumen.ControlCenterState.removeNotificationToast(
                                            toast.notification.id
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: closeButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    anchors.rightMargin: 4
                    width: 28
                    height: 28
                    radius: 8
                    color: closeMouse.containsMouse
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
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Lumen.ControlCenterState.removeNotificationToast(
                                toast.notification.id
                            )
                            toast.notification.dismiss()
                        }
                    }

                    Timer {
                        interval: 3000
                        repeat: false
                        running: toast.toastVisible
                        onTriggered: {
                            toast.toastVisible = false
                            Lumen.ControlCenterState.removeNotificationToast(
                                toast.notification.id
                            )
                        }
                    }
                }
            }
        }
    }
}
