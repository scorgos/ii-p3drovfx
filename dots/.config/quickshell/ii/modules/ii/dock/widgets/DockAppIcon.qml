import QtQuick

DockIcon {
    id: iconContainer
    appId: root.appToplevel?.appId ?? ""
    desktopEntry: root.desktopEntry
    isRunning: root.appIsRunning
    width: root.buttonSize
    height: root.buttonSize
    anchors.centerIn: parent
}