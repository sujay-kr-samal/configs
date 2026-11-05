import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Toggle with:  qs ipc call launcher toggle
Scope {
    id: launcher
    property bool open: false

    // true when the focused workspace has at least one window
    readonly property bool hasWindows:
        (Hyprland.focusedWorkspace?.toplevels?.values?.length ?? 0) > 0

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.open = !launcher.open }
        function show(): void { launcher.open = true }
        function hide(): void { launcher.open = false }
    }

    // window is created on open and destroyed on close, so search resets every time
    LazyLoader {
        active: launcher.open

        PanelWindow {
            id: win
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // click outside the panel to close
            MouseArea {
                anchors.fill: parent
                onClicked: launcher.open = false
            }

            readonly property int rowH: 52
            readonly property int maxRows: 7
            readonly property int bottomGap: 24

            // filtered + ranked results
            readonly property var results: {
                const q = search.text.toLowerCase().trim();
                const all = DesktopEntries.applications.values;
                const list = all.filter(a => {
                    if (a.noDisplay) return false;
                    if (q === "") return true;
                    const hay = (a.name + " " + (a.genericName ?? "") + " " + (a.keywords ?? []).join(" ")).toLowerCase();
                    return hay.includes(q);
                });
                list.sort((a, b) => {
                    const an = a.name.toLowerCase(), bn = b.name.toLowerCase();
                    if (q !== "") {
                        const as = an.startsWith(q) ? 0 : 1;
                        const bs = bn.startsWith(q) ? 0 : 1;
                        if (as !== bs) return as - bs;
                    }
                    return an.localeCompare(bn);
                });
                return list;
            }

            function launch(entry) {
                if (!entry) return;
                entry.execute();
                launcher.open = false;
            }

            Rectangle {
                id: panel
                width: 560
                height: searchBox.height + (list.count > 0 ? list.height + 10 : 0) + 28
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: win.bottomGap
                radius: 26
                // solid-ish over apps, translucent (same as the pills) on an empty workspace
                color: Qt.alpha(Colors.container, launcher.hasWindows ? 0.96 : 0.55)
                border.color: Colors.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: 250 } }

                // open animation (grows up from the bottom)
                property bool shown: false
                Component.onCompleted: { shown = true; search.forceActiveFocus(); }
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.96
                transformOrigin: Item.Bottom
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 120 } }

                // swallow clicks so they don't close the launcher
                MouseArea { anchors.fill: parent }

                // ---------- results (above the search box) ----------
                ListView {
                    id: list
                    anchors.bottom: searchBox.top
                    anchors.bottomMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    height: Math.min(count, win.maxRows) * win.rowH
                    visible: count > 0
                    clip: true
                    // best match sits right next to the search box
                    verticalLayoutDirection: ListView.BottomToTop
                    model: win.results
                    currentIndex: 0
                    highlightMoveDuration: 80
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: ListView.isCurrentItem

                        width: list.width
                        height: win.rowH
                        radius: 16
                        color: selected ? Qt.alpha(Colors.primary, 0.18)
                                        : (hover.hovered ? Qt.alpha(Colors.primary, 0.08) : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }

                        HoverHandler {
                            id: hover
                            onHoveredChanged: if (hovered) list.currentIndex = row.index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 14

                            IconImage {
                                implicitSize: 32
                                source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    elide: Text.ElideRight
                                    font.pixelSize: 15
                                    font.bold: row.selected
                                    color: row.selected ? Colors.primary : Colors.textTint
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: row.modelData.comment ?? row.modelData.genericName ?? ""
                                    elide: Text.ElideRight
                                    font.pixelSize: 11
                                    color: Colors.textDimTint
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.launch(row.modelData)
                        }
                    }
                }

                // ---------- search box (bottom) ----------
                Rectangle {
                    id: searchBox
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 14
                    height: 46
                    radius: height / 2
                    color: Qt.alpha(Colors.surface, launcher.hasWindows ? 0.55 : 0.35)
                    border.color: search.activeFocus ? Colors.primary : Colors.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        Text {
                            text: "\uf002"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 15
                            color: Colors.primary
                        }

                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            color: Colors.textTint
                            selectionColor: Colors.primary
                            selectedTextColor: Colors.surface
                            font.pixelSize: 16
                            clip: true
                            focus: true
                            onTextChanged: list.currentIndex = 0

                            Text {
                                visible: search.text === ""
                                text: "Search apps…"
                                color: Colors.textDimTint
                                font.pixelSize: 16
                            }

                            // list grows upward: Up = further results, Down = back toward the search box
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    launcher.open = false;
                                } else if (event.key === Qt.Key_Up
                                           || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P)
                                           || event.key === Qt.Key_Tab) {
                                    list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down
                                           || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N)
                                           || event.key === Qt.Key_Backtab) {
                                    list.currentIndex = Math.max(list.currentIndex - 1, 0);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    win.launch(win.results[list.currentIndex]);
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
