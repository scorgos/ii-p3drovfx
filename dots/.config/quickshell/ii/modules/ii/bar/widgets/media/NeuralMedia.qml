import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property bool vertical: false
    readonly property int artSize: Appearance.sizes.baseBarHeight - Appearance.rounding.small
    readonly property int textMaxWidth: Appearance.sizes.baseBarHeight * 6
    readonly property int lyricsCustomSize: Config.options.bar.mediaPlayer.lyrics.customSize
    readonly property bool useFixedSize: Config.options.bar.mediaPlayer.useFixedSize
    readonly property int customSize: Config.options.bar.mediaPlayer.customSize
    readonly property bool lyricsEnabled: Config.options.bar.mediaPlayer.lyrics.enable
    readonly property bool useGradientMask: Config.options.bar.mediaPlayer.lyrics.useGradientMask
    readonly property string lyricsStyle: Config.options.bar.mediaPlayer.lyrics.style
    readonly property bool artworkEnabled: Config.options.bar.mediaPlayer.artwork.enable
    readonly property int visBarCount: 5
    readonly property int visBarWidth: Appearance.rounding.unsharpen
    readonly property int visBarGap: Appearance.rounding.unsharpen
    readonly property int visMaxH: Appearance.sizes.baseBarHeight - Appearance.rounding.small

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    readonly property string trackArtist: activePlayer?.trackArtist ?? ""
    readonly property bool hasTrack: (activePlayer?.trackTitle ?? "").length > 0

    readonly property var artUrl: MprisController.artUrl
    readonly property bool isLocalArt: artUrl.startsWith("file://")
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool artDownloaded: false
    readonly property string artSource: {
        if (!artUrl) return "";
        if (isLocalArt) return artUrl;
        return artDownloaded ? Qt.resolvedUrl(artFilePath) : "";
    }

    Layout.fillHeight: true
    implicitWidth: {
        if (!hasTrack) return 0;
        if (lyricsEnabled && LyricsService.hasSyncedLines) return lyricsCustomSize;
        if (useFixedSize) return customSize;
        let w = 0;
        if (artworkEnabled) w += artSize + Appearance.rounding.small;
        if (textColumn.visible) w += textColumn.width + Appearance.rounding.small;
        if (audioVisualizer.visible) w += audioVisualizer.width;
        return w;
    }
    implicitHeight: Appearance.sizes.baseBarHeight
    visible: implicitWidth > 0

    Behavior on implicitWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
    }

    Component.onCompleted: {
        LyricsService.initiliazeLyrics();
        if (typeof rootItem !== "undefined") {
            rootItem.toggleVisible(hasTrack);
        }
    }

    onHasTrackChanged: {
        if (typeof rootItem !== "undefined") {
            rootItem.toggleVisible(hasTrack);
        }
    }

    onArtFilePathChanged: {
        if (!artUrl || artUrl.length === 0) {
            artDownloaded = false;
            return;
        }
        if (isLocalArt) {
            artDownloaded = true;
            return;
        }
        artDownloader.targetFile = artUrl;
        artDownloader.artFilePath = artFilePath;
        artDownloader.artTempPath = artFilePath + ".tmp";
        artDownloaded = false;
        artDownloader.running = true;
    }

    Process {
        id: artDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        property string artTempPath: root.artFilePath + ".tmp"
        command: ["bash", "-c", `[ -f ${artFilePath} ] || (curl -4 -sSL '${targetFile}' -o '${artTempPath}' && mv '${artTempPath}' '${artFilePath}')`]
        onExited: {
            artDownloaded = true;
        }
    }

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        hoverEnabled: !Config.options.bar.tooltips.clickToShow
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            GlobalStates.setMediaWidgetHovered(true);
            if (hoverEnabled) {
                var globalPos = root.mapToItem(null, 0, 0);
                GlobalStates.mediaPopupRect = Qt.rect(globalPos.x, globalPos.y, root.width, root.height);
                GlobalStates.mediaControlsOpen = true;
            }
        }
        onExited: {
            GlobalStates.setMediaWidgetHovered(false);
        }
        onPressed: event => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                if (!hoverEnabled) {
                    var globalPos = root.mapToItem(null, 0, 0);
                    GlobalStates.mediaPopupRect = Qt.rect(globalPos.x, globalPos.y, root.width, root.height);
                    GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
                }
            }
        }
    }

    Item {
        id: albumArtColumn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.artworkEnabled ? root.artSize : 0
        height: root.artworkEnabled ? root.artSize : 0

        MaterialShape {
            anchors.fill: parent
            shape: MaterialShape.Shape.Cookie12Sided
            implicitSize: root.artSize
            color: Appearance.colors.colPrimaryContainer
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            visible: root.artSource.length > 0

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: albumArtColumn.width
                    height: albumArtColumn.height
                    radius: Appearance.rounding.full
                }
            }

            Image {
                anchors.fill: parent
                source: root.artSource
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                sourceSize.width: root.artSize
                sourceSize.height: root.artSize
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            visible: root.artSource.length === 0
            fill: 1
            text: "music_note"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    Rectangle {
        id: textColumn
        anchors.left: albumArtColumn.right
        anchors.leftMargin: root.artworkEnabled ? Appearance.rounding.small : 0
        anchors.verticalCenter: parent.verticalCenter
        height: root.artSize
        width: {
            let w = titleText.implicitWidth;
            if (artistText.implicitWidth > w) w = artistText.implicitWidth;
            return w + Appearance.rounding.small * 2;
        }
        radius: Appearance.rounding.windowRounding
        color: Appearance.colors.colSecondaryContainer
        visible: root.hasTrack && !(root.lyricsEnabled && LyricsService.hasSyncedLines)

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.rounding.small
            anchors.rightMargin: Appearance.rounding.small
            spacing: 0

            StyledText {
                id: titleText
                Layout.fillWidth: true
                text: root.cleanedTitle
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSecondaryContainer
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }

            StyledText {
                id: artistText
                Layout.fillWidth: true
                text: root.trackArtist
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Light
                color: Appearance.colors.colOnSecondaryContainer
                opacity: 0.7
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }
        }
    }

    Loader {
        id: lyricsItemLoader
        active: root.lyricsEnabled && root.hasTrack
        anchors.left: albumArtColumn.right
        anchors.leftMargin: root.artworkEnabled ? Appearance.rounding.small : 0
        anchors.verticalCenter: parent.verticalCenter
        width: root.lyricsCustomSize
        height: root.artSize

        sourceComponent: Item {
            id: lyricsItem

            Loader {
                active: root.lyricsStyle == "static"
                anchors.fill: parent
                sourceComponent: LyricsStatic {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignLeft
                }
            }

            Loader {
                active: root.lyricsStyle == "scroller"
                anchors.fill: parent
                sourceComponent: LyricScroller {
                    anchors.fill: parent
                    visible: root.lyricsStyle == "scroller" && LyricsService.hasSyncedLines
                    defaultLyricsSize: Appearance.font.pixelSize.smallest
                    useGradientMask: root.useGradientMask
                    halfVisibleLines: 1
                    downScale: 0.98
                    rowHeight: 10
                    gradientDensity: 0.25
                }
            }
        }
    }

    Item {
        id: audioVisualizer
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: visBarCount * visBarWidth + (visBarCount - 1) * visBarGap
        height: root.artSize
        visible: root.hasTrack

        readonly property bool isPlaying: root.activePlayer?.isPlaying ?? false
        property list<real> barHeights: [0.2, 0.25, 0.3, 0.22, 0.18]

        Timer {
            running: audioVisualizer.isPlaying
            repeat: true
            interval: 150
            onTriggered: {
                audioVisualizer.barHeights = [
                    0.4 + Math.random() * 0.6,
                    0.5 + Math.random() * 0.5,
                    0.6 + Math.random() * 0.4,
                    0.45 + Math.random() * 0.55,
                    0.35 + Math.random() * 0.65
                ]
            }
        }

        Repeater {
            model: visBarCount
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: index * (visBarWidth + visBarGap)
                width: visBarWidth
                height: visMaxH * audioVisualizer.barHeights[index]
                radius: visBarWidth / 2
                color: Appearance.m3colors.m3primary

                Behavior on height {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
        }
    }
}
