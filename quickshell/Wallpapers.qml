import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Layouts

// Toggle with:  qs ipc call wallpapers toggle
Scope {
    id: picker
    property bool open: false

    // folder with your wallpapers
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/set-wallpaper.sh"

    // path of the wallpaper that is currently set
    property string current: ""

    // true when the focused workspace has at least one window
    readonly property bool hasWindows:
        (Hyprland.focusedWorkspace?.toplevels?.values?.length ?? 0) > 0

    FileView {
        id: currentFile
        path: Quickshell.env("HOME") + "/.cache/current-wall"
        onLoaded: picker.current = text().trim()
    }

    onOpenChanged: if (open) currentFile.reload()

    IpcHandler {
        target: "wallpapers"
        function toggle(): void { picker.open = !picker.open }
        function show(): void { picker.open = true }
        function hide(): void { picker.open = false }
    }

    function apply(path) {
        if (!path) return;
        Quickshell.execDetached([picker.script, path]);
        picker.current = path;
        picker.open = false;
    }

    LazyLoader {
        active: picker.open

        PanelWindow {
            id: win
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-wallpapers"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // click outside the panel to close
            MouseArea {
                anchors.fill: parent
                onClicked: picker.open = false
            }

            FolderListModel {
                id: folderModel
                folder: "file://" + picker.dir
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                caseSensitive: false
                showDirs: false
                sortField: FolderListModel.Name
            }

            Rectangle {
                id: panel
                width: Math.min(parent.width - 80, 1000)
                height: 190
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                radius: 26
                color: Qt.alpha(Colors.container, picker.hasWindows ? 0.96 : 0.55)
                border.color: Colors.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: 250 } }

                // open animation (grows up from the bottom)
                property bool shown: false
                Component.onCompleted: { shown = true; list.forceActiveFocus(); }
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.96
                transformOrigin: Item.Bottom
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // swallow clicks so they don't close the picker
                MouseArea { anchors.fill: parent }

                // empty-folder hint
                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No images found in " + picker.dir
                    color: Colors.textDimTint
                    font.pixelSize: 14
                }

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: 14
                    orientation: ListView.Horizontal
                    clip: true
                    model: folderModel
                    currentIndex: 0
                    highlightMoveDuration: 120
                    boundsBehavior: Flickable.StopAtBounds
                    focus: true

                    // mouse wheel scrolls sideways
                    WheelHandler {
                        onWheel: event => {
                            const max = Math.max(0, list.contentWidth - list.width);
                            list.contentX = Math.max(0, Math.min(max, list.contentX - event.angleDelta.y));
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            picker.open = false;
                        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                            list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                            list.currentIndex = Math.max(list.currentIndex - 1, 0);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            picker.apply(folderModel.get(list.currentIndex, "filePath"));
                            event.accepted = true;
                        }
                    }

                    delegate: Item {
                        id: card
                        required property int index
                        required property url fileUrl
                        required property string filePath
                        required property string fileName
                        readonly property bool selected: ListView.isCurrentItem
                        readonly property bool isCurrent: picker.current === filePath

                        width: 272
                        height: list.height

                        scale: selected ? 1.0 : 0.95
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: 18
                            color: Colors.surface
                            border.width: (card.selected || card.isCurrent) ? 2 : 1
                            border.color: card.selected ? Colors.primary
                                        : (card.isCurrent ? Qt.alpha(Colors.primary, 0.6) : Colors.border)
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Image {
                                anchors.fill: parent
                                source: card.fileUrl
                                sourceSize: Qt.size(544, 306)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            // name strip
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 26
                                color: Qt.alpha("black", 0.5)
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: Text.AlignVCenter
                                    text: card.fileName
                                    elide: Text.ElideMiddle
                                    font.pixelSize: 11
                                    color: "white"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = card.index
                            onClicked: picker.apply(card.filePath)
                        }
                    }
                }
            }
        }
    }
}
