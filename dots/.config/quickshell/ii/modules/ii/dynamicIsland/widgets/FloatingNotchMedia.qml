import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: MprisController.artUrl
    readonly property string title: MprisController.activeTrack?.title ?? "No title"
    readonly property string artist: MprisController.activeTrack?.artist ?? "Unknown Artist"

    property bool isExpanded: false

    // Initialize lyrics tracking
    Component.onCompleted: {
        LyricsService.initiliazeLyrics();
    }

    // ==========================================
    // 1. CONTRACTED MODE (Compact visual layout)
    // ==========================================
    RowLayout {
        id: contractedLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12
        visible: !root.isExpanded

        // Left side: Album art in a 12-sided material shape
        Item {
            id: compactArtContainer
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            // 12-sided shape mask source
            MaterialShape {
                id: compactCookieMask
                anchors.fill: parent
                shapeString: "Cookie12Sided"
                color: Appearance.colors.colSurfaceContainerHighest
                visible: false
            }

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: compactCookieMask
                }

                Image {
                    anchors.fill: parent
                    source: root.artUrl !== "" ? root.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: root.artUrl !== ""
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: 16
                    color: Appearance.colors.colOnSurfaceVariant
                    visible: root.artUrl === ""
                }
            }

            // Click play/pause
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.player) {
                        if (root.playing)
                            root.player.pause();
                        else
                            root.player.play();
                    }
                }
            }
        }

        // Center side: Rounded Rectangle containing metadata or 3-line synced lyrics
        Rectangle {
            id: compactTextContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            color: Appearance.colors.colLayer4
            radius: 12
            clip: true

            readonly property bool hasLyrics: Config.options.bar.mediaPlayer.lyrics.enable && LyricsService.hasSyncedLines

            // Synced lyrics view (3 lines with edge fade)
            Loader {
                id: compactLyricsLoader
                anchors.fill: parent
                anchors.margins: 4
                active: !root.isExpanded && compactTextContainer.hasLyrics
                visible: active
                sourceComponent: LyricScroller {
                    id: lyricScroller
                    anchors.fill: parent
                    textAlign: "left"
                    rowHeight: 16
                    halfVisibleLines: 1
                    useGradientMask: true
                    defaultLyricsSize: Appearance.font.pixelSize.smaller
                }
            }

            // Standard metadata display (Song + Artist)
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 0
                visible: !compactLyricsLoader.visible

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.bold: true
                    text: root.title
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnSurfaceVariant
                    text: root.artist
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        // Right side: simulated visualizer inside 12-sided material shape
        Item {
            id: compactVisualizerContainer
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            // 12-sided background shape
            MaterialShape {
                anchors.fill: parent
                shapeString: "Cookie12Sided"
                color: Appearance.colors.colSurfaceContainerHighest
            }

            // Wave lines visualizer
            Row {
                id: compactVisualizerRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        width: 2
                        height: 14
                        radius: 1
                        color: Appearance.colors.colPrimary
                        transformOrigin: Item.Center

                        SequentialAnimation on scale {
                            running: root.playing
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 0.25
                                to: 1.00
                                duration: 380 + index * 90
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: 1.00
                                to: 0.25
                                duration: 340 + index * 70
                                easing.type: Easing.InOutSine
                            }
                        }

                        scale: root.playing ? scale : 0.3
                        opacity: root.playing ? 1.0 : 0.55
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. EXPANDED MODE (Original media layout)
    // ==========================================
    RowLayout {
        id: expandedLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12
        visible: root.isExpanded

        // Cover Art background (rectangular)
        Rectangle {
            id: expandedArtContainer
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 8
            color: Appearance.colors.colSurfaceContainerHighest
            clip: true

            Image {
                anchors.fill: parent
                source: root.artUrl !== "" ? root.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl !== ""
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "music_note"
                iconSize: 24
                color: Appearance.colors.colOnSurfaceVariant
                visible: root.artUrl === ""
            }
        }

        // Details Layout when expanded or simple text when compact
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.normal
                font.bold: true
                text: root.title
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                text: root.artist
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            // Media controls shown only when expanded
            RowLayout {
                Layout.topMargin: 4
                spacing: 12

                // Previous
                MaterialSymbol {
                    text: "skip_previous"
                    iconSize: 18
                    color: root.player && root.player.canGoPrevious ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant
                    opacity: root.player && root.player.canGoPrevious ? 1.0 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoPrevious
                        onClicked: root.player.previous()
                    }
                }

                // Play/Pause
                MaterialSymbol {
                    text: root.playing ? "pause" : "play_arrow"
                    iconSize: 18
                    color: Appearance.colors.colOnSurface

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.player) {
                                if (root.playing)
                                    root.player.pause();
                                else
                                    root.player.play();
                            }
                        }
                    }
                }

                // Next
                MaterialSymbol {
                    text: "skip_next"
                    iconSize: 18
                    color: root.player && root.player.canGoNext ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant
                    opacity: root.player && root.player.canGoNext ? 1.0 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoNext
                        onClicked: root.player.next()
                    }
                }
            }
        }

        // Visualizer on the right (classic style)
        Row {
            id: expandedVisualizerRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 3
            visible: root.playing

            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: 3
                    height: 14
                    radius: 1.5
                    color: Appearance.colors.colPrimary
                    transformOrigin: Item.Center

                    SequentialAnimation on scale {
                        running: root.playing
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0.25
                            to: 1.00
                            duration: 380 + index * 90
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            from: 1.00
                            to: 0.25
                            duration: 340 + index * 70
                            easing.type: Easing.InOutSine
                        }
                    }

                    scale: root.playing ? scale : 0.3
                    opacity: root.playing ? 1.0 : 0.55
                }
            }
        }
    }
}
