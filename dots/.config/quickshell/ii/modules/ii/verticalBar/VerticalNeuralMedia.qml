import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris

MouseArea {
    id: root

    readonly property int artSize: Appearance.sizes.verticalBarWidth - Appearance.rounding.small * 2
    readonly property int visBarCount: 5
    readonly property int visBarWidth: Appearance.rounding.unsharpen
    readonly property int visBarGap: Appearance.rounding.unsharpen
    readonly property int visMaxH: Appearance.rounding.small * 3

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasTrack: (activePlayer?.trackTitle ?? "").length > 0

    readonly property var artUrl: MprisController.artUrl
    readonly property string artSource: artUrl || ""

    Layout.fillHeight: true
    implicitWidth: Appearance.sizes.verticalBarWidth
    implicitHeight: columnLayout.implicitHeight + Appearance.rounding.small * 2
    visible: hasTrack

    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
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

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: Appearance.rounding.small

        Item {
            id: albumArtVert
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.artSize
            Layout.preferredHeight: root.artSize

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
                        width: albumArtVert.width
                        height: albumArtVert.height
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

        Item {
            id: audioVisualizerVert
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: visBarCount * visBarWidth + (visBarCount - 1) * visBarGap
            Layout.preferredHeight: visMaxH

            readonly property bool isPlaying: root.activePlayer?.isPlaying ?? false
            property list<real> barHeights: [0.2, 0.25, 0.3, 0.22, 0.18]

            Timer {
                running: audioVisualizerVert.isPlaying
                repeat: true
                interval: 150
                onTriggered: {
                    audioVisualizerVert.barHeights = [
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
                    height: visMaxH * audioVisualizerVert.barHeights[index]
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
}
