import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    // ── Script path — uses Directories.home so it works for any user ────────
    readonly property string setupScript: FileUtils.trimFileProtocol(`${Directories.home}/.local/share/ii-vynx/setup-ii-vynx.sh`)

    // ── Single process for all actions ──────────────────────────────────────
    Process {
        id: actionProc
        property string mode: ""
        property string logOutput: ""
        stdout: SplitParser {
            onRead: data => {
                actionProc.logOutput += data + "\n";
            }
        }
        stderr: SplitParser {
            onRead: data => {
                actionProc.logOutput += data + "\n";
            }
        }
        onExited: code => {
            if (code === 0)
                actionProc.logOutput += "✓ Done\n";
            else
                actionProc.logOutput += "✗ Exited with code " + code + "\n";
        }
    }

    // ── Distro ───────────────────────────────────────────────────────────────
    ContentSection {
        icon: "box"
        title: Translation.tr("Distro")
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath(SystemInfo.logo)
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                StyledText {
                    text: SystemInfo.distroName
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    text: SystemInfo.homeUrl
                    textFormat: Text.MarkdownText
                    onLinkActivated: link => Qt.openUrlExternally(link)
                    PointingHandLinkHover {}
                }
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 5
            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: Qt.openUrlExternally(SystemInfo.documentationUrl)
            }
            RippleButtonWithIcon {
                materialIcon: "support"
                mainText: Translation.tr("Help & Support")
                onClicked: Qt.openUrlExternally(SystemInfo.supportUrl)
            }
            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Report a Bug")
                onClicked: Qt.openUrlExternally(SystemInfo.bugReportUrl)
            }
            RippleButtonWithIcon {
                materialIcon: "policy"
                materialIconFill: false
                mainText: Translation.tr("Privacy Policy")
                onClicked: Qt.openUrlExternally(SystemInfo.privacyPolicyUrl)
            }
        }
    }

    // ── Parent-Dots ──────────────────────────────────────────────────────────
    ContentSection {
        icon: "folder_managed"
        title: Translation.tr("Parent-Dots")
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath("illogical-impulse")
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                StyledText {
                    text: Translation.tr("illogical-impulse")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    text: "https://github.com/end-4/dots-hyprland"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    textFormat: Text.MarkdownText
                    onLinkActivated: link => Qt.openUrlExternally(link)
                    PointingHandLinkHover {}
                }
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 5
            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
            }
            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues")
            }
            RippleButtonWithIcon {
                materialIcon: "forum"
                mainText: Translation.tr("Discussions")
                onClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions")
            }
            RippleButtonWithIcon {
                materialIcon: "favorite"
                mainText: Translation.tr("Donate")
                onClicked: Qt.openUrlExternally("https://github.com/sponsors/end-4")
            }
        }
    }

    // ── Dotfiles ─────────────────────────────────────────────────────────────
    ContentSection {
        icon: "folder_data"
        title: Translation.tr("Dotfiles")
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            CustomIcon {
                width: 80
                height: 80
                source: "ii-vynx"
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                StyledText {
                    text: Translation.tr("ii-vynx")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    text: "https://github.com/vaguesyntax/ii-vynx"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    textFormat: Text.MarkdownText
                    onLinkActivated: link => Qt.openUrlExternally(link)
                    PointingHandLinkHover {}
                }
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 5
            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: Qt.openUrlExternally("https://github.com/vaguesyntax/ii-vynx/issues")
            }
            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: Qt.openUrlExternally("https://github.com/vaguesyntax/ii-vynx/wiki")
            }
            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Known Issues")
                onClicked: Qt.openUrlExternally("https://github.com/vaguesyntax/ii-vynx/wiki/Known-Issues-and-Limitations")
            }
        }
    }

    // ── Quickshell Source ────────────────────────────────────────────────────
    ContentSection {
        icon: "swap_horiz"
        title: Translation.tr("Quickshell Source")

        // ── Update buttons (top) ─────────────────────────────────────────
        ContentSubsection {
            title: Translation.tr("Update")
            tooltip: Translation.tr("Pull latest changes from GitHub for each source independently")

            Flow {
                Layout.fillWidth: true
                spacing: 5

                RippleButtonWithIcon {
                    materialIcon: actionProc.running && actionProc.mode === "update-fork" ? "sync" : "system_update_alt"
                    mainText: actionProc.running && actionProc.mode === "update-fork" ? Translation.tr("Updating fork...") : Translation.tr("Update Fork")
                    enabled: !actionProc.running
                    onClicked: {
                        actionProc.logOutput = "";
                        actionProc.mode = "update-fork";
                        actionProc.command = ["bash", page.setupScript, "--update-only", "--no-confirm"];
                        actionProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Pull latest changes from your fork on GitHub")
                    }
                }

                RippleButtonWithIcon {
                    materialIcon: actionProc.running && actionProc.mode === "update-upstream" ? "sync" : "cloud_download"
                    mainText: actionProc.running && actionProc.mode === "update-upstream" ? Translation.tr("Updating...") : Translation.tr("Update ii-vynx")
                    enabled: !actionProc.running
                    onClicked: {
                        actionProc.logOutput = "";
                        actionProc.mode = "update-upstream";
                        actionProc.command = ["bash", page.setupScript, "--update-only", "--ii-vynx", "--no-confirm"];
                        actionProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Pull latest official ii-vynx from GitHub")
                    }
                }
            }

            // Log output area
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                height: logText.implicitHeight + 16
                visible: actionProc.logOutput !== ""
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer0
                border.color: Appearance.colors.colOutline
                border.width: 1

                Text {
                    id: logText
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 8
                    }
                    text: actionProc.logOutput
                    font.family: "monospace"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // ── Switch buttons (bottom) ──────────────────────────────────────
        ContentSubsection {
            title: Translation.tr("Switch Source")
            tooltip: Translation.tr("Switch between sources using local repos — no network required")

            Flow {
                Layout.fillWidth: true
                spacing: 5

                RippleButtonWithIcon {
                    materialIcon: actionProc.running && actionProc.mode === "fork" ? "sync" : "fork_right"
                    mainText: actionProc.running && actionProc.mode === "fork" ? Translation.tr("Switching...") : Translation.tr("P3DROVFX Fork")
                    enabled: !actionProc.running
                    onClicked: {
                        actionProc.logOutput = "";
                        actionProc.mode = "fork";
                        actionProc.command = ["bash", page.setupScript, "--force-install", "--no-pull", "--no-confirm"];
                        actionProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Switch to your fork (local, no network)")
                    }
                }

                RippleButtonWithIcon {
                    materialIcon: actionProc.running && actionProc.mode === "upstream" ? "sync" : "deployed_code"
                    mainText: actionProc.running && actionProc.mode === "upstream" ? Translation.tr("Switching...") : Translation.tr("ii-vynx Official")
                    enabled: !actionProc.running
                    onClicked: {
                        actionProc.logOutput = "";
                        actionProc.mode = "upstream";
                        actionProc.command = ["bash", page.setupScript, "--force-install", "--no-pull", "--no-confirm", "--ii-vynx"];
                        actionProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Switch to official ii-vynx (local, no network)")
                    }
                }
            }
        }
    }
}
