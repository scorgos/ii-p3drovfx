import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import Quickshell

Item {
    id: root
    anchors.fill: parent

    property bool isExpanded: false

    readonly property bool active: (Persistent.states.screenRecord && Persistent.states.screenRecord.active) || false
    readonly property bool paused: (Persistent.states.screenRecord && Persistent.states.screenRecord.paused) || false
    readonly property bool isLoading: (Persistent.states.screenRecord && Persistent.states.screenRecord.loading) || false
    readonly property int elapsedSeconds: (Persistent.states.screenRecord && Persistent.states.screenRecord.seconds) || 0

    onActiveChanged: {
        if (!active) {
            elapsedSeconds = 0;
        }
    }

    readonly property string timeText: {
        const mins = Math.floor(elapsedSeconds / 60);
        const secs = elapsedSeconds % 60;
        return String(mins).padStart(2, '0') + ":" + String(secs).padStart(2, '0');
    }

    // ==========================================
    // 1. CONTRACTED MODE
    // ==========================================
    RowLayout {
        id: contractedLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8
        visible: !root.isExpanded

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 10
            height: 10
            radius: 5
            color: root.paused ? Appearance.colors.colWarning : Appearance.colors.colError

            SequentialAnimation on opacity {
                running: root.active && !root.paused
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 0.3
                    duration: 600
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 0.3
                    to: 1.0
                    duration: 600
                    easing.type: Easing.InOutSine
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.bold: true
            font.features: ({
                    "tnum": 1
                })
            color: Appearance.colors.colOnSurface
            text: root.paused ? Translation.tr("PAUSED") : root.timeText
        }
    }

    // ==========================================
    // 2. EXPANDED MODE
    // ==========================================
    ColumnLayout {
        id: expandedLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 6
        visible: root.isExpanded

        // Dot + label centered
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 8
                height: 8
                radius: 4
                color: root.paused ? Appearance.colors.colWarning : Appearance.colors.colError

                SequentialAnimation on opacity {
                    running: root.active && !root.paused
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                font.bold: true
                font.letterSpacing: 60
                color: root.paused ? Appearance.colors.colWarning : Appearance.colors.colError
                text: root.paused ? Translation.tr("PAUSED") : Translation.tr("RECORDING")
            }
        }

        // Timer centered (big)
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.huge
            font.family: Appearance.font.family.numbers
            font.weight: Font.Bold
            font.features: ({ "tnum": 1 })
            color: Appearance.colors.colOnSurface
            horizontalAlignment: Text.AlignHCenter
            text: root.timeText
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Controls row — two compact buttons filling width
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            RippleButton {
                id: stopBtn
                Layout.fillWidth: true
                Layout.fillHeight: true
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colErrorContainer
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                colRipple: Appearance.colors.colErrorContainerActive

                onClicked: Quickshell.execDetached([Directories.recordScriptPath])

                contentItem: Item {
                    implicitWidth: stopContent.implicitWidth
                    implicitHeight: stopContent.implicitHeight

                    Row {
                        id: stopContent
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            text: "stop"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnErrorContainer
                            fill: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: Translation.tr("Stop")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.bold: true
                            color: Appearance.colors.colOnErrorContainer
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            RippleButton {
                id: pauseBtn
                Layout.fillWidth: true
                Layout.fillHeight: true
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colSecondaryContainer
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                colRipple: Appearance.colors.colSecondaryContainerActive

                onClicked: Quickshell.execDetached([Directories.recordScriptPath, "--pause"])

                contentItem: Item {
                    implicitWidth: pauseContent.implicitWidth
                    implicitHeight: pauseContent.implicitHeight

                    Row {
                        id: pauseContent
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            text: root.paused ? "play_arrow" : "pause"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSecondaryContainer
                            fill: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.paused ? Translation.tr("Resume") : Translation.tr("Pause")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.bold: true
                            color: Appearance.colors.colOnSecondaryContainer
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
