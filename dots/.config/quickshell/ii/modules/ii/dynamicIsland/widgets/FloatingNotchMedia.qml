import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool playing: player ? player.playbackState === MprisPlaybackState.Playing : false
    readonly property string artUrl: MprisController.artUrl
    readonly property string title: (MprisController.activeTrack && MprisController.activeTrack.title) ? MprisController.activeTrack.title : "No title"
    readonly property string artist: (MprisController.activeTrack && MprisController.activeTrack.artist) ? MprisController.activeTrack.artist : "Unknown Artist"
    readonly property string identity: player ? (player.identity ?? "") : ""

    property bool isExpanded: false

    readonly property Item widgetBg: {
        var p = root.parent;
        if (p && p.parent) {
            return p.parent;
        }
        return root;
    }

    readonly property int elementHeight: Math.max(20, Math.min(42, root.height - 10))
    readonly property int barWidth: Math.max(4, Math.min(8, elementHeight / 5))

    property string displayTitle: ""
    property string displayArtist: ""
    property real titleOpacity: 1.0
    property real titleXOffset: 0.0

    property string activeLyricText: ""
    property real lyricOpacity: 1.0
    property real lyricXOffset: 0.0

    readonly property string displaySongText: {
        if (LyricsService.hasSyncedLines && LyricsService.statusText !== "") {
            return LyricsService.statusText;
        }
        return root.title;
    }

    onDisplaySongTextChanged: {
        if (root.isExpanded) {
            lyricTransitionAnimation.stop();
            lyricTransitionAnimation.start();
        } else {
            root.activeLyricText = root.displaySongText;
        }
    }

    onIsExpandedChanged: {
        if (root.isExpanded) {
            LyricsService.initiliazeLyrics();
            root.activeLyricText = root.displaySongText;
        }
    }

    SequentialAnimation {
        id: lyricTransitionAnimation
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "lyricOpacity"
                to: 0.0
                duration: 120
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "lyricXOffset"
                to: -10
                duration: 120
                easing.type: Easing.OutQuad
            }
        }
        PropertyAction {
            target: root
            property: "activeLyricText"
            value: root.displaySongText
        }
        PropertyAction {
            target: root
            property: "lyricXOffset"
            value: 10
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "lyricOpacity"
                to: 1.0
                duration: 180
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "lyricXOffset"
                to: 0.0
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    // Trigger animation on title OR identity (player source) change
    onTitleChanged: {
        if (displayTitle === "") {
            displayTitle = root.title;
            displayArtist = root.artist;
        } else {
            songSwitchAnimation.stop();
            songSwitchAnimation.start();
        }
    }

    onIdentityChanged: {
        if (displayTitle !== "") {
            songSwitchAnimation.stop();
            songSwitchAnimation.start();
        }
    }

    SequentialAnimation {
        id: songSwitchAnimation
        // Phase 1: slide left + fade out
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "titleOpacity"
                to: 0.0
                duration: 150
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "titleXOffset"
                to: -24
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
        // Swap values
        PropertyAction {
            target: root
            property: "displayTitle"
            value: root.title
        }
        PropertyAction {
            target: root
            property: "displayArtist"
            value: root.artist
        }
        PropertyAction {
            target: root
            property: "titleXOffset"
            value: 24
        }
        // Phase 2: slide in from right + fade in
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "titleOpacity"
                to: 1.0
                duration: 220
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "titleXOffset"
                to: 0.0
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }

    Timer {
        running: root.isExpanded && root.playing
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.player) {
                root.player.positionChanged();
            }
        }
    }

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0)
            return "0:00";
        let mins = Math.floor(seconds / 60);
        let secs = Math.floor(seconds % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    // Real Cava Visualizer integration
    property var visualizerPoints: []

    readonly property real bar0Val: visualizerPoints.length > 5 ? visualizerPoints[3] / 1000.0 : 0
    readonly property real bar1Val: visualizerPoints.length > 11 ? visualizerPoints[9] / 1000.0 : 0
    readonly property real bar2Val: visualizerPoints.length > 18 ? visualizerPoints[16] / 1000.0 : 0
    readonly property real bar3Val: visualizerPoints.length > 28 ? visualizerPoints[25] / 1000.0 : 0

    function getBarHeight(index) {
        let minH = barWidth;
        if (!root.playing)
            return minH; // Reset to perfect circle when paused
        let val = 0;
        if (index === 0)
            val = bar0Val;
        else if (index === 1)
            val = bar1Val;
        else if (index === 2)
            val = bar2Val;
        else if (index === 3)
            val = bar3Val;

        let norm = Math.min(1.0, Math.max(0.0, val * 2.0));
        let maxH = elementHeight - 10;
        return minH + norm * (maxH - minH);
    }

    Process {
        id: cavaProc
        running: !root.isExpanded && root.playing
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Component.onCompleted: {
        LyricsService.initiliazeLyrics();
        root.displayTitle = root.title;
        root.displayArtist = root.artist;
        root.activeLyricText = root.displaySongText;
    }

    // ==========================================
    // 1. CONTRACTED MODE (album-art full background)
    // ==========================================
    Item {
        id: contractedLayout
        anchors.fill: parent
        visible: !root.isExpanded
        clip: true

        // OpacityMask to clip album art to rounded corners
        Rectangle {
            id: contractedMaskRect
            anchors.fill: parent
            radius: Appearance.rounding.windowRounding
            visible: false
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: contractedMaskRect
        }

        // ── Cross-fade album art background ─────────────────────────────────
        // Two layers: when artUrl changes, the back one fades in, then swaps.
        property string displayedArt: root.artUrl
        property string previousArt: ""

        onDisplayedArtChanged: {} // binding declared below via Connections

        // Primary (current) art
        Image {
            id: artPrimary
            anchors.fill: parent
            source: contractedLayout.displayedArt
            fillMode: Image.PreserveAspectCrop
            opacity: 1.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Secondary (previous) art – fades out
        Image {
            id: artSecondary
            anchors.fill: parent
            source: contractedLayout.previousArt
            fillMode: Image.PreserveAspectCrop
            opacity: 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Fallback gradient when no art
        Rectangle {
            anchors.fill: parent
            visible: root.artUrl === ""
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Appearance.colors.colSurfaceContainerHighest
                }
                GradientStop {
                    position: 1.0
                    color: Appearance.colors.colSurfaceContainer
                }
            }
        }

        // Music note icon centered when no art
        MaterialSymbol {
            anchors.centerIn: parent
            visible: root.artUrl === ""
            text: "music_note"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnSurfaceVariant
            opacity: 0.5
        }

        // ── Radial gradient dimming overlay ──────────────────────────────────
        // Soft edge-to-center vignette using overlapping horizontal+vertical gradients
        Item {
            anchors.fill: parent
            opacity: root.playing ? 0.82 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Appearance.colors.colScrim
                    }
                    GradientStop {
                        position: 0.4
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                    GradientStop {
                        position: 0.8
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                    GradientStop {
                        position: 1.0
                        color: Appearance.colors.colScrim
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0.0
                        color: Appearance.colors.colScrim
                    }
                    GradientStop {
                        position: 0.4
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                    GradientStop {
                        position: 0.8
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                    GradientStop {
                        position: 1.0
                        color: Appearance.colors.colScrim
                    }
                }
            }
        }

        // ── Content row ─────────────────────────────────────────────────────
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // Left: metadata always visible
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.bold: true
                    color: root.artUrl !== "" ? '#f2f2f2' : Appearance.colors.colOnSurface
                    text: root.displayTitle
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    opacity: root.titleOpacity
                    transform: Translate {
                        x: root.titleXOffset
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: root.artUrl !== "" ? "#C0C0C0" : Appearance.colors.colOnSurfaceVariant
                    text: root.displayArtist
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    opacity: root.titleOpacity
                    transform: Translate {
                        x: root.titleXOffset
                    }
                }
            }

            // Right: visualizer bars
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.barWidth * 4 + 2 * 3
                implicitHeight: root.elementHeight

                Row {
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: 2

                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.barWidth
                            height: root.getBarHeight(index)
                            radius: root.barWidth / 2
                            color: root.artUrl !== "" ? "#FFFFFF" : Appearance.colors.colPrimary

                            Behavior on height {
                                NumberAnimation {
                                    duration: 85
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Art cross-fade logic ─────────────────────────────────────────────
        Connections {
            target: root
            function onArtUrlChanged() {
                if (root.artUrl === contractedLayout.displayedArt)
                    return;
                // Bring secondary to front with old art visible
                contractedLayout.previousArt = contractedLayout.displayedArt;
                artSecondary.opacity = 1.0;
                artPrimary.opacity = 0.0;
                contractedLayout.displayedArt = root.artUrl;
                // Fade: primary (new art) in, secondary out
                artPrimary.opacity = 1.0;
                artSecondary.opacity = 0.0;
            }
        }
    }

    // ==========================================
    // 2. EXPANDED MODE (Premium Spotify-like layout)
    // ==========================================

    // Background Album Art Overlay (covers full parent when expanded, masked to rounded corners)
    Item {
        id: expandedBg
        readonly property bool isMultiWidget: {
            var p = root.parent;
            while (p && !p.hasOwnProperty("activeWidgetsList")) {
                p = p.parent;
            }
            return (p && p.activeWidgetsList.length > 1);
        }

        x: -(root.widgetBg.width - root.width) / 2
        y: -(root.widgetBg.height - root.height) / 2
        width: root.widgetBg.width
        height: root.widgetBg.height
        visible: root.isExpanded

        // Mask shape defining the rounded sections
        Rectangle {
            id: maskRect
            anchors.fill: parent
            radius: Appearance.rounding.windowRounding
            visible: false
        }

        // Image container with graphical effect opacity mask to prevent corner bleeding
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: maskRect
            }

            Image {
                anchors.fill: parent
                source: root.artUrl !== "" ? root.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                opacity: 0.85
                visible: root.artUrl !== ""
            }

            // Radial gradient dimming overlay
            Item {
                anchors.fill: parent
                opacity: root.playing ? 0.55 : 0.8

                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Appearance.colors.colScrim
                        }
                        GradientStop {
                            position: 0.4
                            color: Qt.rgba(0, 0, 0, 0)
                        }
                        GradientStop {
                            position: 0.8
                            color: Qt.rgba(0, 0, 0, 0)
                        }
                        GradientStop {
                            position: 1.0
                            color: Appearance.colors.colScrim
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: Appearance.colors.colScrim
                        }
                        GradientStop {
                            position: 0.4
                            color: Qt.rgba(0, 0, 0, 0)
                        }
                        GradientStop {
                            position: 0.8
                            color: Qt.rgba(0, 0, 0, 0)
                        }
                        GradientStop {
                            position: 1.0
                            color: Appearance.colors.colScrim
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: expandedLayout
        anchors.fill: parent
        anchors.leftMargin: {
            var p = root.parent;
            while (p && !p.hasOwnProperty("activeWidgetsList")) {
                p = p.parent;
            }
            return (p && p.activeWidgetsList.length > 1) ? 8 : 12;
        }
        anchors.rightMargin: anchors.leftMargin
        anchors.topMargin: anchors.leftMargin
        anchors.bottomMargin: {
            var p = root.parent;
            while (p && !p.hasOwnProperty("activeWidgetsList")) {
                p = p.parent;
            }
            return (p && p.activeWidgetsList.length > 1) ? 4 : 8;
        }
        spacing: 6
        visible: root.isExpanded

        // Top Row: Brand Icon (left) + Audio Output Device (right)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            // App program source icon
            MaterialShape {
                implicitWidth: 24
                implicitHeight: 24
                shapeString: "Cookie12Sided"
                color: "transparent"
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop

                Loader {
                    id: appIconLoader
                    anchors.fill: parent
                    active: root.player && root.player.desktopEntry !== ""
                    sourceComponent: IconImage {
                        implicitSize: Appearance.font.pixelSize.huge
                        source: Quickshell.iconPath(root.player ? root.player.desktopEntry : "audio-x-generic", "audio-x-generic")
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: !appIconLoader.active
                    sourceComponent: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_note"
                        iconSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnSurface
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Audio output device pill (headphones/speaker)
            Rectangle {
                id: audioPill
                height: 24
                implicitWidth: audioPillLayout.implicitWidth + 16
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimaryContainer
                border.width: 0

                readonly property string activeAudioDeviceName: Audio.sink ? (Audio.sink.description || "") : ""
                readonly property string audioDeviceIcon: {
                    let desc = activeAudioDeviceName.toLowerCase();
                    if (desc.includes("headphone") || desc.includes("headset") || desc.includes("wired")) {
                        return "headphones";
                    }
                    return "volume_up";
                }

                RowLayout {
                    id: audioPillLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        text: audioPill.audioDeviceIcon
                        iconSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnPrimaryContainer
                    }

                    StyledText {
                        text: audioPill.activeAudioDeviceName !== "" ? audioPill.activeAudioDeviceName : Translation.tr("Wired headphones")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.bold: true
                        color: Appearance.colors.colOnPrimaryContainer
                        Layout.maximumWidth: 100
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Middle Row: Metadata/Lyrics (left) + Large Play/Pause (right)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Left Side: Metadata column (Song title/Lyrics on top, artist below)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    color: root.artUrl !== "" ? "#FFFFFF" : Appearance.colors.colOnSurface
                    text: root.activeLyricText
                    opacity: root.lyricOpacity
                    transform: Translate {
                        x: root.lyricXOffset
                    }
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.artUrl !== "" ? "#B0B0B0" : Appearance.colors.colSubtext
                    text: root.displayArtist
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    opacity: root.titleOpacity
                    transform: Translate {
                        x: root.titleXOffset
                    }
                }
            }

            // Right Side: Large Play/Pause Button
            RippleButton {
                id: playBtn
                implicitWidth: 52
                implicitHeight: 52
                buttonRadius: 18
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                colRipple: Appearance.colors.colPrimaryContainerActive
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                onClicked: {
                    if (root.player) {
                        if (root.playing)
                            root.player.pause();
                        else
                            root.player.play();
                    }
                }

                contentItem: Item {
                    implicitWidth: 52
                    implicitHeight: 52
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.playing ? "pause" : "play_arrow"
                        iconSize: Appearance.font.pixelSize.hugeass
                        color: Appearance.colors.colOnPrimaryContainer
                        fill: 1
                    }
                }
            }
        }

        // Bottom Row: Prev Button + Progress Bar + Next Button
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 12
            Layout.alignment: Qt.AlignBottom

            // Previous Button
            RippleButton {
                id: prevBtn
                implicitWidth: 24
                implicitHeight: 24
                buttonRadius: 12
                colBackground: "transparent"
                colBackgroundHover: "transparent"
                colRipple: Appearance.colors.colPrimaryContainer

                onClicked: {
                    if (root.player)
                        root.player.previous();
                }

                contentItem: Item {
                    implicitWidth: 24
                    implicitHeight: 24
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: Appearance.font.pixelSize.normal
                        color: root.player && root.player.canGoPrevious ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSubtext
                        opacity: root.player && root.player.canGoPrevious ? 1.0 : 0.4
                    }
                }
            }

            // Progress Slider
            Item {
                id: progressArea
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                Loader {
                    id: sliderLoader
                    anchors.fill: parent
                    active: root.player ? (root.player.canSeek ?? false) : false
                    sourceComponent: StyledSlider {
                        configuration: StyledSlider.Configuration.Wavy
                        highlightColor: Appearance.colors.colPrimaryContainer
                        trackColor: Appearance.colors.colSurfaceContainer
                        handleColor: Appearance.colors.colPrimaryContainer
                        value: (root.player && root.player.length > 0) ? (root.player.position / root.player.length) : 0
                        onMoved: if (root.player)
                            root.player.position = value * root.player.length
                    }
                }

                Loader {
                    id: progressBarLoader
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                    }
                    active: root.player ? !(root.player.canSeek ?? false) : false
                    sourceComponent: StyledProgressBar {
                        wavy: root.player ? root.playing : false
                        highlightColor: Appearance.colors.colPrimaryContainer
                        trackColor: colSurfaceContainer
                        value: (root.player && root.player.length > 0) ? (root.player.position / root.player.length) : 0
                    }
                }
            }

            // Next Button
            RippleButton {
                id: nextBtn
                implicitWidth: 24
                implicitHeight: 24
                buttonRadius: 12
                colBackground: "transparent"
                colBackgroundHover: "transparent"
                colRipple: Appearance.colors.colPrimaryContainer

                onClicked: {
                    if (root.player)
                        root.player.next();
                }

                contentItem: Item {
                    implicitWidth: 24
                    implicitHeight: 24
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        iconSize: Appearance.font.pixelSize.normal
                        color: root.player && root.player.canGoNext ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSubtext
                        opacity: root.player && root.player.canGoNext ? 1.0 : 0.4
                    }
                }
            }
        }
    }
}
