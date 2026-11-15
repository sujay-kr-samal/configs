
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Modules/Launcher"
import "Modules/TopBar/workspace"
import "Modules/TopBar/DateTime"
import "Modules/TopBar/Right"
import "Modules/ControlCenter"

ShellRoot {
    id: root

    property bool launcherVisible: false
    property bool controlCenterVisible: false
    property alias theme: themeObject
    property color launcherPrimary: themeObject.primary
    property color launcherPrimaryContainer: themeObject.primaryContainer
    property color launcherBackground: themeObject.background
    property color launcherSurface: themeObject.surface
    property color launcherSurfaceContainer: themeObject.surfaceContainer
    property color launcherForeground: themeObject.foreground
    property color launcherMutedForeground: themeObject.mutedForeground
    property color launcherOutline: themeObject.outline
    property string cacheRoot: (Quickshell.env("XDG_CACHE_HOME")
        || (Quickshell.env("HOME") + "/.cache")) + "/lumen"

    function applyPalette(data) {
        try {
            const colors = data.colors
            themeObject.primary = colors.primary.dark.color
            themeObject.primaryContainer = colors.primary_container.dark.color
            themeObject.secondary = colors.secondary.dark.color
            themeObject.background = colors.background.dark.color
            themeObject.surface = colors.surface.dark.color
            themeObject.surfaceContainer = colors.surface_container.dark.color
            themeObject.foreground = colors.on_surface.dark.color
            themeObject.mutedForeground = colors.on_surface_variant.dark.color
            themeObject.outline = colors.outline.dark.color
        } catch (error) {
            console.warn("Could not apply Matugen palette:", error)
        }
    }

    QtObject {
        id: themeObject
        property color primary: "#8ce2bf"
        property color primaryContainer: "#29483c"
        property color secondary: "#b0ccc8"
        property color background: "#0e1514"
        property color surface: "#151b19"
        property color surfaceContainer: "#1a2120"
        property color foreground: "#dde4e2"
        property color mutedForeground: "#bec9c6"
        property color outline: "#3f4947"
    }

    FileView {
        id: paletteFile
        path: root.cacheRoot + "/matugen.json"
        watchChanges: true

        onLoaded: root.applyPalette(JSON.parse(paletteFile.text()))
        onLoadFailed: function(error) {
            console.warn("Could not load Matugen palette:", error)
        }
    }


    IpcHandler {
        target: "launcher"

        function toggle() {
            root.launcherVisible = !root.launcherVisible
        }

        function close() {
            root.launcherVisible = false
        }

        function toggleControlCenter() {
            root.controlCenterVisible = !root.controlCenterVisible
        }

        function closeControlCenter() {
            root.controlCenterVisible = false
        }
    }

    LauncherWindow {
        id: launcherWindow
        launcherVisible: root.launcherVisible
        primaryColor: root.launcherPrimary
        primaryContainerColor: root.launcherPrimaryContainer
        backgroundColor: root.launcherBackground
        surfaceColor: root.launcherSurface
        surfaceContainerColor: root.launcherSurfaceContainer
        foregroundColor: root.launcherForeground
        mutedForegroundColor: root.launcherMutedForeground
        outlineColor: root.launcherOutline
    }
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 48
            color: "transparent"

            Workspace {
                theme: root.theme
                anchors {
                    left: parent.left
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
            }

            DateTime {
                theme: root.theme
                anchors.centerIn: parent
            }

            Right {
                theme: root.theme
                anchors {
                    right: parent.right
                    rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                onOpenControlCenter: {
                    root.controlCenterVisible = !root.controlCenterVisible
                }
            }

            // Lumen Control Center
            PopupWindow {
                id: controlPopup

                anchor.window: bar
                anchor.rect.x: Math.max(12, bar.width - implicitWidth - 18)
                anchor.rect.y: bar.height + 8

                implicitWidth: Math.min(390, bar.screen.width - 24)
                implicitHeight: Math.min(750, bar.screen.height - bar.height - 20)

                color: "transparent"
                visible: root.controlCenterVisible
                grabFocus: true

                ControlCenter {
                    theme: root.theme
                    anchors.fill: parent
                    visible: root.controlCenterVisible

                    onWallpaperApplied: paletteFile.reload()

                    onCloseRequested: {
                        root.controlCenterVisible = false
                    }
                }
            }
        }
    }
}
