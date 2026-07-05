import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

RowLayout {
    id: root
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 8

    readonly property bool pomodoroActive: TimerService.pomodoroRunning
    readonly property bool stopwatchActive: TimerService.stopwatchRunning

    // Format Pomodoro Time (MM:SS)
    readonly property string pomodoroText: {
        const totalSecs = TimerService.pomodoroSecondsLeft;
        const mins = Math.floor(totalSecs / 60);
        const secs = totalSecs % 60;
        return String(mins).padStart(2, '0') + ":" + String(secs).padStart(2, '0');
    }

    // Format Stopwatch Time (MM:SS)
    readonly property string stopwatchText: {
        const totalCentis = TimerService.stopwatchTime;
        const totalSecs = Math.floor(totalCentis / 100);
        const mins = Math.floor(totalSecs / 60);
        const secs = totalSecs % 60;
        return String(mins).padStart(2, '0') + ":" + String(secs).padStart(2, '0');
    }

    MaterialSymbol {
        id: timerIcon
        Layout.alignment: Qt.AlignVCenter
        text: root.pomodoroActive ? "timer" : "schedule"
        iconSize: 16
        color: root.pomodoroActive 
            ? (TimerService.pomodoroBreak ? Appearance.colors.colPrimary : Appearance.colors.colError) 
            : Appearance.colors.colOnSurface
    }

    StyledText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.bold: true
        color: Appearance.colors.colOnSurface
        text: root.pomodoroActive ? root.pomodoroText : root.stopwatchText
    }
}
