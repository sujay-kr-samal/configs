pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Reads ~/.cache/qs-colors.json (written by matugen) and reloads whenever it changes.
Singleton {
    id: root

    property color primary: "#f5a9d8"
    property color surface: "#16131a"
    property color container: "#2a2630"
    property color text: "#e6e0e9"
    property color textDim: "#cbc4d0"
    property color outline: "#49454f"

    // derived
    readonly property color pill: Qt.alpha(container, 0.55)
    readonly property color border: Qt.alpha(outline, 0.7)
    readonly property color textTint:    Qt.tint(text,    Qt.alpha(primary, 0.45))
    readonly property color textDimTint: Qt.tint(textDim, Qt.alpha(primary, 0.35))

    Behavior on primary   { ColorAnimation { duration: 500 } }
    Behavior on container { ColorAnimation { duration: 500 } }
    Behavior on text      { ColorAnimation { duration: 500 } }
    Behavior on textDim   { ColorAnimation { duration: 500 } }
    Behavior on outline   { ColorAnimation { duration: 500 } }

    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.cache/qs-colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                root.primary   = c.primary;
                root.surface   = c.surface;
                root.container = c.container;
                root.text      = c.on_surface;
                root.textDim   = c.on_surface_variant;
                root.outline   = c.outline_variant;
            } catch (e) {
                console.log("colors parse error:", e);
            }
        }
    }

    // matugen swaps the file atomically, so poll as a safety net
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: colorFile.reload()
    }
}
