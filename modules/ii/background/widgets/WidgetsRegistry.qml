pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

Singleton {
    id: root

    // List of built-in widgets
    readonly property var builtinWidgets: [
        {
            "widgetId": "clock_cookie",
            "name": Translation.tr("Cookie Clock"),
            "category": "Clock",
            "qmlPath": Qt.resolvedUrl("clock/ClockWidget.qml"),
            "styleOverride": "cookie",
            "icon": "schedule",
            "description": Translation.tr("A beautiful analog clock with Material You shapes and customization."),
            "configPage": "widgets/DesktopClockWidgetConfig.qml"
        },
        {
            "widgetId": "clock_digital",
            "name": Translation.tr("Digital Clock"),
            "category": "Clock",
            "qmlPath": Qt.resolvedUrl("clock/ClockWidget.qml"),
            "styleOverride": "digital",
            "icon": "schedule",
            "description": Translation.tr("A modern, resizable digital clock with date and adaptive alignment."),
            "configPage": "widgets/DesktopClockWidgetConfig.qml"
        },
        {
            "widgetId": "clock_nagasaki",
            "name": Translation.tr("Nagasaki Clock"),
            "category": "Clock",
            "qmlPath": Qt.resolvedUrl("clock/ClockWidget.qml"),
            "styleOverride": "nagasaki",
            "icon": "schedule",
            "description": Translation.tr("A classic Nagasaki styled clock widget."),
            "configPage": "widgets/DesktopClockWidgetConfig.qml"
        },
        {
            "widgetId": "clock_wearos",
            "name": Translation.tr("WearOS Clock (Watch)"),
            "category": "Clock",
            "qmlPath": Qt.resolvedUrl("clock/WearOSClockWidget.qml"),
            "icon": "schedule",
            "description": Translation.tr("A circular analog clock widget styled like a Wear OS watch face."),
            "configPage": "widgets/DesktopWearOSClockWidgetConfig.qml"
        },
        {
            "widgetId": "circular_media",
            "name": Translation.tr("Circular Media (Watch)"),
            "category": "Media",
            "qmlPath": Qt.resolvedUrl("media/CircularMediaWidget.qml"),
            "icon": "play_circle",
            "description": Translation.tr("Circular media player widget styled like a smartwatch interface."),
            "configPage": "widgets/DesktopCircularMediaWidgetConfig.qml"
        },
        {
            "widgetId": "media_circular",
            "name": Translation.tr("Circular Media"),
            "category": "Media",
            "qmlPath": Qt.resolvedUrl("media/MediaWidget.qml"),
            "icon": "play_circle",
            "description": Translation.tr("Circular media player widget with album art support."),
            "configPage": "widgets/DesktopMediaWidgetConfig.qml"
        },
        {
            "widgetId": "media_expressive",
            "name": Translation.tr("Expressive Media"),
            "category": "Media",
            "qmlPath": Qt.resolvedUrl("media/ExpressiveMediaWidget.qml"),
            "icon": "music_note",
            "description": Translation.tr("Expressive and large media player widget with dynamic glow and lyrics."),
            "configPage": "widgets/DesktopMediaWidgetConfig.qml"
        },
        {
            "widgetId": "media_classic",
            "name": Translation.tr("Classic Media"),
            "category": "Media",
            "qmlPath": Qt.resolvedUrl("media/MediaWidgetClassic.qml"),
            "icon": "play_circle",
            "description": Translation.tr("Classic rectangular media player with album art and lyrics."),
            "configPage": ""
        },
        {
            "widgetId": "weather_default",
            "name": Translation.tr("Default Weather"),
            "category": "Weather",
            "qmlPath": Qt.resolvedUrl("weather/WeatherWidget.qml"),
            "icon": "cloud",
            "description": Translation.tr("Compact current weather status widget."),
            "configPage": "widgets/DesktopWeatherWidgetConfig.qml"
        },
        {
            "widgetId": "weather_expressive",
            "name": Translation.tr("Expressive Weather"),
            "category": "Weather",
            "qmlPath": Qt.resolvedUrl("weather/ExpressiveWeatherWidget.qml"),
            "icon": "sunny",
            "description": Translation.tr("Detailed and stylized weather card with future forecast."),
            "configPage": "widgets/DesktopWeatherWidgetConfig.qml"
        },
        {
            "widgetId": "weather_classic",
            "name": Translation.tr("Classic Weather"),
            "category": "Weather",
            "qmlPath": Qt.resolvedUrl("weather/WeatherWidgetClassic.qml"),
            "icon": "cloud",
            "description": Translation.tr("Classic resizable weather widget with 1x1, 1x2, and 1x3 modes."),
            "configPage": ""
        },
        {
            "widgetId": "date_default",
            "name": Translation.tr("Date Card"),
            "category": "Date",
            "qmlPath": Qt.resolvedUrl("DateWidget/DateWidget.qml"),
            "icon": "calendar_today",
            "description": Translation.tr("A simple card showing current month and day."),
            "configPage": "widgets/DateDesktopWIdgetConfig.qml"
        },
        {
            "widgetId": "calendar_default",
            "name": Translation.tr("Calendar"),
            "category": "Calendar",
            "qmlPath": Qt.resolvedUrl("calendar/CalendarWidget.qml"),
            "icon": "calendar_month",
            "description": Translation.tr("A calendar widget showing current month with navigation and day cells."),
            "configPage": ""
        },
        {
            "widgetId": "images_converter",
            "name": Translation.tr("Image Converter"),
            "category": "Utility",
            "qmlPath": Qt.resolvedUrl("images/ImageConverterWidget.qml"),
            "icon": "image",
            "description": Translation.tr("Drag and drop image converter supporting multiple formats."),
            "configPage": ""
        },
        {
            "widgetId": "images_custom",
            "name": Translation.tr("Custom Image"),
            "category": "Utility",
            "qmlPath": Qt.resolvedUrl("images/CustomImage.qml"),
            "icon": "photo",
            "description": Translation.tr("Display a custom image with Material You shape masking."),
            "configPage": ""
        },
        {
            "widgetId": "resources_default",
            "name": Translation.tr("System Resources"),
            "category": "System",
            "qmlPath": Qt.resolvedUrl("resources/ResourcesWidget.qml"),
            "icon": "monitor",
            "description": Translation.tr("CPU, RAM, and Battery/Disk usage cards."),
            "configPage": ""
        },
        {
            "widgetId": "usercard_default",
            "name": Translation.tr("User Card"),
            "category": "System",
            "qmlPath": Qt.resolvedUrl("usercard/UserCardWidget.qml"),
            "icon": "account_circle",
            "description": Translation.tr("User profile card with avatar, lock, settings, and power buttons."),
            "configPage": ""
        },
        {
            "widgetId": "visualizer_default",
            "name": Translation.tr("Audio Visualizer"),
            "category": "Media",
            "qmlPath": Qt.resolvedUrl("visualizer/VisualizerWidget.qml"),
            "icon": "graphic_eq",
            "description": Translation.tr("Audio visualizer bars synced with media playback."),
            "configPage": ""
        },
        {
            "widgetId": "worldclock_default",
            "name": Translation.tr("World Clock"),
            "category": "Clock",
            "qmlPath": Qt.resolvedUrl("worldclock/WorldClockWidget.qml"),
            "icon": "public",
            "description": Translation.tr("World clock showing multiple timezones with day/night indicators."),
            "configPage": ""
        }
    ]

    // List of user-installed widgets loaded dynamically
    property var userWidgets: []

    // Combined list of all available widgets
    readonly property var allWidgets: (builtinWidgets || []).concat(userWidgets || [])

    function getWidgetMetadata(widgetId) {
        let list = allWidgets;
        for (let i = 0; i < list.length; i++) {
            if (list[i].widgetId === widgetId) {
                return list[i];
            }
        }
        return null;
    }

    function getQmlPath(widgetId) {
        let meta = getWidgetMetadata(widgetId);
        return meta ? meta.qmlPath : "";
    }

    function getStyleOverride(widgetId) {
        let meta = getWidgetMetadata(widgetId);
        return meta ? meta.styleOverride : undefined;
    }

    Process {
        id: listUserWidgetsProc
        command: ["python3", Directories.scriptPath + "/list_user_widgets.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let str = text.trim();
                if (!str) return;
                try {
                    let list = JSON.parse(str);
                    root.userWidgets = list;
                } catch(e) {
                    console.log("[WidgetsRegistry] Failed to parse user widgets JSON:", e, str);
                }
            }
        }
    }

    // Refresh function for registry (e.g. when widgets are installed/uninstalled)
    function refresh() {
        listUserWidgetsProc.running = false;
        listUserWidgetsProc.running = true;
    }
}
