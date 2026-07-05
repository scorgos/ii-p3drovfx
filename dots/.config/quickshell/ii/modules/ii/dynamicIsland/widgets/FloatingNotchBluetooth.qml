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

    // Access local Bluetooth data from DynamicIslandPanel
    readonly property string deviceName: {
        var p = root.parent;
        while (p && !p.hasOwnProperty("btDeviceName")) {
            p = p.parent;
        }
        return p ? p.btDeviceName : "";
    }

    readonly property string action: {
        var p = root.parent;
        while (p && !p.hasOwnProperty("btAction")) {
            p = p.parent;
        }
        return p ? p.btAction : "connected";
    }

    MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        text: root.action === "connected" ? "bluetooth_connected" : "bluetooth_disabled"
        iconSize: 16
        color: root.action === "connected" ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
    }

    StyledText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.bold: true
        color: Appearance.colors.colOnSurface
        text: {
            const dev = root.deviceName !== "" ? root.deviceName : Translation.tr("Device");
            if (root.action === "connected") {
                return dev + " " + Translation.tr("Connected");
            } else {
                return dev + " " + Translation.tr("Disconnected");
            }
        }
        elide: Text.ElideRight
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }
}
