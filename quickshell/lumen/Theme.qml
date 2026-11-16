pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property color primary: "#8ce2bf"
    property color primaryContainer: "#29483c"
    property color primaryText: "#003829"
    property color primaryContainerText: "#b3f1d5"
    property color secondary: "#b0ccc8"
    property color tertiary: "#a4cdbd"
    property color error: "#ffb4ab"
    property color background: "#0e1514"
    property color surface: "#151b19"
    property color surfaceContainer: "#1a2120"
    property color surfaceContainerHigh: "#252b29"
    property color foreground: "#dde4e2"
    property color mutedForeground: "#bec9c6"
    property color outline: "#3f4947"
    property bool animate: false

    property string cacheRoot: (Quickshell.env("XDG_CACHE_HOME")
        || (Quickshell.env("HOME") + "/.cache")) + "/lumen"

    function applyPalette(data) {
        try {
            const colors = data.colors
            root.primary = colors.primary.dark.color
            root.primaryContainer = colors.primary_container.dark.color
            root.primaryText = colors.on_primary.dark.color
            root.primaryContainerText = colors.on_primary_container.dark.color
            root.secondary = colors.secondary.dark.color
            root.tertiary = colors.tertiary.dark.color
            root.error = colors.error.dark.color
            root.background = colors.background.dark.color
            root.surface = colors.surface.dark.color
            root.surfaceContainer = colors.surface_container.dark.color
            root.surfaceContainerHigh = colors.surface_container_high.dark.color
            root.foreground = colors.on_surface.dark.color
            root.mutedForeground = colors.on_surface_variant.dark.color
            root.outline = colors.outline.dark.color
        } catch (error) {
            console.warn("Could not apply Matugen palette:", error)
        }
    }

    function reloadPalette() {
        paletteFile.reload()
    }

    Behavior on primary { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on primaryContainer { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on primaryText { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on primaryContainerText { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on secondary { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on tertiary { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on error { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on background { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on surface { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on surfaceContainer { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on surfaceContainerHigh { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on foreground { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on mutedForeground { enabled: root.animate; ColorAnimation { duration: 1000 } }
    Behavior on outline { enabled: root.animate; ColorAnimation { duration: 1000 } }

    FileView {
        id: paletteFile
        path: root.cacheRoot + "/matugen.json"
        watchChanges: true

        onLoaded: {
            try {
                root.applyPalette(JSON.parse(paletteFile.text()))
                root.animate = true
            } catch (error) {
                console.warn("Could not parse Matugen palette:", error)
            }
        }

        onLoadFailed: function(error) {
            console.warn("Could not load Matugen palette:", error)
        }
    }
}