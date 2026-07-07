pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Read-only notification list for the lock screen.
 * Strictly display-only: no actions, no dismissal, no mouse handling,
 * so the lock surface keeps forcing focus on the password box.
 */
ColumnLayout {
    id: root

    readonly property var conf: Config.options.lock.notifications
    readonly property string criticalUrgency: NotificationUrgency.Critical.toString()

    property double lockTime: 0
    // The Loader in LockSurface activates when the session gets locked
    Component.onCompleted: lockTime = Date.now()

    readonly property var filtered: Notifications.list.filter(notif => {
        if (conf.onlySinceLock && notif.time < root.lockTime)
            return false;
        if (conf.filters.skipTransient && notif.isTransient)
            return false;
        if (conf.filters.skipLowUrgency && notif.urgency === NotificationUrgency.Low.toString())
            return false;
        const listed = conf.appList.some(app => app.toLowerCase() === notif.appName.toLowerCase());
        if (conf.appListMode === "blocklist" ? listed : !listed)
            return false;
        return true;
    }).sort((a, b) => b.time - a.time)

    // Notifications rendered with full content: everything in "full" mode,
    // otherwise only critical ones when the override allows them through
    readonly property var fullyShown: {
        if (conf.privacy === "full")
            return filtered.slice(0, conf.maxShown);
        if (conf.filters.criticalOverride === "full")
            return filtered.filter(n => n.urgency === root.criticalUrgency).slice(0, conf.maxShown);
        return [];
    }
    readonly property var redactedRest: filtered.filter(n => !fullyShown.includes(n))
    readonly property var redactedGroups: {
        if (conf.privacy !== "redacted")
            return [];
        const groups = [];
        redactedRest.forEach(notif => {
            let group = groups.find(g => g.appName === notif.appName);
            if (!group) {
                group = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    count: 0
                };
                groups.push(group);
            }
            group.count += 1;
        });
        return groups.slice(0, Math.max(0, conf.maxShown - fullyShown.length));
    }
    readonly property int overflowCount: {
        if (conf.privacy === "full")
            return filtered.length - fullyShown.length;
        if (conf.privacy === "redacted")
            return redactedRest.filter(n => !redactedGroups.some(g => g.appName === n.appName)).length;
        return 0; // The count pill already covers every remaining notification
    }

    width: 380
    spacing: 8
    visible: filtered.length > 0

    Repeater {
        model: root.fullyShown
        delegate: FullCard {}
    }

    Repeater {
        model: root.redactedGroups
        delegate: RedactedCard {}
    }

    Loader {
        Layout.alignment: Qt.AlignRight
        active: root.conf.privacy === "countOnly" && root.redactedRest.length > 0
        visible: active
        sourceComponent: CountPill {}
    }

    Loader {
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: 10
        active: root.overflowCount > 0
        visible: active
        sourceComponent: StyledText {
            text: Translation.tr("+%1 more").arg(root.overflowCount)
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurfaceVariant
        }
    }

    component Card: Rectangle {
        radius: Appearance.rounding.normal
        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.08)
    }

    component FullCard: Card {
        id: fullCard
        required property var modelData

        Layout.fillWidth: true
        implicitHeight: fullCardRow.implicitHeight + 20

        RowLayout {
            id: fullCardRow
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 10

            NotificationAppIcon {
                Layout.alignment: Qt.AlignTop
                appIcon: fullCard.modelData.appIcon
                summary: fullCard.modelData.summary
                image: fullCard.modelData.image
                urgency: fullCard.modelData.urgency === root.criticalUrgency ? NotificationUrgency.Critical : NotificationUrgency.Normal
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        Layout.fillWidth: true
                        text: fullCard.modelData.appName
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        text: NotificationUtils.getFriendlyNotifTimeString(fullCard.modelData.time)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: fullCard.modelData.summary
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: fullCard.modelData.body
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }
    }

    component RedactedCard: Card {
        id: redactedCard
        required property var modelData

        Layout.fillWidth: true
        implicitHeight: redactedCardRow.implicitHeight + 20

        RowLayout {
            id: redactedCardRow
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 10

            NotificationAppIcon {
                appIcon: redactedCard.modelData.appIcon
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: redactedCard.modelData.appName
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: redactedCard.modelData.count === 1 ? Translation.tr("1 new notification") : Translation.tr("%1 new notifications").arg(redactedCard.modelData.count)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }
    }

    component CountPill: Card {
        implicitWidth: pillRow.implicitWidth + 28
        implicitHeight: pillRow.implicitHeight + 14
        radius: Appearance.rounding.full

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                fill: 1
                text: "notifications"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                text: root.redactedRest.length
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}
