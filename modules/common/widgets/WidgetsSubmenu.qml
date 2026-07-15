pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: contentCol.implicitHeight + 16

    property var currentCategory: null

    readonly property var widgetCategories: [
        {
            name: Translation.tr("Clock"),
            icon: "schedule",
            variants: [
                { widgetId: "clock_cookie", name: Translation.tr("Cookie Clock") },
                { widgetId: "clock_digital", name: Translation.tr("Digital Clock") },
                { widgetId: "clock_nagasaki", name: Translation.tr("Nagasaki Clock") },
                { widgetId: "clock_wearos", name: Translation.tr("WearOS Clock") }
            ]
        },
        {
            name: Translation.tr("Media"),
            icon: "music_note",
            variants: [
                { widgetId: "media_circular", name: Translation.tr("Circular Media") },
                { widgetId: "media_expressive", name: Translation.tr("Expressive Media") },
                { widgetId: "media_classic", name: Translation.tr("Classic Media") },
                { widgetId: "circular_media", name: Translation.tr("Circular Media (Watch)") }
            ]
        },
        {
            name: Translation.tr("Weather"),
            icon: "cloud",
            variants: [
                { widgetId: "weather_default", name: Translation.tr("Default Weather") },
                { widgetId: "weather_expressive", name: Translation.tr("Expressive Weather") },
                { widgetId: "weather_classic", name: Translation.tr("Classic Weather") }
            ]
        },
        {
            name: Translation.tr("Date"),
            icon: "calendar_today",
            variants: [
                { widgetId: "date_default", name: Translation.tr("Date Card") }
            ]
        },
        {
            name: Translation.tr("Calendar"),
            icon: "calendar_month",
            variants: [
                { widgetId: "calendar_default", name: Translation.tr("Calendar") }
            ]
        },
        {
            name: Translation.tr("Image Converter"),
            icon: "image",
            variants: [
                { widgetId: "images_converter", name: Translation.tr("Image Converter") },
                { widgetId: "images_custom", name: Translation.tr("Custom Image") }
            ]
        },
        {
            name: Translation.tr("System Resources"),
            icon: "monitor_heart",
            variants: [
                { widgetId: "resources_default", name: Translation.tr("System Resources") }
            ]
        },
        {
            name: Translation.tr("User Card"),
            icon: "person",
            variants: [
                { widgetId: "usercard_default", name: Translation.tr("User Card") }
            ]
        },
        {
            name: Translation.tr("Audio Visualizer"),
            icon: "graphic_eq",
            variants: [
                { widgetId: "visualizer_default", name: Translation.tr("Audio Visualizer") }
            ]
        },
        {
            name: Translation.tr("World Clock"),
            icon: "public",
            variants: [
                { widgetId: "worldclock_default", name: Translation.tr("World Clock") }
            ]
        }
    ]

    function isWidgetActive(widgetId) {
        let active = Config.options.background.activeWidgets || [];
        for (let i = 0; i < active.length; i++) {
            if (active[i].widgetId === widgetId) return true;
        }
        return false;
    }

    function toggleWidget(widgetId) {
        if (isWidgetActive(widgetId)) {
            Config.removeWidgetFromDesktop(widgetId);
        } else {
            Config.addWidgetToDesktop(widgetId);
        }
    }

    function isCategoryActive(variants) {
        for (let i = 0; i < variants.length; i++) {
            if (isWidgetActive(variants[i].widgetId)) return true;
        }
        return false;
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colLayer0
    }

    ColumnLayout {
        id: contentCol
        anchors { fill: parent; margins: 8 }
        spacing: 2

        // Lock widget positions
        ConfigSwitch {
            Layout.fillWidth: true
            buttonIcon: "lock"
            text: Translation.tr("Lock widget positions")
            checked: Config.options.background.widgetsLocked
            onCheckedChanged: Config.options.background.widgetsLocked = checked
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.4
        }

        // Category list (level 1)
        ColumnLayout {
            visible: root.currentCategory === null
            spacing: 2

            Repeater {
                model: root.widgetCategories
                delegate: RippleButton {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 40
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2

                    contentItem: RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 12

                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: Appearance.font.pixelSize.larger
                            color: root.isCategoryActive(modelData.variants)
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            opacity: 0.4
                        }
                    }

                    onClicked: root.currentCategory = modelData
                }
            }
        }

        // Variant list (level 2)
        ColumnLayout {
            visible: root.currentCategory !== null
            spacing: 2

            // Back button
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 40
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2

                contentItem: RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 12

                    MaterialSymbol {
                        text: "arrow_back"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: root.currentCategory?.name ?? ""
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.bold: true
                        color: Appearance.colors.colOnLayer1
                    }
                }

                onClicked: root.currentCategory = null
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.4
            }

            Repeater {
                model: root.currentCategory?.variants ?? []
                delegate: ConfigSwitch {
                    required property var modelData
                    Layout.fillWidth: true
                    buttonIcon: "check"
                    text: modelData.name
                    checked: root.isWidgetActive(modelData.widgetId)
                    onCheckedChanged: root.toggleWidget(modelData.widgetId)
                }
            }
        }
    }
}
