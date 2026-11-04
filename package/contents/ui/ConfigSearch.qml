/*
    SPDX-FileCopyrightText: 2026 naglfar <tutal33t@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasma5support as P5Support

KCM.ScrollViewKCM {
    id: root

    property var cfg_searchRunners: []
    property var cfg_searchRunnersDefault: []

    readonly property bool customSelection: cfg_searchRunners.length > 0
    // [{id, name}] of the installed KRunner plugins, sorted by name
    property var installedRunners: []
    property bool runnersLoaded: false
    // Plugins switched off in Plasma Search; plugins that are off by default without being switched off are not known here
    property var disabledRunners: []
    // RunnerModel falls back to all enabled plugins when none of the selected ones is enabled
    readonly property bool allSelectedDisabled: customSelection && cfg_searchRunners.every(id => disabledRunners.includes(id))

    function runnerName(id) {
        const runner = installedRunners.find(r => r.id === id);
        return runner ? runner.name : id;
    }

    // Selected plugins in their order first, then the others by name
    readonly property var rows: {
        const selected = cfg_searchRunners.map(id => ({
            id: id,
            name: runnerName(id),
            selected: true,
            installed: installedRunners.some(r => r.id === id),
            disabled: disabledRunners.includes(id),
        }));
        const others = installedRunners
            .filter(r => !cfg_searchRunners.includes(r.id))
            .map(r => ({ id: r.id, name: r.name, selected: false, installed: true, disabled: disabledRunners.includes(r.id) }));
        return selected.concat(others);
    }

    function setSelected(id, selected) {
        const list = cfg_searchRunners.filter(r => r !== id);
        if (selected) {
            list.push(id);
        }
        cfg_searchRunners = list;
    }

    function move(id, offset) {
        const list = cfg_searchRunners.slice();
        const from = list.indexOf(id);
        const to = from + offset;
        if (from < 0 || to < 0 || to >= list.length) {
            return;
        }
        list.splice(to, 0, list.splice(from, 1)[0]);
        cfg_searchRunners = list;
    }

    // KRunner has no QML API to list its plugins, so ask the krunner binary
    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["krunner --list"]
        onNewData: (source, data) => {
            const runners = [];
            for (const line of String(data["stdout"]).split("\n")) {
                // "Name: pluginId", after a header ending with a line of dashes
                const separator = line.lastIndexOf(": ");
                if (separator > 0) {
                    runners.push({ name: line.slice(0, separator).trim(), id: line.slice(separator + 2).trim() });
                }
            }
            runners.sort((a, b) => a.name.localeCompare(b.name));
            root.installedRunners = runners;
            root.runnersLoaded = true;
            disconnectSource(source);
            enabledStates.read(runners.map(r => r.id));
        }
    }

    // Read the switches from Plasma Search, the same keys KRunner uses
    P5Support.DataSource {
        id: enabledStates
        engine: "executable"

        function read(ids) {
            // Plugin ids are plain identifiers; skip anything else rather than passing it to a shell
            const safeIds = ids.filter(id => /^[A-Za-z0-9_.-]+$/.test(id));
            if (safeIds.length > 0) {
                connectSource(`for id in ${safeIds.join(" ")}; do printf '%s=%s\\n' "$id" "$(kreadconfig6 --file krunnerrc --group Plugins --key "\${id}Enabled")"; done`);
            }
        }

        onNewData: (source, data) => {
            root.disabledRunners = String(data["stdout"]).split("\n")
                .filter(line => line.endsWith("=false"))
                .map(line => line.slice(0, -"=false".length));
            disconnectSource(source);
        }
    }

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.RadioButton {
            Layout.fillWidth: true
            text: i18nc("@option:radio", "Use the plugins and order from Plasma Search")
            checked: !root.customSelection
            onToggled: root.cfg_searchRunners = []
        }

        QQC2.RadioButton {
            Layout.fillWidth: true
            text: i18nc("@option:radio", "Use only the selected plugins, in this order")
            checked: root.customSelection
            // Start with applications, the usual purpose of a launcher
            onToggled: root.cfg_searchRunners = ["krunner_services"]
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: i18nc("@info", "Results of the first plugin are shown first. Plugins disabled in Plasma Search are not used, even when selected here. The settings of each plugin apply everywhere.")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: root.allSelectedDisabled
            type: Kirigami.MessageType.Warning
            text: i18nc("@info", "All selected plugins are disabled in Plasma Search. The launcher then searches with all plugins enabled there.")
        }
    }

    view: ListView {
        id: runnerList

        enabled: root.customSelection
        model: root.rows
        reuseItems: true
        // Rows are not selectable; the checkboxes and buttons are the controls
        currentIndex: -1

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: runnerList.count === 0
            text: root.runnersLoaded ? i18nc("@info", "No search plugins found") : i18nc("@info", "Loading search plugins…")
        }

        delegate: QQC2.ItemDelegate {
            id: delegate

            required property var modelData
            required property int index

            width: ListView.view.width
            // The list itself is the control; rows only hold the checkbox and buttons
            down: false
            highlighted: false
            hoverEnabled: false

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.CheckBox {
                    id: checkBox
                    checked: delegate.modelData.selected
                    // The last selected plugin can't be removed here; choose the other option instead
                    enabled: !(checked && root.cfg_searchRunners.length === 1)
                    Accessible.name: delegate.modelData.name
                    onToggled: root.setSelected(delegate.modelData.id, checked)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: delegate.modelData.name
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: !delegate.modelData.installed ? i18nc("@info %1 is a plugin id", "%1 (not installed)", delegate.modelData.id)
                            : delegate.modelData.disabled ? i18nc("@info %1 is a plugin id", "%1 (disabled in Plasma Search)", delegate.modelData.id)
                            : delegate.modelData.id
                        elide: Text.ElideRight
                        font: Kirigami.Theme.smallFont
                        opacity: 0.7
                    }
                }

                QQC2.ToolButton {
                    visible: delegate.modelData.selected
                    enabled: delegate.index > 0
                    icon.name: "arrow-up"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Move Up")
                    Accessible.name: i18nc("@action:button %1 is a plugin name", "Move %1 up", delegate.modelData.name)
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: root.move(delegate.modelData.id, -1)
                }

                QQC2.ToolButton {
                    visible: delegate.modelData.selected
                    enabled: delegate.index < root.cfg_searchRunners.length - 1
                    icon.name: "arrow-down"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Move Down")
                    Accessible.name: i18nc("@action:button %1 is a plugin name", "Move %1 down", delegate.modelData.name)
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: root.move(delegate.modelData.id, 1)
                }
            }
        }
    }

    footer: RowLayout {
        QQC2.Button {
            enabled: KConfig.KAuthorized.authorizeControlModule("kcm_plasmasearch")
            icon.name: "settings-configure"
            text: i18nc("@action:button opens the Plasma Search settings", "Configure Search Plugins…")
            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_plasmasearch")
        }
    }
}
