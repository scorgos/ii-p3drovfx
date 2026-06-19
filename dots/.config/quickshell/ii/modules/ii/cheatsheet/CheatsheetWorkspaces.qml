pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "workspaces"

/**
 * CheatsheetWorkspaces — the "Workspaces" tab in the cheatsheet.
 *
 * Lists saved workspace profiles and lets the user:
 *   - Snapshot the current layout as a new profile
 *   - Restore a profile (move running apps to saved workspaces)
 *   - Rename or delete profiles
 */
Item {
    id: root

    // ── state ────────────────────────────────────────────────────────────────
    property string filter:        ""
    property bool   showNewForm:   false
    property string newName:       ""
    property string newEmoji:      "🗂️"
    property string newDesc:       ""
    property bool   snapBusy:      false
    property bool   snapSuccess:   false
    property bool   snapError:     false
    property var    expandedSlugs: ({})

    function isProfileExpanded(slug) {
        return !!root.expandedSlugs[slug];
    }

    function setProfileExpanded(slug, isExp) {
        let copy = Object.assign({}, root.expandedSlugs);
        if (isExp) {
            copy[slug] = true;
        } else {
            delete copy[slug];
        }
        root.expandedSlugs = copy;
    }

    // Preset emojis for the picker
    readonly property var emojiList: [
        "🗂️","📚","💻","🎮","🎵","🎬","📝","🔬","🎨","🏋️",
        "☕","🌙","🚀","🏠","🌊","🔧","📊","✉️","🎓","🧠"
    ]

    Component.onCompleted: WorkspaceProfileService.refresh()

    // ── service connections ──────────────────────────────────────────────────
    Connections {
        target: WorkspaceProfileService

        function onSnapshotFinished(success, slug) {
            root.snapBusy = false;
            if (success) {
                root.snapSuccess = true;
                root.showNewForm = false;
                root.newName  = "";
                root.newEmoji = "🗂️";
                root.newDesc  = "";
                snapFeedbackTimer.restart();
            } else {
                root.snapError = true;
                snapFeedbackTimer.restart();
            }
        }
    }

    Timer {
        id: snapFeedbackTimer
        interval: 2500
        onTriggered: { root.snapSuccess = false; root.snapError = false; }
    }

    // ── focus ─────────────────────────────────────────────────────────────────
    onFocusChanged: if (focus) searchField.forceActiveFocus()

    // ── layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── toolbar: search + new snapshot button ─────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.bottomMargin: 14
            spacing: 10

            // search field
            ToolbarTextField {
                id: searchField
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.fillHeight: false
                placeholderText: "Search profiles…"
                text: root.filter
                onTextChanged: root.filter = text
                Keys.onEscapePressed: root.filter = ""
            }

            // snapshot feedback tiny badge
            Rectangle {
                visible: root.snapSuccess || root.snapError
                radius: Appearance.rounding.full
                color: root.snapSuccess
                    ? Appearance.colors.colPrimaryContainer
                    : Appearance.colors.colErrorContainer
                implicitWidth:  fbRow.implicitWidth + 16
                implicitHeight: 36

                RowLayout {
                    id: fbRow
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol {
                        text: root.snapSuccess ? "check_circle" : "error"
                        iconSize: Appearance.font.pixelSize.normal
                        fill: 1
                        color: root.snapSuccess
                            ? Appearance.colors.colOnPrimaryContainer
                            : Appearance.colors.colOnErrorContainer
                    }
                    StyledText {
                        text: root.snapSuccess ? "Saved!" : "Failed"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.snapSuccess
                            ? Appearance.colors.colOnPrimaryContainer
                            : Appearance.colors.colOnErrorContainer
                    }
                }
            }

            // new snapshot button / cancel button
            RippleButtonWithIcon {
                id: newSnapshotBtn
                materialIcon: root.showNewForm ? "close" : "add_a_photo"
                materialIconFill: !root.showNewForm
                mainText: root.showNewForm ? "Cancel" : "New snapshot"
                colText: root.showNewForm
                    ? Appearance.colors.colOnSurfaceVariant
                    : Appearance.colors.colOnPrimary
                colBackground: root.showNewForm
                    ? Appearance.colors.colLayer2
                    : Appearance.colors.colPrimary
                colBackgroundHover: root.showNewForm
                    ? Appearance.colors.colLayer2Hover
                    : Appearance.colors.colPrimaryHover
                buttonRadius: Appearance.rounding.full
                implicitHeight: 36

                onClicked: root.showNewForm = !root.showNewForm
            }
        }

        // ── new snapshot inline form ──────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: root.showNewForm ? newFormLayout.implicitHeight + 20 : 0
            clip: true
            Layout.bottomMargin: root.showNewForm ? 14 : 0

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }
            }

            Rectangle {
                id: newFormBg
                anchors.fill: parent
                radius: Appearance.rounding.large
                color: Appearance.colors.colSurfaceContainerHigh
                border { width: 1; color: Appearance.colors.colOutlineVariant }
            }

            StyledRectangularShadow {
                target: newFormBg
                visible: root.showNewForm
            }

                ColumnLayout {
                    id: newFormLayout
                    anchors {
                        left: parent.left; right: parent.right; top: parent.top
                        margins: 14
                    }
                    spacing: 10

                    // emoji picker + name field row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // emoji grid
                        Flow {
                            id: emojiFlow
                            Layout.preferredWidth: 170
                            spacing: 4

                            Repeater {
                                model: root.emojiList
                                delegate: RippleButton {
                                    id: emojiBtn
                                    required property var modelData
                                    implicitWidth: 28; implicitHeight: 28
                                    buttonRadius: Appearance.rounding.small
                                    toggled: root.newEmoji === modelData
                                    colBackgroundToggled: Appearance.colors.colPrimaryContainer
                                    onClicked: root.newEmoji = modelData

                                    HoverHandler { id: emojiHover }

                                    scale: emojiHover.hovered ? 1.15 : 1.0
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 100
                                            easing.type: Easing.OutQuad
                                        }
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: emojiBtn.modelData
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }

                        // name + description column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialTextField {
                                id: nameField
                                Layout.fillWidth: true
                                placeholderText: "Profile name (required)…"
                                text: root.newName
                                onTextChanged: root.newName = text
                                Keys.onReturnPressed: if (root.newName.trim().length > 0) _doSnapshot()
                                Keys.onEscapePressed: root.showNewForm = false
                                Component.onCompleted: if (root.showNewForm) forceActiveFocus()
                            }

                            MaterialTextField {
                                Layout.fillWidth: true
                                placeholderText: "Description (optional)…"
                                text: root.newDesc
                                onTextChanged: root.newDesc = text
                                Keys.onEscapePressed: root.showNewForm = false
                            }
                        }
                    }

                    // save row
                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }

                        MaterialLoadingIndicator {
                            visible: root.snapBusy
                            implicitWidth: 24; implicitHeight: 24
                        }

                        RippleButtonWithIcon {
                            materialIcon: "save"
                            mainText: "Save snapshot"
                            enabled: root.newName.trim().length > 0 && !root.snapBusy
                            colText: Appearance.colors.colOnPrimary
                            colBackground: Appearance.colors.colPrimary
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            buttonRadius: Appearance.rounding.full
                            implicitHeight: 34
                            onClicked: _doSnapshot()
                        }
                    }
                }
            }
        }

        // ── profile list ──────────────────────────────────────────────────────
        Item {
            id: profileListItem
            Layout.fillWidth: true
            Layout.fillHeight: true

            // empty state
            PagePlaceholder {
                shown: !WorkspaceProfileService.loading
                    && WorkspaceProfileService.profilesModel.count === 0
                icon: "dashboard"
                title: "No profiles yet"
                description: "Click \"New snapshot\" to save your current workspace layout."
            }

            // filtered empty state — count visible children
            property int visibleCardCount: 0
            PagePlaceholder {
                shown: !WorkspaceProfileService.loading
                    && WorkspaceProfileService.profilesModel.count > 0
                    && parent.visibleCardCount === 0
                icon: "search_off"
                title: "No matches"
                description: "Try a different search term."
            }

            // loading indicator
            MaterialLoadingIndicator {
                anchors.centerIn: parent
                visible: WorkspaceProfileService.loading
                implicitWidth: 40; implicitHeight: 40
            }

            StyledFlickable {
                anchors.fill: parent
                contentHeight: profileColumn.implicitHeight + 24
                clip: true

                ColumnLayout {
                    id: profileColumn
                    width: parent.width - 24
                    x: 12
                    y: 12
                    spacing: 14

                    Repeater {
                        id: profileRepeater
                        model: WorkspaceProfileService.profilesModel

                        delegate: ProfileCard {
                            id: card

                            // Filter visibility
                            visible: {
                                const q = root.filter.toLowerCase().trim();
                                if (!q) return true;
                                return name.toLowerCase().includes(q) ||
                                       description.toLowerCase().includes(q);
                            }
                            onVisibleChanged: _updateVisibleCount()
                            Component.onCompleted: _updateVisibleCount()
                            Component.onDestruction: {
                                if (visible) profileListItem.visibleCardCount--;
                            }

                            function _updateVisibleCount() {
                                // recalculate from scratch to avoid drift
                                let n = 0;
                                for (let i = 0; i < profileRepeater.count; i++) {
                                    const item = profileRepeater.itemAt(i);
                                    if (item && item.visible) n++;
                                }
                                profileListItem.visibleCardCount = n;
                            }

                            Layout.fillWidth: true
                            width: profileColumn.width

                            expanded: root.isProfileExpanded(slug)
                            onToggleExpandedRequested: {
                                root.setProfileExpanded(slug, !root.isProfileExpanded(slug));
                            }

                            onRestoreRequested:  WorkspaceProfileService.restoreProfile(slug)
                            onDeleteRequested:   WorkspaceProfileService.deleteProfile(slug)
                            onRenameRequested: (newName) =>
                                WorkspaceProfileService.renameProfile(slug, newName)
                        }
                    }
                }
            }
        }
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    function _doSnapshot() {
        const name = root.newName.trim();
        if (!name) return;
        root.snapBusy = true;
        WorkspaceProfileService.snapshot(name, root.newEmoji, root.newDesc, {});
    }
}
