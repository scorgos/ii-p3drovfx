import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    // Monitor for fullscreen windows
    readonly property HyprlandMonitor hMonitor: Hyprland.monitorFor(win.screen)
    readonly property int activeWsId: hMonitor?.activeWorkspace?.id ?? -1
    readonly property bool fullscreenActive: HyprlandData.windowList.some(w =>
        (w.fullscreen ?? 0) > 0 && (w.workspace?.id ?? -2) === activeWsId)

    // State bindings
    readonly property bool osdActive: GlobalStates.osdVolumeOpen
    readonly property bool notificationActive: Notifications.popupList.length > 0
    readonly property bool recordingActive: (Persistent.states.screenRecord && Persistent.states.screenRecord.active) || false
    readonly property bool pomodoroActive: TimerService.pomodoroRunning
    readonly property bool stopwatchActive: TimerService.stopwatchRunning
    readonly property bool mediaActive: MprisController.isPlaying || MprisController.activePlayer !== null

    // Bluetooth temporary notification status
    property bool btNotifActive: false
    property string btDeviceName: ""
    property string btAction: "connected"

    Connections {
        target: BluetoothStatus
        function onDeviceConnected(device) {
            root.btDeviceName = device.name || device.alias || "Device";
            root.btAction = "connected";
            root.btNotifActive = true;
            btTimer.restart();
        }
        function onDeviceDisconnected(device) {
            root.btDeviceName = device.name || device.alias || "Device";
            root.btAction = "disconnected";
            root.btNotifActive = true;
            btTimer.restart();
        }
    }

    property Timer btTimer: Timer {
        id: btTimer
        interval: 3000
        onTriggered: root.btNotifActive = false
    }

    // Wifi temporary notification status
    property bool wifiNotifActive: false
    property string wifiSsid: ""

    Connections {
        target: Network
        function onWifiStatusChanged() {
            if (Network.wifiStatus === "connected" && Network.networkName !== "") {
                root.wifiSsid = Network.networkName;
                root.wifiNotifActive = true;
                wifiTimer.restart();
            }
        }
    }

    property Timer wifiTimer: Timer {
        id: wifiTimer
        interval: 3000
        onTriggered: root.wifiNotifActive = false
    }

    // Priority resolved mode
    readonly property string mode: {
        if (osdActive)             return "osd";
        if (notificationActive)    return "notification";
        if (wifiNotifActive)       return "wifi";
        if (btNotifActive)         return "bluetooth";
        if (pomodoroActive)        return "pomodoro";
        if (stopwatchActive)       return "stopwatch";
        if (recordingActive)       return "recording";
        if (mediaActive)           return "media";
        return "home";
    }

    // Hover state for general expanding on hover
    property bool hoverActive: hoverHandler.hovered
    property bool isHoverExpanded: false

    onHoverActiveChanged: {
        if (hoverActive) {
            hoverCollapseTimer.stop();
            isHoverExpanded = true;
        } else {
            hoverCollapseTimer.restart();
        }
    }

    property Timer hoverCollapseTimer: Timer {
        id: hoverCollapseTimer
        interval: 1500
        onTriggered: isHoverExpanded = false
    }

    // Trigger state for autohide top screen hover sensor
    property bool screenTopHovered: topSensorHandler.hovered
    property bool showOnTopHover: false

    onScreenTopHoveredChanged: {
        if (screenTopHovered) {
            topHoverCollapseTimer.stop();
            showOnTopHover = true;
        } else {
            topHoverCollapseTimer.restart();
        }
    }

    property Timer topHoverCollapseTimer: Timer {
        id: topHoverCollapseTimer
        interval: 2000
        onTriggered: showOnTopHover = false
    }

    // Determine if the island should be physically hidden (slid up out of bounds)
    readonly property bool idleHidden: {
        if (fullscreenActive) return true;
        if (mode !== "home") return false;
        
        // Mode is home (nothing active): hide if auto-hide is enabled AND user is not hovering the top trigger
        return Config.options.bar.floatingNotch.autoHide && !showOnTopHover;
    }

    // Layout configuration
    readonly property real targetW: {
        if (mode === "osd") return 380;
        if (mode === "notification") return isHoverExpanded ? 460 : 320;
        if (mode === "wifi" || mode === "bluetooth") return 250;
        if (mode === "pomodoro" || mode === "stopwatch") return 145;
        if (mode === "recording") return 125;
        if (mode === "media") return isHoverExpanded ? 360 : 320;
        return 180; // home default width
    }

    readonly property real targetH: {
        if (mode === "osd") return 72;
        if (mode === "notification") return isHoverExpanded ? 120 : 54;
        if (mode === "media") return isHoverExpanded ? 100 : 72;
        return 36; // compact height
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0] ?? null
        visible: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:floatingNotch"

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: targetH + 60

        // Dynamic click/hover mask to prevent blocking the screen
        mask: Region {
            item: root.idleHidden ? topSensor : maskTarget
        }

        // Invisible item serving as window mask, aligning with the container shape
        Item {
            id: maskTarget
            anchors.horizontalCenter: container.horizontalCenter
            anchors.top: container.top
            width: container.width
            height: container.height
        }

        // Auto-position container below any top frame thickness if needed
        Item {
            id: container
            anchors.horizontalCenter: parent.horizontalCenter
            width: targetW + (2 * notchBackground.topRadius)
            height: targetH

            Behavior on width {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }
            }

            // Slide vertically out of screen when idleHidden is true
            y: idleHidden ? -targetH - 10 : 0

            Behavior on y {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }

            // --- Drop Shadow ---
            NotchShadow {
                id: notchShadow
                anchors.fill: parent
                bodyWidth: parent.width
                bodyHeight: parent.height
                topRadius: notchBackground.topRadius
                bottomRadius: notchBackground.bottomRadius
                visible: Config.options.bar.floatingNotch.dropShadow && !idleHidden
                shadowOpacity: root.isHoverExpanded ? 0.6 : 0.35
            }

            // --- Main Notch shape ---
            Notch {
                id: notchBackground
                anchors.fill: parent
                bodyWidth: parent.width
                bodyHeight: parent.height
                topRadius: root.isHoverExpanded ? 20 : 14
                bottomRadius: root.isHoverExpanded ? 24 : 18
                fillColor: Appearance.colors.colSurfaceContainer
                disableBehaviors: true
            }

            // Hover Handler for expanding the Notch
            HoverHandler {
                id: hoverHandler
            }

            // Main Content Layout
            Item {
                id: contentClip
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - (2 * notchBackground.topRadius)
                clip: true

                // OSD Widget Loader
                Loader {
                    id: osdWidgetLoader
                    anchors.fill: parent
                    active: root.mode === "osd"
                    visible: active
                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent
                            Loader {
                                id: osdIndicatorLoader
                                anchors.fill: parent
                                source: {
                                    const item = [
                                        { id: "volume", sourceUrl: "indicators/VolumeIndicator.qml" },
                                        { id: "brightness", sourceUrl: "indicators/BrightnessIndicator.qml" },
                                        { id: "playerVolume", sourceUrl: "indicators/PlayerVolumeIndicator.qml" },
                                        { id: "gamma", sourceUrl: "indicators/GammaIndicator.qml" }
                                    ].find(i => i.id === GlobalStates.osdCurrentIndicator);
                                    if (!item) return "";
                                    return Quickshell.shellPath("modules/ii/topLayer/osd/" + item.sourceUrl);
                                }
                            }
                        }
                    }
                }

                // Notification Widget Loader
                Loader {
                    id: notificationWidgetLoader
                    anchors.fill: parent
                    active: root.mode === "notification"
                    visible: active
                    source: "widgets/FloatingNotchNotification.qml"

                    Binding {
                        target: notificationWidgetLoader.item
                        property: "isExpanded"
                        value: root.isHoverExpanded
                    }
                }

                // Media Widget Loader
                Loader {
                    id: mediaWidgetLoader
                    anchors.fill: parent
                    active: root.mode === "media"
                    visible: active
                    source: "widgets/FloatingNotchMedia.qml"

                    Binding {
                        target: mediaWidgetLoader.item
                        property: "isExpanded"
                        value: root.isHoverExpanded
                    }
                }

                // Pomodoro/Stopwatch Widget Loader
                Loader {
                    id: timerWidgetLoader
                    anchors.fill: parent
                    active: root.mode === "pomodoro" || root.mode === "stopwatch"
                    visible: active
                    source: "widgets/FloatingNotchTimer.qml"
                }

                // Screen Recording Widget Loader
                Loader {
                    id: recordingWidgetLoader
                    anchors.fill: parent
                    active: root.mode === "recording"
                    visible: active
                    source: "widgets/FloatingNotchRecording.qml"
                }

                // Wifi Connections Widget Loader
                Loader {
                    id: wifiWidgetLoader
                    anchors.fill: parent
                    active: root.mode === "wifi"
                    visible: active
                    source: "widgets/FloatingNotchWifi.qml"
                }

                // Bluetooth Connections Widget Loader
                Loader {
                    id: bluetoothWidgetLoader
                    anchors.fill: parent
                    active: root.mode === "bluetooth"
                    visible: active
                    source: "widgets/FloatingNotchBluetooth.qml"
                }

                // Idle home display (Relógio minimalista compactado no centro)
                RowLayout {
                    anchors.centerIn: parent
                    visible: root.mode === "home"
                    spacing: 6

                    MaterialSymbol {
                        text: "water_drop"
                        iconSize: 14
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        text: "ii"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }

        // AutoHide top edge sensor (small transparent sensor at the very top of the screen)
        Rectangle {
            id: topSensor
            width: 160
            height: 4
            color: "transparent"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.options.bar.floatingNotch.autoHide && root.idleHidden

            HoverHandler {
                id: topSensorHandler
            }
        }
    }
}
