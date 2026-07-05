import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

RowLayout {
    id: root
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 12

    property bool isExpanded: false
    
    readonly property var latestNotif: Notifications.popupList.length > 0 ? Notifications.popupList[Notifications.popupList.length - 1] : null

    // Left Column: App Icon
    NotificationAppIcon {
        id: notifIcon
        Layout.alignment: Qt.AlignVCenter
        appIcon: root.latestNotif ? root.latestNotif.appIcon : ""
        summary: root.latestNotif ? root.latestNotif.summary : ""
        urgency: (root.latestNotif && root.latestNotif.notification) ? root.latestNotif.notification.urgency : 1
        image: root.latestNotif ? root.latestNotif.image : ""
        implicitSize: root.isExpanded ? 32 : 22
        
        Behavior on implicitSize {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    // Right Column: Content (Title on top, body on bottom, actions below that when expanded)
    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        // Title (Summary)
        StyledText {
            Layout.fillWidth: true
            font.pixelSize: root.isExpanded ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.smaller
            font.bold: true
            text: root.latestNotif ? root.latestNotif.summary : ""
            maximumLineCount: root.isExpanded ? 2 : 1
            wrapMode: root.isExpanded ? Text.WordWrap : Text.NoWrap
            elide: Text.ElideRight
        }

        // Body Text
        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
            text: root.latestNotif ? root.latestNotif.body : ""
            maximumLineCount: root.isExpanded ? 3 : 1
            wrapMode: root.isExpanded ? Text.WordWrap : Text.NoWrap
            elide: Text.ElideRight
        }

        // Quick Actions Row (Shown only when expanded)
        RowLayout {
            id: actionButtonsRow
            Layout.fillWidth: true
            Layout.topMargin: 6
            visible: root.isExpanded
            opacity: root.isExpanded ? 1.0 : 0.0
            spacing: 8

            Behavior on opacity { NumberAnimation { duration: 150 } }

            // Action buttons list from D-Bus
            Repeater {
                model: root.latestNotif ? root.latestNotif.actions : []
                NotificationActionButton {
                    required property var modelData
                    Layout.fillWidth: true
                    buttonText: modelData.text
                    urgency: root.latestNotif ? root.latestNotif.urgency : 1
                    
                    onClicked: {
                        if (root.latestNotif) {
                            Notifications.attemptInvokeAction(root.latestNotif.notificationId, modelData.identifier);
                        }
                    }
                }
            }

            // Copy to Clipboard Action
            NotificationActionButton {
                Layout.fillWidth: true
                urgency: root.latestNotif ? root.latestNotif.urgency : 1
                
                onClicked: {
                    if (root.latestNotif) {
                        Quickshell.clipboardText = root.latestNotif.body;
                    }
                }

                contentItem: RowLayout {
                    spacing: 6
                    anchors.centerIn: parent
                    
                    MaterialSymbol {
                        iconSize: 14
                        color: Appearance.colors.colOnSurface
                        text: "content_copy"
                    }
                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurface
                        text: Translation.tr("Copy")
                    }
                }
            }

            // Discard (Close) Action
            NotificationActionButton {
                Layout.fillWidth: true
                urgency: root.latestNotif ? root.latestNotif.urgency : 1
                
                onClicked: {
                    if (root.latestNotif) {
                        Notifications.discardNotification(root.latestNotif.notificationId);
                    }
                }

                contentItem: RowLayout {
                    spacing: 6
                    anchors.centerIn: parent
                    
                    MaterialSymbol {
                        iconSize: 14
                        color: Appearance.colors.colOnSurface
                        text: "close"
                    }
                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurface
                        text: Translation.tr("Close")
                    }
                }
            }
        }
    }
}
