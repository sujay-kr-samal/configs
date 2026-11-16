
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.." as Lumen

Item {
    id: root

    signal closeRequested()

    property string searchText: ""
    property int selectedIndex: 0
    property bool registryReady: false
    property var filteredApps: []
    property var usageData: ({})
    property bool usageLoaded: false

    FontLoader {
        id: interfaceFont
        source: "../../assets/fonts/InterVariable.ttf"
    }

    FileView {
        id: usageFile
        path: (Quickshell.env("XDG_CACHE_HOME")
            || (Quickshell.env("HOME") + "/.cache")) + "/lumen/app-usage.json"
        watchChanges: false

        onLoaded: {
            try {
                root.usageData = JSON.parse(usageFile.text())
            } catch (error) {
                root.usageData = ({})
            }
            root.usageLoaded = true
            root.refreshApps()
        }

        onLoadFailed: {
            root.usageData = ({})
            root.usageLoaded = true
            usageFile.setText("{}")
            usageFile.writeAdapter()
        }
    }

    function prepareForOpen() {
        searchField.clear()
        searchText = ""
        selectedIndex = 0
        refreshApps()
        searchField.forceActiveFocus()
    }

    function clearSearchFocus() {
        searchField.focus = false
    }

    function matchScore(app, query) {
        const name = (app.name || "").toLowerCase()
        const genericName = (app.genericName || "").toLowerCase()
        const comment = (app.comment || "").toLowerCase()
        const keywords = (app.keywords || []).map(value => value.toLowerCase())
        const searchable = [name, genericName, comment, ...keywords]
        const words = query.split(/\s+/).filter(word => word.length > 0)
        let score = 0
        let fuzzyMatches = 0

        for (const word of words) {
            let wordScore = Number.POSITIVE_INFINITY

            for (const field of searchable) {
                if (!field)
                    continue
                if (field === word)
                    wordScore = Math.min(wordScore, 0)
                else if (field.startsWith(word))
                    wordScore = Math.min(wordScore, 100)
                else if (field.includes(" " + word))
                    wordScore = Math.min(wordScore, 200)
                else if (field.includes(word))
                    wordScore = Math.min(wordScore, 300)
                else {
                    const fuzzyScore = root.fuzzySubsequenceScore(field, word)
                    if (fuzzyScore >= 0)
                        wordScore = Math.min(wordScore,
                            400 + Math.min(0.99, fuzzyScore / 100))
                }
            }

            if (!Number.isFinite(wordScore))
                return -1

            if (wordScore >= 400)
                fuzzyMatches++
            score += wordScore
        }

        return { fuzzyMatches: fuzzyMatches, score: score }
    }

    function fuzzySubsequenceScore(candidate, query) {
        let candidateIndex = 0
        let gapScore = 0
        let previousIndex = -1

        for (const character of query) {
            const foundIndex = candidate.indexOf(character, candidateIndex)
            if (foundIndex < 0)
                return -1
            if (previousIndex >= 0)
                gapScore += foundIndex - previousIndex - 1
            else
                gapScore += foundIndex
            previousIndex = foundIndex
            candidateIndex = foundIndex + 1
        }

        return gapScore + Math.max(0, candidate.length - query.length) * 0.05
    }

    function recordLaunch(app) {
        if (!usageLoaded)
            return
        const entry = usageData[app.id] || { count: 0, lastLaunched: 0 }
        usageData[app.id] = {
            count: entry.count + 1,
            lastLaunched: Date.now()
        }
        usageFile.setText(JSON.stringify(usageData))
        usageFile.writeAdapter()
    }

    function refreshApps() {
        const apps = DesktopEntries.applications.values || []
        const query = searchText.trim().toLowerCase()
        const matches = []

        for (const app of apps) {
            if (!app || !app.name)
                continue

            const score = query.length > 0
                ? matchScore(app, query)
                : { fuzzyMatches: 0, score: 0 }
            if (score !== -1)
                matches.push({ app: app, fuzzyMatches: score.fuzzyMatches, score: score.score })
        }

        matches.sort((left, right) => {
            if (left.fuzzyMatches !== right.fuzzyMatches)
                return left.fuzzyMatches - right.fuzzyMatches
            if (left.score !== right.score)
                return left.score - right.score
            const leftUsage = usageData[left.app.id] || { count: 0, lastLaunched: 0 }
            const rightUsage = usageData[right.app.id] || { count: 0, lastLaunched: 0 }
            if (leftUsage.count !== rightUsage.count)
                return rightUsage.count - leftUsage.count
            if (leftUsage.lastLaunched !== rightUsage.lastLaunched)
                return rightUsage.lastLaunched - leftUsage.lastLaunched
            return left.app.name.localeCompare(right.app.name)
        })

        filteredApps = matches.map(match => match.app)
        selectedIndex = 0
        appList.currentIndex = filteredApps.length > 0 ? 0 : -1
    }

    function launchApp(index) {
        if (index < 0 || index >= filteredApps.length)
            return

        try {
            recordLaunch(filteredApps[index])
            filteredApps[index].execute()
            closeRequested()
        } catch (error) {
            console.warn("Could not launch application:", error)
        }
    }

    onSelectedIndexChanged: {
        if (appList.count > 0) {
            appList.currentIndex = selectedIndex
            appList.positionViewAtIndex(selectedIndex, ListView.Contain)
        }
    }

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged() {
            root.registryReady = true
            root.refreshApps()
        }
    }

    Timer {
        interval: 1200
        running: true
        repeat: false
        onTriggered: root.registryReady = true
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Lumen.Theme.surface
        border.color: Lumen.Theme.outline
        border.width: 1
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Item {
                width: parent.width
                height: 42

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Applications"
                        color: Lumen.Theme.foreground
                        font.family: interfaceFont.name
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Find something to open"
                        color: Lumen.Theme.mutedForeground
                        font.family: interfaceFont.name
                        font.pixelSize: 11
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.registryReady
                        ? filteredApps.length + " APPS"
                        : "SCANNING"
                    color: Lumen.Theme.mutedForeground
                    font.family: interfaceFont.name
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                id: searchBox
                width: parent.width
                height: 54
                radius: 13
                color: searchField.activeFocus
                    ? Lumen.Theme.surfaceContainer : Lumen.Theme.background
                border.color: searchField.activeFocus
                    ? Lumen.Theme.primary : Lumen.Theme.outline
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 17
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    color: Lumen.Theme.primary
                    font.family: interfaceFont.name
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                TextField {
                    id: searchField

                    anchors.fill: parent
                    anchors.leftMargin: 40
                    anchors.rightMargin: text.length > 0 ? 72 : 14
                    placeholderText: "Search apps, names, descriptions..."
                    color: Lumen.Theme.foreground
                    placeholderTextColor: Lumen.Theme.mutedForeground
                    selectionColor: Lumen.Theme.primary
                    selectedTextColor: Lumen.Theme.background
                    font.family: interfaceFont.name
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter

                    background: Rectangle {
                        color: "transparent"
                        border.width: 0
                    }

                    onTextChanged: {
                        root.searchText = text
                        root.refreshApps()
                    }

                    Keys.onEscapePressed: root.closeRequested()
                    Keys.onDownPressed: {
                        event.accepted = true
                        if (root.selectedIndex < appList.count - 1)
                            root.selectedIndex++
                    }
                    Keys.onUpPressed: {
                        event.accepted = true
                        if (root.selectedIndex > 0)
                            root.selectedIndex--
                    }
                    Keys.onReturnPressed: root.launchApp(root.selectedIndex)
                    Keys.onEnterPressed: root.launchApp(root.selectedIndex)
                }

                Button {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 56
                    height: 36
                    visible: searchField.text.length > 0
                    text: "Clear"
                    font.family: interfaceFont.name
                    font.pixelSize: 11
                    onClicked: {
                        searchField.clear()
                        searchField.forceActiveFocus()
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Lumen.Theme.primary
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.down ? Lumen.Theme.primaryContainer : "transparent"
                        radius: 8
                    }
                }
            }

            ListView {
                id: appList

                width: parent.width
                height: Math.max(0, parent.height - 42 - searchBox.height
                    - parent.spacing * 3 - footer.height)
                clip: true
                spacing: 4
                model: root.filteredApps
                currentIndex: root.selectedIndex
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    id: appRow
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: 64

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: root.selectedIndex === appRow.index
                            ? Lumen.Theme.primaryContainer
                            : rowMouse.containsMouse
                                ? Qt.rgba(Lumen.Theme.foreground.r,
                                          Lumen.Theme.foreground.g,
                                          Lumen.Theme.foreground.b, 0.12)
                                : "transparent"
                        border.color: root.selectedIndex === appRow.index
                            ? Lumen.Theme.primary : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 110 } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 40
                            radius: 10
                            color: Lumen.Theme.background

                            Image {
                                id: appIcon
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                source: {
                                    const icon = appRow.modelData.icon
                                    return icon ? Quickshell.iconPath(icon, true) : ""
                                }
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appIcon.status !== Image.Ready
                                text: (appRow.modelData.name || "?").slice(0, 1).toUpperCase()
                                color: Lumen.Theme.primary
                                font.family: interfaceFont.name
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 62
                            anchors.right: parent.right
                            anchors.rightMargin: 42
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: parent.width
                                text: appRow.modelData.name || "Unnamed application"
                                color: Lumen.Theme.foreground
                                font.family: interfaceFont.name
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: appRow.modelData.genericName
                                    || appRow.modelData.comment || "Application"
                                color: Lumen.Theme.mutedForeground
                                font.family: interfaceFont.name
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.selectedIndex === appRow.index
                            text: "Enter"
                            color: Lumen.Theme.mutedForeground
                            font.family: interfaceFont.name
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: root.selectedIndex = appRow.index
                            onClicked: root.launchApp(appRow.index)
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, 300)
                    spacing: 6
                    visible: appList.count === 0

                    Text {
                        width: parent.width
                        text: root.registryReady
                            ? (root.searchText.length > 0
                                ? "No matching applications" : "No applications found")
                            : "Loading applications..."
                        color: Lumen.Theme.foreground
                        font.family: interfaceFont.name
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        visible: root.registryReady && root.searchText.length === 0
                        text: "Check that your apps provide desktop entries."
                        color: Lumen.Theme.mutedForeground
                        font.family: interfaceFont.name
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Item {
                id: footer
                width: parent.width
                height: 18

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter launch    Up/Down move    Esc close"
                    color: Lumen.Theme.mutedForeground
                    font.family: interfaceFont.name
                    font.pixelSize: 10
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "LUMEN"
                    color: Lumen.Theme.primary
                    font.family: interfaceFont.name
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Component.onCompleted: {
        refreshApps()
        if (DesktopEntries.applications.values.length > 0)
            registryReady = true
    }
}
