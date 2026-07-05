import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 8

    readonly property bool active: (Persistent.states.screenRecord && Persistent.states.screenRecord.active) || false
    readonly property bool paused: (Persistent.states.screenRecord && Persistent.states.screenRecord.paused) || false

    property int elapsedSeconds: 0

    onActiveChanged: {
        if (!active) {
            elapsedSeconds = 0;
        }
    }

    Timer {
        id: recordingTimer
        interval: 1000
        repeat: true
        running: root.active && !root.paused
        onTriggered: root.elapsedSeconds++
    }

    readonly property string timeText: {
        const mins = Math.floor(elapsedSeconds / 60);
        const secs = elapsedSeconds % 60;
        return String(mins).padStart(2, '0') + ":" + String(secs).padStart(2, '0');
    }

    // Red pulsating circle indicator
    Rectangle {
        id: recordDot
        Layout.alignment: Qt.AlignVCenter
        width: 10
        height: 10
        radius: 5
        color: root.paused ? Appearance.colors.colWarning : Appearance.colors.colError

        SequentialAnimation on opacity {
            running: root.active && !root.paused
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.bold: true
        color: Appearance.colors.colOnSurface
        text: root.paused ? Translation.tr("PAUSED") : root.timeText
    }
}
